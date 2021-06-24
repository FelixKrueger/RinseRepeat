#!/usr/bin/perl
use warnings;
use strict;

my @files = glob('*1.92bp.fq.gz');
my $count = 0;

my $pbat = '--pbat';
# my $pbat = ''; # use this for directional libraries
my $prefix;
foreach my $index (0..$#files) {
    $count++;


    ### IAP
    $prefix = 'IAP';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/IAP/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### L1A
    $prefix = 'L1A';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/LINEs/L1A/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### L1Tf
    $prefix = 'L1Tf';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/LINEs/L1Tf/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### SINEB1
    $prefix = 'SINE_B1';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/SINE_B1_genome/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### Major satellites
    $prefix = 'Major_sat';
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/major_sat_miguel_supplied_extended_20bp/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].$prefix.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### Minor satellites
    $prefix = 'Minor_sat'; 
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/minor_satellites_1bp/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -p -1000 -o $files[$index].${prefix}.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### MuERV-L
    $prefix = 'MuERV-L'; 
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/MuERV-L/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -o $files[$index].${prefix}.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

    ### MuLV LTR
    $prefix = 'MuLV_LTR'; 
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/MuLV_LTR/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -o $files[$index].${prefix}.log -j y -m eas -M felix.krueger\@babraham.ac.uk";
 
    ### EtnI_LTR
    $prefix = 'EtnI_LTR'; 
    system "echo \"bismark $pbat --prefix $prefix --bam /bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/EtnI_LTR/ $files[$index] \" | qsub -cwd -V -l vf=2G -pe orte 6 -p -1000 -N bm_$prefix.$count -o $files[$index].${prefix}.log -j y -m eas -M felix.krueger\@babraham.ac.uk";

}
