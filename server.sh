#!/bin/bash
#1.패키지 확인 bind9, bind9utils, apache2
#2.네임서버의 IP설정 (현재 PC's IP)
#3.named.conf.option 파일 설정
#4.방화벽 설정 DNS53, FTP21, HTTP80
#5.named 서비스 시작
#6.네임서버 작동 확인
#7.웹페이지 Default 설정 /var/www/html
#8.도메인이름 설정 /etc/bind/named.conf
#9.도메인 포워드존 설정 /etc/bind/도메인이름.db
#10.apache2 서비스 시작
#11.bind9 서비스 시작
echo "[이것이 우분투 리눅스다] 자동설치"
echo "Chapter 09 [네임 서버 설치와 운영]"
echo "패키지 설치 확인(1/11)"
ins_bind9=$(dpkg -l bind9 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_bind9utils=$(dpkg -l bind9utils 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_apache2=$(dpkg -l apache2 2> /dev/null | grep ii | cut -d ' ' -f 1)
if [ "$ins_bind9" == "ii" ]; then
    echo "bind9 설치됨."
else
    echo "bind9설치 안됨."
    read -s -n 1 -p "bind9 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    echo "bind9 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y bind9
fi
if [ "$ins_bind9utils" == "ii" ]; then
    echo "bind9utils 설치됨."
else
    echo "bind9utils 설치 안됨."
    read -s -n 1 -p "bind9utils 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    echo "bind9utils 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y bind9utils
fi
if [ "$ins_apache2" == "ii" ]; then
    echo "apache2 설치됨."
else
    echo "apache2 설치 안됨."
    read -s -n 1 -p "bind9 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    echo "apache2 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y apache2
fi
echo "네임서버의 IP설정(2/11)"
currentIP=$(ifconfig | sed -n '/broadcast/p' | cut -d ' ' -f 10) > /dev/null
read -p "현재 PC의 사설IP가 $currentIP가 맞습니까?(y/n)" answer
if [ "$answer" == "n" -o "$answer" == "N" ]; then
    read -p "현재 PC의 IP : " currentIP
fi
echo "/etc/resolv.conf 파일의 네임서버를 $currentIP로 변경합니다."
backupDNS=$(grep nameserver /etc/resolv.conf) > /dev/null
sed -i "/^nameserver/s/.*/nameserver $currentIP/g" /etc/resolv.conf
printf "/etc/resolv.conf 파일 "
printf "%s\n" "$(cat /etc/resolv.conf | grep nameserver)"
echo "named.conf.option 파일 설정(3/11)"
sed -i '/^\tdnssec-validation/s/.*/dnssec-validation no;\n\trecursion yes;\n\tallow-query { any; };/g' /etc/bind/named.conf.option
namedrow=$(cat -n /etc/bind/named.conf.option | grep dnssec-validation | cut -c 6) > /dev/null
sed -n "$namedrow, $((namedrow+1)), $((named+2))" /etc/bind/named.conf.option
echo "방화벽 설정(4/11)"
ufw allow 53 > /dev/null
echo "53번 포트 허용"
ufw allow 21 > /dev/null
echo "21번 포트 허용"
ufw allow 80 > /dev/null
echo "80번 포트 허용"
echo "named 서비스 시작(5/11)"
systemctl restart named
systemctl enable named
StatusNamed=$(systemctl status named | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$StatusNamed" == "active" ]; then
    echo "named 서비스 정상 작동중."
else
    echo "오류 : named 서비스가 정상 작동중이 아님."
    exit
fi
echo "네임서버  작동 확인(6/11)"
echo "테스트할 URL : www.google.com"
is_workURL=$(nslookup www.google.com | cut -d ' ' -f 1) > dev/null
if [ "$is_workURL" == ";;" ]; then
    echo "네임서버가 작동하지 않음."
    sed -i "/^nameserver/s/nameserver $backupDNS/g" /etc/resolv.conf
    exit
else
    echo "네임서버가 정상 작동함."
fi
echo "웹페이지 Default 설정(7/11)"
read -p "생성할 웹페이지 제목 : " indextitle
cd /var/www/html
mv index.html backup_index.bak
touch index.html
echo "<!DOCTYPE html>" >> index.html
echo "<html>" >> index.html
echo "<head>" >> index.html
echo "\t<meta charset=\"utf-8\">" >> index.html
echo "\t<title>$indextitle</title>" >> index.html
echo "</head>" >> index.html
echo "<body>" >> index.html
echo "\t<h1>Ubuntu 20.04 LTS test Web server</h1>" >> index.html
echo "\t<p>You can modify this file in /var/www/html/index.html</p>" >> index.html
echo "</body>" >> index.html
echo "</html>" >> index.html
echo "도메인 이름 설정(8/11)"
read -p "도메인 이름(.com 제외|ex:john) : " DomainName
echo "zone \"$DomainName.com\" IN {" >>  /etc/bind/named.conf
echo "/ttype master;" >> /etc/bind/named.conf
echo "file /etc/bind/$DomainName.com.db;" >> /etc/bind/named.conf
echo "};" >> /etc/bind/named.conf
echo "도메인 포워드존 설정(9/11)"
read -p "FTP 서버의 IP : " FTPserverIP
touch /etc/bind/$DomainName.com.db
echo "\$TTL\t3H" >> /etc/bind/$DomainName.com.db
echo "@\tIN\tSOA\t@\troot.\t( 2 1D 1H 1W 1H )" >> /etc/bind/$DomainName.com.db
echo "" >> /etc/bind/$DomainName.com.db
echo "@\tIN\tNS\t@" >> /etc/bind/$DomainName.com.db
echo "\tIN\tA\t$currentIP" >> /etc/bind/$DomainName.com.db
echo "" >> /etc/bind/$DomainName.com.db
echo "www\tIN\tA\t$currentIP" >> /etc/bind/$DomainName.com.db
echo "ftp\tIN\tA\t$FTPserverIP" >> /etc/bind/$DomainName.com.db
echo "apache2 서비스 시작(10/11)"
systemctl restart apache2
systemctl enable apache2
Statusapache2=$(systemctl status apache2 | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$Statusapache2" == "active" ]; then
    echo "apache2 서비스 정상 작동중."
else
    echo "오류 : apache2 서비스가 정상 작동중이 아님."
    exit
fi
echo "bind9 서비스 시작(11/11)"
systemctl restart bind9
systemctl enable bind9
Statusbind9=$(systemctl status bind9 | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$Statusbind9" == "active" ]; then
    echo "bind9 서비스 정상 작동중."
else
    echo "오류 : bind9 서비스가 정상 작동중이 아님."
    exit
fi
echo "##########자동 설치 완료##########"
