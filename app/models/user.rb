class User < ApplicationRecord
  include Deletable
  include UserCollaboratorInterface

  INVITATION_EXPIRATION_DAYS = 14
  COMMON_PASSWORDS_FILE_PATH = "app/assets/10-million-password-list-top-1000000.txt".freeze
  TWO_FACTOR_LOCK_TIME = 1.hour

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :registerable, :trackable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable, :rememberable, :validatable, :recoverable, :encryptable, :lockable

  belongs_to :organisation

  has_many :owner_user_collaborations, class_name: "Collaboration::Access::OwnerUser", foreign_key: "collaborator_id"
  has_many :investigations, through: :owner_user_collaborations, dependent: :nullify, as: :user
  has_many :activities, through: :investigations
  has_many :user_sources, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :collaborations, dependent: :destroy, as: :collaborator

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

  # Active users are those with current access to the service (ie have set up an account and haven't been deleted)
  # and who have accepted the user declaration
  def self.active
    where(account_activated: true).not_deleted
  end

  def self.current
    RequestStore.store[:current_user]
  end

  def self.current=(user)
    RequestStore.store[:current_user] = user
  end

  def in_same_team_as?(user)
    team == user.team
  end

  def name
    super.to_s
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

  def can_validate_risk_level?
    has_role? :risk_level_validator
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
    raw, enc = Devise.token_generator.generate(self.class, :unlock_token)
    self.unlock_token = enc
    save!(validate: false)
    reset_password_token = set_reset_password_token
    NotifyMailer.account_locked(
      self,
      unlock_token: raw,
      reset_password_token: reset_password_token
    ).deliver_later
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

private

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
