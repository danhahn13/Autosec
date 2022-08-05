#!/bin/bash

echo "
    ___         __                      
   /   | __  __/ /_____  ________  _____
  / /| |/ / / / __/ __ \/ ___/ _ \/ ___/
 / ___ / /_/ / /_/ /_/ (__  )  __/ /__  
/_/  |_\__,_/\__/\____/____/\___/\___/  

 A Secuity Tool By

    Daniel Hahn
"


OPTION=$(zenity --list --column="Options" --title="Choose an option" "External enumeration" \ "Internal enumeration" \ "Email filtering test")

if [[ $OPTION == "External enumeration" ]]; then

    DOMAIN=$(zenity --entry --text "Enter your domain" --title "External Enumeration" --entry-text="Example: google.com")

    function external () {

    #subfinder command that gets all domain names
        echo "# Finding all subdomains..."
        echo "33"

        subfinder -d $DOMAIN -o subdomains.txt

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
        echo $DOMAIN >> subdomains.txt 

        #clear extra files
        rm thirdlevel-subdomains.txt && rm -r third

        #Finding which domains are alive
        echo "# Extracting only live domains..."
        echo "66"
        cat subdomains.txt | sort -u |httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ":443" > live-subdomains.txt

        #Performing a TCP and UDP port scan on all live hosts and saving into a directory
        echo "# Performing a TCP port scan..."
        echo "90"
        if [ ! -d "scannedhosts" ]; then
            mkdir scannedhosts
        fi
        nmap -Pn --top-ports 10 -iL live-subdomains.txt -oN scannedhosts/TCP.txt

        echo "Performing a UDP port scan..."
        nmap -Pn -sU --top-ports 10 -iL live-subdomains.txt -oN scannedhosts/UDP.txt
    }
    external | zenity --progress --title "External Enumeration" --auto-close



elif [[ $OPTION == "Internal enumeration" ]]; then

    IP=$(zenity --entry --text "Enter your IP range" --title "Internal Enumeration" --entry-text="Example: 10.1.10.0/24")

    function internal () {

        #mapping the network
        echo "Mapping the network..."
        nmap -sn $IP -oN livehosts.txt

        #take out everythhing but the ip addresses so we can perform further scanning
        cat livehosts.txt | awk '/is up/ {print up}; {gsub (/\(|\)/,""); up =$NF}' > livehosts-list.txt

        #performing a port scan on live hosts
        nmap -Pn --top-ports 10 -iL livehosts-list.txt -oN portscans.txt
    }
    internal | zenity --progress --title "Internal Enumeration" --auto-close

elif [[ $OPTION="Email filtering test" ]]; then

    #modify the details below
        TO=$(zenity --entry --text "Enter the target email" --title "Email Filtering Test" --entry-text="Example: johndoe@tesla.com")
        FROM=$(zenity --entry --text "Enter the sender email" --title "Email Filtering Test" --entry-text="Example: janedoe@tesla.com")
        SERVER=$(zenity --entry --text "Enter the SMTP address and port" --title "Email Filtering Test" --entry-text="Example: xxx.outlook.com:25")

        #Spoofed address
        SPOOFINTERNAL=$(zenity --entry --text "Spoof an internal address" --title "Email Filtering Test" --entry-text="Example: janedoe@tesla.com")

        #Spoof external email with softfail(~all) and hardfail(-all).
        SPOOFSPF_SOFT=ceo\@dell.com
        SPOOFSPF_HARD=ceo\@amazon.com


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

    
        # Test 3 - Send an email with a spoofed internal address
        sleep 1
        sendEmail \
        -f "$SPOOFINTERNAL" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 4 - spoofed internal email address" \
        -m "This is the fourth test - spoofed internal email address" 
    
        # Test 4 - Send an email with a spoofed internal address and an SPF soft fail
        sleep 1
        sendEmail \
        -f "$SPOOFSPF_SOFT" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 5 - spoofed external email address with SPF Soft Fail" \
        -m "This is the fifth test - spoofed external ewmail address with SPF Soft Fail" 
        
        # Test 5 - Send an email with a spoofed internal address and SPF hard fail
        sleep 1
        sendEmail \
        -f "$SPOOFSPF_HARD" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 6 - spoofed external email address with SPF Hard Fail" \
        -m "This is the sixth test - spoofed external ewmail address with SPF Hard Fail"
    
        # Test 6 - Send an email with an embedded URL
        sleep 1
        sendEmail \
        -f "$FROM" \
        -t "$TO" \
        -s "$SERVER" \
        -o tls=no \
        -u "This is test number 7 - Embedded URL" \
        -m "This is the seventh test - embedded URL https://www.google.com"
       

else

    zenity --warning --text="Please try again and select an option"
fi