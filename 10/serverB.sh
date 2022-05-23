#!bin/bash
#1.Pakage Check sendmail, dovecot-pop3d
#2.set mailserver name
#3.host name setting /etc/hostname /etc/hosts /etc/mail/local-host-names 
#4.firewall disable
#5.Sendmail server file modify /etc/mail/sendmail.cf
#6./etc/mail/access file modify
#7.dovecot service file modify /etc/dovecot/dovecot.conf /etc/dovecot/conf.d/10-mail.conf
#8.add user
#9.Sendmail, dovecot start service
#10.reboot
echo "[This is ubuntu linux] Auto install"
echo "Chapter 10 [Mailserver install and operation]"
echo "Excute installer before Set netplan : nameserver->serverIP"
read -p "Input y to continue(y/n) : " answer
if [ "$answer" != "y" ]; then
    exit 0
fi
echo "Excute in Server(B)"
echo "Pakage Check(1/10)"
ins_sendmail=$(dpkg -l sendmail 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_dovecot=$(dpkg -l dovecot-pop3d 2> /dev/null | grep ii | cut -d ' ' -f 1)
if [ "$ins_sendmail" == "ii" ]; then
    echo "sendmail pakage is installed."
else
    echo "sendmail pakage is not installed."
    read -s -n 1 -p "Install sendmail. Press any key to continue."
    printf "\n"
    echo "installing sendmail... (Do not close terminal is installing)"
    apt-get install sendmail -y vsftpd > /dev/null
fi
if [ "$ins_dovecot" == "ii" ]; then
    echo "dovecot pakage is installed."
else
    echo "dovecot pakage is not installed."
    read -s -n 1 -p "Install dovecot. Press any key to continue."
    printf "\n"
    echo "installing dovecot... (Do not close terminal is installing)"
    apt-get install dovecot-pop3d -y vsftpd > /dev/null
fi
echo "set mailserver name(2/10)"
while true; do
    read -p "Mail server name(ex:mail.nate.com) : " mailservername
    read -p "Check Mail server name : $mailservername(y/n) " answer
    if [ "$answer" == "y" ]; then
        break
    fi
    clear
done
while true; do
    read -p "Mail server(B) name(ex:mail.nate.com) : " mailserverBname
    read -p "Check Mail server(B) name : $mailserverBname(y/n) " answer
    if [ "$answer" == "y" ]; then
        break
    fi
    clear
done
echo "host name setting(3/10)"
defaulthost=$(cat /etc/hosts | grep 127.0.1.1)
currentIP=$(ifconfig | sed -n '/broadcast/p' | cut -d ' ' -f 10) > /dev/null
is_AlreadySethost=$(cat /etc/hosts | grep "$currentIP" | cut -c 1)
printf "$mailservername" > /etc/hostname
if [ "$is_AlreadySethost" == "1" ]; then
    echo "Already Mail server has registered."
    echo "change to $mailservername"
    sed -i "/^$currentIP/s/.*/$currentIP\t$mailservername/g" /etc/hosts
else
    sed -i "/^$defaulthost/s/.*/$defaulthost\n$currentIP\t$mailservername/g" /etc/hosts
fi
sed -i '1,2!d' /etc/mail/local-host-names
printf "$mailservername\n" > /etc/mail/local-host-names
echo "firewall disable(4/10)"
ufw disable
echo "Sendmail server file modify(5/10)"
Cwhostname=$(echo $mailservername | cut -c 6-)
CwhostnameB=$(echo $mailserverBname | cut -c 6-)
CwcurrentIP=$(echo $currentIP | cut -c -11)
sed -i "/^Cw/s/.*/Cw$CwhostnameB/g" /etc/mail/sendmail.cf
sed -i '/^O Daemon/s/, Addr=127.0.0.1/ /g' /etc/mail/sendmail.cf
echo "/etc/mail/access file modify(6/10)"
sed -i '140,$d' /etc/mail/access
printf "$Cwhostname\tRELAY\n" >> /etc/mail/access
printf "$CwhostnameB\tRELAY\n" >> /etc/mail/access
printf "$CwcurrentIP\tRELAY" >> /etc/mail/access
makemap hash /etc/mail/access < /etc/mail/access
echo "dovecot service file modify(7/10)"
sed -i '/^#listen/s/#l/l/g' /etc/dovecot/dovecot.conf
sed -i "/^#base/s/.*/base_dir = \/var\/run\/dovecot\/\ndisable_plaintext_auth = no/g" /etc/dovecot/dovecot.conf
sed -i '/^#mail_access/s/.*/mail_access_groups = mail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i '/^#lock/s/#l/l/g' /etc/dovecot/conf.d/10-mail.conf
echo "add user(8/10)"
read -p "add new username : " newuser
adduser $newuser
echo "Sendmail, dovecot start service(9/10)"
systenctl restart sendmail
systenctl enable sendmail
systenctl restart dovecot
systenctl enable dovecot
echo "reboot(10/10)"
echo "##########Auto Install Complete!##########"
echo "reboot after 10 seconds."
sleep 10
reboot
