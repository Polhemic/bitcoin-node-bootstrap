#!/bin/bash

# Automated Ubuntu instance setup script
# To take a clean Ubuntu 12.04 LTS install to a fully running
# and secure Bitcoin node.

# [TODO] Check that we are running as root, sudo'd or otherwise

# Setup the and update the packages

apt-get update -y
apt-get upgrade -y
apt-get install git -y
apt-get install software-properties-common python-software-properties -y
apt-get install vnstat -y
apt-get install apache2 php5 php5-gd -y
#apt-get install ufw -y
apt-get install fail2ban -y

# the following line must come after "python-software-properties"
add-apt-repository -y ppa:bitcoin/bitcoin
apt-get update -y
apt-get upgrade -y
apt-get install bitcoind -y

# Setup a swap device
# [TODO] Check if the swap is already enabled
#dd if=/dev/zero of=/swapfile bs=1M count=1024 ; mkswap /swapfile ; swapon /swapfile
#echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# Setup the firewall
#ufw allow 22/tcp
#ufw allow 80/tcp
#ufw allow 8333/tcp
#ufw --force enable

# Setup bitcoinrpc
git clone https://github.com/jgarzik/python-bitcoinrpc
pushd python-bitcoinrpc
python setup.py build
python setup.py install
popd
rm -rf python-bitcoinrpc

#Setup vnstat
device_test=`ifconfig | grep eth0`
net_device=""
if [ "$device_test" = "" ]; then
    echo "Found venet0 device"
    net_device="venet0"
else
    echo "Found eth0 device"
    net_device="eth0"
fi
vnstat -u -i $net_device
vnstat -i $net_device
/etc/init.d/apache2 start
pushd /tmp
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xvf vnstat_php_frontend-1.5.1.tar.gz
sed -i "s/\$language = 'nl'/\$language = 'en'/" vnstat_php_frontend-1.5.1/config.php
if [ "$net_device" = "venet0" ]; then
    sed -i "s/eth0/venet0/" vnstat_php_frontend-1.5.1/config.php
fi
cp -fr vnstat_php_frontend-1.5.1/ /var/www/vnstat
popd

### FINISHED root level setup, now proceeding to the service user.
# [TODO] Run this as the service user

# Setup bitcoin
if [ ! -d ".bitcoin" ]; then
    mkdir .bitcoin
fi
config=".bitcoin/bitcoin.conf"
touch $config
echo "server=1" > $config
echo "daemon=1" >> $config
echo "connections=100" >> $config
randUser=`< /dev/urandom tr -dc A-Za-z0-9 | head -c30`
randPass=`< /dev/urandom tr -dc A-Za-z0-9 | head -c30`
echo "rpcuser=$randUser" >> $config
echo "rpcpassword=$randPass" >> $config
bitcoind -daemon

crontab -l > tempcron
echo "@reboot bitcoind -daemon" >> tempcron
echo "*/5 * * * * python /usr/local/bin/btc-update.py" >> tempcron
echo "*/5 * * * * /usr/bin/vnstat -u >/dev/null 2>&1" >> tempcron
crontab tempcron
rm tempcron

scriptFilename="/usr/local/bin/btc-update.py"
cat <<EOM > $scriptFilename
#!/usr/bin/python
from bitcoinrpc.authproxy import AuthServiceProxy
import time
 
access = AuthServiceProxy("http://RPCUSER:RPCPASSWORD@127.0.0.1:8332")
info = access.getinfo()
 
ff = open('/var/www/index.html', 'w')
 
 
ff.write("<!DOCTYPE html>")
ff.write("<html lang='en-us'>")
ff.write("<head>")
ff.write("<meta charset='utf-8'>")
ff.write("<title>Bitcoin Node Status</title>")
ff.write("<link href='http://fonts.googleapis.com/css?family=Exo+2:300,400' rel='stylesheet' type='text/css'>")
ff.write("<style type='text/css'> ")
ff.write("</style>")
ff.write("</head>")
ff.write("<body>")
 
