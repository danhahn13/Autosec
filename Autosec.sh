#!/bin/bash

echo "
    ___         __                      
   /   | __  __/ /_____  ________  _____
  / /| |/ / / / __/ __ \/ ___/ _ \/ ___/
 / ___ / /_/ / /_/ /_/ (__  )  __/ /__  
/_/  |_\__,_/\__/\____/____/\___/\___/  

 
Usage: 
./Autosec.sh <function> <target>

    Example 1 - External domain enumeration: 
    ./Autosec.sh -x google.com

    Example 2 - Internal network enumeration: 
    ./Autosec.sh -i 10.1.10.0/24

    Example 3 - email filtering security test:
     ./Autosec.sh -e"

while getopts x:i:e opt; do
case $opt in

    #external domain enumeration
    x)
        #if [ $# -ne 1 ]; then
            #echo "Usage: ./Autosec.sh -x <domain>"
           # echo "Example: ./Autosec.sh -x google.com"
           # exit 1
        #fi

        #subfinder command that gets all domain names
        echo "Finding all subdomains..."
        subfinder -d $2 -o subdomains.txt

        #Regex to extract only third-level domain names with no duplicates.
        cat subdomains.txt | grep -Po "(\w+\.\w+\.\w+)$" | sort -u >> thirdlevel-subdomains.txt

        #if statement to make a directory only if it does not exist.
        if [ ! -d "third" ]; then
            mkdir third
        fi

        #Re-run subfinder on each third level domain to get a complete list of subdomains
        for x in $(cat thirdlevel-subdomains.txt);
            do subfinder -d $x -o third/$x.txt;
            cat third/$x.txt | sort -u >> subdomains.txt;
        done

        #throws the original domain back into the list
        echo $2 >> subdomains.txt 

        #clear extra files
        rm thirdlevel-subdomains.txt && rm -r third

        #Finding which domains are alive
        echo "Extracting only live domains..."
        cat subdomains.txt | sort -u |httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > live-subdomains.txt

        #Performing a TCP and UDP port scan on all live hosts and saving into a directory
        echo "Performing a TCP port scan..."
        if [ ! -d "scannedhosts" ]; then
        	mkdir scannedhosts
        fi
        nmap -Pn --top-ports 10 -iL live-subdomains.txt -oN scannedhosts/TCP.txt

        echo "Performing a UDP port scan..."
        nmap -Pn -sU --top-ports 10 -iL live-subdomains.txt -oN scannedhosts/UDP.txt
        ;;

    #internal network enumeration
    i)
        #mapping the network
        echo "Mapping the network..."
        nmap -sn $2 -oN livehosts.txt

        #take out everythhing but the ip addresses so we can perform further scanning
        cat livehosts.txt | awk '/is up/ {print up}; {gsub (/\(|\)/,""); up =$NF}' > livehosts-list.txt

        #performing a port scan on live hosts
        nmap -Pn --top-ports 10 -iL livehosts-list.txt -oN portscans.txt
        ;;

    #email filtering security test
    e)
    
        ;;

esac
done