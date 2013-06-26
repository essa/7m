# This file is covered by the Ruby license. See COPYING for more details.
# Copyright (C) 2009-2010, Apple Inc. All rights reserved.

framework 'Foundation'
require 'CTParser'
require 'stringio'
require 'control_tower'

CTParser # Making sure the Objective-C class is pre-loaded

module ControlTowerExt
  class RackSocket
    VERSION = [1,0].freeze

    def initialize(host, port, server, concurrent, logger)
      @app = server.app
      @logger = logger
      @socket = TCPServer.new(host, port)
      @socket.listen(50)
      @status = :closed # Start closed and give the server time to start
      @response_handlers = [
        XSendFileResponseHandler,
        EnumResponseHandler,
        RackResponseHandler
      ]
      setup_queue(concurrent)
    end

    def setup_queue(concurrent)
      if concurrent
        @multithread = true
        @request_queue = Dispatch::Queue.concurrent
        @logger.debug "Caution! Wake turbulance from heavy aircraft landing on parallel runway."
        @logger.debug "(Parallel Request Action ENABLED!)"
      else
        @multithread = false
        @request_queue = Dispatch::Queue.new('com.apple.ControlTower.rack_socket_queue')
      end
      @request_group = Dispatch::Group.new
    end

    def open
      @status = :open
      @logger.info "Web Server READY"
      while (@status == :open)
        connection = @socket.accept
        @request_queue.async(@request_group) do
          process_connection(connection)
        end
      end
    rescue Errno::EBADF # happens when @socket was closed
      true
    end

    def process_connection(connection)
      env = { 'rack.errors' => $stderr,
        'rack.multiprocess' => false,
        'rack.multithread' => @multithread,
        'rack.run_once' => false,
        'rack.version' => VERSION }
      resp = nil
      begin
        request_data = parse!(connection, env)
        if request_data
          resp = handle_request(connection, request_data)
        else
          $stderr.puts "Error: No request data received!"
        end
      rescue EOFError, Errno::ECONNRESET, Errno::EPIPE, Errno::EINVAL
        $stderr.puts "Error: Connection terminated!"
      rescue Object => e
        p $!
        p $@
        if resp.nil? && !connection.closed?
          connection.write "HTTP/1.1 400\r\n\r\n"
        else
          # We have a response, but there was trouble sending it:
          $stderr.puts "Error: Problem transmitting data -- #{e.inspect}"
          $stderr.puts e.backtrace.join("\n")
        end
      ensure
        # We should clean up after our tempfile, if we used one.
        input = env['rack.input']
        input.unlink if input.class == Tempfile
        connection.close rescue nil
      end
    end

    def handle_request(connection, request_data)
      request_data['REMOTE_ADDR'] = connection.addr[3]
      status, headers, body = @app.call(request_data)

      response_handler = @response_handlers.find do |h|
        h.process_this_response?(headers, body)
      end
      response_handler.new(connection, request_data, status, headers, body).process_response
    end

    def close
      @status = :close
      @request_group.wait
      @socket.close
    end


    private

    def parse!(connection, env)
      parser = Thread.current[:http_parser] ||= CTParser.new
      parser.reset
      data = NSMutableData.alloc.init
      data.increaseLengthBy(1) # add sentinel
      parsing_headers = true # Parse headers first
      nread = 0
      content_length = 0
      content_uploaded = 0
      connection_handle = NSFileHandle.alloc.initWithFileDescriptor(connection.fileno)

      while (parsing_headers || content_uploaded < content_length) do
        # Read the availableData on the socket and give up if there's nothing
        incoming_bytes = connection_handle.availableData
        return nil if incoming_bytes.length == 0

        # Until the headers are done being parsed, we'll parse them
        if parsing_headers
          data.setLength(data.length - 1) # Remove sentinel
          data.appendData(incoming_bytes)
          data.increaseLengthBy(1) # Add sentinel
          nread = parser.parseData(data, forEnvironment: env, startingAt: nread)
          if parser.finished == 1
            parsing_headers = false # We're done, now on to receiving the body
            content_length = env['CONTENT_LENGTH'].to_i
            content_uploaded = env['rack.input'].length
          end
        else # Done parsing headers, now just collect request body:
          content_uploaded += incoming_bytes.length
          env['rack.input'].appendData(incoming_bytes)
        end
      end

      if content_length > 1024 * 1024
        body_file = Tempfile.new('control-tower-request-body-')
        NSFileHandle.alloc.initWithFileDescriptor(body_file.fileno).writeData(env['rack.input'])
        body_file.rewind
        env['rack.input'] = body_file
      else
        env['rack.input'] = StringIO.new(NSString.alloc.initWithData(env['rack.input'], encoding: NSASCIIStringEncoding))
      end
      # Returning what we've got...
      return env
    end
  end

  class ResponseHandlerBase
    def initialize(connection, request_data, status, headers, body)
      @connection = connection
      @requst_data = request_data
      @status = status
      @headers = headers
      @body = body
    end

    def process_response
      process_response_header

      # Start writing the response
      resp = make_response(@status, @headers)
      @connection.write  resp

      # Write the body
      send_body

      resp
    end

    def no_need_for_content_length?(status, headers)
      status == -1 ||
        (status >= 100 and status <= 199) ||
        status == 204 ||
        status == 304 ||
        headers.has_key?('Content-Length')
    end

    def make_response(status, headers)
      resp = "HTTP/1.1 #{status}\r\n"
      headers.each do |header, value|
        resp << "#{header}: #{value}\r\n"
      end
      resp << "\r\n"
      resp
    end

    def process_response_header
      # Unless somebody's already set it for us (or we don't need it), set the Content-Length
      unless no_need_for_content_length?(@status, @headers)
        @headers['Content-Length'] = content_length
      end

      # TODO -- We don't handle keep-alive connections yet
      @headers['Connection'] = 'close'
    end
  end

  class RackResponseHandler < ResponseHandlerBase
    def self.process_this_response?(headers, body)
      true # this is the last handler so process every response unless others did not 
    end

    def content_length
      @body.bytesize
    end

    def send_body(body)
      @connection.write @body
    end
  end

  class EnumResponseHandler < ResponseHandlerBase
    def self.process_this_response?(headers, body)
      body.respond_to?(:each) 
    end

    def content_length
      size = 0
      @body.each { |x| size += x.bytesize }
      size
    end

    def send_body
      # Write the body
      @body.each do |chunk|
        @connection.write chunk
      end
    end
  end

  class XSendFileResponseHandler < ResponseHandlerBase
    XSendfileHeader = 'X-Sendfile'

    def self.process_this_response?(headers, body)
      # If there's an X-Sendfile header, we'll use sendfile(2)
      headers.has_key?(XSendfileHeader)
    end

    def initialize(connection, request_data, status, headers, body)
      super
      x_sendfile = headers[XSendfileHeader]
      case x_sendfile
      when IO
        @file = x_sendfile
      else
        @file = ::File.open(x_sendfile, 'r')
      end
      range_header = request_data["HTTP_RANGE"]
      if range_header and range_header =~ /bytes=(\d*)-(\d*)/
        @range_start = $1.to_i
        @range_end = $2.to_i
        if @range_end < @range_start
          @range_end = content_length - 1
        # elsif @range_start == @range_end
          # @range_start = 0
        end
        @status = 206 if @status == 200
        puts "range request #{range_header} -> #{@range_start}-#{@range_end}"
      end
    end

    def process_response_header
      super
      if @range_start and @range_end
        @headers['Content-Length'] = @range_end - @range_start + 1
      else
        @headers['Content-Length'] = content_length
      end
      @headers.delete(XSendfileHeader)
      if @range_start or @range_end
        @headers['Accept-Ranges'] = 'bytes'
        @headers['Content-Range'] = "bytes #{@range_start}-#{@range_end}/#{content_length}"
        @headers['Pragma'] = 'no-cache'
        @headers['Expires'] = '-1'
      end
    end

    def content_length
      @file.stat.size
    end

    def send_body
      if @range_start and @range_end
        @connection.sendfile(@file, @range_start, @range_end)
      else
        @connection.sendfile(@file, 0, content_length)
      end
      puts "send_body end", @headers.inspect
    end
  end


  class Server
    attr_reader :app

    def initialize(app, options)
      @app = app
      parse_options(options)
      @socket = RackSocket.new(@host, @port, self, @concurrent, @logger)
    end

    def start
      trap 'INT' do
        @socket.close
        exit
      end

      # Ok, let the server do it's thing
      @socket.open
    end

    def stop
      @socket.close
    end

    private

    def parse_options(opt)
      @port = (opt[:port] || 8080).to_i
      @host = opt[:host] || `hostname`.chomp
      @concurrent = opt[:concurrent]
      @logger = opt[:logger] || Logger.new(STDOUT)
    end
  end
end
