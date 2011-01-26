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

      params[:port] ||= 11500
      params[:host] ||= '0.0.0.0'
      params[:stats] ||= false
      params[:log_level] ||= 'error'

      Officer::Log.set_log_level params[:log_level]
    end

    def run
      EM.error_handler {|e| Officer::Log.error e}

      EM.kqueue = true if EM.kqueue?
      EM.epoll = true if EM.epoll?

      EM::run do
        if @params[:stats]
          EM::PeriodicTimer.new(5) {Officer::LockStore.instance.log_state}
        end

        if @enable_shutdown_port
          EM::start_server '127.0.0.1', 11501, ShutdownConnection
        end

        EM::start_server @params[:host], @params[:port], Connection::Connection

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
