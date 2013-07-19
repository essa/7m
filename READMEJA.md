
# 7m (SevenMinutes)

SevenMinutes は、オープンソースのMac専用オーディオメディアサーバです。目標は

- ポッドキャストとiTunes内の好きな音楽からあなた専用の「ラジオ番組」re-mixして
- いつでもどこでも聞けるようにすること

です。具体的には

- iTunesで管理されているオーディオコンテンツを、ブラウザー内のプレイヤー、iOS用の専用アプリ、mp3プレイヤーアプリ(m3u形式のplaylistをサポートしているもの)に配信します
- プレイリストをそのまま再生することと、そこから「ラジオ番組」をリミックスすることができます
- 再生後にリアルタイムで、iTunesのブックマーク(再生位置)や再生日時を同期します
- 長いコンテンツを部分的に(少しづつ)聞くことができます
- プレイリストと「ラジオ番組」を一つの長いmp3ファイルにexportできます。これを利用して、Dropboxのiosアプリでオフラインで聞くことができます。
- 細い回線でも聞けるように、ビットレートをリアルタイムで下げて変換して配信できます

SevenMinutesの「ラジオ番組」とは

- iTunesのプレイリストとスマートプレイリストを「ソース」として使用し
- 指定された曲数または再生時間に合うように、いくつかのトラックを抜き出し
- リアルタイムで新しい結合されたプレイリストを作成します
- クライアントからのリクエストでいつでも「番組」を再作成します。これによって、新しく到着したpodcastを取りこむことができます
- 長いコンテンツを分割して、少しづつ番組に取り込むことができます。トーク(podcast)と音楽を偏らないようにちょうどよくremixすることが可能です

これによって、いつでもどこでもあなた専用の「ラジオ番組」を聞くことができます。

はじめてみましょう -> https://github.com/essa/7m/wiki/GettingStarted

## なぜ "SevenMinutes" か？

私は、英語の勉強用と技術関係のニュースを知るために、たくさんのpodcastを聞いています。しかし、ほとんどが長過ぎて、全部を集中して聞き通すことができません。

私が集中して聞けるのは、せいぜい7分(SevenMinutes)くらいです。

それだけでも集中して聞くと、すぐ音楽を聞いてリラックスしたくなってしまいます。

なので、podcastを分割して間に音楽をはさむスクリプトを作って試してみたのですが、それを聞いてみると「これはラジオだな」と思いました。

今「ネットラジオ」を呼ばれているものは、私から見ると本当のラジオとは言えません。単なる音楽のプレイリストです。私は、昔、AMのラジオをよく聞いていたので、トークと音楽が両方あってはじめて「ラジオ」と言えるという思いが強くあります。

好きな音楽の合間に好きなトーク、好きなトークの合間に好きな曲、というのは、それが自動的に配信されるとしたら、とても面白いコンテツになり得ると考えました。

私は、iTunesのsmart playlistのヘビーユーザですが、残念ながら、それだけでは、それを実現することができませんでした。

それで、このソフトを開発したのですが、今、私は、7分のトークの合間に自分の好きな曲がかかる、自分専用の「ラジオ番組」を毎日、楽しんでいます。

## モジュール

SevenMinutesの構成要素は以下の通りです。

- httpストリーミングでiTunesで管理されたコンテンツを配信するWebアプリ
- 簡単なOS/X用のGUIフロントエンド
- javascriptで書かれたプレイヤーアプリ
- iTunesのプレイリストをm3u形式にリアルタイムで変換するコンバータ
- iOSの専用アプリ

そして、SevenMinutesは、GUIモードとCUIモードがあります。

### GUIモード

一般ユーザ用にGUIのフロントエンドから起動します。この形式のアーカイブは下記のURLにあります。

http://www.uncate.org/7m/

これには、iOS専用アプリ以外の全ての構成要素が実行可能な形で含まれていますので、ただ、アイコンをクリックすれば使用することができます。

これ以外に必要なものは、SOXだけです。 https://github.com/essa/7m/wiki/InstallSox

### CUI モード

SevenMinutes は、オープンソースソフトウエアとして、https://github.com/essa/7m で公開しています。

パワーユーザや開発者の方は、これをチェックアウトして、ターミナルから起動することができます。

## セットアップ

### 必要ソフト

#### プラットフォーム

Mac OS/X Mountain Lion or higher.

SevenMinutes のサーバ側は MacRuby で書かれているので、他のOSでは動きません。

#### sox and ffmpeg

