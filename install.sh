#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [LNMP/Nginx] AMH-R - Modified By weing104 ';
echo ' https://kimtsu.com & https://github.com/weing104/amh-R ';
echo '================================================================';


# Function List *****************************************************************************
function CheckSystem()
{
    [ $(id -u) != '0' ] && echo '[Error] Please use root to install AMH.' && exit;
    egrep -i "debian" /etc/issue /proc/version >/dev/null && SysName='Debian';
    egrep -i "ubuntu" /etc/issue /proc/version >/dev/null && SysName='Ubuntu';
    whereis -b yum | grep '/yum' >/dev/null && SysName='CentOS';
    [ "$SysName" == ''  ] && echo '[Error] Your system is not supported install AMH' && exit;

    SysBit='32' && [ `getconf WORD_BIT` == '32' ] && [ `getconf LONG_BIT` == '64' ] && SysBit='64';
    Cpunum=`cat /proc/cpuinfo | grep 'processor' | wc -l`;
    echo "${SysName} ${SysBit}Bit";
    RamTotal=`free -m | grep 'Mem' | awk '{print $2}'`;
    RamSwap=`free -m | grep 'Swap' | awk '{print $2}'`;
    echo "Server ${IPAddress}";
    echo "${Cpunum}*CPU, ${RamTotal}MB*RAM, ${RamSwap}MB*Swap";
    echo '================================================================';
    
    RamSum=$[$RamTotal+$RamSwap];
    [ "$SysBit" == '32' ] && [ "$RamSum" -lt '250' ] && \
    echo -e "[Error] Not enough memory install AMH. \n(32bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 250MB)" && exit;

    if [ "$SysBit" == '64' ] && [ "$RamSum" -lt '480' ];  then
        echo -e "[Error] Not enough memory install AMH. \n(64bit system need memory: ${RamTotal}MB*RAM + ${RamSwap}MB*Swap > 480MB)";
        [ "$RamSum" -gt '250' ] && echo "[Notice] Please use 32bit system.";
        exit;
    fi;
}


function InputDomain()
{
    if [ "$Domain" == '' ]; then
        echo '[Error] empty server ip.';
        read -p '[Notice] Please input server ip:' Domain;
        [ "$Domain" == '' ] && InputDomain;
    else
        echo '[OK] Your server ip is:' && echo $Domain;
        read -p '[Notice] This is your server ip? : (y/n)' confirmDM;
        if [ "$confirmDM" == 'n' ]; then
            Domain='';
            InputDomain;
        elif [ "$confirmDM" != 'y' ]; then
            InputDomain;
        fi;
    fi;
}


function InputMysqlPass()
{
    if [ "$MysqlPass" == '' ]; then
        echo '[Error] MySQL password is empty.';
        read -p '[Notice] Please input MySQL password:' MysqlPass;
        [ "$MysqlPass" == '' ] && InputMysqlPass;
    else
        echo '[OK] Your MySQL password is:' && echo $MysqlPass;
    fi;
}


function Timezone()
{
    rm -rf /etc/localtime;
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime;

    echo '[ntp Installing] ******************************** >>';
    [ "$SysName" == 'CentOS' ] && yum install -y ntp || apt-get install -y ntpdate;
    ntpdate -u pool.ntp.org;
    StartDate=$(date);
    StartDateSecond=$(date +%s);
    echo "Start time: ${StartDate}";
}


