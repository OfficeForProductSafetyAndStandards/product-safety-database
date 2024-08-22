class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      return { error: "No file provided" } if file.nil?

      begin
        uri = URI(Rails.application.config.antivirus_url)
        req = Net::HTTP::Post.new(uri)
        req.basic_auth(ENV["ANTIVIRUS_USERNAME"], ENV["ANTIVIRUS_PASSWORD"])

        File.open(file) do |f|
          req.set_form([["file", f]], "multipart/form-data")

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: Rails.env.production?) do |http|
            http.request(req)
          end

          case response
          when Net::HTTPSuccess
            body = JSON.parse(response.body)
            { safe: body["safe"] }
          else
            { error: "HTTP request failed with status #{response.code}" }
          end
        end
      rescue Errno::ENOENT
        { error: "File not found" }
      rescue JSON::ParserError
        { error: "Invalid JSON response" }
      rescue Net::ReadTimeout
        { error: "Request timed out" }
      rescue StandardError => e
        { error: "An unexpected error occurred: #{e.message}" }
      ensure
        file.close
      end
    end
  rescue StandardError => e
    { error: "Failed to download blob: #{e.message}" }
  end
end
