class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def self.analyze_later
    false
  end

  def metadata
    download_blob_to_tempfile do |file|
      response = RestClient::Request.execute method: :post, url: Rails.application.config.antivirus_url, user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: }
      body = JSON.parse(response.body)
      Rails.logger.info("££££££££££ AntiVirusAnalyzer is done")
      { safe: body["safe"] }
    end
  end
end
