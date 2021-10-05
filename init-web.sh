#!/bin/bash
yum -y update
yum -y install httpd

cat <<EOF > /var/www/html/index.html
<html>
<h2><font color="8A2BE2">Hello world</font></h2><br>
</html>
EOF

sudo service httpd start
chkconfig httpd on