#! /usr/bin/env perl
BEGIN {
    require Text::NSP;
}

use strict;
use warnings;
use feature 'say';

use Data::Printer;
use File::Path qw(make_path);
use File::Temp qw(tempfile tempdir);
use Getopt::Long;

#######################
# forward declaration
sub count($$);
sub statistic();
sub usage();

#######################
# global variables
our $tmp_dir = tempdir(CLEANUP => 1);
our $freq_dir = join('/', $tmp_dir, "freq");
our $stat_dir = join('/', $tmp_dir, "stat");
our @tokens  = qw(POS TAGGED LEMMA);
our @statistics = qw(ll x2);
our @freq_files;

#######################
# Options
my $corpus_file;
my $corpus;     # need for database.pl
my $help;

GetOptions(
    'file=s' => \$corpus_file,
    'corpus=s' => \$corpus,
    'help'  => \$help
);

#######################
# working

usage() if($help);
unless ($corpus_file) {
    say 'no corpus file';
    usage();
}

unless ($corpus) {
    say "no corpus name!\n
    Disable cleanup of temp directory.\n
    Run database Script manually.";
    $tmp_dir = tempdir(CLEANUP => 0);
}

say '--------------- Build Corpusinforations -------------------';

say "Temp directory: $tmp_dir";
say "Input file: $corpus_file";

make_path($freq_dir);
make_path($stat_dir);

my $filename = $corpus_file;
$filename =~ s/\.[^.]+$//;
count($corpus_file, $filename);
statistic();

say "Temp directory: $tmp_dir";

if ($corpus) {
    system("perl ./database.pl -corpus=$corpus -sdir=$tmp_dir -wdir=data -fileprefix=$filename");
}

#####################
# subroutines

sub usage() {
    say "usage: [APP] [-h] [-c corpus -f corpus_file]
    -c, -corpus\tname of the corpus
    -f, -file\t\tname of the corpus file
    -h, -help\t\tthis text";
    exit;
}

sub count ($$) {
    my $file     = shift;
    my $filename = shift;

    for my $token (values @tokens) {
        for my $window (qw(2 3 4 5 6 7 8 9 10)) {
            my $ofile = "$filename.$token.w$window";
            say 'excute system begin';
            say "Tokenfile: $token";
            say "Windowsize: $window";
            say "Outputfile: $ofile";
            system("perl assert/count.pl --window $window --token Token/VRT/$token $freq_dir/$ofile $corpus_file");
            say 'excute system end';
            push @freq_files, $ofile;
        }
    }
};

sub statistic () {
    for my $statistic (@statistics) {
        for my $ifile (@freq_files) {
            my $ofile = "$ifile.$statistic";
            say "Outputfile: $ofile";
            system("perl assert/statistic.pl $statistic $stat_dir/$ofile $freq_dir/$ifile");
        }
    }
};
