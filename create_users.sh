#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

# Check if the input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: bash $0 <name-of-text-file>"
    exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create the log file and set permissions
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
    chmod 644 $LOG_FILE
    echo "Creating log file and secure directory..."
else
    echo "Log file already exists."
fi

# Create the secure directory and password file
if [ ! -d "/var/secure" ]; then
    mkdir /var/secure
    chmod 700 /var/secure
fi

if [ ! -f "$PASSWORD_FILE" ]; then
    touch $PASSWORD_FILE
    chmod 600 $PASSWORD_FILE
else
    echo "Password file already exists."
fi

# Function to log actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to create a user and its groups
create_user() {
    USERNAME=$1
    IFS=',' read -ra GROUPS <<< "$2"

    # Create user with a home directory
    if id -u $USERNAME >/dev/null 2>&1; then
        log_action "User $USERNAME already exists."
    else
        useradd -m $USERNAME
        log_action "Created user $USERNAME."
    fi

    # Create personal group
    if ! getent group $USERNAME >/dev/null 2>&1; then
        groupadd $USERNAME
        log_action "Created personal group $USERNAME."
    fi

    usermod -aG $USERNAME $USERNAME

    # Add user to additional groups
    for GROUP in "${GROUPS[@]}"; do
        GROUP=$(echo $GROUP | xargs)  # Remove leading/trailing whitespace
        if ! getent group $GROUP >/dev/null 2>&1; then
            groupadd $GROUP
            log_action "Created group $GROUP."
        fi
        usermod -aG $GROUP $USERNAME
        log_action "Added user $USERNAME to group $GROUP."
    done

    # Set up home directory permissions
    chown -R $USERNAME:$USERNAME /home/$USERNAME
    chmod 700 /home/$USERNAME
    log_action "Set up home directory for $USERNAME with correct permissions."

    # Generate a random password
    PASSWORD=$(openssl rand -base64 12)
    echo "$USERNAME:$PASSWORD" | chpasswd
    log_action "Set password for user $USERNAME."

    # Store the password securely
    echo "$USERNAME,$PASSWORD" >> $PASSWORD_FILE
}

# Read the input file line by line
while IFS=';' read -r USERNAME GROUPS; do
    USERNAME=$(echo $USERNAME | xargs)  # Remove leading/trailing whitespace
    GROUPS=$(echo $GROUPS | xargs)  # Remove leading/trailing whitespace
    create_user $USERNAME "$GROUPS"
done < "$INPUT_FILE"

log_action "User creation process completed."
