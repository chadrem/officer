module Officer
  module Command

    class Factory
      @@commands = {} # command_name => klass

      class << self
        def create command_name, connection, params
          @@commands[command_name].new connection, params
        end

        def register command_name, klass
          @@commands[command_name] = klass
        end
      end
    end

    class Base
      class << self
        def register
          Factory.register to_s.split('::').last.underscore, self
        end
      end

      def initialize connection, params
        @connection = connection
        @params  = params
        
        setup

        raise('Invalid params') unless valid?
      end

      def execute
        raise 'Must override.'
      end

    private
      def valid?
        false
      end

      def require_string string
        string && !string.empty?
      end
    end

    class Lock < Base
      register

      def execute
        L.debug 'executing lock command.'
      end

    private
      def setup
        @lock_name = @params[0]
      end

      def valid?
        require_string @lock_name
      end
    end

    class Unlock < Base
      register

      def execute
          L.debug 'executing unlock command.'
      end

    private
      def setup
        @lock_name = @params[0]
      end

      def valid?
        require_string @lock_name
      end
    end
  end
end