class CreateInvestigation
  include Interactor

  delegate :investigation, :current_user, to: :context

  def call
    Investigation.transaction do
      build_case_creators
      build_case_owners

      context.investigation = investigation
      investigation.pretty_id = pretty_id
      investigation.save!

      investigation.create_audit_activity_for_case
    rescue StandardError => e
      raise e unless Rails.env.production?
      Raven.capture(e)
      context.fail!
    else
      send_confirmation_email
    end
  end

private

  def build_case_creators
    investigation.build_case_creator_team(collaborators_attributes(current_user.team))
    investigation.build_case_creator_user(collaborators_attributes(current_user))
  end

  def build_case_owners
    investigation.build_case_owner_team(collaborators_attributes(current_user.team))
    investigation.build_case_owner_user(collaborators_attributes(current_user))
  end

  def collaborators_attributes(collaborating)
    { added_by_user: current_user, include_message: false, collaborating: collaborating }
  end

  def pretty_id
    cases_before = Investigation.where("created_at < ? AND created_at > ?", Time.current, Time.current.beginning_of_month).count
    "#{Time.current.strftime('%y%m')}-%04d" % (cases_before + 1)
  end

  def send_confirmation_email
    NotifyMailer.investigation_created(
      investigation.pretty_id,
      current_user.name,
      current_user.email,
      investigation.title,
      investigation.case_type
    ).deliver_later
  end
end
