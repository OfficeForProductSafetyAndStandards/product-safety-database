class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      return { error: "No file provided" } if file.nil?

      begin
        antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "http://localhost:3000/v2/scan-chunked"
        uri = URI(antivirus_url)
        req = Net::HTTP::Post.new(uri)
        req.basic_auth(ENV["ANTIVIRUS_USERNAME"], ENV["ANTIVIRUS_PASSWORD"])
        req["Content-Type"] = "application/octet-stream"
        req["filename"] = "file"

        File.open(file) do |f|
          req.body = f.read

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: Rails.env.production?) do |http|
            http.request(req)
          end

          case response
          when Net::HTTPSuccess
            body = JSON.parse(response.body)
            { safe: !body.fetch("infected", false) }
          else
            { error: "HTTP request failed with status #{response.code}" }
          end
        end
      rescue Errno::ENOENT
        { error: "File not found locally" }
      rescue JSON::ParserError
        { error: "Invalid JSON response" }
      rescue Net::ReadTimeout
        { error: "Request timed out" }
      rescue StandardError => e
        { error: "An unexpected error occurred: #{e.message}" }
      ensure
        file.close unless file.closed?
      end
    end
  rescue ActiveStorage::FileNotFoundError
    { error: "File not found in storage" }
  rescue StandardError => e
    { error: "Failed to download blob: #{e.message}" }
  end
end
