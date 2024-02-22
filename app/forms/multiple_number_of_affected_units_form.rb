class MultipleNumberOfAffectedUnitsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :number_of_affected_units_forms

  def initialize(*)
    self.number_of_affected_units_forms = []
    super
  end

  def self.from(investigation_products)
    new.tap do |f|
      f.number_of_affected_units_forms = investigation_products.map do |investigation_product|
        NumberOfAffectedUnitsForm.from(investigation_product)
      end
    end
  end

  def number_of_affected_units_forms_attributes=(attributes)
    attributes.each do |_i, number_of_affected_units_forms_params|
      @number_of_affected_units_forms.push(NumberOfAffectedUnitsForm.new(number_of_affected_units_forms_params))
    end
  end

  def valid?
    children_valid = number_of_affected_units_forms.map(&:valid?).all?
    number_of_affected_units_forms.each_with_index do |number_of_affected_units_form, i|
      number_of_affected_units_form.errors.each do |error|
        errors.import(error, { attribute: "number_of_affected_units_forms_attributes[#{i}].#{error.attribute}".to_sym })
      end
    end
    children_valid
  end

  def formatted_error_messages
    messages = errors.map do |error|
      index = error.attribute.to_s.split("[").last.split("]").first.to_i
      investigation_product_id = number_of_affected_units_forms[index].investigation_product_id.to_i
      product_name = investigation_products[investigation_product_id].product.name_with_brand
      [error.attribute, "#{product_name}: #{error.message}"]
    end

    OpenStruct.new(formatted_error_messages: messages)
  end

private

  def investigation_products
    @investigation_products ||= InvestigationProduct.joins(:product).where(id: number_of_affected_units_forms.map(&:investigation_product_id)).decorate.index_by(&:id)
  end
end
