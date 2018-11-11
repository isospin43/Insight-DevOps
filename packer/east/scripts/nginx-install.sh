#!/bin/bash

# * nginx  *

export localhost_ip="127.0.0.1"
export localhost_dns="localhost"
export private_ip="`curl -s http://instance-data/latest/meta-data/local-ipv4`"
export private_dns="`curl -s http://instance-data/latest/meta-data/local-hostname`"
export public_ip="`curl -s http://instance-data/latest/meta-data/public-ipv4`"
export public_dns="`curl -s http://instance-data/latest/meta-data/public-hostname`"


sudo apt-get -qq -y install nginx
sudo cat <<EOF2 > /tmp/default.conf
server
{
  listen 80 ;
  server_name $public_ip $public_dns;
  root /var/www/html;
      location / {
        #proxy_pass http://127.0.0.1:8500;
        #proxy_set_header Host \$http_host;
        #proxy_set_header X-Real-IP \$remote_addr;
        #proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        #proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ /\. {
        deny all;
    }
}
EOF2
sudo mv /tmp/default.conf /etc/nginx/conf.d/default.conf
sudo mv /tmp/nginx.conf.file /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl stop nginx.service
sudo systemctl start nginx.service
#sudo systemctl status nginx.service
#exit(1)
