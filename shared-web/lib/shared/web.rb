# requires all dependencies
Gem.loaded_specs['shared-web'].dependencies.each do |d|
  require d.name unless d.name.include? "elasticsearch"
end

# Elasticsearch gems need to be 'required' with a different name than gem name, hence we do it separately
require "elasticsearch/model"
require "elasticsearch/rails"

require "shared/web/engine"

module Shared
  module Web
    ROOT_PATH = Pathname.new(File.join(__dir__, "..", ".."))

    class << self
      def webpacker
        @webpacker ||= ::Webpacker::Instance.new(
          root_path: ROOT_PATH,
          config_path: ROOT_PATH.join("config/webpacker.yml")
        )
      end
    end

  end
end
