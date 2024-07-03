# HNG Internship DevOps Track

# DevOps Stage 1: Linux User Creation Bash Script

## Task

Your company has employed many new developers. As a SysOps engineer, you are required to write a bash script called `create_users.sh` that reads a text file containing the employees' usernames and group names, where each line is formatted as `user;groups`.

The script should:
1. Create users and groups as specified.
2. Set up home directories with appropriate permissions and ownership.
3. Generate random passwords for the users.
4. Log all actions to `/var/log/user_management.log`.
5. Store the generated passwords securely in `/var/secure/user_passwords.csv`.

Ensure error handling for scenarios like existing users and provide clear documentation and comments within the script.

## Requirements
- Each user must have a personal group with the same group name as the username (this group name will not be written in the text file).
- A user can have multiple groups, each group delimited by a comma ",".
- Usernames and user groups are separated by a semicolon ";" (ignore whitespace).

### Example Input
```plainText
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data
```

### Usage
```bash
sudo bash create_users.sh <name-of-text-file>
```
### Verification Commands
To verify the creation of users, groups, and directories, use the following commands:
```bash
getent passwd | grep -E 'light|idimma|mayowa'
getent group | grep -E 'light|idimma|mayowa|sudo|dev|www-data'
ls -ld /home/light /home/idimma /home/mayowa
sudo cat /var/log/user_management.log
sudo cat /var/secure/user_passwords.csv
```
### Example Output
```plainText
User creation process completed successfully. Kindly Check /var/log/user_management.log for details.
```