
# invoke by $ macruby -rubygems -Ispec spec/program_spec.rb

require 'date'
require 'hashie'
require "spec_helper"
require "radio_program"


describe "RadioProgram" do
  describe "Item" do
    before do
      @track = MockTrack.new(
        persistentID: '456',
        name: 'aaa',
        duration: 100
      )
      @item = RadioProgram::Item.new(@track)
      @item.parent = Hashie::Mash.new(id: '123')
    end

    describe 'attributes' do
      it 'should have persistentID' do
        @item.persistentID = 'aaaa'
        @item.persistentID.must_equal 'aaaa'
      end
      it 'should have pause_at' do
        t = Time.now
        @item.pause_at = t
        @item.pause_at.must_equal t
      end
      it 'should have played' do
        @item.played.must_equal false
        @item.played = true
        @item.played.must_equal true
      end
      it 'should have to_json_hash' do
        t = Time.now
        @item.pause_at = t
        h = @item.to_json_hash
        h[:pause_at].must_equal t
      end
      it 'should have to_json_hash with links' do
        h = @item.to_json_hash
        h[:path].must_equal "programs/123/tracks/456" 
      end

    end
    describe 'duration_left' do
      it 'should be duration without bookmark and pause_at' do
        @item.duration_left.must_equal 100
      end
      it 'should consider bookmark' do
        @track.bookmark = 10
        @item.duration_left.must_equal 90
      end
      it 'should consider pause_at' do
        @track.bookmark = 10
        @item.pause_at = 40
        @item.duration_left.must_equal 30
      end

      it 'should not be playable when localtion is nil' do
        @item.playable?.must_equal true
        @track.location = nil
        (not @item.playable?).must_equal true
      end
    end

    describe 'original_bookmark' do
      it 'should remenber bookmark when item was created' do
        item = RadioProgram::Item.new(@track)
        item.original_bookmark.must_equal nil
        @track.bookmark = 123
        item2 = RadioProgram::Item.new(@track)
        item2.original_bookmark.must_equal(123)
        @track.bookmark = 456
        item.original_bookmark.must_equal nil
        item2.original_bookmark.must_equal(123)
      end
    end

    describe 'context' do
      it 'should save pause_at as bookmark to context' do
        context = RadioProgram::Context.new
        @item.pause_at = 33
        @item.save_to(context)
        item = RadioProgram::Item.new(@track)
        item.bookmark.must_equal nil
        item.load_from(context)
        item.bookmark.must_equal 33
      end
      it 'should save played_at to context' do
        d = Time.now
        context = RadioProgram::Context.new
        @item.played_recently?(d).must_equal false
        @item.virtual_played_at = d
        @item.played_recently?(d).must_equal true
        @item.save_to(context)
        item = RadioProgram::Item.new(@track)
        item.played_recently?(d).must_equal false
        item.load_from(context)
        item.played_recently?(d).must_equal true
      end
      it 'should not update track' do
        @track.bookmark = 11
        context = RadioProgram::Context.new
        @item.pause_at = 33
        @item.save_to(context)
        item = RadioProgram::Item.new(@track)
        item.bookmark.must_equal 11
        item.load_from(context)
        item.bookmark.must_equal 33
        @track.bookmark.must_equal 11
      end
    end

  end

  describe 'Context' do
    before do
      @time = Time.now
      @context = RadioProgram::Context.new(@time)
    end

    it 'should clear old items' do
      @context[:items][:aaa][:bbb] = 1
      @context.save_to('/tmp/7mcontexttest.yml')

      context = RadioProgram::Context.new(@time)
      context.load_from('/tmp/7mcontexttest.yml')
      context[:items][:aaa][:bbb].must_equal 1

      context = RadioProgram::Context.new(@time + 24*60*60)
      context.load_from('/tmp/7mcontexttest.yml')
      context[:items][:aaa][:bbb].must_equal nil
    end
  end

  describe "frame param" do
    before do
      logger = Logger.new(STDOUT)
      logger.level = Logger::FATAL
      @config = {
        name: 'program1',
        refresh_interval: 3600,
        logger: logger,
        frames: [
          { name: 'music', source: 'source1', max_track: 3 },
          { name: 'podcast', source: 'source2', max_track: 1 }
        ]
      }
      @manager = RadioProgram::SourceManager.new(
        name: 'aaa'
      )
      @tracks1 = [
        { persistentID: '0001', duration: 60.0 },
        { persistentID: '0002', duration: 60.0 },
        { persistentID: '0003', duration: 60.0 },
      ].map do |t|
        MockTrack.new t
      end
      @tracks2 = [
        { persistentID: '1001', duration: 60.0 },
      ].map do |t|
        MockTrack.new t
      end
    end

    it 'should include all tracks' do
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, @manager
      program.refresh!
      program.tracks.size.must_equal 4
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 0003 1001)
    end

    it 'should include max tracks' do
      frame_config = @config[:frames][0]
      frame_config[:max_track] = 2
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0003 0001 1001)
    end

    it 'should include min duration' do
      frame_config = @config[:frames][0]
      frame_config[:duration] = '120-180'
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0003 0001 1001)
    end

    it 'should set pause_at for max duration' do
      frame_config = @config[:frames][0]
      frame_config[:duration] = '80-90'
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)
      program.tracks[1].pause_at.must_equal 30.0

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0003 0001 1001)
      program.tracks[1].pause_at.must_equal 30.0
    end

    it 'should calc duration from bookmark' do
      frame_config = @config[:frames][0]
      frame_config[:duration] = '80-90'
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      @tracks1[0].bookmark = 10.0
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)
      program.tracks[1].pause_at.must_equal 40.0
    end

    it 'should set pause_at for max_duration_per_track' do
      frame_config = @config[:frames][0]
      frame_config[:duration] = '50-60'
      frame_config[:max_duration_per_track] = 30
      @config[:frames][1][:max_duration_per_track] = 20
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      @tracks1[0].bookmark = 10.0
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)
      pause = program.tracks.map { |t| t.pause_at }
      pause.must_equal [40, 30, 20]
      bookmarks = program.tracks.map { |t| t.bookmark }
      bookmarks.must_equal [10, nil, nil]

      tracks = program.tracks.map do |t|
        {
          id: t.persistentID,
          pause_at: t.pause_at,
          bookmark: t.bookmark,
        }
      end
      tracks.must_equal [
        {:id=>"0001", :pause_at=>40.0, :bookmark=>10.0}, 
        {:id=>"0002", :pause_at=>30.0, :bookmark=>nil},
        {:id=>"1001", :pause_at=>20.0, :bookmark=>nil}
      ] 
    end

    it 'should set pause_at for max_duration_per_track with bookmark' do
      frame_config = @config[:frames][0]
      frame_config[:duration] = '51-60'
      frame_config[:max_duration_per_track] = 30
      @config[:frames][1][:max_duration_per_track] = 20
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      @tracks1[0].bookmark = 40.0
      @tracks1[1].bookmark = 10.0
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      tracks = program.tracks.map do |t|
        {
          id: t.persistentID,
          pause_at: t.pause_at,
          bookmark: t.bookmark,
          duration: t.duration,
        }
      end
      expected = [
        { id: '0001', bookmark: 40,  pause_at: nil, duration: 60 },
        { id: '0002', bookmark: 10,  pause_at: 40,  duration: 60 },
        { id: '0003', bookmark: nil, pause_at: 10,  duration: 60 },
        { id: '1001', bookmark: nil, pause_at: 20,  duration: 60 },
      ]

      tracks.each_with_index do |t, i|
        t.must_equal expected[i]
      end
    end

    it 'should save and load context ' do
      File::unlink '/tmp/context.json' rescue nil
      @config[:context_file] = '/tmp/context.json'
      manager1 = RadioProgram::SourceManager.new({})
      frame_config = @config[:frames][0]
      frame_config[:max_track] = 2
      manager1.add_source('source1') { @tracks1 } 
      manager1.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, manager1
      File::unlink '/tmp/context.json' rescue nil
      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0001 0002 1001)

      manager2 = RadioProgram::SourceManager.new({})
      manager2.add_source('source1') { @tracks1 } 
      manager2.add_source('source2') { @tracks2 } 
      program = SevenMinutes::RadioProgram::Program.new @config, manager2
      program.refresh!
      program.tracks.size.must_equal 3
      ids = program.tracks.map { |t| t.persistentID }
      ids.must_equal %w(0003 0001 1001)
    end

    def compare_tracks(tracks, expected)
      tracks.map do |t|
        {
          id: t.persistentID,
          pause_at: t.pause_at,
          bookmark: t.bookmark,
        }
      end.must_equal expected
    end

    it 'should play same tracks again' do
      File::unlink '/tmp/context.json' rescue nil
      @config[:context_file] = '/tmp/context.json'
      frame_config = @config[:frames][0]
      frame_config[:duration] = '10-10'
      frame_config[:max_duration_per_track] = 5
      @config[:frames][1][:max_duration_per_track] = 20
      @manager.add_source('source1') { @tracks1 } 
      @manager.add_source('source2') { @tracks2 } 
      @tracks1[0].bookmark = nil
      @tracks1[1].bookmark = nil
      program = SevenMinutes::RadioProgram::Program.new @config, @manager

      program.refresh!
      compare_tracks program.tracks, [
        { id: '0001', bookmark: nil, pause_at: 5},
        { id: '0002', bookmark: nil, pause_at: 5},
        { id: '1001', bookmark: nil, pause_at: 20},
      ]
      program.refresh!
      compare_tracks program.tracks, [
        { id: '0003', bookmark: nil, pause_at: 5},
        { id: '0001', bookmark: 5,   pause_at: 10},
        { id: '1001', bookmark: 20, pause_at: 40},
      ]
      program.refresh!
      compare_tracks program.tracks, [
        { id: '0002', bookmark: 5, pause_at: 10},
        { id: '0003', bookmark: 5,   pause_at: 10},
        { id: '1001', bookmark: 40, pause_at: nil},
      ]
    end
  end

  describe "MockTrack" do
    it 'should have same attributes with Track' do
      t = MockTrack.new ( { name: 'aaa'} )
      t.name.must_equal 'aaa'
    end

    it 'should have to_json_hash' do
      t = MockTrack.new ( { name: 'aaa'} )
      h = t.to_json_hash
      h[:name].must_equal 'aaa'
    end

  end

  describe 'SourceManager' do
    before do
      @g = RadioProgram::SourceManager.new(
        name: 'aaa'
      )
    end

    describe 'program source' do
      before do
        @tracks = tracks = [
          { name: 'track a', persistentID: '111' },
          { name: 'track b', persistentID: '222' },
          { name: 'track c', persistentID: '333' },
        ].map do |h|
          MockTrack.new h
        end
        @g.add_source 'source1' do
          tracks
        end
      end

      it 'should get tracks from source' do
        t = @g.peek_next_track('source1')
        t.persistentID.must_equal '111'
      end
      
      it 'should advance cursor' do
        t = @g.peek_next_track('source1')
        t.persistentID.must_equal '111'
        @g.advance_track('source1')
        @g.peek_next_track('source1').persistentID.must_equal '222'
      end

      it 'should recycle tracks' do
        ids = []
        7.times do
          ids << @g.peek_next_track('source1').persistentID
          @g.advance_track('source1')
        end
        ids.must_equal %w(111 222 333 111 222 333 111)
      end

    end

  end

  describe "Program" do
    before do
      logger = Logger.new(STDOUT)
      logger.level = Logger::FATAL
      @config = {
        name: 'program1',
        logger: logger, 
        refresh_interval: 3600,
        frames: [
          { name: 'podcast', source: 'source1' }
        ]
      }
      @g = RadioProgram::SourceManager.new(
        name: 'aaa'
      )
      @tracks = tracks = [
        { name: 'track a', persistentID: '0001' },
      ].map do |h|
        MockTrack.new h
      end
      @g.add_source 'source1' do
        tracks
      end
      @program = SevenMinutes::RadioProgram::Program.new @config, @manager
    end
    describe "initialize" do
      it "should be initialized" do
        @program.must_be_kind_of(SevenMinutes::RadioProgram::Program)
      end
      it 'should have name' do
        @program.name.must_equal 'program1'
      end
      it 'should have refresh interval' do
        @program.refresh_interval.must_equal 3600
      end
      it 'should have 0 tracks' do
        @program.tracks.must_be_kind_of(Array)
        @program.tracks.size.must_equal 0
      end
      it 'should have program frames' do
        @program.frames.must_be_kind_of(Array)
        @program.frames.size.must_equal 1
      end
      it 'should symbolize_keys_recursive of config' do
        program = SevenMinutes::RadioProgram::Program.new ({
          'name' => 'program2',
          'frames' => []
        })

        program.name.must_equal 'program2'
      end
    end

    describe "Frame" do
      it "should be initialized" do
        @frame = @program.frames.first
        @frame.must_be_kind_of(SevenMinutes::RadioProgram::Frame)
        @frame.name.must_equal 'podcast'
      end
    end

    describe "refresh_interval" do
      it 'should be true after initialized' do
        @program.need_refresh?.must_equal true
      end
      it 'should be false after refreshed' do
        t = Time.now
        @program.need_refresh?(t).must_equal true
        @program.record_refresh(t)
        @program.need_refresh?(t).must_equal false
      end
      it 'should be true after refresh_interval from refreshed' do
        t = Time.now
        @program.need_refresh?(t).must_equal true
        @program.record_refresh(t)
        @program.need_refresh?(t).must_equal false
        @program.need_refresh?(t+3599).must_equal false
        @program.need_refresh?(t+3600).must_equal true
      end
    end
    describe "refresh simple" do
      it 'should have tracks' do
        program = SevenMinutes::RadioProgram::Program.new @config, @g
        program.refresh!
        t = program.tracks.first
        t.persistentID.must_equal '0001'
      end
    end
  end
end


