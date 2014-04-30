bitcoin-node-bootstrap
======================

A system install script to simply setup a bitcoin node on a newly installed linux system

Invocation Instructions
=======================

    root@test:~# dpkg-reconfigure tzdata
    
    Current default time zone: 'Europe/London'
    Local time is now:      Wed Apr 30 21:07:23 BST 2014.
    Universal Time is now:  Wed Apr 30 20:07:23 UTC 2014.
    
    root@test:~# wget https://raw.githubusercontent.com/Polhemic/bitcoin-node-bootstrap/master/install.sh
    --2014-04-30 21:07:41--  https://raw.githubusercontent.com/Polhemic/bitcoin-node-bootstrap/master/install.sh
    Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 199.27.76.133
    Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|199.27.76.133|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 6129 (6.0K) [text/plain]
    Saving to: `install.sh'
    
    100%[==========================================================>] 6,129       --.-K/s   in 0s
    
    2014-04-30 21:07:42 (92.4 MB/s) - `install.sh' saved [6129/6129]
    
    root@test:~# chmod +x install.sh
    root@test:~# ./install.sh

Note that you must change timezones before installing. The vnstat solution doesn't seem to work right if you change timezone after setting it up.
