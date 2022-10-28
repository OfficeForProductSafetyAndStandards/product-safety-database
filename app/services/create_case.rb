class CreateCase
  include Interactor

  delegate :investigation, :user, :product, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)
    context.fail!(error: "Product must be supplied for non opss users") if !user.is_opss? && !product.is_a?(Product)
    team = user.team

    investigation.creator_user = user
    investigation.creator_team = team
    investigation.notifying_country = team.country

    ActiveRecord::Base.transaction do
      # This ensures no other pretty_id generation is happenning concurrently.
      # The ID 1 needs to uniquely identify the type of action (in this case
      # case saving) but this is currently not implemented elsewhere
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(1)")

      investigation.pretty_id = generate_pretty_id

      investigation.build_owner_collaborations_from(user)

      investigation.save!

      AddProductToCase.call!(investigation:, product:, user:, skip_email: true) if product

      create_audit_activity_for_case_added
    end

    send_confirmation_email
  end

private

  def generate_pretty_id
    "#{date.strftime('%y%m')}-#{latest_case_number_this_month.next}"
  end

  def create_audit_activity_for_case_added
    activity_class = investigation.case_created_audit_activity_class
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      added_by_user: user,
      investigation:,
      title: nil,
      body: nil,
      metadata:
    )
  end

  def send_confirmation_email
    NotifyMailer.investigation_created(
      investigation.pretty_id,
      user.name,
      user.email,
      investigation.decorate.title,
      investigation.case_type
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
