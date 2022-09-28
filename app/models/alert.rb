class Alert < ApplicationRecord
  include Searchable
  include Documentable

  attr_accessor :investigation_url

  belongs_to :investigation
  belongs_to :added_by_user, class_name: :User, optional: true

  redacted_export_with :id, :created_at, :description, :investigation_id, :summary, :updated_at
end
