# 7m (SevenMinutes)

[demo movie](http://www.youtube.com/watch?v=jY747-OmNSE) | 
[slide](http://www.uncate.org/7m/slide/7m.html#/) | 
[日本語](https://github.com/essa/7m/blob/master/READMEJA.md)

SevenMinutes is an open source Audio Media Server for Mac focusing on

- ubiquitous listening 
- remix a "Radio Program" from podcasts and your favorite musics

It can 

- distribute iTunes audio contents to web browsers (players as WebApp) / a dedicated iOS app / mp3 player apps(supporting m3u playlist)
- play your playlists and remix a "Radio Program" for you from them
- sync bookmark and played date real-time to iTunes after playing
- play partially your long tracks 
- export playlists / "Radio Program" as a combined mp3 file for Dropbox mobile apps to listen off line
- reduce traffic by converting audio tracks to specified bit rate for slow 3G connection

A "Radio Program" in SevenMinutes

- uses iTunes playlists / smart playlists as source of audio tracks
- picks up audio tracks from sources in specified duration or number of tracks
- mixes them and create a new combined playlist in real time
- refresh tracks on demand anytime, so you can listen new distributed podcasts
- cuts a long track to specified duration, limits track duration from one source

So you can listen to your "Radio Program"s consists of talk (podcasts) and music anytime, anywhere on virtually every device you have.

Start here -> https://github.com/essa/7m/wiki/GettingStarted

## Why "SevenMinutes" ?

I subscribe many podcasts for learning English and gathering news in tech domain. But most of them are too long for me to listen all because listening English contents requires much concentration for a non-native speaker.

I can listen for only "Seven Minutes" at most with enough concentration.

I need to refresh myself listening my favorite songs some duration after listening podcasts.

So I tried a prototype version of this project and found it was real "Radio Station".

I don't agree to call so called "Net Radio" stations a radio. Because they are only playlists of musics without any talk. I loved AM-radio programs with both talk and music.

Favorite talks between favorite songs, or favorite songs between favorite talks are very interesting contents if automatically refreshed.

I am a heavy user of iTunes smart playlist. But it was not smart enough realizing my real 'Radio Program'.

Now I am enjoying my personal "Radio" consists of "Seven Minutes" talks and favorite music with SevenMinutes.

## Modules

SevenMinutes is consists of 

- a web app with iTunes interface that distributes audio contents by http streaming
- simple GUI front end for OS/X
- a javascript player to play contents on PC/Mac browser
- a real-time converter from iTunes playlists to m3u playlist for many mp3 players
- a dedicated iOS App

It can be invoked in GUI mode or CUI mode.

### GUI mode

SevenMinutes is distributed for end users as a Mac App with every module except iOS app. Get it from 

http://www.uncate.org/7m/

In this mode, you can invoke it as a Mac desktop app just by clicking icon.

Only requirement in this mode is sox.

### CUI mode

SevenMinutes is distributed for power users and developers as a github repository at https://github.com/essa/7m .

You can checkout it and invoke it with MacRuby in a terminal window.

## Setup

### Requirement

#### Platform

Mac OS/X Mountain Lion or higher.

The web app of SevenMinutes is written in MacRuby, so it will not run in other os.

#### sox and ffmpeg

SevenMinutes requires sox (http://sox.sourceforge.net/).

I think easiest way to install it is using Homebrew (http://mxcl.github.io/homebrew/).

  $ brew install sox

And it uses ffmpeg to convert audio files to mp3.

If you have many contents in other than mp3 format, you should install ffmpeg.

  $ brew install ffmpeg

If you use SevenMinutes in GUI mode, sox is only requirement to run it.

If you use SevenMinutes in CUI mode, you have to install products below.

#### MacRuby 0.12 and later (CUI mode only)

Install it from http://macruby.org/ or 

  $ rvm install macruby-0.12

And you should install required gems by

  $ rake install_gems

#### node.js, npm and grunt (CUI mode only)

The web app is written in coffeescript.
You have to compile it by Grunt.

After install node.js and npm,

  $ cd cui.bundle
  $ npm install
  $ grunt

This will generate app.js to cui.bundle/public (for web app) and to ios/www/js (for iOS app).

#### phantomjs (for test mode only)

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

Most of sources are common in web app and native app for iOS (and coming Android app).

The player in iOS uses a phonegap plug-in for streaming audio (AVPlayer).

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

Caution: Currently, no consideration for security!!! Do it at your own risk!!!

## Status

Alpha. But I myself am enjoying my personal "Radio" using this everyday.

Server runs whole day without trouble, but iOS app need restarting between "Program"s sometime.

It modifies 'bookmark', 'playedDate', 'playedCount', 'bookmarkable' attributes of iTunes track. So if you uses these attributes for you smart playlists or something, don't run this in your Mac now.

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
- rateit -- http://rateit.codeplex.com/ cui/public/jslib/jquery.rateit.min.js
- jquery.marquee -- http://remysharp.com/2008/09/10/the-silky-smooth-marquee/ cui/public/jslib/jquery.marquee.js

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

## Author and License

Written by Taku NAKAJIMA.

Released under Ruby's License.

