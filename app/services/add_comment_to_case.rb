class AddAccidentOrIncidentToCase
  include Interactor
  include EntitiesToNotify

  delegate :investigation, :body, :user, :comment, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    ActiveRecord::Base.transaction do
      CommentActivity.create!(
        body: body,
        investigation_id: investigation.id
      )
    end
  end
end
