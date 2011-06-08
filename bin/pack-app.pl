#!perl -w
use strict;
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

pack-app.pl - generate monolithic script by inlining modules

=cut

my @prepend;

sub inline_module {
    my ($module,$import) = @_;
    (my $file = "$module.pm") =~ s!::|'!/!g;
    eval "require $module; 1"
        or die $@;
    open my $fh, '<', $INC{$file}
        or die "Couldn't read '$INC{$file}' for $module: $!";
    local $/;
    my $src = join "\n",
                     '{',
                     <$fh>,
                     '}',
                     '$INC{__PACKAGE__}=$0;'
                     ;
    unshift @prepend, $src;
    
    if (defined $import and $import =~ /\S/) {
        "$module->import($import);\n"
    } else {
        "#use $module; # inlined above\n";
    }
}

sub inline_modules {
    my ($source, @modules) = @_;
    my $modules = join "|", map{quotemeta($_)}@modules;
    $modules = qr/($modules)/;
    
    1 while
        $source =~ s/^use\s+$modules(?:\s*([^;]+)|);\s*/inline_module($1)/msge;
    $source
}

my ($infile,$templatefile, $outfile) = @ARGV;
open my $in, '<', $infile
    or die "Couldn't read '$infile': $!";
my $source = do { local $/; <$in> };
$source = inline_modules($source, 'App::Ffeedflotr');

# Move hashbang to top
if ($source =~ s/^(#.*)/package main;/) {
    unshift @prepend, "$1\n";
}

# Append the inline template as __DATA__ section
my $template = do {
    open my $fh, '<', $templatefile
        or die "Couldn't read '$templatefile': $!";
    local $/; <$fh>
};
$source .= join "\n",
               '__DATA__',
               $template
        ;

open my $fh, '>', $outfile
    or die "Couldn't create '$outfile': $!";
binmode $fh;
print {$fh} join '', @prepend, $source;

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
