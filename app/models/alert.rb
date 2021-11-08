class Alert < ApplicationRecord
  include Searchable
  include Documentable

  attr_accessor :investigation_url

  belongs_to :investigation

  has_one :source, as: :sourceable, dependent: :destroy

  redacted_export_with :id, :created_at, :description, :investigation_id, :summary, :updated_at
end
