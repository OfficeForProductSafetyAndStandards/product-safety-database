class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify

  def self.load_from_keycloak(orgs = KeycloakClient.instance.all_organisations)
    orgs.each do |org|
      record = find_or_create_by(id: org[:id])
      record.update(org.slice(:name, :path))
    end
  end
end
