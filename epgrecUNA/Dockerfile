FROM debian:jessie
MAINTAINER l3tnun
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 80
EXPOSE 8888
ARG CPUCORE="1"

#ファイルのコピー
ADD ./nginx /tmp/nginx
ADD ./epgdump /tmp/epgdump
ADD ./crontab /tmp/

#timezone 設定
RUN echo "Asia/Tokyo" > /etc/timezone && \
dpkg-reconfigure -f noninteractive tzdata && \
\
#必要なパッケージをインストール
apt-get update && \
apt-get -y install at cron nginx php5-fpm php5-cli php5-mysql make gcc git g++ automake && \
\
#at の設定
#www-data で at コマンドが実行できるように
sed -i".org" 's/www-data//g' /etc/at.deny && \
\
#php-fpm の timezone を設定
sed -i".org" 's/^disable_functions/;disable_functions/g' /etc/php5/fpm/php.ini && \
find /etc/php5 -name "php.ini" | xargs sed -i".org" 's/^;date.timezone =/date.timezone = "Asia\/Tokyo"/g' && \
\
#nginx の設定
cp /tmp/nginx/epgrec /etc/nginx/sites-available/ && \
rm /etc/nginx/sites-enabled/default && \
ln -s /etc/nginx/sites-available/epgrec /etc/nginx/sites-enabled/epgrec && \
\
#build epgdump
#ファイルのコピー
cd /tmp/epgdump/ && \
make && \
make install && \
\
#build BonDriver
cd  /tmp && \
git clone https://github.com/sudosan/BonDriverProxy_Linux && \
cd /tmp/BonDriverProxy_Linux && \
make client && \
\
#build recbond
cd /tmp/BonDriverProxy_Linux && \
git clone https://github.com/dogeel/recbond && \
cd /tmp/BonDriverProxy_Linux/recbond && \
./autogen.sh && \
./configure && \
make && \
make install && \
\
#BonDriver の配置
mkdir /Bon && \
cp  /tmp/BonDriverProxy_Linux/BonDriver_Proxy.so /Bon/ && \
\
#EPG 更新の設定
cat /tmp/crontab >> /etc/crontab && \
\
#ffmpeg のビルドの準備
apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev wget && \
apt-get -y install yasm libx264-dev libmp3lame-dev libopus-dev && \
apt-get -y install libasound2 libass5 libvdpau1 libva-x11-1 libva-drm1 libxcb-shm0 libxcb-xfixes0 libxcb-shape0 libvorbisenc2 libtheora0 && \
mkdir /tmp/ffmpeg_sources && \
cd /tmp/ffmpeg_sources && \
\
#fdk-aac のビルド
wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master && \
tar xzvf fdk-aac.tar.gz && \
cd mstorsjo-fdk-aac* && \
autoreconf -fiv && \
./configure --disable-shared && \
make && \
make install && \
\
#ffmpeg のビルド
cd /tmp/ffmpeg_sources && \
wget http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 && \
cd /tmp/ffmpeg_sources/ffmpeg && \
./configure \
  --prefix=/usr/local \
  --disable-shared \
  --pkg-config-flags=--static \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libx264 \
  --enable-nonfree \
&& \
cd /tmp/ffmpeg_sources/ffmpeg && \
make -j${CPUCORE} && \
make install && \
\
#EPGRemote のインストール
#node.js のインストール
apt-get install -y nodejs npm && \
npm cache clean && \
npm install n -g && \
n lts && \
apt-get purge -y nodejs npm && \
hash -r && \
\
#EPGRemote のビルド
cd /usr/local && \
git clone https://github.com/l3tnun/EPGRemote.git && \
cd EPGRemote && \
npm install && \
npm run build && \
\
#mp2 instal
npm install pm2 -g && \
\
#一時ファイルの削除
cd / && \
rm -rf /tmp/* &&\
\
#不要なパッケージの削除
apt-get purge -y make gcc git g++ automake build-essential libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev wget && \
apt-get autoremove -y && \
apt-get clean -y

ENTRYPOINT chown -R www-data:www-data /var/www/epgrec && \
chmod 777 /var/www/epgrec/templates_c && \
chmod 777 /var/www/epgrec/video && \
chmod 777 /var/www/epgrec/thumbs && \
chmod 777 /var/www/epgrec/settings && \
chmod 777 /var/www/epgrec/cache && \
/etc/init.d/cron start && \
/etc/init.d/atd start && \
/etc/init.d/php5-fpm start && \
/etc/init.d/nginx start && \
/usr/local/bin/pm2 --no-daemon start /usr/local/EPGRemote/build-server/index.js --name epgremote && \
tail -f /dev/null

