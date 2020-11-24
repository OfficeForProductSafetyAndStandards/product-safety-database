class TestResultForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :date, :govuk_date
  attribute :details
  attribute :legislastion
  attribute :result
  attribute :standard_product_was_tested_against, :comma_separated_list

end
