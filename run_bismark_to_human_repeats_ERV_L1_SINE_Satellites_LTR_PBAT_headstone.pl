#!/usr/bin/perl
use warnings;
use strict;

# This script runs Bismark against the following human repeat consensus sequences: L1, SINE, Satellites, LTR and ERV
# Adapted to work with SLURM on Headstone, Dec 05, 2019

my @files = glob('*fq.gz');
my $count = 0;

my $pbat = '--pbat';
# my $pbat = ''; # use this for directional libraries
my $prefix;

foreach my $index (0..$#files) {
    $count++;
    
    ### 
    $prefix = 'ERV';
    system ("ssub --mem=2G -c3 -o $files[$index].$prefix.log --email bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/${prefix}_bisulfite_genome/ $files[$index]");
    
    ### 
    $prefix = 'L1';
    system ("ssub --mem=2G -c3 -o $files[$index].$prefix.log --email bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/${prefix}_bisulfite_genome/ $files[$index]");
    
    ### 
    $prefix = 'SINE';
    system ("ssub --mem=2G -c3 -o $files[$index].$prefix.log --email bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/${prefix}_bisulfite_genome/ $files[$index]");
    
    ### 
    $prefix = 'Satellite';
    system ("ssub --mem=2G -c3 -o $files[$index].$prefix.log --email bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/${prefix}_bisulfite_genome/ $files[$index]");
    
    ### 
    $prefix = 'LTR';
    system ("ssub --mem=2G -c3 -o $files[$index].$prefix.log --email bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/${prefix}_bisulfite_genome/ $files[$index]");
    
}
