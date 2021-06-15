#!/usr/bin/perl
use warnings;
use strict;
use Cwd;
$|++;

my $parent_dir = getcwd();
# warn "Parent dir is: $parent_dir\n\n";

my @files = glob ("*repeat_family_report.txt");
print "Files to be combined are:\n",join("\n",@files),"\n\n";

my %results; # storing all names and counts
 
my $out = 'repeat_family_summary_report.txt';
open (OUT,'>',$out) or die "Can't write outfile to $out: $!\n\n";

for my $file (@files){
    next unless (-f $file); # only interested in files
    
    my $extract = 0;
    my $total; #storing the total number of sequences
    
    open (IN,$file) or die  "Can't read from file $file: $!\n\n"; 

    my $count = 0;

    while (<IN>){
	chomp;
	if ($extract == 0){ # we have not reached the repeat alignment summary

	    if ($_ =~ /^total/){ # getting the total number of sequences in that file
		my ($el1,$el2) = (split (/\t/));
		# warn "$el1~~\n$el2~~\n";
		$total = $el2;
		next;
	    }

	    if ($_ =~ /^Number of sequences/){
		$_ = <IN>; # extra empty lane
		$_ = <IN>; # header line. Everything from here will be repeat elements and their aligment count
		++$extract;
		# warn "$_\n";
	    }
	    else{
		next;
	    }
	}
	else{
	    # All elements here should be repeat elements and their alignment count
	    my ($el1,$el2) = (split (/\t/));
	    # warn "$el1\t$el2\n~~~~~\n";
	    ++$count;	 
	    $results{$file} -> {1}      -> {total}   = $total; # total counts
	    $results{$file} -> {$count} -> {element} = $el1;
	    $results{$file} -> {$count} -> {count}   = $el2;
	}
	#  warn "Changed into directory: $dir\n";
    }
}

# REFORMATTING THE DATA

my %reformat;
my $element = 1; # element 1 are the filenames

### ADDING FILENAMES
push @{$reformat{$element}}, "";  # first element of the header line is empty
foreach my $file(sort keys %results){
    push @{$reformat{$element}}, $file;    
}

my @elements;
foreach my $file(sort keys %results){
    foreach my $entry (sort {$a<=>$b} keys %{$results{$file}}){
	push @elements, $entry;
    }
    last; # needed only once
}  
# print "Number of elements:\n",join ("\t",@elements),"\n\n";

### ADDING REPEAT COUNTS
foreach my $number(@elements){
    $element += $number;
    #   print "$number\n";
    #sleep(1);
    my $file_number = 0;
    foreach my $file(sort keys %results){
	++$file_number;
	if ($file_number == 1){ # for the first file we also print the repeat element name
	    #  	    print "$results{$file}->{$number}->{element}\t";
	    #	    print "$results{$file}->{$number}->{count}\t"; 
	    push @{$reformat{$element}}, $results{$file}->{$number}->{element};
	    push @{$reformat{$element}}, $results{$file}->{$number}->{count};
	}
	else{
	    # print "$results{$file}->{$number}->{count}\t";
	    push @{$reformat{$element}}, $results{$file}->{$number}->{count};
	}
    }
}

### ADDING THE TOTAL COUNT PER FILE
# once we are done we also print the total number of that file

$element += 1; 
my $file_number = 0;
foreach my $file(sort keys %results){
    ++$file_number;
    if ($file_number == 1){
	push @{$reformat{$element}}, "Total";
	push @{$reformat{$element}}, $results{$file}->{1}->{total};
    }
    else{
	# print "$results{$file}->{$number}->{count}\t";
	push @{$reformat{$element}}, $results{$file}->{1}->{total};
    }
}

################################################

### Printing the reformatted data structure
foreach my $line (sort {$a<=>$b} keys %reformat){
    foreach my $index (0..$#{$reformat{$line}}){
	# print "index: $index\t$reformat{$line}[$index]"; sleep(1);
	print "$reformat{$line}[$index]";
	print OUT "$reformat{$line}[$index]";
	
	if  ($index == $#{$reformat{$line}}){
	    print OUT "\n";  
	    print "\n";
	}
	else{
	    print OUT "\t";  
	    print "\t";
	}
    }
}

### example input file

#Total summary of sequences aligning to repeats (lane3195_ACAGTGGT_TS_Ap2gamma_L004_R1_val_1.fq)
#
#        number of seqs  percent of total
#aligning to repeats     17047790        32.1
#not aligning to repeats 35980221        67.9
#total   53028011        100.0
#
#
#Number of sequences aligning to individual classes of repeats (multiple hits possible)
#
#        number of seqs
#LINE_L1 7729616
#LINE_L2 213911
#LTR_ERV1        718050
#LTR_ERVK        3068667
# ...
