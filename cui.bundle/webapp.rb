
require 'sinatra/base'
require 'sinatra/xsendfile'
require 'json'
require 'yaml'
require 'version'
require 'itunes'
require 'radio_program'

module SevenMinutes

  class CommonLogger
    # FORMAT = %{%s - %s [%s] "%s %s%s %s" %d %s %0.4f\n}
    FORMAT = %{%s - %s "%s %s%s %s" %d %s %0.4f}

    def initialize(app, logger)
      @app = app
      @logger = logger
    end
    def call(env)
      began_at = Time.now
      status, header, body = @app.call(env)
      header = Rack::Utils::HeaderHash.new(header)
      log(env, status, header, began_at)
      [status, header, body]
    end
    private
    def log(env, status, header, began_at)
      now = Time.now

      length = extract_content_length(header)

      @logger.info FORMAT % [
        env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
        env["REMOTE_USER"] || "-",
        # now.strftime("%d/%b/%Y %H:%M:%S"),
        env["REQUEST_METHOD"],
        env["PATH_INFO"],
        env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
        env["HTTP_VERSION"],
        status.to_s[0..3],
        length,
        now - began_at ]

      e = env['sinatra.error']
      if e and not e.kind_of?(Sinatra::NotFound)
        @logger.error e.to_s
        @logger.error e.backtrace.join("\n")
      end
    end

    def extract_content_length(headers)
      value = headers['Content-Length'] or return '-'
      value.to_s == '0' ? '-' : value
    end
  end

  class App < Sinatra::Base
    include Sinatra::Xsendfile
    include SevenMinutes
    include SevenMinutes::RadioProgram
    include SevenMinutes::Utils

    def initialize(conf)
      @conf = conf
      super()
    end
    
    @@playlist_root = {}

    def self.add_playlist_root(name, root)
      @@playlist_root[name] = root
    end

    def self.get_playlist_root(name)
      @@playlist_root[name]
    end

    configure do
      base_dir = SevenMinutes::base_dir
      set :public, base_dir + '/public' # for sinatra 1.0
      set :public_folder, base_dir + '/public'

      #Sinatra::Xsendfile.replace_send_file! # replace Sinatra's send_file with x_send_file
      set :xsf_header, "X-Sendfile" # for ControlTower
    end

    get '/' do
      index_html_path = File::join(settings.public_folder, "index.html")
      send_file index_html_path
    end

    get %r{^/(programs|playlists)$} do
      list = params[:captures].first
      playlist_root(list).all.map do |playlist|
        playlist.to_json_hash
      end.to_json
    end

    get %r{^/(programs|playlists)/(\w+)$} do
      list, id = params[:captures]
      playlist = playlist_root(list).find(id)
      playlist.to_json_hash.to_json
    end

    get %r{^/(programs|playlists)/(\w+).pls$} do
      list, id = params[:captures]
      playlist = playlist_root(list).find(id)
      return 404 unless playlist

      playlist.refresh_if_needed!(force: params[:refresh])
      content_type 'audio/mpegurl'
      Config::with_config(playlist.config) do
        tl = Utils::TrackList.new(playlist)
        tl.to_pls(host: 'http://' + request.host_with_port, type: list, id: id, bps: params[:bps])
      end
    end
  
    get %r{^/(programs|playlists)/(\w+).m3u8?$} do
      list, id = params[:captures]
      playlist = playlist_root(list).find(id)
      return 404 unless playlist

      playlist.refresh_if_needed!(force: params[:refresh]) 
      # playlist.refresh! if playlist.kind_of?(Program)
      content_type 'audio/x-mpegurl'
      Config::with_config(playlist.config) do
        tl = Utils::TrackList.new(playlist)
        tl.to_m3u8(host: 'http://' + request.host_with_port, type: list, id: id, bps: params[:bps])
      end
    end

    post %r{^/(programs|playlists)/(\w+)/refresh$} do
      list, id = params[:captures]
      playlist = playlist_root(list).find(id)
      p params
      playlist.refresh!(params)
      { ok: true }.to_json
    end

    get %r{^/(programs|playlists)/(\w+)/media/?(\d+)?$} do
      list, id, bps = params[:captures]
      playlist = playlist_root(list).find(id)
      tl = Utils::TrackList.new(playlist)
      Config::with_config(playlist.config) do
        path = tl.media_file_path(bps: bps)
        if File::exists?(path)
          content_type('audio/mpeg')
          Config::with_config(playlist.config) do
            x_send_file(path)
          end
        else
          404
        end
      end
    end

    post %r{^/(programs|playlists)/(\w+)/media/((\d*)/)?(create|export)$} do
      list, id, bps, _, command = params[:captures]
      playlist = playlist_root(list).find(id)
      tl = Utils::TrackList.new(playlist)
      Config::with_config(playlist.config) do
        tl.prepare_media(bps: bps, command: command, name: playlist.name)
      end
      { ok: true }.to_json
    end

    get %r{^/(programs|playlists)/(\w+)/tracks$} do
      list, id = params[:captures]
      playlist = playlist_root(list).find(id)
      if playlist
        playlist.refresh_if_needed!(force: params[:refresh]) 
        tl = Utils::TrackList.new(playlist)
        tl.to_json_array.to_json
      else
        404
      end
    end

    get %r{^/(programs|playlists)/(\w+)/tracks/(\w+)$} do
      with_location = params[:with_location]
      track = find_track_in_playlist(params)
      if track
        track.to_json_hash(with_location: with_location).to_json
      else
        404
      end
    end

    route 'PATCH', %r{^/(programs|playlists)/(\w+)/tracks/(\w+)$} do
      track = find_track_in_playlist(params)
      unless track
        list, list_id, track_id = params[:captures]
        track = ITunes::Track::find(nil, track_id)
      end
      if track
        body = JSON.parse(request.body.read)
        p body
        track.update(body)
        track.to_json_hash.to_json
      else
        404
      end
    end

    get %r{^/(programs|playlists)/(\w+)/tracks/(\w+)/media(/\d+)?(/?(\d+)-(\d*))?(.mp3)?$} do
      list, playlist_id, track_id, bps, _, start, pause = params[:captures]
      bps = bps[1..-1].to_i if bps and bps[0] == '/'
      p request.path, params[:captures]
      playlist = playlist_root(list).find(playlist_id)
      track = find_track_in_playlist(params)

      if params[:prepareNext].to_i > 0
        tl = Utils::TrackList.new(playlist)
        tl.prepare_next_of(bps, track)
      end

      if track and track.location
        options = { bps: bps, start: start, pause: pause }
        location = track.location
        Config::with_config(playlist.config) do
          if track.media_file_path(options) != location
            if track.prepare_media(options)
              location = track.media_file_path(options)
            end
          end
        end
        if params[:sync].to_i > 0
          track.update_bookmark_and_playedDate
        end
        case location
        when /mp3$/ 
          content_type('audio/mpeg')
        when /m4.$/
          content_type('audio/mp4')
        else # unkonwn type
          content_type('audio/mpeg')
        end
        if request.request_method == 'GET'
          x_send_file(location)
        else
          200
        end
      else
        404
      end
    end

    get %r{^/search/(.+)/tracks$} do
      q = URI.unescape($1).force_encoding("UTF-8")
      tracks = SevenMinutes::ITunes::search(q)
      search_result = Struct.new(:tracks).new(tracks)
      tl = Utils::TrackList.new(search_result)
      tl.to_json_array.to_json
    end

    get '/status' do
      content_type 'text/json'
      queues = ITunes::QueuePlaylist.all
      {
        status: 'ok',
        version: SevenMinutes::VERSION,
        queues: queues.map {|pl| pl.to_json_hash},
        has_sox: ITunes::conf[:has_sox]
      }.to_json
    end

    post %r{^/queue/(.+)/tracks/(.+)$} do
      list, track = params[:captures]
      p list, track
      playlist = ITunes::QueuePlaylist.find_by_name(list)
      if playlist
        playlist.add(track)
        { ok: true}.to_json
      else
        404
      end
    end

    def find_track_in_playlist(params)
      list, list_id, track_id = params[:captures]
      playlist = playlist_root(list).find(list_id)
      if playlist
        # logger = playlist.config[:logger]
        # logger.debug "tracks #{playlist.name} #{playlist.tracks.map(&:name).inspect}" if logger
        playlist.tracks.find do |t|
          t.validate_handle and track_id == t.persistentID
        end
      else
        nil
      end
    end

    def playlist_root(path)
      root = SevenMinutes::App::get_playlist_root(path)
      return root if root
      case path 
      when 'programs'
        Program
      when 'playlists'
        ITunes::Playlist
      else
        halt 404
      end
    end
  end
end
