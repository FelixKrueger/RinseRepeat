#! /usr/bin/perl
use strict;
use warnings;
use IO::Handle;
$|++;

## this script takes in Illumina sequence files and aligns them the all classes of mouse repeats individually.
## last modified on Jan 2015 to run on the cluster

my @filenames = @ARGV;

foreach my $filename (@filenames){
  align_fragments_to_the_mouse_repeatome ($filename);
}


sub align_fragments_to_the_mouse_repeatome {
  my $filename = shift; 
  warn "\nInput filename: $filename\n";
  my $outfile = $filename;
  die "Please check renaming settings!\n\n" unless ($outfile =~ s/(fq$|fastq$|fastq\.gz$|fq\.gz$)/repeat_family_report.txt/);
  warn "Writing output to file: $outfile\n\n";

  # Creating a datastructure to store Repeat types, the location where the index for the 'repeat-genome' is located, filehandles for the Bowtie alignments
  # and the number of times the sequences were seen
  my @fhs = (
      { name => 'LINE_L1',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LINE_L1/LINE_L1.N_sep',
      },
      { name => 'LINE_L2',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LINE_L2/LINE_L2.N_sep',
      },
      { name => 'LTR_ERV1',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERV1/LTR_ERV1.N_sep',
      },
      { name => 'LTR_ERVK',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERVK/LTR_ERVK.N_sep',
      },
      { name => 'LTR_ERVL',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_ERVL/LTR_ERVL.N_sep',
      },
      { name => 'LTR_MaLR',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/LTR_MaLR/LTR_MaLR.N_sep',
      },
      { name => 'major_satellite',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/major_satellite/major_satellite.N_sep',
      },
      { name => 'minor_satellite',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/minor_satellite/minor_satellite.N_sep',
      },
      { name => 'rRNA',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/rRNA/rRNA.N_sep',
      },
      { name => 'SINE_B2',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_B2/SINE_B2.N_sep',
      },
      { name => 'SINE_B4',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_B4/SINE_B4.N_sep',
      },
      { name => 'SINE_Alu_B1',                                                                                                                                                                             
        repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/SINE_Alu_B1/SINE_Alu_B1.N_sep',                                                                                          }, 
      { name => 'telomere',
	repeat_index => '/bi/scratch/Genomes/Mouse/GRCm38/Repeatome/repeat_families_N_separated/telomere/telomere',
      }, 
      );
  
  # Now starting 12 instances of Bowtie feeding in the sequence file, one for every type of repeat and reading in the sequence identifier for the first
  # sequence where an alignment was found in the data structure above.
  
  warn "Now running Bowtie against several different repeat families\n\n";
  foreach my $fh (@fhs){
      if ($filename =~ /gz$/){
	  open ($fh->{fh},"zcat $filename | bowtie -k 1 $fh->{repeat_index} - |") or die "Can't open pipe to bowtie: $!";
      }
      else{
	  open ($fh->{fh},"bowtie -k 1 $fh->{repeat_index} $filename |") or die "Can't open pipe to bowtie: $!";
      }

      warn "Now starting the bowtie aligner for $fh->{name} repeats\n";
      $_ = $fh->{fh}->getline();  ### this is a workaround because = <$fh->{fh}>; fails inside the magic brackets. Another way would be to put the ###
      ### dereferenced filehandle into a new string like   my $temp = $fh->{fh};  my $_ =<$temp>; ###
      if ($_){
	  my $id = (split(/\t/))[0]; # this is the first element of the bowtie output (= the sequence identifier)
	  # assigning the identifier of the first bowtie Output line to last_seq_id
	  $fh->{last_seq_id} = $id; # put into the data structure as last_seq_id
      }
      else{
	  $fh->{last_seq_id} = '';
      }
  }

  # Reading in the sequence fastQ file and checking if the sequence could be aligned to one or more of the different repeat types

  open (IN,$filename) or die $!;
  warn "\nReading in the sequence file $filename\n";
  my $not_aligning_to_repeats_counter = 0;
  my $count=0;
  while (1){
    ++$count;
    # last if ($count > 50000);
    if ($count%250000==0){
      warn "Processed $count sequences so far\n";
    }
    my $identifier = <IN>;
    my $sequence = <IN>;
    my $identifier_2 = <IN>;
    my $quality_value = <IN>;
    #remember this checks if the 4 scalars are true, so 0 or blank will exit here
    last unless ($identifier and $sequence and $identifier_2 and $quality_value);
    chomp $identifier;
    $identifier =~ s/^\@//; # deletes the @ in the beginning
    my $sequence_is_aligning_to_repeats = 0;

    # reading from the filehandles to see if this sequence aligned to a repeat type

    foreach my $index (0..$#fhs){
      if ($fhs[$index]->{last_seq_id} eq $identifier){
	$fhs[$index]->{seen}++;
	$sequence_is_aligning_to_repeats = 1;
	my $newline = $fhs[$index]->{fh}->getline();
	next unless ($newline); # skips if the end of the file was reached
	my ($id) = split /\t/,$newline; ## need to split the first element into a list, or it will produce the length of the list.... -> ()
	
	# if the sequence identifier was found, we are going to read in the next line from the filehandle and replace the last_seq_id for that repeat type
	$fhs[$index]->{last_seq_id}=$id;
      }
    }
    ++$not_aligning_to_repeats_counter unless ($sequence_is_aligning_to_repeats == 1);

  }
  # Number of sequences in the s_.._.._sequence.txt file
  warn "Total number of sequences processed: $count.\n\n";
  close (IN) or die "Failed to closed filehandle: $!\n";

  # Now writing the whole report to an output file

  open (OUT,'>',$outfile) or die $!;
  my $number_of_sequences_aligning_to_repeats = $count-$not_aligning_to_repeats_counter;
  my $percentage_aligning_to_repeats = sprintf ("%.1f",100*$number_of_sequences_aligning_to_repeats/$count);

  # We will create an output file which can be directly used in Excel to produce graphs from it
  # Firstly a general report: How many sequences in the the file did align versus did not align to any repeats

  print "Total summary of sequences aligning to repeats ($filename)\n\n";
  print join ("\t",'','number of seqs','percent of total'),"\n";
  print join ("\t",'aligning to repeats',"$number_of_sequences_aligning_to_repeats","$percentage_aligning_to_repeats"),"\n";
  print join ("\t",'not aligning to repeats',$not_aligning_to_repeats_counter,sprintf("%.1f",100-$percentage_aligning_to_repeats)),"\n";
  print join ("\t",'total',"$count",'100.0'),"\n\n\n";

  print OUT "Total summary of sequences aligning to repeats ($filename)\n\n";
  print OUT join ("\t",'','number of seqs','percent of total'),"\n";
  print OUT join ("\t",'aligning to repeats',"$number_of_sequences_aligning_to_repeats","$percentage_aligning_to_repeats"),"\n";
  print OUT join ("\t",'not aligning to repeats',$not_aligning_to_repeats_counter,sprintf("%.1f",100-$percentage_aligning_to_repeats)),"\n";
  print OUT join ("\t",'total',"$count",'100.0'),"\n\n\n";

  # And secondly a more detailed report: How many sequences aligned the individual types of repeats (this does allow mulitple hits per sequence)

  print "Number of sequences aligning to individual classes of repeats (multiple hits possible)\n\n";
  print join ("\t",'','number of seqs'),"\n";
  print OUT "Number of sequences aligning to individual classes of repeats (multiple hits possible)\n\n";
  print OUT join ("\t",'','number of seqs'),"\n";

  foreach my $fh (@fhs){
    if (exists $fh->{seen}){
      print "$fh->{name}\t$fh->{seen}\n";
      print OUT "$fh->{name}\t$fh->{seen}\n";
    }
    else{
      print "$fh->{name}\t0\n";
      print OUT "$fh->{name}\t0\n";
    }
  }
## lastly we are going to compare the number of alignments for a certain repeat class with a reference alignment (for example shotgun sequencing or a 4C
## fragment list. We will then calculate enrichment factors for certain repeat classes
  close (OUT) or die $!;
}

