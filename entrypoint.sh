#!/bin/bash

# Generate a random UUID
RCR=$(cat /proc/sys/kernel/random/uuid)

# Create a log file
touch checkquota.log
log=checkquota.log

# URL to download rclone
URL="https://gitlab.com/developeranaz/git-hosts/-/raw/main/rclone/rclone"

# Extract the file ID from the URL
FILE_ID=$(echo "$URL" | sed -n 's|^.*/raw/main/\([^/]*\)/\([^/]*\)$|\2|p')

# Display the file ID
echo "File ID: $FILE_ID"

# Download rclone executable
wget "$URL" -O /home/$RCR

# Set executable permissions for rclone and other scripts
chmod +x /home/$RCR
chmod +x /Mega-index-heroku/quota-bypass/init.sh
chmod +x /Mega-index-heroku/quota-bypass/login.sh
chmod +x /Mega-index-heroku/quota-bypass/bypass.sh

# Create log file for quota bypass
touch /Mega-index-heroku/quota-bypass/checkquota.log

# Check rclone version
/home/$RCR version

# Configure rclone with cloud storage credentials
/home/$RCR config create 'CLOUDNAME' 'mega' 'user' $UserName 'pass' $PassWord

# Infinite loop to serve the cloud storage
while :
do
    if [ "$Auto_Quota_Bypass" = true ]; then
        # Start rclone server with settings
        /home/$RCR serve http CLOUDNAME: --addr :$PORT --buffer-size 256M --dir-cache-time 12h \
        --vfs-read-chunk-size 256M --vfs-read-chunk-size-limit 2G --vfs-cache-mode writes > "$log" 2>&1 &

        # Continuously monitor log for "Bandwidth Limit Exceeded" message
        while sleep 10
        do
            if fgrep --quiet "Bandwidth Limit Exceeded" "$log"; then
                cd /Mega-index-heroku/quota-bypass
                bash bypass.sh
            fi
        done
    else
        # Start rclone server without quota bypass
        /home/$RCR serve http CLOUDNAME: --addr :$PORT --buffer-size 256M --dir-cache-time 12h \
        --vfs-read-chunk-size 256M --vfs-read-chunk-size-limit 2G --vfs-cache-mode writes 
    fi
done

# Error message for incorrect Auto_Quota_Bypass configuration
echo "Auto_Quota_Bypass :$Auto_Quota_Bypass, value error please use true or false. Check your Heroku config vars"
/home/$RCR serve http CLOUDNAME: --addr :$PORT --buffer-size 256M --dir-cache-time 12h \
--vfs-read-chunk-size 256M --vfs-read-chunk-size-limit 2G --vfs-cache-mode writes
