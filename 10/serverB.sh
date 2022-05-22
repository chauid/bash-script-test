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
echo "Excute in Server(B)"
echo "Pakage Check(1/)"
