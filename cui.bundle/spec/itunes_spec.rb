
# invoke by $ macruby -rubygems -Ispec spec/itunes_spec.rb

require "spec_helper"
require "itunes"

describe "ITunes" do
  SevenMinutes::Test::setup_playlist_for_test

  before do
    l = Logger.new(STDOUT)
    l.level = Logger::FATAL
    SevenMinutes::ITunes::init_app(base_dir: ".", logger: l, auto_fix_duplicate_name: false)
  end

  describe "app" do
    it "should be initialized as ITunesApplication" do
      SevenMinutes::ITunes::app.must_be_kind_of(ITunesApplication)
    end
  end

  describe SevenMinutes::ITunes::Playlist do
    describe ".all" do
      it "should return playlists" do
        pl = ITunes::Playlist::all
        pl.must_be_kind_of(Array)
        pl.first.must_be_kind_of(SevenMinutes::ITunes::Playlist)
        pl.map(&:name).must_include(Test::PlaylistName)
      end
    end

    def pl
      SevenMinutes::ITunes::Playlist::find_by_name(Test::PlaylistName)
    end

    describe ".find_by_name" do
      it do
        pl.must_be_kind_of(SevenMinutes::ITunes::Playlist)
        pl.name.must_equal Test::PlaylistName
      end
    end

    describe "#to_json_hash" do
      it 'should return hash' do
        h = pl.to_json_hash
        h[:name].must_equal Test::PlaylistName
        h[:id].wont_be_nil
      end
    end

    describe "#tracks" do
      it "should return tracks" do
        tracks = pl.tracks
        tracks.must_be_kind_of(Array)
      end
    end
  end

  describe "tracks" do
    def pl
      SevenMinutes::ITunes::Playlist::find_by_name(Test::PlaylistName)
    end

    describe ".find" do
      it "should return track" do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        t.must_be_kind_of(ITunes::Track)
      end
      it "should return nil for non existent playlist" do
        ITunes::cache.clear
        t = ITunes::Track.find("abcd", Test::pl.tracks.first.persistentID)
        t.must_be_nil
      end
      it "should return nil for non existent track" do
        t = ITunes::Track.find(pl.persistentID, 'abcd')
        t.must_be_nil
      end
    end

    describe "#to_json_hash" do
      it 'should return hash' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        h = t.to_json_hash
        expected = Test::pl.tracks.first
        h[:location].must_be_nil
        h[:name].must_equal expected.name
        h[:artist].must_equal expected.artist
        h[:album].must_equal expected.album
        h.key?(:bookmark).must_equal true
        h.key?(:bookmarkable).must_equal true
        h.key?(:playedCount).must_equal true
        h.key?(:playedDate).must_equal true
        h.key?(:duration).must_equal true
        h.key?(:bitRate).must_equal true
        h.key?(:rating).must_equal true
        h.key?(:pause_at).must_equal true
      end
      it 'should return hash' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        h = t.to_json_hash(with_location: true)
        expected = Test::pl.tracks.first
        h[:location].must_equal Test::name_to_location(expected.name)
      end
      it 'should return links' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        h = t.to_json_hash(with_location: true)
        expected = Test::pl.tracks.first
        h[:parent_path].must_equal "playlists/#{pl.persistentID}"
        h[:path].must_equal "playlists/#{pl.persistentID}/tracks/#{expected.persistentID}"
        h[:access_path].must_equal "playlists/#{pl.persistentID}/tracks/#{expected.persistentID}"
      end
    end
    describe "#update" do
      it 'should update bookmark' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        t.update 'bookmark' => 12.34
        t.bookmark.must_be_within_epsilon 12.34, 0.01
        t.update 'bookmark' => 23.45
        t.bookmark.must_be_within_epsilon 23.45, 0.01
      end
      it 'should update bookmarkable' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        t.update 'bookmarkable' => true
        t.bookmarkable.must_equal true
        t.update 'bookmarkable' => false
        t.bookmarkable.must_equal true
      end
      it 'should update playedCount' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        t.update 'playedCount' => 5
        t.playedCount.must_equal 5
        t.update 'playedCount' => 0
        t.playedCount.must_equal 0
      end
      it 'should update playedDate' do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        d = DateTime.parse '2013/04/29 10:30:00 +0900'
        t.update 'playedDate' => '2013/04/29 10:30:00 +0900'
        t.playedDate.must_equal d.to_time

        d = DateTime.parse '2013/04/29 11:30:00 +0900'
        t.update 'playedDate' => '2013/04/29 11:30:00 +0900'
        t.playedDate.must_equal d.to_time
      end
    end

    describe "#location" do
      it "should return location of media file" do
        t = ITunes::Track.find(pl.persistentID, Test::pl.tracks.first.persistentID)
        expected = Test::pl.tracks.first
        t.location.must_equal Test::name_to_location(expected.name)
      end
    end
  end
end


