#!/bin/bash
#1.Pakage Check
#2.Firewall Check
#3.Set welcome msg
#4.vsftpd service start
echo "[This is ubuntu linux] Auto install"
echo "Chapter 09 [Nameserver install and operation]"
echo "Excute in Server(B)"
echo "Pakage Check(1/4)"
ins_vsftpd=$(dpkg -l vsftpd 2> /dev/null | grep ii | cut -d ' ' -f 1)
if [ "$ins_vsftpd" == "ii" ]; then
    echo "vsftpd pakage is installed."
else
    echo "vsftpd pakage is not installed."
    read -s -n 1 -p "Install vsftpd. Press any key to continue."
    apt-get install vsftpd -y vsftpd
fi
echo "Firewall Check(2/4)"
ufw allow 21
echo "Set welcome msg(3/4)"
cd /srv/ftp
touch welcome.msg
echo "###########################" >> welcome.msg
echo "Welcome !!! Ubuntu 20.04 LTS FTP Server" >> welcome.msg
echo "###########################" >> welcome.msg
echo "Start vsftpd service(4/4)"
systemctl restart vsftpd
systemctl enable vsftpd
StatusFTP=$(systemctl status vsftpd | grep Active | cut -d ' ' -f 7)
if [ "$StatusFTP" == "active" ]; then
    echo "vsftpd is active."
else
    echo "Error : vsftpd is not active"
    exit
fi
