module Officer

  class Server
    def initialize options={}
      options.reverse_merge! :port => 11500, :host => '0.0.0.0'

      @port = options[:port]
      @host = options[:host]
    end

    def run
      EM.error_handler {|e|
        L.debug_exception e
      }
    
      EM::run {
        EM::start_server @host, @port, Connection::Connection
      }
    end
  end

end