#!/usr/bin/expect
# Credit http://krypted.com/mac-os-x-server/automating-the-server-app-setup-using-a-script/

set timeout 300
spawn /Applications/Server.app/Contents/ServerRoot/usr/sbin/server setup
expect "Press Return to view the software license agreement." { send \r }
expect "Do you agree to the terms of the software license agreement? (y/N)" { send "y\r" }
expect "User name:" { send MYADMINUSERNAME\r }
expect "Password:" { send MYPASSWORD\r }
interact
exit 0
