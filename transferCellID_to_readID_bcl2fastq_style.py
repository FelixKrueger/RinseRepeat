#!/usr/bin/env python
import sys, gzip, os
import getopt
from glob import glob
from time import sleep as sleep
import re

index_file = "Sample5451_L001_concatentated_indexes.txt"

### Splitting into individual files fails for all 576 paired-end files. Let's see if it works for 288 each...
# index_file = "plus_dox.txt"
# index_file = "minus_dox.txt"

# Last modified 14 June 2021

do_the_splitting = 1

indexes = {}       # storing all relevant R2 barcode combinations
fhs = {}           # storing the filehandles for all output files
fhs2 = {}          # R2 output filehandes

processed_barcodes = {}
faithless_barcodes = {}
# These are the potential barcode conditions, and which sample they encode
#    TnB     constant_first_barcode      i7        i5    constant_2nd_barcode    TnA        Sample_name
# GAGATTCC GGACAGGGACAGCCGAGCCCACGAGAC GGCATACT	TATGGCAC TCGTCGGCAGCGTCTCCACGC ATAGAGGC	201124_triplex_-dox_plate1_K27me3_A01

def submain():
    # read expected barcode combinations
    # read_indexes()
    
    print (f"Python version: {sys.version}.")
    allfiles = glob("*_merged_*fastq.gz")

    # print (allfiles)
    allfiles.sort() # required as glob doesn't necessarily store files in alphabetical order
    # print (allfiles)
    # 10X files tend to come as R1, R2, and I1
    while len(allfiles) >= 3:
        indexfile = allfiles.pop(0)
        r1file = allfiles.pop(0)
        r2file = allfiles.pop(0)
        
        # r2file = allfiles.pop(0)

        print (f"Reading in paired FastQ files:\n R1: {r1file}\n R2: {r2file}\nIndex: {indexfile}")
        main(r1file,r2file,indexfile)
        # print ("Clearing filehandles")
        #fhs.clear() # clearing filehandles
        #fhs2.clear()
        #processed_barcodes.clear()
        
def main(r1file, r2file, barcode1file):

    expected_count   = 0
    unexpected_count = 0
    count = 0              # total sequence count

    r2f = gzip.open(r2file)
    b1f = gzip.open(barcode1file)
   
    print ("Opening output filehandles")
    open_output_filehandles (r1file,r2file,barcode1file)
    
    # print (f"Reading file: >{r2file}<")
    with gzip.open(r1file) as r1f:

        while True:
            r2_readID  = r2f.readline().decode().strip()
            r2_seq     = r2f.readline().decode().strip()
            r2_line3   = r2f.readline().decode().strip()
            r2_qual    = r2f.readline().decode().strip()

            if not r2_qual:
                break

            r1_readID  = r1f.readline().decode().strip()
            r1_seq     = r1f.readline().decode().strip()
            r1_line3   = r1f.readline().decode().strip()
            r1_qual    = r1f.readline().decode().strip()

            count += 1

            b1_readID  = b1f.readline().decode().strip()
            b1_seq     = b1f.readline().decode().strip()
            b1_line3   = b1f.readline().decode().strip()
            b1_qual    = b1f.readline().decode().strip()


            if count%1000000 == 0:
                print (f"Processed {count} reads so far")

            # if count == 100:
            #     break # that's quite enough for a test
            
            # print (f"{r1_readID}\n{r1_seq}\n{r1_line3}\n{r1_qual}\n")	
            # print (f"{r2_readID}\n{r2_seq}\n{r2_line3}\n{r2_qual}\n")	
            # print (f"{b1_seq}\n\n")
            
            # The first 16bp of R1 are the cell barcode. The rest are UMI (I believe)
            cell_barcode = r1_seq[0:16]
            # print (f"{cell_barcode}") 
            # sleep(1)			
            
            # replacing underscores so they can be carried through the alignment process 
            r1_readID = r1_readID.replace(" ","_")
            r2_readID = r2_readID.replace(" ","_")
            b1_readID = b1_readID.replace(" ","_")

            # # Writing out the extracted indexes to readIDs
            new_r1ID = f"{r1_readID}_CB:{cell_barcode}"
            new_r2ID = f"{r2_readID}_CB:{cell_barcode}"
            new_b1ID = f"{b1_readID}_CB:{cell_barcode}"

            # print (f"{new_r1ID}\n{new_r2ID}\n{new_b1ID}\n\n")
            # sleep(1)

         
            new_r1 = (f"{new_r1ID}\n{r1_seq}\n{r1_line3}\n{r1_qual}\n")
            new_r2 = (f"{new_r2ID}\n{r2_seq}\n{r2_line3}\n{r2_qual}\n")	
            new_b1 = (f"{new_b1ID}\n{b1_seq}\n{b1_line3}\n{b1_qual}\n")	
            
            #print (f"{new_r1}\n{new_r2}\n{new_b1}")
            # sleep(1)
            fhs["read1"].write(f"{new_r1}".encode())
            fhs["read2"].write(f"{new_r2}".encode())
            fhs["barcode1"].write(f"{new_b1}".encode())
                # fhs2[indexes[composite]].write(f"{new_r2}".encode())
            
            # else:
            #     new_r1 = (f"{r1_readID}\n{r1_seq}\n{r1_line3}\n{r1_qual}\n")
            #     new_r2 = (f"{r2_readID}\n{r2_seq}\n{r2_line3}\n{r2_qual}\n")

            #     fhs["read1_unassigned"].write(f"{new_r1}".encode())
            #     fhs2["read2_unassigned"].write(f"{new_r2}".encode())	
            #     # print ("Barcode combination was unexpected. Moving on for the time being.")
            #     if composite not in faithless_barcodes.keys():
            #         faithless_barcodes[composite] = 0
            #     faithless_barcodes[composite] += 1

            #     unexpected_count += 1
    
    # barcode_count = 0
    # print ("\n\nExpected (annotated) barcodes\n-----------------------------")
    # print ("barcode #\tcomposite barcodes\tsample name\t# found")
    # for bcode in sorted (processed_barcodes, key=processed_barcodes.get, reverse=True):
    #     barcode_count += 1
    #     print (f"{barcode_count}\t{bcode}\t{indexes[bcode]}\t{processed_barcodes[bcode]}")
    #     if barcode_count == 1000:
    #         break
    
    # barcode_count = 0
    # print ("\n\nUnexpected (unexplained) barcodes\n---------------------------------")
    # print ("barcode #\tcomposite barcodes\tsample name\t# found")
    # for rogue in sorted (faithless_barcodes, key=faithless_barcodes.get, reverse=True):
    #     barcode_count += 1
    #     print (f"{barcode_count}\t{rogue}\tN/A\t{faithless_barcodes[rogue]}")
    #     if barcode_count == 50:
    #         break

    r2f.close()
    b1f.close()
    close_filehandles()

    print (f"Total number of reads processed: {count}")
    print (f"Expected R2 barcode combinations: {expected_count}\nUnexpected R2 barcode combinations: {unexpected_count}")


