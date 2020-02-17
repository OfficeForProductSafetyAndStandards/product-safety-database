require "devise/strategies/psd_database_authenticatable"

module Devise
  module Models
    module PsdDatabaseAuthenticatable
      extend ActiveSupport::Concern
      included do
        include DatabaseAuthenticatable
      end
    end
  end
end
