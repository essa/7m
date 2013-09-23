#
# this test should be invoked by ruby 2.0.X not macruby
#

require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'


require "minitest/spec"
require "hashie"
require 'net/http'

MiniTest::Unit.autorun

module SevenMinutes
  module Test
    def start_server_for_macruby
      return if @task and @task.isRunning == 1
      @task = NSTask.launchedTaskWithLaunchPath('/usr/local/bin/macruby', arguments: %w(-rubygems cui_main.rb spec/fixtures/7m_for_test.yml))
      at_exit { @task.terminateTask }
    end

    def self.start_server
      @pid = fork do 
        exec('/usr/local/bin/macruby -rubygems cui_main.rb')
      end
      at_exit { Process.kill :INT, @pid}
      h = Net::HTTP.new('localhost', 16017)
      while true
        begin
          r = h.get2('/status')
          return if r.code == '200'
        rescue Errno::ECONNREFUSED
        end
        sleep 1
      end
    end
    def self.stop_server
      Process.kill :INT, @pid if @pid
    end
  end
end
include SevenMinutes

describe "SevenMinutes webserver test" do
  before do
    Test::stop_server
    sleep 1
    Test::start_server
    @h = Net::HTTP.new('localhost', 16017)
  end

  it "should return status" do
    # r = @h.get2('/musics/05%20Something%20Elated.mp3', 'Range' => 'bytes=0-1')
    r = @h.get2('/status')
    r.code.must_equal '200'
  end

  it 'should accept range request' do
    r = @h.get2('/playlists')
    r.code.must_equal '200'

    pl = JSON.parse(r.body).find {|l| l['name'] == '7mtest'}
    r = @h.get2('/' + pl['path'] + '/tracks')
    r.code.must_equal '200'
    t = JSON.parse(r.body).first
    r = @h.get2('/' + t['path'] + '/media', 'Range' => 'bytes=0-1')
    r.code.must_equal '206'
    r['content-range'].must_match %r[bytes 0-1/(\d+)]
    r['content-range'] =~ %r[bytes 0-1/(\d+)]
    l = $1.to_i
    r.body.size.must_equal 2
    r.body.must_equal 'ID'

    r = @h.get2('/' + t['path'] + '/media', 'Range' => "bytes=0-#{l-1}")
    r.code.must_equal '206'
    r['content-range'].must_equal %[bytes 0-#{l-1}/#{l}]
    r.body.size.must_equal l 
  end
end

describe "SevenMinutes integration test" do
  include Capybara::DSL
  before do
    Capybara.javascript_driver = :poltergeist
    Capybara.default_driver = :poltergeist
    Capybara.app_host = 'http://localhost:16017'
    Test::stop_server
    sleep 1
    Test::start_server
  end

  it "should display config view" do
    visit '/#config'
    sleep 1.0
    page.body.must_match /SevenMinutes/
    page.body.must_match /bps/
  end

  it "should display playlists view" do
    visit '/#config'
    sleep 1.0
    page.body.must_match /SevenMinutes/
    click_link 'config-save'
    page.body.must_match /7mtest/
  end

  it "should display track name" do
    visit '/#config'
    sleep 1.0
    page.body.must_match /SevenMinutes/
    click_link 'config-save'
    page.body.must_match /7mtest/
    click_link '7m_demo'
    sleep 1.0
    page.body.must_match /Deux Arabesques/
  end

  it "should play track with DummyPlayer" do
    setup_dummy_player
    click_link '7m_demo'
    sleep 1.0
    page.body.must_match /Deux Arabesques/
    click_link 'Play!'
    sleep 1.0
    page.body.must_match /Deux Arabesques/
    find(:css, 'div[data-role="header"] h1').text.must_equal 'Playing'
    page.evaluate_script('App.playing.get("status")').must_equal 3 # App.Status.PLAYING
  end

  it "should search and play with queue" do
    setup_dummy_player

    # search tracks
    click_link 'Request Playlist'
    within("#search-ul") do
      click_link 'Search and Request'
    end
    sleep 1.0
    find('#search-word').set('Deux')
    page.execute_script "$('#search-word').trigger('keyup')"
    sleep 3.0
    page.body.must_match /Deux Arabesques/

    # add it to queue
    click_link 'Deux Arabesques: No 1. Andantino con moto'
    sleep 1.0
    click_link 'Request'
    sleep 3.0
    page.evaluate_script('App.playing.get("status")').must_equal 3 # App.Status.PLAYING

    # add another track to queue
    click_link 'Deux Arabesques: No 2. Allegretto scherzando'
    sleep 1.0
    click_link 'Request'

    # reload and check Queue
    visit '/'
    sleep 1.0
    click_link 'Request Playlist'
    within("#search-ul") do
      click_link 'Playing Queue'
    end
    sleep 1.0
    page.body.must_match /Deux Arabesques: No 1. Andantino con moto/
    page.body.must_match /Deux Arabesques: No 2. Allegretto scherzando/
  end

  def setup_dummy_player
    visit '/#config'
    sleep 1.0
    page.body.must_match /SevenMinutes/
    select('On', from: 'Show developer only options:')
    within('#dev-only-area') do
      #choose('PC')
      page.execute_script "$('#interface-pc').attr('checked', true).trigger('create')"
      select('On', from: 'use dummy player:')
    end

    click_link 'config-save'
    page.body.must_match /7mtest/

  end
end
 
 
