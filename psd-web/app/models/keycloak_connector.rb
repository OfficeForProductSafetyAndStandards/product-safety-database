class KeycloakConnector < ApplicationRecord
  # To add
  # mobile number - user_attribute.value
  # account create date - user_entity.created_timestamp
  # last accessed date
  # password update date - credential.created_date
  # username?

  EMAIL = 1
  FIRST_NAME = 2

  LAST_NAME = 3
  USERNAME = 4
  USER_CREATED_TIMESTAMP = 5

  SALT = 6
  CRYPTED_PASSWORD = 7
  HASH_ITERATIONS = 8
  TYPE = 9

  MOBILE_NUMBER = 4


  FIELDS = <<~SQL.freeze
    ue.id, ue.email, ue.first_name,
    ue.last_name, ue.username, ue.created_timestamp,
    c.salt, c.value, c.hash_iterations, c.user_id, c.type
    ua.user_id, ua.name, ua.value
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
    rows.each do |salt, encrypted_password, iterations, email, credential_type|
      user = User.find_by(email: row[EMAIL])
      next unless user

      # user.password_salt = salt
      # user.encrypted_password = encrypted_password
      # user.hash_iterations = iterations
      # user.credential_type = credential_type
      user.password_salt = row[SALT]
      user.encrypted_password = row[CRYPTED_PASSWORD]
      user.hash_iterations = row[HASH_ITERATIONS]
      user.credential_type = row[TYPE]
      user.keycloak_first_name = row[FIRST_NAME]
      user.keycloak_last_name = row[LAST_NAME]
      user.keycloak_username = row[USERNAME]
      user.keycloak_created_at = Time.at(row[USER_CREATED_TIMESTAMP])
      user.mobile_number = Time.at(row[MOBILE_NUMBER])
      user.save!
    end
  end
end
