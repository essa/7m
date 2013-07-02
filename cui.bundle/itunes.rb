#
#  itunes.rb
#  TokyoTower
#
#  Created by Nakajima Taku on 2013/04/02.
#  Copyright 2013年 Nakajima Taku. All rights reserved.
#

require 'date'
require "forwardable"
require "logger"

require 'utils'

framework("ScriptingBridge")

module SevenMinutes
  module ITunes
    @@itunes = nil
    @@logger = Logger.new(STDOUT)
    @@cache = {}
    @@conf = {}

    def self.init_itunes(base_dir)
      return if @@itunes
      # sdef /Applications/iTunes.app | sdp -fh --basename ITunes
      # gen_bridge_metadata -c '-I.' ITunes.h > ITunes.bridgesupport
      load_bridge_support_file File::join(base_dir, 'ITunes.bridgesupport')
      @@itunes = SBApplication.applicationWithBundleIdentifier("com.apple.itunes")
    end

    def self.init_app(conf)
      @@conf = conf
      base_dir = conf[:base_dir]
      self.init_itunes(base_dir)
      @@logger = conf[:logger]
      @@cache = {}
    end

    def self.app
      @@itunes
    end

    def self.logger
      @@logger
    end

    def self.cache
      @@cache
    end

    def self.conf
      @@conf
    end

    def self.library
      @@itunes.sources[0].libraryPlaylists.first
    end

    def self.pause
      @@itunes.pause
    end

    # It may be better to use objectWithID instead of objectWithName
    # But objectWithID didn't work and I could not figure out why.
    def self.name_to_location(name, persistentID)
      t = @@itunes.sources[0].libraryPlaylists.first.fileTracks.objectWithName(name)
      return nil unless t

      if t.persistentID == persistentID 
        t.location and t.location.path
      else
        # if ITunes::conf[:auto_fix_duplicate_name]
        if true
          while t.persistentID != persistentID 
            t.name = t.name + '_'
p t.name
            t = @@itunes.sources[0].libraryPlaylists.first.fileTracks.objectWithName(name)
          end
          t.location.path
        else
          nil
        end
      end
    end

    def self.file_track(track)
      name = track.name
      persistentID = track.persistentID
      t = @@itunes.sources[0].libraryPlaylists.first.fileTracks.objectWithName(name)

      if t.persistentID == persistentID 
        t
      else
        # if ITunes::conf[:auto_fix_duplicate_name]
        if true
          while t.persistentID != persistentID 
            t.name = t.name + '_'
p t.name
            t = @@itunes.sources[0].libraryPlaylists.first.fileTracks.objectWithName(name)
          end
          t
        else
          nil
        end
      end
    end

    class Playlist
      include Utils::Refresher
      extend Forwardable
      attr_reader :track_cache
      def_delegators :@handle, :name, :size, :persistentID

      def self.all
        ITunes::app.sources[0].playlists.select do |pl|
          pl.specialKind == ITunesESpKNone and pl.size > 0
        end.map do |pl|
          Playlist.new(pl)
        end
      end

      def self.find(playlist_id)
        all.find do |pl|
          pl.persistentID == playlist_id
        end
      end

      def self.find_by_name(name)
        all.find do |pl|
          pl.name == name
        end
      end

      def initialize(h)
        @handle = h
        @tracks = []
      end

      def to_json_hash
        {
          id: persistentID,
          name: name,
          path: "playlists/#{persistentID}"
        }
      end

      def get_new_tracks
        tracks_limit = ITunes::conf[:tracks_limit] || 100
        cnt = 0
        tracks = []
        @handle.tracks.map do |t|
          break if cnt > tracks_limit
          cnt += 1
          tt = Track.new(self, t)
          tracks << tt
        end
        tracks
      end

      def tracks
        if @tracks.size == 0
          refresh!
        end
        @tracks
      end

      def config
        ITunes::conf
      end

      def id
        self.persistentID
      end
    end

    class Track
      include SevenMinutes::Utils::Playable
      extend Forwardable
      attr_reader :parent, :handle
      attr_accessor :pause_at
      def_delegators :@handle, :name, :persistentID, :bookmark, :bookmarkable, :duration, :playedDate, :playedCount, :artist, :album, :bitRate, :rating, :volumeAdjustment
      def_delegators :@handle, :'bookmark=', :'bookmarkable=', :'playedDate=', :'playedCount='

      def self.find(playlist_id, track_id)
        pl = Playlist.find(playlist_id)
        return nil unless pl

        handle = ITunes::cache[track_id]
        if handle and handle.persistentID == track_id
          ITunes::logger.debug "cache hit #{handle.persistentID} #{handle.name}"
          return new(pl, handle).tap { |t| t.playlist = pl}
        end

        pl.tracks.find do |t|
          t.persistentID == track_id
        end
      end

      def initialize(parent, handle)
        @parent = parent
        @handle = ITunes::file_track(handle)
        if handle.persistentID
          ITunes::cache.clear if ITunes::cache.size > 1000
          ITunes::cache[handle.persistentID] = handle 
        end
      end

      # Only ITunesFileTrack has location method
      # But ITunesFileTrack can be got from only libraryPlaylist.fileTracks
      def location
        if @handle.kind_of? ITunesFileTrack
          if @handle.location
            @handle.location.path
          else
            nil
          end
        else
          ITunes::name_to_location(self.name, self.persistentID)
        end
      end

      def to_json_hash(options={})
        h = {
          id: persistentID,
          path: "playlists/#{self.parent.persistentID}/tracks/#{persistentID}",
          access_path: "playlists/#{self.parent.persistentID}/tracks/#{persistentID}",
          parent_path: "playlists/#{self.parent.persistentID}",
          name: name,
          bookmarkable: bookmarkable,
          bookmark: bookmark,
          artist: artist,
          duration: duration,
          album: album,
          playedDate: playedDate,
          playedCount: playedCount,
          bitRate: bitRate,
          rating: rating,
          pause_at: pause_at,
        }

        with_location = options[:with_location]
        if with_location
          h[:location] = location 
        end

        h
      end

      def update(param)
        @handle.bookmarkable = param['bookmarkable'] if param['bookmarkable']
        @handle.bookmark = param['bookmark'] if param['bookmark']
        @handle.playedCount = param['playedCount'] if param['playedCount']
        if param['playedDate']
          date = DateTime.parse(param['playedDate'])
          @handle.playedDate = date.to_time
        end
      end
    end
  end

end
