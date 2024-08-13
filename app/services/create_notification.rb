class CreateNotification
  include Interactor

  delegate :notification, :user, :product, :prism_risk_assessment, :bulk, :from_task_list, to: :context

  def call
    context.fail!(error: "No notification supplied") unless notification.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Product must be supplied for non opss users") if !bulk && !from_task_list && !user.is_opss? && !product.is_a?(Product)
    team = user.team

    notification.creator_user = user
    notification.creator_team = team
    notification.notifying_country = team.country
    notification.state = "submitted" unless from_task_list || bulk

    ActiveRecord::Base.transaction do
      # This ensures no other pretty_id generation is happening concurrently.
      # The ID 1 needs to uniquely identify the type of action (in this case
      # case saving) but this is currently not implemented elsewhere
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(1)")

      notification.pretty_id = generate_pretty_id

      notification.build_owner_collaborations_from(user)

      notification.save!

      AddProductToNotification.call!(notification:, product:, user:, skip_email: true) if product

      AddPrismRiskAssessmentToNotification.call!(notification:, product:, prism_risk_assessment:, user:) if prism_risk_assessment

      create_audit_activity_for_case_added
    end

    send_confirmation_email unless context.silent
  end

private

  def generate_pretty_id
    "#{date.strftime('%y%m')}-#{latest_case_number_this_month.next}"
  end

  def create_audit_activity_for_case_added
    activity_class = notification.case_created_audit_activity_class
    metadata = activity_class.build_metadata(notification)

    activity_class.create!(
      added_by_user: user,
      investigation: notification,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def send_confirmation_email
    NotifyMailer.notification_created(
      notification.pretty_id,
      user.name,
      user.email,
      notification.decorate.title,
      "notification"
    ).deliver_later
  end

  def date
    Time.zone.now
  end

  def latest_case_number_this_month
    case_number = Investigation.select(:pretty_id)
      .where("created_at < ? AND created_at > ?", date, date.beginning_of_month)
      .order(:id).last&.pretty_id

    return "0000" unless case_number

    case_number.split("-").last
  end
end
