module Officer

  class Lock
    attr_reader :name
    attr_reader :queue

    def initialize name
      @name = name
      @queue = []
    end
  end

  class LockStore
    include Singleton

    def initialize
      @locks = {} # name => Lock
      @connections = {} # Connection => [name, ...]
    end

    def log_state
      L.debug '-----'

      L.debug 'LOCK STORE:'
      puts
      
      puts "locks:"
      @locks.each do |name, lock|
        puts "#{name}: queue_length=#{lock.queue.length}"
      end
      puts

      puts "Connections:"
      @connections.each do |connection, names|
        puts "#{connection.object_id}: names=[#{names.join(', ')}]"
      end
      puts

      L.debug '-----'
    end

    def acquire name, connection
      lock = @locks[name] ||= Lock.new(name)

      unless lock.queue.include? connection
        lock.queue << connection
        (@connections[connection] ||= []) << name
      end
      
      if lock.queue.first == connection
        connection.acquired name
      end
    end

    def release name, connection
      lock = @locks[name]

      unless lock
        connection.release_failed(name) and return
      end

      if lock.queue.first == connection
        lock.queue.shift
        connection.released name

        next_connection = lock.queue.first

        if next_connection
          next_connection.acquired name
        else
          @locks.delete name
        end
      end
    end

    def unbind connection
      names = @connections[connection] || []

      names.each do |name|
        release name, connection
      end

      @connections.delete connection
    end
  end

end