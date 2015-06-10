#!/usr/bin/perl

# SNMP parsing tool to use against SNMP data gathered.
# by Deral Heiland June 2015

use strict;
use warnings;

if ($#ARGV != 0)
   {
    print "\nSyntax    \"snmpprs.pl OutputFile\" \n";
    print "-----------------------------------------------------------\n";
    print "example-1   ./snmpprs.pl results.txt\n";
    print "example-2   ./snmpprs.pl /home/location/results.txt\n";
    print "-----------------------------------------------------------\n";
    print "OutputFile :File name and path where you want the data writen too\n";
        exit(1);
}

my $outfile = $ARGV[0];
my $regpath = "./";
my $line;
my $file;


# Import regular express data file--
my $reg_file="$regpath/reg_list";
open(DAT, $reg_file) || die("Could not open file!");
my @reg_data=<DAT>;
close(DAT);

# open folder and read list of SNMP files
my $dir = "./";
opendir(DIR, $dir) or die "Can't open $dir: $!";
my @list = grep(/\.snmp$/,readdir(DIR));
closedir(DIR);

# Open OutputFile for writing parsed information
open(OUTFILE, ">$outfile") || die("Failed to open  Output file $!");

# For loops for parsing each SNMP data file "To many nested for loops - This will get cleaned up later into a beter structure"
foreach (@list)
  {
  chomp;
  open (FILE, "$_") || die("Failed to open SNMP data file $!");
  $file = "$_";
  foreach $line (<FILE>)  
    {   
     foreach (@reg_data)
       {
        chomp;
        my $regx = $_;
        if ($line =~ /$regx/i)
          {
           print "$file:$line"; 
           print OUTFILE "$file:$line";
          }
       }
     }
  close (FILE);
  }
close (OUTFILE);
