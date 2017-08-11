#!/usr/bin/env sh

sudo sysctl -w net.ipv4.tcp_fin_timeout=15
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

mysql -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root')"
mysql -uroot -proot -e 'create database killbill;'
mysql -uroot -proot -e 'create database kaui_test;'

curl 'http://docs.killbill.io/0.18/ddl.sql' | mysql -uroot -proot killbill

# Somehow missing on JRuby-9
gem install bundler

gem install kpm

kpm install

cat<<EOS >> conf/catalina.properties
org.killbill.dao.url=jdbc:mysql://localhost:3306/killbill
org.killbill.dao.user=root
org.killbill.dao.password=root
org.killbill.billing.osgi.dao.url=jdbc:mysql://localhost:3306/killbill
org.killbill.billing.osgi.dao.user=root
org.killbill.billing.osgi.dao.password=root
org.killbill.catalog.uri=SpyCarAdvanced.xml
EOS

./bin/catalina.sh start

TIME_LIMIT=$(( $(date +%s) + 120 ))
RET=0
while [ $RET != 201 -a $(date +%s) -lt $TIME_LIMIT ] ; do
  RET=$(curl -s \
             -o /dev/null \
             -w "%{http_code}" \
             -X POST \
             -u 'admin:password' \
             -H 'Content-Type:application/json' \
             -H 'X-Killbill-CreatedBy:admin' \
             -d '{"apiKey":"bob", "apiSecret":"lazar"}' \
             "http://127.0.0.1:8080/1.0/kb/tenants")
  tail -50 logs/catalina.out
  sleep 5
done

tail -50 logs/catalina.out