function CloseSelinux()
{
    [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
    setenforce 0 >/dev/null 2>&1;
}

function DeletePackages()
{
    if [ "$SysName" == 'CentOS' ]; then
        yum -y remove httpd;
        yum -y remove php;
        yum -y remove mysql-server mysql;
        yum -y remove php-mysql;
    else
        apt-get --purge remove nginx
        apt-get --purge remove mysql-server;
        apt-get --purge remove mysql-common;
        apt-get --purge remove php;
    fi;
}

function InstallBasePackages()
{
    if [ "$SysName" == 'CentOS' ]; then
        yum -y install yum-fastestmirror;

        cp /etc/yum.conf /etc/yum.conf.lnmp
        sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf
        for packages in gcc gcc-c++ ncurses-devel libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel pcre-devel libtool-libs freetype-devel gd zlib zlib-devel zip unzip wget crontabs iptables file bison cmake patch mlocate flex diffutils automake make  readline-devel git glibc-devel glibc-static glib2-devel  bzip2-devel gettext-devel libcap-devel logrotate ftp openssl expect; do 
            yum -y install $packages; 
        done;
        mv -f /etc/yum.conf.lnmp /etc/yum.conf;
    else
        apt-get remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common php;
        killall apache2;
        apt-get update;
        for packages in build-essential gcc g++ git git-core cmake make ntp logrotate automake patch re2c wget flex cron libzip-dev libc6-dev rcconf bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev libcurl3 libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect; 
        do apt-get install -y $packages --force-yes;
        done;
    fi;
}


function InstallReady()
{

    mkdir -p /home/download;
    chmod +rw /home/download;

    groupadd www;
    useradd www -g www -M -s /sbin/nologin;

}


# Install Function  *********************************************************
function InstallLibiconv()
{
    # [dir] /usr/local/libiconv
    if [ ! -d /usr/local/libiconv ]; then
        mkdir /home/patch;
        cd /home/download;
        wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz;
        tar -zxf libiconv-1.14.tar.gz -C /usr/local/src;

        wget -O /home/patch/libiconv-glibc-2.16.patch http://www.itkb.ro/userfiles/file/libiconv-glibc-2.16.patch.gz
        cd /usr/local/src/libiconv-1.14;
        patch -p0 < /home/patch/libiconv-glibc-2.16.patch
        ./configure --prefix=/usr/local/libiconv;
        make;
        make install;

        echo '[OK] libiconv is installed!';
    fi;
}


function InstallLibmcrypt()
{
    # [dir] /usr/local/libmcrypt
    if [ ! -d /usr/local/libiconv ]; then
        cd /home/download;
        wget http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz;
        tar -zxf libmcrypt-2.5.8.tar.gz -C /usr/local/src;

        cd /usr/local/src/libmcrypt-2.5.8;
        ./configure --prefix=/usr/local/libmcrypt;
        make;
        make install;
        /sbin/ldconfig;
        cd libltdl/;
        ./configure --enable-ltdl-install;
        make && make install;
        ln -sf /usr/local/lib/libmcrypt.la /usr/lib/libmcrypt.la;
        ln -sf /usr/local/lib/libmcrypt.so /usr/lib/libmcrypt.so;
        ln -sf /usr/local/lib/libmcrypt.so.4 /usr/lib/libmcrypt.so.4;
        ln -sf /usr/local/lib/libmcrypt.so.4.4.8 /usr/lib/libmcrypt.so.4.4.8;
        ldconfig;

        echo '[OK] libmcrypt is installed!';
    fi;
}


function InstallMhash()
{
    # [dir] /usr/local/libmcrypt
    if [ ! -d /usr/local/mhash ]; then
        cd /home/download;
        wget http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz;
        tar -zxf mhash-0.9.9.9.tar.gz -C /usr/local/src;

        cd /usr/local/src/mhash-0.9.9.9;
        ./configure --prefix=/usr/local/mhash;
        make;
        make install;
        ln -sf /usr/local/lib/libmhash.a /usr/lib/libmhash.a
        ln -sf /usr/local/lib/libmhash.la /usr/lib/libmhash.la
        ln -sf /usr/local/lib/libmhash.so /usr/lib/libmhash.so
        ln -sf /usr/local/lib/libmhash.so.2 /usr/lib/libmhash.so.2
        ln -sf /usr/local/lib/libmhash.so.2.0.1 /usr/lib/libmhash.so.2.0.1
        ldconfig

        echo '[OK] mhash is installed!';
    fi;
}


function InstallMcrypt()
{
    # [dir] /usr/local/libmcrypt
    if [ ! -d /usr/local/mcrypt ]; then
        cd /home/download;
        wget http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz;
        tar -zxf mcrypt-2.6.8.tar.gz -C /usr/local/src;

        cd /usr/local/src/mcrypt-2.6.8;
        ./configure --prefix=/usr/local/mcrypt;
        make;
        make install;

        echo '[OK] mcrypt is installed!';
    fi;
}


function InstallAutoconf()
{
    # [dir] /usr/local/autoconf /usr/local/src/autoconf*
    if [ ! -d /usr/local/autoconf ]; then
        cd /home/download;
        wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz;
        tar -zxf autoconf-2.13.tar.gz -C /usr/local/src;

        cd /usr/local/src/autoconf-2.13
        ./configure --prefix=/usr/local/autoconf
        make;
        make install;

        echo '[OK] autoconf is installed!';
    fi;
}


function InstallPcre()
{
    # [dir] /usr/local/pcre /usr/local/src/pcre*
    if [ ! -d /usr/local/pcre ]; then
        cd /home/download;
        wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.39.tar.gz;
        tar -zxf pcre-8.39.tar.gz -C /usr/local/src;
    
        cd /usr/local/src/pcre-8.39;
        ./configure --prefix=/usr/local/pcre;
        make;
        make install;

        echo '[OK] pcre is installed!';
    fi;
}


function InstallCurl()
{
    # [dir] /usr/local/pcre /usr/local/src/curl*
    if [ ! -d /usr/local/curl ]; then
        cd /home/download;
        wget https://curl.haxx.se/download/curl-7.51.0.tar.gz;
        tar -zxf curl-7.51.0.tar.gz -C /usr/local/src;
    
        cd /usr/local/src/pcre-7.51.0;
        ./configure --prefix=/usr/local/curl --enable-ares --without-nss --with-ssl;
        make;
        make install;

        echo '[OK] curl is installed!';
    fi;
}

function InstallZlib()
{
    # [dir] /usr/local/zlib /usr/local/src/zlib*
    if [ ! -d /usr/local/zlib ]; then
        cd /home/download;
        wget http://zlib.net/zlib-1.2.8.tar.gz;
        tar -zxf zlib-1.2.8.tar.gz -C /usr/local/src;
    
        cd /usr/local/src/zlib-1.2.8;
        ./configure --prefix=/usr/local/zlib;
        make;
        make install;
        echo '/usr/local/zlib/lib' >> /etc/ld.so.conf.d/local.conf;
        ldconfig -v;

        echo '[OK] zlib is installed!';
    fi;
}

function InstallLibressl()
{
    # [dir] /usr/local/libressl /usr/local/src/libressl*
    if [ ! -d /usr/local/libressl ]; then
        cd /home/download;
        wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.4.4.tar.gz;
        tar -zxf libressl-2.4.4.tar.gz -C /usr/local/src;

        cd /usr/local/src/libressl-2.4.4;
        ./config --prefix=/usr/local/libressl;
        make;
        make install;

        echo '[OK] libressl is installed!';
    fi;
}

function InstallMysql()
{
    # [dir] /usr/local/mysql/
    echo "[${MysqlVersion} Installing] ************************************************** >>";
    if [ ! -f /usr/local/mysql/bin/mysql ]; then
        cd /home/download;
        wget http://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.54.tar.gz;
        tar -zxf mysql-5.5.54.tar.gz -C /usr/local/src;

        cd /usr/local/src/mysql-5.5.54;
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/home/mysql_data -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=0 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=complex;
        make;
        make install;   

        groupadd mysql;
        useradd mysql -g mysql -M -s /sbin/nologin;
        chmod +w /usr/local/mysql;
        chown -R mysql:mysql /usr/local/mysql;
        mkdir -p /home/mysql_data;
        chown -R mysql:mysql /home/mysql_data;

cat > /etc/my.cnf<<EOF
[client]
#password   = your_password
port        = 3306
socket      = /tmp/mysql.sock

[mysqld]
port        = 3306
socket      = /tmp/mysql.sock
datadir = /home/mysql_data
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
thread_cache_size = 8
query_cache_size = 8M
tmp_table_size = 16M

#skip-networking
max_connections = 500
max_connect_errors = 100
open_files_limit = 65535

log-bin=mysql-bin
binlog_format=mixed
server-id   = 1
expire_logs_days = 10

default_storage_engine = InnoDB
innodb_data_home_dir = /home/mysql_data
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /home/mysql_data
innodb_buffer_pool_size = 16M
innodb_additional_mem_pool_size = 2M
innodb_log_file_size = 5M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout
EOF


        if [ $RamTotal -gt 1500 -a $RamTotal -le 2500 ];then
                sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' /etc/my.cnf;
                sed -i 's@^query_cache_size.*@query_cache_size = 16M@' /etc/my.cnf;
                sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 16M@' /etc/my.cnf;
                sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' /etc/my.cnf;
                sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' /etc/my.cnf;
                sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' /etc/my.cnf;
                sed -i 's@^table_open_cache.*@table_open_cache = 256@' /etc/my.cnf;
        elif [ $RamTotal -gt 2500 -a $RamTotal -le 3500 ];then
                sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' /etc/my.cnf;
                sed -i 's@^query_cache_size.*@query_cache_size = 32M@' /etc/my.cnf;
                sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 32M@' /etc/my.cnf;
                sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' /etc/my.cnf;
                sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' /etc/my.cnf;
                sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' /etc/my.cnf;
                sed -i 's@^table_open_cache.*@table_open_cache = 512@' /etc/my.cnf;
        elif [ $RamTotal -gt 3500 ];then
                sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' /etc/my.cnf;
                sed -i 's@^query_cache_size.*@query_cache_size = 64M@' /etc/my.cnf;
                sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 64M@' /etc/my.cnf;
                sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' /etc/my.cnf;
                sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' /etc/my.cnf;
                sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' /etc/my.cnf;
                sed -i 's@^table_open_cache.*@table_open_cache = 1024@' /etc/my.cnf;
        fi;
        /usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/home/mysql_data;
        

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************

        ldconfig;
        if [ "$SysBit" == '64' ] ; then
            ln -sf /usr/local/mysql/lib/mysql /usr/lib64/mysql;
        else
            ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql;
        fi;
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
        chmod 755 /etc/init.d/mysql;
        /etc/init.d/mysql start;
        ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql;
        ln -sf /usr/local/mysql/bin/mysqladmin /usr/bin/mysqladmin;
        ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
        ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
        ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;
        ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck;

        /usr/local/mysql/bin/mysqladmin password $MysqlPass;
        rm -rf /home/mysql_data/test;

# EOF **********************************
mysql -hlocalhost -uroot -p$MysqlPass <<EOF
USE mysql;
DELETE FROM user WHERE User!='root' OR (User = 'root' AND Host != 'localhost');
UPDATE user set password=password('$MysqlPass') WHERE User='root';
DROP USER ''@'%';
FLUSH PRIVILEGES;
EOF
# **************************************

        echo '[OK] MySQL is installed.';
    fi;
}

function InstallPhp()
{
    # [dir] /usr/local/php
    echo "[PHP Installing] ************************************************** >>";
    if [ ! -d /usr/local/php ]; then
        mkdir -p /etc/php5
        cd /home/download;
        wget http://php.net/distributions/php-5.5.38.tar.gz;
        tar -zxf php-5.5.38.tar.gz -C /usr/local/src;
        cd /usr/local/src/php-5.5.38;
        ./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php/etc --enable-ftp --enable-gd-native-ttf --enable-mbstring --enable-bcmath --enable-shmop --enable-soap --enable-exif --enable-sysvsem --enable-inline-optimization --enable-mbregex --enable-xml --with-zlib --with-curl --with-mhash --with-mcrypt --with-gd --with-jpeg-dir --with-png-dir --enable-pcntl --enable-sockets --with-xmlrpc --with-gettext --with-iconv=/usr/local/libiconv --with-zlib=/usr/local/zlib --with-openssl=/usr/local/openssl --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-libxml-dir=/usr --without-pear --disable-ipv6 --disable-fileinfo --disable-rpath --disable-debug;
        fi;
        make ZEND_EXTRA_LIBS='-liconv';
        make;
        make install;
        
        mkdir -p /usr/local/php/etc
        cp /usr/local/php/php.ini-production /usr/local/php/etc/php.ini;

        # php extensions
        sed -i 's#extension_dir = "./"#extension_dir = "/usr/local/php/lib/php/extensions/no-debug-non-zts-20060613/"\n#' /usr/local/php/etc/php.ini
        sed -i 's#output_buffering =.*#output_buffering = On#' /usr/local/php/etc/php.ini
        sed -i 's/post_max_size =.*/post_max_size = 50M/g' /usr/local/php/etc/php.ini
        sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' /usr/local/php/etc/php.ini
        sed -i 's/;date.timezone =.*/date.timezone = PRC/g' /usr/local/php/etc/php.ini
        sed -i 's/short_open_tag =.*/short_open_tag = On/g' /usr/local/php/etc/php.ini
        sed -i 's/; cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g' /usr/local/php/etc/php.ini
        sed -i 's/max_execution_time =.*/max_execution_time = 300/g' /usr/local/php/etc/php.ini
        sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/g' /usr/local/php/etc/php.ini

        cat >/usr/local/php/etc/php-fpm.conf<<EOF
[global]
pid = /usr/local/php/var/run/php-fpm.pid
error_log = /usr/local/php/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_55_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF

        mkdir /etc/php.d;
        mkdir /usr/local/php/etc/fpm;
        mkdir /usr/local/php/var/run/pid;
        /usr/local/php/sbin/php-fpm;

        ln -sf /usr/local/php/bin/php /usr/bin/php;
        ln -sf /usr/local/php/bin/phpize /usr/bin/phpize;
        ln -sf /usr/local/php/sbin/php-fpm /usr/bin/php-fpm;

        if [ $RamTotal -gt 1024 -a $RamTotal -le 1500 ]; then
            Memory_limit=192
        elif [ $RamTotal -gt 1500 -a $RamTotal -le 3500 ]; then
            Memory_limit=256
        elif [ $RamTotal -gt 3500 -a $RamTotal -le 4500 ]; then
            Memory_limit=320
        elif [ $RamTotal -gt 4500 ]; then
            Memory_limit=448
        else
            Memory_limit=128
        fi;

        sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" /usr/local/php/etc/php.ini;
        sed -i "s@^;opcache.memory_consumption.*@opcache.memory_consumption=$Memory_limit@" /usr/local/php/etc/php.ini;

        if [ $RamTotal -le 3000 ]; then
            sed -i "s@^pm.max_children.*@pm.max_children = $(($RamTotal/2/20))@" /usr/local/php/etc/php-fpm.conf;
            sed -i "s@^pm.start_servers.*@pm.start_servers = $(($RamTotal/2/30))@" /usr/local/php/etc/php-fpm.conf;
            sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($RamTotal/2/40))@" /usr/local/php/etc/php-fpm.conf;
            sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($RamTotal/2/20))@" /usr/local/php/etc/php-fpm.conf;
        elif [ $RamTotal -gt 3000 -a $RamTotal -le 4500 ]; then
            sed -i "s@^pm.max_children.*@pm.max_children = 80@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" /usr/local/php/etc/php-fpm.conf;
        elif [ $RamTotal -gt 4500 -a $RamTotal -le 6500 ]; then
                sed -i "s@^pm.max_children.*@pm.max_children = 90@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 90@" /usr/local/php/etc/php-fpm.conf;
        elif [ $RamTotal -gt 6500 -a $RamTotal -le 8500 ]; then
                sed -i "s@^pm.max_children.*@pm.max_children = 100@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.start_servers.*@pm.start_servers = 70@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 60@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 100@" /usr/local/php/etc/php-fpm.conf;
        elif [ $RamTotal -gt 8500 ]; then
                sed -i "s@^pm.max_children.*@pm.max_children = 120@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.start_servers.*@pm.start_servers = 80@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 70@" /usr/local/php/etc/php-fpm.conf;
                sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 120@" /usr/local/php/etc/php-fpm.conf;
        fi;

        cp /usr/local/php/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
        chmod +x /etc/init.d/php-fpm;

        echo "[OK] PHP install completed.";

}

