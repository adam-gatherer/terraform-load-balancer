#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
echo "<h1>Ahoy there skipper, welcome to $(hostname -f)<h1>" > /var/www/html/index.html