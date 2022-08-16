Autosec is a tool designed to automate various tasks related to penetration testing
## About Autosec

Sublist3r is a bash tool designed to automate various penetration testing tasks. It helps penetration testers and bug hunters tests systems and save time by automating repetitive tasks. The options currently available are:

* **External Domain Enumeration:** This enumerates a given domain by finding live subdomains and performing port scans.
* **Internal Network Enumeration:** This enumerates an internal network by mapping the network and performing port scans.
* **Email Filtering Test:** This reviews the security posture of an organisation's email filtering system by sending specially crafted emails.

## Installation & Setup

**Step 1:** 
Download the repository

```
git clone https://github.com/danhahn13/Autosec.git
```
**Step 2:** 
Ensure the scripts are executable

```
sudo chmod +x Autosec.sh
```
```
sudo chmod +x setup.sh
```
**Step 3:** 
Run the setup script

```
sudo ./setup.sh
```

**Step 4:** 
Run the tool

```
sudo ./Autosec.sh
```
