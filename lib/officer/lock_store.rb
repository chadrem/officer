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
        puts "#{name}: connections=[#{lock.queue.map{|c| c.object_id}.join(', ')}]"
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

      # Queue the lock request unless this connection already has the lock.
      unless lock.queue.include? connection
        lock.queue << connection
        (@connections[connection] ||= []) << name
      end
      
      # Tell the client to block unless it has acquired the lock.
      if lock.queue.first == connection
        connection.acquired name
      end
    end

    def release name, connection
      lock = @locks[name]
      names = @connections[connection]

      # Client should only be able to release a lock that
      # exists and that it has previously queued.
      if lock.nil? || !names.include?(name)
        connection.release_failed(name) and return
      end

      # If connecton has the lock, release it and let the next
      # connection know that it has acquired the lock.
      if lock.queue.first == connection
        lock.queue.shift
        connection.released name

        if next_connection = lock.queue.first
          next_connection.acquired name
        else
          @locks.delete name
        end

      # If the connection is queued, but doesn't have the lock,
      # release it and leave the other connections alone.
      else
        lock.queue.delete connection
        connection.released name
      end

      @connections[connection].delete name
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