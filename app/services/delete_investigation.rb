class DeleteInvestigation
  include Interactor

  delegate :investigation, :deleted_by, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No deleted_by supplied") unless deleted_by.is_a?(User)
    context.fail!(error: "Cannot delete investigation with products") unless Pundit.policy(deleted_by, investigation).can_be_deleted?

    ActiveRecord::Base.transaction do
      investigation.mark_as_deleted!
      investigation.update!(deleted_by: deleted_by.id)

      investigation.__elasticsearch__.delete_document
    end
  end
end
