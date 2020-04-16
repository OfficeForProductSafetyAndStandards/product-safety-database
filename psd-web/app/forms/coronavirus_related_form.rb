class CoronavirusRelatedForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :coronavirus_related, :boolean, default: nil

  validates :coronavirus_related,
            inclusion: { in: [true, false], message: I18n.t(".coronavirus_related_form.inclusion") }
end
