#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use Data::Printer;
use File::Path qw(make_path remove_tree);
use Getopt::Long;
use Mojo::JSON qw(encode_json);
use Storable qw(store_fd fd_retrieve);

#######################
# forward declaration
sub build_db($);
sub get_corpus($$$);
sub get_statistic($$);
sub usage();
sub _store($$);
sub _hash_to_json($);

#######################
# Options
my $src_dir;
my $work_dir;
my $fprefix;
my $corpus;
my $help;

GetOptions(
    'wdir=s' => \$work_dir,
    'sdir=s' => \$src_dir,
    'corpus=s' => \$corpus,
    'fileprefix=s' => \$fprefix,
    'help'  => \$help
);

usage() if($help);

unless ($work_dir) {
    say "No working directory defined!";
    usage();
}

unless ($fprefix) {
    say "No file prefix defined!";
    usage();
}

unless ($corpus) {
    say "No corpus defined!";
    usage();
}

our $tmp_dir = '';
if (defined $src_dir) {
    $tmp_dir = $src_dir;
} else {
    $tmp_dir = $work_dir;
}


#######################
# global variables
our $freq_dir   = join('/', $tmp_dir, "freq");
our $stat_dir   = join('/', $tmp_dir, "stat");
our $db_dir     = join('/', $work_dir, "corpus");
our $db_corpus_dir = join('/', $db_dir, $corpus);
our @tokens     = qw(POS WORDFORMS LEMMA);
our @statistics = qw(ll x2);
our @freq_files;

#######################
# working

say '--------------- Build Database -------------------';

make_path($db_dir);
build_db($fprefix);

#######################
# subroutines

sub usage() {
    say "usage: [APP] [-h] [-c corpus -f corpus_file]
    -c, -corpus\tname of the corpus
    -f, -fileprefix\tprefix of the corpus file (mostly the string to the last dot)
    -s, -sdir\tsource directory
    -w, -wdir\tworking directory
    -h, -help\t\tthis text";
    exit;
}

sub build_db($) {
    my $fprefix  = shift;
    remove_tree($db_corpus_dir);
    make_path($db_corpus_dir);

    my $db_struct = {};
    for my $token (@tokens) {
        for my $windowSize (qw(2 3 4 5 6 7 8 9 10)) {
        #for my $windowSize (qw(10)) {
            my $corpus_struct = {};
            $db_struct->{$token}->{$windowSize} = join('_', $token, $windowSize);
            $corpus_struct = get_corpus($fprefix, $token, $windowSize);
            #my $corpus_json = _hash_to_json($corpus_struct);
# XXX create db struct.
            _store($corpus_struct, join('/', $db_corpus_dir,
                        $db_struct->{$token}->{$windowSize}));
        }
    }

    #my $db_json = _hash_to_json($db_struct);
    _store($db_struct, join('/', $db_corpus_dir, ".meta"));
}

sub get_corpus($$$) {
    my $fprefix     = shift;
    my $token       = shift;
    my $windowSize  = shift;
    my $corpus_struct = {};
    my $ifile = "$fprefix.$token.w$windowSize";
    say $ifile;
    open my $MFH, "<:encoding(UTF-8)", join('/', $freq_dir, $ifile)
        or die "Can't read file: $!\nDirectory: $freq_dir";

    while (<$MFH>) {
        my ($n1, $n2, $ctotal, $cn1, $freq) = undef;
        chomp;
        ($n1, $n2, $freq) = split /<>/, $_;
        unless ($n2) {
            $corpus_struct->{ctotal} = $n1;
            next;
        }

        ($ctotal, $cn1)   = split / /, $freq;
        $corpus_struct->{$n1}->{cn1} = $cn1;
        $corpus_struct->{$n1}->{$n2}->{ctotal} = $ctotal;
        push @{$corpus_struct->{$n2}->{rel}}, $n1;
    }
    $corpus_struct = get_statistic($ifile, $corpus_struct);

    close $MFH;
    undef $ifile;
    return $corpus_struct;
}

sub get_statistic ($$) {
    my $filename        = shift;
    my $corpus_struct   = shift;
    for my $sig_value (@statistics) {
        my $iStatFile = "$filename.$sig_value";
        say $iStatFile;
        open my $MFH, "<:encoding(UTF-8)", join('/', $stat_dir, $iStatFile)
            or die "Can't read file: $!\nDirectory:$stat_dir";
        while (<$MFH>) {
            chomp;
            my ($n1, $n2, $prio, $stat_value) = undef;
            my $numbers;
            ($n1, $n2, $numbers) = split /<>/, $_;
            next unless ($n2);
            ($prio, $stat_value)   = split / /, $numbers;

            $corpus_struct->{$n1}->{$n2}->{statistic}->{$sig_value} = {
                priority    =>  $prio,
                value       =>  $stat_value
            };
        }
        close $MFH;
    }
    return $corpus_struct;
}


#TODO Test for _store
sub _store($$) {
    my $data        =   shift;
    my $location    =   shift;

    open  my $FH , ">", $location || return undef;
    store_fd \$data, $FH;
    close $FH;
}

sub _hash_to_json ($) {
    my $meta_struct         = shift;
    my $json_bytes          = encode_json($meta_struct);
    return $json_bytes;
}

