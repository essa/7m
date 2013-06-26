
require 'rack/test'
require 'yaml'

require "spec_helper"
require 'itunes'
require 'radio_program'

$CONF = 'tt_test.yml'
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
      source: #{Test::PlaylistName}
      max_track: 2
      duration: 10
      max_duration_per_track: 300
END
  conf.merge!(base_dir: base_dir)
  conf.symbolize_keys_recursive!
  ITunes::init_app(conf)
  RadioProgram::Program::init(conf, ITunes)
end
require 'webapp'

describe "Server Test with racktest with real iTunes" do
  include Rack::Test::Methods

  def app
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    SevenMinutes::App.new(logger)
  end

  SevenMinutes::Test::setup_playlist_for_test

  before(:each) do
    SevenMinutes::RadioProgram::Program::init_manager
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
  describe 'get "/programs/:id/tracks"' do
    def pl
      ITunes::Playlist::find_by_name(Test::PlaylistName)
    end

    it "should be success" do
      get "/programs/1/tracks"
      last_response.status.must_equal 200
    end

    it "should return playlist" do
      get "/programs/1/tracks"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      # j.size.must_equal Test::pl.tracks.size + 1
      t = j.first
      expected = Test::pl.tracks.first
      t['id'].must_equal expected.persistentID 
      t['name'].must_equal expected.name 
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
      pl = j.find {|l| l['name'] == Test::PlaylistName }
      pl['name'].must_equal Test::PlaylistName 
      pl.has_key?('id').must_equal true
      pl.has_key?('path').must_equal true
    end
  end

  describe 'get "/playlists/:id"' do
    def pl
      ITunes::Playlist::find_by_name(Test::PlaylistName)
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
      ITunes::Playlist::find_by_name(Test::PlaylistName)
    end

    it "should be success" do
      get "/playlists/#{pl.persistentID}/tracks"
      last_response.status.must_equal 200
    end

    it "should return playlist" do
      get "/playlists/#{pl.persistentID}/tracks"
      j = JSON.parse(last_response.body)
      j.must_be_kind_of(Array)
      j.size.must_equal Test::pl.tracks.size
      t = j.first
      expected = Test::pl.tracks.first
      t['id'].must_equal expected.persistentID 
      t['name'].must_equal expected.name 
      t['parent_path'].must_equal "playlists/#{pl.persistentID}"
    end
  end

  describe 'get "/playlists/:playlist_id/tracks/:track_id"' do
    def pl
      ITunes::Playlist::find_by_name(Test::PlaylistName)
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
      expected = Test::pl.tracks.first
      j['id'].must_equal expected.persistentID 
      j['name'].must_equal expected.name 
      j['location'].must_be_nil
    end

  end

  # describe 'get "/tracks/:track_id/media"' do
    # def pl
      # ITunes::Playlist::find_by_name(Test::PlaylistName)
    # end

    # def t
      # pl.tracks.first
    # end

    # it "should be success" do
      # get "/tracks/#{t.persistentID}/media"
      # last_response.status.must_equal 200
    # end

    # it "should return media file by x-sendfile feature of web server" do
      # get "/tracks/#{t.persistentID}/media"
      # last_response.headers["X-Sendfile"].must_equal t.location
    # end
  # end
end


