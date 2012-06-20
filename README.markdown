# Officer - Ruby lock server and client built on EventMachine

Officer is designed to help you coordinate distributed processes and avoid race conditions.  Inspiration comes from [elock](http://github.com/dustin/elock).

Read more in my blog post: [http://remesch.com/officer-the-ruby-lock-server-and-client](http://remesch.com/officer-the-ruby-lock-server-and-client)

## Installation

    gem install officer

## Usage

Officer uses the 'daemons' gem to simplify creating long lived background processes.

Help information:
Usage: officer [-hofplsdm]
    -h, --host=HOST                  The hostname or IP to bind to (default: 0.0.0.0)
    -o, --socket-type=OPTION         TCP or UNIX (default: TCP)
    -f, --socket-file=FILE           Full path and name to the UNIX domain socket file (only used with '-o UNIX', default: /tmp/officer.sock)
    -p, --port=PORT                  The port to listen on (default: 11500)
    -l, --log-level                  Set the log level to debug, info, or error (default: error)
    -s, --stats                      Log stats every 5 seconds (default: off, required log level: info)
    -d, --pid-dir                    Set directory where pid file will be saved (default: operating system's run directory)
    -m, --max-idle                   Maximum idle time (in seconds) to wait before closing a connection that is idle and hasn't sent a keep alive (default: 60)
        --help

Run Officer in the foreground with full logging and statistics:

    officer run -- -l debug -s -d /tmp

Run Officer in the background (production mode) and listen on a specific IP and port:

    officer start -- -h 127.0.0.1 -p 9999 -d /tmp

### Other notes:

- The server listens on 0.0.0.0:11500 by default.
- All debugging and error output goes to stdout for now.
- By default, a pid file is created in /var/run and stdout is written to /var/log/officer.output.  This will require root permissions which is normally a bad idea.  You can avoid this by picking a different directory (example: officer start -- -d /tmp).
- I personally run Officer in production using Ruby Enterprise Edition (REE) which is based on Ruby 1.8.7.
- RVM and JRuby users should check the [Known Issues](https://github.com/chadrem/officer/wiki/Known-Issues) wiki page.
- UNIX domain sockets are supported (example: officer start -- -o UNIX -p /tmp)

## Ruby Client

    require 'rubygems'
    require 'officer'

### Create a client object

    client = Officer::Client.new :host => 'localhost', :port => 11500

Options:

- :host => Hostname or IP address of the server to bind to (default: 0.0.0.0).
- :port => TCP Port to listen on (default: 11500).
- :socket_type => TCP or UNIX (default: TCP).
- :socket_file => Full path to the server's UNIX domain socket file (default: /tmp/officer.sock).  This option is only used when the socket type is UNIX.
- :namespace => Prepend a namespace to each lock name (default: empty string).
- :keep_alive_freq => Frequency (in Hz) to send a keep alive message (default: 6 Hz).

### Lock

    client.lock 'some_lock_name'

Options:

- :timeout => The number of seconds to wait for a lock to become available (default: wait forever).
- :queue_max => If the lock queue length is greater than :queue_max then don't wait for the lock (default: infinite).


### Unlock

    client.unlock 'some_lock_name'


### Lock a block of code

    client.with_lock('some_lock_name', :timeout => 5) do
      puts 'hello world'
    end

Options:

- Same options as the above Lock command.


### Release all locks for this connection

    client.reset


### Reconnect (all locks will be released)

    client.reconnect

- Useful if you use Officer with Phusion Passenger and smart spawning.  See [Passenger's documentation](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_smart_spawning_gotcha_1_unintential_file_descriptor_sharing) for more information.


### Disconnect

    client.disconnect

- Close the connection to the server.


### Show locks

    client.locks

- Returns the internal state of all the server's locks.


### Show connections

    client.connections

- Returns the internal state of all the server's connections.


### Show my locks

    client.my_locks


## Contributing to Officer

1. Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
2. Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
3. Fork the project.
4. Start a feature/bugfix branch.
5. Commit and push until you are happy with your contribution.
6. Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
7. Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


## Copyright

Copyright (c) 2010 - 2012 Chad Remesch. See LICENSE for details.
