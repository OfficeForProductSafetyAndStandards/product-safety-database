class KeycloakConnector < ApplicationRecord

  FIELDS = <<~SQL.freeze
    ue.id, ue.email, ue.first_name,
    ue.last_name, ue.username, ue.created_timestamp,
    c.salt, c.value as crypted_password, c.hash_iterations, c.user_id, c.type,
    ua.user_id, ua.name, ua.value as mobile_number
  SQL

  CREDENTIALS_QUERY = <<~SQL.freeze
    SELECT
    #{FIELDS}
    FROM user_entity ue
    LEFT JOIN credential c ON ue.id = c.user_id AND c.type = 'password'
    LEFT JOIN user_attribute ua ON ue.id = ua.user_id AND ua.name = 'mobile_number';
  SQL

  establish_connection :keycloak

  def self.copy_keycloak_credentials
    rows = KeycloakConnector.connection.query(CREDENTIALS_QUERY)
    rows.each do |row|
      user = User.find_by(email: row[1])
      #user = User.find_by(email: row["email"])
      next unless user

      # user.password_salt = salt
      # user.encrypted_password = encrypted_password
      # user.hash_iterations = iterations
      # user.credential_type = credential_type
      #user.password_salt = row["salt"]
      user.password_salt = row[6]
      # user.encrypted_password = row["crypted_password"]
      # user.hash_iterations = row["hash_iterations"]
      # user.credential_type = row["type"]
      # user.keycloak_first_name = row["first_name"]
      # user.keycloak_last_name = row["last_name"]
      # user.keycloak_username = row["username"]
      # user.keycloak_created_at = Time.at(row["created_timestamp"])
      # user.mobile_number = row["mobile_number"]
      # user.save!
    end
  end
end
