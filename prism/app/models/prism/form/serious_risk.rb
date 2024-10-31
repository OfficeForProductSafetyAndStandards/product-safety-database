module Prism
  module Form
    class SeriousRisk
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :risk_type, :string
      attribute :investigation_id, :integer
      attribute :product_id, :string
      attribute :product_ids, array: true

      attr_accessor :created_by_user_id
      attr_accessor :risk_assessment

      def persist!
        return false unless valid?

        ActiveRecord::Base.transaction do
          # Create risk assessment
          @risk_assessment = Prism::RiskAssessment.new(
            risk_type: risk_type,
            created_by_user_id: created_by_user_id
          )

          byebug

          return false unless @risk_assessment.save(context: :serious_risk)

          # Investigations/products
          if investigation_id.present? && product_ids.present?
            associated_investigation = @risk_assessment.associated_investigations.create!(
              investigation_id: investigation_id
            )
            product_ids.each do |pid|
              associated_investigation.associated_investigation_products.create!(
                product_id: pid
              )
            end
          elsif product_id.present?
            @risk_assessment.associated_products.create!(
              product_id: product_id
            )
            # Store product_id for later use in rebuttable step
            @current_product_id = product_id
          end

          true
        end
      end

      # Getter for current product ID to use in rebuttable step
      def current_product_id
        @current_product_id
      end
    end
  end
end