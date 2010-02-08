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
      @connections = {} # Connection => Set(name, ...)
      @acquire_counter = 0
    end

    def log_state
      L.info '-----'

      L.info 'LOCK STORE:'
      L.info ''
      
      L.info "locks:"
      @locks.each do |name, lock|
        L.info "#{name}: connections=[#{lock.queue.map{|c| c.object_id}.join(', ')}]"
      end
      L.info ''

      L.info "Connections:"
      @connections.each do |connection, names|
        L.info "#{connection.object_id}: names=[#{names.to_a.join(', ')}]"
      end
      L.info ''

      L.info "Acquire Rate: #{@acquire_counter.to_f / 5}/s"
      @acquire_counter = 0

      L.info '-----'
    end

    def acquire name, connection, options={}
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

      lock.queue.delete connection
      names.delete name

      connection.timed_out name
    end
  end

end