#!/bin/bash
#1.Pakage Check
#2.Firewall Check
#3.Set welcome msg
#4./etc/vsftpd.conf modify
#5.vsftpd service start
echo "[This is ubuntu linux] Auto install"
echo "Chapter 09 [Nameserver install and operation]"
echo "Excute in Server(B)"
echo "Pakage Check(1/5)"
ins_vsftpd=$(dpkg -l vsftpd 2> /dev/null | grep ii | cut -d ' ' -f 1)
if [ "$ins_vsftpd" == "ii" ]; then
    echo "vsftpd pakage is installed."
else
    echo "vsftpd pakage is not installed."
    read -s -n 1 -p "Install vsftpd. Press any key to continue."
    printf "\n"
    echo "installing vsftpd... (Do not close terminal is installing)"
    apt-get install vsftpd -y vsftpd > /dev/null
fi
echo "Firewall Check(2/5)"
ufw allow 21 > /dev/null
echo "Set welcome msg(3/5)"
cd /srv/ftp
if [ ! -f "./welcome.msg" ]; then
  touch welcome.msg
  echo "#######################################" >> welcome.msg
  echo "Welcome !!! Ubuntu 20.04 LTS FTP Server" >> welcome.msg
  echo "#######################################" >> welcome.msg
fi
echo "/etc/vsftpd.conf modify(4/5)"
is_banner=$(cat /etc/vsftpd.conf | grep anonymous_enable | cut -c 18-20)
if [ "$is_banner" == "YES" ]; then
  echo "banner is Already set."
else
  sed -i '/^anonymous_enable/s/.*/anonymous_enable=YES\nbanner_file=\/srv\/ftp\/welcome.msg/g' /etc/vsftpd.conf
fi
echo "Start vsftpd service(5/5)"
systemctl restart vsftpd > /dev/null
systemctl enable vsftpd > /dev/null
StatusFTP=$(systemctl status vsftpd | grep Active | cut -d ' ' -f 7)
if [ "$StatusFTP" == "active" ]; then
    echo "vsftpd is active."
else
    echo "Error : vsftpd is not active"
    exit
fi
echo "##########Auto Install Complete!##########"
