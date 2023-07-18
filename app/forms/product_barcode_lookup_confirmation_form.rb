class ProductBarcodeLookupConfirmationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :correct, :string
  validates :correct, inclusion: { in: %w[yes no] }

  def correct?
    correct == "yes"
  end
end
