class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      response = RestClient::Request.execute method: :post, url: Rails.application.config.antivirus_url, user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: }
      body = JSON.parse(response.body)

      attachments = ActiveStorage::Attachment.where(blob_id: blob.id)
      Rails.logger.info "uuuuuusssssseeeeerrrrrr:"
      Rails.logger.info blob.metadata
      Rails.logger.info blob
      Rails.logger.info Blob.find(blob.id)
      user = User.find(blob.metadata["created_by"])

      # if body["safe"] == false - allow this to run all the time for logging purposes etc.
        # if blob is currently attached we need to purge the attachment which in turn will purge the blob
        unless attachments.empty?
          attachments.each do |attachment|
            Rails.logger.info "Attachment!!!!!"
            Rails.logger.info attachment.record_type
            unless attachment.record_type == "Activity"
              NotifyMailer.unsafe_attachment(user: user, record_type: attachment.record_type, id: attachment.record_id).deliver_later
            end
            attachment.purge_later
            Activity.find(attachment.record_id).destroy if attachment.record_type == "Activity"
          end

        else
          Rails.logger.info "Blob!!!!!"
          blob.purge_later
        end
      # else
        { safe: body["safe"] }
      # end
    end
  end
end
