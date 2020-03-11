class KeycloakConnector < ApplicationRecord
  COLUMNS = <<~SQL.freeze
    ue.email,

    ue.first_name,
    ue.last_name,
    ue.username,
    ue.created_timestamp,

    c.salt,
    c.value as crypted_password,
    c.hash_iterations,
    c.type,

    ua.value as mobile_number,

    ue.id, ua.user_id, c.user_id, ua.name
  SQL

  CREDENTIALS_QUERY = <<~SQL.freeze
    SELECT
    #{COLUMNS}
    FROM user_entity ue
    LEFT JOIN credential c ON ue.id = c.user_id AND c.type = 'password'
    LEFT JOIN user_attribute ua ON ue.id = ua.user_id AND ua.name = 'mobile_number';
  SQL

  establish_connection :keycloak

  def self.copy_keycloak_data
    rows = KeycloakConnector.connection.query(CREDENTIALS_QUERY)
    rows.each do |row|
      user = User.find_by(email: row[0])
      next unless user

      user.keycloak_created_at = Time.zone.at(row[4].to_f/1000)

      user.password_salt = row[5]
      user.encrypted_password = row[6] if row[6] # don't copy over nil password
      user.hash_iterations = row[7]
      user.credential_type = row[8]

      user.mobile_number = row[9]

      unless user.save
        Rails.logger.info("[KeycloakConnector] User with id #{user.id} failed with errors: #{user.errors.try(:full_messages)}")
      end
    end
  end
end
