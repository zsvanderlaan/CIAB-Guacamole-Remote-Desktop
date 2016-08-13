#!/bin/bash

#========================================================================================================================
# mk-cn1-environment.sh 
#
# by brian mullan (bmullan.mail@gmail.com)
#
# Purpose:
#
# Install the apt tool to speed up apt's thru multiple threads/connections to the repositories
# Install a local Ubuntu-Mate Desktop Environment (DE) into a VM or an LXC container
# Install misc useful apps/tools for future users of this DE container
#
# Installation Notes:
#
# This will take 10-20 minutes depending on speed of the host PC/server
#
#
#========================================================================================================================
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
#========================================================================================================================

#
#
#
read -p "Press any key to install the Ubuntu-MATE Desktop Environment into LXC container named cn1..."
#
#
#-----------------------------------------------------------------------------------------------------------------
# NOTE: all of the following script will be executed in the LXC containers created not on the HOST
#-----------------------------------------------------------------------------------------------------------------

# NOTE:  the setup-lxd.sh script will have passed a UserID parameter to this script we need to save that for use later

userID=$1

# Note I am currently using Ubuntu 16.04 (xenial) for both Host & Containers so if you change to 16.04 etc tomorrow adjust the
# following appropriately

# add Canonical Partner repositories

echo "deb http://archive.canonical.com/ubuntu xenial partner" | sudo tee -a /etc/apt/sources.list
echo  "deb-src http://archive.canonical.com/ubuntu xenial partner" | sudo tee -a /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list

sudo apt update
sudo apt upgrade -y

#======================================================================================================

# "Make sure 'software-properties' is installed for add-apt-repository won't work..."

sudo apt install software-properties-common -y

#Install miscellaneous

sudo apt install pulseaudio alsa-base alsa-utils linux-sound-base gstreamer1.0-pulseaudio gstreamer1.0-alsa libpulse-dev libvorbis-dev -y


# Install UBUNTU-MATE desktop environment as default for Guacamole RDP User to work with.


#========================================================================================
# 2 ways to install a minimal MATE desktop if the 2nd doesn't work ... comment it out and
# uncomment the 1st and try it..?

sudo add-apt-repository ppa:ubuntu-mate-dev/xenial-mate -y

sudo apt update

sudo apt upgrade

sudo apt install lightdm ubuntu-mate-core ubuntu-mate-desktop ubuntu-restricted-extras ubuntu-restricted-addons -y

echo "Desktop Install Done"

# "Configure the Xsession file default desktop environment to make ALL future Users default xsession to be UBUNTU-MATE..."

sudo update-alternatives --set x-session-manager /usr/bin/mate-session

#======================================================================
# "Install misc useful sw apps/tools for the future users..."
#
# "gdebi - to support cli .DEB installs (if a sudo user)"
# "nano - my favorite quick/easy cli text editor"
# "firefox - the browser obviously"
# "terminator - my favorite 'multi-window' Terminal program"
# "synaptic - so future sudo users can manage sw apps easier"
#======================================================================

sudo apt install openssh-server gdebi nano terminator synaptic wget curl ufw network-manager gedit -y

# enable ufw

sudo ufw enable

#==============================================
# open certain ports on the ciab-desktop server

sudo ufw allow 22          # ssh
sudo ufw allow 8080        # http
sudo ufw allow https       
sudo ufw allow 3389        # rdp
sudo ufw allow 4822        # guacd
sudo ufw allow 4713        # pulseaudio
sudo ufw allow 5353        # avahi

# install xrdp & x11rdp
sudo dpkg -i /home/$userID/xrdp.deb
sudo dpkg -i /home/$userID/x11rdp.deb

# remove systemd xrdp start files as they for some reason don't work right.   This will
# leave upstart to start xrdp at system boot

sudo rm /lib/systemd/system/xrdp*

#---------------------------------------------------------------------------------------------
# In setup-containers.sh we used LXC to copy the ciab-logo.bmp to the $USER (the installers)
# new acct in this container. Here we move it from there to where it needs to be in order
# for it to be displayed on the xrdp login screen

# first make sure the directory exists... it should but just in case

sudo mkdir /usr/local/share/xrdp

sudo cp /home/$userID/ciab-logo.bmp /usr/local/share/xrdp/ciab-logo.bmp

# We are going to add Pulseaudo TCP load module to both system.pa and default.pa.   That way it doesn't matter if pulseaudio
# is configured to run in default "per user" mode or in the "system wide" mode.

# if running Pulseaudio in normal "per user" mode...
sudo echo "load-module module-native-protocol-tcp" | sudo tee -a /etc/pulse/default.pa
sudo echo "load-module module-xrdp-sink" | sudo tee -a /etc/pulse/default.pa
sudo echo "load-module module-xrdp-source"| sudo tee -a /etc/pulse/default.pa

# if running Pulseaudio in "system" mode...
sudo echo "load-module module-native-protocol-tcp" | sudo tee -a /etc/pulse/system.pa
sudo echo "load-module module-xrdp-sink" | sudo tee -a /etc/pulse/system.pa
sudo echo "load-module module-xrdp-source"| sudo tee -a /etc/pulse/system.pa

#=================================================================================================
# change browsers to chromium-browser by installing it & removing firefox.  
# we do this because chromium is the basis of Chrome has been shown to have the better performance 
# with Guacamole

sudo apt install chromium-browser adobe-flashplugin -y
sudo apt remove firefox -y

#==============================================================================================================================================
# in order for all new users added to this server via sudo adduser xxx in the future we need to change the /etc/adduser.conf file
# to set /etc/adduser.conf to add all new users accounts created to the audio/pulse/pulse-access groups
#
# To do this we need to change the following 2 lines in adduser.conf.
#
# The following line needs to be first be uncommented & also changed to "include" the groups we want the user added to
##EXTRA_GROUPS="dialout cdrom floppy audio video plugdev users"
# and 
# The following line just needs to be uncommented so the EXTRA_GROUPS option above will be default behavior for adding new, non-system users
##ADD_EXTRA_GROUPS=1
#
# make the 1st change
sudo sed -i 's/#EXTRA_GROUPS="dialout cdrom floppy audio video plugdev users"/EXTRA_GROUPS="audio pulse pulse-access"/' /etc/adduser.conf
# make the 2nd change
sudo sed -i 's/#ADD_EXTRA_GROUPS=1/ADD_EXTRA_GROUPS=1/' /etc/adduser.conf

# copy our custom built pulseaudio drivers for xrdp/freerdp to the correct directory
# In ubuntu 16.04 this is pulseaudio 8.0. 

sudo mv /home/$userID/module-xrdp*.so   /usr/lib/pulse-8.0/modules
sudo chown root:root /usr/lib/pulse-8.0/modules/module-xrdp*.so
sudo chmod 644 /usr/lib/pulse-8.0/modules/module-xrdp*.so

# make sure the "installing" user is a member of audio/pulse/pulse-access groups
# any users added later via the CLI by the Admin will automatically be added to these "groups"

sudo adduser $userID pulse
sudo adduser $userID pulse-access
sudo adduser $userID audio

#=======================================
# Clean up some things before exiting...

sudo apt-get autoremove -y

#
#
# "Mate Desktop Environment installation in CN1 is finished.."
#
# "*** Remember to create some UserID's in the LXC container CN1 for your CIAB Desktop users ! "
#
#
#

exit 0

