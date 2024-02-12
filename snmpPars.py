#!/usr/bin/env python3

import os
import re
import sys

if len(sys.argv) != 2:
    print("\nSyntax: \"snmpprs.py OutputFile\"\n")
    print("-----------------------------------------------------------")
    print("Example 1: ./snmpprs.py results.txt")
    print("Example 2: ./snmpprs.py /home/location/results.txt")
    print("-----------------------------------------------------------")
    print("OutputFile: File name and path where you want the data written to")
    sys.exit(1)

outfile = sys.argv[1]
regpath = "./"
file_list = []

# Import regular expression data from a file
reg_file = os.path.join(regpath, "reg_list")
with open(reg_file, 'r') as f:
    reg_data = f.read().splitlines()

# List SNMP files in the current directory
dir_path = "./"
for file in os.listdir(dir_path):
    if file.endswith(".snmp"):
        file_list.append(file)

# Open OutputFile for writing parsed information
with open(outfile, "w") as out_file:
    for filename in file_list:
        with open(filename, 'r') as snmp_file:
            for line in snmp_file:
                for regx in reg_data:
                    if re.search(regx, line, re.IGNORECASE):
                        print(f"{filename}:{line}", end="")
                        out_file.write(f"{filename}:{line}")

print("Parsing complete.")

