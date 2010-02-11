module Officer
  module Connection

    module EmCallbacks
      def post_init
        @connected = true
        @timers = {} # name => Timer
      end

      def receive_line line
        line.chomp!

        command = Officer::Command::Factory.create line, self
        command.execute

      rescue Exception => e
        L.debug_exception e
        raise
      end

      def unbind
        @connected = false

        Officer::LockStore.instance.reset self
      end
    end

    module LockStoreCallbacks
      def acquired name
        @timers.delete(name).cancel if @timers[name]

        send_line({:result => 'acquired', :name => name}.to_json)
      end

      def already_acquired name
        send_line({:result => 'already_acquired', :name => name}.to_json)
      end

      def released name
        send_line({:result => 'released', :name => name}.to_json)
      end

      def release_failed name
        send_line({:result => 'release_failed', :name => name}.to_json)
      end

      def reset_succeeded
        @timers.values.each {|timer| timer.cancel}
        send_line({:result => 'reset_succeeded'}.to_json)
      end

      def queued name, options={}
        timeout = options[:timeout]

        return if timeout.nil? || @timers[name]

        @timers[name] = EM::Timer.new(timeout) do
          Officer::LockStore.instance.timeout name, self
        end
      end

      def timed_out name
        @timers.delete name
        send_line({:result => 'timed_out', :name => name}.to_json)
      end

      def locks locks_hash
        send_line({:result => 'locks', :value => locks_hash}.to_json)
      end

      def connections conns_hash
        send_line({:result => 'connections', :value => conns_hash}.to_json)
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockStoreCallbacks

      def to_host_s
        port, ip = Socket.unpack_sockaddr_in get_peername
        "#{ip}:#{port}"
      end

    private
      attr_reader :connected

      def send_line line
        send_data "#{line}\n" if @connected
      end
    end

  end
end