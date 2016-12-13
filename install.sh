#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

clear;
echo '================================================================';
echo ' [LNMP/Nginx] AMH-R - Modified By weing104 ';
echo ' https://kimtsu.com & https://github.com/weing104/amh-R ';
echo '================================================================';


# Function List *****************************************************************************
function InputMysqlPass()
{
    if [ "$MysqlPass" == '' ]; then
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
    apt-get install -y ntpdate;
    ntpdate -u pool.ntp.org;
}


function CloseSelinux()
{
    [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config;
    setenforce 0 >/dev/null 2>&1;
}

function DeletePackages()
{
        apt-get --purge remove nginx
        apt-get --purge remove mysql-server;
        apt-get --purge remove mysql-common;
        apt-get --purge remove php;
}

function InstallBasePackages()
{
        apt-get remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker mysql-client mysql-server mysql-common php;
        killall apache2;
        apt-get update;
        for packages in build-essential gcc g++ git git-core cmake make ntp logrotate automake patch libzip-dev libc6-dev bison cpp binutils unzip tar bzip2 libncurses5-dev libncurses5 libtool libevent-dev libpcre3 libpcre3-dev libpcrecpp0 libssl-dev zlibc openssl libsasl2-dev libxml2 libxml2-dev libltdl3-dev libltdl-dev zlib1g zlib1g-dev libbz2-1.0 libbz2-dev libglib2.0-0 libglib2.0-dev libpng3 libfreetype6 libfreetype6-dev libjpeg62 libjpeg62-dev libjpeg-dev libpng-dev libpng12-0 libpng12-dev libcurl3 libpq-dev libpq5 gettext libcurl4-gnutls-dev  libcurl4-openssl-dev libcap-dev ftp openssl expect; 
        do apt-get install -y $packages --force-yes;
        done;
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
        echo "[OK] libiconv install completed.";
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
        echo "[OK] libmcrypt install completed.";
    else
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
        echo "[OK] zlib install completed.";
    else
        echo '[OK] zlib is installed!';
    fi;
}


function InstallMysql()
{
    # [dir] /usr/local/mysql/
    if [ ! -f /usr/local/mysql/bin/mysql ]; then
        mkdir -p /usr/local/mysql;
        mkdir -p /usr/local/mysql/data;
        groupadd mysql;
        useradd mysql -g mysql -M -s /sbin/nologin;
        chown -R mysql:mysql /usr/local/mysql;
        chown -R mysql:mysql /usr/local/mysql/data;

        cd /home/download;
        wget http://cdn.mysql.com//Downloads/MySQL-5.5/mysql-5.5.54.tar.gz;
        tar -zxf mysql-5.5.54.tar.gz -C /usr/local/src;

        cd /usr/local/src/mysql-5.5.54;
        rm -f /etc/my.cnf;
        cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/usr/local/mysql/data -DMYSQL_UNIX_ADDR=/usr/local/mysql/data/mysql.sock -DSYSCONFDIR=/etc -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=0 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8mb4 -DDEFAULT_COLLATION=utf8mb4_general_ci;
        make && make install;   


        cat > /etc/my.cnf<<EOF
[client]
port = 3306
socket = /usr/local/mysql/data/mysql.sock

[mysqld]
port = 3306
socket = /usr/local/mysql/data/mysql.sock
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
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
innodb_data_home_dir = /usr/local/mysql/data
innodb_data_file_path = ibdata1:10M:autoextend
innodb_log_group_home_dir = /usr/local/mysql/data
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

        #初始化mysql
        /usr/local/mysql/scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data;
        chown -R mysql:mysql /usr/local/mysql/data;
        

# EOF **********************************
cat > /etc/ld.so.conf.d/mysql.conf<<EOF
/usr/local/mysql/lib/mysql
/usr/local/lib
EOF
# **************************************
        #添加启动项
        cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
        chmod 755 /etc/init.d/mysql;

        #启动服务
        ldconfig;
        ln -sf /usr/local/mysql/lib/mysql /usr/lib/mysql
        ln -sf /usr/local/mysql/include/mysql /usr/include/mysql
        /etc/init.d/mysql start;

        #设置软链
        ln -sf /usr/local/mysql/bin/mysql /usr/bin/mysql;
        ln -sf /usr/local/mysql/bin/mysqldump /usr/bin/mysqldump;
        ln -sf /usr/local/mysql/bin/myisamchk /usr/bin/myisamchk;
        ln -sf /usr/local/mysql/bin/mysqld_safe /usr/bin/mysqld_safe;
        ln -sf /usr/local/mysql/bin/mysqlcheck /usr/bin/mysqlcheck;

        /usr/local/mysql/bin/mysqladmin password $MysqlPass;

        echo '[OK] MySQL is installed.';
    fi;
}

function InstallPhp()
{
    #编译PHP安装
    if [ ! -d /usr/local/php ]; then
        mkdir -p /usr/local/php;
        mkdir -p /usr/local/php/etc;
        cd /home/download;
        wget http://php.net/distributions/php-5.5.38.tar.gz;
        tar -zxf php-5.5.38.tar.gz -C /usr/local/src;
        cd /usr/local/src/php-5.5.38;
        ./configure --prefix=/usr/local/php --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-config-file-path=/usr/local/php/etc --with-mysql-sock=/usr/local/mysql/data/mysql.sock --enable-ftp --enable-gd-native-ttf --enable-mbstring --enable-bcmath --enable-shmop --enable-soap --enable-exif --enable-sysvsem --enable-inline-optimization --enable-mbregex --enable-xml --with-zlib --with-curl --with-mhash --with-mcrypt --with-gd --with-jpeg-dir --with-png-dir --enable-pcntl --enable-sockets --with-xmlrpc --with-gettext --with-iconv --with-openssl --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-libxml-dir=/usr --disable-ipv6 --disable-fileinfo --disable-rpath --disable-debug;
        make ZEND_EXTRA_LIBS='-liconv';
        make install;

        #设置软链
        ln -sf /usr/local/php/bin/php /usr/bin/php
        ln -sf /usr/local/php/bin/phpize /usr/bin/phpize
        ln -sf /usr/local/php/bin/pear /usr/bin/pear
        ln -sf /usr/local/php/bin/pecl /usr/bin/pecl
        ln -sf /usr/local/php/sbin/php-fpm /usr/bin/php-fpm
        
        #配置PHP
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

        #安装pear和composer
        pear config-set php_ini /usr/local/php/etc/php.ini
        pecl config-set php_ini /usr/local/php/etc/php.ini
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

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
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF
        
        #设置启动项
        cp /usr/local/php/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm;
        chmod +x /etc/init.d/php-fpm;

        echo '[OK] PHP is installed.';
    fi;
}

function InstallNginx()
{
    # [dir] /usr/local/nginx
    if [ ! -d /usr/local/nginx ]; then
        #下载nginx
        mkdir -p /usr/local/nginx;
        cd /home/download;
        wget http://nginx.org/download/nginx-1.10.2.tar.gz;
        tar -zxf nginx-1.10.2.tar.gz -C /usr/local/src;

        #下载libressl
        wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-2.4.4.tar.gz;
        tar -zxf libressl-2.4.4.tar.gz -C /usr/local/src;

        #编译nginx
        cd /usr/local/src/nginx-1.10.2;
        ./configure --prefix=/usr/local/nginx --user=www --group=www --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_realip_module --with-http_sub_module --with-http_flv_module --with-http_mp4_module --with-http_stub_status_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --with-pcre=/usr/local/src/pcre-3.69 --with-zlib=/usr/local/src/zlib-1.2.8 --with-openssl=/usr/local/src/libressl-2.4.4; 
        make && make install;

        #设置软链
        cd ../
        ln -sf /usr/local/nginx/sbin/nginx /usr/bin/nginx


        mkdir -p /data/wwwroot/default;
        chmod +w /data/wwwroot/default;
        mkdir -p /usr/local/nginx/conf/vhost/ /usr/local/nginx/conf/rewrite/;
        chown www:www -R /home/wwwroot/default;
        mkdir -p /data/wwwlogs;
        chmod 777 /data/wwwlogs;

        #配置nginx
        rm -f /usr/local/nginx/conf/nginx.conf;
        wget -O /usr/local/nginx/conf/nginx.conf --no-check-certificate https://raw.githubusercontent.com/weing104/AMH-R/master/nginx.conf;
        

        ln -s /usr/local/lib/libpcre.so.1 /lib64/
        ln -s /usr/local/lib/libpcre.so.1 /lib/

        #配置启动项
        wget -O /etc/init.d/nginx --no-check-certificate https://raw.githubusercontent.com/weing104/AMH-R/master/nginx;
        chmod +x /etc/init.d/nginx;

        echo '[OK] Nginx is installed.';
    fi;
}


# AMH Installing ****************************************************************************
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
InstallMysql;
InstallPhp;
InstallNginx;


if [ -s /usr/local/nginx ] && [ -s /usr/local/php ] && [ -s /usr/local/mysql ]; then


echo '================================================================';
    echo 'Congratulations, AMH-R install completed.';
    echo "MySQL Password:${MysqlPass}";
    echo '';
    echo '******* SSH Dirs *******';
    echo 'WebSite: /data/wwwroot';
    echo 'Nginx: /usr/local/nginx';
    echo 'PHP: /usr/local/php';
    echo 'MySQL: /usr/local/mysql';
    echo 'MySQL-Data: /usr/local/mysql/data';
    echo '';
echo '================================================================';
else
    echo 'Sorry, Failed to install AMH-R';
fi;
