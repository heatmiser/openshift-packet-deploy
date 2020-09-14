#!/bin/bash

wget -O /tmp/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x /tmp/jq
cp /tmp/jq /usr/local/bin

wget -O /tmp/yq https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64
chmod +x /tmp/yq
cp /tmp/yq /usr/local/bin

wget -O /tmp/virtctl https://github.com/kubevirt/kubevirt/releases/download/v0.30.5/virtctl-v0.30.5-linux-x86_64
chmod +x /tmp/virtctl
cp /tmp/virtctl /usr/local/bin

wget https://gist.githubusercontent.com/joemiller/4069513/raw/297ccb1edccc56fef2209d365f5f189f5f150cea/netspeed.sh -O /usr/local/bin/netspeed
chmod +x /usr/local/bin/netspeed

wget https://gist.githubusercontent.com/joemiller/4069513/raw/297ccb1edccc56fef2209d365f5f189f5f150cea/netpps.sh -O /usr/local/bin/netpps
chmod +x /usr/local/bin/netpps

yum install -y nginx nfs-utils haproxy firewalld git nvme-cli lvm2 qemu-img dhcp-server

systemctl start firewalld

# Update nginx configs for file hosting
sed -i "s|location / {|location / {\n             autoindex on;|g" /etc/nginx/nginx.conf
sed -i "s/80/8080/g" /etc/nginx/nginx.conf
rm -rf /usr/share/nginx/html/index.html
rm -rf /usr/share/nginx/html/poweredby.png
rm -rf /usr/share/nginx/html/nginx-logo.png

# Update firewalld

## Openshift firewall exceptions
firewall-cmd --zone=public --permanent --add-port=8080/tcp
firewall-cmd --zone=public --permanent --add-port=6443/tcp
firewall-cmd --zone=public --permanent --add-port=22623/tcp
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --zone=public --permanent --add-port=80/tcp
firewall-cmd --zone=public --permanent --add-port=1936/tcp

## NFS firewall exceptions
firewall-cmd --zone=public --permanent --add-service=nfs
firewall-cmd --zone=public --permanent --add-service=mountd
firewall-cmd --zone=public --permanent --add-service=rpc-bind

# Restart services
systemctl restart firewalld
systemctl enable nginx
systemctl start nginx

systemctl enable haproxy
systemctl start haproxy

systemctl enable nfs-server.service
systemctl start nfs-server.service

nvmeDevList=($(nvme list | grep "/dev" | awk '{print $1}'))

# Since this shell script is a terraform rendererd template, anywhere a
# bash array variable is referenced, we must use an additional $ in front
# of the array variable access (like $${hello}) to prevent Terraform from
# interpolating values from the configuration into the string
if (( $${#nvmeDevList[@]} > 0 )); then
  for i in $${nvmeDevList[@]}; do
    pvcreate $i
  done
  vgcreate -s 4M vgcnv01 $${nvmeDevList[@]}
  lvcreate -n lvcnv01 --extents 100%FREE -i $${#nvmeDevList[@]} -I 4MB vgcnv01
  mkfs.xfs -K /dev/vgcnv01/lvcnv01
  mkdir -p /mnt/nfs
  echo "/dev/mapper/vgcnv01-lvcnv01 /mnt/nfs xfs defaults 0 0" >> /etc/fstab
  mount /mnt/nfs
fi

mkdir -p /mnt/nfs/ocp
chmod -R 777 /mnt/nfs/ocp
mkdir -p /mnt/nfs/store0{0..9}
chmod -R 777 /mnt/nfs/store0{0..9}