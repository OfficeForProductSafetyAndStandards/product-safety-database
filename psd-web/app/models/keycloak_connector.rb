class KeycloakConnector < ApplicationRecord
  # To add
  # mobile number - user_attribute.value
  # account create date - user_entity.created_timestamp
  # last accessed date
  # password update date - credential.created_date
  # username?
  CREDENTIALS_QUERY = <<~SQL.freeze
    SELECT c.salt, c.value, c.hash_iterations, u.email, c.type FROM credential c INNER JOIN user_entity u ON c.user_id = u.id
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
