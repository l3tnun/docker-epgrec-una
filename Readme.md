#docker-epgrecUNA

epgrecUNA + [EPGRemote](https://github.com/l3tnun/EPGRemote) の Docker コンテナ

##前提条件
Docker, docker-compose, [u-n-k-n-o-w-n/BonDriverProxy_Linux
](https://github.com/u-n-k-n-o-w-n/BonDriverProxy_Linux) の導入が必須です。

BonDriverProxy_Linux の機能はないので、自分で準備してください。(Dockerfile を追加するなり適当に)

また b25 関係の機能は無いので、 BonDriverProxy_Linux 側で処理をするか、自分で追加してください。

##動作確認環境

・Docker Host
>OS: Debian jessie

>Docker version 1.12.3, build 6b644ec

>docker-compose version 1.8.1, build 878cff1

・BonDriverProxy_Linux Host

>BonDriverProxy_Linux: BonDriverProxyEx版

>ネットワーク上の別マシン

##インストール手順
・プロジェクトディレクトリ内で下記の手順を実行してください。

###1. epgrecUNA と epgdump を作者ページから適当な場所にダウンロードし展開する
* epgdump を ./epgrecUNA/ に展開する
* epgrecUNA を ./ に展開する

###2. コンテナのビルド準備
####make 時の cpu core 数の指定を設定

```./docker-compose.yml``` の ```CPUCORE=2``` となっている部分を CPU コア数に応じて変更する

####EPG 更新用の cron の設定

```
cp epgrecUNA/crontab.sample epgrecUNA/crontab
```

BonDriver を他で使用している際に EPG 更新が走るとチャンネル権を奪われるので、必要に応じて crontab の設定を変更する

EPGRemote でリアルタイム視聴を使用する予定であれば変更することを推奨します (EPGRemote 専用のチューナーを用意する場合は関係ないです)

####EPGRemote の config のコピー

```
cp ./epgremote_config/config.json.sample ./epgremote_config/config.json
cp ./epgremote_config/logConfig.json.sample ./epgremote_config/logConfig.json
```

###3. コンテナのビルド

```
sudo docker-compose pull
sudo docker-compose build
```

###4. ```./epgrec/config.php``` の編集

#### ```$GR_CHANNEL_MAP``` をチャンネルに合わせて設定する


#### ```$rec_cmds``` に recbond を追加する
* recbond の path は ```/usr/local/bin/recbond``` になる

#### ```$OTHER_TUNERS_CHARA``` でチューナーの設定
* チューナーの数に応じて設定する

* reccmd と device を変更する

BonDriver は /BonDriver にマウントされるので device 指定は以下のように書く

```
'device'   => '--driver /BonDriver/BonDriver_Proxy-T.so'
```

###5. epgrecUNA の実行
以下のコマンドでコンテナが起動する

```
sudo docker-compose up -d
```

以下のディレクトリがマウントされる

```
./BonDriver			->	/BonDriver
./epgrec			->	/var/www/epgrec
./epgremote_config	->	/usr/local/EPGRemote/config
```

###6. BonDriver の設定
コンテナが起動したら以下のコマンドで実行中のコンテナイメージから BonDriver をコピーする

```
sudo docker cp epgrec:/Bon/BonDriver_Proxy.so ./BonDriver/BonDriver_Proxy-S.so
sudo docker cp epgrec:/Bon/BonDriver_Proxy.so ./BonDriver/BonDriver_Proxy-T.so
```

```BonDriver/BonDriver_Proxy-*.so.conf``` の設定をする

```
cp ./BonDriver/BonDriver_Proxy.so.conf.sample ./BonDriver/BonDriver_Proxy-S.so.conf
cp ./BonDriver/BonDriver_Proxy.so.conf.sample ./BonDriver/BonDriver_Proxy-T.so.conf
```

ADDRESS, PORT, BONDRIVER, CHANNEL_LOCK などの必要な部分を書き換える

###7. ブラウザでの epgrecUNA の設定
ブラウザで http://DockerHostIP:8080 へアクセスしてセットアップをする

MySQL の設定は以下のようになっている

```
MySQLホスト名: mysql
MySQL接続ユーザー名: epgrec
MySQL接続パスワード: epgrec
使用データベース名: epgrec
```

ffmpeg は ```/usr/local/bin/ffmpeg ``` にインストールされている

###8. EPGRemote の設定
以下のコマンドで検索用 php ファイルを ```./epgrec``` へコピーする

```
sudo docker cp epgrec:/usr/local/EPGRemote/php/epgremote ./epgrec/
```

```./epgremote_config/config.json``` の設定は [EPGRemote の Readme](https://github.com/l3tnun/EPGRemote#readme) を見ながら設定する

###9. コンテナの停止
以下のコマンドでコンテナを停止できる

```
sudo docker-compose up stop
```

## 設定

### epgrecUNA
* ポート番号: 8080

### EPGRemote
* ポート番号: 8888

### 録画ファイル保存先
epgrec のインストール設定時に設定を変更していなければ、プロジェクトフォルダ内の ```./epgrec/video``` に保存されます。

###ffmpeg
```
ffmpeg -version
ffmpeg version N-82560-gd1d18de Copyright (c) 2000-2016 the FFmpeg developers
built with gcc 4.9.2 (Debian 4.9.2-10)
configuration: --prefix=/usr/local --pkg-config-flags=--static --enable-gpl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libx264 --enable-nonfree
libavutil      55. 40.100 / 55. 40.100
libavcodec     57. 66.105 / 57. 66.105
libavformat    57. 57.100 / 57. 57.100
libavdevice    57.  2.100 / 57.  2.100
libavfilter     6. 67.100 /  6. 67.100
libswscale      4.  3.101 /  4.  3.101
libswresample   2.  4.100 /  2.  4.100
libpostproc    54.  2.100 / 54.  2.100
```

##Licence
MIT Licence としておきます。