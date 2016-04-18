#!/bin/bash
# Settings for mac mini servers
# ---------------------------------------------------------------------------- #
# This is built for a specific purpose in mind, but is easily editable to suit
# your needs.
# We need to deploy 89 Mac mini's across North America for use in Caching,
# JAMF Casper FileShare Distribution Points, Presto2 printserver, and Zello
# walkie-talkie host.
#
# The settings here are mostly default, but we wanted as 0-touch setup as
# possible.
#
#
#    This script is NOT meant to be run multiple times on the same system.
#
# ---------------------------------------------------------------------------- #

# Variables
# Edit each section below to suit your preferences for each service

# Server.app Setup Variables
# These are the local admin to the Mac
localAdminUser="admin" # Change!
localAdminPass="password" # Change!
localAdminDir="/var" # Change!
serverSetupLocation="/var/scripts" # Location of the serverSetup.exp for use during deployment. Change!

# Server.app Caching Setup Variables
cachingServerRoot="/Library/Server" # Default is /Library/Server
cachingDataPath="/Library/Server/Caching/Data" # Default is /Library/Server/Caching/Data
cachingLocalSubnetsOnly="yes"
cachingAllowPersonalCaching="no"
cachingReservedVolumeSpace="10000000000" # Sizes are in bytes (~100GB)
cachingCacheLimit="50000000000" # Sizes are in bytes (~50GB)

# CasperShare Setup Variables
casperDPDirectory="/Users/Shared/CasperShare" # Can be put anywhere, really. Put in a visible folder for other techs to easily find.
casperDPDirectoryFriendlyName="CasperShare" # I just make it the same as the dir.
# User setup
casperDPReadWriteShortName="casperadmin"
casperDPReadWriteRealName="Casper Admin"
casperDPReadWritePassword="password" # Change!
casperDPReadShortName="casperinstall"
casperDPReadRealName="Casper Install"
casperDPReadPassword="password" # Change!

# Virtual Box
zelloOVA="/path/to/ZelloServer.ova"
windowsOVA="path/to/Windows.ova"

# Log and log archive location
log_location="/var/log/serverDeploy_install.log"
archive_log_location="/var/log/serverDeploy_install-$(date +%Y-%m-%d-%H-%M-%S).log"

# Progress tracker:
# Windows VM - 0%
# Presto 2 - 0%
    # todo
    # checks defaults
    # apply license (if needed)

mainScript() {
    # Run the script

    if [[ -f "$log_location" ]]; then
        /bin/mv "$log_location" "$archive_log_location"
    fi

    ScriptLogging "  --------------------  "
    ScriptLogging " Starting Server Deploy "
    ScriptLogging "  --------------------  "
    ScriptLogging " "
    ScriptLogging "$(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging " "

    # Comment out functions you do not want to run.
    #serverSetup
    #serverCachingSetup
    #casperDP
    #windowsVMSetup
    #zelloVMSetup
    #prestoSetup

    ScriptLogging "  --------------------  "
    ScriptLogging " Server Deploy Complete "
    ScriptLogging "  --------------------  "
    ScriptLogging " "
    ScriptLogging "$(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging " "
    ScriptLogging " end "
}

# ---------------------------------------------------------------------------- #
#                      No need to edit below this line                         #
# ---------------------------------------------------------------------------- #

serverSetup() {
    # Setup Server.app
    # agree to terms, etc.
    ScriptLogging "  --------------------  "
    ScriptLogging "    Server.app Setup    "
    ScriptLogging "  --------------------  "

    SERVERVAR=$(expect -c '

        set timeout 300

        set theusername $localAdminUser
        set thepassword $localAdminPass

        spawn /Applications/Server.app/Contents/ServerRoot/usr/sbin/server setup

        expect {
            "Press Return to view the software license agreement." { send \r }
        }
        expect {
            "Do you agree to the terms of the software license agreement? (y/N)" { send "y\r" }
        }
        expect {
            "User name:" { send $theusername\r }
        }
        expect {
            "Password:" { send $thepassword\r }
        }
        interact
        expect eof
    ')

    echo ${SERVERVAR}
    sleep 5
}

# Start setting up Server.app (Caching)
serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    ScriptLogging "  --------------------  "
    ScriptLogging "      Caching Setup     "
    ScriptLogging "  --------------------  "

    # start the service
    ScriptLogging " Setting up Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ServerRoot = "$cachingServerRoot" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:DataPath = "$cachingDataPath" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:LocalSubnetsOnly = "$cachingLocalSubnetsOnly" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:AllowPersonalCaching = "$cachingAllowPersonalCaching" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ReservedVolumeSpace = "$cachingReservedVolumeSpace" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:CacheLimit = "$cachingCacheLimit" | ScriptLogging

    # restart the service
    ScriptLogging " Restarting Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching
    sleep 10
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching
    ScriptLogging " Caching enabled and setup! "
}

