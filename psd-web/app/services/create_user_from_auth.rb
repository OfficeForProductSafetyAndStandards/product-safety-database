class CreateUserFromAuth
  def initialize(omniauth_response)
    self.omniauth_response = omniauth_response
  end

  def user
    @user ||= begin
      User.find_or_create_by!(id: uuid) do |user|
        user.email        = email
        user.name         = name
        user.organisation = organisation
        user.teams        = teams
      end
    end
  end

private

  attr_accessor :omniauth_response

  def teams
    @teams ||= groups.any? ? Team.where(path: groups) : []
  end

  def organisation
    @organisation ||= Organisation.find_by(path: groups) || teams.first&.organisation
  end

  def groups
    omniauth_response.dig("extra", "raw_info", "groups")
  end

  def email
    omniauth_response.dig("info", "email")
  end

  def name
    omniauth_response.dig("info", "name")
  end

  def uuid
    omniauth_response["uuid"]
  end
end
