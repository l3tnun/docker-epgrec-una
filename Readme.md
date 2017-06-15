# docker-epgrecUNA

epgrecUNA + [EPGRemote](https://github.com/l3tnun/EPGRemote) の Docker コンテナ

## このブランチについて

ffmpeg の nvenc に対応したブランチになっています。

epgrec UNA のベースイメージが Debian から ubuntu 16.04 へ変更になった影響で、php が 5 系から 7 系に変更されています。

そのため、epgrecUNA151114Fix2 の時点で ```epgrec/templates/programTable.html ``` に以下の修正が必要です。

* 666行目の 0x3f を 63 へ変更する

```
#変更前
{if $k_category != 15 || $k_sub_genre>=0x3f }

#変更後
{if $k_category != 15 || $k_sub_genre>=63 }

```

* 679行目の 0x7f を 127 へ変更する

```
#変更前
<b>　曜日:</b>{if $weekofday == 0x7f}なし{else}{$wds_name}{/if}

#変更後
<b>　曜日:</b>{if $weekofday == 127}なし{else}{$wds_name}{/if}

```

## 前提条件
Docker, docker-compose, [nvidia-docker](https://github.com/NVIDIA/nvidia-docker), [u-n-k-n-o-w-n/BonDriverProxy_Linux
](https://github.com/u-n-k-n-o-w-n/BonDriverProxy_Linux) の導入が必須です。

BonDriverProxy_Linux の機能はないので、自分で準備してください。(Dockerfile を追加するなり適当に)

また b25 関係の機能は無いので、 BonDriverProxy_Linux 側で処理をするか、自分で追加してください。

## 動作確認環境

・Docker Host
>OS: Ubuntu Server 16.04 LTS

>Docker version 17.03.1-ce, build c6d412e

>docker-compose version 1.13.0, build 1719ceb

>nvidia-docker version 1.0.1

・BonDriverProxy_Linux Host

>BonDriverProxy_Linux: BonDriverProxyEx版

>ネットワーク上の別マシン

## インストール手順
・プロジェクトディレクトリ内で下記の手順を実行してください。

### 1. epgrecUNA と epgdump を作者ページから適当な場所にダウンロードし展開する
* epgdump を ./epgrecUNA/ に展開する
* epgrecUNA を ./ に展開する

### 2. コンテナのビルド準備
#### make 時の cpu core 数の指定を設定

```./docker-compose.yml``` の ```CPUCORE=2``` となっている部分を CPU コア数に応じて変更する

#### EPG 更新用の cron の設定

```
cp epgrecUNA/crontab.sample epgrecUNA/crontab
```

BonDriver を他で使用している際に EPG 更新が走るとチャンネル権を奪われるので、必要に応じて crontab の設定を変更する

EPGRemote でリアルタイム視聴を使用する予定であれば変更することを推奨します (EPGRemote 専用のチューナーを用意する場合は関係ないです)

#### EPGRemote の config のコピー

```
cp ./epgremote_config/config.json.sample ./epgremote_config/config.json
cp ./epgremote_config/logConfig.json.sample ./epgremote_config/logConfig.json
```

### 3. コンテナのビルド

```
sudo docker-compose pull
sudo docker-compose build
```

### 4. ```./epgrec/config.php``` の編集

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

### 5. epgrecUNA の実行
epgrec の初期設定のために起動する

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

### 6. BonDriver の設定
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

### 7. ブラウザでの epgrecUNA の設定
ブラウザで http://DockerHostIP:8080 へアクセスしてセットアップをする

MySQL の設定は以下のようになっている

```
MySQLホスト名: mysql
MySQL接続ユーザー名: epgrec
MySQL接続パスワード: epgrec
使用データベース名: epgrec
```

ffmpeg は ```/usr/local/bin/ffmpeg ``` にインストールされている

### 8. EPGRemote の設定
以下のコマンドで検索用 php ファイルを ```./epgrec``` へコピーする

```
sudo docker cp epgrec:/usr/local/EPGRemote/php/epgremote ./epgrec/
```

```./epgremote_config/config.json``` の設定は [EPGRemote の Readme](https://github.com/l3tnun/EPGRemote#readme) を見ながら設定する

### 9. コンテナの停止
nvidia-docker から起動するために一度コンテナを停止する

以下のコマンドでコンテナを停止できる

```
sudo docker-compose stop
```

### 10. nvidia-docker からのコンテナの起動
nvidia-docker からコンテナを起動する

--restart=always をつけているため、ホスト起動時にコンテナが自動で起動する

```
sudo ./startup.sh
```

停止する場合は以下のコマンドを実行する

```
sudo ./stop.sh
```

## epgrecUNA によるエンコードの際の注意

www-data で nvenc を使う場合 `LD_LIBRARY_PATH` の設定をすること

```
export LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64
```

## 設定

### epgrecUNA
* ポート番号: 8080

### EPGRemote
* ポート番号: 8888

### 録画ファイル保存先
epgrec のインストール設定時に設定を変更していなければ、プロジェクトフォルダ内の ```./epgrec/video``` に保存されます。

### ffmpeg
```
ffmpeg -version
ffmpeg version 3.3.2 Copyright (c) 2000-2017 the FFmpeg developers
built with gcc 5.4.0 (Ubuntu 5.4.0-6ubuntu1~16.04.4) 20160609
configuration: --prefix=/usr/local --disable-shared --pkg-config-flags=--static --enable-gpl --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libx264 --enable-nonfree --enable-nvenc --enable-cuda --enable-cuvid --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-cflags=-I/usr/local/include --extra-ldflags=-L/usr/local/cuda/lib64
libavutil      55. 58.100 / 55. 58.100
libavcodec     57. 89.100 / 57. 89.100
libavformat    57. 71.100 / 57. 71.100
libavdevice    57.  6.100 / 57.  6.100
libavfilter     6. 82.100 /  6. 82.100
libswscale      4.  6.100 /  4.  6.100
libswresample   2.  7.100 /  2.  7.100
libpostproc    54.  5.100 / 54.  5.100
```

## Licence
MIT Licence としておきます。