module Users
  class Load
    extend ActiveModel::Naming
    include Interactor

    def call
      context.user = context.user_service.user
    rescue RuntimeError => e
      Raven.capture_exception(e)
      errors.add(:base, e.message)
      context.fail!(errors: errors)
    end

  private

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end
  end
end
