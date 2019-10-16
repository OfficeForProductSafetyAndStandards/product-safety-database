module Indexable
  extend ActiveSupport::Concern

  included do



    # index_name [ENV.fetch("ES_NAMESPACE", "default_namespace"), Rails.env, (model.superclass.respond_to?(:__elasticsearch__) ? self.superclass : self).to_s.gsub('::', '').downcase].join("_")

    class_eval do
      after_commit -> { insert_search_index }, on: :create
      after_commit -> { update_search_index }, on: :update
      after_commit -> { delete_search_index }, on: :destroy
    end
  end

  def insert_search_index
    __elasticsearch__.index_document
    self.class.__elasticsearch__.refresh_index! if Rails.env.test?
  end

  def update_search_index
    __elasticsearch__.update_document
    self.class.__elasticsearch__.refresh_index! if Rails.env.test?
  end

  def delete_search_index
    __elasticsearch__.delete_document
    self.class.__elasticsearch__.refresh_index! if Rails.env.test?
  end
end
