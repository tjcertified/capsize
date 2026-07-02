#!/bin/sh

# Check if terminal supports colors
if [ -t 1 ] && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    RESET='\033[0m' # No Color / Reset
else
    GREEN=''
    YELLOW=''
    CYAN=''
    BLUE=''
    RESET=''
fi

get_config_secrets() {
    get_server=false
    found_creds=false
    while IFS= read -r line; do
        if [ "$skip_next" = true ]; then
            skip_next=false
            continue
        fi
        #echo "Checking line: $line"
        if echo "$line" | grep -q '"auths":'; then
            get_server=true
            continue
        fi
        if [ "$get_server" = true ]; then
            #echo "Looking for server in line: $line"
            get_server=false
            server=$(echo "$line" | sed -n 's/.*"\(.*\)":.*/\1/p')
            #echo "Found server: $server"
        fi
        if echo "$line" | grep -q '"auth":'; then
            # extract the base64 string
            auth=$(echo "$line" | sed -n 's/.*"auth": "\(.*\)".*/\1/p')
            # decode it and print the username and password
            tmp=$(echo "$auth" | base64 --decode)
            #echo "$tmp"
            get_server=true
            skip_next=true
        fi
        if [ -n "$server" ] && [ -n "$tmp" ]; then
            # Get username - before the colon
            name="${tmp%%:*}"

            # Get password - after the colon
            pwd="${tmp#*:}"
            echo "${YELLOW}($server) ${RESET}[User: $name, PWD: $pwd]"
            server=""
            tmp=""
            found_creds=true
        fi
    done < "$1"
    if [ "$found_creds" = false ]; then
        echo "No credentials found in $1"
    fi
}

for userdir in /home/*; do
    found_file=false
    echo "${CYAN}Checking $userdir${RESET}"
    # Look for docker/podman config dir
    dockerconfig="$userdir/.docker/config.json"
    podmanconfig="$userdir/.config/containers/auth.json"
    if [ -e "$podmanconfig" ]; then
        echo "${GREEN}Found podman config in $userdir${RESET}"
        get_config_secrets "$podmanconfig"
        found_file=true
    fi
    if [ -e "$dockerconfig" ]; then
        echo "${GREEN}Found docker config in $userdir${RESET}"
        get_config_secrets "$dockerconfig"
        found_file=true
    fi
    if [ "$found_file" = false ]; then
        echo "No config file found"
    fi
    echo "\n------------------------------\n"
done
