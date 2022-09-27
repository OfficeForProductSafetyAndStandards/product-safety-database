class ChangeBatchNumber
  include Interactor
  include EntitiesToNotify

  delegate :investigation_product, :batch_number, :user, to: :context

  def call
    context.fail!(error: "No investigation product supplied") unless investigation_product.is_a?(InvestigationProduct)
    context.fail!(error: "No batch number supplied") unless batch_number.is_a?(String)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation_product.assign_attributes(batch_number: batch_number)
    return if investigation_product.changes.none?

    ActiveRecord::Base.transaction do
      investigation_product.save!
      create_audit_activity_for_batch_number_changed
    end
  end

private

  def create_audit_activity_for_batch_number_changed
    metadata = activity_class.build_metadata(investigation_product)

    activity_class.create!(
      source: UserSource.new(user:),
      investigation: investigation_product.investigation,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def activity_class
    AuditActivity::Investigation::UpdateBatchNumber
  end
end
