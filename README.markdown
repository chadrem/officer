# Officer - Distributed Lock Server and Client

This project is a work in progress and shouldn't be considered production ready at this time.
It is implemented using Ruby and Eventmachine. Inspiration comes from [elock](http://github.com/dustin/elock).

## Installation

	install gemcutter
	gem install officer

## Usage

Start the server using the 'officer' command in a shell.
It will listen on all interfaces on port 11500.
All debugging output goes to stdout for now.

## Ruby Client

	require 'rubygems'
	require 'officer'

### Create a client object (:host and :port default to localhost:11500)

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

- Properly handle nested with_lock() blocks.  For example:
	client.with_lock('some_lock') {
	  client.with_lock('some_lock') {
	  }
	  # The lock should still be held at this point.
	}
- Option to abort a lock request if there already a certain number of clients waiting for the lock.
- Lock statistics.
- Retrieve the complete list of locks.
- Retrieve the list of locks for the current connection.

## Copyright

Copyright (c) 2010 Chad Remesch. See LICENSE for details.
