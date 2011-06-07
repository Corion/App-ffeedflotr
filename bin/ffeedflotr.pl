#!perl -w
use strict;
use WWW::Mechanize::Firefox;
use Getopt::Long;
use Time::Local;
use Time::HiRes qw(sleep);
use Data::Dumper;
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

ffeedflotr.pl - like feedGnuplot , except using Firefox+flot for display

=head1 SYNOPSIS

  # Simple plot
  perl -w bin\ffeedflotr.pl --title test
  1 1
  2 4
  3 9
  4 16
  ^D

  # Realtime streaming of data
  perl -wle "$|++;while(1){print( $i++,' ',rand(10));sleep 1}" \
  | perl -w bin\ffeedflotr.pl --title test --stream --xlen 15

  # Plot multiple sets
  perl -w bin\ffeedflotr.pl --title test
  1 1   1
  2 4  10
  3 9  11
  4 16 100

=head1 OPTIONS

=over 4

=item *

C<<--stream>> - stream data from stdin, repaint every second

=item *

C<<--update-interval>> - set minimum update interval in seconds

=item *

C<<--xlen>> - number of items to keep while streaming

=item *

C<<--type>> - select type of chart

C<< line >> - a chart with lines, the default

C<< pie >> - a pie chart. Flot will use the first row in the dataset.
You can use C<<--xlen>> to discard leading rows from the set.

C<< bar >> - a bar chart. Not implemented

=item *

C<<--legend>> - legend for data column

Use like this:

    --legend 1=Pass --legend 2=Fail

C<<--color>> - color for data column

The color can be any (HTML) color name or a number.

Use like this:

    --color 1=green --color 2=red

=item *

C<<--xlabel>> - label for the X-axis

=item *

C<<--xmax>> - maximum size for the X-axis

=item *

C<<--ylabel>> - label for the Y-axis

=item *

C<<--ymax>> - maximum size for the Y-axis

=item *

C<<--fill>> - fill the area under the graph

=item *

C<<--background>> - url of a background image

=item *

C<<--time>> - X-axis is a time series

=item *

C<<--timeformat>> - format for the time

Default is C<%y-%0m-%0d>

=item *

C<<--output>> - name of the output file

=item *

C<<--tab>> - the (regex for) the tab to reuse

=item *

C<<--mozrepl>> - mozrepl connection string

=back

=cut

GetOptions(
    'tab:s'     => \my $tab,
    'mozrepl:s' => \my $mozrepl,
    'stream'    => \my $stream,
    'xlabel:s'   => \my $xaxis_label,
    'ylabel:s'   => \my $yaxis_label,
    'xmax:s'   => \my $xmax,
    'ymax:s'   => \my $ymax,
    'xlen:s'    => \my $xlen,
    'title|t:s' => \my $title,
    'type:s' => \my $chart_type,
    'pie-start-angle:s' => \my $pie_start_angle,
    'fill'      => \my $fill,
    'time'      => \my $time,
    'timeformat:s' => \my $timeformat,
    'output|o:s' => \my $outfile,
    'sep:s' => \my $separator,
    'legend:s' => \my @legend,
    'color:s' => \my @color,
    'width:s' => \my $width,
    'height:s' => \my $height,
    'background:s' => \my $background,
    'update-interval:s' => \my $sleep_interval,
);
$tab = $tab ? qr/$tab/ : undef;
$separator ||= qr/\s+/;
if (! ref $separator) {
    $separator = qr/$separator/
};
$chart_type ||= 'line';
$sleep_interval ||= 0.5;

my @colinfo;

for (@legend) {
    /(.*?)=(.*)/
        or warn "Ignoring malformed legend [$_]", next;
    $colinfo[ $1 ] ||= {};
    $colinfo[ $1 ]->{label} = $2;
};
for (@color) {
    /(.*?)=(.*)/
        or warn "Ignoring malformed color [$_]", next;
    $colinfo[ $1 ] ||= {};
    $colinfo[ $1 ]->{color} = $2;
};

# Transform to px if nothing else was specified
$width ||= "100%";
$height ||= "100%";
for ($width, $height) {
    $_ = "${_}px"
        if /^\d+$/;
};

$timeformat ||= '%y-%0m-%0d';
$title ||= 'App::ffeedflotr plot';

my $mech = WWW::Mechanize::Firefox->new(
    create => 1,
    tab    => $tab,
    activate => 1,
    autoclose => ($stream or $outfile),
);

# XXX Find out why Firefox does not like Javascript in data: URLs
#     and what we can do about it (tempfile?)
#my $c = do { open my $fh, '<', "template/ffeedflotr.htm" or die "$!"; binmode $fh; local $/; <$fh> };
#$mech->update_html($c);
$mech->get_local('../template/ffeedflotr.htm');

# Now, resize the container in our template
my $container = $mech->by_id('plot1', single => 1);
$container->{style}->{width} = $width;
$container->{style}->{height} = $height;

