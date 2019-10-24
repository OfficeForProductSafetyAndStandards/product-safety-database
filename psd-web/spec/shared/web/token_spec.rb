require 'spec_helper'

RSpec.describe Shared::Web::Token do
  before do
    allow(ENV).to receive(:fetch).with('KEYCLOAK_CLIENT_ID').and_return(client_id)
    allow(ENV).to receive(:fetch).with('KEYCLOAK_CLIENT_SECRET').and_return(client_secret)
  end

  let!(:request_for_token) do
    stub_request(:post, "http://#{token_endpoint}/").
      with(
        body: { 'client_id' => client_id, 'client_secret' => client_secret, 'grant_type' => 'client_credentials' },
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      ).
      to_return(status: returned_status, body: json_body, headers: {})
  end

  subject do
    described_class.new(token_endpoint)
  end

  let(:token_endpoint) { 'example.com' }
  let(:client_id) { '123' }
  let(:client_secret) { 'secret' }

  let(:json_body) do
    { expires_in: new_expires_in, access_token: new_token }.to_json
  end

  let(:new_expires_in) { 10 }
  let(:returned_status) { 200 }
  let(:new_token) { 'new-token-123' }

  describe '#access_token' do
    context 'no existing access token' do
      context 'request successful' do
        it 'gets a new token from Keycloak and returns it' do
          expect(subject.access_token).to eq(new_token)
          expect(request_for_token).to have_been_requested
        end
      end

      context 'request unsuccessful' do
        let(:returned_status) { 400 }

        it 'raises exception' do
          expect { subject.access_token }.to raise_exception(RestClient::BadRequest)
        end
      end
    end

    context 'existing access token' do
      before do
        subject.send(:token=, existing_token)
      end

      let(:existing_token) { 'existing-token-123' }

      context 'which is not expired' do
        before do
          subject.send(:expires_at=, Time.now.to_i + 10)
        end

        it 'returns the existing token without requesting from Keycloak' do
          expect(subject.access_token).to eq(existing_token)
          expect(request_for_token).not_to have_been_requested
        end
      end

      context 'which is expired' do
        before do
          subject.send(:expires_at=, Time.now.to_i - 10)
        end

        it 'gets a new token from Keycloak and returns it' do
          expect(subject.access_token).to eq(new_token)
          expect(request_for_token).to have_been_requested
        end
      end
    end
  end
end
