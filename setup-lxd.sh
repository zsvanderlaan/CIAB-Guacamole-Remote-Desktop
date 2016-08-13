#!/bin/bash

if [ $(id -u) = 0 ]; then echo "Please DO NOT run this script as either SUDO or ROOT... run it as your normal UserID !"; exit 1 ; fi

#================================================================================================================
# setup-lxd.sh
#
# by brian mullan (bmullan.mail@gmail.com)
#
# Purpose:
#
#   This script will install LXD onto this Host/server/VM/lxc container
# 
# IMPORTANT NOTE:  run this script as your normal non-sudo userID do NOT run as SUDO !!
#
# AFTER this script finished installing LXD do the following:
# 1) at the command line enter the command -  newgrp lxd
# 2) then execute the script setup-containers.sh to complete the installation of 2 LXC containers
#    cn1 and cn2.   cn1 will have Ubuntu-MATE Desktop installed into it and cn2 will have Xubuntu Desktop (xfce4)
#
#
#================================================================================================================
# Copyright (c) 2016 Brian Mullan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#================================================================================================================

# set location where the installation files were placed when they were UNTarred.  If you put them somewhere 
# else then change the following to point to that directory

files=/opt/ciab/

#-------------------------------------------------------------------------------------------------------------
# Assumptions:
# 1) you are running this script on the same HOST where we previously installed ciab-desktop 
#    since when we did that all of the ciab-desktop bundled bash scripts etc were all copied onto that machine
#    or vm etc.
# 2) you are in a terminal in the directory on the Host that contains all of the ciab-desktop scripts etc when
#    this setup-lxd.sh script is run
#-------------------------------------------------------------------------------------------------------------

# Now we need to make sure LXD/LXC is installed

# notify user/installer of what we are doing
echo
echo
echo "---------------------------------------------------------------------------------"
echo "Installing LXD/LXC to support orchestration/management/use of LXC containers both"
echo "on remote or local Servers/Hosts!"
echo
echo "When the following installs LXD you will be presented with 11-12 screens/forms"
echo "concerning IPv4, DHCP, and IPv6 addressing for LXD on your system."
echo
echo "The 5th screen/form is titled CONFIGURING LXD but is where it asks for the IP"
echo "address to use for LXD.   This will by default be some random 10.x.x.x IP address"
echo
echo "You can accept the default it provides or change it to something like 10.0.3.1"
echo "which is the traditional IP of the predecessor LXC lxCbr0 bridge that lxDbr0"
echo "replaces."
echo 
echo "This IP address for the lxdbr0 bridge is really only important in the context of"
echo "CIAB Remote Desktop in regards to enabling audio/sound from the 2 LXD containers"
echo "created later to be heard by the remote user."
echo
echo "That enablement is provided by each user's .bashrc file containing & exporting a"
echo "PulseAudio environment variable PULSE_SERVER=X.X.X.X for each user where X.X.X.X"
echo "needs to be the IP address of the Host Server (ie the IP address of the lxdbr0"
echo "bridge."
echo
echo "I've tried within the following scripts to parse out whatever IP address you"
echo "chose & inserting the PULSE_SERVER=X.X.X.X statement into the LXD container's"
echo "/etc/bash.bashrc file which is the template from which all future added UserID"
echo "accounts get their default .bashrc file contents."  
echo "---------------------------------------------------------------------------------"
echo
echo
read -p "Press any key to continue..."
echo
echo

# On ubuntu 16.04 LXD comes pre-installed but we will uninstall/reinstall lxd to make
# sure

sudo apt purge lxd -y
sudo apt install lxd -y

echo
echo
echo 
echo "*****************************************************************************************"
echo
echo "At the prompt, execute the following command to complete installation of LXD."
echo
echo "    $ ./setup-containers.sh"
echo
echo "The above will complete the installation & configuration of 2 LXC containers CN1 and CN2."
echo
echo "cn1 will have the Ubuntu-MATE Desktop installed into it"
echo
echo "then we will use the lxc copy command to copy/clone cn1 to a 2nd container called cn2"
echo
echo
read -p "Press any key to perform the above installation step..."
echo
echo


# make sure the "newgrp lxd" command executes as a NON-sudo user.  
#
# NOTE: Also the newgrp command executes last in this script for a reason.
# After execution of the "newgrp" you cannot place any further cmds in this script as 
# they will not execute.  So to finish this up we put the "sudo lxd init" command in the 
# next script you'll execute which is "setup-containers.sh"

newgrp lxd

exit 0




