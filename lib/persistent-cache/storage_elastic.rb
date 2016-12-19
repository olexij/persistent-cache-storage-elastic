require 'net/http'
require "persistent-cache/version"
require "persistent-cache/storage_api"
require 'eh/eh'
require 'base64'
require 'json'
require 'elasticsearch'
require 'elasticsearch-api'

module Persistent
  class StorageElastic < Persistent::Storage::API
    attr_accessor :storage_details
    attr_accessor :storage
    attr_accessor :encode_value_base64

    def initialize(storage_details = nil, encode_value_base64 = true)
      # encode the value to avoid paarsing errors in Elasticsearch. Do not encode it if there will be no problems with special characters (see Elasticsearch documentation)
      @encode_value_base64 =encode_value_base64

      @storage_details = {
          host: 'http://localhost:9200/',
          transport_options: {
              request: {timeout: 5}
          },
          eh_options: {
             threshold: 1
          },
          index: 'persistent_cache',
          type:'entry'
      }

      @storage_details.merge!(storage_details)  if storage_details
      @storage = Elasticsearch::Client.new(@storage_details)

      if @encode_value_base64 # set the type of value to binary, do ti will be not parsed
      begin
        uri = URI( "#{@storage_details[:host]}/#{@storage_details[:index]}")
        http = Net::HTTP.new(uri.host, uri.port)
        req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        req.body = '{"mappings": { "#{@storage_details[:type]}"": { "properties": { "value": { "type": "binary"},  "timestamp": {"type": "string" } } } } }'
        http.request(req)
      rescue => e
        puts "failed #{e}"
      end
      end
    end

    def is_elastic_available
      status = @storage.cluster.health['status']
      return status != 'red'
    end

    def save_key_value_pair(key, value, timestamp = nil)
      delete_entry(key)
      time_entry = timestamp.nil? ? Time.now.to_s : timestamp.to_s
      EH::retry!(:args => [key, value, time_entry], :opts => @storage_details[:eh_options]) do
        json = value.to_json()
        value = Base64.encode64(json) if @encode_value_base64
        @storage.create index: @storage_details[:index], type: @storage_details[:type], id: key.to_s, body: { value:  json, timestamp: time_entry}
      end
    end

    def lookup_key(key)
      begin
        EH::retry!(:args => [key], :opts => @storage_details[:eh_options]) do
          result = @storage.get index: @storage_details[:index], type: @storage_details[:type], id: key.to_s
          value = Base64.decode64(result['_source']['value'])  if @encode_value_base64
          json = result['_source']['value']
          value = JSON::parse(json)
          {value:  value,  timestamp: result['_source']['timestamp']}
        end
      rescue Elasticsearch::Transport::Transport::Errors::NotFound
        {}
      end
    end

    def delete_entry(key)
      begin
        EH::retry!(:args => [key], :opts => @storage_details[:eh_options]) do
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
      EH::retry!(:args => [], :opts => @storage_details[:eh_options]) do
        response = @storage.search index:  @storage_details[:index], search_type: 'scan', scroll: '5m', size: 10
        # Call `scroll` until results are empty
        while response = @storage.scroll(scroll_id: response['_scroll_id'], scroll: '5m') and not response['hits']['hits'].empty? do
          keys.push response['hits']['hits'].map { |r| r['_id'] }
        end
      end
      return keys
    end

    def clear
      EH::retry!(:args => [], :opts => @storage_details[:eh_options]) do
        @storage.indices.delete index: @storage_details[:index] rescue nil
        @storage.indices.create index: @storage_details[:index]
      end
    end
  end
end
