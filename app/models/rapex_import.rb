class RapexImport < ApplicationRecord
  redacted_export_with :id, :created_at, :reference, :updated_at
end
