#!/usr/bin/env bash
set -e

##### functions

function led_turnon () {
    gpio -g write 21 1
    sleep $1
    gpio -g write 21 0
}

function led_blynk () {
    for i in {1..100};do $(led_turnon $1; sleep $1);done;
    echo setup failed.
}

##### error handling

# when an error occurs, blynk a led 100 times
trap 'gpio -g write 21 1' ERR

##### Start
echo 'Setup start.'

### LED port setting
gpio -g mode 21 out

### update packages
cd $HOME
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none apt-get -y upgrade

### install some packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y expect

### install tightvncserver
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tightvncserver

### set vncserver password
/usr/bin/expect <<EOF
spawn "/usr/bin/vncserver"
expect "Password:"
send "iot0x0x\r"
expect "Verify:"
send "iot0x0x\r"
expect "view-only password (y/n)?"
send "n\r"
expect eof
exit
EOF

### some settings to run tightvncserver automatically at the boot time
cd $HOME

## create vncboot ##
cat << EOS >> vncboot
#! /bin/sh
# /etc/init.d/vncboot

### BEGIN INIT INFO
# Provides: vncboot
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start VNC Server at boot time
# Description: Start VNC Server at boot time.
### END INIT INFO

USER=pi
HOME=/home/pi

export USER HOME

case "\$1" in
start)
echo "Starting VNC Server"
#Insert your favoured settings for a VNC session
su $USER -c '/usr/bin/vncserver :1'
;;

stop)
echo "Stopping VNC Server"
su $USER -c '/usr/bin/vncserver -kill :1'
;;

*)
echo "Usage: /etc/init.d/vncboot {start|stop}"
exit 1
;;
esac

exit 0
EOS
## create vncboot end ##

sudo chown root:root vncboot
sudo chmod 755 vncboot
sudo cp -a vncboot /etc/init.d
sudo update-rc.d vncboot defaults

### update Node-RED package
cd $HOME
curl -sL https://raw.githubusercontent.com/node-red/raspbian-deb-package/master/resources/update-nodejs-and-nodered -o update-nodejs-and-nodered
echo "y" | bash update-nodejs-and-nodered
sudo systemctl enable nodered.service

### install BCM2835 library
cd $HOME
wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.51.tar.gz
tar xvf  bcm2835-1.51.tar.gz
cd bcm2835-1.51
./configure
make
sudo make check
sudo make install

### install node-dht-sensor
sudo npm install -g node-dht-sensor

### install node-red-contrib-dht-sensor
sudo npm install -g node-red-contrib-dht-sensor

### install node-red-contrib-ui
sudo npm install -g node-red-contrib-ui

### install node-red-m2x
sudo npm install -g node-red-m2x

##### complete

# when a setup complete successfully, LED is turned on.
gpio -g write 21 1

echo 'Setup completed.'
exit 0

