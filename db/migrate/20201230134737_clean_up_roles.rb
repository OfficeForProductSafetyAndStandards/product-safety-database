class CleanUpRoles < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      reversible do |dir|
        # rubocop:disable Rails/SaveBang
        dir.up do
          Role.where(name: "user").delete_all # Redundant legacy from Keycloak

          team_roles = Role.where(name: %w[opss_user risk_level_validator], entity_type: "User")

          team_roles.each do |role|
            new_role_name = role.name == "opss_user" ? "opss" : role.name
            role.entity.team.roles.create(name: new_role_name) # Fail silently when not unique
          end

          team_roles.delete_all
        end

        dir.down do
          team_roles = Role.where(name: %w[opss risk_level_validator], entity_type: "Team")

          team_roles.each do |role|
            new_role_name = role.name == "opss" ? "opss_user" : role.name
            role.entity.users.each { |user| user.roles.create(name: new_role_name) } # Fail silently when not unique
          end

          team_roles.delete_all
        end
        # rubocop:enable Rails/SaveBang
      end
    end
  end
end
