class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      response = RestClient::Request.execute method: :post, url: ENV.fetch("ANTIVIRUS_URL", "http://antivirus"), user: ENV["ANTIVIRUS_USERNAME"], password: ENV["ANTIVIRUS_PASSWORD"], payload: { file: file }
      body = JSON.parse(response.body)
      { safe: body["safe"] }
    end
  end
end
