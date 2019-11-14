class Organisation < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify

  validates :id, presence: true, uuid: true
  validates :name, presence: true
  validates :path, presence: true

  def self.load_from_keycloak(orgs = KeycloakClient.instance.all_organisations)
    orgs.each do |org|
      begin
        record = find_or_create_by!(id: org[:id]) do |new_record|
          new_record.name = org[:name]
          new_record.path = org[:path]
        end

        record.update!(org.slice(:name, :path))
      rescue ActiveRecord::ActiveRecordError => e
        if Rails.env.production?
          Raven.capture_exception(e)
        else
          raise(e)
        end
      end
    end
  end
end
