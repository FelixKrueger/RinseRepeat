#! /usr/bin/perl
use strict;
use warnings;
use IO::Handle;
use Getopt::Long;
$|++;

## This script takes in 10X Illumina sequence files and aligns them the various classes of mouse repeats individually.
## FastQ file need to contain a Cell-Barcode field in the read header (no spaces) as the very last element, e.g.:
## @A00489:350:HJLCVDRXX:1:2101:2275:1235_2:N:0:TAGGACGT_CB:TCTACATCACGGCACT
## so that we can score single cells individually. The script "transferCellID_to_readID_bcl2fastq_style.py" adds the
## cell barcode to the readID (as CB:CELLBARCODESQUENCE (16bp))

## last modified on June 16, 2021

my $cutoff;  # we don't want to report every cell if it didn't have a total number of reads of Hmm. 10?
GetOptions ( "cutoff=i"  => \$cutoff ) or die "Failed to read options\n";

unless (defined $cutoff){
	$cutoff = 10;
}

my @filenames = @ARGV;
unless (@filenames){
  die "\nUSAGE is:\n\n  mouse_repeat_family_analysis_10X.pl (--cutoff [10]) <filenames>
  
  e.g.: mouse_repeat_family_analysis_10X.pl 10X_FastQ_file_with_CellBarcodes(_trimmed).fq.gz\n\n";
}



foreach my $filename (@filenames){
    align_fragments_to_the_mouse_repeatome ($filename);
}

