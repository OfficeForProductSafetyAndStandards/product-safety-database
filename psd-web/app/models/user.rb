class User < ApplicationRecord
  INVITATION_EXPIRATION_DAYS = 14
  COMMON_PASSWORDS_FILE_PATH = "lib/10-million-password-list-top-1000000.txt".freeze

  devise :database_authenticatable, :omniauthable, :timeoutable, omniauth_providers: %i[openid_connect]
  belongs_to :organisation

  has_many :investigations, dependent: :nullify, as: :assignable
  has_many :activities, through: :investigations
  has_many :user_sources, dependent: :destroy
  has_many :user_roles, dependent: :destroy

  has_and_belongs_to_many :teams

  validates :id, presence: true, uuid: true


  with_options on: :registration_completion do |registration_completion|
    registration_completion.validates :mobile_number, presence: true
    registration_completion.validate :validate_mobile_number
    registration_completion.validates :name, presence: true
    registration_completion.validates :password, presence: true
    registration_completion.validates :password, length: { minimum: 8 }, allow_blank: true

    registration_completion.validate :validate_password_not_common,
                                     unless: Proc.new { |user| user.errors.messages[:password].any? }
  end




  attr_accessor :access_token # Used only in User.current thread context

  def self.activated
    where(account_activated: true)
  end

  def self.create_and_send_invite!(email_address, team, inviting_user)
    user = create!(
      id: SecureRandom.uuid,
      email: email_address,
      organisation: team.organisation,
      invitation_token: SecureRandom.hex(15)
    )

    # TODO: remove this once we’ve updated the application to no
    # longer depend upon this role.
    user.user_roles.create!(name: "psd_user")

    team.users << user

    SendUserInvitationJob.perform_later(user.id, inviting_user.id)
  end

  def self.resend_invite(email_address, inviting_user)
    # Only want to allow resending invites to users that share a team with the inviting user.
    user = User.joins(:teams)
               .where(teams: { id: inviting_user.teams.pluck(:id) })
               .find_by!(email: email_address)

    SendUserInvitationJob.perform_later(user.id, inviting_user.id)
  end

  def self.load_from_keycloak(users = KeycloakClient.instance.all_users)
    # We're not interested in users not belonging to an organisation, as that means they are not PSD users
    # - however, checking this based on permissions would require a request per user
    users.map do |user|
      user[:teams] = Team.where(id: user[:groups])

      # Filters out user groups which aren't related to PSD. User may belong directly to an Organisation, or indirectly via a Team
      user[:organisation] = Organisation.find_by(id: user[:groups]) || user[:teams].first&.organisation

      user
    end

    users.reject { |user| user[:organisation].blank? }.each do |user|
      begin
        record = find_or_create_by!(id: user[:id]) do |new_record|
          new_record.email = user[:email]
          new_record.name = user[:name]
          new_record.organisation = user[:organisation]
        end

        record.update!(user.slice(:name, :email, :organisation))
        record.teams = user[:teams]

        SyncKeycloakUserRolesJob.perform_later(record.id)
      rescue ActiveRecord::ActiveRecordError => e
        if Rails.env.production?
          Raven.capture_exception(e)
        else
          raise(e)
        end
      end
    end
  end

  def load_roles_from_keycloak
    roles = KeycloakClient.instance.get_user_roles(id).uniq

    return if roles == user_roles.pluck(:name).map(&:to_sym)

    transaction do
      user_roles.delete_all
      roles.each { |role| user_roles.create!(name: role) }
    end
  end

  def self.current
    RequestStore.store[:current_user]
  end

  def self.current=(user)
    RequestStore.store[:current_user] = user
  end

  def name
    super.to_s
  end

  def display_name(ignore_visibility_restrictions: false, other_user: User.current)
    return @display_name if @display_name

    membership = if (ignore_visibility_restrictions || (organisation_id == other_user&.organisation_id)) && teams.any?
                   team_names
                 else
                   organisation.name
                 end

    @display_name = "#{name} (#{membership})"
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

  def self.get_assignees(except: [])
    user_ids_to_exclude = Array(except).collect(&:id)
    self.activated.where.not(id: user_ids_to_exclude).eager_load(:organisation, :teams)
  end

  def self.get_team_members(user:)
    users = [].to_set
    user.teams.each do |team|
      team.users.activated.find_each do |team_member|
        users << team_member
      end
    end
    users
  end

  def has_viewed_introduction!
    update has_viewed_introduction: true
  end

  def invitation_expired?
    invited_at && invited_at <= INVITATION_EXPIRATION_DAYS.days.ago
  end

private

  def validate_password_not_common
    File.foreach(COMMON_PASSWORDS_FILE_PATH, chomp: true) do |common_password|
      if common_password == password
        errors.add(:password, I18n.t(:too_common, scope: %i[activerecord errors models user attributes password]))
        break
      end
    end
  end

  def validate_mobile_number
    return if mobile_number.blank?

    if mobile_number.count("0-9") < 10
      errors.add(:mobile_number, I18n.t(:invalid, scope: %i[activerecord errors models user attributes mobile_number]))
    end
  end

  def current_user?
    User.current&.id == id
  end

  def has_role?(role)
    user_roles.exists?(name: role)
  end
end
