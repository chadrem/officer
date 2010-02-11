module Officer

  class Server
    def initialize opts={}
      @port      = opts[:port]    || 11500
      @host      = opts[:host]    || '0.0.0.0'
      @verbose   = opts[:verbose] || false
    end

    def run
      EM.error_handler do |e|
        L.debug_exception e
      end
    
      EM::run do
        if @verbose
          EM::PeriodicTimer.new(5) do
            Officer::LockStore.instance.log_state
          end
        end

        EM::start_server @host, @port, Connection::Connection
      end
    end
  end

end