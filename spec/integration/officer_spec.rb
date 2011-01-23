require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "benchmark"

describe Officer do
  before do
    @server_thread = Thread.new do
      Officer::Server.new.run
    end
  end

  after do
    @server_thread.terminate
  end

  describe "COMMAND: with_lock" do
    before do
      @client = Officer::Client.new
    end

    after do
      @client.send("disconnect")
      @client = nil
    end

    it "should allow a client to request and release a lock using block syntax" do
      @client.with_lock("testlock") do
        @client.my_locks.should eq({"value"=>["testlock"], "result"=>"locks"})
      end
    end
  end

  describe "COMMAND: reset" do
    before do
      @client = Officer::Client.new
    end

    after do
      @client.send("disconnect")
      @client = nil
    end

    it "should allow a client to reset all of its locks (release them all)" do
      @client.lock("testlock1")
      @client.lock("testlock2")
      @client.my_locks.should eq({"value"=>["testlock1", "testlock2"], "result"=>"locks"})
      @client.reset
      @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
    end
  end

  describe "COMMAND: reconnect" do
    before do
      @client = Officer::Client.new
    end

    after do
      @client.send("disconnect")
      @client = nil
    end

    it "should allow a client to force a reconnect in order to get a new socket" do
      original_socket = @client.instance_variable_get("@socket")
      @client.reconnect
      @client.instance_variable_get("@socket").should_not eq(original_socket)
      @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
    end
  end

  describe "COMMAND: connections" do
    before do
      @client1 = Officer::Client.new
      @client2 = Officer::Client.new

      @client1_src_port = @client1.instance_variable_get('@socket').addr[1]
      @client2_src_port = @client2.instance_variable_get('@socket').addr[1]

      @client1.lock("client1_testlock1")
      @client1.lock("client1_testlock2")
      @client2.lock("client2_testlock1")
      @client2.lock("client2_testlock2")
    end

    after do
      @client1.send("disconnect")
      @client1 = nil
      @client2.send("disconnect")
      @client2 = nil
    end

    it "should allow a client to see all the connections to a server" do
      connections = @client2.connections

      connections["value"]["127.0.0.1:#{@client1_src_port}"].should eq(["client1_testlock1", "client1_testlock2"])
      connections["value"]["127.0.0.1:#{@client2_src_port}"].should eq(["client2_testlock1", "client2_testlock2"])
      connections["value"].keys.length.should eq(2)
      connections["result"].should eq("connections")
    end
  end

  describe "COMMAND: locks" do
    before do
      @client1 = Officer::Client.new
      @client2 = Officer::Client.new

      @client1_src_port = @client1.instance_variable_get('@socket').addr[1]
      @client2_src_port = @client2.instance_variable_get('@socket').addr[1]

      @client1.lock("client1_testlock1")
      @client1.lock("client1_testlock2")
      @client2.lock("client2_testlock1")
      @client2.lock("client2_testlock2")
    end

    after do
      @client1.send("disconnect")
      @client1 = nil
      @client2.send("disconnect")
      @client2 = nil
    end

    it "should allow a client to see all the locks on a server (including those owned by other clients)" do
      locks = @client2.locks

      locks["value"]["client1_testlock1"].should eq(["127.0.0.1:#{@client1_src_port}"])
      locks["value"]["client1_testlock2"].should eq(["127.0.0.1:#{@client1_src_port}"])
      locks["value"]["client2_testlock1"].should eq(["127.0.0.1:#{@client2_src_port}"])
      locks["value"]["client2_testlock2"].should eq(["127.0.0.1:#{@client2_src_port}"])
      locks["value"].length.should eq(4)
      locks["result"].should eq("locks")
    end
  end

  describe "COMMAND: my_locks" do
    before do
      @client = Officer::Client.new
    end

    after do
      @client.send("disconnect")
      @client = nil
    end

    it "should allow a client to request its locks" do
      @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
    end
  end

  describe "COMMAND: lock & unlock" do
    describe "basic functionality" do
      before do
        @client = Officer::Client.new
      end

      after do
        @client.send("disconnect")
        @client = nil
      end

      it "should allow a client to request and release a lock" do
        @client.lock("testlock").should eq({"result" => "acquired", "name" => "testlock"})
        @client.my_locks.should eq({"value"=>["testlock"], "result"=>"locks"})
        @client.unlock("testlock")
        @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
      end
    end

    describe "locking options" do
      describe "OPTION: timeout" do
        before do
          @client1 = Officer::Client.new
          @client2 = Officer::Client.new

          @client1_src_port = @client1.instance_variable_get('@socket').addr[1]
          @client2_src_port = @client2.instance_variable_get('@socket').addr[1]

          @client1.lock("testlock")
        end

        after do
          @client1.send("disconnect")
          @client1 = nil
          @client2.send("disconnect")
          @client2 = nil
        end

        it "should allow a client to set an instant timeout when obtaining a lock" do
          @client2.lock("testlock", :timeout => 0).should eq(
            {"result"=>"timed_out", "name"=>"testlock", "queue"=>["127.0.0.1:#{@client1_src_port}"]}
          )
        end

        it "should allow a client to set a positive integer timeout when obtaining a lock" do
          time = Benchmark.realtime do
            @client2.lock("testlock", :timeout => 1).should eq(
              {"result"=>"timed_out", "name"=>"testlock", "queue"=>["127.0.0.1:#{@client1_src_port}"]}
            )
          end
          time.should > 1
          time.should < 1.5
        end
      end

      describe "OPTION: queue_max" do
        before do
        end

        after do
          @thread1.terminate
          @thread2.terminate
        end

        it "should allow a client to abort when obtaining a lock if too many other clients are waiting for the same lock" do
          @client1 = Officer::Client.new
          @client1.lock("testlock")

          @thread1 = Thread.new {
            @client2 = Officer::Client.new
            @client2.lock("testlock")
            raise "This should never execute since the lock request should block"
          }

          @thread2 = Thread.new {
            @client3 = Officer::Client.new
            @client3.lock("testlock")
            raise "This should never execute since the lock request should block"
          }

          sleep(0.25)  # Allow thread 1 & 2 time to run.

          @thread1.status.should eq("sleep")
          @thread2.status.should eq("sleep")

          client1_src_port = @client1.instance_variable_get('@socket').addr[1]
          client2_src_port = @client2.instance_variable_get('@socket').addr[1]
          client3_src_port = @client3.instance_variable_get('@socket').addr[1]

          @client4 = Officer::Client.new
          @client4.lock("testlock", :queue_max => 3).should eq(
            {"result" => "queue_maxed", "name" => "testlock", "queue" =>
              ["127.0.0.1:#{client1_src_port}", "127.0.0.1:#{client2_src_port}", "127.0.0.1:#{client3_src_port}"]}
          )
        end
      end

      describe "OPTION: namespace" do
        before do
          @client = Officer::Client.new(:namespace => "myapp")
        end

        after do
          @client.send("disconnect")
          @client = nil
        end

        it "should allow a client to set a namespace when obtaining a lock" do
          @client.with_lock("testlock") do
            @client.locks["value"]["myapp:testlock"].should_not eq(nil)
          end
        end
      end
    end
  end
end
