require 'spec_helper'

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true # TODO: Record 3space later
  c.cassette_library_dir = 'spec/cassettes'
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
  c.hook_into :webmock
  c.ignore_host 'bad.host'
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

