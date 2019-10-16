module Shared
  module Web
    class Token 
          
      REQUEST_HEADER = { 'Content-Type' => 'application/x-www-form-urlencoded' }.freeze

      def initialize(token_endpoint)
        self.token_endpoint = token_endpoint
      end

      def token
        return refresh! if access_token.nil? || expired?

        access_token
      end

      private
      attr_accessor :expires_at, :expires_in, :token_endpoint, :access_token

      def expired?
        expires_at < Time.now.to_i
      end

      def refresh!
        RestClient.post(token_endpoint, payload, REQUEST_HEADER) do |response, request, result|
          case response.code
          when 200..399
            json_response = JSON response.body
            self.expires_at = Time.now.to_i + json_response['expires_in']
            self.access_token = json_response['access_token']
          else
            response.return!
          end
        end
        access_token
      end

      def payload
        { 'client_id' => client_id,
        'client_secret' => secret,
        'grant_type' => 'client_credentials'
        }
      end

      def client_id
        ENV.fetch("KEYCLOAK_CLIENT_ID")
      end

      def secret
        ENV.fetch("KEYCLOAK_CLIENT_SECRET")
      end
    end 
  end
end

