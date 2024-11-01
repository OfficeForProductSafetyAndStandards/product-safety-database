module Prism
  module Form
    class SeriousRisk
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :product_id, :string
      attribute :risk_type, :string

      validates :risk_type, presence: true, inclusion: { in: %w[serious_risk normal_risk] }
    end
  end
end
