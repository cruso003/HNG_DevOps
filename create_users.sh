#!/bin/bash

# Check if the input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: bash $0 <name-of-text-file>"
    exit 1
fi

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
SECURE_DIR="/var/secure"
PASSWORD_FILE="$SECURE_DIR/user_passwords.csv"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Input file $INPUT_FILE does not exist."
    exit 1
fi

# Function to log actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE > /dev/null
}

# Ensure the log file and secure directory exist with correct permissions
echo "Creating log file and secure directory..."
sudo mkdir -p $SECURE_DIR
sudo touch $LOG_FILE $PASSWORD_FILE
sudo chmod 644 $LOG_FILE
sudo chmod 600 $PASSWORD_FILE

# Function to create a user and its groups
create_user() {
    USERNAME=$1
    IFS=',' read -ra GROUPS <<< "$2"

    log_action "Processing user: $USERNAME"

    # Create user with a home directory
    if id -u $USERNAME >/dev/null 2>&1; then
        log_action "User $USERNAME already exists."
    else
        if sudo useradd -m $USERNAME; then
            log_action "Created user $USERNAME."
        else
            log_action "Failed to create user $USERNAME."
            return
        fi
    fi

    # Create personal group
    if ! sudo getent group $USERNAME >/dev/null 2>&1; then
        if sudo groupadd $USERNAME; then
            log_action "Created personal group $USERNAME."
        else
            log_action "Failed to create personal group $USERNAME."
            return
        fi
    fi

    if sudo usermod -aG $USERNAME $USERNAME; then
        log_action "Added user $USERNAME to their personal group."
    else
        log_action "Failed to add user $USERNAME to their personal group."
    fi

    # Add user to additional groups
    for GROUP in "${GROUPS[@]}"; do
        GROUP=$(echo $GROUP | xargs)  # Remove leading/trailing whitespace
        if ! sudo getent group $GROUP >/dev/null 2>&1; then
            if sudo groupadd $GROUP; then
                log_action "Created group $GROUP."
            else
                log_action "Failed to create group $GROUP."
                continue
            fi
        fi
        if sudo usermod -aG $GROUP $USERNAME; then
            log_action "Added user $USERNAME to group $GROUP."
        else
            log_action "Failed to add user $USERNAME to group $GROUP."
        fi
    done

    # Set up home directory permissions
    if sudo chown -R $USERNAME:$USERNAME /home/$USERNAME && sudo chmod 700 /home/$USERNAME; then
        log_action "Set up home directory for $USERNAME with correct permissions."
    else
        log_action "Failed to set up home directory for $USERNAME."
    fi

    # Generate a random password
    PASSWORD=$(openssl rand -base64 12)
    if echo "$USERNAME:$PASSWORD" | sudo chpasswd; then
        log_action "Set password for user $USERNAME."
    else
        log_action "Failed to set password for user $USERNAME."
    fi

    # Store the password securely
    echo "$USERNAME,$PASSWORD" | sudo tee -a $PASSWORD_FILE > /dev/null
}

# Read the input file line by line
while IFS=';' read -r USERNAME GROUPS; do
    USERNAME=$(echo $USERNAME | xargs)  # Remove leading/trailing whitespace
    GROUPS=$(echo $GROUPS | xargs)  # Remove leading/trailing whitespace
    create_user $USERNAME "$GROUPS"
done < "$INPUT_FILE"

log_action "User creation process completed."
echo "User creation process completed."
