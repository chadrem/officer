module Officer
  module Connection

    module EmCallbacks
      def post_init
        L.debug "Client connected."
      end

      def receive_line line
        line.chomp!
        L.debug "Received line: #{line}"
        tokens = line.split
        command = tokens.shift

        command = Officer::Command::Factory.create command, self, tokens
        command.execute

      rescue Exception => e
        L.debug_exception e
        raise
      end

      def unbind
        L.debug "client disconnected."
      end
    end

    module LockCallbacks
      def acquired name
        L.debug "acquired lock: #{name}"
        send_line "acquired #{name}"
      end

      def released name
        L.debug "released lock: #{name}"
        send_line "released #{name}"
      end

      def queued name
        L.debug "queued lock: #{name}"
        send_line "queued #{name}"
      end
    end

    class Connection < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
      include LockCallbacks

      def send_line line
        send_data "#{line}\n"
      end
    end

  end
end