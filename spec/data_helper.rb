require 'spec_helper'
require_relative '../lib/models'

# undo test data
RSpec.configure do |c|
  c.around(:each) do |e|
    db = Sequel::Model.db
    db.transaction(rollback: :always) do
      e.run
    end
  end
end

require 'factory_girl'
FactoryGirl.find_definitions

RSpec.configure do |c|
  c.include FactoryGirl::Syntax::Methods
end

# sequel uses #save
FactoryGirl.define do
  to_create { |m| m.save }
end

