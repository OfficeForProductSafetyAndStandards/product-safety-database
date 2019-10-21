module Indexable
  extend ActiveSupport::Concern

  included do
    pp '*' * 80
    pp [self.to_s, ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, self.to_s.gsub('::', '').downcase].join("_")
    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, self.to_s.gsub('::', '').downcase].join("_")
  end
end
