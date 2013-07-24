
# invoke by $ macruby -rubygems -Ispec spec/utils_spec.rb

require 'stringio'
require 'logger'
require 'hashie'
require "spec_helper"
require 'config'
require 'minitest/mock'

describe Hash do
  describe "symbolize_keys_recursive" do
    it 'should symbolize_keys' do
      h = { 'aaa' => 1, 'bbb' => 2}
      h.symbolize_keys_recursive!
      h[:aaa].must_equal 1
      h[:bbb].must_equal 2
    end
    it 'should symbolize_keys recursive' do
      h = { 'aaa' => 1, 'bbb' => { 'ccc' => 2} }
      h.symbolize_keys_recursive!
      h[:bbb][:ccc].must_equal 2
    end
  end
end

describe Utils::ArrayExt do
  describe 'prev_me_next' do
    it 'should do nothing on empty array' do
      a = []
      a.extend Utils::ArrayExt
      a.prev_me_next do |_prev, me ,_next|
        [_prev, me ,_next]
      end.must_equal []
    end
    it 'should pass nil for prev and next on one element array'  do
      a = [1]
      a.extend Utils::ArrayExt
      a.prev_me_next do |_prev, me ,_next|
        [_prev, me ,_next]
      end.must_equal [
        [nil, 1, nil]
      ]
    end
    it 'should pass prev and next on two element array'  do
      a = [0, 1]
      a.extend Utils::ArrayExt
      a.prev_me_next do |_prev, me ,_next|
        [_prev, me ,_next]
      end.must_equal [
        [nil, 0, 1],
        [0, 1, nil]
      ]
    end
    it 'should pass prev and next on  array'  do
      a = (0..5).map { |v| { value: v } }
      a.extend Utils::ArrayExt
      a.prev_me_next do |_prev, me ,_next|
        me.merge!(prev: _prev[:value]) if _prev
        me.merge!(next: _next[:value]) if _next
        me
      end.must_equal [
        {:value=>0, :next=>1},
        {:value=>1, :prev=>0, :next=>2},
        {:value=>2, :prev=>1, :next=>3},
        {:value=>3, :prev=>2, :next=>4},
        {:value=>4, :prev=>3, :next=>5},
        {:value=>5, :prev=>4}
      ]
    end
  end
end

describe SevenMinutes::Config do
  describe 'with_config' do
    it 'should set config to Thread::current' do
      SevenMinutes::Config::with_config(aaa: 1) do
        SevenMinutes::Config::current[:aaa].must_equal 1
      end
    end
    it 'should merge current and restore it' do
      SevenMinutes::Config::with_config(aaa: 1, bbb: 2) do
        SevenMinutes::Config::current[:aaa].must_equal 1
        SevenMinutes::Config::current[:bbb].must_equal 2
        SevenMinutes::Config::with_config(aaa: 3) do
          SevenMinutes::Config::current[:aaa].must_equal 3
          SevenMinutes::Config::current[:bbb].must_equal 2
        end
        SevenMinutes::Config::current[:aaa].must_equal 1
        SevenMinutes::Config::current[:bbb].must_equal 2
      end
    end

    it 'should set logger and shell' do
      SevenMinutes::Config::with_config(aaa: 1) do
        config = SevenMinutes::Config::current
        config[:logger].wont_be_nil
        config[:shell].wont_be_nil
      end
    end
  end
end

describe SevenMinutes::Utils::Shell do
  before do
    @sio = StringIO.new("", 'r+')
    @logger = Logger.new(@sio)
    @logger.level = Logger::DEBUG
  end

  it 'should exec cmd and log the output' do
    SevenMinutes::Config::with_config(logger: @logger, shell: nil)  do
      shell = SevenMinutes::Config::current.shell 
      ret = shell.exec('ls')
      ret.must_equal true
      @sio.rewind
      log = @sio.read
      log.must_match /^D.*ls$/
      log.must_match /Rakefile/
      log.must_match /utils.rb/
    end
  end

  it 'should return false on exec error' do
    SevenMinutes::Config::with_config(logger: @logger, shell: nil)  do
      shell = SevenMinutes::Config::current.shell 
      ret = shell.exec('ls /non_existing_dir')
      ret.must_equal false
      @sio.rewind
      log = @sio.read
      # puts log
      # W, [2013-06-08T16:34:12.991407 #13338]  WARN -- : command 'ls /non_existing_dir...' failed!
      # W, [2013-06-08T16:34:12.991995 #13338]  WARN -- : ls: /non_existing_dir: No such file or directory
      log.must_match /^W/
      log.must_match /No such file or directory/
    end
  end
