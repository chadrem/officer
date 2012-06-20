module Officer

  class Server
    class ShutdownConnection < EventMachine::Connection
      def unbind
        EM::stop_event_loop
      end
    end

    def initialize params={}
      @semaphore = Mutex.new
      set_running(false)

      @params = params

      params[:socket_type] ||= 'TCP'
      params[:port] ||= 11500
      params[:host] ||= '0.0.0.0'
      params[:socket_file] ||= '/tmp/officer.sock'
      params[:stats] ||= false
      params[:log_level] ||= 'error'
      params[:close_idle] = params.include?(:close_idle) ? params[:close_idle] : true
      params[:max_idle] ||= 60 # Seconds.

      Officer::Log.set_log_level params[:log_level]
    end

    def run
      Officer::Log.debug 'Starting Officer #{Officer::VERSION} with params:'

      @params.each do |param, value|
        Officer::Log.debug "  #{param} => #{value}"
      end

      EM.error_handler {|e| Officer::Log.error e}

      EM.kqueue = true if EM.kqueue?
      EM.epoll = true if EM.epoll?

      EM::run do
        if @params[:stats]
          EM::PeriodicTimer.new(5) do
            Officer::LockStore.instance.log_state
          end
        end

        if @params[:close_idle]
          EM::PeriodicTimer.new(5) do
            Officer::LockStore.instance.close_idle_connections @params[:max_idle]
          end
        end

        if @enable_shutdown_port
          EM::start_server '127.0.0.1', 11501, ShutdownConnection
        end

        if @params[:socket_type] == 'TCP'
          EM::start_server @params[:host], @params[:port], Connection::Connection
        else
          EM::start_unix_domain_server @params[:socket_file], Connection::Connection
        end

        set_running(true)
      end

      set_running(false)
    end

    def running?
      @semaphore.synchronize {@running}
    end

  private

    def set_running value
      @semaphore.synchronize {@running = value}
    end
  end

end
