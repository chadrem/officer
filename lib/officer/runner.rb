module Officer

  class Runner
    def run
      hack_argv
      set_choices
      unhack_argv
      set_daemon_options
      run_daemon
    end

    # HACK: Both the Choice and Daemons gems will parse ARGV so I
    # modify ARGV for Choice and then restore it for Daemons.
    def hack_argv
      if ARGV.include? '--'
        @saved_args = ARGV.slice! 0..ARGV.index('--')
      end
    end

    def unhack_argv
      ARGV.unshift(*@saved_args) if @saved_args
    end

    def set_choices

      Choice.options do
        option :host do
          short '-h'
          long '--host=HOST'
          desc 'The hostname or IP to bind to (default: 0.0.0.0)'
        end

        option :socket_type do
          short '-o'
          long '--socket-type=OPTION'
          desc 'TCP (default) or UNIX'
          default 'TCP'
          validate /^(TCP|UNIX)$/
        end

        option :socket_file do
          short '-f'
          long '--socket-file=FILE'
          desc 'Full path and name to the UNIX socket file (only used if --socket-type=UNIX, default: /tmp/officer.sock)'
        end

        option :port do
          short '-p'
          long '--port=PORT'
          desc 'The port to listen on (default: 11500)'
          cast Integer
        end

        option :log_level do
          short '-l'
          long '--log-level'
          desc 'Set the log level to debug, info, or error (default: error)'
        end

        option :stats do
          short '-s'
          long '--stats'
          desc 'Log stats every 5 seconds (default: off, required log level: info)'
        end

        option :pid_dir do
          short '-d'
          long '--pid-dir'
          desc "Set directory where pid file will be saved (default: operating system's run directory)"
        end

        option :help do
          long '--help'
        end
      end

      @choices = Choice.choices
    end

    def set_daemon_options
      @daemon_options = {
        :dir_mode   => :system,
        :multiple   => false,
        :monitor    => true,
        :log_output => true
      }

      if @choices[:pid_dir]
        @daemon_options[:dir_mode] = :normal
        @daemon_options[:dir] = @choices[:pid_dir]
      end
    end

    def run_daemon
      Daemons.run_proc('officer', @daemon_options) do
        Officer::Server.new(@choices).run
      end
    end
  end

end