end

describe Utils::Sox do
  it 'should create sox command' do
    sox = Utils::Sox.new('in', 'out')
    sox.command.must_equal('sox --buffer 1024000 in -c 2 out')
  end

  it 'should accept many input files' do
    sox = Utils::Sox.new(%w(in1 in2 in3), 'out')
    sox.command.must_equal('sox --buffer 1024000 in1 -c 2 in2 -c 2 in3 -c 2 out')
  end
  it 'should use conf' do
    SevenMinutes::Config::with_config(sox_bin: '/opt/bin/sox')  do
      sox = Utils::Sox.new('in', 'out')
      sox.command.must_equal('/opt/bin/sox --buffer 1024000 in -c 2 out')
    end
  end
  it 'should use global opt' do
    SevenMinutes::Config::with_config(sox_opt: '-b 2000')  do
      sox = Utils::Sox.new('in', 'out')
      sox.command.must_equal('sox -b 2000 in -c 2 out')
    end
  end

  it 'should use bps opt' do
    sox = Utils::Sox.new('in', 'out', bps: 128)
    sox.command.must_equal('sox --buffer 1024000 in -c 2 -r 48000 out')
  end
  it 'should use trim opt' do
    SevenMinutes::Config::with_config(sox_fadetime: 2)  do
      sox = Utils::Sox.new('in', 'out', start: 10)
      sox.command.must_equal('sox --buffer 1024000 in -c 2 out trim 8 fade 2')
      sox = Utils::Sox.new('in', 'out', pause: 25)
      sox.command.must_equal('sox --buffer 1024000 in -c 2 out fade 0 25 2')
      sox = Utils::Sox.new('in', 'out', start: 10, pause: 25)
      sox.command.must_equal('sox --buffer 1024000 in -c 2 out trim 8 fade 2 19')
    end
  end
end

describe SevenMinutes::Utils::Refresher do
  Refresher = SevenMinutes::Utils::Refresher
  before do
    @pl = Object.new 
    @pl.instance_eval do
      class << self 
        attr_reader :tracks
        def get_new_tracks
          [
            { persistentID: '0001', duration: 60.0 },
            { persistentID: '0002', duration: 60.0 },
            { persistentID: '0001', duration: 60.0 },
          ].map do |t|
            MockTrack.new t
          end
        end
      end
      @tracks = []
    end
    @pl.extend Refresher
  end

  it 'should refresh when @tracks is empty' do
    @pl.refresh_if_needed!
    @pl.tracks.size.must_equal 3
  end
  it 'should record refreshed_at and timestamp' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.refreshed_at.must_equal now
    @pl.timestamp.must_equal now.to_i
  end

  it 'should not refresh when fresh' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.refresh_if_needed!(now: now + 1)
    @pl.refreshed_at.must_equal now
  end

  it 'should refresh when forced' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.refresh_if_needed!(now: now + 1, force: true)
    @pl.refreshed_at.must_equal now + 1
  end

  it 'should refresh when it dose not have enough tracks' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.refresh_if_needed!(now: now + 1, minimum_tracks: 2)
    @pl.refreshed_at.must_equal now 
    @pl.refresh_if_needed!(now: now + 1, minimum_tracks: 4)
    @pl.refreshed_at.must_equal now + 1
  end

  it 'should refresh when it dose not have enough active tracks' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.tracks[0].played = true
    @pl.refresh_if_needed!(now: now + 1, minimum_tracks: 2)
    @pl.refreshed_at.must_equal now + 1
  end

  it 'should refresh when it dose not have enough duration' do
    now = Time.now
    @pl.refresh_if_needed!(now: now)
    @pl.refresh_if_needed!(now: now + 1, minimum_duration: 170)
    @pl.refreshed_at.must_equal now 
    @pl.tracks[0].played = true
    @pl.refresh_if_needed!(now: now + 2, minimum_duration: 170)
    @pl.refreshed_at.must_equal now + 2
  end

  it 'should avoid duplicate id' do
    @pl.refresh_if_needed!
    @pl.tracks.map(&:persistentID).must_equal %w(0001 0002 0001_2)
  end
end

