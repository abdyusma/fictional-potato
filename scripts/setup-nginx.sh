#!/bin/bash

# update amazon linux
yum update -y

# install nginx
yum install nginx -y

# customize nginx page
sudo sed -i "s/Welcome to/$(hostname) uses/" /usr/share/nginx/html/index.html

# start nginx
systemctl start nginx

# start nginx during boot
sudo systemctl enable nginx
