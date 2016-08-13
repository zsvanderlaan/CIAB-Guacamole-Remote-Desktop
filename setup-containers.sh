#!/bin/bash

# NOTE:  This script should NOT be executed as SUDO or ROOT .. but as a normal UserID

# Check if user is root or sudo ... if so... then exit and tell user.

echo
echo
if [ $(id -u) = 0 ]; then echo "Do NOT run this script SUDO or ROOT... please run as your normal UserID !"; exit 1 ; fi
echo
echo

#================================================================================================================
# setup-containers.sh 
#
# by brian mullan (bmullan.mail@gmail.com)
#
# Purpose:
#
#   use LXD/LXC instead of traditional LXC to create LXC containers on a Host for use with CIAB-DESKTOP
#
#   for more guidance on LXD see:   https://linuxcontainers.org/lxd/getting-started-cli/
# 
# IMPORTANT NOTE:  run this script as your normal non-sudo userID do NOT run as SUDO !!
#
# Basic LXD/LXC commands...
#
# To register locally the Default LXD/LXC repository of Template "images" for pre-built LXC rootfs which include
# CentOS, Ubuntu, Debian, Fedora, OpenSuse, Oracle etc
#
# NOTE:  this only needs to be done once...
#
#           $ lxc remote add images images.linuxcontainers.org
#
# To list all available LXD/LXC images you can use after doing the above "add" command (its a long list so you
# may want to redirect it to a file so you can look at it later:
#
#           $ lxc image list images:
#
# To launch (create & start) an LXD/LXC container pick the image/architecture/distro you want to use:
#
# examples:
#    to launch a CentOS v7 x64 bit container:
#           $ lxc launch images:centos/7/amd64 my_centos_cn
#         or
#    to launch an Ubuntu xenial (re 15.10) x64 bit container:
#           $ lxc launch images:ubuntu/xenial/amd64 my_ubuntu_cn
#
# To get all info about an existing container:
#
#           $ lxc info cn_name
#
# To get a shell inside the container, or to run any other command that you want, you may do:
#
#           $ lxc exec cn_name /bin/bash
#
# To directly pull or push files from/to the container with the following.   This is particularly useful
# when you want to copy a Bash or Python script to an LXD/LXC container for later execution.
#
#           $ lxc file pull cn_name/path/to/file .
#          or
#           $ lxc file push /path/to/file cn_name/
#
# To run a command inside an LXD/LXC container without logging into it first use:
#
#      example - to run apt-get update inside the container:
#
#           $ lxc exec cn_name -- apt-get update
#
# To stop an LXD/LXC container:
#
#           $ lxc stop cn_name
#
# To delete an LXD/LXC container:
#
#           $ lxc delete cn_name
#
#
#
#=============================================================================================================
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
#=============================================================================================================

# set location where the installation files were placed when they were UNTarred.  If you put them somewhere 
# else then change the following to point to that directory

files=/opt/ciab/

# before we start creating containers we need to complete 2 more steps in the LXD setup/configuration

# make sure ROOT owns the unix.socket used by LXD
sudo chown root:lxd /var/lib/lxd/unix.socket

echo "********************************************************************************************************"
echo
echo "Next we need to make sure to initialize LXD which uses the command 'sudo lxd init'."
echo
echo "This command will begin a series of prompts for you to answer questions about the setup of the LXD"
echo "bridge used to communicate from the Host server to the LXD containers.   This bridge by default will"
echo "be called LXDBR0 unless you change that in one of the prompted questions.   Keep the default !"
echo
echo "You will also be asked for the IP address, DHCP etc of the LXD bridge/containers.   Just accept the"
echo "defaults for now !"
echo
echo "When prompted for whether you want to configure IPv6... I recommend answering NO for now !"
echo
echo
echo
read -p "Press any key to continue..."
echo
echo

sudo lxd init

#-------------------------------------------------------------------------------------------------------------
# Assumptions:
# 1) you are running this script on the same HOST where we previously installed ciab-desktop 
#    since when we did that all of the ciab-desktop bundled bash scripts etc were all copied onto that machine
#    or vm etc.
# 2) you are in a terminal in the directory on the Host that contains all of the ciab-desktop scripts etc when
#    this setup-containers.sh script is run
#-------------------------------------------------------------------------------------------------------------

