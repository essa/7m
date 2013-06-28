
require 'rack/test'
require 'yaml'

require "spec_helper"
require 'itunes'
require 'radio_program'

ENV['RACK_ENV'] = 'test'
module SevenMinutes
  def self.base_dir
    File::join File::dirname(__FILE__), '..'
  end
  conf = YAML::load <<END
base_dir: .
programs:
  - name: podcasts
    refresh_interval: 60
    frames:
    - name: podcasts
      source: new_podcasts
      max_track: 2
      duration: 10
      max_duration_per_track: 300
    - name: music
      source: favarite_music
      max_track: 3
      duration: 1800
      max_duration_per_track: 300
END

  conf.symbolize_keys_recursive!
  $CONF = conf
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  conf[:logger] = logger
  @shell = conf[:shell] = MockShell.new
  module MockITunes
    module Playlist
      def self.all
        [
          Hashie::Mash.new(persistentID: '001', name: 'favorite music', config: $CONF),
          Hashie::Mash.new(persistentID: '002', name: 'new podcasts', config: $CONF),
        ].map do |pl|
          def pl.to_json_hash(options={})
            self.to_hash.merge(id: self.persistentID)
          end
          def pl.tracks
            [
              MockTrack.new( persistentID: '1111', name: 'aaa', location: 'x'),
              MockTrack.new( persistentID: '1122', name: 'bbb', location: 'x')
            ]
          end
          pl
        end
      end
      def self.find(id)
        all.find { |pl| pl.persistentID == id}
      end
    end
  end
  RadioProgram::Program::init(conf, MockITunes)
end

require 'webapp'
SevenMinutes::App::add_playlist_root('playlists', MockITunes::Playlist)

