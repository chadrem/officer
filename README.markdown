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

Run Officer in the foreground with verbose mode enabled (useful for debugging):
    sudo officer run -- -v

Run Officer in the background (production mode) and listen on a specific IP and port:
    sudo officer start -- -h 127.0.0.1 -p 9999

- The server listens on 0.0.0.0:11500 by default.
- All debugging and error output goes to stdout for now.  The daemons gem is configured to log stdout.
- The daemons gem will create a PID file in /var/run and log files in /var/log when using the 'start' option for background mode.

## Ruby Client

    require 'rubygems'
    require 'officer'

### Create a client object (defaults to localhost:11500)

    client = Officer::Client.new :host => 'localhost', :port => 11500

### Lock

    client.lock 'some_lock_name'

### Unlock

    client.unlock 'some_lock_name'

### Wrap a block of code in a lock/unlock (with optional 5 second timeout)

    client.with_lock('some_lock_name', :timeout => 5) do
      puts 'hello world'
    end

### Release all locks for this connection

    client.reset

### Reconnect (all locks will be released)

    client.reconnect

- Useful if you use Officer with Phusion Passenger and smart spawning.  See [Passenger's documentation](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_smart_spawning_gotcha_1_unintential_file_descriptor_sharing) for more information.

### Locks

    client.locks

- Returns the internal state of all the server's locks.

### Connections

    client.connections

- Returns the internal state of all the server's connections.

## Planned Features

- Retrieve the list of locks for the current connection.
- Client: Option to abort a lock request if there is already a certain number of clients waiting for the lock.

## Copyright

Copyright (c) 2010 Chad Remesch. See LICENSE for details.
