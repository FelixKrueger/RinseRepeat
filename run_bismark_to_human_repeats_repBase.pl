#!/usr/bin/perl
use warnings;
use strict;

# This script runs Bismark against the following human repeat consensus sequences: LINE, SINE, Satellites, other LTR, HERV1, HERVK, HERVL and Unknown
# last modified 12 02 2015

my @files = glob('*fq.gz');
my $count = 0;

# my $pbat = '--pbat';
my $pbat = ''; # use this for directional libraries
my $prefix;

foreach my $index (0..$#files) {
    $count++;
    
     ### 
    $prefix = 'DNA_transposons';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/DNA_transposons/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'HERV1';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/HERV1/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'HERVK';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/HERVK/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'HERVL';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/HERVL/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'LINE';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/LINE/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### 
    $prefix = 'other_LTR';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/other_LTR/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
    ### 
    $prefix = 'Satellites';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/Satellites/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
    ### 
    $prefix = 'SINE';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/SINE/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
    ### 
    $prefix = 'Unknown';
    system "echo \"bismark $pbat --bowtie2 --prefix $prefix --bam /bi/scratch/Genomes/Human/GRCh37/Repeatome/repBase_consensus_genomes/Unknown/ $files[$index] \" | qsub -b n -cwd -V -l h_vmem=2G -pe orte 3 -N bm_$prefix.$count -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
    
}
