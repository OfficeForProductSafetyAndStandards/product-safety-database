class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      response = RestClient::Request.execute method: :post, url: Rails.application.config.antivirus_url, user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: }
      body = JSON.parse(response.body)

      # sleep to ensure that file is attached
      sleep 1

      attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)
      user = User.find(blob.metadata["created_by"])
      Rails.logger.info "$$$$$$$$$"
      Rails.logger.info attachment

      if attachment
        Rails.logger.info "Sending unsafe attachment email"
        Rails.logger.info attachment.record_type
        NotifyMailer.unsafe_attachment(user: user, record_type: attachment.record_type, id: attachment.record_id).deliver_later
        attachment.purge_later
      else
        Rails.logger.info "Sending unsafe blob email"
        NotifyMailer.unsafe_file(user: user, created_at: blob.created_at.to_s(:govuk)).deliver_later
        blob.purge_later
      end
      # else
      { safe: body["safe"] }
      # end
    end
  end
end
