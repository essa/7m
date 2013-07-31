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
    @@index = nil
    @@queue_playlists = []

    def self.init_itunes(base_dir)
      return if @@itunes
      # sdef /Applications/iTunes.app | sdp -fh --basename ITunes
      # gen_bridge_metadata -c '-I.' ITunes.h > ITunes.bridgesupport
      load_bridge_support_file File::join(base_dir, 'ITunes.bridgesupport')
      @@itunes = SBApplication.applicationWithBundleIdentifier("com.apple.itunes")
      @@index = FileTrackIndex.new(@@itunes)
      @@index.load_tracks
    end

    def self.init_app(conf)
      @@conf = conf
      base_dir = conf[:base_dir]
      self.init_itunes(base_dir)
      @@logger = conf[:logger]
      create_queue(conf)
    end

    def self.app
      @@itunes
    end

    def self.logger
      @@logger
    end

    def self.index
      @@index
    end

    def self.conf
      @@conf
    end

    def self.create_queue(conf)
      library = @@itunes.sources.find { |s| s.kind == ITunesESrcLibrary }
      userPlaylists = library.userPlaylists

      qnames = conf[:queue_names] || %w(7m_queue)
      qnames.each do |q_name|
        q_pl = library.playlists.find { |l| l.name == q_name }
        unless q_pl
          q_pl = ITunesUserPlaylist.alloc.initWithProperties(name: q_name) 
          userPlaylists <<  q_pl
        end
        @@queue_playlists << q_pl unless queue_playlist?(q_pl.persistentID)
      end
    end


    def self.queue_playlist?(persistentID)
      @@queue_playlists.find do |q|
        q.persistentID == persistentID
      end
    end

    class FileTrackIndex
      attr_reader :itunes
      def initialize(itunes)
        @itunes = itunes
        @index = {}
        @mutex = Mutex.new
      end

      def load_tracks
        @mutex.synchronize do
          pl = get_pl
          do_load_tracks(pl)
        end
      end

      def [](pid)
        @mutex.synchronize do
          i = @index[pid]
          return nil unless i
          pl = get_pl
          ret = pl.fileTracks[i]
          if ret.persistentID != pid
            do_load_tracks(pl)
            i = @index[pid]
            return nil unless i
            ret = pl.fileTracks[i]
          end
          ret
        end
      end

      private

      def get_pl
        library = @itunes.sources.find { |s| s.kind == ITunesESrcLibrary }
        library.libraryPlaylists.find { |l|  l.specialKind == ITunesESpKLibrary }
      end

      def do_load_tracks(pl)
        ITunes::logger.info "start loading fileTracks"
        ids =  pl.fileTracks.arrayByApplyingSelector(:persistentID)
        @index = {}
        ids.each.with_index do |t, i|
          @index[t] = i
        end
        ITunes::logger.info "end loading fileTracks"
      end
    end

    def self.search(q)
      library = @@itunes.sources.find { |s| s.kind == ITunesESrcLibrary }
      pl = library.libraryPlaylists.find { |l|  l.specialKind == ITunesESpKLibrary }
      only = ITunesESrAAll
      case q
      when /^album: *(.+)/
        only = ITunesESrAAlbums 
        q = $1
      when /^artist: *(.+)/
        only = ITunesESrAArtists
        q = $1
      end
      pl.searchFor(q, only: only)[0..30].map do |t|
        Track.new(nil, t.persistentID)
      end
    end

    class Playlist
      include Utils::Refresher
      extend Forwardable
      def_delegators :@handle, :name, :size, :persistentID
      attr_reader :handle

      def self.all
        ITunes::app.sources[0].playlists.select do |pl|
          pl.specialKind == ITunesESpKNone
        end.map do |pl|
          if ITunes::queue_playlist?(pl.persistentID)
            QueuePlaylist.new(pl)
          else
            Playlist.new(pl)
          end
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
        tracks_limit = ITunes::conf[:tracks_limit] || 30
        cnt = 0
        ret = []
        @handle.get
        tracks = @handle.tracks.dup
        if tracks.size > tracks_limit
          tracks = @handle.tracks[0..tracks_limit]
        end
        tracks.each do |t|
          p cnt
          p t.name
          cnt += 1
          tt = Track.new(self, t.persistentID)
          p tt.handle
          ret << tt if tt.handle
        end
        ret
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

    class QueuePlaylist < Playlist
      def self.all
        Playlist.all.select do |pl|
          pl.kind_of?(QueuePlaylist)
        end
      end

      def self.find_by_name(name)
        Playlist.all.find do |pl|
          pl.name == name
        end
      end

      def add(track_id)
        track = ITunes::index[track_id]
        p :add, track, handle
        p handle.tracks
        handle.tracks.each do |t|
          return if t.persistentID == track_id
        end
        track.duplicateTo handle
        p track.name, handle.name
        p handle.tracks
      end

      def to_json_hash
        super.merge(queue: true)
      end

      def remove_track(persistentID)
        handle.tracks.each do |t|
          if t.persistentID == persistentID
            t.delete
          end
        end
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
        unless playlist_id
          return new(nil, track_id)
        end
        pl = Playlist.find(playlist_id)
        return nil unless pl

        ret = pl.tracks.find do |t|
          t.persistentID == track_id
        end
        if ret
          if ret.validate_handle
            ret
          else
            nil
          end
        else
          nil
        end
      end

      def initialize(parent, pid)
        @parent = parent
        @persistentID = pid
        @handle = ITunes::index[pid]
      end

      # Only ITunesFileTrack has location method
      def location
        if @handle.kind_of? ITunesFileTrack
          if @handle.location
            @handle.location.path
          else
            nil
          end
        else
          nil
        end
      end

      def validate_handle
        if @handle and @handle.get and @handle.persistentID == @persistentID
          true
        else
          @handle = ITunes::index[@persistentID]
          if @handle
            true
          else
            false
          end
        end
      end

      def to_json_hash(options={})
        h = {
          id: persistentID,
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
        if self.parent
          h.merge!(
            path: "playlists/#{self.parent.persistentID}/tracks/#{persistentID}",
            access_path: "playlists/#{self.parent.persistentID}/tracks/#{persistentID}",
            parent_path: "playlists/#{self.parent.persistentID}",
          )
        end

        with_location = options[:with_location]
        if with_location
          h[:location] = location 
        end

        h
      end

      def update(param)
        @handle.rating = param['rating'] if param['rating']
        @handle.bookmarkable = param['bookmarkable'] if param['bookmarkable']
        @handle.bookmark = param['bookmark'] if param['bookmark']
        @handle.playedCount = param['playedCount'] if param['playedCount']
        if param['playedDate']
          date = DateTime.parse(param['playedDate'])
          @handle.playedDate = date.to_time
          if self.parent.kind_of?(QueuePlaylist)
            self.parent.remove_track(self.persistentID)
          end
        end
      end
    end
  end

end
