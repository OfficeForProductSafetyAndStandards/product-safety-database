class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      uri = URI(Rails.application.config.antivirus_url)
      req = Net::HTTP::Post.new(uri)
      req.basic_auth(ENV["ANTIVIRUS_USERNAME"], ENV["ANTIVIRUS_PASSWORD"])
      req.set_form([["file", File.open(file)]], "multipart/form-data")

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: Rails.env.production?) do |http|
        http.request(req)
      end

      body = JSON.parse(response.body)
      { safe: body["safe"] }
    end
  end
end
