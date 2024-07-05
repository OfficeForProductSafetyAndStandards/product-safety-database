# frozen_string_literal: true

class SearchForOrAddABusinessForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :add_another_business
  validates :add_another_business, presence: true
end
