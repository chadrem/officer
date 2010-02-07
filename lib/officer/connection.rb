module Officer
  module Connection

    module EmCallbacks
      def post_init
        L.debug "Client connected."

        @connected = true
        @timers = {} # name => Timer
      end

      def receive_line line
        line.chomp!

        L.debug "Received line: #{line}"

        command = Officer::Command::Factory.create line, self
        command.execute

      rescue Exception => e
        L.debug_exception e
        raise
      end

      def unbind
        @connected = false

        L.debug "client disconnected."

        Officer::LockStore.instance.reset self
      end
    end

    module LockCallbacks
      def acquired name
        L.debug "acquired lock: #{name}"

        @timers.delete(name).cancel if @timers[name]

        send_line({:result => 'acquired', :name => name}.to_json)
      end

      def already_acquired name
        L.debug "already acquired lock: #{name}"

        send_line({:result => 'already_acquired', :name => name}.to_json)
      end

      def released name
        L.debug "released lock: #{name}"

        send_line({:result => 'released', :name => name}.to_json)
      end

      def release_failed name
        L.debug "release lock failed: #{name}"

        send_line({:result => 'release_failed', :name => name}.to_json)
      end

      def reset_succeeded
        L.debug "reset"
        
        @timers.values.each {|timer| timer.cancel}
        send_line({:result => 'reset_succeeded'}.to_json)
      end

      def queued name, options={}
        L.debug "queued. options=#{options.inspect}"

        timeout = options[:timeout]

        return if timeout.nil? || @timers[name]

        @timers[name] = EM::Timer.new(timeout) do
          Officer::LockStore.instance.timeout name, self
        end
      end

      def timed_out name
        L.debug "Timed out connection=#{object_id}, name=#{name}"

        @timers.delete name
        send_line({:result => 'timed_out', :name => name}.to_json)
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockCallbacks

    private
      attr_reader :connected

      def send_line line
        send_data "#{line}\n" if @connected
      end
    end

  end
end