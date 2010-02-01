module Officer

  class Lock
    def self.locks_for obj
      case obj.class
      when String
        @locks_for_name[obj]
      when Officer::Connection::Connection
        @locks_for_connection[obj]
      else
        raise 'Invalid argument'
      end
    end
  end

  class LockStore
    include Singleton

    def initialize
      @locks_for_name = {}
      @locks_for_connection = {}
    end
  end

end