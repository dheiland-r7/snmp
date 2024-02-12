#!/usr/bin/env python3

# Multithreaded SNMP data gathering script in Python.
# This script parses a target list from cli or file containing IP addresses and CIDRs, then uses the IP addresses to run snmpbulkwalk and extract SNMP MIB data.
# Deral Heiland, November 2023

import sys
import subprocess
import os
from threading import Thread
from queue import Queue
from netaddr import IPNetwork, IPAddress

if len(sys.argv) != 5:
    print("\nSyntax: \"snmpbw.py target community timeout threads\"\n")
    print("-----------------------------------------------------------")
    print("example-1:   ./snmpbw.py 192.168.0.1 public 2 1")
    print("example-2:   ./snmpbw.py ipfile.txt public 2 4")
    print("-----------------------------------------------------------")
    print("community : public or whatever the community string is")
    print("timeout   : Timeout is in seconds")
    print("threads   : Number of threads to run\n")
    sys.exit(1)

# Set variables
CIDRFIL = sys.argv[1]
RO = sys.argv[2]
TIME = sys.argv[3]
nthreads = int(sys.argv[4])
DataQueue = Queue()

# Call CIDR parsing subroutine
def cidr_parse(cidr_file):
    ip_addresses = []
    a = 0

    # Extract IP addresses from CIDR or CIDR file
    if cidr_file.endswith('.txt'):
        with open(cidr_file, 'r') as file:
            cidrs = file.readlines()
        for cidr in cidrs:
            for ip in IPNetwork(cidr.strip()):
                ip_addresses.append(str(ip))
    else:
        for ip in IPNetwork(cidr_file):
            ip_addresses.append(str(ip))

    return ip_addresses

mydata = cidr_parse(CIDRFIL)

# Thread query subroutine that runs as a thread
def worker():
    while True:
        DataElement = DataQueue.get()
        if DataElement is None:
            break

        count = DataQueue.qsize()
        print(f"SNMP query:       {DataElement}")
        print(f"Queue count:      {count}")
        with open(f"{DataElement}.snmp", "w") as OUTFILE:
            try:
                result = subprocess.check_output(
                    f"snmpbulkwalk -On -t {TIME} -r1 -v2c -c {RO} {DataElement}",
                    shell=True,
                    stderr=subprocess.STDOUT,
                )
                result = result.decode("utf-8")
                OUTFILE.write(result)
                print(f"SNMP SUCCESS:     {DataElement}")
            except subprocess.CalledProcessError as e:
                print(f"No Response from: {DataElement}")
                os.remove(f"{DataElement}.snmp") 
                pass
        if count == 0:
            for _ in range(nthreads):
                DataQueue.put(None)

# Insert tasks into the thread queue
for data_element in mydata:
    DataQueue.put(data_element)

# Start some threads
threads = [Thread(target=worker) for _ in range(nthreads)]
for thread in threads:
    thread.start()

# Wait for threads to finish processing
for thread in threads:
    thread.join()

sys.exit()

