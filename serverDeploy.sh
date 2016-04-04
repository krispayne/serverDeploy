#!/bin/bash
# Settings for mac mini servers

# Variables

# Progress tracker:

# Settings we are going to need to edit
# Caching service - 80%
# Casper Distribution Point (http) - 0%
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

    #may only be `touch` for the dir.

}

vboxSetup() {

    #man VBoxManage

}

windowsVMSetup() {

    #man VBoxManage
    #windows VM image will need to be built and deployed

}

zelloVMSetup() {

    #man VBoxManage
    #zello is an OOB ova.

}

prestoSetup() {

    #probably some defaults write commands.

}

main() {
    # Run the script
    # Comment out functions you do not want to run.
    serverCachingSetup
}