SevenMinutes は sox (http://sox.sourceforge.net/) が必要です。

soxのインストールは、 Homebrew (http://mxcl.github.io/homebrew/) から行なうのが一番簡単だと思います。Homebrewがインストールされていれば

  $ brew install sox

でインストールできます。

また、近い将来、ffmpegによって、mp3以外のファイルもサポートする予定です。ついでに

  $ brew install ffmpeg

もインストールしておいた方がいいでしょう。

GUIモードで使用する場合は、必要ソフトは sox だけです。

CUIモードでは、これに加え、下記のソフトが必要になります。

#### MacRuby 0.12 and later (CUI mode only)

http://macruby.org/ からインストールするか、rvmで下記のコマンドでインストールしてください。

  $ rvm install macruby-0.12

その後、下記コマンドで必要なgemをインストールしてください。

  $ rake install_gems

#### node.js, npm and grunt (CUI mode only)

クライアント側のアプリは、 coffeescript で書かれています。node.jsとnpmをインストールしてから下記コマンドを実行してください。

  $ cd cui.bundle
  $ npm install
  $ grunt

これによって app.js が生成され、cui.bundle/public (for web app) と ios/www/js (for iOS app) にコピーされます。

#### phantomjs (for test mode only)

CUIモードでspecを実行するには、phantomjsが必要です。これをインストールしてから、下記コマンドを実行してください。

  $ rake jasmine

### running SevenMinutes in CUI mode

エディタで、cui.bundle/7m.yml を編集してから、下記コマンドによって起動します。

  $ cd cui.bundle
  $ macruby cui_main.rb 7m.yml

### running iOS app

(under construction)

## Testing

警告: specを実行すると、iTunesに'7mtest'というプレイリストが作成され、いくつかの曲がそこに追加されます。

  $ rake spec  # unit tests for web server
  $ rake jasmine # unit tests for web app
  $ rake integration_test # integration test

integration_test は capybara で書かれています。macrubyでcapybaraを動かすことができなったので、このテストだけは、ruby-2.0.X で動かします。

## Technical memos

### JS libraries

- jQuery
- jQuery mobile
- backbone.js and underscore.js
- jPlayer (http://jplayer.org/)

for testing JS

- jasmine
- sinon
- jasmine-jquery
- phantomjs

### Web App as Mac OS/X desktop App and cui app written in MacRuby

(under construction)

### phonegap for web app and native app

クライアントのプレイヤーは、Coffeescript with backbone.js, jQuery mobile, phonegap によって書かれています。

7割くらいのコードは、WebAppとios native app で共通に使われています。(今後、開発するandroid app でも同じコードが使えると思います)。

ただ、iosアプリのプレイヤーは、StreamAudioというios専用のphonegapプラグインを新たに開発して、これを使用しています。

## Related Projects

### 動作確認したプレイヤー

iRadio(iOS)
https://itunes.apple.com/it/app/iradio/id426290891?mt=8

ServerStream(Android)
https://play.google.com/store/apps/details?id=net.sourceforge.servestream

### UPnP PortMapper

警告: 現状はセキュリティ上の考慮を何もしていません。at your own risk で使ってください。

UPnP PortMapper
http://upnp-portmapper.sourceforge.net/

## Status

アルファレベルです。ただ、自分は毎日使えています。

サーバはだいたい一日動きます。iOSのアプリは、時々再起動が必要です。

このプログラムは、iTunesの 以下の項目を変更します。

- 再生位置 'bookmark'
- 再生日時 'playedDate'
- 再生回数 'playedCount'
- 再生位置を記憶 'bookmarkable' 

このあたりをよく使っている方は、十分注意して使用してください。

## ToDo

- documents
- more specs
- improve visual design
- enable rating 
- cross fade
- notification about interaction with server in players
- better audio session handling in iOS app
- Android App
- Simple authentication with Basic Auth
- UPnP Integration
- editing 7m.yml in GUI
- plug-in System for remixing "Radio Program"

## Credits

### Source imported in this repository

- VolumeSlider phonegap plug-in (https://github.com/phonegap/phonegap-plugins/tree/master/iPhone/VolumeSlider) -- ios/SevenMinutes/VolumeSlider.*
- jQuery -- cui.bundle/public/jslib/jquery-*
- jQueryMobile -- cui.bundle/public/jslib/jquery-mobile
- jPlayer -- cui.bundle/public/jslib/jplayer*
- backbone.js -- cui.bundle/public/jslib/backbone.js
- underscore.js -- cui.bundle/public/jslib/underscore.js

### Sources modified from other projects.

StreamAudio plugin was modified from phonegap Media plugin

- ios/SevenMinutes/Plugins/StreamAudio.h
- ios/SevenMinutes/Plugins/StreamAudio.m

WebServer was modified from control_tower (https://github.com/MacRuby/ControlTower)

- cui.bundle/control_tower_ext.rb

### Sample mp3 files for tests are public domain music and downloaded from

Classical Music mp3 Free Download Historical Recordings Public Domain
http://classicalmusicmp3freedownload.com/index.php?title=Main_Page

cui.bundle/spec/fixtures/*.mp3

### icon files 

cui.bundle/public/images/*

Pretty Office Icon Set Part 8 | Custom Icon Design
http://www.customicondesign.com/free-icons/pretty-office-icon-set/pretty-office-icon-set-part-8/
http://www.iconarchive.com/show/pretty-office-8-icons-by-custom-icon-design.html

## ライセンス

Written by Taku NAKAJIMA.

Released under Ruby's License.

