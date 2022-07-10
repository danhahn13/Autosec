#!/bin/bash

echo "
    ______                   ______                    
   / ____/___ ________  __   / ____/___  __  ______ ___ 
  / __/ / __ `/ ___/ / / /  / __/ / __ \/ / / / __ `__ \
 / /___/ /_/ (__  ) /_/ /  / /___/ / / / /_/ / / / / / /
/_____/\__,_/____/\__, /  /_____/_/ /_/\__,_/_/ /_/ /_/ 
                 /____/                                 

Usage: "

#if [ $# -gt 2 ]; then echo ""

#subfinder command that gets all domain names
echo "Finding all domains..."
subfinder -d $1 -o domains.txt
echo $1 >> domains.txt #throws the original domain back into the list

#Finding which domains are alive
echo "Extracting only live domains..."
cat domains.txt | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > livehosts.txt

#Performing a port scan on all live hosts and saving into a directory
echo "Performing a port scan..."
if [ ! -d "scannedhosts" ]; then
	mkdir scannedhosts
fi

nmap -Pn -p- -iL livehosts.txt -oN scannedhosts/scans.txt