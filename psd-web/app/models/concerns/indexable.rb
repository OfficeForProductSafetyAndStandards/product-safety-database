module Indexable
  extend ActiveSupport::Concern

  included do
    pp [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, self.to_s.gsub('::', '').downcase].join("_")
    self.index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, self.to_s.gsub('::', '').downcase].join("_")
  end
end
