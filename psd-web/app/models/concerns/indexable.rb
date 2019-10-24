module Indexable
  extend ActiveSupport::Concern

  included do
    index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, model_name.plural].join("_")
  end
end
