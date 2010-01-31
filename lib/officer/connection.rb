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

    class Base < EventMachine::Protocols::LineAndTextProtocol
      include EmCallbacks
    end

  end
end