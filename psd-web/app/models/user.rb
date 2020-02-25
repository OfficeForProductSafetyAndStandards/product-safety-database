class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :registerable, :trackable and :omniauthable
  devise :database_authenticatable, :timeoutable, :trackable, :rememberable, :validatable, :recoverable, :encryptable

  belongs_to :organisation

  has_many :investigations, dependent: :nullify, as: :assignable
  has_many :activities, through: :investigations
  has_many :user_sources, dependent: :destroy
  has_many :user_roles, dependent: :destroy

  has_and_belongs_to_many :teams

  attribute :skip_password_validation, :boolean, default: false

  def self.activated
    where(account_activated: true)
  end

  def self.create_and_send_invite!(email_address, team, inviting_user)
    user = create!(
      skip_password_validation: true,
      id: SecureRandom.uuid,
      email: email_address,
      organisation: team.organisation,
      invitation_token: SecureRandom.hex(15)
    )
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

private

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
