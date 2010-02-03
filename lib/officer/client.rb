require 'socket'
require 'fcntl'

require 'rubygems'
require 'active_support'
require 'json'

module Officer

  class GenericError < RuntimeError; end
  class AlreadyConnectedError < GenericError; end
  class NotConnectedError < GenericError; end
  class LockError < GenericError; end
  class UnlockError < GenericError; end

  class Client
    def initialize options={}
      options.reverse_merge! :host => 'localhost', :port => 11500

      @host = options[:host]
      @port = options[:port]

      connect
    end

    def reconnect
      disconnect
      connect
    end

    def lock name
      execute({:command => 'lock', :name => name}.to_json)
    end

    def unlock name
      execute({:command => 'unlock', :name => name}.to_json)
    end

    def with_lock name
      response = lock name
      raise LockError unless response['result'] == 'acquired'

      begin
        yield
      ensure
        response = unlock name
        raise UnlockError unless response['result'] == 'released'
      end
    end

    def reset
      execute({:command => 'reset'}.to_json)
    end

  private
    def connect
      raise AlreadyConnectedError if @socket

      @socket = TCPSocket.new @host, @port.to_i
      @socket.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
    end

    def disconnect
      raise NotConnectedError unless @socket

      @socket.close
      @socket = nil
    end

    def execute command
      @socket.write command + "\n"
      result = @socket.gets "\n"
      JSON.parse result.chomp
    end
  end

end