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
#source expected1.sh

# Start setting up Server.app (Caching)

serverCachingSetup() {
    # start the service
    serveradmin start caching

    # define some settings
    serveradmin settings caching:ServerRoot = "/Library/Server"
    serveradmin settings caching:LocalSubnetsOnly = yes
    serveradmin settings caching:AllowPersonalCaching = no
    serveradmin settings caching:DataPath = "/Library/Server/Caching/Data"
    serveradmin settings caching:ReservedVolumeSpace = 25000000000
    serveradmin settings caching:CacheLimit = 53687091200

}

casperDP() {

}

vboxSetup() {

}

windowsVMSetup() {

}

zelloVMSetup() {


}

prestoSetup() {


}

main() {
    # Run the script
    # Comment out functions you do not want to run.
    serverCachingSetup
}
