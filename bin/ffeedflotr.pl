#!perl -w
use strict;
use WWW::Mechanize::Firefox;
use Getopt::Long;
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

=cut

GetOptions(
    'tab:s'     => \my $tab,
    'mozrepl:s' => \my $mozrepl,
    'stream'    => \my $stream,
    'xlabel:s'   => \my $xaxis_label,
    'ylabel:s'   => \my $yaxis_label,
    'xlen:s'    => \my $xlen,
    'title|t:s' => \my $title,
);
$tab = $tab ? qr/$tab/ : undef;

$title ||= 'App::ffeedflotr plot';

my $mech = WWW::Mechanize::Firefox->new(
    create => 1,
    tab    => $tab,
    activate => 1,
    autoclose => ($stream),
);

my $c = do { open my $fh, '<', "template/ffeedflotr.htm" or die "$!"; binmode $fh; local $/; <$fh> };

#$mech->update_html($c);
$mech->get_local('../template/ffeedflotr.htm');

#my ($plotData,$type) = $mech->eval_in_page('plotData');

$mech->document->{title} = $title;

my ($setupPlot, $type) = $mech->eval_in_page("setupPlot");

sub plot {
    my ($data) = @_;
    $setupPlot->($data);
};

# First, assume simple single series, [x,y] pairs
# For real streaming, using AnyEvent might be nice
# especially so we can read 1s worth of data instead of going
# line by line

# XXX We should presize the graph to $xlen if it is greater 0

my @data;

DO_PLOT: {
    if ($stream) {
        # On Windows, we can't easily select() on an FH ...
        # So we just read one line and replot
        push @data, [split /\s+/, scalar <>];
    } else {
        # Read everything and plot it
        @data = map { [split /\s+/] } <>;
    };
    
    # Keep only the latest elements
    if ($xlen and @data > $xlen) {
        splice @data, 0, 0+@data-$xlen;
    };

    my $data = [{
                  "stack" => 1, # for later, when we support stacking data
                  "data"  => \@data,
                  "label" => $xaxis_label,
                  "id"    => 1, # for later, when we support multiple datasets
    }];
    plot($data);

    if ($stream) {
        sleep 1;
        redo DO_PLOT;
    };
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
