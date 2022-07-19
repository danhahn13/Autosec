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
        TO=xxx\@gmail.ie
        FROM=xxx\@gmail.com
        SERVER=xxx.outlook.com:25

        # Test 1 - Send normal email to test connection
        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 1 - normal email" \
        -m "This is test number 1 - normal email" \
        -o tls=no \

        # Test 2 - Send an exe
        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 2 - executable file" \
        -m "This is the second test - exe attached" \
        -o tls=no \

        # Test 3 - Send a virus in 4 forms
        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 3a - malware" \
        -m "This is the third test - malware attached" \
        -o tls=no \

        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 3b - malware" \
        -m "This is the third test - malware attached" \
        -o tls=no \


        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 3c - malware" \
        -m "This is the third test - malware attached" \
        -o tls=no \

        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -u "This is test number 3d - malware" \
        -m "This is the third test - malware attached" \
        -o tls=no \
    
        # Test 4 - Send an email with a spoofed internal address
        sleep 1
        sendEmail \
        -f "$FROMSPOOFINTERNAL" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 4 - spoofed internal email address" \
        -m "This is the fourth test - spoofed internal email address" 
    
        # Test 5 - Send an email with a spoofed internal address and an SPF soft fail
        sleep 1
        sendEmail \
        -f "$FROMSPOOFSPF_SOFT" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 5 - spoofed external email address with SPF Soft Fail" \
        -m "This is the fifth test - spoofed external ewmail address with SPF Soft Fail" 
        
        # Test 6 - Send an email with a spoofed internal address and SPF hard fail
        sleep 1
        sendEmail \
        -f "$FROMSPOOFSPF_HARD" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 6 - spoofed external email address with SPF Hard Fail" \
        -m "This is the sixth test - spoofed external ewmail address with SPF Hard Fail"
    
        # Test 7 - Send an email with an embedded URL
        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 7 - Embedded URL" \
        -m "This is the seventh test - embedded URL https://www.google.com"
        ;;

esac
done