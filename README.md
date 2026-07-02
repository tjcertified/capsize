# 🚢 CAPSIZE! 🛶

The CAPSIZE! tool overturns your container repo login information (pun intended). This tool investigates a compromised computer for container repository login credentials in local configuration files. It does so by iterating over all user folders under `/home` and searching for both docker and podman configuration files with authentication info.

## Problem
Although there are ways to hide credentials with docker logins, I have found their usage limited, trending toward non-existent. I understand why as these credential managers are a bit of a pain to set up correctly, and cumbersome in practice to use. I personally have used `pass` and not only had problems with setup but also had problems getting it out to users without more trouble.

However, without credential managers, attackers who have infiltrated your systems can easily decode the base64-encoded auth strings in your configurations and this tool exploits that vulnerability.

## Why this matters
Logins for Docker can gain you access to a closed repo and can allow you to pose as the user/org and push malicious containers, which is bad enough on its own. 

The worse case is for repos that are not public. An example would be a local setup or an enterprise/cloud instance that an enterprise sets up. These often rely on LDAP, and discovering a non-token based login could reveal real credentials for real systems.

## Existing tools
While there are plenty of tools that do exfiltration of files, I have not seen any that focus specifically on this vulnerability on a machine. While a simple script, it has the potential to be very effective at capturing a common lack of security on a compromised system.

## Design
This tool was explicitly designed with linux in mind, with as few external tools as possible and with as much POSIX compliance as possible. I have never been part of a red team, but I assume you don't want to install any tools, so no python or even slightly uncommon packages. Additionally, I would assume that people aren't running docker on Windows in enterprise environments, or at least that such a target would not be high value, so linux seemed like the best target OS. I wrote the script to guarantee runtimes in anything that has typical linux tools installed, i.e. only using POSIX-compliant shell so avoiding `bash`-specific calls.

I did use a few standard tools external to simple `sh` scripting which seemed acceptable: `sed`, `grep`, and `base64`. I did not use any of the `read` parameters that were specific to `bash`. This was to make the script as runnable on as many systems as possible with no installation required.

I also avoided trying to log in to anything in the script, even though the extraction allows for such by extracting both the server and the auth information. The two reasons for not trying this was to avoid detection and to let the user record these values and try to log in when it was convenient to do so.

## Evaluation
To evaluate, I tried against my local environment with multiple home directories and by creating faked config.json files in both `bash` and `dash` shells. For ease of testing, I have provided a single config.json, but testing this should be pretty simple on any system that has either docker or podman (or both) and that has logged in to a container repository without credential management in place. If necessary, you can make the appropriate paths for users and configs as shown in the code in the script and place this fake config file accordingly just to test the tool.

## Prerequisites
All you should need to test is some test data and a root shell. This script will likely run into permissions errors if not at least run with `sudo`, but in a red teaming scenario, it would be expected that the actor already has root permissions so would be running in an elevated shell and wouldn't need to use `sudo`.

The specific expected packages, as listed before, are `grep`, `sed`, and `base64`. If you are running inside an optimized container, you may not have these installed, but the typical linux system these days that is not specifically base Alpine has these by default.

## Installation
First, clone this repo

Next, put this script on a machine where you have root access.

Finally, run the script in an elevated shell to see if your machine has compromised docker configs.
