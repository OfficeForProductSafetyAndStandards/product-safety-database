class KeycloakConnector < ApplicationRecord

  FIELDS = <<~SQL.freeze
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
    #{FIELDS}
    FROM user_entity ue
    LEFT JOIN credential c ON ue.id = c.user_id AND c.type = 'password'
    LEFT JOIN user_attribute ua ON ue.id = ua.user_id AND ua.name = 'mobile_number';
  SQL

  establish_connection :keycloak

  def self.copy_keycloak_credentials
    rows = KeycloakConnector.connection.query(CREDENTIALS_QUERY)
    rows.each do |row|
      user = User.find_by(email: row[0])
      next unless user

       user.keycloak_first_name = row[1]
       user.keycloak_last_name = row[2]
       user.keycloak_username = row[3]
       user.keycloak_created_at = Time.at(row[4])

       user.password_salt = row[5]
       user.encrypted_password = row[6]
       user.hash_iterations = row[7]
       user.credential_type = row[8]

       user.mobile_number = row[9]

       user.save!
    end
  end
end
