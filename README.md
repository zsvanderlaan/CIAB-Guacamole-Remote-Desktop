# Guacamole with Tomcat8, NGINX, MySQL, XRDP/X11RDP and LXD Containers for Clientless (browser only) Linux Remote Desktop
Guacamole HTML5 remote Desktop installation scripts utilizing Tomcat8, Nginx, Mysql and Ubuntu LXD containers to provide Ubuntu-Mate Desktops Remotely using only a Browser.

This collection of files when copied to a target Ubuntu 16.04 server (Cloud, VM or Physical server) will, when run as documented in the **README.PDF**, install and configure Guacamole clientless Remote Desktop gateway to enable users to access Remote Desktops off of the target Ubuntu 16.04 Server using only a HTML5 browser.

The installation/configuration also configures Guacamole to run on Tomcat8, with NGINX for reverse proxy & HTTPS support.

MySQL is used by Guacamole to maintain an encrypted Guacamole User and Connection database.

To enable connection for Remote Desktop off of the Ubuntu system XRDP and X11RDP have been built  from source to have the latest versions of both as those in most Distro repositories are quite old.   During installation both XRDP & X11RDP will be installed on the Ubuntu 16.04 server to enable RDP connections.

After installation & configuration of Guacamole/Tomcat/NGINX/MySQL these scripts will install the Ubuntu-Mate desktop on the target Server/Host.

Upon completion the Installer has only to log into Guacamole as Admin and add Users and an RDP "connection" to the Ubuntu Server/Host.

Using an AWS or Digital Ocean Cloud server which has multiple vCPU and SSDs for the installation the installation usually completes approximately 25-30 minutes.

At that point per instructions in the README.PDF file you can reboot your server & Users can begin logging in via a Browser by pointing their browser to the remote Server/host.

Example:

> https://ip_address_of_server/guacamole

Assuming they have had a Guacamole login created for they will log into Guacamole first and be presented with 1 or more Remote Desktop Server/Host "connections" the Guacamole Admin has created and enable for their account.

Choosing to log into the Ubuntu Server/Host connection a user will next be presented with the XRDP login screen.    

The XRDP User Login/Password *"may"*  be the same -or- different from that of the Guacamole Login/Password for that user.   That is the discretion of the Guacamole Admin and the User.    Because Guacamole can be thought of as a connection gateway to possibly many Remote Desktop Servers it makes sense to usually have separate Login/Password for Guacamole than for the User's Login/Password on the target Server/Hosts.

> NOTE:   Guacamole can be configured to use SSO ... this is not part of the CIAB installation script process though and you should refer to http://guacamole.incubator.apache.org/  for how to accomplish this using LDAP or AD etc.

The *XRDP Login/Password for a User will be the same as the Ubuntu Server/Host User Account* that the admin must create in advance for each User !

After successfully entering their XRDP Login/Password the user will be presented with their Ubuntu-Mate Desktop Environment with all the usual privileges/restrictions of working on any Linux system.

Run the Chromium (open source Chrome) web browser and go to Youtube and watch a video and you will be struck by how well video & audio works considering you are running a browser remotely inside an Ubuntu Remote Desktop session in your own local browser!

The CIAB installation scripts do NOT address Printer or File Share configuration but again refer to the Guacamole website (see above) for their documentation about how to configure such for your users.

Lastly... if you are interested there are several scripts provided which .. if you (the installer) choose to optionally install them will create 2 Ubuntu LXD Containers on the Server/Host.   In each LXD Container, XRDP/X11RDP and Ubuntu-Mate will be installed also.   Upon completion the Installer will need to add a new Guacamole "connection" configuration for each LXD container.

For each Remote Desktop user that the Admin wants to allow use of one or both of the LXD container Remote Desktops the Admin will have to check the box for that additional "connection" in each respective Guacamole User profile setting.

After doing so those Users upon logging into Guacamole will be presented with 1, 2 or 3 Remote Desktop Server connections to choose from and can login to any or all of them and using Guacamole switch back & forth between them.

One restriction using the LXD containers that I have not overcome yet is in regards to Audio support in the LXD container Desktops.   There is some configuration (possibly a bug) between XRDP & Pulseaudio (linux sound server).   

> **NOTE**   Audio DOES WORK in the LXD containers as long as the User logs into his/her "Host" Desktop session first and doesn't log out while using one or both of the LXD Container Desktops!

LXD containers also can be almost instantly "cloned" by a System Admin to create even more Remote Desktop Servers.   Unlike HW VMs (vmware, virtualbox, kvm etc) LXD containers utilize/share the Server/Host's Kernel and so take up very much less Compute/Memory resources than a HW VM.    With LXD you can often have 10-20X the number of "servers" configured for any specific Server/Host than you could using HW VMs.    Also, LXD can be used in Cloud Servers which generally is not possible with HW VM technologies. 

So some might wonder about what possible use cases for the multiple Remote Desktop servers (Host, container1 and container2) might be.   A couple ides might be that each has different Linux software installed for different purposes such as for different User collaboration groups (Marketing vs Sales),  or in regards to schools Grade 5 versus Grade 12 students?  

If you have the skills please feel free to help improve the above scripts & documentation/instructions in the **README.PDF** file.

And if anyone can figure out the quirk with Pulseaudio/XRDP the LXD containers so a User can just log into a container desktop without having to first login to their Host desktop session in order to have Audio in the container.... I'll buy you a beer (or two)  :-)
