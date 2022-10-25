#
# Author:: Duan Shiqiang
#
# Copyright (C) 2016, Nextlabs Inc.
#
# All rights reserved - Do Not Redistribute
#
require 'spec_helper'

describe Utility::SMTP do
  describe 'test SMTP connection' do

    context 'success' do
      let(:response) { double(success?: true) }
      let(:net_smtp) { double(start: nil, auth_login: response, started?: true, finish: nil, ) }

      before {
        allow(Net::SMTP).to receive(:new).and_return(net_smtp)
      }

      it 'should be success' do
        expect(Utility::SMTP.test_SMTP_connection(nil, nil, nil, nil)).to be(true);
      end

    end

    context 'failed' do
      let(:response) { double(success?: false) }
      let(:net_smtp) { double(start: nil, auth_login: response, started?: true, finish: nil, ) }

      before {
        allow(Net::SMTP).to receive(:new).and_return(net_smtp)
      }

      it 'should be failed' do
        expect(Utility::SMTP.test_SMTP_connection(nil, nil, nil, nil)).to be(false);
      end
    end

    context 'failed with exception' do
      let(:net_smtp) { double(start: nil, started?: false ) }
      let(:error) { Exception.new('failed to auth the server') }

      before {
        allow(net_smtp).to receive(:auth_login).and_raise(error)
        allow(Net::SMTP).to receive(:new).and_return(net_smtp)
      }

      it 'should raise error' do
        expect{ Utility::SMTP.test_SMTP_connection(nil, nil, nil, nil) }.to raise_error(error)
      end

    end

    context 'failed with timeout' do
      let(:net_smtp) { double(start: nil, started?: true, finish: nil )}

      before {
        allow(net_smtp).to receive(:auth_login) do
          # sleep a bit longer than the timeout
          sleep 3
        end
        allow(Net::SMTP).to receive(:new).and_return(net_smtp)
      }

      it 'should timeout' do
        expect{ Utility::SMTP.test_SMTP_connection(nil, nil, nil, nil, 2) }.to raise_error(Timeout::Error)
      end

    end

  end
end