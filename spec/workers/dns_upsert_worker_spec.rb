require 'spec_helper'

describe Evercam::DNSUpsertWorker do

  subject { Evercam::DNSUpsertWorker }

  it 'delegates the update to ZoneManager' do
    Evercam::DNS::ZoneManager.any_instance.
      expects(:update).with('abcd', '127.0.0.1')

    subject.new.perform('abcd', '127.0.0.1')
  end

  it 'resolves hostnames to ip addresses' do
    Evercam::DNS::ZoneManager.any_instance.
      expects(:update).with('abcd', '127.0.0.1')

    subject.new.perform('abcd', 'localhost')
  end

end

