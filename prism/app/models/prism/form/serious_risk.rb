module Prism
  module Form
    class SeriousRisk
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :poses_a_serious_risk, :boolean

      validates :poses_a_serious_risk, inclusion: [true, false]
    end
  end
end