# notify user/installer of what we are doing
echo
echo
echo "------------------------------------------------------------------------------------"
echo "Creating our 2 LXD/LXC containers and adding the User/Installer as a SUDO privileged"
echo "User Account in both of those containers.  We are naming our containers CN1 and CN2"
echo "------------------------------------------------------------------------------------"
echo
echo
read -p "Press any key to continue..."
echo
echo

#-------------------------------------------------------------------------------------------------------------
# for ciab-desktop demonstration use-case...
# lets create just 2 containers CN1 and CN2
#
# in CN1 we will pre-install the Ubuntu-MATE desktop environment
# For Container CN2 we will Clone/Copy the CN1 container with its Ubuntu-Mate desktop environment & name
# the new Container CN2
#-------------------------------------------------------------------------------------------------------------

# This will execute on the LXC Host.  Make the image prebuilt templates available locally to utilize:
#
# The following is commented out because its not needed any more by LXD

#lxc remote add images images.linuxcontainers.org

# Launch an Ubuntu xenial 16.04 64 bit containers and name it cn1.  We are launching CN1 as a
# PRIVILEGED container:

lxc launch images:ubuntu/xenial/amd64 cn1 -c security.privileged=true

# set LXC container CN1 to autostart when the Host is rebooted

lxc config set cn1 boot.autostart 1

#---------------------------------------------------------------------------------------------------------------
# Next we need to get the IP address of the LXD lxdbr0 bridge that was created when we installed LXD
# and add that to the global template used to create .bashrc files as the IP address
# for the PULSE_SERVER environment variable for all future Container desktop users.
# 
# This is needed so audio/sound in the Container for each user is redirected by PulseAudio in that 
# container to the PulseAudio Daemon in the Host server.    This way audio/sound in the container
# will be provided to the end-user's web browser so they hear audio/sound remotely.
#
# We do this by running ifconfig against the lxdbr0 interface & then parsing out the IP address of lxdbr0.
# Then we append to the Container's /etc/bash.bashrc file.
#---------------------------------------------------------------------------------------------------------------

lxdbr0_ip=$(/sbin/ifconfig lxdbr0|grep inet|head -1|sed 's/\:/ /'|awk '{print $3}')

pulse_setup=$'export PULSE_SERVER='$lxdbr0_ip

# copy the Host's /etc/bash.bashrc file so we can edit it (re append some statements to it)
# then we will "push" that copy into the CN1 container to replace the CN1 container's
# own /etc/bash.bashrc file contents
#
# append the PULSE_SERVER=X.X.X.X statement into the Container's /etc/bash.bashrc

sudo cp /etc/bash.bashrc /opt/ciab/bash.bashrc

sudo chmod 666 /opt/ciab/bash.bashrc

echo $pulse_setup | tee -a /opt/ciab/bash.bashrc

# now use LXC command to "push" that replacement bash.bashrc file into the CN1 container's /etc/ directory
# to replace its default with our edited version

sudo chmod 644 /opt/ciab/bash.bashrc

lxc file push /opt/ciab/bash.bashrc cn1/etc/

#--------------------------------------------------------------------------------------------------------
# Add the following 3 statement to the Host's "/etc/pulse/default.pa" config file 
# The 1st statement tells PulseAudio to load its TCP module and to permit access to the Host's PulseAudio 
# server daemon from localhost (127.0.0.1) plus any LXC containers attached to LXDBR0.  
# The 2nd two statements are load modules used by XRDP
#
# NOTE:  to make sure pulseaudio is running all the time so TCP connections can be made to it we run
#        pulseaudio in "system" mode.   In system mode, pulseaudio does NOT use /etc/pulse/default.pa
#        but instead uses /etc/pulse/system.pa.   So we will add some modifications to that config file
#        so containers can acccess pulseaudio for sound support.
#--------------------------------------------------------------------------------------------------------

lxdbr0_subnet=`echo $lxdbr0_ip | cut -d"." -f1-3`".0/24"

# We are going to add Pulseaudo TCP load module to both system.pa and default.pa.   That way it doesn't matter if pulseaudio
# is configured to run in default "per user" mode or in the "system wide" mode.

