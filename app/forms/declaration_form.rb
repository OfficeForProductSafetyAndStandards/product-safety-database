class DeclarationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :agree
  validates :agree, acceptance: true
end
