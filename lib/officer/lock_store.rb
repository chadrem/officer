module Officer

  class LockQueue < Array
    def to_host_a
      map {|conn| conn.to_host_s}
    end
  end

  class Lock
    attr_reader :name
    attr_reader :queue

    def initialize name
      @name = name
      @queue = LockQueue.new
    end
  end

  class LockStore
    include Singleton

    def initialize
      @locks = {} # name => Lock
      @connections = {} # Connection => Set(name, ...)
      @acquire_counter = 0
    end

    def log_state
      l = Officer::Log

      l.info '-----'

      l.info 'LOCK STORE:'
      l.info ''

      l.info "locks:"
      @locks.each do |name, lock|
        l.info "#{name}: connections=[#{lock.queue.to_host_a.join(', ')}]"
      end
      l.info ''

      l.info "Connections:"
      @connections.each do |connection, names|
        l.info "#{connection.to_host_s}: names=[#{names.to_a.join(', ')}]"
      end
      l.info ''

      l.info "Acquire Rate: #{@acquire_counter.to_f / 5}/s"
      @acquire_counter = 0

      l.info '-----'
    end

    def acquire name, connection, options={}
      if options[:queue_max]
        lock = @locks[name]

        if lock && !lock.queue.include?(connection) && lock.queue.length >= options[:queue_max]
          connection.queue_maxed name, :queue => lock.queue.to_host_a
          return
        end
      end

      @acquire_counter += 1

      lock = @locks[name] ||= Lock.new(name)

      if lock.queue.include? connection
        lock.queue.first == connection ? connection.already_acquired(name) : connection.queued(name, options)

      else
        lock.queue << connection
        (@connections[connection] ||= Set.new) << name

        lock.queue.count == 1 ? connection.acquired(name) : connection.queued(name, options)
      end
    end

    def release name, connection, options={}
      if options[:callback].nil?
        options[:callback] = true
      end

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

      names.delete name
    end

    def reset connection
      names = @connections[connection] || Set.new

      names.each do |name|
        release name, connection, :callback => false
      end

      @connections.delete connection
      connection.reset_succeeded
    end

    def timeout name, connection
      lock = @locks[name]
      names = @connections[connection]

      return if lock.queue.first == connection # Don't timeout- already have the lock.

      lock.queue.delete connection
      names.delete name

      connection.timed_out name, :queue => lock.queue.to_host_a
    end

    def locks connection
      locks = {}

      @locks.each do |name, lock|
        locks[name] = lock.queue.to_host_a
      end

      connection.locks locks
    end

    def connections connection
      connections = {}

      @connections.each do |conn, names|
        connections[conn.to_host_s] = names.to_a
      end

      connection.connections connections
    end

    def my_locks connection
      my_locks = @connections[connection] ? @connections[connection].to_a : []
      connection.my_locks my_locks
    end

    def watchdog
      @connections.each do |conn, names|

      end
    end
  end

end
