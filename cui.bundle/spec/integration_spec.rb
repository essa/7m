#
# this test should be invoked by ruby 2.0.X not macruby
#

require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'


require "minitest/spec"
require "hashie"

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
      p @pid
      at_exit { Process.kill :INT, @pid}
    end
    def self.stop_server
      Process.kill :INT, @pid if @pid
    end
  end
end
include SevenMinutes

describe "SevenMinutes integration test" do
  include Capybara::DSL
  before do
    Capybara.javascript_driver = :poltergeist
    Capybara.default_driver = :poltergeist
    Capybara.app_host = 'http://localhost:16017'
    Test::stop_server
    sleep 1
    Test::start_server
    sleep 5
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
end
 
 
