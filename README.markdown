# Officer - Distributed Lock Server and Client

It is implemented using Ruby and Eventmachine. Inspiration comes from [elock](http://github.com/dustin/elock).

## Installation

    sudo gem install gemcutter
    sudo gem install officer

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

- The server listens on 0.0.0.0:11500 by default.
- All debugging and error output goes to stdout for now.  The daemons gem is configured to log to stdout which gets redirected to /var/log/officer.output on OSX and Linux.
- The daemons gem will create a PID file in /var/run and log files in /var/log when using the 'start' option for background mode.

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
- :queue_max => If the lock queue length is greater than :queue_max then don't wait for the lock.


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


### Show locks

    client.locks

- Returns the internal state of all the server's locks.


### Show connections

    client.connections

- Returns the internal state of all the server's connections.

## Planned Features

- Retrieve the list of locks for the current connection.
- Client: Option to abort a lock request if there is already a certain number of clients waiting for the lock.
- Server: configure the daemons gem to allow multiple server processes to run on one box.
- Tests

## Copyright

Copyright (c) 2010 Chad Remesch. See LICENSE for details.
