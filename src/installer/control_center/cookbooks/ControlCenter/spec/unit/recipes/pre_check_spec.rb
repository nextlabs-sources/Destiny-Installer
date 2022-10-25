#
# Author:: Duan Shiqiang
#
# Copyright (C) 2016, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#
require 'spec_helper'

describe 'ControlCenter::pre_check' do

  let(:chef_run) { ChefSpec::SoloRunner.new } # Notice we don't converge here
  let(:dependent_recipes) { ['ControlCenter::bootstrap'] }
  let(:existing_installation_dir) { '/path/to/existing_installation_dir' }
  let(:existing_installation_version) { '1.0' }
  let(:non_exist_dir) { '/non/exist/path' }

  before {
    ENV['START_DIR'] = ::File.expand_path('../../../..', __FILE__)
    chef_run.node.set['installation_dir'] = '/path/to/installation_dir'
    # stub the check for directory existing
    allow(::File).to receive(:directory?).and_call_original
    allow(::File).to receive(:directory?).with(non_exist_dir).and_return(false)
    allow(::File).to receive(:directory?).with(existing_installation_dir).and_return(true)
  }

  context 'when install: server port open' do
    before {
      chef_run.node.set['installation_mode'] = 'install'
      chef_run.node.set['web_service_port'] = 0 # any number
      allow(Server::Config).to receive(:port_open?).and_return(true);
    }

    it 'should raise error' do
      # refer to: https://github.com/sethvargo/chefspec/issues/489#issuecomment-53726672
      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end
  end

  context 'when install|upgrade: disk space not enough' do

    it 'install should raise error' do
      chef_run.node.set['installation_mode'] = 'install'
      # server port should not disturb the test case
      allow(Server::Config).to receive(:port_open?).and_return(false);
      allow(Server::Config).to receive(:disk_space_available?).and_return(false);

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'upgrade should raise error' do
      chef_run.node.set['installation_mode'] = 'upgrade'
      # upgrade doesn't check server port

      allow(Server::Config).to receive(:disk_space_available?).and_return(false);
      # stub the existing server check
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return(existing_installation_version)
      chef_run.node.set['supported_upgrade_versions'] = [existing_installation_version]
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'remove should not raise error' do
      chef_run.node.set['installation_mode'] = 'remove'
      # remove doesn't check server port

      # stub the existing server check
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return(existing_installation_version)
      chef_run.node.set['supported_remove_versions'] = [existing_installation_version]
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.not_to raise_error
    end

  end

  context 'when install: existing server' do

    before {
      chef_run.node.set['installation_mode'] = 'install'
      allow(Server::Config).to receive(:get_current_server_version).and_return(0)
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)
      # server port should not disturb the test case
      allow(Server::Config).to receive(:port_open?).and_return(false);
      allow(Server::Config).to receive(:disk_space_available?).and_return(false);
      # disk space should not disturb the test case
      allow(Server::Config).to receive(:disk_space_available?).and_return(true);
    }

    it 'should raise error if has existing server' do
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'should not raise error if no existing server found' do
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(false)
      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.not_to raise_error
    end

  end

  context 'when upgrade|remove: existing server' do

    before {
      # upgrade and remove doesn't check server port
      # disk space should not disturb the test case
      allow(Server::Config).to receive(:disk_space_available?).and_return(true);
    }

    it 'remove should raise error if no existing server found' do
      chef_run.node.set['installation_mode'] = 'remove'
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(false)
      allow(Server::Config).to receive(:get_current_server_version).and_return(0)
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(nil)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'upgrade should raise error if no existing server found' do
      chef_run.node.set['installation_mode'] = 'upgrade'
      allow(Server::Config).to receive(:has_any_server_installed?).and_return(false)
      allow(Server::Config).to receive(:get_current_server_version).and_return(0)
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(nil)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'upgrade should raise error if existing server version not supported' do
      chef_run.node.set['installation_mode'] = 'upgrade'
      chef_run.node.set['supported_upgrade_versions'] = [ '2.0' ]

      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return('1.0') # as long as not same as '2.0'
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'remove should raise error if existing server version not supported' do
      chef_run.node.set['installation_mode'] = 'remove'
      chef_run.node.set['supported_remove_versions'] = [ '2.0' ]

      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return('1.0') # as long as not same as '2.0'
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(existing_installation_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'upgrade should raise error is existing server location not exist' do
      chef_run.node.set['installation_mode'] = 'upgrade'
      chef_run.node.set['supported_remove_versions'] = [ existing_installation_version ]

      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return(existing_installation_version)
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(non_exist_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'remove should raise error is existing server location not exist' do
      chef_run.node.set['installation_mode'] = 'remove'
      chef_run.node.set['supported_remove_versions'] = [ existing_installation_version ]

      allow(Server::Config).to receive(:has_any_server_installed?).and_return(true)
      allow(Server::Config).to receive(:get_current_server_version).and_return(existing_installation_version)
      allow(Server::Config).to receive(:get_current_installation_dir).and_return(non_exist_dir)

      expect{ chef_run.converge(*(dependent_recipes + [described_recipe])) }.to raise_error(RuntimeError)
    end

    it 'remove should raise error is existing sever service running' do
      #TODO
    end

    it 'upgrade should raise error is existing sever service running' do
      #TODO
    end

  end

  context 'when install: advance checks' do

    it 'should raise error if DB check is enabled and won\'t pass' do
      #TODO
    end

    it 'should not raise error if DB check is enabled and will pass' do
      #TODO
    end

    it 'should not raise error if DB check is disabled' do
      #TODO
    end

    it 'should raise error if SMTP check is enabled and won\'t pass' do
      #TODO
    end

    it 'should not raise error if SMTP check is enabled and will pass' do
      #TODO
    end

    it 'should not raise error if SMTP check is disabled' do
      #TODO
    end

  end

end