# if running Pulseaudio in normal "per user" mode...
echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;$lxdbr0_subnet auth-anonymous=1" | sudo tee -a /etc/pulse/default.pa
echo "load-module module-xrdp-sink" | sudo tee -a /etc/pulse/default.pa
echo "load-module module-xrdp-source"| sudo tee -a /etc/pulse/default.pa

# if running Pulseaudio in "system" mode...
echo "load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;$lxdbr0_subnet auth-anonymous=1" | sudo tee -a /etc/pulse/system.pa
echo "load-module module-xrdp-sink" | sudo tee -a /etc/pulse/system.pa
echo "load-module module-xrdp-source"| sudo tee -a /etc/pulse/system.pa

#---------------------------------------------------------------------------------------------------------------
# with the above done any future userID's created will inherit the environment variable PULSE_SERVER=X.X.X.X
# from /etc/bash.bashrc when they log in.
#
# With the correct PULSE_SERVER=lxdbr0_ip address which should let audio work no matter what you previously set
# as the IP address for the lxdbr0 bridge
#---------------------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------------------
# After the CN1 container is started we begin by first creating a new User Account using whoever is running this
# install script as the UserID.  We'll also make the new User in the container a privileged user (re sudo priv)
#---------------------------------------------------------------------------------------------------------------

# create the new User in the cn1 container

echo
echo
echo "--------------------------------------------------------------------------------------"
echo "Creating the User/Installer's account in Container CN1"
echo
echo "As normal when doing 'sudo adduser a_newID' you will be prompted to enter the new user"
echo "Password (twice) and then the User Name for the Acct, then some misc info."
echo "--------------------------------------------------------------------------------------"
echo
echo
read -p "Press any key to do this now for Container CN1..."
echo
echo

lxc exec cn1 -- adduser $USER

# set the above userIDs to have SUDO privileges in both CN1 and CN2 (so they can be an admin in them)
 
lxc exec cn1 -- adduser $USER adm
lxc exec cn1 -- adduser $USER sudo

#----------------------------------------------------------------------------------------------------------------
# Next pushing the appropriate script to its now running container.
#
# each bash script that we will use will pre-install the same general tools I find useful:
#      - terminator, gdebi, nano, apt-fast, synaptic
#      - openssh-server, firefox, git, wget, curl
#
# each script will also install both xrdp and x11rdp using the 2 .DEB files included in the ciab-desktop tar file
#
#
# to facilitate this we have 2 prebuilt bash scripts mk-cn1-environment.sh, mk-cn2-environment.sh
#
# These are simple scripts and are identical to each other except for which desktop they install
#
# push appropriate script to its container
#-----------------------------------------------------------------------------------------------------------------

cd $files

lxc file push ./mk-cn1-environment.sh cn1/home/$USER/

# push the 2 xrdp .DEB files to cn1
lxc file push ./xrdp.deb cn1/home/$USER/
lxc file push ./x11rdp.deb cn1/home/$USER/

# push the xrdp pulseaudio drivers into the containers
lxc file push ./module-xrdp*.so   cn1/home/$USER/

# copy our CIAB Desktop logo to each container & we will move it to the right directory later when
# the scripts mk-cn1-environments.sh and mk-cn2-environments.sh run.  Those 2 scripts run "inside"
# their respective LXC containers so at that time those scripts can easily move the ciab-logo.bmp
# file to the right directory in each container (directory - /usr/local/share/xrdp/)

lxc file push ./ciab-logo.bmp cn1/home/$USER/

#-------------------------------------------------------------------------------------------------------------------------
# Finally, execute the script in the CN1 container designed to install a complete Desktop environment so gets installed.
#
# step 1 - make sure all bash scripts we pushed are executable & owned by the $USER (current installer UserID)
# step 2 - execute the mk-cnX-environment.sh file in each container & let it do its job of installing a desktop
#          environment in each container

# make sure bash scripts we pushed are executable

# on cn1
lxc exec cn1 -- /bin/bash -c "chmod +x /home/$USER/*.sh"

# fix ownership of files we pushed

# on cn1
lxc exec cn1 -- /bin/bash -c "chown $USER:$USER /home/$USER/*.sh"
lxc exec cn1 -- /bin/bash -c "chown $USER:$USER /home/$USER/*.deb"