casperDP() {

    # Create the directory for the DP Share, if it doesn't already exist
    if [ -d "$casperDPDirectory" ]; then
        ScriptLogging " Directory Exists "
    else
        ScriptLogging "  Create $casperDPDirectory"
        /bin/mkdir "$casperDPDirectory"
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    ScriptLogging "  Create $casperDPReadWriteShortName..."
    dscl . -create "/Users/$casperDPReadWriteShortName"
    dscl . -create "/Users/$casperDPReadWriteShortName" UserShell /bin/bash
    dscl . -create "/Users/$casperDPReadWriteShortName" RealName "$casperDPReadWriteRealName"
    dscl . -create "/Users/$casperDPReadWriteShortName" UniqueID $RANDOM
    dscl . -create "/Users/$casperDPReadWriteShortName" PrimaryGroupID 1000

    ScriptLogging "  Create $casperDPReadShortName..."
    dscl . -create "/Users/$casperDPReadShortName"
    dscl . -create "/Users/$casperDPReadShortName" UserShell /bin/bash
    dscl . -create "/Users/$casperDPReadShortName" RealName "$casperDPReadRealName"
    dscl . -create "/Users/$casperDPReadShortName" UniqueID $RANDOM
    dscl . -create "/Users/$casperDPReadShortName" PrimaryGroupID 1000

    ScriptLogging "  Set $casperDPReadWriteShortName password..."
    dscl . -passwd "/Users/$casperDPReadWriteShortName" "$casperDPReadWritePassword"

    ScriptLogging "  Set $casperDPReadShortName password..."
    dscl . -passwd "/Users/$casperDPReadShortName" "$casperDPReadPassword"

    # enable the filesharing service
    /usr/sbin/sharing -a "$casperDPDirectory" -AS $casperDPDirectoryFriendlyName -s 110 -g 000 | ScriptLogging

    # enable casperadmin and casperinstall access
    ScriptLogging "  Set ACL's for our Casper Users..."
    /bin/chmod +a "$casperDPReadWriteShortName allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity" "$casperDPDirectory"
    /bin/chmod +a "$casperDPReadShortName allow list,search,readattr,readextattr,readsecurity" "$casperDPDirectory"

}

windowsVMSetup() {
    # windows VM image will need to be built and deployed
    # vboxmanage import ${windowsOVA}
    # vboxmanage startvm "Windows 7"
    # this is on hold
true;
}

zelloVMSetup() {

    ScriptLogging "  --------------------  "
    ScriptLogging "     Zello OVA Setup    "
    ScriptLogging "  --------------------  "

    # Import Zello OVA
    vboxmanage import ${zelloOVA}

    # Create LauchAgent for $localAdminUser
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
    <plist version=\"1.0\">
    <dict>
        <key>Label</key>
            <string>com.rh.zelloserver</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/local/bin/vboxmanage</string>
            <string>startvm</string>
            <string>Zello Server 64</string>
        </array>
    </dict>
    </plist>" > ${localAdminDir}/${localAdminUser}/Library/LaunchDaemons/com.rh.zelloserver.plist
true;
}

prestoSetup() {
    #check if presto server is installed
    #set default settings for environment
    #apply license
true;
}

ScriptLogging(){

    if [ -n "$1" ]; then
        IN="$1"
    else
        read -r IN # This reads a string from stdin and stores it in a variable called IN
    fi

    DATE=$(date +%Y-%m-%d\ %H:%M:%S)
    LOG="$log_location"

    echo "$DATE" " $IN" >> $LOG
}

# Start your engines
mainScript
