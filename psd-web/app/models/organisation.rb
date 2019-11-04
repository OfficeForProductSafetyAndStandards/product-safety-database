class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify, primary_key: :keycloak_id
  has_many :teams, dependent: :nullify, primary_key: :keycloak_id

  def self.load_from_keycloak
    KeycloakClient.instance.all_organisations.each do |org|
      record = find_or_create_by(keycloak_id: org[:id])
      record.update_attributes(org.slice(:name, :path))
    end
  end
end
