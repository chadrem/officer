module Officer

  class GenericError < RuntimeError; end
  class AlreadyConnectedError < GenericError; end
  class LockError < GenericError; end
  class LockTimeoutError < LockError; end
  class LockQueuedMaxError < LockError; end
  class UnlockError < GenericError; end

  class Client
    def initialize options={}
      @socket_type = options[:socket_type] || 'TCP'
      @socket_file = options[:socket_file] || '/tmp/officer.sock'
      @host = options[:host] || 'localhost'
      @port = options[:port] || 11500
      @namespace = options[:namespace]
      @keep_alive_freq = options[:keep_alive_freq] || 6 # Hz.
      @keep_alive_enabled = options.include?(:keep_alive_enabled) ? options[:keep_alive_enabled] : true
      @thread = nil
      @lock = Mutex.new

      connect
    end

    def reconnect
      disconnect
      connect

      self
    end

    def disconnect
      @lock.synchronize do
        @thread.terminate if @thread
        @thread = nil

        @socket.close if @socket
        @socket = nil
      end

      self
    end

    def lock name, options={}
      result = execute :command => 'lock', :name => name_with_ns(name),
        :timeout => options[:timeout], :queue_max => options[:queue_max]
      strip_ns_from_hash result, 'name'
    end

    def unlock name
      result = execute :command => 'unlock', :name => name_with_ns(name)
      strip_ns_from_hash result, 'name'
    end

    def with_lock name, options={}
      response = lock name, options
      result = response['result']
      queue = (response['queue'] || []).join ','

      raise LockTimeoutError.new("queue=#{queue}") if result == 'timed_out'
      raise LockQueuedMaxError.new("queue=#{queue}") if result == 'queue_maxed'
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

    def my_locks
      result = execute :command => 'my_locks'
      result['value'] = result['value'].map {|name| strip_ns(name)}

      result
    end

  private
    def connect
      @lock.synchronize do
        raise AlreadyConnectedError if @socket

        case @socket_type
        when 'TCP'
          @socket = TCPSocket.new @host, @port.to_i
        when 'UNIX'
          @socket = UNIXSocket.new @socket_file
        else
          raise "Invalid socket type: #{@socket_type}"
        end

        @socket.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
        @socket.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1

        @thread = Thread.new { thread_main } unless @thread && @thread.alive?
      end
    end

    def execute command
      @lock.synchronize do
        command = command.to_json
        @socket.write command + "\n"

        result = nil

        while true
          rs = IO.select([@socket], nil, nil, sleep_sec)

          if rs.nil?
            keep_alive
          else
            result = @socket.gets "\n"
            return JSON.parse result.chomp
          end
        end
      end
    rescue
      reconnect
      raise
    end

    def name_with_ns name
      @namespace ? "#{@namespace}:#{name}" : name
    end

    def strip_ns name
      @namespace ? name.gsub(Regexp.new("^#{@namespace}:"), '') : name
    end

    def strip_ns_from_hash hash, key
      hash[key] = strip_ns(hash[key])
      hash
    end

    def sleep_sec
      60.0 / @keep_alive_freq
    end

    # This method assumes the calling thread already holds @lock.
    def keep_alive
      return unless @keep_alive_enabled
      return unless @socket

      command = { :command => 'keep_alive' }
      @socket.write command.to_json + "\n"
      nil
    end

    def thread_main
      while true
        sleep(sleep_sec)

        if @lock.try_lock
          begin
            keep_alive
          rescue Exception => e
          ensure
            @lock.unlock
          end
        end
      end
    end
  end

end
