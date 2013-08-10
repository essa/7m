
require "forwardable"
require "json"
require "logger"

require 'utils'
require 'config'

module SevenMinutes
  module RadioProgram
    class Item
      include Utils::Playable
      extend Forwardable
      attr_accessor :parent, :persistentID
      attr_accessor :pause_at, :virtual_bookmark, :virtual_played_at
      attr_reader :original_bookmark, :played, :track
      def_delegators :@track, :name, :bookmarkable, :duration, :playedDate, :playedCount, :artist, :album, :bitRate, :rating, :volumeAdjustment, :location
      def_delegators :@track, :'bookmark=', :'bookmarkable=', :'playedDate=', :'playedCount='

      def initialize(track)
        @track = track
        @persistentID = track.persistentID
        @virtual_bookmark = nil
        @virtual_played_at = nil
        @original_bookmark = track.bookmark
        @played = false
      end

      def bookmark
        @virtual_bookmark or @track.bookmark
      end

      def to_json_hash(options={})
        h = {
          id: self.persistentID,
          played: self.played,
          pause_at: self.pause_at,
        }
        if self.parent
          h.merge! path: "programs/#{parent.id}/tracks/#{persistentID}"
        end
        @track.to_json_hash(options).merge(h)
      end

      def update(body)
        self.played = body.delete("played")
        @track.update(body)
      end

      def to_hash
        to_json_hash
      end

      def played_recently?(now=Time.now)
        self.virtual_played_at != nil and self.virtual_played_at > now - 24*60*60
      end

      def save_to(context)
        context[:items][self.persistentID.intern] = { bookmark: pause_at, virtual_played_at: self.virtual_played_at }
      end

      def load_from(context)
        h = context[:items][self.persistentID.intern]
        return unless h
        @virtual_bookmark = h[:bookmark]
        @virtual_played_at = h[:virtual_played_at]
      end

      def active?(now=Time.now)
        @track.playable? and not played_recently?(now)
      end

      def validate_handle
        @track.validate_handle
      end
    end

    class Context
      def initialize(now = Time.now)
        @now = now
        @hash = Hash.new do |h, k|
          h[k] = Hash.new do |hh, kk|
            hh[kk] = { created_at: now}
          end
        end
      end
      def [](key)
        @hash[key] 
      end

      # def []=(key, val)
        # val.default_proc = proc do |hh, kk|
          # hh[kk] = { created_at: @now}
        # end
        # @hash[key] = val
      # end

      def save_to(fname)
        @hash.each do |k, v|
          v.each do |kk, vv|
            vv[:modified_at] = @now
          end
        end
        File::open(fname, 'w') do |f|
          f.write @hash.to_json
        end
      end

      def load_from(fname, logger = Logger.new(STDOUT))
        hash = File::open(fname) do |f|
          JSON.parse(f.read)
        end
        hash.each do |k, v|
          @hash[k.intern] = v.symbolize_keys_recursive
          @hash[k.intern].each do |kk, vv|
            next unless vv[:modified_at]
            modified_at = DateTime.parse(vv[:modified_at]).to_time
            if modified_at < @now - 24*60*60
              @hash.delete(k.intern)
            end
          end
        end
      rescue Errno::ENOENT
        logger.warn $!
      end
    end

    class SourceManager
      class UnknownSource < RuntimeError
      end
      class Source < Struct.new(:name, :proc, :tracks, :index)
        def current_track
          tracks[index]
        end

        def advance_track(t)
          advance_track_1
          if self.any_active_track?(t) and self.current_track and not self.current_track.active?(t)
            advance_track(t)
          end
        end

        def advance_track_1
          self.index += 1
          if self.index >= self.tracks.size
            get_tracks_from_source
            self.index = 0
          end
        end

        def get_tracks_from_source
          self.tracks = self.proc.call.map { |t| Item.new(t) }
        end

        def any_active_track?(now)
          self.tracks.any? { |t| t.active?(now) }
        end
      end
      
      def initialize(config)
        @config = config
        @sources = {}
        @logger = @config[:logger]
        unless @logger
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::FATAL
        end
      end

      def init_source
        @sources.each do |k, v|
          v.index = 0
          v.tracks = []
        end
      end

      def set_now(t)
        @now = t
      end

      def now
        @now or Time.now
      end
    
      def add_source(name, &block)
        @sources[name.intern] = Source.new(name, block, [], 0)
      end

      def peek_next_track(source_name)
        s = get_source(source_name)
        return nil unless s
        s.get_tracks_from_source if s.tracks.size == 0
        t = s.current_track
        return nil unless t
        context = Config::current[:context] || Context.new
        t.load_from(context)
        unless t.active?(now)
          advance_track(source_name)
        end
        t = s.current_track
        t.load_from(context)
        if t and t.active?(now)
          t
        else
          nil
        end
      end

      def advance_track(source_name)
        get_source(source_name).advance_track(now)
      end

      def load_from(context)
        h = context[:source]
        h.each do |name, hh|
          s = get_source(name.to_s)
          s.index = hh[:index] if s
        end
      end

      def save_to(context)
        h = context[:source]
        @sources.each do |k, v|
          h[k] = {
            index: v.index
          }
        end
      end

      def clear_sources
        @sources.each_value do |v|
          v.tracks = []
        end
      end

      private
      def get_source(name)
        return nil unless name
        s = @sources[name.intern]
        raise UnknownSource, "unknown program source #{name}" unless s
        s
      end
    end

    class Program
      include Utils
      include Refresher
      @@programs = nil
      def self.init(conf, itunes)
        manager = SourceManager.new(conf)
        itunes::Playlist::all.each do |pl|
          name = pl.name
          manager.add_source(name) do
            pl  = itunes::Playlist::find_by_name(name)
            if pl
              pl.tracks
            else
              []
            end
          end
        end
        cnt = 0
        remix = conf[:'remixed playlists'] || conf[:programs]
        @@programs = remix.map do |c|
          cnt += 1
          c[:id] = cnt
          c[:logger] = conf[:logger]
          Program.new(c, manager)
        end
      end

      def self.all
        @@programs
      end

      def self.find(id)
        all.find {|rp| rp.id.to_s == id.to_s }
      end

      def self.init_manager
        self.all.each do |prg|
          prg.manager.init_source
          prg.refreshed_at = nil
        end
      end

      attr_reader :config, :manager, :id, :name, :tracks, :frames
      attr_accessor :refreshed_at
      def initialize(config, manager = nil)
        @config = config.symbolize_keys_recursive
        @id = @config[:id]
        @name = @config[:name]
        @logger = @config[:logger]
        unless @logger
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::FATAL
        end
        @manager = manager
        @tracks = []
      end

      def get_new_tracks
        @logger.info 'refresh! start'
        context = Context.new
        context_file = @config[:context_file]
        context.load_from(context_file, @logger) if context_file
        @manager.load_from(context)
        tracks = []
        Config::with_config(@config.merge(context: context)) do
          @config[:frames].each do |frame_config|
            f = Frame.new frame_config.merge(logger: @logger), @manager
            Config::with_config(f.config) do
              begin
                f.get_tracks.each do |t|
                  tracks << t
                end
              rescue SourceManager::UnknownSource
                @logger.warn $!
              end
            end
          end
        end
        @manager.save_to(context)
        tracks.each do |t|
          t.parent = self
          t.save_to(context)
        end
        context.save_to(context_file) if context_file
        @manager.clear_sources
        @logger.info 'refresh! end'
        tracks
      end

      def to_json_hash
        {
          id: id,
          name: name,
          path: "programs/#{id}"
        }
      end
    end

    class Frame
      attr_reader :name, :config, :max_track, :max_duration_per_track, :max_duration, :min_duration

      def initialize(config, manager)
        @config = config.symbolize_keys_recursive
        @manager = manager
        @name = self.config[:name]
        @logger = self.config[:logger]
        @source = self.config[:source]
      end

      def get_tracks
        config = Config::current
        @max_track = config[:max_track] || 100
        @max_duration_per_track = config[:max_duration_per_track].to_i
        parse_duration(config[:duration])
        @logger.debug "Frame #{name} max_track=#{max_track} min=#{min_duration} max=#{max_duration} per_track=#{max_duration_per_track}"

        tracks = []
        t = peek_next_track
        while make_track_usable_for_this_time(tracks, t)
          advance_track
          tracks << t
          t = peek_next_track
        end
        logger = config[:logger]
        logger.info "get_tracks #{name} #{@source} #{tracks.map(&:name).inspect}"

        tracks
      end

      private

      def parse_duration(duration)
        case duration.to_s
        when /(\d+)-(\d+)/
          @min_duration = $1.to_i
          @max_duration = $2.to_i
        when /(\d+)/
          @max_duration = @min_duration = $1.to_i
        else
          @min_duration = 0
          @max_duration = 24*60*60
        end
      end

      def peek_next_track
        @manager.peek_next_track(@source)
      end

      def make_track_usable_for_this_time(tracks, t)
        return false unless t
        return false if tracks.last == t
        if max_track and tracks.size >= max_track
          return false
        end

        if max_duration_per_track > 0
          dl = t.duration_left
          if dl > max_duration_per_track
            t.pause_at = t.bookmark.to_f + max_duration_per_track
          else
            t.pause_at = nil
          end
        end

        total_duration = calc_duration(tracks)
        if min_duration > 0 and total_duration >= min_duration
          return false
        end
        if max_duration > 0
          if t.duration_left + total_duration >= max_duration
            if total_duration >= max_duration
              return false
            else
              t.pause_at = t.bookmark.to_f + (max_duration - total_duration)
              return true
            end
          end
        end
        return true
      end

      def advance_track
        @manager.advance_track(@source)
      end

      def calc_duration(tracks)
        tracks.inject(0) do |duration, t|
          duration + t.duration_left
        end
      end
    end
  end
end

