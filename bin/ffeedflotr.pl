#!perl -w
use strict;
use WWW::Mechanize::Firefox;
use Getopt::Long;
use Time::Local;
use Data::Dumper;

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

=cut

GetOptions(
    'tab:s'     => \my $tab,
    'mozrepl:s' => \my $mozrepl,
    'stream'    => \my $stream,
    'xlabel:s'   => \my $xaxis_label,
    'ylabel:s'   => \my $yaxis_label,
    'xlen:s'    => \my $xlen,
    'title|t:s' => \my $title,
    'fill'      => \my $fill,
    'time'      => \my $time,
    'timeformat:s' => \my $timeformat,
    'output|o:s' => \my $outfile,
);
$tab = $tab ? qr/$tab/ : undef;

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

$mech->document->{title} = $title;

my ($setupPlot, $type) = $mech->eval_in_page("setupPlot");

sub plot {
    my ($data) = @_;
    $setupPlot->($data);
};

(my $xaxis, $type) = $mech->eval_in_page("plotConfig.xaxis");
(my $lines, $type) = $mech->eval_in_page("plotConfig.lines");

$lines->{fill} = $fill;

if ($time) {
    $xaxis->{mode} = "time";
    $xaxis->{timeformat} = $timeformat;
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

DO_PLOT: {
    if ($stream) {
        # On Windows, we can't easily select() on an FH ...
        # So we just read one line and replot
        push @data, [split /\s+/, scalar <>];
    } else {
        # Read everything and plot it
        @data = map { s/^\s+//; [ split /\s+/] } <>;
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

    my $idx = 1;
    my $data = [
        map +{
                  "stack" => $idx++, # for later, when we support stacking data
                  "data"  => $_,
                  "label" => $xaxis_label, # XXX This needs to become multiple labels
                  "id"    => $idx, # for later, when we support multiple datasets
    }, @sets];
    plot($data);

    if ($stream) {
        sleep 1;
        redo DO_PLOT;
    };
};

if ($outfile) {
    my $png = $mech->content_as_png($mech->tab,{left=>0,top=>0,width=>900,height=>330});

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
