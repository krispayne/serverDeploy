#!/bin/bash
# Settings for mac mini servers

# Variables
# Log and log archive location
log_location="/var/log/serverDeploy_install.log"
archive_log_location="/var/log/serverDeploy_install-$(date +%Y-%m-%d-%H-%M-%S).log"

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
    ./serverSetup.exp "$username" "$password"
    sleep 5
}

# Start setting up Server.app (Caching)
serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    # start the service
    ScriptLogging " Setting up Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching

    # Set location of the ServerRoot
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ServerRoot = "/Library/Server"

    # Set location of the Cache data
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:DataPath = "/Library/Server/Caching/Data"

    # Set to only supply and recieve cache from local subnets
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:LocalSubnetsOnly = yes

    # Disable personal caching
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:AllowPersonalCaching = no

    # Reservered Volume Space - Needs research
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:ReservedVolumeSpace = 10000000000

    # Cache limit of ~50GB
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings caching:CacheLimit = 50000000000

    # restart the service
    ScriptLogging " Restarting Caching Server "
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching
    sleep 10
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching
}

casperDP() {

    # Create the directory for the DP Share, if it doesn't already exist
    if [[ ! -d /Users/Shared/CasperShare ]]; then
        /bin/mkdir /Users/Shared/CasperShare/
        ScriptLogging " Directory Exists "
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    dscl / -create /Users/casperadmin UserShell /bin/bash RealName "Casper Admin"
    dscl / -create /Users/casperinstall UserShell /bin/bash RealName "Casper Install"
    dscl / -passwd /Users/casperadmin INSERTPASSWORDHERE
    dscl / -passwd /Users/casperinstall INSERTPASSWORDHERE

    # enable the filesharing service
    /usr/sbin/sharing -a /Users/Shared/CasperShare -A CasperShare -S CasperShare -s 110 -g 000

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
    # vboxmanage createvm --name "Windows 7" --register
    # vboxmanage startvm "Windows 7"
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
