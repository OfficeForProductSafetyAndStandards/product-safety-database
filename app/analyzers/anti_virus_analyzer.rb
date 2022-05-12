class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      response = RestClient::Request.execute method: :post, url: Rails.application.config.antivirus_url, user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: }
      body = JSON.parse(response.body)

      attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)
      user = User.find(blob.metadata["created_by"])

      # if body["safe"] == false - allow this to run all the time for logging purposes etc.
        # if blob is currently attached we need to purge the attachment which in turn will purge the blob
        if attachment
          Rails.logger.info "Attachment!!!!!"
          Rails.logger.info attachment.record_type
          NotifyMailer.unsafe_attachment(user: user, record_type: attachment.record_type, id: attachment.record_id).deliver_later
          attachment.purge_later
          # delete file attached activity as it is no longer needed
          # Activity.find(attachment.record_id).destroy if attachment.record_type == "Activity"
        else
          Rails.logger.info "Blob!!!!!"
          blob.purge_later
        end
      # else
      #   { safe: body["safe"] }
      # end
    end
  end
end
