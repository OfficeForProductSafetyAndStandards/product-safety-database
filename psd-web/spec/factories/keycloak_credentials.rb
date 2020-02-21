FactoryBot.define do
  factory :keycloak_credential do
    salt { "\xC6\xAF\xE7\x91y\x91Fn\xE2\v\xF4\xE3^A\x98g" }
    # passwordpasswordpasswordpassword
    encrypted_password { "Jud2hU6IHPx5yK3COhRJGAnJawRqkQ8sZIKmjZWkYfE1XIWXTItlXt+rL6s/ExuWi9xplij+0rKOZttpTqp/PA==" }
    hash_iterations { 27_500 }
    email { "test@example.org" }
    credential_type { "password" }
  end
end
