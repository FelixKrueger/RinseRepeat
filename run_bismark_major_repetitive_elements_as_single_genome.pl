#!/usr/bin/perl
use warnings;
use strict;

# This script runs Bismark against the following repeat consensus sequences as one genome: IAP, L1A, L1Tf, SINEB1, Major satellites, Minor satellites, MuERV-L, MuLV LTR and EtnI LTR

my @files = glob('*fq.gz');
my $count = 0;

 my $pbat = '--pbat';
# my $pbat = ''; # use this for directional libraries
my $prefix;

foreach my $index (0..$#files) {
    $count++;
    ### 
    $prefix = 'MultiRepeats';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/MultiRepeatGenome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=3G -pe orte 5 -p -1000 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

}
