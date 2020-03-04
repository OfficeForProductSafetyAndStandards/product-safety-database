class KeycloakConnector < ApplicationRecord
  # To add
  # mobile number - user_attribute.value
  # account create date - user_entity.created_timestamp
  # last accessed date
  # password update date - credential.created_date
  # username?

  EMAIL = 1
  FIRST_NAME = 2
  LAST_NAME = 2
  USERNAME = 3
  USER_CREATED_TIMESTAMP = 4
  SALT = 4
  CRYPTED_PASSWORD = 4
  HASH_ITERATIONS = 4
  MOBILE_NUMBER = 4

  FIELDS = <<~SQL.freeze
    ue.id, ue.email, ue.first_name, ue.last_name, ue.username, ue.created_timestamp,
    c.salt, c.value, c.hash_iterations, c.user_id,
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
      user = User.find_by(email: email)
      next unless user

      user.password_salt = salt
      user.encrypted_password = encrypted_password
      user.hash_iterations = iterations
      user.credential_type = credential_type
      user.save!
    end
  end
end
