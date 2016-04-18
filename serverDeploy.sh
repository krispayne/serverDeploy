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
export localAdminUser="change" # Change!
export localAdminPass="change" # Change!
localAdminDir="/var" # Change!

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
casperDPReadWritePassword="change" # Change!
casperDPReadShortName="casperinstall"
casperDPReadRealName="Casper Install"
casperDPReadPassword="change" # Change!

# Virtual Box
zelloOVA="/var/location/ZelloServer.ova"
#windowsOVA="/var/location/Windows.ova"

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

    ScriptLogging "----------------------"
    ScriptLogging "Starting Server Deploy"
    ScriptLogging " "

    # Comment out functions you do not want to run.
    serverSetup
    serverCachingSetup
    casperDP
    zelloVMSetup
    #windowsVMSetup

    ScriptLogging "----------------------"
    ScriptLogging "Server Deploy Complete"
    ScriptLogging " "
    ScriptLogging "$(date +%Y-%m-%d\ %H:%M:%S)"
    ScriptLogging "----------------------"

}

# ---------------------------------------------------------------------------- #
#                      No need to edit below this line                         #
# ---------------------------------------------------------------------------- #

serverSetup() {
    # Setup Server.app
    # agree to terms, etc.
    ScriptLogging "----------------------"
    ScriptLogging "Server.app Setup"
    ScriptLogging " "

    SERVERVAR=$(expect -c '

        set timeout 300
        set theusername $env(localAdminUser)
        set thepassword $env(localAdminPass)

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
    ')

    echo "${SERVERVAR}" | ScriptLogging
    sleep 10
}

# Start setting up Server.app (Caching)
serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    ScriptLogging "----------------------"
    ScriptLogging "Caching Setup"
    ScriptLogging " "

    # start the service
    ScriptLogging " - Setting up Caching Server"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ServerRoot = "$cachingServerRoot" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:DataPath = "$cachingDataPath" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:LocalSubnetsOnly = "$cachingLocalSubnetsOnly" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:AllowPersonalCaching = "$cachingAllowPersonalCaching" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ReservedVolumeSpace = "$cachingReservedVolumeSpace" | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:CacheLimit = "$cachingCacheLimit" | ScriptLogging

    # restart the service
    ScriptLogging " - Restarting Caching Server"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching | ScriptLogging
    sleep 10
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching | ScriptLogging
    ScriptLogging " - Caching enabled and setup!"
}

casperDP() {

    ScriptLogging "----------------------"
    ScriptLogging "CasperShare Setup"
    ScriptLogging " "

    # Create the directory for the DP Share, if it doesn't already exist
    if [ -d "$casperDPDirectory" ]; then
        ScriptLogging " - Directory Exists "
    else
        ScriptLogging " - Create $casperDPDirectory"
        /bin/mkdir "$casperDPDirectory"
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    ScriptLogging " - Create $casperDPReadWriteShortName..."
    dscl . -create "/Users/$casperDPReadWriteShortName" | ScriptLogging
    dscl . -create "/Users/$casperDPReadWriteShortName" UserShell /bin/bash | ScriptLogging
    dscl . -create "/Users/$casperDPReadWriteShortName" RealName "$casperDPReadWriteRealName" | ScriptLogging
    dscl . -create "/Users/$casperDPReadWriteShortName" UniqueID $RANDOM | ScriptLogging
    dscl . -create "/Users/$casperDPReadWriteShortName" PrimaryGroupID 1000 | ScriptLogging

    ScriptLogging " - Create $casperDPReadShortName..."
    dscl . -create "/Users/$casperDPReadShortName" | ScriptLogging
    dscl . -create "/Users/$casperDPReadShortName" UserShell /bin/bash | ScriptLogging
    dscl . -create "/Users/$casperDPReadShortName" RealName "$casperDPReadRealName" | ScriptLogging
    dscl . -create "/Users/$casperDPReadShortName" UniqueID $RANDOM | ScriptLogging
    dscl . -create "/Users/$casperDPReadShortName" PrimaryGroupID 1000 | ScriptLogging

    ScriptLogging " - Set $casperDPReadWriteShortName password..."
    dscl . -passwd "/Users/$casperDPReadWriteShortName" "$casperDPReadWritePassword" | ScriptLogging

    ScriptLogging " - Set $casperDPReadShortName password..."
    dscl . -passwd "/Users/$casperDPReadShortName" "$casperDPReadPassword" | ScriptLogging

    # enable the filesharing service
    /usr/sbin/sharing -a "$casperDPDirectory" -AS $casperDPDirectoryFriendlyName -s 110 -g 000 | ScriptLogging

    # enable casperadmin and casperinstall access
    ScriptLogging " - Set ACL's for our Casper Users..."
    /bin/chmod +a "$casperDPReadWriteShortName allow list,add_file,search,add_subdirectory,delete_child,readattr,writeattr,readextattr,writeextattr,readsecurity" "$casperDPDirectory" | ScriptLogging
    /bin/chmod +a "$casperDPReadShortName allow list,search,readattr,readextattr,readsecurity" "$casperDPDirectory" | ScriptLogging

    # Start filesharing in server
    ScriptLogging " - Turning on FileSharing"
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start sharing | ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start smb | ScriptLogging
    ScriptLogging " - FileSharing enabled and setup!"

}

windowsVMSetup() {
    # windows VM image will need to be built and deployed
    # vboxmanage import ${windowsOVA}
    # vboxmanage startvm "Windows 7"
    # this is on hold
    echo " ---- Windows! ----" | ScriptLogging
}

zelloVMSetup() {

    ScriptLogging "----------------------"
    ScriptLogging "Zello OVA Setup"
    ScriptLogging " "

    touch ${localAdminDir}/${localAdminUser}/Library/LaunchDaemons/com.rh.zelloserver.plist | ScriptLogging

    # Import Zello OVA
    vboxmanage import ${zelloOVA} | ScriptLogging


    ScriptLogging " - Creating LaunchAgent"
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
