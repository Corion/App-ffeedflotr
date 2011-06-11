#!perl -w
use strict;
use LWP::Simple 'get';
use Carp qw(croak);
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

generate-inline-template.pl - fetch the (online) resources needed

=cut

sub fetch {
    my ($url) = @_;
    my $inlined = get $url;
    if (! $inlined) {
        croak "Couldn't inline '$url'";
    };
    join "\n", 
         "<!-- fetched from '$url' -->",
         '<script type="text/javascript">',
         $inlined,
         '</script>'
};

my ($in,$out) = @ARGV;
$in ||= 'template/ffeedflotr-online.htm';
if (! $out) {
    ($out = $in) =~ s/-online//i;
};

my $html = do { open my $fh, '<', $in or die "Couldn't read '$in': $!";
                binmode $fh;
                local $/;
                <$fh>
              } ;
$html =~ s!<script .*?src="(.*?)"></script>!fetch($1)!ge;

open my $fh, '>', $out
    or die "Couldn't create '$out': $!";
binmode $fh;
print {$fh} $html;

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