#--------------------------------------------------------------------------------------------
# make sure the Installing user is part of all the right Pulseaudio groups on the Host/Server

sudo adduser $USER audio
sudo adduser $USER pulse
sudo adduser $USER pulse-access


#---------------------------------------------------------------------------------------------------------
# the next step installs the Desktop environment in the CN1 container.  This will take a while (5-10 min).

echo
echo "Installing Ubuntu-MATE desktop into container cn1..."
echo
echo

# note: we pass $USER to the mk-cn1-environment.sh script so it can use it also
lxc exec cn1 -- /bin/bash -c "/home/$USER/mk-cn1-environment.sh $USER" 

echo
echo "Next we will Clone/Copy the CN1 container to a 2nd container called CN2..."
echo 
echo "Notice: using LXD the Clone/Copy only takes about 1 minute compared to the time it took to create the"
echo "        CN1 container initially.   This is just one of the benefits of LXD/LXC !"
echo
echo "        Cloning/Copying an existing container even a hundred times is a relatively fast process..."
echo

# Next we stop Container CN1 so we can copy/clone it to a new container CN2
lxc stop cn1
lxc copy cn1 cn2 

# restart CN1 
lxc start cn1

# set LXC container CN2 to autostart when the Host is rebooted
lxc config set cn2 boot.autostart 1

# Start container CN2
lxc start cn2

# Because we cloned CN1 to make CN2... CN2's hostname will still be 'CN1'.   
# We need to change CN2's hostname to CN2.

lxc exec cn2 -- /bin/bash -c "sed -i 's/cn1/cn2/' /etc/hostname"

# now when CN1 and CN2 are rebooted below CN2 will restart with 'CN2' as its hostname

# Next to prevent a problem with XRDP's use of pulseaudio we will comment out the statement
# in /etc/xrdp/sesman.ini that sets an Environment variable PULSE_SCRIPT for each logged in
# user to point to xrdp's default.pa file ... which prevents the Host's own pulseaudio
# /etc/pulse/default.pa file from being executed.
# We will do this in both CN1 and CN2 containers and in the HOST

# do host first
sudo sed -i 's/PULSE_SCRIPT/#PULSE_SCRIPT/' /etc/xrdp/sesman.ini

# then both containers...
lxc exec cn1 -- /bin/bash -c "sed -i 's/PULSE_SCRIPT/#PULSE_SCRIPT/' /etc/xrdp/sesman.ini"
lxc exec cn2 -- /bin/bash -c "sed -i 's/PULSE_SCRIPT/#PULSE_SCRIPT/' /etc/xrdp/sesman.ini"

# Now because of an apport bug that causes recurring error msgs to pop up on each login let's
# disable apport on host, cn1 and cn2

# on host
sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport

# in both containers
lxc exec cn1 -- /bin/bash -c "sed -i 's/enabled=1/enabled=0/' /etc/default/apport"
lxc exec cn2 -- /bin/bash -c "sed -i 's/enabled=1/enabled=0/' /etc/default/apport"


echo "LXD container CN2 has been created!  Was that quick or what?"
echo
echo 
echo
echo "LXD/LXC containers cn1 and cn2 should be running now with Ubuntu-Mate in both CN1 and CN2!"
echo
echo "Both containers should be rebooted to make sure each starts up correctly that xrdp is started okay."
echo
read -p "Press any key to continue..."
echo
echo

echo "Rebooting cn1..."
lxc exec cn1 -- /bin/bash -c "shutdown -r now"
echo
echo "Rebooting cn2..."
lxc exec cn2 -- /bin/bash -c "shutdown -r now"
echo
echo

# lets list the LXC containers just to check 
echo
echo " Check to see if cn1 and cn2 rebooted...and restarted okay."
echo
echo " When the listing of LXD/LXC containers appears write down the IP address of CN1 and CN2 !"
echo
echo " You will need those IP addresses later when you first login to Guacamole and configure"
echo " 'connections' to CN1 and CN2 so users can access them and their respective Desktop Environments."
echo


# wait 15 seconds for LXC containers to start back up then list them for the User

sleep 15
lxc list

echo
echo
echo " You should probably reboot the Server/Host one more time to make sure everything starts up as planned"
echo " and that you can successfully login via Guacamole and begin configuring connections, users, etc."
echo

exit 0



