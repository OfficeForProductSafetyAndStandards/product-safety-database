class SignUserIn
  class FormValidator
    include Interactor

    delegate :sign_in_form, :resource, to: :context

    def call
      if sign_in_form.invalid?
        resource.errors.merge!(sign_in_form.errors)
        context.fail!
      end
    end
  end
end
