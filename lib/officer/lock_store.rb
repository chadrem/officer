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
        puts "#{connection.object_id}: names=[#{names.to_a.join(', ')}]"
      end
      puts

      L.debug '-----'
    end

    def acquire name, connection
      lock = @locks[name] ||= Lock.new(name)

      lock.queue << connection unless lock.queue.include? connection

      (@connections[connection] ||= Set.new) << name
      
      if lock.queue.first == connection
        connection.acquired name
      end
    end

    def release name, connection, options={}
      options.reverse_merge! :callback => true

      lock = @locks[name]
      names = @connections[connection]

      # Client should only be able to release a lock that
      # exists and that it has previously queued.
      if lock.nil? || !names.include?(name)
        connection.release_failed(name) if options[:callback]
        return
      end

      # If connecton has the lock, release it and let the next
      # connection know that it has acquired the lock.
      if lock.queue.first == connection
        lock.queue.shift
        connection.released name if options[:callback]

        if next_connection = lock.queue.first
          next_connection.acquired name
        else
          @locks.delete name
        end

      # If the connection is queued and doesn't have the lock,
      # dequeue it and leave the other connections alone.
      else
        lock.queue.delete connection
        connection.released name
      end

      @connections[connection].delete name
    end

    def reset connection
      names = @connections[connection] || Set.new

      names.each do |name|
        release name, connection, :callback => false
      end

      @connections.delete connection

      connection.reset_succeeded
    end
  end

end