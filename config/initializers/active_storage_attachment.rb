Rails.configuration.to_prepare do
  ActiveStorage::Attachment.include Antivirusable
end
