module Officer

  class Log
    include Singleton

    def debug message
      puts message
    end

    def debug_exception e
      debug '-----'
      debug "EXCEPTION: "
      debug e
      debug e.backtrace.join "\n  "
      debug '-----'
    end
  end
  
end

L = Officer::Log.instance