ff.write("<link href='http://fonts.googleapis.com/css?family=Exo+2:300,400' rel='stylesheet' type='text/css'>")
ff.write("<style>")
 
ff.write("/* Eric Meyer's Reset CSS v2.0 - http://cssreset.com */")
ff.write("html,body,div,span,applet,object,iframe,h1,h2,h3,h4,h5,h6,p,blockquote,pre,a,abbr,acronym,address,big,cite,code,del,dfn,em,img,ins,kbd,q,s,samp,small,strike,strong,sub,sup,tt,var,b,u,i,center,dl,dt,dd,ol,ul,li,fieldset,form,label,legend,table,caption,tbody,tfoot,thead,tr,th,td,article,aside,canvas,details,embed,figure,figcaption,footer,header,hgroup,menu,nav,output,ruby,section,summary,time,mark,audio,video{border:0;font-size:100%;font:inherit;vertical-align:baseline;margin:0;padding:0}article,aside,details,figcaption,figure,footer,header,hgroup,menu,nav,section{display:block}body{line-height:1}ol,ul{list-style:none}blockquote,q{quotes:none}blockquote:before,blockquote:after,q:before,q:after{content:none}table{border-collapse:collapse;border-spacing:0}")
 
ff.write("html,body{height:100%;}")
ff.write("body{")
ff.write("color: #444;")
ff.write("background: url(http://www.babayara.com/wp-content/uploads/2013/08/vlcsnap-2013-08-24-23h14m34s7.png) no-repeat;")
ff.write("}")
 
ff.write("#wrap{")
ff.write("background-color: rgba(255, 255, 255, 0.6);")
ff.write("width: 100%;")
ff.write("height: 100%;")
ff.write("padding-top: 50px;")
ff.write("padding-left: 50px;")
ff.write("line-height: 1.4;")
ff.write("font-size: 24px;")
ff.write("font-family: 'Exo 2', sans-serif;")
ff.write("}")
 
ff.write("h3{")
ff.write("font-weight: 300;")
ff.write("}")
 
ff.write("h1{")
ff.write("font-weight: 400;")
ff.write("margin-bottom: 15px;")
ff.write("}")
ff.write("</style>")
ff.write("<div id='wrap'>")
ff.write("<h1>Bitcoin Node: MYIPADDRESS:8333<br \></h1>")
ff.write("<h3>")
 
ff.write("Last Update: " + time.strftime("%H:%M:%S %Y-%m-%d %Z") + "<br \>\n")
ff.write("Connections: " + str(info['connections']) + "<br \>\n")
ff.write("Blocks: " + str(info['blocks']) + "<br \>\n")
ff.write("Difficulty: " + str(info['difficulty']) + "<br \>\n")
 
ff.write("Location: MYLOCATION")
ff.write("</h3>")
ff.write("<br>Node created by <a href='https://bitcointalk.org/index.php?action=profile;u=58076'>Morblias</a>")
ff.write("<br>Donate: 1Morb18DsDHNEv6TeQXBdba872ZSpiK9fY")
ff.write("<br><a href='https://blockchain.info/address/1Morb18DsDHNEv6TeQXBdba872ZSpiK9fY'><img src='http://qrfree.kaywa.com/?l=1&amp;s=4&amp;d=1Morb18DsDHNEv6TeQXBdba872ZSpiK9fY' alt='QRCode'></a>")
ff.write("</div>")
ff.write("</body></html>")
 
ff.close()
EOM

myipaddress=`wget -O - -q curlmyip.com`
mylocation=`wget -q -O - freegeoip.net/csv | tr -d \" | awk -F"," '{ print $6 ", " $4 }'`

sed -i "s/RPCUSER/$randUser/g" $scriptFilename
sed -i "s/RPCPASSWORD/$randPass/g" $scriptFilename
sed -i "s/MYLOCATION/$mylocation/" $scriptFilename
sed -i "s/MYIPADDRESS/$myipaddress/" $scriptFilename

chmod +x $scriptFilename
$scriptFilename
