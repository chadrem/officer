module Officer
  module Connection

    module EmCallbacks
      def post_init
        @connected = true
        @timers = {} # name => Timer
        @last_cmd_at = Time.now.utc

        Officer::Log.info "Connected: #{to_host_s}"
      end

      def receive_line line
        line.chomp!

        Officer::Log.debug "#{to_host_s} received line: #{line}"

        command = Officer::Command::Factory.create line, self
        command.execute
        @last_cmd_at = Time.now.utc

      rescue Exception => e
        Officer::Log.error e
        raise
      end

      def unbind
        @connected = false

        Officer::LockStore.instance.reset self

        Officer::Log.info "Disconnected: #{to_host_s}"
      end
    end

    module LockStoreCallbacks
      def acquired name
        @timers.delete(name).cancel if @timers[name]

        send_result 'acquired', :name => name
      end

      def already_acquired name
        send_result 'already_acquired', :name => name
      end

      def released name
        send_result 'released', :name => name
      end

      def release_failed name
        send_result 'release_failed', :name => name
      end

      def reset_succeeded
        @timers.values.each {|timer| timer.cancel}
        send_result 'reset_succeeded'
      end

      def queued name, options={}
        timeout = options[:timeout]

        return if timeout.nil? || @timers[name]

        @timers[name] = EM::Timer.new(timeout) do
          Officer::LockStore.instance.timeout name, self
        end
      end

      def timed_out name, options={}
        @timers.delete name
        send_result 'timed_out', :name => name, :queue => options[:queue]
      end

      def locks locks_hash
        send_result 'locks', :value => locks_hash
      end

      def connections conns_hash
        send_result 'connections', :value => conns_hash
      end

      def queue_maxed name, options={}
        send_result 'queue_maxed', :name => name, :queue => options[:queue]
      end

      def my_locks names
        send_result 'my_locks', :value => names
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockStoreCallbacks

      attr_reader :last_cmd_at

      def to_host_s
        begin
          @to_host_s ||= non_cached_to_host_s
        rescue ArgumentError
          # we assume unix socket, so no ip/port info
          @to_host_s ||= 'UNIX socket client'
        end
      end

    private
      attr_reader :connected

      def non_cached_to_host_s
        port, ip = Socket.unpack_sockaddr_in get_peername
        "#{ip}:#{port}"
      end

      def send_line line
        Officer::Log.debug "#{to_host_s} sent line: #{line}"

        send_data "#{line}\n" if @connected
      end

      def send_result result, options={}
        params = options.dup
        params[:result] = result

        send_line params.to_json
      end
    end

  end
end
