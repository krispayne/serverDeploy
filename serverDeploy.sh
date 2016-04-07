#!/bin/bash
# Settings for mac mini servers

# Variables
# Log and log archive location
log_location="/var/log/serverDeploy_install.log"
archive_log_location="/var/log/serverDeploy_install-`date +%Y-%m-%d-%H-%M-%S`.log"

# Progress tracker:

# Settings we are going to need to edit
# Caching service - 100%
# Casper Distribution Point (http) - 40%
# Viritual Box - 0%
# Windows VM - 0%
# Zello VM - 0%
# Presto 2 - 0%

# Bring in our other dependencies

serverSetup() {
    # Setup Server.app
    # agree to terms, etc.
    # Setup Server.app
    source expected1.sh
    sleep 5
}

# Start setting up Server.app (Caching)
serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    # start the service
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching 2>&1 >> ScriptLogging

    # Set location of the ServerRoot
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ServerRoot = "/Library/Server" 2>&1 >> ScriptLogging

    # Set location of the Cache data
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:DataPath = "/Library/Server/Caching/Data" 2>&1 >> ScriptLogging

    # Set to only supply and recieve cache from local subnets
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:LocalSubnetsOnly = yes 2>&1 >> ScriptLogging

    # Disable personal caching
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:AllowPersonalCaching = no 2>&1 >> ScriptLogging

    # Reservered Volume Space - Needs research
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ReservedVolumeSpace = 10000000000 2>&1 >> ScriptLogging

    # Cache limit of ~50GB
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:CacheLimit = 50000000000 2>&1 >> ScriptLogging

    # restart the service
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching 2>&1 >> ScriptLogging
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching 2>&1 >> ScriptLogging

}

casperDP() {

    # Create the directory for the DP Share, if it doesn't already exist
    if [[ ! -d /Users/Shared/CasperShare ]]; then
        /bin/mkdir /Users/Shared/CasperShare/ 2>&1 >> ScriptLogging
    else
        ScriptLogging "Directory Exists"
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    dscl / -create /Users/casperadmin UserShell /bin/bash RealName "Casper Admin" 2>&1 >> ScriptLogging
    dscl / -create /Users/casperinstall UserShell /bin/bash RealName "Casper Install" 2>&1 >> ScriptLogging
    dscl / -passwd /Users/casperadmin INSERTPASSWORDHERE 2>&1 >> ScriptLogging
    dscl / -passwd /Users/casperinstall INSERTPASSWORDHERE 2>&1 >> ScriptLogging

    # enable the filesharing service
    /usr/sbin/sharing -a /Users/Shared/CasperShare -A CasperShare -S CasperShare -s 110 -g 000 2>&1 >> ScriptLogging

    # enable casperadmin and casperinstall access
    # need to parse through the serveradmin settings sharing results after setting up a dummy share
    # /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings sharing:sharePointList:_array_id:/Users/Shared/CasperShare:

}

vboxSetup() {

    #man vboxmanage
    #https://www.virtualbox.org/manual/ch08.html
true;
}

windowsVMSetup() {

    #man VBoxManage
    #windows VM image will need to be built and deployed
    # vboxmanage createvm --name "Windows 7" --register 2>&1 >> ScriptLogging
    # vboxmanage startvm "Windows 7" 2>&1 >> ScriptLogging
true;
}

zelloVMSetup() {

    #man VBoxManage
    #zello is an OOB ova.
    # vboxmanage import "/var/rh/zello.ova" 2>&1 >> ScriptLogging
    # vboxmanage startvm "Zello Server 64" 2>&1 >> ScriptLogging
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

    if [ -n "$1" ]; then
        IN="$1"
    else
        read IN # This reads a string from stdin and stores it in a variable called IN
    fi

    DATE=`date +%Y-%m-%d\ %H:%M:%S`
    LOG="$log_location"

    echo "$DATE" " $IN" >> $LOG
}

mainScript() {
    # Run the script
    # Comment out functions you do not want to run.
    serverSetup
    serverCachingSetup
    #casperDP
    #vboxSetup
    #windowsVMSetup
    #zelloVMSetup
    #prestoSetup
}

mainScript
