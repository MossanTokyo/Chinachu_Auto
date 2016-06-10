#!/bin/bash

###########################################################
# setting. change these for yourself
###########################################################
export records=$HOME/records/
export mytmp=$HOME/tmp/
export cuser=hogesan
export cpass=hogepass

 
# install prerequisites
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install chrony software-properties-common\
 wget pkg-config build-essential curl git-core libssl-dev\
 yasm libtool autoconf libboost-all-dev libpcsclite-dev dkms\
 pcsc-tools pcscd samba libpcsclite-dev unzip\
 linux-headers-`uname -r`
 
# samba settings
sudo sed -i "28i unix charset = UTF-8" /etc/samba/smb.conf
sudo sed -i "29i dos charset = CP932" /etc/samba/smb.conf
sudo sed -i "30i load printers = no" /etc/samba/smb.conf
sudo sed -i "31i disable spoolss = yes" /etc/samba/smb.conf
 
#[share] setting for samba
echo '[share]' | sudo tee -a /etc/samba/smb.conf
echo 'comment = Shared folder' | sudo tee -a /etc/samba/smb.conf
echo 'path = '$records | sudo tee -a /etc/samba/smb.conf
echo 'guest ok = yes' | sudo tee -a /etc/samba/smb.conf
echo 'writable = yes' | sudo tee -a /etc/samba/smb.conf
echo 'create mode = 0777' | sudo tee -a /etc/samba/smb.conf
echo 'directory mode = 0777' | sudo tee -a /etc/samba/smb.conf
 
# sambaのパスワードの設定
sudo smbpasswd -a $USER
 
#build pt3
mkdir ~/build
cd ~/build
git clone https://github.com/m-tsudo/pt3.git
cd pt3
make
sudo make install
# add this in dkms if you want
#sudo /bin/bash ./dkms.install
 
# add a blacklist
echo "blacklist earth-pt3" | sudo tee -a  /etc/modprobe.d/blacklist.conf
 
echo "blacklist kernel" | sudo tee -a  /etc/modprobe.d/blacklist.conf
 
#sudo reboot

# intall arib25
cd ~/build
git clone https://github.com/stz2012/libarib25.git
cd libarib25/
make
sudo make install
sudo /sbin/ldconfig
 
#install recpt1
cd ~/build
git clone git://github.com/stz2012/recpt1.git
cd recpt1/recpt1
./autogen.sh
./configure --enable-b25
make
sudo make install

# install chinachu
cd ~
  
git clone git://github.com/kanreisa/Chinachu.git ~/chinachu
cd ~/chinachu
  
echo "[]" > rules.json
cp ~/scripts/config.json ./

echo 1 | ./chinachu installer

echo "[]" > rules.json
 
cp config.sample.json config.json
 
# change settings
sed -i 's|./recorded/|'$records'|' ./config.json
sed -i 's|/tmp/|'$mytmp'|' ./config.json
sed -i "4i \ \ \"schedulerEpgRecordTime\": 180," ./config.json
sed -i 's|akari:bakuhatsu|'$cuser':'$cpass'|' ./config.json
 
./chinachu service operator initscript > /tmp/chinachu-operator
./chinachu service wui initscript > /tmp/chinachu-wui
 
cd /tmp
sudo chown root:root chinachu-*
sudo chmod 755 chinachu-*
sudo mv chinachu-* /etc/init.d/
sudo update-rc.d chinachu-operator defaults
sudo update-rc.d chinachu-wui defaults
