module Officer

  class Server
    def initialize options={}
      options.reverse_merge! :port => 11500, :host => '0.0.0.0', :verbose => false

      @port = options[:port]
      @host = options[:host]
      @verbose = options[:verbose]
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