class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def self.analyze_later
    false
  end

  def metadata
    download_blob_to_tempfile do |file|
      Rails.logger.info "$$$$$ ANTIVIRUS ANALYZER CALLED at #{Time.now}"
      response = RestClient::Request.execute method: :post, url: Rails.application.config.antivirus_url, user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: }
      body = JSON.parse(response.body)
      # adding user_notified false to show that the user has not seen an error message about this issue yet.
      Rails.logger.info "$$$$$ ANTIVIRUS ANALYZER FINISHED AT #{Time.now}"
      { safe: body["safe"], user_notified: false }
    end
  end
end