describe SevenMinutes::Utils::Playable do
  Playable = SevenMinutes::Utils::Playable
  describe 'duration_left' do
    before do
      @track = Hashie::Mash.new(duration: 100)
      @track.extend Playable
    end
    it 'should be duration' do
      @track.duration_left.must_equal 100
    end
    it 'should consider bookmark' do
      @track.bookmark = 10
      @track.duration_left.must_equal 90
    end
    it 'should consider pause_at' do
      @track.pause_at = 80
      @track.duration_left.must_equal 80
      @track.bookmark = 10
      @track.duration_left.must_equal 70
    end
  end
  describe 'playable?' do
    before do
      # For production code, location should be path of mp3 file
      # For test location, set location to be path of any existing file
      # So set it to this source file
      @track = Hashie::Mash.new(location: Test::fixtures.first)
      @track.extend Playable
    end
    it 'should be playable when track has location and the file exists' do
      @track.playable?.must_equal true
    end
    it 'should not be playable when location is null' do
      @track.location = nil
      @track.playable?.must_equal false
    end
    it 'should not be playable when location is not exists' do
      @track.location =  'non existing file'
      @track.playable?.wont_equal true
    end
  end

  describe 'media_file_path' do
    before do
      @track = Hashie::Mash.new(persistentID: '0001', location: Test::fixtures.first)
      @track.extend Playable
      Thread::current[:seven_minutes_conf] = {
        media_temp: '/tmp/7m/media_temp'
      }
    end

    it 'should be location' do
      @track.media_file_path.must_equal @track.location
    end
    it 'should be temp file when bps is specified' do
      @track.media_file_path(bps: 128).must_equal "/tmp/7m/media_temp/128/0/0001.mp3"
    end
    it 'should be temp file when start position is specified' do
      @track.media_file_path(start: 100).must_equal "/tmp/7m/media_temp/0/0/0001_from_100.mp3"
    end
    it 'should be temp file when pause position is specified' do
      @track.media_file_path(pause: 100).must_equal "/tmp/7m/media_temp/0/0/0001_to_100.mp3"
    end
    it 'should be temp file when every option is specified' do
      @track.media_file_path(bps:256, start: 50, pause: 100).must_equal "/tmp/7m/media_temp/256/0/0001_from_50_to_100.mp3"
    end
  end

  describe 'prepare_media' do
    before do
      @track = Hashie::Mash.new(persistentID: '0001', location: __FILE__)
      @track.extend Playable
      @shell = MockShell.new
    end
    it 'should do nothing when original media can be used'do
      SevenMinutes::Config::with_config(
        shell: @shell,
        media_temp: '/tmp/7m/media_temp'
      ) do
        @track.prepare_media
        @shell.commands.must_equal []
      end
    end
    it 'should convert media file when bps is specified'do
      SevenMinutes::Config::with_config(
        shell: @shell,
        media_temp: '/tmp/7m/media_temp'
      ) do
        @track.prepare_media(bps: 96)
        @shell.commands.must_equal [
          "sox --buffer 1024000 #{__FILE__} -c 2 -r 32000 /tmp/7m/media_temp/96/0/0001.mp3"
        ]
      end
    end
    it 'should convert m4a'do
      SevenMinutes::Config::with_config(
        shell: @shell,
        media_temp: '/tmp/7m/media_temp'
      ) do
        @track.location = 'a.m4a'
        @track.prepare_media(bps: 96)

        @shell.commands.first.must_match %r[^ffmpeg(.*)a.m4a]
        @shell.commands.last.must_match %r[sox --buffer 1024000(.*)-c 2 -r 32000 /tmp/7m/media_temp/96/0/0001.mp3]
      end
    end
  end

  describe 'update_bookmark_and_playedDate' do
    before do
      @track = Hashie::Mash.new(persistentID: '0001', location: __FILE__, playedCount: 1)
      @track.mock = MiniTest::Mock.new
      @track.extend Playable
      def @track.update(h)
        mock.update(h)
      end
      @shell = MockShell.new
    end
    it 'should update playedDate and playedCount' do
      now = DateTime.now
      @track.mock.expect :update, true, [{ 'playedDate' => now.to_s, 'playedCount' => 2, 'played' => 1}]
      @track.update_bookmark_and_playedDate(now)
      @track.mock.verify
      @track.playable?.must_be :!=, true
    end
    it 'should update bookmark when pause_at was specified' do
      @track.pause_at = 10
      @track.mock.expect :update, true, [{ 'bookmark' => 10, 'bookmarkable' => true, 'played' => 1}]
      @track.update_bookmark_and_playedDate
      @track.mock.verify
      @track.playable?.must_be :!=, true
    end
  end
end

