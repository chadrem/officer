module Officer
  module Command

    class Factory
      @@commands = {} # command_name => klass

      class << self
        def create line, connection
          request = JSON.parse line
          @@commands[request['command']].new connection, request
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

      def initialize connection, request
        @connection = connection
        @request  = request
        
        setup

        raise('Invalid request') unless valid?
      end

      def execute
        raise 'Must override.'
      end

    private
      def setup # Override if necessary.
      end

      def valid? # Override if necessary.
        true
      end

      def require_string arg
        arg.class == String && arg.length > 0
      end

      def optional_positive_integer arg
        arg.nil? || (arg.is_a?(Fixnum) && arg > 0)
      end
    end

    class Lock < Base
      register

      def execute
        Officer::LockStore.instance.acquire @name, @connection, :timeout => @timeout
      end

    private
      def setup
        @name = @request['name']
        @timeout = @request['timeout']
      end

      def valid?
        require_string @request['name']
        optional_positive_integer @request['timeout']
      end
    end

    class Unlock < Base
      register

      def execute
        Officer::LockStore.instance.release @name, @connection
      end

    private
      def setup
        @name = @request['name']
      end

      def valid?
        require_string @request['name']
      end
    end

    class Reset < Base
      register

      def execute
        Officer::LockStore.instance.reset @connection
      end
    end

    class Locks < Base
      register

      def execute
        Officer::LockStore.instance.locks @connection
      end
    end

    class Connections < Base
      register

      def execute
        Officer::LockStore.instance.connections @connection
      end
    end
  end
end