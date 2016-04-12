# Persistent::StorageElastic

This gem provides an elastic search storage back-end to Persistent::Cache. Please see https://rubygems.org/gems/persistent-cache.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'persistent-cache-storage-elastic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install persistent-cache-storage-elastic

## Usage

TBD

Tell Persistent::Cache to use this provider so:

    require 'persistent-cache/storage_elastic'
    require 'persistent-cache'

    storage_details = { 'tbd' => 'to be provided' }
    freshness = nil # forever or freshness in seconds
    cache = Persistent::Cache.new(storage_location, freshness, Persistent::Cache::STORAGE_ELASTIC)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/evangraan/persistent-cache-storage-elastic. This gem was sponsored by Hetzner (Pty) Ltd - http://hetzner.co.za

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

