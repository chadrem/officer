# Officer - Distributed Lock Server and Client

This project is a work in progress and shouldn't be considered production ready at this time.
It is implemented using Ruby and Eventmachine. Inspiration comes from [elock](http://github.com/dustin/elock).

## Installation

    sudo gem install gemcutter
    sudo gem install officer

## Usage

    sudo officer --help
    sudo officer start

- The server listens on 0.0.0.0:11500 by default.  In the future this should be configurable.
- All debugging output goes to stdout for now.  Use 'sudo officer run' to see it.

## Ruby Client

	require 'rubygems'
	require 'officer'

### Create a client object (defaults to localhost:11500)

	client = Officer::Client.new :host => 'localhost', :port => 11500

### Lock

	client.lock 'some_lock_name'

### Unlock

	client.unlock 'some_lock_name

### Wrap a block of code in a lock/unlock (with optional 5 second timeout)

	client.with_lock('some_lock_name', :timeout => 5) do
	  puts 'hello world'
	end

### Release all locks for this connection

	client.reset

### Reconnect (all locks will be released)

	client.reconnect

## Planned Features

- Lock statistics.
- Retrieve the complete list of locks.
- Retrieve the list of locks for the current connection.
- Client: Option to abort a lock request if there is already a certain number of clients waiting for the lock.
- Server: Make IP and port configurable.

## Copyright

Copyright (c) 2010 Chad Remesch. See LICENSE for details.
