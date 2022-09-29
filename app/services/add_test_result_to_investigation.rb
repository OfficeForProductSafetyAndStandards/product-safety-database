class AddTestResultToInvestigation
  include Interactor
  include EntitiesToNotify

  delegate :user, :investigation, :document, :date, :details, :legislation, :result, :standards_product_was_tested_against, :product_id, :failure_details, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    Test::Result.transaction do
      context.test_result = investigation.test_results.create!(
        date:,
        details:,
        legislation:,
        result:,
        failure_details:,
        standards_product_was_tested_against:,
        product_id:
      )

      context.test_result.document.attach(document)
      create_audit_activity
      email_team_with_access(investigation, user)
    end
  end

private

  def create_audit_activity
    AuditActivity::Test::Result.create!(
      added_by_user: user,
      investigation:,
      product: context.test_result.product,
      metadata: AuditActivity::Test::Result.build_metadata(context.test_result)
    )
  end

  def email_team_with_access(investigation, user)
    email_recipients_for_team_with_access(investigation, user).each do |entity|
      NotifyMailer.investigation_updated(
        investigation.pretty_id,
        entity.name,
        entity.email,
        "Test result was added to the #{investigation.case_type} by #{user.decorate.display_name(viewer: entity)}.",
        "#{investigation.case_type.upcase_first} updated"
      ).deliver_later
    end
  end
end
