
# ![logo](https://raw.github.com/essa/7m/master/ios/SevenMinutes/Resources/icons/icon-72.png) 7m (SevenMinutes)

[demo movie](http://www.youtube.com/watch?v=jY747-OmNSE) | 
[slide](http://www.uncate.org/7m/slide/7m.html#/) | 
[日本語](https://github.com/essa/7m/blob/master/READMEJA.md)

7m (SevenMinutes)は、オープンソースのMac専用オーディオメディアサーバです。iTunes内の音楽とPodcastをさまざまな機器で聞くことを可能にします。

- ブラウザ (PCとMacの Chrome/Firefox/Safari)
- iPhone と iPad (iOSの専用アプリを使用)
- Android (ServeStreamというmp3プレイヤーアプリを使用)
- ネット上のm3uプレイリストをサポートしたmp3プレイヤー
- ios用のDropboxアプリ

![overview of 7m](http://www.uncate.org/7m/slide/images/7m.png)

使いたい人はまずはこちらをどうぞ -> [GettingStarted](https://github.com/essa/7m/wiki/GettingStartedJA)


# 三種類のプレイリスト

7m は、基本的には「プレイリスト再生アプリ」です。次の三種類のプレイリストを再生します。

- iTunesのプレイリスト
- 「リミックス」プレイリスト
- 「リクエスト」プレイリスト

## iTunesのプレイリスト

- 7m は iTunes上で作成された プレイリスト / スマートプレイリスト を再生できます
- 再生後に、iTunesで管理されている「再生日時」「再生回数」等の情報を更新します。これは スマートプレイリスト を活用する時に便利です
- 遅い回線用に、低いビットレートに変換して送信することができます

## 「リミックス」プレイリスト

podcastと好きな音楽を「リミックス」したプレイリストを再生することができます。

7m の「リミックス」プレイリストとは

- iTunesのプレイリストとスマートプレイリストを「ソース」として使用し
- 指定された曲数または再生時間に合うように、いくつかのトラックを抜き出し
- リアルタイムで新しい結合されたプレイリストを作成します
- クライアントからのリクエストでいつでも「番組」を再作成します。これによって、新しく到着したpodcastを取りこむことができます
- 長いコンテンツを分割して、少しづつ番組に取り込むことができます。トーク(podcast)と音楽を偏らないようにちょうどよくremixすることが可能です

これによって、いつでもどこでもあなた専用の「ラジオ番組」を聞くことができます。

## 「リクエスト」プレイリスト

- iTunes上の全てのオーディオコンテンツを、クライアントアプリから検索することができます
- 検索結果から指定した曲を「リクエスト」できます
- 「Playing Queue」という特殊なプレイリストがあって、リクエストされた曲はここに追加されます
- 再生すると、その曲は「Playing Queue」から削除されます

- ポッドキャストとiTunes内の好きな音楽から、あなた専用の「ラジオ番組」をリミックスして
- いつでもどこでも聞けるようにすること

## なぜ "SevenMinutes" か？

私は、英語の勉強用と技術関係の情報収集用に、英語のpodcastをたくさん聞いています。しかし、ほとんどが長過ぎて、全部を集中して聞き通すことができません。

私が集中して聞けるのは、せいぜい7分(SevenMinutes)くらいです。

それだけでも集中して聞くと、すぐ音楽を聞いてリラックスしたくなってしまいます。

なので、podcastを分割して間に音楽をはさむスクリプトを作って試してみたのですが、それを聞いてみると「これはラジオだな」と思いました。

今「ネットラジオ」を呼ばれているものは、私から見ると本当のラジオとは言えません。単なる音楽のプレイリストです。私は、AMラジオが好きでよく聞いていたので、トークと音楽が両方あってはじめて「ラジオ」と言えるという思いが強くあります。

好きな音楽の合間に好きなトーク、好きなトークの合間に好きな曲、というのは、それが自動的に配信されるとしたら、とても面白いコンテツになり得ると感じました。

私は、iTunesのsmart playlistのヘビーユーザですが、残念ながら、それだけでは、そういう自分の理想の「ラジオ」を実現することができませんでした。それでこのソフトを開発しました。

今、私は、7分(SevenMinutes)くらいのトークの合間に自分の好きな曲がかかる、自分専用の「ラジオ番組」を毎日、楽しんでいます。

## モジュール

SevenMinutesの構成要素は以下の通りです。

- httpストリーミングでiTunesで管理されたコンテンツを配信するWebアプリ
- 簡単なOS/X用のGUIフロントエンド
- javascriptで書かれたプレイヤー
- iTunesのプレイリストをm3u形式にリアルタイムで変換するコンバータ
- iOSの専用アプリ

そして、SevenMinutesは、GUIモードとCUIモードがあります。

### GUIモード

一般ユーザ用にGUIのフロントエンドを含めたアーカイブをこのURLに置いてあります。

http://www.uncate.org/7m/

これには、iOS専用アプリ以外の全ての構成要素が実行可能な形で含まれていますので、アイコンをクリックすれば、すぐに使用することができます。

これ以外に必要なものは、soxだけです。 https://github.com/essa/7m/wiki/InstallSox

### CUI モード

SevenMinutes は、オープンソースソフトウエアとして、https://github.com/essa/7m で公開しています。

パワーユーザや開発者の方は、これをチェックアウトして、ターミナルから起動することもできます。

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

[README](https://github.com/essa/7m) を参照してください

## Credits

[README](https://github.com/essa/7m) を参照してください

## ライセンス

Written by Taku NAKAJIMA.

Released under Ruby's License.

