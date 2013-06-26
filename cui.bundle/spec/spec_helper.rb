
require "minitest/spec"
require "hashie"

require 'utils'

module SevenMinutes
  module Test
    PlaylistName = '7mtest'
    @@pl = nil

    def self.pl
      @@pl
    end

    def self.setup_playlist_for_test
      return if @@pl
      name = PlaylistName
      dir = File::dirname(__FILE__)
      fixtures = Dir["#{dir}/fixtures/*.mp3"]

      load_bridge_support_file File::join(File::dirname(__FILE__),  '..', 'ITunes.bridgesupport')
      itunes = SBApplication.applicationWithBundleIdentifier("com.apple.itunes")
      library = itunes.sources.find { |s| s.kind == ITunesESrcLibrary }
      music_pl = library.libraryPlaylists.find { |l|  l.specialKind == ITunesESpKLibrary }
      raise 'music not found' unless music_pl

      @@pl = pl = library.playlists.find { |l| l.name == name }
      return if pl and pl.tracks.size == fixtures.size

      if pl
        pl.tracks.each do |t|
          t = music_pl.fileTracks.objectWithName(t.name)
          loc = t.location
          t.delete
          NSFileManager.defaultManager.trashItemAtURL loc, resultingItemURL:nil, error:nil
        end
        pl.delete
      end

      userPlaylists = library.userPlaylists
      userPlaylists << ITunesUserPlaylist.alloc.initWithProperties(name: name) 
      pl = userPlaylists.objectWithName(name)
      itunes.add fixtures.map{ |f| NSURL.fileURLWithPath(f) }, to: pl
      @@pl = pl
    end

    def self.name_to_location(name)
      itunes = SBApplication.applicationWithBundleIdentifier("com.apple.itunes")
      library = itunes.sources.find { |s| s.kind == ITunesESrcLibrary }
      music_pl = library.libraryPlaylists.find { |l|  l.specialKind == ITunesESpKLibrary }
      t = music_pl.fileTracks.objectWithName(name)
      t.location.path
    end

    def self.fixtures
      Dir[File::join(File::dirname(__FILE__), 'fixtures', '*.mp3')]
    end
  end
end

include SevenMinutes

MiniTest::Unit.autorun

class MockShell
  attr_reader :commands
  def initialize
    @commands = []
  end

  def exec(cmd)
    @commands << cmd
    true
  end

  def with_lock(path, &block)
    block.call
  end
end

class MockTrack < Hashie::Mash
  include SevenMinutes::Utils::Playable

  def initialize(h)
    # location should be any existing file
    super(h.merge(location: Test::fixtures.first))
  end

  def to_json_hash(options={})
    self.to_hash.symbolize_keys_recursive.merge(id: self.persistentID)
  end

  def active?(t=Time.now)
    return false if playedDate and playedDate >= t - 24*60*60
    return true if location and File::exists? location
    return false
  end

  def inspect
    'MockTrack ' + to_hash.inspect
  end
end
