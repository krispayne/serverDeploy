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
serverSetupUsername="admin" # Change!
serverSetupPassword="password" # Change!

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

# Log and log archive location
log_location="/var/log/serverDeploy_install.log"
archive_log_location="/var/log/serverDeploy_install-$(date +%Y-%m-%d-%H-%M-%S).log"

# Progress tracker:

# Settings we are going to need to edit
# Windows VM - 0%
# Zello VM - 0%
# Presto 2 - 0%

mainScript() {
    # Run the script
    # Comment out functions you do not want to run.

    #All are off by default!

    #serverSetup
    #serverCachingSetup
    #casperDP
    #windowsVMSetup
    #zelloVMSetup
    #prestoSetup
}

# ---------------------------------------------------------------------------- #
#                      No need to edit below this line                         #
# ---------------------------------------------------------------------------- #

serverSetup() {
    # Setup Server.app
    # agree to terms, etc.

    ./serverSetup.exp "$serverSetupUsername" "$serverSetupPassword"
    sleep 5
}

# Start setting up Server.app (Caching)
serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    # start the service
    echo " Setting up Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ServerRoot = "$cachingServerRoot"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:DataPath = "$cachingDataPath"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:LocalSubnetsOnly = "$cachingLocalSubnetsOnly"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:AllowPersonalCaching = "$cachingAllowPersonalCaching"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ReservedVolumeSpace = "$cachingReservedVolumeSpace"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:CacheLimit = "$cachingCacheLimit"

    # restart the service
    echo " Restarting Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching
    sleep 10
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching
    echo " Caching enabled and setup! "
}

casperDP() {

    # Create the directory for the DP Share, if it doesn't already exist
    if [ -d "$casperDPDirectory" ]; then
        echo " Directory Exists "
    else
        echo "Create $casperDPDirectory"
        /bin/mkdir "$casperDPDirectory"
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    echo "Create $casperDPReadWriteShortName..."
    dscl . -create "/Users/$casperDPReadWriteShortName"
    dscl . -create "/Users/$casperDPReadWriteShortName" UserShell /bin/bash
    dscl . -create "/Users/$casperDPReadWriteShortName" RealName "$casperDPReadWriteRealName"
    dscl . -create "/Users/$casperDPReadWriteShortName" UniqueID $RANDOM
    dscl . -create "/Users/$casperDPReadWriteShortName" PrimaryGroupID 1000

    echo "Create $casperDPReadShortName..."
    dscl . -create "/Users/$casperDPReadShortName"
    dscl . -create "/Users/$casperDPReadShortName" UserShell /bin/bash
    dscl . -create "/Users/$casperDPReadShortName" RealName "$casperDPReadRealName"
    dscl . -create "/Users/$casperDPReadShortName" UniqueID $RANDOM
    dscl . -create "/Users/$casperDPReadShortName" PrimaryGroupID 1000

    echo "Set $casperDPReadWriteShortName password..."
    dscl . -passwd "/Users/$casperDPReadWriteShortName" "$casperDPReadWritePassword"

    echo "Set $casperDPReadShortName password..."
    dscl . -passwd "/Users/$casperDPReadShortName" "$casperDPReadPassword"

    # enable the filesharing service
    /usr/sbin/sharing -a "$casperDPDirectory" -AS $casperDPDirectoryFriendlyName -s 110 -g 000

    # enable casperadmin and casperinstall access
    echo "Set ACL's for our Casper Users..."
    /bin/chmod +a "$casperDPReadWriteShortName allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity" "$casperDPDirectory"
    /bin/chmod +a "$casperDPReadShortName allow list,search,readattr,readextattr,readsecurity" "$casperDPDirectory"

}

windowsVMSetup() {

    #man VBoxManage
    #windows VM image will need to be built and deployed
    # vboxmanage createvm --name "Windows 7" --register
    # vboxmanage startvm "Windows 7"
    # this is on hold
true;
}

zelloVMSetup() {

    #man VBoxManage
    #zello is an OOB ova.
    # vboxmanage import "/var/rh/zello.ova"
    # vboxmanage startvm "Zello Server 64"
true;
}

prestoSetup() {

    #probably some defaults write commands.

    #check if presto server is installed
    #set default settings for environment
    #apply license
true;
}

ScriptLogging(){

    if [[ -f "$log_location" ]]; then
        /bin/mv "$log_location" "$archive_log_location"
    fi

    ScriptLogging "  -------------------  "
    ScriptLogging " Starting Server Deploy "
    ScriptLogging "  -------------------  "
    ScriptLogging " "
    ScriptLogging "$(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging " "

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