sub align_fragments_to_the_mouse_repeatome {

    my $filename = shift; 
    warn "\nInput filename: $filename\n";
    my $outfile = my $cellbarcodes_file = $filename;
    
    die "Please check renaming settings!" unless ($outfile =~ s/(fq$|fastq$|fastq\.gz$|fq\.gz$)/10X_repeat_family_report.txt/);
	die "Please check renaming settings!" unless ($cellbarcodes_file =~ s/(fq$|fastq$|fastq\.gz$|fq\.gz$)/cellwise_repeat_content.txt/);
	
	warn "Writing output to file: $outfile\n\n";
	
	open (OUT,'>',$outfile) or die "Failed to open filehandle for overview file $outfile: $!";
	open (CB,'>',$cellbarcodes_file) or die "Failed to open filehandle for $cellbarcodes_file: $!";
	

    # Creating a datastructure to store Repeat types, the location where the index for the 'repeat-genome' is located, filehandles for the Bowtie alignments
    # and the number of times the sequences were seen
    my @fhs = (
		{ 	name => 'LINE_L1',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LINE_L1/LINE_L1.N_sep',
		},
		{ 	name => 'LINE_L2',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LINE_L2/LINE_L2.N_sep',
		},
		{ 	name => 'LTR_ERV1',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERV1/LTR_ERV1.N_sep',
		},
		{ 	name => 'LTR_ERVK',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERVK/LTR_ERVK.N_sep',
		},
		{ 	name => 'LTR_ERVL',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERVL/LTR_ERVL.N_sep',
		},
		{ 	name => 'LTR_MaLR',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_MaLR/LTR_MaLR.N_sep',
		},
		{ 	name => 'major_satellite',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/major_satellite/major_satellite.N_sep',
		},
		{ 	name => 'minor_satellite',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/minor_satellite/minor_satellite.N_sep',
		},
		{ 	name => 'rRNA',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/rRNA/rRNA.N_sep',
		},
		{ 	name => 'SINE_Alu_B1',                                                                                                                     
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_Alu_B1/SINE_Alu_B1.N_sep',                                                           
		},    
		{ 	name => 'SINE_B2',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_B2/SINE_B2.N_sep',
		},
		{ 	name => 'SINE_B4',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_B4/SINE_B4.N_sep',
		},
		{ 	name => 'telomere',
			repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/telomere/telomere',
		},
		{ 	name => 'IAP',
			repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/IAP/IAP',
		},

	);
  
	# Now starting several instances of Bowtie2 feeding in the sequence file, one for every type of repeat and reading in the sequence identifier 
	# for the first sequence for which an alignment was found in the data structure above.
	
	warn "Now running Bowtie2 against several different repeat families\n\n";
	
	foreach my $fh (@fhs){

		open ($fh->{fh},"bowtie2 --no-head -x $fh->{repeat_index} -U $filename |") or die "Can't open pipe to bowtie2: $!";
		
		warn "Now starting Bowtie2 for $fh->{name} repeats\n";
		$_ = $fh->{fh}->getline();  ### this is a workaround because = <$fh->{fh}>; fails inside the magic brackets. Another way would be to put the ###
		### dereferenced filehandle into a new string like   my $temp = $fh->{fh};  my $_ =<$temp>; ###
		if ($_){
			my ($id,$flag) = (split(/\t/))[0,1]; # this is the first element of the bowtie output (= the sequence identifier)
			# warn "$id\t$flag\n"; sleep(1);
			# assigning the identifier of the first bowtie Output line to last_seq_id
			$fh->{last_seq_id} = $id; # put into the data structure as last_seq_id
			$fh->{last_seq_flag} = $flag;
		}
		else{
			$fh->{last_seq_id} = undef;
			$fh->{last_seq_flag} = undef;
		}
	}
	
	my %cellbarcodes = (); # This dictionary will store the final repeat matrix
	
	# Reading in the sequence FastQ file and checking if the sequence could be aligned to one or more of the different repeat types
	if ($filename =~ /gz$/){
		open (IN,"zcat $filename | ") or die $!;
	}
	else{
		open (IN,$filename) or die $!;
	}
	warn "\nReading in the sequence file $filename\n";
	
	my $not_aligning_to_repeats_counter = 0;
	my $count = 0;
	my $sequence_is_aligning_to_repeats; # works as switch
  
  	while (1){
		my $identifier = <IN>;
		my $sequence = <IN>;
		my $identifier_2 = <IN>;
		my $quality_value = <IN>;
		#remember this checks if the 4 scalars are true, so 0 or blank will exit here
		last unless ($identifier and $sequence and $identifier_2 and $quality_value);
		
		++$count;
		if ($count%250000==0){
			warn "Processed $count sequences so far\n";
		}

    	chomp $identifier;
		$identifier =~ s/^\@//; # deletes the @ in the beginning
		
		$sequence_is_aligning_to_repeats = 0; # default is unaligned
		
		$identifier =~ s/\s.*$//; # deletes everything from the first whitespace. Shouldn't be required here
		# warn "$identifier\n"; 
		# Extracting the Cell Barcode (CB) identifier. This should be CB:TCTACATCACGGCACT (16bp)
		my $cb = substr($identifier,-19,19);
		# warn "$cb\n";
		$cellbarcodes{$cb}->{total}++;
		
		# Now reading from the filehandles to see if this sequence aligned to a repeat type

		foreach my $index (0..$#fhs){
	    	
			# only relevant if there was an alignment at all
			if ($fhs[$index]->{last_seq_id}){ 
			
				if ($fhs[$index]->{last_seq_id} eq $identifier){
			
					if ($fhs[$index]->{last_seq_flag} == 4){ # sequence unmapped
						# warn "sequence unmapped\n"; sleep(1);
					}
					else{
						# if the sequence was not unmapped, it did map... Duh
						$fhs[$index]->{alignments}->{$cb}->{seen}++;
						$sequence_is_aligning_to_repeats = 1;
					}
					
					# Attempting to read a new line
					my $newline = $fhs[$index]->{fh}->getline();
					if ($newline){
						my ($id,$flag) = (split (/\t/,$newline))[0,1]; ## need to split the first element into a list, or it will produce the length of the list.... -> ()
				
						# if the sequence identifier was found, we are going to read in the next line from the filehandle and replace the last_seq_id for that repeat type
						$fhs[$index]->{last_seq_id}   = $id;
						$fhs[$index]->{last_seq_flag} = $flag;
					}
					else{
						# skips if the end of the file was reached
						$fhs[$index]->{last_seq_id}   = undef;
						$fhs[$index]->{last_seq_flag} = undef;
						next;
					}	 
				}
				else{
					warn "This shouldn't happen for Bowtie2 alignments....";
				}
			}
		}
   
    	++$not_aligning_to_repeats_counter unless ($sequence_is_aligning_to_repeats == 1);

  	}	

	# Number of sequences in the sequence file
	warn "Total number of sequences processed: $count\n\n";
	close (IN) or die "Failed to closed IN filehandle: $!";

  	# Now writing the whole report to an output file
	
	my $number_of_sequences_aligning_to_repeats = $count-$not_aligning_to_repeats_counter;
	my $percentage_aligning_to_repeats = sprintf ("%.1f",100*$number_of_sequences_aligning_to_repeats/$count);

	### We will create an output file which can be directly used in Excel to produce graphs from it
	
	### Firstly, a general report: How many sequences in the the file did align vs. did not align to any repeat(s)

	print "Total summary of sequences aligning to repeats ($filename)\n\n";
	print join ("\t",'','number of seqs','percent of total'),"\n";
	print join ("\t",'aligning to repeats',"$number_of_sequences_aligning_to_repeats","$percentage_aligning_to_repeats"),"\n";
	print join ("\t",'not aligning to repeats',$not_aligning_to_repeats_counter,sprintf("%.1f",100-$percentage_aligning_to_repeats)),"\n";
	print join ("\t",'total',"$count",'100.0'),"\n\n";

	print OUT "Total summary of sequences aligning to repeats ($filename)\n\n";
	print OUT join ("\t",'','number of seqs','percent of total'),"\n";
	print OUT join ("\t",'aligning to repeats',"$number_of_sequences_aligning_to_repeats","$percentage_aligning_to_repeats"),"\n";
	print OUT join ("\t",'not aligning to repeats',$not_aligning_to_repeats_counter,sprintf("%.1f",100-$percentage_aligning_to_repeats)),"\n";
	print OUT join ("\t",'total',"$count",'100.0'),"\n\n";
	
	### And secondly a more detailed report of How many sequences aligned the individual types of repeats (this does allow mulitple hits per sequence)
	
	### Initialising the cell barcode centric repeat counts
	warn "Initialising the cell barcode centric repeat counts\n";
	foreach my $cbc (keys %cellbarcodes){
		# warn "$cbc\n";
		foreach my $index (0..$#fhs){
			# Initialising each repeat class for each cell with a count of 0
			$cellbarcodes{$cbc}->{repeats}->{$fhs[$index]->{name}} = 0;
		}	
	}
	warn "Done\n\n";

	### Scoring repeat content per cell
	warn "Aggregating repeat alignments per cell\n";
	foreach my $fh (@fhs){
		# warn "$fh->{name}\n";
		foreach my $cell (keys %{$fh->{alignments}}){
			# warn "$fh->{name}\t$cell\t$fh->{alignments}->{$cell}->{seen}\n";
			$cellbarcodes{$cell}->{repeats}->{$fh->{name}} += $fh->{alignments}->{$cell}->{seen};
		}
	}

	warn "Done\n\n";

	### FINAL REPORTING
	warn "Printing full list of Cell Barcodes and their repeat alignment status to file: $cellbarcodes_file\n";
	
	my @headerlines = ("cell barcode","total reads");
	foreach my $index (0..$#fhs){
		# print "$fhs[$index]->{name}\t";
		push @headerlines, $fhs[$index]->{name};
	}	
	# warn join ("\t",@headerlines),"\n";
	print CB join ("\t",@headerlines),"\n";
	my $reported = 0;

	foreach my $cellbarcode (sort {$cellbarcodes{$b}->{total} <=> $cellbarcodes{$a}->{total}} keys %cellbarcodes){
		# warn "$cellbarcode\n";
		if ($cellbarcodes{$cellbarcode}->{total} < $cutoff){
			last;
		}
		++$reported;
		print CB "$cellbarcode\t$cellbarcodes{$cellbarcode}->{total}\t";
		foreach my $index (0..$#fhs){
			my $repeatclass = $fhs[$index]->{name};
			# print CB "$repeatclass\t$cellbarcodes{$cellbarcode}->{repeats}->{$repeatclass}\t";
			print CB "$cellbarcodes{$cellbarcode}->{repeats}->{$repeatclass}\t";
			# sleep(1);
		}
		print CB "\n";
	}
	warn "All done. Enjoy.\n\n";
	
	print "Number of cells (i.e. Cell Barcodes) detected in total: ",scalar keys %cellbarcodes,"\n";	
	print "Number of cells had at least $cutoff reads and were reported: $reported\n\n";
	print OUT "Number of cells (i.e. Cell Barcodes) detected in total: ",scalar keys %cellbarcodes,"\n";	
	print OUT "Number of cells had at least $cutoff reads and were reported: $reported\n\n";

	close OUT or die "Failed to close filehandle OUT: $!";
	close CB  or die "Failed to close filehandle CB: $!";

}

