class User < ApplicationRecord
  INVITATION_EXPIRATION_DAYS = 14
  COMMON_PASSWORDS_FILE_PATH = "app/assets/10-million-password-list-top-1000000.txt".freeze
  TWO_FACTOR_LOCK_TIME = 1.hour

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :registerable, :trackable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable, :rememberable, :validatable, :recoverable, :encryptable, :lockable

  belongs_to :organisation

  has_many :investigations, dependent: :nullify, as: :assignable
  has_many :activities, through: :investigations
  has_many :user_sources, dependent: :destroy
  has_many :user_roles, dependent: :destroy

  has_and_belongs_to_many :teams

  validates :password,
            common_password: { message: I18n.t(:too_common, scope: %i[activerecord errors models user attributes password]) },
            unless: proc { |user| !password_required? || user.errors.messages[:password].any? }

  validates :name, presence: true, on: :change_name

  with_options on: :registration_completion do |registration_completion|
    registration_completion.validates :mobile_number, presence: true
    registration_completion.validates :mobile_number,
                                      phone: { message: I18n.t(:invalid, scope: %i[activerecord errors models user attributes mobile_number]) },
                                      unless: -> { mobile_number.blank? }
    registration_completion.validates :name, presence: true
    registration_completion.validates :password, presence: true
    registration_completion.validates :password, length: { minimum: 8 }, allow_blank: true
  end

  attribute :skip_password_validation, :boolean, default: false
  attribute :invitation_token, :string, default: -> { SecureRandom.hex(15) }
  attribute :invited_at, :datetime, default: -> { Time.current }

  # Active users are those with current access to the service (ie have set up an account and haven't been deleted)
  # and who have accepted the user declaration
  def self.active
    where(account_activated: true).not_deleted
  end

  def self.not_deleted
    where(deleted_at: nil)
  end

  def self.find_user_within_teams_with_email!(teams:, email:)
    joins(:teams).where(teams: { id: teams.pluck(:id) }).find_by!(email: email)
  end

  def self.create_and_send_invite!(email_address, team, inviting_user)
    user = create!(
      skip_password_validation: true,
      id: SecureRandom.uuid,
      email: email_address,
      organisation: team.organisation
    )

    # TODO: remove this once we’ve updated the application to no
    # longer depend upon this role.
    user.user_roles.create!(name: "psd_user")
    user.user_roles.create!(name: "opss_user") if inviting_user.is_opss?

    team.users << user

    SendUserInvitationJob.perform_later(user.id, inviting_user.id)
  end

  def self.resend_invite(email_address, inviting_user)
    user = find_user_within_teams_with_email!(email: email_address, teams: inviting_user.teams)

    user.update! invitation_token: user.invitation_token || SecureRandom.hex(15), invited_at: Time.current

    SendUserInvitationJob.perform_later(user.id, inviting_user.id)
  end

  def self.current
    RequestStore.store[:current_user]
  end

  def self.current=(user)
    RequestStore.store[:current_user] = user
  end

  def team
    teams.first
  end

  def in_same_team_as?(user)
    (teams & user.teams).any?
  end

  def name
    super.to_s
  end

  def team_names
    teams.map(&:name).join(", ")
  end

  def is_psd_user?
    has_role? :psd_user
  end

  def is_psd_admin?
    has_role? :psd_admin
  end

  def is_opss?
    has_role? :opss_user
  end

  def is_team_admin?
    has_role? :team_admin
  end

  def is_superuser?
    has_role? :superuser
  end

  def has_completed_registration?
    encrypted_password.present? && name.present? && mobile_number.present? && mobile_number_verified
  end

  def self.get_assignees(except: [])
    user_ids_to_exclude = Array(except).collect(&:id)
    active.where.not(id: user_ids_to_exclude).eager_load(:organisation, :teams)
  end

  def self.get_team_members(user:)
    users = [].to_set
    user.teams.each do |team|
      team.users.active.find_each do |team_member|
        users << team_member
      end
    end
    users
  end

  def has_viewed_introduction!
    update has_viewed_introduction: true
  end

  def deleted?
    deleted_at.present?
  end

  def invitation_expired?
    invited_at <= INVITATION_EXPIRATION_DAYS.days.ago
  end

  def mark_as_deleted!
    return if deleted?

    update!(deleted_at: Time.current)
  end

  # BEGIN: place devise overriden method calls bellow

  # Devise::Models::Lockable

  def send_unlock_instructions
    raw, enc = Devise.token_generator.generate(self.class, :unlock_token)
    self.unlock_token = enc
    save(validate: false)
    reset_password_token = set_reset_password_token
    NotifyMailer.account_locked(self,
                                unlock_token: raw,
                                reset_password_token: reset_password_token).deliver_later
    raw
  end

  def increment_failed_attempts
    return unless mobile_number_verified?

    super
  end

  # Don't reset password attempts yet, it will happen on next successful login
  def unlock_access!
    self.locked_at = nil
    self.unlock_token = nil
    save(validate: false)
  end

  # Devise::Models::Authenticatable

  def active_for_authentication?
    true
  end

  def self.find_first_by_auth_conditions(conditions, opts = {})
    super(conditions, opts.merge(deleted_at: nil))
  end

private

  def lock_two_factor!
    update_column(:second_factor_attempts_locked_at, Time.current)
  end

  def unlock_two_factor!
    update_column(:second_factor_attempts_locked_at, nil)
  end

  def two_factor_lock_expired?
    return true if second_factor_attempts_locked_at.nil?

    (second_factor_attempts_locked_at + TWO_FACTOR_LOCK_TIME) < Time.current
  end

  def send_reset_password_instructions_notification(token)
    return if deleted?

    NotifyMailer.reset_password_instructions(self, token).deliver_later
  end
  # END: Devise methods

  def current_user?
    User.current&.id == id
  end

  def has_role?(role)
    user_roles.exists?(name: role)
  end

  def password_required?
    return false if skip_password_validation

    super
  end
end
