module Officer

  class Log
    include Singleton

    def debug message
      return unless [:debug].include?(LOG_LEVEL)

      write message
    end

    def info message
      return unless [:debug, :info].include?(LOG_LEVEL)

      write message
    end

    def debug_exception e
      debug '-----'
      debug "EXCEPTION: "
      debug e
      debug e.backtrace.join "\n  "
      debug '-----'
    end

  private
    def write message
      puts message
    end
  end
  
end

L = Officer::Log.instance
LOG_LEVEL = :info