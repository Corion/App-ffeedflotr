package App::Ffeedflotr;
use strict;
use vars qw($VERSION);
use WWW::Mechanize::Firefox;
use Time::Local;
use Time::HiRes qw(sleep);
use File::Temp qw(tempfile);
use List::Util qw(min);

$VERSION = '0.01';

=head1 NAME

App::Ffeedflotr - plot data in Firefox using flot

=head1 SYNOPSIS

This module currently is just a placeholder
to accompany the C<ffeedflotr.pl> program in this
distribution.

=cut

sub new {
    my ($class, %options) = @_;
    
    my @passthrough = qw(tab autoclose);
    my %mech_opts = map { 
                        exists $options{ $_ }
                        ? ($_ => delete $options{ $_ })
                        : ()
                    } @passthrough;
    
    $options{ mech } = WWW::Mechanize::Firefox->new(
        create => 1,
        activate => 1,
        %mech_opts
    );
    
    my @colinfo;
    
    for (@{ delete $options{ legend } || []}) {
        /(.*?)=(.*)/
            or warn "Ignoring malformed legend [$_]", next;
        $colinfo[ $1 ] ||= {};
        $colinfo[ $1 ]->{label} = $2;
    };
    for (@{ delete $options{ color } || [] }) {
        /(.*?)=(.*)/
            or warn "Ignoring malformed color [$_]", next;
        $colinfo[ $1 ] ||= {};
        $colinfo[ $1 ]->{color} = $2;
    };
    $options{ colinfo } = \@colinfo;
    $options{ type } ||= 'line';
    
    bless \%options => $class;
}

sub mech { $_[0]->{mech} }

sub configure_plot {
    my ($self, %options) = @_;
    my @defaults = (qw(template width height background pie_start_angle xmax ymax type));
    for (@defaults) {
        $options{ $_ } ||= $self->{ $_ };
    }

    # Write the tempfile for Firefox
    my ($fh,$tempname) = tempfile();
    binmode $fh;
    print {$fh} ${ $options{ template } };
    close $fh;
    
    my $mech = $self->mech;
    
    # XXX URI::file->new();
    $tempname = "file:///$tempname";
    $mech->get($tempname);

    # Now, resize the container in our template
    my $container = $self->{container} = $mech->by_id('plot1', single => 1);
    $container->{style}->{width} = $options{ width };
    $container->{style}->{height} = $options{ height };
    # Set the page title
    $mech->document->{title} = $options{ title };

    my $type;
    (my $xaxis, $type) = $mech->eval_in_page("plotConfig.xaxis");
    (my $yaxis, $type) = $mech->eval_in_page("plotConfig.yaxis");
    (my $lines, $type) = $mech->eval_in_page("plotConfig.lines");
    (my $series, $type) = $mech->eval_in_page("plotConfig.series");
    
    if ($options{ background }) {
        my $plot1 = $mech->by_id('plot1', single => 1 );
        $plot1->{style}->{backgroundImage} = "url($options{ background })";
    };
    
    if ($options{ type } eq 'pie') {
        $series->{pie}->{show} = 1;
        $series->{pie}->{startAngle} = $options{ pie_start_angle };
    } elsif ($options{ type } eq 'scatter') {
        $lines->{show} = 0;
    };
    
    $lines->{fill} = $options{ fill };
    
    # XXX guess time from first 10 elements of data?!
    if ($options{ 'time' }) {
        $xaxis->{mode} = "time";
        $xaxis->{timeformat} = $options{ timeformat };
    };
    
    if ($options{ xmax }) {
        $xaxis->{max} = $options{ xmax };
    };
    
    if ($options{ ymax }) {
        $yaxis->{max} = $options{ ymax };
    };

}

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

sub parse_row {
    my ($self,$line) = @_;
    local $_ = $line;
    s/^\s+//;
    [ map {s/^\s+//; $_ } split /$self->{separator}/ ]
};

sub read_available_input {
    my ($self, $pipe) = @_;
    
    # Just spawn a thread
    # to asynchronously read from the filehandle
    if (! $self->{input}) {
        require threads;
        require Thread::Queue;
        my $queue = $self->{input} = Thread::Queue->new();
        threads::async(sub {
            $queue->enqueue( "$_" ) # make an explicit copy, again
                while(<$pipe>);
            $queue->enqueue( undef );
        })->detach;
    };

    my $q = $self->{input};
    my @res = $q->dequeue; # block for at least one item
    # And fetch all items that are available right now
    while ($q->pending) {
        push @res, $q->dequeue($q->pending);
    };
    @res
}

sub detect_separator {
    my ($self, %options) = @_;
    my $data = $options{ data };
    my @candidates = @{ $options{ candidates } || [qr/\t/,qr/,/,qr/;/,qr/\s+/]};
    my $rowcount = $options{ sample };
    
    my $separator;
    
    my $rowcount = min( $#$data, $rowcount ); # only check the first lines
    CANDIDATE: for my $candidate (@candidates) {
        my $colcount =()= $data[0] =~ /($candidate)/g;
        if ($colcount) {
            for (@data[ 1..$check_limit ]) {
                my $newcount =()= /($candidate)/g;
                next CANDIDATE
                    if ($newcount != $colcount);
            };
            $separator = $candidate;
            last CANDIDATE;
        };
    };
    $separator
}

sub plot {
    my ($self,@data) = @_;
    
    $self->{ separator } ||= $self->detect_separator(
        data => \@data,
    );
    @data = map { $self->parse_row( $_ ) } @data;
    
    # Keep only the latest elements
    if ($self->{xlen} and @data > $self->{xlen}) {
        splice @data, 0, 0+@data-$self->{xlen};
    };
    
    # Split up multiple columns (x,y1,y2,y3) into (x,y1),(x,y2),...
    my @sets;
    for my $col (1..$#{$data[0]} ) {
        push @sets, [ map { [ $self->{'time'} ? ts $_->[0] : 0+$_->[0], 0+$_->[$col]] } @data ];
    };

    my $idx = 0;
    my $data = [
        map { $idx++; +{
                  #"stack" => $idx, # for later, when we support stacking data
                  "data"  => $_,
                  hoverable => 1,
                  "id"    => $idx, # for later, when we support multiple datasets
                  # Other, user-specified data
                  %{ $self->{colinfo}->[ $idx ] || {} },
    }} @sets];
    
    my ($setupPlot, $type) = $self->mech->eval_in_page("setupPlot");
    $setupPlot->($data);
}

sub get_png {
    my ($self) = @_;
    my $png = $self->mech->element_as_png($self->{container});
}

sub save_png {
    my ($self,$outfile) = @_;
    open my $out, '>', $outfile
        or die "Couldn't create '$outfile': $!";
    binmode $out;
    print {$out} $self->get_png;
}

1;