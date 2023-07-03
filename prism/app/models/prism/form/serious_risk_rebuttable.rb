module Prism
  module Form
    class SeriousRiskRebuttable
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :less_than_serious_risk, :boolean
      attribute :description, :string

      validates :less_than_serious_risk, inclusion: [true, false]
      validates :description, presence: true, if: -> { less_than_serious_risk == true }
    end
  end
end
