#!/usr/bin/perl

# Multithreaded SNMP data gathering script. This script parses target list from file containing ip addresses and CIDRs then uses the IP addresses to to run snmpbulkwalk and extract the SNMP MIB data
# by Deral Heiland May 2015

use strict;
use warnings;
use NetAddr::IP;
use threads;
use Thread::Queue;
if ($#ARGV != 3)
   {
    print "\nSyntax    \"snmpbw.pl target community timeout threads\" \n";
    print "-----------------------------------------------------------\n";
    print "example-1   ./snmpbw.pl 192.168.0.1 public 2 1\n";
    print "example-2   ./snmpbw.pl ipfile.txt  public 2 4\n";
    print "-----------------------------------------------------------\n";
    print "community :public or what ever the community string is\n";
    print "timeout   :Timeout is in seconds \n";
    print "threads   :number of threads to run \n\n";
        exit(1);
}

# set variables
my $CIDRFIL = $ARGV[0];
my $RO = $ARGV[1];
my $TIME = $ARGV[2];
my $HOST = "";
my $nthreads = $ARGV[3];
my $DataQueue = Thread::Queue -> new();

# call cidr parsing subroutin
my @mydata =&cidr_parse($CIDRFIL);

#Thread query subroutine, but that runs 'as a thread'.
sub worker 
{
  while (my $DataElement = $DataQueue->dequeue)
    {
     my $count = $DataQueue->pending();
     print "SNMP query:       $DataElement\n";
     print "Queue count:      $count\n";
     open(OUTFILE, ">$DataElement.snmp") || die("Failed to open  Output file $HOST $!");
     my $result = `snmpbulkwalk -On -t "$TIME" -r1 -v2c -c "$RO" "$DataElement" 1 2>&1`;
     if ($result =~ /^Timeout: No Response from /)
       {
       `rm ./$DataElement.snmp`;
        print "No Response from: $DataElement\n";
       }
     else
       { 
        print OUTFILE "$result\n";
        print "SNMP SUCCESS:     $DataElement\n";
        close(OUTFILE);
       }
# Check for queue empty and returns from subroutine and exits 
     if ($count == 0)
      {
       foreach(1..$nthreads)
       {
       $DataQueue->enqueue(undef);
       }
       return;
      }             
    }
}
#insert tasks into thread queue.
$DataQueue->enqueue(@mydata);

#start some threads
for ( 1..$nthreads )
  {
  threads -> create ( \&worker );
  }

#Wait for threads to all finish processing.
for my $thr ( threads -> list() )
  {
  $thr -> join();
  }



# CIDR/HOST list parse routin
sub cidr_parse 
 {
  my (@ipaddress);
  my $a = 0;
   # extract ip addresses from CIDR or CIDR file and output to targetdata.txt file
   if ( -e $CIDRFIL )
      {
       open(HAND, $CIDRFIL) || die("Unable to open: $CIDRFIL $!");
       my @cidr=<HAND>;
       close(HAND);
       for my $cidr( @cidr )
          {
           my $n = NetAddr::IP->new( $cidr );
           for my $ip( @{$n->hostenumref} )
              {
               $ipaddress[$a] = $ip->addr;
               $a ++;
              }
          }
      }

   else
      {
       my $cidr = $CIDRFIL;
       my $n = NetAddr::IP->new( $cidr );
       for my $ip( @{$n->hostenumref} )
          {
           my $errText = $!;
           chomp($errText);
           $ipaddress[$a] = $ip->addr;
           $a ++;
          }
       }
        close (OUTFILE);
        return (@ipaddress);
 }
exit;
