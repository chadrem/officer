module Officer

  class Server
    def initialize params={}
      @params = params

      params[:port] ||= 11500
      params[:host] ||= '0.0.0.0'
      params[:stats] ||= false
      params[:log_level] ||= 'error'

      Officer::Log.set_log_level params[:log_level]
    end

    def run
      EM.error_handler {|e| Officer::Log.error e}

      EM::run do
        if @params[:stats]
          EM::PeriodicTimer.new(5) {Officer::LockStore.instance.log_state}
        end

        EM::start_server @params[:host], @params[:port], Connection::Connection
      end
    end
  end

end