describe SevenMinutes::Utils::TrackList do
  TrackList = SevenMinutes::Utils::TrackList
  Playable = SevenMinutes::Utils::Playable
  before do
    @list = Hashie::Mash.new(id: '1001', name: 'list')
    @tracks = [
      Hashie::Mash.new(persistentID: '0001', name: 'aaaa', location: Test::fixtures[0], duration: 10),
      Hashie::Mash.new(persistentID: '0002', name: 'bbbb', location: Test::fixtures[1], duration: 20),
      Hashie::Mash.new(persistentID: '0003', name: 'cccc', location: Test::fixtures[2], duration: 30),
    ]
    
    @tracks.each do |t| 
      t.extend Playable 
      t.parent =  @list
    end
    @list.tracks = []
    @tracks.each {|t| @list.tracks << t}
    @tl = TrackList.new(@list)
  end

  it 'should make json_array' do
    @list.tracks.each do |t|
      def t.to_json_hash 
        to_hash.symbolize_keys_recursive
      end
      def t.validate_handle
        true
      end
    end
    @tl = TrackList.new(@list)
    a = @tl.to_json_array
    a.must_be :kind_of?, Array
    a.first.must_be :kind_of?, Hash
  end

  it 'should make m3u8 playlist ' do
    @tracks[0].album = 'album_aaa'
    @tracks[0].bookmark = 10 # this will be ignored because it's after program creation
    @tracks[0].pause_at = 20
    @tracks[1].album = 'artist_bbb'
    @list.tracks = []
    @tracks.each {|t| @list.tracks << t }

    tl = TrackList.new(@list)
    tl.to_m3u8(type: 'programs', id: 123, bps: 128).must_equal <<END
#EXTM3U
#EXTINF:10, album_aaa - aaaa(-20)
/programs/123/tracks/0001/media/128/0-20.mp3?sync=1&prepareNext=1
#EXTINF:20, artist_bbb - bbbb
/programs/123/tracks/0002/media/128.mp3?sync=1&prepareNext=1
#EXTINF:30, cccc
/programs/123/tracks/0003/media/128.mp3?sync=1&prepareNext=1
END
  end

  it 'should exclude played track for m3u8 playlist ' do
    @list.tracks[0].played = true
    tl = TrackList.new(@list)
    tl.to_m3u8(type: 'programs', id: 123, bps: 128).must_equal <<END
#EXTM3U
#EXTINF:20, bbbb
/programs/123/tracks/0002/media/128.mp3?sync=1&prepareNext=1
#EXTINF:30, cccc
/programs/123/tracks/0003/media/128.mp3?sync=1&prepareNext=1
END
  end
  it 'should make pls ' do
    @tl.to_pls({}).must_equal <<END
[playlist]
File1=/tracks/0001/media/0.mp3?sync=1&prepareNext=1
Title1= - aaaa(-)
Length1=10
File2=/tracks/0002/media/0.mp3?sync=1&prepareNext=1
Title2= - bbbb(-)
Length2=20
File3=/tracks/0003/media/0.mp3?sync=1&prepareNext=1
Title3= - cccc(-)
Length3=30
NumberOfEntries=3
Version=2
END
  end

  it 'should do nothing when original media can be used'do
    shell = MockShell.new
    SevenMinutes::Config::with_config(
      shell: shell,
      media_temp: '/tmp/7m/media_temp'
    ) do
      @tl.prepare_media
      shell.commands.size.must_equal 1
      shell.commands.last.must_match %r[^sox(.*)/tmp/7m/media_temp/list/0/1/1001.mp3]
    end
  end
  it 'should prepare media with sox'do
    shell = MockShell.new
    SevenMinutes::Config::with_config(
      shell: shell,
      media_temp: '/tmp/7m/media_temp'
    ) do
      @tl.prepare_media(bps: 128)
      shell.commands.size.must_equal 4
      shell.commands.first.must_match %r[^sox(.*)/tmp/7m/media_temp/128/0/0001.mp3]
      shell.commands.last.must_match %r[^sox(.*)/tmp/7m/media_temp/list/128/1/1001.mp3]
    end
  end
end

describe MockShell do
  before do
    @track = Hashie::Mash.new(location: __FILE__)
    @track.extend Playable
    @shell = MockShell.new
    Thread::current[:seven_minutes_conf] = {
      shell: @shell
    }
  end

  it 'should be capable of executing shell command' do
    @track.exec("ls -l")
    @shell.commands.first.must_equal "ls -l"
  end

end

