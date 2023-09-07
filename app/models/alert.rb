class Alert < ApplicationRecord
  include Documentable

  attr_accessor :investigation_url

  belongs_to :investigation
  belongs_to :added_by_user, class_name: :User, optional: true

  redacted_export_with :id, :added_by_user_id, :created_at, :description,
                       :investigation_id, :summary, :updated_at
end
