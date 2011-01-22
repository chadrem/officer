require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Officer do
  before do
    @server_thread = Thread.new do
      Officer::Server.new.run
    end
  end

  after do
    @server_thread.terminate
  end

  context "single client tests" do
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

    it "should allow a client to request and release a lock using non-block syntax" do
      @client.lock("testlock")
      @client.my_locks.should eq({"value"=>["testlock"], "result"=>"locks"})
      @client.unlock("testlock")
      @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
    end

    it "should allow a client to request and release a lock using block syntax" do
      @client.with_lock("testlock") do
        @client.my_locks.should eq({"value"=>["testlock"], "result"=>"locks"})
      end
    end

    it "should allow a client to reset all of its locks (release them all)" do
      @client.lock("testlock1")
      @client.lock("testlock2")
      @client.my_locks.should eq({"value"=>["testlock1", "testlock2"], "result"=>"locks"})
      @client.reset
      @client.my_locks.should eq({"value"=>[], "result"=>"locks"})
    end
  end

  context "multi-client tests" do
    before do
      @client1 = Officer::Client.new
      @client2 = Officer::Client.new
    end

    after do
      @client1.send("disconnect")
      @client1 = nil
      @client2.send("disconnect")
      @client2 = nil
    end

    it "should allow a client to see all the locks on a server (including those owned by other clients)" do
      @client1.lock("client1_testlock1")
      @client1.lock("client1_testlock2")
      @client2.lock("client2_testlock1")
      @client2.lock("client2_testlock2")
      # @client2.locks.should eq(false)
    end
  end
end