function InstallNginx()
{
    # [dir] /usr/local/nginx
    echo "[Nginx Installing] ************************************************** >>";
    if [ ! -d /usr/local/nginx ]; then
        # [dir] /usr/local/src/ngx_http_substitutions_filter_module
        cd /home/download;
        git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

        wget http://nginx.org/download/nginx-1.10.2.tar.gz;
        tar -zxf nginx-1.10.2.tar.gz -C /usr/local/src;
        cd /usr/local/src/nginx-1.10.2;
        ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-http_stub_status_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --with-pcre=/usr/local/src/pcre-3.69 --with- zlib=/usr/local/src/zlib-1.2.8 --with-openssl=/usr/local/src/libressl-2.4.4; 
        make;
        make install;

        mkdir -p /home/wwwroot/default /usr/local/nginx/conf/vhost/ /usr/local/nginx/conf/rewrite/;
        chown www:www -R /home/wwwroot/default;

        [ "$SysBit" == '64' ] && mkdir lib64 || mkdir lib;
        /usr/local/nginx/sbin/nginx;
        ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx;

        echo '[OK] Nginx is installed.';
    fi;
}


# AMH Installing ****************************************************************************
CheckSystem;
InputDomain;
InputMysqlPass;
Timezone;
CloseSelinux;
DeletePackages;
InstallBasePackages;
InstallReady;
InstallLibiconv;
InstallLibmcrypt;
InstallMhash;
InstallMcrypt;
InstallAutoconf;
InstallPcre;
InstallCurl;
InstallZlib;
InstallLibressl;
InstallMysql;
InstallPhp;
InstallNginx;


if [ -s /usr/local/nginx ] && [ -s /usr/local/php ] && [ -s /usr/local/mysql ]; then


echo '================================================================';
    echo 'Congratulations, AMH-R install completed.';
    echo "MySQL Password:${MysqlPass}";
    echo '';
    echo '******* SSH Dirs *******';
    echo 'WebSite: /home/wwwroot';
    echo 'Nginx: /usr/local/nginx';
    echo 'PHP: /usr/local/php';
    echo 'MySQL: /usr/local/mysql';
    echo 'MySQL-Data: /home/mysql_data';
    echo '';
echo '================================================================';
else
    echo 'Sorry, Failed to install AMH-R';
fi;
