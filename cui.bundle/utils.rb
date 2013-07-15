
require 'shellwords'
require 'date'
require 'json'

class Hash
  def symbolize_keys_recursive
    dup.symbolize_keys_recursive!
  end
  def symbolize_keys_recursive!
    keys.each do |key|
      self[(key.to_sym rescue key) || key] = delete(key)
    end
    values.each do |val|
      if val.kind_of?(Hash)
        val.symbolize_keys_recursive!
      end
    end
    self
  end
end

module SevenMinutes
  module Utils
    module ArrayExt
      def prev_me_next(&block)
        ret = []
        (self + [nil]).inject([nil, nil]) do |prev_and_me, _next|
          _prev, me = *prev_and_me
          # puts "#{_prev}, #{me}, #{_next}"
          ret << [_prev, me, _next] if me
          [me, _next]
        end

        ret.map do |_prev, me, _next|
          block.call _prev, me, _next
        end
      end
    end

    class Shell
      def initialize(logger)
        ENV['PATH'] = ENV['PATH'] + ':/usr/local/bin'
        @logger = logger
      end

      def exec(cmd)
        @logger.debug cmd
        r, w = IO.pipe
        pid = spawn(cmd, :out=>w, :err=>w)
        w.close
        Process.waitpid pid
        ok = $?.exitstatus == 0
        if ok
          @logger.debug r.read
        else
          @logger.warn "command '#{cmd[0..20]}...' failed!"
          @logger.warn r.read
        end
        ok
      end

      def with_lock(path, &block)
        lockfile = "#{File::dirname(path)}/lock"
        FileUtils::mkdir_p File::dirname(lockfile)
        FileUtils::touch lockfile
        File.open(lockfile, 'w') do |f|
          f.flock(File::LOCK_EX)
          begin
            block.call
          ensure
            f.flock(File::LOCK_UN)
          end
        end
      end
    end

    class Sox
      attr_reader :sox_bin, :sox_opt, :bps_opt, :trim_opt, :infile, :outfile
      def initialize(infile, outfile, options={})
        conf = SevenMinutes::Config::current
        @sox_bin = conf[:sox_bin] || 'sox'
        @sox_opt = conf[:sox_opt] || '--buffer 1024000'
        @bps_opt = make_bps_opt(options[:bps])
        @trim_opt = make_trim_opt(conf, options)
        @outfile = Shellwords::escape(outfile)
        @infile = case infile
                  when Array
                    infile.map do |f|
                      Shellwords::escape(f) + ' -c 2'
                    end.join(' ')
                  else
                    Shellwords::escape(infile.to_s) + ' -c 2'
                  end
      end

      def command
        [sox_bin, sox_opt, infile, bps_opt, outfile, trim_opt].compact.join(' ')
      end

      def make_bps_opt(bps)
        case bps.to_i
        when 1..24 ; "-r 8000"
        when 24..32 ; "-r 12000"
        when 32..48 ; "-r 16000"
        when 48..64 ; "-r 24000"
        when 64..96 ; "-r 32000"
        when 96..128 ; "-r 48000"
        else ; nil
        end
      end

      def make_trim_opt(conf, options)
        start = options[:start].to_i
        pause = options[:pause].to_i
        fadetime = (conf[:sox_fadetime] || 3).to_i
        if start > 0
          if pause > 0
            "trim #{start-fadetime} fade #{fadetime} #{pause-start+fadetime*2}"
          else
            "trim #{start-fadetime} fade #{fadetime}"
          end
        else
          if pause > 0
            "fade 0 #{pause} #{fadetime}"
          else
            nil
          end
        end
      end
    end

    module Playable
      attr_accessor :played

      def duration_left
        if self.pause_at
          self.pause_at - self.bookmark.to_i
        else
          self.duration.to_i - self.bookmark.to_i
        end
      end

      def playable?
        location = self.location
        # location != nil and location =~ /(mp3|m4a)/ and File::exists?(location) and not played 
        location != nil and location =~ /mp3$/ and File::exists?(location) 
      end

      def exec(cmd)
        shell = Thread::current[:seven_minutes_conf][:shell]
        shell.exec(cmd)
      end

      def media_file_path(options={})
        if options[:bps].to_i > 0 or options[:start].to_i > 0 or options[:pause].to_i > 0
          media_temp = Thread::current[:seven_minutes_conf][:media_temp] || '/tmp/7m'
          bps = options[:bps] || 0
          id = self.persistentID
          filename = id
          if options[:start].to_i > 0
            filename += "_from_#{options[:start]}"
          end
          if options[:pause].to_i > 0
            filename += "_to_#{options[:pause]}"
          end
          File::join(media_temp, bps.to_s, id[0], filename + '.mp3')
        else
          self.location
        end
      end

      def prepare_media(options={})
        media_file_path = self.media_file_path(options)
        location = self.location
        if media_file_path != location
          return true if File::exists?(media_file_path)
          conf = Config::current
          shell = conf.shell
          shell.with_lock(media_file_path) do
            unless File::exists?(media_file_path)
              if location =~ /(m4a|m4p)/
                temp = "/tmp/#{self.persistentID}.mp3"
                shell.exec("ffmpeg -v error -y -i #{Shellwords::escape(location)} #{temp}")
                location = temp
              end
              sox = Sox.new(location, media_file_path, options)
              shell.exec(sox.command)
            else
              true
            end
          end
        else
          true
        end
      end

      def update_bookmark_and_playedDate(now = DateTime.now)
        if self.pause_at and self.pause_at.to_i > 0
          update('bookmarkable' => true, 'bookmark' => self.pause_at, 'played' => 1)
        else
          update('playedDate' => now.to_s, 'playedCount' => self.playedCount + 1, 'played' => 1)
        end
      end
    end

    module Refresher
      attr_reader :refreshed_at, :timestamp

      # user class must define tracks and get_new_tracks
      def refresh!(options={})
        if options[:clear]
          @tracks.clear
        else
          @tracks = @tracks.select {|t| t.validate_handle and not t.played }
        end
        track_ids = {}
        @tracks.each {|t| track_ids[t.persistentID] = true }

        self.get_new_tracks.each do |t|
          pid = t.persistentID
          cnt = 1
          while track_ids[t.persistentID]
            cnt += 1
            t.persistentID = "#{pid}_#{cnt}"
          end
          @tracks << t
          track_ids[t.persistentID] = true
        end
        @refreshed_at = options[:now] || Time.now
        @timestamp = @refreshed_at.to_i
      end

      def refresh_if_needed!(options=nil)
        options ||= {}
        minimum_tracks = options[:minimum_tracks] || 0
        minimum_duration = options[:minimum_duration] || 0
        active_tracks = self.tracks.select {|t| t.playable? and not t.played}
        duration = active_tracks.inject(0) { |d, t| d + t.duration_left }
        if options[:force] or active_tracks.size <= minimum_tracks or duration <= minimum_duration
          refresh!(options)
        end
      end

    end

    class TrackList
      def initialize(list)
        @list = list
      end


      def to_json_array
        tracks = @list.tracks.map do |t|
          t.validate_handle
          t.to_json_hash
        end
        set_prev_next(tracks)
        tracks
      end

      def prepare_media(options={})
        ret = true
        bps = options[:bps].to_i
        mpath = if options[:command] == 'export'
                  name = options[:name]
                  fname = DateTime.now.strftime("#{name}_%m%d%H%M_#{bps}")
                  File::expand_path("~/Dropbox/7m/#{fname}.mp3")
                else
                  media_file_path(options)
                end
        shell = Thread::current[:seven_minutes_conf][:shell]
        shell.with_lock(mpath) do
          unless File::exists?(mpath)
            files = []
            tracks = []
            @list.tracks.each do |t|
              t.validate_handle
              t.extend Playable
              start = t.bookmark
              pause = t.pause_at
              t_options = {
                start: start,
                pause: pause,
                bps: bps
              }
              ret = t.prepare_media(t_options)
              next unless ret
              path = t.media_file_path(t_options)
              next unless File::exists?(path)
              files << path
              tracks << t
            end
            sox = Sox.new(files, mpath, options)
            ret = shell.exec(sox.command) 
            if ret and options[:command] == 'export'
              ret = update_bookmark_and_playedDate(tracks)
            end
          end
        end
        ret
      end

      def media_file_path(options={})
        media_temp = Thread::current[:seven_minutes_conf][:media_temp] || '/tmp/7m'
        media_temp += "/list"
        bps = options[:bps] || 0
        id = @list.id.to_s 
        filename = id
        if options[:start]
          filename += "_from_#{options[:start].to_i}"
        end
        if options[:pause]
          filename += "_to_#{options[:pause].to_i}"
        end
        File::join(media_temp.to_s, bps.to_s, id[0].to_s, filename.to_s + '.mp3')
      end

      def update_bookmark_and_playedDate(tracks)
        tracks.each do |t|
          t.update_bookmark_and_playedDate
        end
      end

      def to_pls(options)
        bps = options[:bps]
        pls = [
          '[playlist]',
        ]
        @list.tracks.each.with_index(1) do |t, i|
          t.validate_handle
          start = t.original_bookmark
          pause = t.pause_at
          t_options = {
            start: start.to_i,
            pause: pause.to_i,
            bps: bps || 0
          }
          path = "/#{options[:type]}/#{options[:id]}/tracks/#{t.persistentID}/media/#{t_options[:bps]}"
          if t_options[:start] > 0 or t_options[:pause] > 0
            path += "/#{t_options[:start]}-#{t_options[:pause]}"
          end
          # pls << "File#{i}=" + options[:host] + path + ".mp3?sync=true"
          # pls << "File#{i}=" + options[:host] + path + ".mp3"
          pls << "File#{i}=" + "#{options[:id]}/tracks/#{t.persistentID}/media/#{t_options[:bps]}.mp3?sync=1&prepareNext=1"
          pls << "Title#{i}=" + "#{t.album} - #{t.name}(#{start}-#{pause})"
          pls << "Length#{i}=" + "#{t.duration_left.to_i}"
        end
        pls << "NumberOfEntries=#{@list.tracks.size}"
        pls << 'Version=2' 

        # puts pls.join("\n") + "\n"
        pls.join("\n") + "\n"
      end
      
      def to_m3u8(options)
        bps = options[:bps]
        m3u8 = [
          '#EXTM3U',
        ]
        @list.refresh_if_needed!(Config::current[:m3u]) 

        @list.tracks.each do |t|
          next if t.played
          t.validate_handle
          start = t.original_bookmark
          pause = t.pause_at
          t_options = {
            start: start.to_i,
            pause: pause.to_i,
            bps: bps || 0
          }
          album_or_artist = t.album || t.artist
          m3u8 << 
            "#EXTINF:#{t.duration_left.to_i}, " +
              if album_or_artist 
                "#{album_or_artist} - #{t.name}" 
              else
                t.name
              end +
              if start.to_i > 0 or pause.to_i > 0
                "(#{start}-#{pause})"
              else
                ""
              end
          path = "/#{options[:type]}/#{options[:id]}/tracks/#{t.persistentID}/media/#{t_options[:bps]}"
          if t_options[:start] > 0 or t_options[:pause] > 0
            path += "/#{t_options[:start]}-#{t_options[:pause]}"
          end
          m3u8 << options[:host].to_s + path + ".mp3?sync=1&prepareNext=1"
        end

        # puts m3u8.join("\n") + "\n"
        m3u8.join("\n") + "\n"
      end

      def prepare_next_of(bps, track)
        i = @list.tracks.index(track)
        return unless i
        next_track = @list.tracks[i+1]
        return unless next_track

        options = {
          start: next_track.bookmark.to_i,
          pause: next_track.pause_at.to_i,
          bps: bps
        }
        mpath = Config::with_config(@list.config){ media_file_path }
        return if File::exists?(mpath)

        queue = Dispatch::Queue.concurrent
        @list.config[:logger].debug "prepare sox for #{next_track.name} #{next_track.bookmark} #{next_track.pause_at}"
        queue.after(5+rand(5)) do
          Config::with_config(@list.config) do
            unless File::exists?(mpath)
              Config::current[:logger].debug "delayed start sox for #{next_track.name} #{next_track.bookmark} #{next_track.pause_at}"
              next_track.prepare_media(options) 
            end 
          end 
        end
      end

      private
      def exec(cmd)
        shell = Thread::current[:seven_minutes_conf][:shell]
        shell.exec(cmd)
      end

      def set_prev_next(tracks)
        tracks.extend ArrayExt
        tracks.prev_me_next do |_prev, me, _next|
          if _prev
            me[:prev_id] = _prev[:id]
            me[:prev_path] = _prev[:path]
          end
          if _next
            me[:next_id] = _next[:id]
            me[:next_path] = _next[:path]
            me[:next_media_path] = _next[:media_path]
          end
          me
        end
      end
    end


    # for avoiding a bug of MacRuby!!!
    # can't access Array#prev_me_next in some special situation
    # def prev_me_next(array, &block)
      # ret = []
      # (array + [nil]).inject([nil, nil]) do |prev_and_me, _next|
        # _prev, me = *prev_and_me
        # # puts "#{_prev}, #{me}, #{_next}"
        # ret << [_prev, me, _next] if me
        # [me, _next]
      # end

      # ret.map do |_prev, me, _next|
        # block.call _prev, me, _next
      # end
    # end

  end
end
