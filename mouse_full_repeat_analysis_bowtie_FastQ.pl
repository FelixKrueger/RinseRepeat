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
  die "Please check renaming settings!\n\n" unless ($outfile =~ s/\.fq$/_repeat_report.txt/);
  warn "Writing output to file: $outfile\n\n";

  # Creating a datastructure to store Repeat types, the location where the index for the 'repeat-genome' is located, filehandles for the Bowtie alignments
  # and the number of times the sequences were seen
  my @fhs = (
	     { name => 'Dust',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Dust_only/Dust',
	     },
	     { name => 'LINE',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/LINE_only/LINE',
	     },
	     { name => 'Low Complexity Regions',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Low_Complexity_Regions_only/low_complexity',
	     },
	     { name => 'LTR',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/LTRs_only/LTRs',
	     },
	     { name => 'Other Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Other_Repeats_only/other_repeats',
	     },
	     { name => 'RNA Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/RNA_Repeats_only/RNA_repeats',
	     },
	     { name => 'Satellite Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Satellite_Repeats_only/Satellite_repeats',
	     },
	     { name => 'Simple Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Simple_Repeats_only/simple_repeats',
	     },
	     { name => 'SINE',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/SINE_only/SINE',
	     },
	     { name => 'Tandem Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Tandem_Repeats_only/Tandem_repeats',
	     },
	     { name => 'Type II Transposons',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Type_II_Transposons_only/type_II_transposons',
	     },
	     { name => 'Unknown Repeats',
	       repeat_index => '/bi/scratch/Genomes/Mouse/NCBIM37/Repeatome/Repeatome_N_separated/Unknown_Repeats_only/unknown_repeats',
	     },
	    );

  # These are the numbers for the alignments against each major type of repeat in shotgun sequences (every fifth possible fragment of a given size
  # from the mouse genome
  #   my %all_36bp_fragments = (
  # 			    'Dust' =>
  # 			    {
  # 			     number => '17835201'
  # 			    },
  # 			    'LINE' =>
  # 			    {
  # 			     number => 105665806,
  # 			    },
  # 			     'Low Complexity Regions' =>
  #  			    {
  #  			     number => 10895688,
  #  			    },
  #  			    'LTR' =>
  #  			    {
  #  			     number => 47459512,
  #  			    },
  #  			    'Other Repeats' =>
  #  			    {
  #  			     number => 4352930,
  #  			    },
  #  			    'RNA Repeats' =>
  #  			    {
  #  			     number => 1170674,
  #  			    },
  #  			    'Satellite Repeats' =>
  #  			    {
  #  			     number => 1170674,
  #  			    },	
  #  			    'Simple Repeats' =>
  #  			    {
  #  			     number => 9660666,
  #  			    },	
  #  			    'SINE' =>
  #  			    {
  #  			     number => 17889438,
  #  			    },	
  #  			    'Tandem Repeats' =>
  #  			    {
  #  			     number => 56219751,
  #  			    },	
  #  			    'Type II Transposons' =>
  #  			    {
  #  			     number => 4820513,
  #  			    },	
  #  			    'Unknown Repeats' =>
  #  			    {
  #  			     number => 2200742,
  #  			    },	
  # 			   );
  #   #  my %all_38bp_fragments = (
  #   #			   );
  #   #  my %all_76bp_fragments = (
  #   #       			);
  #   my $total_shotgun_alignments_36bp = 0;
  #   foreach my $key(keys %all_36bp_fragments){
  #     my $number = $all_36bp_fragments{$key}->{number};
  #     print "$number\n";
  #     $total_shotgun_alignments_36bp += $number;
  #   }
  #   foreach my $key(keys %all_36bp_fragments){
  #     my $percentage = sprintf ("%.2f",100*$all_36bp_fragments{$key}->{number}/$total_shotgun_alignments_36bp);
  #     $all_36bp_fragments{$key}->{percentage} = $percentage;
  #     print "$all_36bp_fragments{$key}->{percentage}\n";
  #   }
  #   exit;


  # Now starting 12 instances of Bowtie feeding in the sequence file, one for every type of repeat and reading in the sequence identifier for the first
  # sequence where an alignment was found in the data structure above.

  warn "Now running Bowtie against the 12 major types of repeats individually (based on NCBIM37, including the gamma 3 satellite repeat consensus sequence)\n\n";
  foreach my $fh (@fhs){
    open ($fh->{fh},"bowtie -k 1 $fh->{repeat_index} $filename |") or die "Can't open pipe to bowtie: $!";
    # -q --phred64-quals: specifies an Illumina fastQ file
    # -k 1: only reports 1 valid alignment for a certain sequence
    # other than that we are run bowtie with the standard conditions

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

