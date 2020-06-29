class CreateCase
  include Interactor

  delegate :investigation, :user, to: :context

  def call
    context.fail!(error: "No investigation supplied") unless investigation.is_a?(Investigation)
    context.fail!(error: "No user supplied") unless user.is_a?(User)

    investigation.creator_user = user
    investigation.creator_team = user.team

    ActiveRecord::Base.transaction do
      # This ensures no other pretty_id generation is happenning concurrently.
      # The ID 1 needs to uniquely identify the type of action (in this case
      # case saving) but this is currently not implemented elsewhere
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(1)")

      investigation.pretty_id = generate_pretty_id

      investigation.build_owner_user_collaboration(collaborator: user)
      investigation.build_owner_team_collaboration(collaborator: user.team)

      investigation.save!

      create_audit_activity_for_case_added

      # When a case is created we don't want to send notification emails as in
      # the AddProductToCase service
      investigation.products.each do |product|
        create_audit_activity_for_product_added(product)
      end
    end

    send_confirmation_email
  end

private

  def generate_pretty_id
    sprintf("#{date.strftime('%y%m')}-%04d", (number_of_cases_this_month + 1))
  end

  def create_audit_activity_for_case_added
    activity_class = investigation.case_created_audit_activity_class
    metadata = activity_class.build_metadata(investigation)

    activity_class.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: nil,
      body: nil,
      metadata: metadata
    )
  end

  def create_audit_activity_for_product_added(product)
    AuditActivity::Product::Add.create!(
      source: UserSource.new(user: user),
      investigation: investigation,
      title: product.name,
      product: product
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

  def number_of_cases_this_month
    Investigation.where("created_at < ? AND created_at > ?", date, date.beginning_of_month).count
  end
end
