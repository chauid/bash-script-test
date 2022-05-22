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
if [ "$ins_apache2" == "ii" ]; then
    echo "apache2 설치됨."
else
    echo "apache2 설치 안됨."
    read -s -n 1 -p "apache2 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "apache2 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y apache2 > /dev/null
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
echo "named.conf.options 파일 설정(3/11)"
is_setoptions=$(cat /etc/bind/named.conf.options | grep dnssec | cut -d ' ' -f 2)
if [ "$is_setoptions" == "no;" ]; then
    echo "Already setting /etc/bind/named.conf.options"
else
    sed -i '/^\tdnssec-validation/s/.*/\tdnssec-validation no;\n\trecursion yes;\n\tallow-query { any; };/g' /etc/bind/named.conf.options
fi
echo "방화벽 설정(4/11)"
ufw allow 53 > /dev/null
echo "53번 포트 허용"
ufw allow 21 > /dev/null
echo "21번 포트 허용"
ufw allow 80 > /dev/null
echo "80번 포트 허용"
echo "named 서비스 시작(5/11)"
systemctl restart named > /dev/null
systemctl enable named > /dev/null
StatusNamed=$(systemctl status named | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$StatusNamed" == "active" ]; then
    echo "named 서비스 정상 작동중."
else
    echo "오류 : named 서비스가 정상 작동중이 아님."
    exit
fi
echo "네임서버  작동 확인(6/11)"
echo "테스트할 URL : www.naver.com"
is_workURL=$(nslookup www.naver.com | head -1 | cut -c 1-2)
if [ "$is_workURL" != "Se" ]; then
    echo "네임서버가 작동하지 않음."
    sed -i "/^nameserver/s/nameserver $backupDNS/g" /etc/resolv.conf
    exit
else
    echo "네임서버가 정상 작동함."
fi
echo "웹페이지 Default 설정(7/11)"
read -p "생성할 웹페이지 제목 : " indextitle
cd /var/www/html
if [ -f "./index.html" ]; then
  mv -f index.html backup_index.bak
fi
touch index.html
printf "<!DOCTYPE html>\n" >> index.html
printf "<html>\n" >> index.html
printf "<head>\n" >> index.html
printf "\t<meta charset=\"utf-8\">\n" >> index.html
printf "\t<title>$indextitle</title>\n" >> index.html
printf "</head>\n" >> index.html
printf "<body>\n" >> index.html
printf "\t<h1>Ubuntu 20.04 LTS test Web server</h1>\n" >> index.html
printf "\t<p>You can modify this file in /var/www/html/index.html</p>\n" >> index.html
printf "</body>\n" >> index.html
printf "</html>\n" >> index.html
echo "도메인 이름 설정(8/11)"
read -p "도메인 이름(.com 제외|ex:john) : " DomainName
printf "zone \"$DomainName.com\" IN {\n" >>  /etc/bind/named.conf
printf "\ttype master;\n" >> /etc/bind/named.conf
printf "file \"/etc/bind/$DomainName.com.db\";\n" >> /etc/bind/named.conf
printf "};\n" >> /etc/bind/named.conf
echo "도메인 포워드존 설정(9/11)"
read -p "FTP 서버의 IP : " FTPserverIP
touch /etc/bind/$DomainName.com.db
printf "\$TTL\t3H\n" >> /etc/bind/$DomainName.com.db
printf "@\tIN\tSOA\t@\troot.\t( 2 1D 1H 1W 1H )\n" >> /etc/bind/$DomainName.com.db
printf "\n" >> /etc/bind/$DomainName.com.db
printf "@\tIN\tNS\t@\n" >> /etc/bind/$DomainName.com.db
printf "\tIN\tA\t$currentIP\n" >> /etc/bind/$DomainName.com.db
printf "\n" >> /etc/bind/$DomainName.com.db
printf "www\tIN\tA\t$currentIP\n" >> /etc/bind/$DomainName.com.db
printf "ftp\tIN\tA\t$FTPserverIP\n" >> /etc/bind/$DomainName.com.db
echo "apache2 서비스 시작(10/11)"
systemctl restart apache2 > /dev/null
systemctl enable apache2 > /dev/null
Statusapache2=$(systemctl status apache2 | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$Statusapache2" == "active" ]; then
    echo "apache2 서비스 정상 작동중."
else
    echo "오류 : apache2 서비스가 정상 작동중이 아님."
    exit
fi
echo "bind9 서비스 시작(11/11)"
systemctl restart bind9 > /dev/null
systemctl enable bind9 > /dev/null
Statusbind9=$(systemctl status bind9 | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$Statusbind9" == "active" ]; then
    echo "bind9 서비스 정상 작동중."
else
    echo "오류 : bind9 서비스가 정상 작동중이 아님."
    exit
fi
echo "##########자동 설치 완료!##########"