describe "Server Test with racktest with mock iTunes" do
  include Rack::Test::Methods

  def app
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    SevenMinutes::App.new(logger)
  end

  before(:each) do
    @shell = MockShell.new
    SevenMinutes::RadioProgram::Program::init_manager
    SevenMinutes::RadioProgram::Program::all.each do |prg|
      prg.config[:shell] = @shell
      pl01 = Hashie::Mash.new(persistentID: 'pl01')
      pl02 = Hashie::Mash.new(persistentID: 'pl02')
      prg.manager.add_source 'new_podcasts' do 
        [
          MockTrack.new( persistentID: '1111', name: 'aaa', duration: 600, location: 'x', playlist: pl01),
          MockTrack.new( persistentID: '1122', name: 'bbb', duration: 600, location: 'x', playlist: pl02)
        ]
      end
      prg.manager.add_source 'favarite_music' do 
        [
          MockTrack.new( persistentID: '2211', name: 'xxx', duration: 600, location: 'x', playlist: pl02),
          MockTrack.new( persistentID: '2222', name: 'yyy', duration: 600, location: 'x', playlist: pl01)
        ]
      end
    end
    SevenMinutes::ITunes::cache.clear
  end

  describe 'get "/"' do
    it "should return index page" do
      get '/'
      last_response.status.must_equal 200
    end
  end

  describe 'get "/programs"' do
    it "should be success" do
      get '/programs'
      last_response.status.must_equal 200
    end

    it "should return list of programs" do
      get '/programs'
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      j.first.must_be_kind_of(Hash)
    end

    it "should return the programs for test" do
      get '/programs'
      j = JSON.parse(last_response.body)
      pl = j.find {|l| l['name'] == 'podcasts' }
      pl['id'].must_equal  1
      pl['name'].must_equal 'podcasts'
    end
  end

  describe 'get "/programs/:id"' do
    it "should be success" do
      get '/programs/1'
      last_response.status.must_equal 200
    end

    it "should return list of programs" do
      get '/programs/1'
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['name'].must_equal 'podcasts'
    end
  end

  describe 'get "/programs/:id.m3u8"' do
    it "should be success(m3u8)" do
      get '/programs/1.m3u8'
      last_response.status.must_equal 200
    end

    it "should return list of programs in m3u8 format" do
      get '/programs/1.m3u8'
      m3u8 = last_response.body
      m3u8.must_match /#EXTM3U/
      m3u8.must_match /#EXTINF/
    end
  end

  describe 'get "/programs/:program_id/tracks/:track_id"' do
    it "should be success" do
      get "/programs/1/tracks/1111"
      last_response.status.must_equal 200
    end

    it "should return track" do
      get "/programs/1/tracks/1111"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['id'].must_equal  '1111'
      j['name'].must_equal  'aaa'
      j['pause_at'].must_equal 10
    end

    it "should return paths" do
      get "/programs/1/tracks/1111"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['id'].must_equal  '1111'
      j['access_path'].must_equal  'playlists/pl01/tracks/1111'
      j['media_path'].must_equal  'playlists/pl01/tracks/1111/media'
    end
  end

  describe 'get "/programs/:id/tracks"' do

    it "should be success" do
      get "/programs/1/tracks"
      last_response.status.must_equal 200
    end

    it "should return playlist" do
      get "/programs/1/tracks"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      # j.size.must_equal Test::Tracks.size + 1
      t = j.first
      t['persistentID'].must_equal '1111'
      t['name'].must_equal 'aaa'
    end

    it "should return links" do
      get "/programs/1/tracks"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      # j.size.must_equal Test::Tracks.size + 1
      self_links = j.map { |t| t['path'] }
      self_links.must_equal [
        "programs/1/tracks/1111",
        "programs/1/tracks/2211",
        "programs/1/tracks/2222",
        "programs/1/tracks/2211_2",
      ]

      prev_links = j.map { |t| t['prev_path'] }
      prev_links.must_equal [
        nil,
        "programs/1/tracks/1111",
        "programs/1/tracks/2211",
        "programs/1/tracks/2222",
      ]

      next_links = j.map { |t| t['next_path'] }
      next_links.must_equal [
        "programs/1/tracks/2211",
        "programs/1/tracks/2222",
        "programs/1/tracks/2211_2",
        nil,
      ]
    end
  end

  describe 'post "/programs/:id/refresh"' do
    it "should be success" do
      post "/programs/1/refresh"
      last_response.status.must_equal 200
    end
  end

  describe 'post "/programs/:id/media/create"' do
    it "should be success" do
      post "/programs/1/media/create"
      last_response.status.must_equal 200
    end
    it "should exec sox" do
      post "/programs/1/media/create"
      commands = @shell.commands
      commands.join("\n").must_match %r[^sox (.*) /tmp/7m/list/0/1/1.mp3$]
    end
  end

  describe 'post "/programs/:id/media/128/create"' do
    it "should be success" do
      post "/programs/1/media/128/create"
      last_response.status.must_equal 200
    end
    it "should exec sox" do
      post "/programs/1/media/128/create"
      commands = @shell.commands
      commands.last.must_match %r[^sox(.*)-r 48000(.*)/tmp/7m/list/128/1/1.mp3$]
    end
  end

  describe 'post "/programs/:id/media/128/export"' do
    it "should be success" do
      post "/programs/1/media/128/export"
      last_response.status.must_equal 200
    end

    it "should export list media" do
      post "/programs/1/media/128/export"
      export_dir = File::expand_path('~/Dropbox/7m')
      commands = @shell.commands
      commands.last.must_match %r[^sox(.*)-r 48000(.*)#{export_dir}/podcasts_(\d*)_128.mp3$]
    end
  end

  describe 'get "/programs/:id/media/128"' do
    before do
      system 'mkdir -p /tmp/7m/list/128/1'
      system 'touch /tmp/7m/list/128/1/1.mp3'
    end

    after do
      system 'rm -rf /tmp/7m/list/128/1'
    end
    it "should be success" do
      get "/programs/1/media/128"
      last_response.status.must_equal 200
    end
    it "should return file" do
      get "/programs/1/media/128"
      last_response.headers["X-Sendfile"].must_equal '/tmp/7m/list/128/1/1.mp3'
    end
  end

  describe 'get "/playlists"' do
    it "should be success" do
      get '/playlists'
      last_response.status.must_equal 200
    end
    it "should return list of playlists" do
      get '/playlists'
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      j.first.must_be_kind_of(Hash)
    end

    it "should return the playlists for test" do
      get '/playlists'
      j = JSON.parse(last_response.body)
      pl = j.find {|l| l['name'] == 'favorite music' }
      pl['name'].must_equal 'favorite music'
    end
  end

  describe 'get "/playlists/:id"' do
    def pl
      MockITunes::Playlist::all.first
    end

    it "should be success" do
      get "/playlists/#{pl.persistentID}"
      last_response.status.must_equal 200
    end

    it "should return playlist" do
      get "/playlists/#{pl.persistentID}"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['id'].must_equal(pl.persistentID)
      j['name'].must_equal(pl.name)
    end
  end
  describe 'get "/playlists/:id/tracks"' do
    def pl
      MockITunes::Playlist::all.first
    end

    it "should be success" do
      get "/playlists/#{pl.persistentID}/tracks"
      last_response.status.must_equal 200
    end
    it "should return playlist" do
      get "/playlists/#{pl.persistentID}/tracks"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      j.size.must_equal pl.tracks.size
      t = j.first
      expected = pl.tracks.first
      t['id'].must_equal expected.persistentID 
      t['name'].must_equal expected.name 

    end
  end

  describe 'get "/playlists/:playlist_id/tracks/:track_id"' do
    def pl
      MockITunes::Playlist::all.first
    end

    def t
      pl.tracks.first
    end

    it "should be success" do
      get "/playlists/#{pl.persistentID}/tracks/#{t.persistentID}"
      last_response.status.must_equal 200
    end

    it "should return track" do
      get "/playlists/#{pl.persistentID}/tracks/#{t.persistentID}"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['id'].must_equal '1111'
      j['name'].must_equal 'aaa'
      j['location'].must_equal Test::fixtures.first
    end

    it "should return track with location" do
      get "/playlists/#{pl.persistentID}/tracks/#{t.persistentID}?with_location=1"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Hash)
      j['location'].must_equal Test::fixtures.first
    end
  end

  describe 'get "playlists/:playlist_id/tracks/:track_id/media"' do
    def pl
      MockITunes::Playlist::all.first
    end

    def t
      pl.tracks.first
    end


    it "should be success xxxxx" do
      get "/playlists/#{pl.persistentID}/tracks/#{t.persistentID}/media"
      last_response.status.must_equal 200
    end

    it "should return media file by x-sendfile feature of web server" do
      get "/playlists/#{pl.persistentID}/tracks/#{t.persistentID}/media"
      last_response.headers["X-Sendfile"].must_equal Test::fixtures.first
    end

  end
  describe 'get "programs/:playlist_id/tracks/:track_id/media/:bps"' do
    before do
      system 'mkdir -p /tmp/7m/96/1'
      system 'touch /tmp/7m/96/1/1111.mp3'
    end

    after do
      system 'rm -rf /tmp/7m/96/1'
    end
    it "should be success with bps" do
      get "/programs/1/tracks/1111/media/128"
      last_response.status.must_equal 200
    end

    it "should return media file by x-sendfile feature of web server" do
      get "/programs/1/tracks/1111/media/96"
      last_response.status.must_equal 200
      last_response.headers["X-Sendfile"].must_equal '/tmp/7m/96/1/1111.mp3'
    end

    it "should make media file by sox with start" do
      get "/programs/1/tracks/1111/media/0/1200-"
      last_response.status.must_equal 200
      last_response.headers["X-Sendfile"].must_equal '/tmp/7m/0/1/1111_from_1200.mp3'
      commands = @shell.commands
      commands.last.must_match %r[^sox(.*)/tmp/7m/0/1/1111_from_1200.mp3 trim 1197 fade 3$]
    end

    it "should make media file by sox with start end bps" do
      get "/programs/1/tracks/1111/media/96/100-180"
      last_response.status.must_equal 200
      last_response.headers["X-Sendfile"].must_equal '/tmp/7m/96/1/1111_from_100_to_180.mp3'
      commands = @shell.commands
      commands.last.must_match %r[^sox (.*)-r 32000(.*)/tmp/7m/96/1/1111_from_100_to_180.mp3 trim 97 fade 3 86$]
    end
  end
end


