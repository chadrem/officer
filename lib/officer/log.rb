module Officer

  class Log < SimpleDelegator
    include Singleton

    class << self
      def debug msg
        instance.debug msg
      end

      def info msg
        instance.info msg
      end

      def error msg
        instance.error msg
      end

      def set_log_level level
        level = case level
          when 'debug' then Logger::DEBUG
          when 'info'  then Logger::INFO
          else Logger::ERROR
        end

        instance.level = level
      end
    end

    def initialize
      @logger = Logger.new STDOUT

      super @logger
    end
  end

end