#!/usr/bin/env sh

sudo sysctl -w net.ipv4.tcp_fin_timeout=15
sudo sysctl -w net.ipv4.tcp_tw_reuse=1

if [ "$DB_ADAPTER" = 'mysql2' ]; then
  mysql -u $DB_USER -e 'create database killbill;'
  mysql -u $DB_USER -e 'create database kaui_test;'
  curl 'http://docs.killbill.io/0.18/ddl.sql' | mysql -u $DB_USER killbill
elif [ "$DB_ADAPTER" = 'postgresql' ]; then
  psql -U $DB_USER -c 'create database killbill;'
  psql -U $DB_USER -c 'create database kaui_test;'
  curl 'https://raw.githubusercontent.com/killbill/killbill/master/util/src/main/resources/org/killbill/billing/util/ddl-postgresql.sql' | psql -U $DB_USER killbill
  curl 'https://raw.githubusercontent.com/killbill/killbill/master/util/src/main/resources/org/killbill/billing/util/ddl-postgresql.sql' | psql -U $DB_USER kaui_test
  curl 'http://docs.killbill.io/0.18/ddl.sql' | psql -U $DB_USER killbill
fi

if $(ruby -e'require "java"'); then
  # Somehow missing on JRuby-9
  gem install bundler

  # https://github.com/jruby/activerecord-jdbc-adapter/issues/780
  if [ "$DB_ADAPTER" = 'mysql2' ]; then
    cat db/ddl.sql | mysql -u $DB_USER kaui_test
  elif [ "$DB_ADAPTER" = 'postgresql' ]; then
    cat db/ddl.sql | psql -U $DB_USER kaui_test
  fi
else
  bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}
  bundle exec rake db:migrate
fi

gem install kpm

kpm install

if [ "$DB_ADAPTER" = 'mysql2' ]; then
  cat<<EOS >> conf/catalina.properties
org.killbill.dao.url=jdbc:mysql://localhost:$DB_PORT/killbill
org.killbill.billing.osgi.dao.url=jdbc:mysql://localhost:$DB_PORT/killbill
EOS
elif [ "$DB_ADAPTER" = 'postgresql' ]; then
  cat<<EOS >> conf/catalina.properties
org.killbill.dao.url=jdbc:postgresql://localhost:$DB_PORT/killbill
org.killbill.billing.osgi.dao.url=jdbc:postgresql://localhost:$DB_PORT/killbill
EOS
fi

cat<<EOS >> conf/catalina.properties
org.killbill.dao.user=$DB_USER
org.killbill.dao.password=
org.killbill.billing.osgi.dao.user=$DB_USER
org.killbill.billing.osgi.dao.password=
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

# For Travis debugging
echo "*** conf/catalina.properties"
cat conf/catalina.properties

echo "*** ActiveRecord config"
./bin/rails runner 'puts ActiveRecord::Base.connection_config'

echo "*** logs/catalina.out"
tail -50 logs/catalina.out
