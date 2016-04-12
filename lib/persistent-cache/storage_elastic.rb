require "persistent-cache/version"
require "persistent-cache/storage_api"
require 'eh/eh'

require 'elasticsearch'
require 'elasticsearch-api'

module Persistent
  class StorageElastic < Persistent::Storage::API
    attr_accessor :storage_details
    attr_accessor :storage

    def initialize(storage_details = nil)
      @storage_details = {
          host: 'http://localhost:9200/',
          transport_options: {
              request: {timeout: 5}
          },
          index: 'persistent_cache',
          type:'entry'
      }

      @storage_details.merge!(storage_details)  if storage_details
      @storage = Elasticsearch::Client.new(@storage_details)
    end

    def is_elastic_available
      status = @storage.cluster.health['status']
      return status != 'red'
    end

    def save_key_value_pair(key, value, timestamp = nil)
      delete_entry(key)
      time_entry = timestamp.nil? ? Time.now.to_s : timestamp.to_s
      EH::retry!(:args => [key, value, time_entry]) do
        #@storage[key] = {:value => value, :timestamp => time_entry}
        @storage.create index: @storage_details[:index], type: @storage_details[:type], id: key.to_s, body: { value: value, timestamp: time_entry}
      end
    end

    def lookup_key(key)
      begin
        EH::retry!(:args => [key]) do
          result = @storage.get index: @storage_details[:index], type: @storage_details[:type], id: key.to_s
          {value: result['_source']['value'],  timestamp: result['_source']['timestamp']}
        end
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        []
      end
    end

    def delete_entry(key)
      begin
        EH::retry!(:args => [key]) do
          @storage.delete index: @storage_details[:index], type: @storage_details[:type], id: key.to_s
        end
      rescue   Elasticsearch::Transport::Transport::Errors::NotFound
        # don't raise an error
      end
    end

    def size
      EH::retry!(:args => []) do
        @storage.count(index: @storage_details[:index])['count']
      end
    end

    def keys
      keys = []
      EH::retry!(:args => []) do
        response = @storage.search index:  @storage_details[:index], search_type: 'scan', scroll: '5m', size: 10
        # Call `scroll` until results are empty
        while response = @storage.scroll(scroll_id: response['_scroll_id'], scroll: '5m') and not response['hits']['hits'].empty? do
          keys.push response['hits']['hits'].map { |r| r['_id'] }
        end
      end
      return keys
    end

    def clear
      EH::retry!(:args => []) do
        @storage.indices.delete index: @storage_details[:index] rescue nil
        @storage.indices.create index: @storage_details[:index]
      end
    end
  end
end
