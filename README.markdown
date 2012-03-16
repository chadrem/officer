# Officer - Ruby lock server and client built on EventMachine

Officer is designed to help you coordinate distributed processes and avoid race conditions.  Inspiration comes from [elock](http://github.com/dustin/elock).

Read more in my blog post: [http://remesch.com/officer-the-ruby-lock-server-and-client](http://remesch.com/officer-the-ruby-lock-server-and-client)

## Installation

    gem install officer

## Usage

Officer uses the 'daemons' gem to simplify creating long lived background processes.
Here are some simple examples in case you aren't familiar with it.

'daemons' help information:
    sudo officer --help

Officer's help information:
    sudo officer run -- --help

Run Officer in the foreground with full logging and statistics:
    sudo officer run -- -l debug -s

Run Officer in the background (production mode) and listen on a specific IP and port:
    sudo officer start -- -h 127.0.0.1 -p 9999

### Other notes:

- The server listens on 0.0.0.0:11500 by default.
- All debugging and error output goes to stdout for now.
- The daemons gem will create a pid file in /var/run and redirect stdout to /var/log/officer.output when using the 'start' option for background mode.
- I personally run Officer in production using Ruby Enterprise Edition (REE) which is based on Ruby 1.8.7.
- RVM and JRuby users should check the [Known Issues](https://github.com/chadrem/officer/wiki/Known-Issues) wiki page.

## Ruby Client

    require 'rubygems'
    require 'officer'

### Create a client object

    client = Officer::Client.new :host => 'localhost', :port => 11500

Options:

- :host => Hostname or IP address of the server to bind to (default: 0.0.0.0).
- :port => TCP Port to listen on (default: 11500).


### Lock

    client.lock 'some_lock_name'

Options:

- :timeout => The number of seconds to wait for a lock to become available (default: wait forever).
- :namespace => Prepend a namespace to each lock name (default: empty string).
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
