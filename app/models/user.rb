class User < ApplicationRecord
  include Deletable
  include UserCollaboratorInterface

  enum locked_reason: {
    failed_attempts: "failed_attempts",
    inactivity: "inactivity"
  }

  INVITATION_EXPIRATION_DAYS = 14
  COMMON_PASSWORDS_FILE_PATH = "app/assets/10-million-password-list-top-1000000.txt".freeze
  TWO_FACTOR_LOCK_TIME = 1.hour

  # Time at which a user who has completed registration is considered inactive if they have not used the service
  INACTIVE_THRESHOLD = 3.months

  # Limits the frequency of database updates so they don't happen on each request which would affect performance
  LAST_ACTIVITY_TIME_UPDATE_THRESHOLD = 5.minutes

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :registerable, :trackable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable, :rememberable, :validatable, :recoverable, :encryptable, :lockable

  belongs_to :organisation

  has_many :owner_user_collaborations, class_name: "Collaboration::Access::OwnerUser", foreign_key: "collaborator_id"
  has_many :investigations, through: :owner_user_collaborations, dependent: :nullify, as: :user
  has_many :activities, through: :investigations
  has_many :roles, dependent: :destroy, as: :entity
  has_many :collaborations, dependent: :destroy, as: :collaborator
  has_many :case_exports
  has_many :business_exports
  has_many :product_exports
  has_many :api_tokens, dependent: :destroy

  belongs_to :team

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
  attribute :invited_at, :datetime, default: -> { Time.zone.now }

  redacted_export_with :id, :account_activated, :created_at, :deleted_at, :failed_attempts,
                       :has_accepted_declaration, :has_been_sent_welcome_email, :has_viewed_introduction,
                       :invited_at, :keycloak_created_at, :last_sign_in_at, :locked_at, :mobile_number_verified,
                       :organisation_id, :remember_created_at, :second_factor_attempts_locked_at,
                       :secondary_authentication_operation, :sign_in_count, :team_id, :updated_at,
                       :last_activity_at_approx, :locked_reason

  # Active users are those with current access to the service (ie have set up an account and haven't been deleted)
  # and who have accepted the user declaration
  def self.active
    where(account_activated: true).not_deleted
  end

  def self.inactive
    active.where(arel_table[:last_activity_at_approx].lt(INACTIVE_THRESHOLD.ago))
  end

  def self.lock_inactive_users!
    inactive.each { |user| user.lock_access!(reason: locked_reasons[:inactivity]) }
  end

  def in_same_team_as?(user)
    team == user.team
  end

  def name
    super.to_s
  end

  def all_data_exporter?
    has_role? :all_data_exporter
  end

  def notifying_country_editor?
    has_role? :notifying_country_editor
  end

  def is_opss?
    has_role? :opss
  end

  def is_team_admin?
    has_role? :team_admin
  end

  def is_superuser?
    has_role? :super_user
  end

  def is_prism_user?
    has_role? :prism
  end

  def can_validate_risk_level?
    has_role? :risk_level_validator
  end

  def can_send_email_alert?
    has_role? :email_alert_sender
  end

  def can_view_restricted_cases?
    has_role? :restricted_case_viewer
  end

  def can_bulk_upload_products?
    has_role? :product_bulk_uploader
  end

  def can_use_product_recall_tool?
    team.name == "OPSS Incident Management"
  end

  def has_role?(role)
    roles.exists?(name: role) || team.roles.exists?(name: role)
  end

  def has_completed_registration?
    encrypted_password.present? && name.present? && mobile_number.present? && mobile_number_verified
  end

  def self.get_owners(except: [])
    user_ids_to_exclude = Array(except).collect(&:id)
    active.where.not(id: user_ids_to_exclude).eager_load(:organisation, :team)
  end

  def has_viewed_introduction!
    update has_viewed_introduction: true
  end

  def invitation_expired?
    invited_at <= INVITATION_EXPIRATION_DAYS.days.ago
  end

  # BEGIN: place devise overriden method calls bellow

  # Devise::Models::Lockable

  def send_unlock_instructions
    token = set_unlock_token
    send_account_locked_email(token)
    token
  end

  def send_unlock_instructions_after_inactivity
    token = set_unlock_token
    send_account_locked_inactive_email(token)
  end

  def increment_failed_attempts
    return unless mobile_number_verified?

    super
  end

  def lock_access!(opts = {})
    self.locked_reason = opts.fetch(:reason, self.class.locked_reasons[:failed_attempts])

    # Only send the email immediately if the account was locked due to failed attempts. Otherwise it will be sent when the user next logs in
    opts[:send_instructions] = false if locked_reason == self.class.locked_reasons[:inactivity]

    super(opts)
    save!(validate: false)
  end

  # Don't reset password attempts yet, it will happen on next successful login
  def unlock_access!
    self.locked_at = nil
    self.unlock_token = nil
    save!(validate: false)
  end

  # Devise::Models::Authenticatable

  def active_for_authentication?
    true
  end

  def self.find_first_by_auth_conditions(conditions, opts = {})
    super(conditions, opts.merge(deleted_at: nil))
  end

  def mobile_number_change_allowed?
    !mobile_number_verified?
  end

  def has_filled_out_account_setup_form_and_verified_number?
    name.present? && mobile_number_verified?
  end

  def mark_as_deleted!(deleted_by = nil)
    return if deleted?

    self.deleted_at = Time.zone.now
    self.deleted_by = deleted_by.id if deleted_by
    self.account_activated = false
    self.invitation_token = nil

    save!
  end

  def reset_to_invited_state!
    self.deleted_at = nil
    self.account_activated = false
    self.mobile_number_verified = false
    self.has_accepted_declaration = false
    self.has_been_sent_welcome_email = false
    self.has_viewed_introduction = false
    self.name = nil
    self.mobile_number = nil

    save!
  end

  def update_last_activity_time!
    if !last_activity_at_approx || (last_activity_at_approx < LAST_ACTIVITY_TIME_UPDATE_THRESHOLD.ago)
      self.last_activity_at_approx = Time.zone.now
      save!(validate: false)
    end
  end

private

  def set_unlock_token
    raw, enc = Devise.token_generator.generate(self.class, :unlock_token)
    self.unlock_token = enc
    save!(validate: false)
    raw
  end

  def send_account_locked_email(token)
    reset_password_token = set_reset_password_token
    NotifyMailer.account_locked(
      self,
      unlock_token: token,
      reset_password_token:
    ).deliver_later
  end

  def send_account_locked_inactive_email(token)
    NotifyMailer.account_locked_inactive(self, token).deliver_later
  end

  def lock_two_factor!
    update_column(:second_factor_attempts_locked_at, Time.zone.now)
  end

  def unlock_two_factor!
    update_column(:second_factor_attempts_locked_at, nil)
  end

  def two_factor_lock_expired?
    return true if second_factor_attempts_locked_at.nil?

    (second_factor_attempts_locked_at + TWO_FACTOR_LOCK_TIME) < Time.zone.now
  end

  def send_reset_password_instructions_notification(token)
    return if deleted?

    NotifyMailer.reset_password_instructions(self, token).deliver_later
  end
  # END: Devise methods

  def password_required?
    return false if skip_password_validation

    super
  end
end
