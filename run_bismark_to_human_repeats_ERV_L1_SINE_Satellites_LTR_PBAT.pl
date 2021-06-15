#!/usr/bin/perl
use warnings;
use strict;

# This script runs Bismark against the following human repeat consensus sequences: L1, SINE, Satellites, LTR and ERV

my @files = glob('*fq.gz');
my $count = 0;

my $pbat = '--pbat';
# my $pbat = ''; # use this for directional libraries
my $prefix;

foreach my $index (0..$#files) {
    $count++;
    
    ### 
    $prefix = 'ERV';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/ERV_bisulfite_genome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
    ### 
    $prefix = 'L1';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/L1_bisulfite_genome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'SINE';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/SINE_bisulfite_genome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'Satellite';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/Satellite_bisulfite_genome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
    ### 
    $prefix = 'LTR';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/LTR_bisulfite_genome/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

}
