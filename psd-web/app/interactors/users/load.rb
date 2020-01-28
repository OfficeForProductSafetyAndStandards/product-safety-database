module Users
  class Load
    extend ActiveModel::Naming
    include Interactor

    def call
      context.user = user_service.user
    rescue RuntimeError => e
      Raven.capture_exception(e)
      errors.add(:base, e.message)
      context.fail!(errors: errors)
    end

  private

    def user_service
      CreateUserFromAuth.new(context.omniauth_response)
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end
  end
end
