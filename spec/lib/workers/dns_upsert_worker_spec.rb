require 'spec_helper'
require_lib 'workers'

describe Evercam::DNSUpsertWorker do

  subject { Evercam::DNSUpsertWorker }

  it 'delegates the update to ZoneManager' do
    Evercam::DNS::ZoneManager.any_instance.
      expects(:update).with('abcd', '1234')

    subject.new.perform('abcd', '1234')
  end

end

