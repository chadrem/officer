require 'socket'
require 'fcntl'

require 'rubygems'
require 'json'

module Officer

  class GenericError < RuntimeError; end
  class AlreadyConnectedError < GenericError; end
  class LockError < GenericError; end
  class LockTimeoutError < LockError; end
  class LockQueuedMaxError < LockError; end
  class UnlockError < GenericError; end

  class Client
    def initialize options={}
      @host = options[:host] || 'localhost'
      @port = options[:port] || 11500
      @namespace = options[:namespace]

      connect
    end

    def reconnect
      disconnect
      connect
    end

    def lock name, options={}
      execute :command => 'lock', :name => name_with_ns(name),
        :timeout => options[:timeout], :queue_max => options[:queue_max]
    end

    def unlock name
      execute :command => 'unlock', :name => name_with_ns(name)
    end

    def with_lock name, options={}
      response = lock name, options
      result = response['result']
      
      raise LockTimeoutError if result == 'timed_out'
      raise LockQueuedMaxError if result == 'queue_maxed'
      raise LockError unless %w(acquired already_acquired).include?(result)

      begin
        yield
      ensure
        # Deal with nested with_lock calls.  Only the outer most call should tell the server to unlock.
        if result == 'acquired'
          response = unlock name
          raise UnlockError unless response['result'] == 'released'
        end
      end
    end

    def reset
      execute :command => 'reset'
    end

    def locks
      execute :command => 'locks'
    end

    def connections
      execute :command => 'connections'
    end

  private
    def connect
      raise AlreadyConnectedError if @socket

      @socket = TCPSocket.new @host, @port.to_i
      @socket.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
    end

    def disconnect
      @socket.close
      @socket = nil
    end

    def execute command
      command = command.to_json
      @socket.write command + "\n"
      result = @socket.gets "\n"
      JSON.parse result.chomp
    rescue
      reconnect
      raise
    end

    def name_with_ns name
      @namespace ? "#{@namespace}:#{name}" : name
    end
  end

end