def open_output_filehandles(filename1,filename2,barcode1file):

    print (f"Got following sample files: {filename1} and {filename2} and {barcode1file}")
    pattern = '(.*)_(S\d+_L00\d_[RI]\d_001.fastq.gz)'

    p = re.compile(pattern)
    # print (filename1)
    
    # Read 1 
    m = p.findall(filename1)
    sample = m[0][0]
    ending = m[0][1]
    new_filename1 = f"{sample}_CB_{ending}"
    
    # Read 2
    m = p.findall(filename2)
    sample = m[0][0]
    ending = m[0][1]
    # ending = ending.replace("R4","R2")
    new_filename2 = f"{sample}_CB_{ending}"

    # Barcode 1 
    m = p.findall(barcode1file)
    sample = m[0][0]
    ending = m[0][1]
    new_barcode1 = f"{sample}_CB_{ending}"

    print (new_filename1)
    print (new_filename2)
    print (new_barcode1)

    outfh1 = gzip.open (new_filename1,mode='w',compresslevel=3)
    outfh2 = gzip.open (new_filename2,mode='w',compresslevel=3)
    outbc1 =  gzip.open (new_barcode1,mode='w',compresslevel=3)
    
    fhs["read1"]    = outfh1
    fhs["read2"]    = outfh2
    fhs["barcode1"] = outbc1


    return
    # readID,state,chrom,pos = [ line.decode().strip().split(sep="\t")[i] for i in [0,1,2,3]]
    # repeat_vals = [f"{i}" for i in range(1,34)]


def close_filehandles():
    for name in fhs.keys():
        print (f"closing filehandle (fhs) for >{name}<, was >{fhs[name]}<")
        fhs[name].close()
    # for name in fhs2.keys():
    #     # print (f"closing filehandle (fhs2) for >{name}<, was >{fhs2[name]}<")
    #     fhs2[name].close()


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def read_indexes():

    '''
    First we need to read in all combinations of i7, i5, Read2 Barcode 1 and Read2 Barcode 2
    '''

    with open(index_file) as f:

        count = 0

        for line in f:
            if count == 0: #
                eprint (f"Skipping header line >>{line.strip()}<<")
                sleep(1)
                count += 1
                continue

            count += 1
            # print (f"line {count}: content >{line.strip()}<")

            # Example format
            # sample name	barcode 1	barcode 2
            # 201124_triplex_-dox_plate1_K27me3_A01	GAGATTCCGGACAGGGACAGCCGAGCCCACGAGACGGCATACT	TATGGCACTCGTCGGCAGCGTCTCCACGCATAGAGGC
            # 201124_triplex_-dox_plate1_K27me3_A02	GAGATTCCGGACAGGGACAGCCGAGCCCACGAGACGAGCAGTA	TATGGCACTCGTCGGCAGCGTCTCCACGCATAGAGGC
            # 201124_triplex_-dox_plate1_K27me3_A03	GAGATTCCGGACAGGGACAGCCGAGCCCACGAGACAGCAAGCA	TATGGCACTCGTCGGCAGCGTCTCCACGCATAGAGGC
            
            samplename, barcode1, barcode2  = line.strip().split("\t")
            # print (f"{samplename} : {barcode1} : {barcode2}")
            # sleep(1)

            # combo = f"{barcode1}:{barcode2}"
            TnB = barcode1[0:8]
            middle1 = barcode1[8:35]
            i7  = barcode1[-8::]
            # print (f"{barcode1} : {TnB} : {middle1} : {i7}") 
            
            i5  = barcode2[0:8]
            middle2 = barcode2[8:29]
            TnA = barcode2[-8:]
            # print (f"{barcode2} : {i5} : {middle2} : {TnA}") 
            
            combo = f"{TnB}:{i7}:{i5}:{TnA}"
            # print (combo)
            # pos = int(pos)
            if combo in indexes.keys():
                # pass
                print (f"already present: {combo}")
            else:
                indexes[combo] = samplename

        # print ("All possible samples:")
        # for codes in indexes.keys():
        #     print (f"{codes}\t{indexes[codes]}")

    # eprint ("Finished reading annotations\n")


if __name__ == "__main__":
    submain()
else:
    print ("Just getting imported")
