#!/bin/bash

PATH=/usr/local/bin:/bin:/usr/bin:/sbin

function nginx-repo {
  cat <<EOT >> /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOT
}

function page-update {
  WEBCOPY=`sum -r <(curl -s https://raw.githubusercontent.com/puppetlabs/exercise-webpage/master/index.html) | awk '{print $1}'`
  LOCALCOPY=`sum -r <(cat /usr/share/nginx/html/index.html) |awk '{print $1}'`

  if [ $WEBCOPY = $LOCALCOPY ]
    then
      echo "Web copy checksum $WEBCOPY and Local copy checksum $LOCALCOPY match...  nothing to do"
      exit
    else
      echo "Web copy checksum $WEBCOPY and Local copy checksum $LOCALCOPY do not match..  Updating page."
      curl -s https://raw.githubusercontent.com/puppetlabs/exercise-webpage/master/index.html > /usr/share/nginx/html/index.html
  fi
}


# Check to see if nginx is installed

if [ -x /usr/sbin/nginx ]
  then
     echo "nginx already installed"
     page-update
     exit
  else
     # Add nginx to yum repository
     echo "creating nginx yum repo"
     nginx-repo
     
     # Install nginx with yum
     yum install -y nginx
     
     # Change the port to 8000
     sed '2 s/80/8000/' /etc/nginx/conf.d/default.conf >> /tmp/nginxdef.$$
     cp /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.orig
     cp /tmp/nginxdef.$$ /etc/nginx/conf.d/default.conf
     rm /tmp/nginxdef.$$

     # Grab latest copy of the webpage and add local
     curl -s https://raw.githubusercontent.com/puppetlabs/exercise-webpage/master/index.html > /usr/share/nginx/html/index.html

     # Start the service
     if [ -x /etc/init.d/nginx ]
       then
          /etc/init.d/nginx start
          # start on reboot
          chkconfig --add nginx
       else
          # service nginx start
          systemctl start nginx
          # Start on reboot
          systemctl enable nginx
     fi
fi
