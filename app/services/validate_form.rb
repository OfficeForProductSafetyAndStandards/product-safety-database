class ValidateForm
  include Interactor

  delegate :form, to: :context

  def call
    context.fail!(error: form.errors.full_messages.to_sentence) if form.invalid?
  end
end
