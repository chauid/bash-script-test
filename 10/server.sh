#!bin/bash
#1.패키지 확인 bind9, bind9utils, sendmail, dovecot-pop3d
#2.메일서버 이름 설정
#3.호스트 이름 변경 /etc/hostsname /etc/hosts /etc/mail/local-host-names
#4./etc/bind/named.conf.option 파일 설정 /etc/bind/named.conf.options
#5.메일서버 도메인 이름 설정 /etc/bind/named.conf
#6.메일서버 도메인 포워드존 설정
#7.방화벽 설정
#8.네임서버 작동 확인
#9.NetworkManager 설정
#10.Sendmail 서버 파일 설정 /etc/mail/sendmail.cf
#11./etc/mail/access 파일 수정
#12.dovecot 서비스 파일 설정 /etc/dovecot/dovecot.conf /etc/dovecot/conf.d/10-mail.conf
#13.evolution 사용자 추가
#14.Sendmail, dovecot 서비스 시작
#15.재부팅
ins_bind9=$(dpkg -l bind9 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_bind9utils=$(dpkg -l bind9utils 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_sendmail=$(dpkg -l sendmail 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_dovecot=$(dpkg -l dovecot-pop3d 2> /dev/null | grep ii | cut -d ' ' -f 1)
echo "[이것이 우분투 리눅스다] 자동설치"
echo "Chapter 10 [메일 서버 설치와 운영]"
echo "Server PC에서 실행해 주세요."
echo "server(B) PC 설정을 모두 마치고 실행해주세요."
read -p "server(B) 설정을 모두 마쳤으면 y를 입력하세요.(y/n) : " answer
if [ "$answer" != "y" ]; then
    exit 0
fi
echo "패키지 설치 확인(1/15)"
if [ "$ins_bind9" == "ii" ]; then
    echo "bind9 설치됨."
else
    echo "bind9설치 안됨."
    read -s -n 1 -p "bind9 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "bind9 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y bind9 > /dev/null
fi
if [ "$ins_bind9utils" == "ii" ]; then
    echo "bind9utils 설치됨."
else
    echo "bind9utils 설치 안됨."
    read -s -n 1 -p "bind9utils 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "bind9utils 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y bind9utils > /dev/null
fi
if [ "$ins_sendmail" == "ii" ]; then
    echo "sendmail 설치됨."
else
    echo "sendmail 설치 안됨."
    read -s -n 1 -p "sendmail 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "sendmail 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y sendmail > /dev/null
fi
if [ "$ins_dovecot" == "ii" ]; then
    echo "dovecot-pop3d 설치됨."
else
    echo "dovecot-pop3d 설치 안됨."
    read -s -n 1 -p "dovecot-pop3d 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "dovecot-pop3d 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y dovecot-pop3d > /dev/null
fi
echo "메일서버 이름 설정(2/15)"
while true; do
    read -p "메일서버 이름(ex:mail.nate.com) : " mailservername
    read -p "메일서버의 이름이 $mailservername이 맞습니까?(y/n) " answer
    if [ "$answer" == "y" ]; then
        break
    fi
    clear
done
while true; do
    read -p "메일서버(B) 이름(ex:mail.nate.com) : " mailserverBname
    read -p "메일서버의 이름이 $mailserverBname이 맞습니까?(y/n) " answer
    if [ "$answer" == "y" ]; then
        break
    fi
    clear
done

while true; do
    read -p "메일서버(B)의 IP : " mailserverB_IP
    read -p "메일서버의 이름이 $mailserverB_IP이 맞습니까?(y/n) " answer
    if [ "$answer" == "y" ]; then
        break
    fi
    clear
done
echo "호스트 이름 변경(3/15)"
defaulthost=$(cat /etc/hosts | grep 127.0.1.1)
currentIP=$(ifconfig | sed -n '/broadcast/p' | cut -d ' ' -f 10) > /dev/null
is_AlreadySethost=$(cat /etc/hosts | grep "$currentIP" | cut -c 1)
printf "$mailservername" > /etc/hostname
if [ "$is_AlreadySethost" == "1" ]; then
    echo "이미 메일서버 호스트가 등록되어있습니다."
    echo "$mailservername으로 바꿉니다."
    sed -i "/^$currentIP/s/.*/$currentIP\t$mailservername/g" /etc/hosts
else
    sed -i "/^$defaulthost/s/.*/$defaulthost\n$currentIP\t$mailservername/g" /etc/hosts
fi
sed -i '1,2!d' /etc/mail/local-host-names
printf "$mailservername\n" > /etc/mail/local-host-names
echo "named.conf.options 파일 설정(4/15)"
is_setoptions=$(cat /etc/bind/named.conf.options | grep dnssec | cut -d ' ' -f 2)
if [ "$is_setoptions" == "no;" ]; then
    echo "이미 설정되었습니다. /etc/bind/named.conf.options"
else
    sed -i '/^\tdnssec-validation/s/.*/\tdnssec-validation no;\n\trecursion yes;\n\tallow-query { any; };/g' /etc/bind/named.conf.options
fi
echo "메일서버 도메인 이름 설정(5/15)"
printf "zone \"$mailservername\" IN {\n" >>  /etc/bind/named.conf
printf "\ttype master;\n" >> /etc/bind/named.conf
printf "file \"/etc/bind/$mailservername.db\";\n" >> /etc/bind/named.conf
printf "};\n" >> /etc/bind/named.conf
printf "\n"
printf "zone \"$mailserverBname\" IN {\n" >>  /etc/bind/named.conf
printf "\ttype master;\n" >> /etc/bind/named.conf
printf "file \"/etc/bind/$mailserverBname.db\";\n" >> /etc/bind/named.conf
printf "};\n" >> /etc/bind/named.conf
echo "메일서버 도메인 포워드존 설정(6/15)"
if [ -e "/etc/bind/$mailservername.db" ]; then
    echo "이미 $mailservername.db 파일이 있습니다."
    echo "새로운 파일로 교체합니다."
    rm -rf /etc/bind/$mailservername.db
fi
if [ -e "/etc/bind/$mailserverBname.db" ]; then
    echo "이미 $mailserverBname.db 파일이 있습니다."
    echo "새로운 파일로 교체합니다."
    rm -rf /etc/bind/$mailserverBname.db
fi
touch /etc/bind/$mailservername.db
printf "\$TTL\t3H\n" >> /etc/bind/$mailservername.db
printf "@\tIN\tSOA\t@\troot.\t( 2 1D 1H 1W 1H)\n" >> /etc/bind/$mailservername.db
printf "\n" >> /etc/bind/$mailservername.db
printf "@\tIN\tNS\t@\n" >> /etc/bind/$mailservername.db
printf "\tIN\tA\t$currentIP\n" >> /etc/bind/$mailservername.db
printf "\tIN\tMX\t10\t$mailservername.\n" >> /etc/bind/$mailservername.db
printf "\n" >> /etc/bind/$mailservername.db
printf "mail\tIN\tA\t$currentIP" >> /etc/bind/$mailservername.db
touch /etc/bind/$mailserverBname.db
printf "\$TTL\t3H\n" >> /etc/bind/$mailserverBname.db
printf "@\tIN\tSOA\t@\troot.\t( 2 1D 1H 1W 1H)\n" >> /etc/bind/$mailserverBname.db
printf "\n" >> /etc/bind/$mailserverBname.db
printf "@\tIN\tNS\t@\n" >> /etc/bind/$mailserverBname.db
printf "\tIN\tA\t$mailserverB_IP\n" >> /etc/bind/$mailserverBname.db
printf "\tIN\tMX\t10\t$mailserverBname.\n" >> /etc/bind/$mailserverBname.db
printf "\n" >> /etc/bind/$mailserverBname.db
printf "mail\tIN\tA\t$mailserverB_IP" >> /etc/bind/$mailserverBname.db
echo "방화벽 설정(7/15)"
ufw disable
echo "네임서버 작동 확인(8/15)"
systemctl restart named > /dev/null
systemctl enable named > /dev/null
StatusNamed=$(systemctl status named | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$StatusNamed" == "active" ]; then
    echo "named 서비스 정상 작동중."
else
    echo "오류 : named 서비스가 정상 작동중이 아님."
    exit 0
fi
backupDNS=$(grep nameserver /etc/resolv.conf) > /dev/null
sed -i "/^nameserver/s/.*/nameserver $currentIP/g" /etc/resolv.conf
sleep 1
is_workURL=$(nslookup $mailservername | head -1 | cut -c 1-2)
if [ "$is_workURL" != "Se" ]; then
    echo "네임서버가 작동하지 않음."
    sed -i "/^nameserver/s/nameserver $backupDNS/g" /etc/resolv.conf
    exit
else
    testmailserver=$(nslookup $mailservername | grep Address | tail -n 1 | cut -d ' ' -f 2)
    testmailserverB=$(nslookup $mailserverBname | grep Address | tail -n 1 | cut -d ' ' -f 2)
fi
if [ "$testmailserver" == "$currentIP" ]; then
    echo "메일서버 작동(1/2)"
else
    echo "메일서버 작동 오류(1/2) server PC Error!"
fi
if [ "$testmailserverB" == "$mailserverB_IP" ]; then
    echo "메일서버 작동(2/2)"
else
    echo "메일서버 작동 오류(2/2) server(B) PC Error!"
fi
echo "NetworkManager 설정(9/15)"
networkname=$(ls /etc/NetworkManager/system-connections/*.nmconnection)
sed -i "/^dns=/s/.*/dns=$currentIP;/g" "$networkname"
systemctl restart NetworkManager
systemctl enable NetworkManager
echo "Sendmail 서버 파일 설정(10/15)"
Cwhostname=$(echo $mailservername | cut -c 6-)
CwhostnameB=$(echo $mailserverBname | cut -c 6-)
CwcurrentIP=$(echo $currentIP | cut -c -11)
sed -i "/^Cw/s/.*/Cw$Cwhostname/g" /etc/mail/sendmail.cf
sed -i '/^O Daemon/s/, Addr=127.0.0.1/ /g' /etc/mail/sendmail.cf
echo "/etc/mail/access 파일 수정(11/15)"
sed -i '140,$d' /etc/mail/access
printf "$Cwhostname\tRELAY\n" >> /etc/mail/access
printf "$CwhostnameB\tRELAY\n" >> /etc/mail/access
printf "$CwcurrentIP\tRELAY" >> /etc/mail/access
makemap hash /etc/mail/access < /etc/mail/access
echo "dovecot 서비스 파일 설정(12/15)"
sed -i '/^#listen/s/#l/l/g' /etc/dovecot/dovecot.conf
sed -i "/^#base/s/.*/base_dir = \/var\/run\/dovecot\/\ndisable_plaintext_auth = no/g" /etc/dovecot/dovecot.conf
sed -i '/^#mail_access/s/.*/mail_access_groups = mail/g' /etc/dovecot/conf.d/10-mail.conf
sed -i '/^#lock/s/#l/l/g' /etc/dovecot/conf.d/10-mail.conf
echo "evolution 사용자 추가(13/15)"
read -p "추가할 사용자 이름 : " newuser
adduser $newuser
echo "Sendmail, dovecot 서비스 시작(14/15)"
systenctl restart sendmail
systenctl enable sendmail
systenctl restart dovecot
systenctl enable dovecot
echo "재부팅(15/15)"
echo "##########자동 설치 완료!##########"
echo "10초 후 재부팅 합니다."
sleep 10
reboot
