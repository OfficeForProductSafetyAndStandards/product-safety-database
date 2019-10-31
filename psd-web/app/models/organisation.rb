class Organisation < ActiveHash::Base
  include ActiveHash::Associations
  include ActiveHashSafeLoadable

  field :id
  field :name
  field :path

  has_many :users, dependent: :nullify
  has_many :teams, dependent: :nullify

  def self.load(force: false)
    begin
      self.safe_load(KeycloakClient.instance.all_organisations(force: force), data_name: "organisations")
    rescue StandardError => e
      Rails.logger.error "Failed to fetch organisations from Keycloak: #{e.message}"
      self.data = nil
    end
  end

  def self.all(options = {})
    self.load

    if options.has_key?(:conditions)
      where(options[:conditions])
    else
      @records ||= []
    end
  end
end

Organisation.load if Rails.env.development?
