class InviteUserToTeamForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email
  attribute :team
  attribute :name

  validates :email, email: { if: ->(form) { form.email.present? } }
  validate :cannot_be_existing_activated_user_on_same_team
  validate :cannot_be_existing_user_on_another_team
  validate :email_domain_must_be_whitelisted, if: :enforce_whitelist?

  validates_presence_of :email
  validates_presence_of :team

private

  def cannot_be_existing_activated_user_on_same_team
    if existing_user&.account_activated? && existing_user.team == team
      errors.add(:email, :already_in_team, email:, team: team_name)
    end
  end

  def cannot_be_existing_user_on_another_team
    if existing_user && !existing_user.deleted? && existing_user.team != team
      errors.add(:email, :existing_user, opss_enquiries_email:)
    end
  end

  def email_domain_must_be_whitelisted
    address = Mail::Address.new(email)
  rescue Mail::Field::IncompleteParseError
    # This error will be thrown when an email address is incorrectly formatted. The form will be invalid based on that so no need to do add error here.
  else
    errors.add(:email, :not_whitelisted, opss_enquiries_email:) unless whitelisted_domains.include?(address.domain.to_s.downcase)
  end

  def team_name
    team.decorate.name
  end

  def existing_user
    # User emails are forced to lower case when saved, so we must compare case insensitively
    @existing_user ||= User.find_by email: email&.downcase
  end

  def enforce_whitelist?
    Rails.application.config.email_whitelist_enabled
  end

  def whitelisted_domains
    Rails.application.config.whitelisted_emails["email_domains"].map { |domain| domain.downcase.strip }
  end

  def opss_enquiries_email
    I18n.t("enquiries_email")
  end
end
