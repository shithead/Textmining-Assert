#! /usr/bin/env perl
BEGIN {
    require Text::NSP;
}

use strict;
use warnings;
use feature 'say';

use Getopt::Long;
use File::Path qw(make_path);
use File::Temp qw(tempfile tempdir);
use Data::Printer;

#######################
# forward declaration
sub count($$);
sub statistic();

#######################
# globale variables
our $tmp_dir = tempdir(CLEANUP => 1);
#$tmp_dir = '/tmp/zni4LHx12n';
our $freq_dir = join('/', $tmp_dir, "freq");
our $stat_dir = join('/', $tmp_dir, "stat");
our @tokens  = qw(POS TAGGED LEMMA);
our @statistics = qw(ll x2);
our @freq_files;

#######################
# Options
my $corpus_file;

GetOptions(
    'file=s' => \$corpus_file
);

#######################
# working

unless ($corpus_file) {
    say 'no corpus file';
    exit;
}
say "Temp directory: $tmp_dir";
say "Input file: $corpus_file";

make_path($freq_dir);
make_path($stat_dir);

my $filename = $corpus_file;
$filename =~ s/\.[^.]+$//;
count($corpus_file, $filename);
statistic();

######################
# subroutines

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
