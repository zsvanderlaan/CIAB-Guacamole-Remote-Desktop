#!/bin/bash


# NOTE:  Execute this Script as SUDO or ROOT .. NOT as a normal UserID

# Check if user is root or ... if NOT then exit and tell user.

if ! [ $(id -u) = 0 ]; then echo "Please run this script as either SUDO or ROOT !"; exit 1 ; fi

#==============================================================================================================================================
# ciab-remote-desktop by Brian Mullan, Raleigh NC USA, bmullan.mail@gmail.com
#
# ciab-desktop is a script which installs/integrates several technologies to provide a HTML5 browser based remote desktop capability TO a 
# Linux server.
#
# ANY device which has an HTML5 capable browser should be able to login after installation & initial connection/user setup.
#
# Benefit:  Since the User will be connected to a Remote Desktop ... it no longer matters how fast a cpu, how much memory or disk storage
#           the User's own local machine has (chromebook, tablet, phone or old PC)... everything is running virtually for them and you
#           can install ciab-desktop on even the most powerful Cloud servers with many cpu core, terabytes of memory & storage.
#
# This script can be run on any Ubuntu cloud/local server, pc, or even on a VM (KVM or VirtualBox) and also in an LXC container.
#
# Technologies involved include:  guacamole, xrdp, x11rdp, tomcat8, mysql, nginx, lxc and ubuntu
#
# Note:  you should run this setup.sh script as from "some" user (re user you created) home directory
#        When done it will have placed several tar.gz files as well as several new directories in that home directory.  You should be
#        able to safely delete any/all of those new files/directories after installation.
#
#
#=============================================================================================================================================
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
#==============================================================================================================================================

#----------------------------------------------------------------------------------------------------------------------------------------------
# IMPORTANT:
# set "files" to the location where installation files were UNTarred. If it was not in /opt/ciab then change to point to where you put them

files=/opt/ciab

cd $files


# add Canonical Partner repositories

echo "deb http://archive.canonical.com/ubuntu xenial partner" | tee -a /etc/apt/sources.list
echo "deb-src http://archive.canonical.com/ubuntu xenial partner" | tee -a /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list
echo "deb-src http://us.archive.ubuntu.com/ubuntu/ xenial-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list


apt-get update
apt-get upgrade -y

# install apt
apt-get install apt -y

# From here on we can use apt to update Everything
apt dist-upgrade -y

#Install miscellaneous

apt install pulseaudio pulseaudio-utils alsa-base alsa-utils linux-sound-base gstreamer1.0-pulseaudio gstreamer1.0-alsa libpulse-dev -y


# Install UBUNTU-MATE desktop environment as default for Guacamole RDP User to work with.


#========================================================================================
# 2 ways to install a minimal MATE desktop if the 2nd doesn't work ... comment it out and
# uncomment the 1st and try it..?

add-apt-repository ppa:ubuntu-mate-dev/xenial-mate -y

apt update

apt upgrade -y

apt install lightdm ubuntu-mate-core ubuntu-mate-desktop ufw ubuntu-restricted-extras ubuntu-restricted-addons -y

echo "Desktop Install Done"

#Configure the Xsession file default desktop environment
# change ALL future User default xsession to be UBUNTU-MATE

update-alternatives --set x-session-manager /usr/bin/mate-session 

# and some gui based useful tools that aren't included in the minimal-xubuntu-desktop

apt install gdebi synaptic gedit wget git terminator network-manager -y

# enable UFW then open ports we will be using

ufw enable

#==============================================
# open certain ports on the ciab-desktop server

ufw allow 22          # ssh
ufw allow 8080        # http
ufw allow https       
ufw allow 4822        # guacd
ufw allow 3389        # rdp
ufw allow 4713        # pulseaudio
ufw allow 5353        # avahi


cd $files

#==============================================================================================
# We need to do some pulseaudio/xrdp setup work...
#
# Copy our custom built pulseaudio drivers for xrdp/freerdp to the correct directory
# For Ubuntu 16.04 which uses Pulseaudio v8 this is the following

cp ./module-xrdp*.so   /usr/lib/pulse-8.0/modules


#============================================================================================================
# now install the .DEB files which should have been included in the .tar.gz file containing this build script
# and which should be in the same directory the script was in...

dpkg -i ./xrdp.deb
dpkg -i ./x11rdp.deb

