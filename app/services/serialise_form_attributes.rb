class SerialiseFormAttributes
  include Interactor

  delegate :form, :form_serializable_hash_arguments, to: :context

  def call
    context.serialised_form_attributes = OpenStruct.new(form.serializable_hash(*serializable_hash_arguments))
  end

  def serializable_hash_arguments
    form_serializable_hash_arguments || []
  end
end
