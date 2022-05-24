#!bin/bash
#1.패키지 설치 확인 mariadb-server, mariadb-client
#2.mariadb 서비스 시작
#3.방화벽 설정 mariadb3306
#4.MariaDB 비밀번호 설정
#5.mysql 외부 접속 허용 설정
ins_mariadb_S=$(dpkg -l mariadb-server 2> /dev/null | grep ii | cut -d ' ' -f 1)
ins_mariadb_C=$(dpkg -l mariadb-client 2> /dev/null | grep ii | cut -d ' ' -f 1)
echo "패키지 설치 확인(1/)"
if [ "$ins_mariadb_S" == "ii" ]; then
    echo "mariadb-server 설치됨."
else
    echo "mariadb-server 설치 안됨."
    read -s -n 1 -p "mariadb-server 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "mariadb-server 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y mariadb-server > /dev/null
fi
if [ "$ins_mariadb_C" == "ii" ]; then
    echo "mariadb-client 설치됨."
else
    echo "mariadb-client 설치 안됨."
    read -s -n 1 -p "mariadb-client 패키지를 설치합니다. 계속하려면 아무키나 누르세요."
    printf "\n"
    echo "mariadb-client 설치중... (설치중에 터미널을 끄지 마세요.)"
    apt-get install -y mariadb-client > /dev/null
fi
echo "#2.mariadb 서비스 시작(2/)"
systemctl restart mariadb
systemctl enable mariadb
StatusMariaDB=$(systemctl status mariadb | grep Active | cut -d ' ' -f 7) > /dev/null
if [ "$StatusMariaDB" == "active" ]; then
    echo "mariadb 서비스 정상 작동중."
else
    echo "오류 : mariadb 서비스가 정상 작동중이 아님."
    exit 0
fi
echo "방화벽 설정(3/)"
ufw allow 3306
echo "MariaDB 비밀번호 설정(4/)"
read -s -p "root권한 비밀번호 : " mariaPW
mysqladmin -u root password "$mariaPW"
echo "mysql 외부 접속 허용 설정(5/)"
sed -i '/^bind/s/b/#b/g' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
echo "##########자동 설치 완료!##########"
exit 0
