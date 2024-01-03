class DeleteNotification
  include Interactor

  delegate :notification, :deleted_by, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No deleted_by supplied") unless deleted_by.is_a?(User)
    context.fail!(error: "Cannot delete notification with products") unless Pundit.policy(deleted_by, notification).can_be_deleted?

    ActiveRecord::Base.transaction do
      notification.mark_as_deleted!
      notification.update!(deleted_by: deleted_by.id)
      notification.reindex
    end
  end
end
