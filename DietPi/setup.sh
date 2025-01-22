#!/bin/bash

mkdir /home/pi
cd /home/pi
git clone https://github.com/estruyf/unicorn-busy-server.git
cd unicorn-busy-server

# https://github.com/estruyf/unicorn-busy-server/
# https://github.com/estruyf/unicorn-busy-server/blob/master/install-fallback.sh
# Install the required dependencies
apt-get install -y python3-pip python3-dev python3-spidev python3-gpiozero
pip3 install -r ./requirements.txt --break-system-packages

# Create the service
cp busylight.service /etc/systemd/system/busylight.service
systemctl enable busylight.service
systemctl start busylight.service

# Set up Pi as "USB stick"
if ! grep -q "^dtoverlay=dwc2" /boot/config.txt; then
  echo "dtoverlay=dwc2" >> /boot/config.txt
fi
if ! grep -q "load-module=dwc2" /boot/cmdline.txt; then
  sed -i '/rootwait/!b;/rootwait/ s/rootwait\(.*\)/rootwait load-module=dwc2\1/' /boot/cmdline.txt
fi

modprobe -r g_mass_storage
umount /mnt/usbstick
rm -rf /mnt/usbstick

if [ -f /piusb.bin ]; then
  echo "--- /piusb.bin already created, deleting..."
  rm /piusb.bin
fi

if [ ! -f /piusb.bin ]; then
  echo "--- Create /piusb.bin..."
  dd bs=1M if=/dev/zero of=/piusb.bin count=128
  mkdosfs /piusb.bin -F 32 --mbr=yes -n PIUSB
  echo "--- /piusb.bin created..."
fi

mkdir /mnt/usbstick
chmod +w /mnt/usbstick
if ! grep -Fxq "/piusb.bin /mnt/usbstick vfat rw,users,user,exec,umask=000 0 0" /etc/fstab; then
  echo "/piusb.bin /mnt/usbstick vfat rw,users,user,exec,umask=000 0 0" >> /etc/fstab
fi
mount -a
systemctl daemon-reload

echo "#latestStatus=available#" > /mnt/usbstick/status.txt

# Install additional requirements
pip3 install requests --break-system-packages

echo "--- Downloading status_monitor.py..."
wget -O /home/pi/status_monitor.py https://github.com/tzwaeaen/busy-light/raw/refs/heads/main/DietPi/status_monitor.py
if [ $? -eq 0 ]; then
  echo "--- Download successful..."
else
  echo "--- Download failed..."
  exit
fi

# Run everything on reboot
echo "--- Adding boot tasks to crontab..."
(crontab -l 2>/dev/null; echo "@reboot /sbin/modprobe g_mass_storage file=/piusb.bin"; echo "@reboot python3 /home/pi/status_monitor.py") | sort -u | crontab -

echo "--- initiating reboot..."
reboot
