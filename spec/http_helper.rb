require 'spec_helper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.default_cassette_options = { :record => :new_episodes }
  c.configure_rspec_metadata!
  c.hook_into :webmock
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end