# Set the page title
$mech->document->{title} = $title;

my ($setupPlot, $type) = $mech->eval_in_page("setupPlot");

sub plot {
    my ($data) = @_;
    $setupPlot->($data);
};

(my $xaxis, $type) = $mech->eval_in_page("plotConfig.xaxis");
(my $yaxis, $type) = $mech->eval_in_page("plotConfig.yaxis");
(my $lines, $type) = $mech->eval_in_page("plotConfig.lines");
(my $series, $type) = $mech->eval_in_page("plotConfig.series");

if ($background) {
    my $plot1 = $mech->by_id('plot1', single => 1 );
    $plot1->{style}->{backgroundImage} = "url($background)";
};


if ($chart_type eq 'pie') {
    $series->{pie}->{show} = 1;
    $series->{pie}->{startAngle} = $pie_start_angle;
};

if ($chart_type eq 'scatter') {
    $lines->{show} = 0;
};

$lines->{fill} = $fill;

if ($time) {
    $xaxis->{mode} = "time";
    $xaxis->{timeformat} = $timeformat;
};

if ($xmax) {
    $xaxis->{max} = $xmax;
};

if ($ymax) {
    $yaxis->{max} = $ymax;
};

# First, assume simple single series, [x,y] pairs
# For real streaming, using AnyEvent might be nice
# especially so we can read 1s worth of data instead of going
# line by line

# XXX We should presize the graph to $xlen if it is greater 0
# XXX Support timelines and time events

sub ts($) {
    # Convert something that vaguely looks like a date/time to a JS timestamp
    local $_ = $_[0];
    if (/^(\d\d\d\d)-?(\d\d)-?(\d\d)$/) { # yyyy-mm-dd, canonicalize
        $_ = "$1-$2-$3";
    } elsif (/^(\d\d\d\d)-?([01]\d)$/) { # yyyy-mm, map to first of month
        $_ = "$1-$2-01";
    };
    if (/^(\d\d\d\d)-?([01]\d)-?([0123]\d)$/) { # yyyy-mm-dd, map to 00:00:00
        $_ = "$_ 00:00:00";
    };
    my @d = reverse /(\d+)/g;
    $d[-2]--; # adjust January=0 in unix time* APIs
    timelocal(@d)*1000;
};

my @data;

sub parse_row($) {
    local $_ = $_[0];
    s/^\s+//;
    [ map {s/^\s+//; $_ } split /$separator/ ]
};

my $input;
sub read_available_input {
    my ($pipe) = @_;
    
    # Just spawn a thread
    # to asynchronously read from the filehandle
    if (! $input) {
        require threads;
        require Thread::Queue;
        $input = Thread::Queue->new();
        threads::async(sub {
            $input->enqueue( "$_" ) # make an explicit copy, again
                while(<$pipe>);
            $input->enqueue( undef );
        })->detach;
    };

    my @res = $input->dequeue; # block for at least one item
    # And fetch all items that are available right now
    while ($input->pending) {
        push @res, $input->dequeue($input->pending);
    };
    @res
}

my $done;
DO_PLOT: {
    if ($stream) {
        # On Windows, we can't easily select() on an FH ...
        # So we just read one line and replot
        push @data, map { $done=!defined($_); defined($_) ? parse_row( $_ ) : () } read_available_input( *STDIN );
    } else {
        # Read everything and plot it
        @data = map { parse_row $_ } <>;
    };
    
    # Keep only the latest elements
    if ($xlen and @data > $xlen) {
        splice @data, 0, 0+@data-$xlen;
    };
    
    # Split up multiple columns (x,y1,y2,y3) into (x,y1),(x,y2),...
    my @sets;
    for my $col (1..$#{$data[0]} ) {
        push @sets, [ map { [ $time ? ts $_->[0] : 0+$_->[0], 0+$_->[$col]] } @data ];
    };

    my $idx = 0;
    my $data = [
        map { $idx++; +{
                  #"stack" => $idx, # for later, when we support stacking data
                  "data"  => $_,
                  #"label" => $legend{$idx},
                  hoverable => 1,
                  "id"    => $idx, # for later, when we support multiple datasets
                  # Other, user-specified data
                  %{ $colinfo[ $idx ] || {} },
    }} @sets];
    plot($data);

    if ($stream) {
        sleep $sleep_interval;
        redo DO_PLOT
            unless $done;
    };
};

if ($outfile) {
    my $png = $mech->element_as_png($container);

    open my $out, '>', $outfile
        or die "Couldn't create '$outfile': $!";
    binmode $out;
    print {$out} $png;
};

END {
    undef $mech; # so the autoclose gets a chance to do its thing?!
};

=head1 SEE ALSO

=over 4

=item *

L<http://search.cpan.org/dist/feedGnuplot> - a similar program for Gnuplot

=back

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/App-ffeedflotr>.

=head1 SUPPORT

The public support forum of this module is
L<http://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module/program is released under the same terms as Perl itself.

=cut
