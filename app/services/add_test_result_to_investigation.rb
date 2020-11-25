class AddTestResultToInvestigation
  include Interactor
  include EntitiesToNotify

  delegate :user, :investigation, :document, :date, :details, :legislation, :result, :standards_product_was_tested_against, :product_id, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    Test::Result.transaction do
      context.test_result = investigation.test_results.create!(
        date: date, details: details, legislation: legislation, result: result, standards_product_was_tested_against: standards_product_was_tested_against, product_id: product_id
      )
      context.test_result.document.attach(document.file)
      context.activity = create_audit_activity
    end
  end

private

  def create_audit_activity
    # email_recipients_for_team_with_access.each do |recipient|
    #   NotifyMailer.investigation_updated(
    #     investigation.pretty_id,
    #     entity.name,
    #     entity.email,
    #     email_update_text,
    #     activity.email_subject_text
    #   ).deliver_later
    # end
  end
end
