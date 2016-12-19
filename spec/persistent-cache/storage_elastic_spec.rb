require 'spec_helper'
require 'time'
require 'elasticsearch'
require 'base64'

describe Persistent::StorageElastic do
  before :each do
    @test_key = "testkey"
    @test_value = "testvalue"
    @iut = Persistent::StorageElastic.new
    @iut.clear
  end

  context "when released" do
    it 'has a version number' do
      expect(Persistent::Storage::Elastic::VERSION).not_to be nil
    end
  end

  context "when constructed" do
    it "should be connected to a healthy cluster" do
      expect(@iut.storage.nil?).to eql(false)
      #expect(@iut.is_elastic_available).to eql(true)
    end
  end

  context "when asked to store a key value pair" do
    it "should store the key/value pair in Elasticsearch, with the current time as timestamp" do
      start_time = Time.now - 1
      @iut.save_key_value_pair((@test_key), (@test_value))
      result = @iut.lookup_key((@test_key))
      expect(result[:value]).to eql((@test_value))
      test_time = Time.parse(result[:timestamp])
      expect(test_time).to be > start_time
      expect(test_time).to be < start_time + 600
    end

    it "should store the key/value pair in Elasticsearch, with a timestamp specified" do
      test_time = (Time.now - 2500)
      @iut.save_key_value_pair((@test_key), (@test_value), test_time)
      result = @iut.lookup_key((@test_key))
      expect(result.nil?).to eql(false)
      expect(result[:value]).to eql((@test_value))
      time_retrieved = Time.parse(result[:timestamp])
      expect(time_retrieved.to_s).to eql(test_time.to_s)
    end

    it "should overwrite the existing key/value pair if they already exist" do
      @iut.save_key_value_pair((@test_key), (@test_value))
      @iut.save_key_value_pair((@test_key), ("testvalue2"))
      result = @iut.lookup_key((@test_key))
      expect(result[:value]).to eql(("testvalue2"))
    end

    it "should write plain string value when asked" do
      base64_encoded_storage = Persistent::StorageElastic.new(nil, true)
      base64_encoded_storage.clear

      value = 'bar'

      base64_encoded_storage.save_key_value_pair('foo', value)

      # read encoded value as plain text
      plain_storage = Persistent::StorageElastic.new(nil, false)

      result = plain_storage.lookup_key('foo')

      expect(result[:value]).to eql(value)
    end

    it "should write plain numeric value when asked" do
      value = 1

      # read encoded value as plain text
      plain_storage = Persistent::StorageElastic.new(nil, false)
      plain_storage.clear
      plain_storage.save_key_value_pair('foo', value)

      result = plain_storage.lookup_key('foo')

      expect(result[:value]).to eql(value)
    end
    
  it "should write base64 encoded string value when asked" do
    base64_encoded_storage = Persistent::StorageElastic.new(nil, true)
    base64_encoded_storage.clear

    value = 'bar'

    base64_encoded_storage.save_key_value_pair('foo', value)

    # read encoded value as plain text
    result = base64_encoded_storage.lookup_key('foo')

    expect(result[:value]).to eql(value)
  end

  it "should write  base64 encoded  numeric value when asked" do
    value = 1

    # read encoded value as plain text
    base64_encoded_storage = Persistent::StorageElastic.new(nil, true)
    base64_encoded_storage.clear
    base64_encoded_storage.save_key_value_pair('foo', value)

    result = base64_encoded_storage.lookup_key('foo')

    expect(result[:value]).to eql(value)
  end

end

  context "When looking up a value given its key" do
    it "should retrieve the value from Elasticsearch" do
      @iut.save_key_value_pair((@test_key), (@test_value))
      result = @iut.lookup_key((@test_key))
      expect(result[:value]).to eql((@test_value))
    end

    it "should retrieve the timestamp when the value was stored from Elasticsearch" do
      timestamp = Time.now.to_s
      @iut.save_key_value_pair((@test_key), (@test_value), timestamp)
      sleep 1
      result = @iut.lookup_key((@test_key))
      expect(result[:timestamp]).to eql(timestamp)
    end

    it "should return an empty array if a key is not in storage" do
      @iut.delete_entry((@test_key))
      result = @iut.lookup_key((@test_key))
      expect(result).to eql({})
    end
  end

  context "when asked to delete an entry" do
    it "should not raise an error if the entry is not present" do
      @iut.delete_entry(("shouldnotbepresent"))
    end

    it "should delete the entry if it is present" do
      @iut.save_key_value_pair((@test_key), (@test_value))
      result = @iut.lookup_key((@test_key))
      expect(result[:value]).to eql((@test_value))
      @iut.delete_entry((@test_key))
      result = @iut.lookup_key((@test_key))
      expect(result).to eql({})
    end
  end

  context "when asked the size of the Elasticsearch database" do
    it "should return 0 if the Elasticsearch database has no entries" do
      expect(@iut.size).to eql(0)
    end

    it "should return the number of entries" do
      populate_database(@iut)
      size = @iut.size
      expect(size).to eql(3)
    end
  end

  context "when asked for the keys in the Elasticsearch database" do
    it "should return an empty array if there are no entries in the Elasticsearch database" do
      expect(@iut.keys).to eql([])
    end

    it "should return the keys in the Elasticsearch database" do
      populate_database(@iut)
      keys = @iut.keys.flatten
      expect(keys.include?(("one"))).to eql(true)
      expect(keys.include?(("two"))).to eql(true)
      expect(keys.include?(("three"))).to eql(true)
      expect(@iut.size).to eql(3)
    end

    it "should return the keys in an array, with each key in its own sub-array" do
      populate_database(@iut)
      found = false
      test = 'one'
      keys = @iut.keys
      found = true if (@iut.keys[0][0] == test or @iut.keys[0][1] == test or @iut.keys[0][2] == test)
      expect(found).to eql(true)
    end
  end

  context "when asked to clear the Elasticsearch database" do
    it "should delete all entries in Elasticsearch" do
      populate_database(@iut)
      @iut.clear
      expect(@iut.size).to eql(0)
    end
  end

  def populate_database(iut)
    iut.save_key_value_pair(("one"), ("one"))
    iut.save_key_value_pair(("two"), ("two"))
    iut.save_key_value_pair(("three"), ("three"))
    iut.storage.indices.flush index: iut.storage_details[:index]
  end
end
