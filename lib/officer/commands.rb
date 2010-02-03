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
    end

    class Lock < Base
      register

      def execute
        L.debug 'executing lock command.'
        Officer::LockStore.instance.acquire @name, @connection
      end

    private
      def setup
        @name = @request['name']
      end

      def valid?
        require_string @request['name']
      end
    end

    class Unlock < Base
      register

      def execute
        L.debug 'executing unlock command.'
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
        L.debug 'executing reset command.'
        Officer::LockStore.instance.reset @connection
      end
    end
  end
end