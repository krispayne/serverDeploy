#!/bin/bash
# Settings for mac mini servers

# Variables

# Progress tracker:

# Settings we are going to need to edit
# Caching service - 100%
# Casper Distribution Point (http) - 40%
# Viritual Box - 0%
# Windows VM - 0%
# Zello VM - 0%
# Presto 2 - 0%

# Bring in our other dependencies


# Start setting up Server.app (Caching)

serverCachingSetup() {

    # Credit:
    # http://krypted.com/mac-security/the-new-caching-service-in-os-x-server/
    # http://krypted.com/mac-security/use-the-caching-server-in-os-x-server-5/

    # Setup Server.app
    #source expected1.sh

    # start the service
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
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin stop caching
    /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin start caching

}

casperDP() {

    # Create the directory for the DP Share, if it doesn't already exist
    if [[ ! -d /Users/Shared/CasperShare ]]; then
        /bin/mkdir /Users/Shared/CasperShare/
    else
        echo "Directory Exists"
    fi

    # Create users for the share: casperadmin (read/write) casperinstall (read)
    dscl / -create /Users/casperadmin UserShell /bin/bash RealName "Casper Admin"
    dscl / -create /Users/casperinstall UserShell /bin/bash RealName "Casper Install"
    dscl / -passwd /Users/casperadmin INSERTPASSWORDHERE
    dscl / -passwd /Users/casperinstall INSERTPASSWORDHERE

    # enable the filesharing service
    /usr/sbin/sharing -a /Users/Shared/CasperShare -A CasperShare -S CasperShare -s 110 -g 000

    # enable casperadmin and casperinstall access
    # need to parse through the seradmin settings sharing results after setting up a dummy share
    # /Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin settings sharing:sharePointList:_array_id:/Users/Shared/CasperShare:


}

vboxSetup() {

    #man VBoxManage

}

windowsVMSetup() {

    #man VBoxManage
    #windows VM image will need to be built and deployed
    # VBoxManage startvm windows

}

zelloVMSetup() {

    #man VBoxManage
    #zello is an OOB ova.
    # VBoxManage startvm zello

}

prestoSetup() {

    #probably some defaults write commands.

}

main() {
    # Run the script
    # Comment out functions you do not want to run.
    serverCachingSetup
}
