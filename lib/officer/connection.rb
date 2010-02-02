module Officer
  module Connection

    module EmCallbacks
      def post_init
        L.debug "Client connected."
        @connected = true
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
        Officer::LockStore.instance.unbind self
      end
    end

    module LockCallbacks
      def acquired name
        L.debug "acquired lock: #{name}"
        send_line({:result => 'acquired', :name => name}.to_json)
      end

      def released name
        L.debug "released lock: #{name}"
        send_line({:result => 'released', :name => name}.to_json)
      end

      def release_failed name
        L.debug "release lock failed: #{name}"
        send_line({:result => 'release_failed', :name => name}.to_json)
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockCallbacks

      attr_reader :connected

      def send_line line
        send_data "#{line}\n" if @connected
      end
    end

  end
end