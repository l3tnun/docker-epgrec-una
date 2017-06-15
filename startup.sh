sudo docker rm epgrec
sudo docker rm epgrec-mysql

docker run  \
-e MYSQL_USER=epgrec \
-e MYSQL_PASSWORD:=epgrec \
-e MYSQL_ROOT_PASSWORD=mysql \
-e MYSQL_DATABASE=epgrec \
-p 3306:3306 \
-v dockerepgrecuna_epgrec-db:/var/lib/mysql \
--restart=always \
--name epgrec-mysql -i -t -d dockerepgrecuna_mysql \
mysqld --character-set-server=utf8 --collation-server=utf8_unicode_ci

nvidia-docker run \
-v ./epgrec:/var/www/epgrec \
-v ./BonDriver:/BonDriver \
-v ./epgremote_config:/usr/local/EPGRemote/config \
-v dockerepgrecuna_epgrec-cron-vol:/var/spool/cron \
-p 8080:80 \
-p 8888:8888 \
--link epgrec-mysql:mysql \
--name epgrec \
--restart=always \
--name epgrec -i -t -d dockerepgrecuna_epgrec

