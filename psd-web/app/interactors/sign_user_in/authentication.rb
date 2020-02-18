class SignUserIn
  class Authentication
    include Interactor

    delegate :resource, :warden, to: :context

    def call
      authenticated_resource = warden.authenticate(context.auth_options)

      if authenticated_resource
        context.resource = authenticated_resource
      else
        resource.errors.add(:email, "Enter correct email address and password")
        context.fail!
      end
    end
  end
end
