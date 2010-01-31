module Officer

  class Lock
    def initialize
      
    end
  end

  class WaitQueue
    def initialize
      @queue = []
    end
  end

  class LockStore
    include Singleton

    def initialize
      @lock_hash = {}
    end

    def acquire name, conn_id
      
    end

    def release name, conn_id
      
    end

    def available? name, conn_id
      
    end
  end

end