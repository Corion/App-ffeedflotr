#!perl -w
use strict;
use Getopt::Long;
use App::Ffeedflotr;
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
if (defined $separator and ! ref $separator) {
    $separator = qr/$separator/
};
$chart_type ||= 'line';
$sleep_interval ||= 0.5;

# Transform to px if nothing else was specified
$width ||= "100%";
$height ||= "100%";
for ($width, $height) {
    $_ = "${_}px"
        if /^\d+$/;
};

$timeformat ||= '%y-%0m-%0d';
$title ||= 'App::Ffeedflotr plot';

# XXX How to inline this?
# Read from DATA, write to tempfile
my $template = do {
                   open my $fh, '<', 'template/ffeedflotr.htm'
                       or die "Couldn't read 'template/ffeedflotr.htm': $!";
                   local $/; <$fh> };

my $app = App::Ffeedflotr->new(
    tab => $tab,
    autoclose => ($stream or $outfile),
    title => $title,
    'time' => $time,
    timeformat => $timeformat,
    width => $width,
    height => $height,
    legend => \@legend,
    color  => \@color,
    type => $chart_type,
    sleep_interval => \$sleep_interval,
    separator => $separator,
    template => \$template,
    type => $chart_type,
    xlen => $xlen,
    fill => $fill,
    xmax => $xmax,
    ymax => $ymax,
);

$app->configure_plot();

# First, assume simple single series, [x,y] pairs
# For real streaming, using AnyEvent might be nice
# especially so we can read 1s worth of data instead of going
# line by line

# XXX We should presize the graph to $xlen if it is greater 0
# XXX Support timelines and time events

my @data;

my $done;
DO_PLOT: {
    if ($stream) {
        push @data, $app->read_available_input( *STDIN );
        if (@data and ! defined $data[-1]) {
            $done = 1;
            pop @data;
        }
    } else {
        # Read everything and plot it
        @data = <>;
    };
    
    $app->plot(@data);

    if ($stream) {
        sleep $sleep_interval;
        redo DO_PLOT
            unless $done;
    };
};

if ($outfile) {
    $app->save_png($outfile);
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
