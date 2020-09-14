#!/bin/bash

# Break secondary NIC from bond0 and configure for internal net
backupdev=$(nmcli dev status | grep System | tail -1 | awk '{print $1}')
nmcli connection down "System $backupdev"
nmcli connection del "System $backupdev"
nmcli con add type ethernet con-name $backupdev ifname $backupdev
nmcli con mod $backupdev ipv4.addresses 192.168.2.2/24
nmcli con mod $backupdev ipv4.method manual
nmcli con up $backupdev

# Configure and enable dhcpd

cp /usr/lib/systemd/system/dhcpd.service /etc/systemd/system/
sed -i -e "s/\$DHCPDARGS/$backupdev \$DHCPDARGS/" /etc/systemd/system/dhcpd.service
systemctl --system daemon-reload
systemctl enable dhcpd
systemctl restart dhcpd.service
