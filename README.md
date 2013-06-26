
# 7m (SevenMinutes)

SevenMinutes is an Audio Media Server for Mac. It makes a Net Radio Station from your iTunes contents.

It can 

- distributes iTunes audio contents for web browsers (players as WebApp) / a dedicated iOS App / mp3 player apps(using m3u / pls playlist)
- play your playlists and mix a "Radio Program" for you from them
- play partially your long tracks and mix a Radio Program from them
- sync bookmark and played date real-time to iTunes after playing
- export playlists / "Radio Program" as a combined mp3 file for Dropbox mobile apps to listen off line
- reduce trafic by converting audio tracks to specified bit rate for slow 3G connection

A "Radio Program" in SevenMinutes

- uses iTunes playlists / smart playlists as a source of audio tracks
- picks up audio tracks from sources in specified duration or number of tracks
- mixes them and make a new combined playlist
- refresh tracks on demand anytime, you can listen new distrubted podcasts real-time
- cuts a long track to specified duration, limets track duration from one source

So you can listen to your "Radio Program"s consists of talk (podcasts) and music anytime, anywhere on virtually every device you have.

And you can pause anytime and continue on other device.

## Modules

SevenMinutes is consists of 

- a web server with iTunes interface that distributes audio contents by http streaming
- simple GUI frontend for Mac
- a Web App to listen contents on PC/Mac browser
- a real-time converter from iTunes playlists to m3u playlist for many mp3 players
- a dedicated iOS App

It can be invoked in GUI mode or CUI mode.

### GUI mode

SevenMinutes is distributed for end users as a Mac App with every module except iOS app.

In this mode, you can invoke it just clicking icon.

Only requirement in this mode is sox.

### CUI mode

SevenMinutes is distributed for power users and developers as a github repository.

You can checkout it and invoke it with MacRuby in terminal.

## Setup

### Requirement

#### sox and ffmpeg

SevenMinutes requires sox (http://sox.sourceforge.net/).

I think easiest way to install it is using Homebrew (http://mxcl.github.io/homebrew/).

  $ brew install sox

And it uses ffmpeg to convert audio files to mp3.

If you have many contents in other than mp3 format, you should install ffmpeg.

  $ brew install ffmpeg

If you use SevenMinutes in GUI mode, sox is only requirement to run it.

If you use SevenMinutes in CUI mode, you have to install products below.

#### MacRuby 0.12 and later

Install it from http://macruby.org/ or 

  $ rvm install macruby-0.12

And you should install required gems by

  $ rake install_gems

#### node.js, npm and grunt

The web app is written in coffeescript.
You have to compile it by Grunt.

After install node.js and npm,

  $ cd cui.bundle
  $ npm install
  $ grunt

This will generate app.js to cui.bundle/public (for web app) and to ios/www/js (for iOS app).

#### phantomjs

running js specs in CUI mode requires phantomjs

  $ rake jasmine

### running SevenMinutes in CUI mode

Edit cui.bundle/7m.yml and

  $ cd cui.bundle
  $ macruby cui_main.rb 7m.yml

### running iOS app

(under construction)

## Testing

Caution: some spec will create a playlist named '7mtest' and add some tracks to iTunes!

  $ rake spec  # unit tests for web server
  $ rake jasmine # unit tests for web app
  $ rake integration_test # integration test

The integration_test is written using capybara.

I can't find a way to run capybara in macruby. So I wrote it for Matz ruby2.0.0.

You need Ruby 2.0.0 installed if you run integration tests.

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

Players are written in Coffeescript with backbone.js, jQuery mobile, phonegap.

Most of sources are common in web app and native app for iOS (and comming Android app).

## Related Projects

### Music players tested with SevenMinutes

iRadio(iOS)
https://itunes.apple.com/it/app/iradio/id426290891?mt=8

ServerStream(Android)
https://play.google.com/store/apps/details?id=net.sourceforge.servestream

### UPnP PortMapper

You can connect to SevenMinutes across 3G using

UPnP PortMapper
http://upnp-portmapper.sourceforge.net/

## Credits

### Sample mp3 files for tests are public domain music and donwloaded from

cui.bundle/spec/fixtures/*.mp3

Classical Music mp3 Free Download Historical Recordings Public Domain
http://classicalmusicmp3freedownload.com/index.php?title=Main_Page

### icon files 

cui.bundle/public/images/*

Pretty Office Icon Set Part 8 | Custom Icon Design
http://www.customicondesign.com/free-icons/pretty-office-icon-set/pretty-office-icon-set-part-8/
http://www.iconarchive.com/show/pretty-office-8-icons-by-custom-icon-design.html

## ToDo

- more specs
- improve visual design
- Android App
- Simple authentication with Basic Auth
- UPnP Integration
- editing 7m.yml in GUI
- plugin System for Radio Program

## License

Ruby's