# append the load-module statements for xrdp to the end of /etc/pulse/default.pa
# then comment out the /etc/xrdp/sesman.ini line that sets the PULSE_SERVER= statement for the users
# since we do NOT want xrdp's default.pa file pre-empting the pulseaudio default.pa file or the pulseaudio tcp
# module will never get loaded.


#=========================================================================================================================
# xrdp has some problem starting with systemd so I am taking a shortcut & just deleting those system xrdp service files... 
# that will force xrdp to be started by Upstart instead
#
# NOTE: you MAY see a SystemD ERROR in the terminal related to xrdp ... you can ignore it as we will
#       be setting xrdp to start using Upstart NOT SystemD...

rm /lib/systemd/system/xrdp*

#---------------------------------------------------------------------------------------------
# copy the CIAB logo to /usr/local/share/xrdp so it will be displayed on the xrdp login screen
# first make sure the directory exists... it should but just in case

cd $files
mkdir /usr/local/share/xrdp
cp ./ciab-logo.bmp /usr/local/share/xrdp/ciab-logo.bmp


#====================================================================================================
# change browsers to chromium/chrome bin installing chromium-browser & removing firefox.  
# we do this because Chromium is the basis for Chrome & has been shown to have the better performance 
# with Guacamole

apt install chromium-browser adobe-flashplugin -y
apt remove firefox -y

#===========================================================================================================================================
# in order for all new users added to this server via adduser xxx in the future we need to change the /etc/adduser.conf file
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
sed -i 's/#EXTRA_GROUPS="dialout cdrom floppy audio video plugdev users"/EXTRA_GROUPS="audio pulse pulse-access"/' /etc/adduser.conf
# make the 2nd change
sed -i 's/#ADD_EXTRA_GROUPS=1/ADD_EXTRA_GROUPS=1/' /etc/adduser.conf

#===================================================================================================================================
# NOTE:  the following section does NOT work right.  Maybe someone else can figure out why.
#        First you either need to create a SystemD init script to auto-start pulseaudio at boot in System Wide mode
#        -or- after the system boots SUDO SU to root and start pulseaudio in system wide mode (# pulseaudio --system)
#
#        However, in either case XRDP does not take Pulseaudio Output (even though PAVUCONTROL shows the XRDP SINK have sound data
#        in it when played) ... and fails to transfer it to the RDPSND channel that Guacamole utilizes to carry remote audio back
#        to the Remote Desktop user.
#
#        So for now... do not use the following section unless you are wanting to try to fix this (Let me know if you have success).
#
# On Host/Server we want Pulseaudio to always be running so we change the /etc/default/pulseaudio file to do that instead of running 
# only on a per-user basis (ie only when at least 1 user is logged in)
#
# To run pulseaudio as a system-wide daemon, we need to edit a few files.
#
# 1.) /etc/default/pulseaudio
#
#    PULSEAUDIO_SYSTEM_START=1
#
# 2.) /etc/pulse/daemon.conf - See man pulse-daemon.conf for more information.
#
#    daemonize = yes
#    local-server-type = system
#
# 3.) /etc/pulse/client.conf
#
#    autospawn = no

#touch /etc/default/pulseaudio
#echo "PULSEAUDIO_SYSTEM_START=1" | tee -a /etc/default/pulseaudio
#echo "DISALLOW_MODULE_LOADING=1" | tee -a /etc/default/pulseaudio
#echo "daemonize = yes" | tee -a /etc/pulse/daemon.conf
#echo "local-server-type = system" | tee -a /etc/pulse/daemon.conf
#echo "autospawn = no" | tee -a /etc/pulse/client.conf

#================={ End of pulseaudio system wide setup section }===================================================================

#=======================================
# Clean up some things before exiting...

apt-get autoremove -y

echo
echo
echo 
echo "***********************************************************************************************"
echo
echo " If you only want to use Guacamole to access the Server/Host Desktop -- "
echo " YOU ARE DONE !!   re: Do not execute the next script - setup-lxd.sh"
echo
echo " If you DO want to execute the Optional Creation & Installation of 2 more Desktop Servers using"
echo " LXD/LXC then continue with the following step." 
echo
echo " At the prompt, execute the script 'setup-lxd.sh'."
echo " NOTE:"
echo " DO NOT execute the next script as sudo/root !"   
echo
echo "    $ ./setup-lxd.sh"
echo
echo
echo
read -p "Press any key to continue or to stop Installation/Configuration at this point..."
echo
echo


exit 0









