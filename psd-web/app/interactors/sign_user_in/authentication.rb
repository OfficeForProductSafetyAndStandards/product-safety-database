class SignUserIn
  class Authentication
    include Interactor

    delegate :resource, :warden, to: :context

    def call
      authenticated_resource = warden.authenticate(context.auth_options)

      if authenticated_resource
        context.resource = authenticated_resource
      else
        resource.errors.clear
        resource.errors.add(:base, I18n.t(:wrong_email_or_password, scope: "sign_user_in.email"))
        context.fail!
      end
    end
  end
end
