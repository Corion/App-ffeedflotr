# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $lib = 'App::Ffeedflotr';

(my $main_base = $lib) =~ s!::|'!/!g;
my $main_module = "$main_base.pm";
(my $main_repo = lc $lib) =~ s/\W+/-/g;

# I should maybe use something like Shipwright...
regen_README("lib/$main_module");
regen_EXAMPLES("lib/$main_base/Examples.pm");

my @tests = map { glob $_ } 't/*.t', 't/*/*.t';

WriteMakefile1(
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/Corion/' . $main_repo,
        },
    },
    BUILD_REQUIRES => {
                        #'Task::Weaken' => 0, #to be sure that weaken is present
    },
    'NAME'          => $lib,
    'LICENSE'       => 'perl',
    'VERSION_FROM'  => "lib/$main_module", # finds $VERSION
    'PREREQ_PM'     => {
                       'WWW::Mechanize::Firefox' => 0.45, # ->by_id()
                       'List::Util' => 0, # for min()
                       'File::Temp' => 0, # for tempfile()
                       'Time::Local' => 0,
                       # threads - if you want nonblocking streaming
                       # Thread::Queue - ditto
                      }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM   => "lib/$main_module", # retrieve abstract from module
    AUTHOR          => 'Max Maischein <corion@cpan.org>',
    test            => { TESTS => join( ' ', @tests ) },
);

1;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;
    
    WriteMakefile(%params);
}

sub regen_README {
    eval {
        require Pod::Readme;

        my $parser = Pod::Readme->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0], 'README');
    };
    eval {
        require Pod::Markdown;

        my $parser = Pod::Markdown->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0]);
        open my $fh, '>', 'README.mkdn'
            or die "Couldn't open 'README.mkdn': $!";
        print $fh $parser->as_markdown;
    };
}


sub regen_EXAMPLES {
    my ($target) = @_;
    my $perl = $^X;
    if (-d 'examples') {
        warn "(Re)Creating $target\n";
        if ($perl =~/\s/) {
            $perl = qq{"$perl"};
        };
        my $examples = `$perl -w examples/gen_examples_pod.pl`;
        if ($examples) {
            $examples =~ s/\r\n/\n/g;
            if (open my $out, '>', "$target") {
                binmode $out;
                print $out $examples;
            };
        };
    };
};