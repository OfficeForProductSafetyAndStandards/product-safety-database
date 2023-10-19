class BulkProductsCreateCaseForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name
  attribute :reference_number
  attribute :reference_number_provided, :boolean

  validates :name, presence: true, length: { maximum: 100 }
  validates :reference_number, presence: true, if: -> { reference_number_provided }
  validates :reference_number_provided, inclusion: { in: [true, false] }

  def self.from(bulk_products_upload)
    investigation = bulk_products_upload.investigation
    new(
      name: investigation.user_title,
      reference_number: investigation.complainant_reference,
      reference_number_provided: reference_number_provided?(investigation)
    )
  end

  private_class_method def self.reference_number_provided?(investigation)
    # Case name is mandatory, therefore if it is present then the user must
    # have also made a choice about whether or not to provide a reference,
    # as opposed to not making a choice at all.
    return if investigation.user_title.blank? && investigation.complainant_reference.blank?

    investigation.complainant_reference.present?
  end
end
