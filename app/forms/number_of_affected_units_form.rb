class NumberOfAffectedUnitsForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serialization

  attribute :investigation_product_id # When used in conjunction with `MultipleNumberOfAffectedUnitsForm`
  attribute :exact_units
  attribute :approx_units
  attribute :affected_units_status
  attribute :number_of_affected_units

  validates :affected_units_status, inclusion: { in: InvestigationProduct.affected_units_statuses.keys }
  validates :approx_units, presence: { message: "Enter how many units are affected" }, if: -> { affected_units_status == "approx" }
  validates :exact_units, presence: { message: "Enter how many units are affected" }, if: -> { affected_units_status == "exact" }

  def self.from(investigation_product)
    new(investigation_product.serializable_hash.slice("number_of_affected_units", "affected_units_status")).tap do |investigation_product_form|
      if investigation_product.affected_units_status == InvestigationProduct.affected_units_statuses["approx"]
        investigation_product_form.approx_units = investigation_product.number_of_affected_units
      elsif investigation_product.affected_units_status == InvestigationProduct.affected_units_statuses["exact"]
        investigation_product_form.exact_units = investigation_product.number_of_affected_units
      end
      investigation_product_form.investigation_product_id = investigation_product.id
    end
  end

  def number_of_affected_units
    return if affected_units_status.blank?

    case affected_units_status
    when "exact"
      exact_units
    when "approx"
      approx_units
    end
  end
end
