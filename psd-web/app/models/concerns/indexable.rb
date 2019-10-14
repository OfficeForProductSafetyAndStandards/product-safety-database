module Indexable
  extend ActiveSupport::Concern

  included do
    [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, self.class.to_s.gsub('::', '').downcase].join("_")
  end
end
