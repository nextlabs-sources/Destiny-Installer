#
# Author:: Duan Shiqiang
#
# Copyright (C) 2016, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#
require 'spec_helper'

describe 'ControlCenter::bootstrap' do

  let(:chef_run) { ChefSpec::SoloRunner.new } # Notice we don't converge here

  before {
    ENV['START_DIR'] = ::File.expand_path('../../../..', __FILE__)
  }

  context 'when install' do

    before {
      chef_run.node.set['installation_mode'] = 'install'
    }

    it "installation_dir's should have 'PolicyServer' append if its base name is not 'PolicyServer'" do

      chef_run.node.set['installation_dir'] = '/path/to/installation_dir'
      chef_run.converge(described_recipe)
      expect(chef_run.node['installation_dir']).to eq('/path/to/installation_dir/PolicyServer')

    end

    it "installation_dir should be as it is if its base name is already 'PolicyServer'" do
      chef_run.node.set['installation_dir'] = '/path/to/PolicyServer'
      puts chef_run.node['installation_dir']
      chef_run.converge(described_recipe)
      expect(chef_run.node['installation_dir']).to eq('/path/to/PolicyServer')
    end

    it 'should have necessary folders created' do
      chef_run.node.set['installation_dir'] = '/path/to/PolicyServer'
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/path/to/PolicyServer')
      expect(chef_run).to create_directory(chef_run.node['log_dir'])
    end

  end

  context 'when upgrade|remove: installation_dir' do

    let(:existing_installation_dir) { '/path/to/existing_installation_dir' }

    before {
      # first we specified a value for installation_dir
      chef_run.node.set['installation_dir'] = '/path/to/installation_dir'
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)
      # stub the check for directory existing
      # refer: http://stackoverflow.com/questions/9972964/rspec-stubbing-method-for-only-specific-arguments
      allow(::File).to receive(:directory?).and_call_original
      allow(::File).to receive(:directory?).with(existing_installation_dir).and_return(true)
    }

    it 'remove: user specified installation dir should be ignored' do
      chef_run.node.set['installation_mode'] = 'remove'
      chef_run.converge(described_recipe)
      expect(chef_run.node['installation_dir']).to eq(existing_installation_dir)
    end

    it 'upgrade: user specified installation dir should be ignored' do
      chef_run.node.set['installation_mode'] = 'upgrade'
      chef_run.converge(described_recipe)
      expect(chef_run.node['installation_dir']).to eq(existing_installation_dir)
    end

  end

end