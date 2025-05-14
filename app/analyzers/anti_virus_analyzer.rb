class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      file_obj = nil
      begin
        antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "https://staging.clamav.uktrade.digital/v2/scan-chunked"

        file_obj = File.new(file.path, "rb")
        file_content = file_obj.read

        Rails.logger.debug("AntiVirusAnalyzer: Connecting to #{antivirus_url}")

        response = RestClient::Request.execute(
          method: :post,
          url: antivirus_url,
          user: ENV["ANTIVIRUS_USERNAME"],
          password: ENV["ANTIVIRUS_PASSWORD"],
          headers: {
            "Content-Type" => "application/octet-stream",
            "Transfer-Encoding" => "chunked",
          },
          payload: file_content,
        )

        if response.code == 200
          result = JSON.parse(response.body)
          Rails.logger.debug("AntiVirusAnalyzer: Response: #{result.inspect}")
          if result["malware"]
            Rails.logger.info("AntiVirusAnalyzer: Malware detected: #{result['reason']}")
            { safe: false, message: result["reason"] }
          else
            Rails.logger.debug("AntiVirusAnalyzer: File is safe")
            { safe: true }
          end
        else
          Rails.logger.error("AntiVirusAnalyzer: HTTP Error - Status: #{response.code}, Body: #{response.body}")
          { safe: false, message: response.body }
        end
      rescue StandardError => e
        Rails.logger.error("AntiVirusAnalyzer: Error scanning file: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        { safe: false, error: e.message }
      ensure
        file_obj&.close if file_obj && !file_obj.closed?
      end
    end
  rescue ActiveStorage::FileNotFoundError
    Rails.logger.error("AntiVirusAnalyzer: File not found in storage")
    { error: "File not found in storage" }
  rescue StandardError => e
    Rails.logger.error("AntiVirusAnalyzer: Failed to download blob: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { error: "Failed to download blob: #{e.message}" }
  end
end
