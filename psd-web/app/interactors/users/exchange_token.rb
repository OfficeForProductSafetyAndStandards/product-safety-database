module Users
  class ExchangeToken
    extend ActiveModel::Naming
    include Interactor

    def call
      store_authentication(auth_token)
    rescue Keycloak::KeycloakException
      raise
    rescue StandardError => e
      Raven.capture_exception(e)
      errors.add(:base, e.message)
      context.fail!(errors: errors)
    end

  private

    def auth_token
      user_signed_in? ? context.omniauth_response : refresh_token
    end

    def user_signed_in?
      KeycloakClient.instance.user_signed_in?(access_token)
    end

    def api_client
      KeycloakClient.instance
    end

    def refresh_token
      api_client.exchange_refresh_token_for_token(
        context.dig("omniauth_response", "credentials", "refresh_token")
      )
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def access_token
      keycloak_tokens_store["access_token"] || context.omniauth_response
    end

    def store_authentication(authentication)
      context.keycloak_tokens_store[cookie_name] = { value: authentication.to_json, httponly: true }
    end

    def keycloak_tokens_store
      return {} if context.keycloak_tokens_store[cookie_name].nil?

      JSON.parse(context.keycloak_tokens_store[cookie_name])
    end

    def cookie_name
      :"keycloak_token_#{ENV["KEYCLOAK_CLIENT_ID"]}"
    end
  end
end
