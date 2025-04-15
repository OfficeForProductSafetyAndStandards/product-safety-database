class AntiVirusAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    download_blob_to_tempfile do |file|
      file_obj = nil
      begin
        # Check if URL already has /scan endpoint (DBT platform)
        is_dbt_scan_url = ENV["ANTIVIRUS_URL"] && ENV["ANTIVIRUS_URL"].include?("/scan")

        # Set up the base URL based on platform
        if is_dbt_scan_url
          # DBT platform - use URL as-is since it already contains /scan
          antivirus_url = ENV["ANTIVIRUS_URL"]
          platform_name = "DBT"
        else
          # GOV.UK PaaS - append /v2/scan-chunked to URL
          antivirus_url = ENV["ANTIVIRUS_URL"] ? "#{ENV['ANTIVIRUS_URL'].chomp('/')}/v2/scan-chunked" : "http://localhost:3000/v2/scan-chunked"
          platform_name = "PaaS"
        end

        Rails.logger.debug("AntiVirusAnalyzer: Connecting to #{antivirus_url} (#{platform_name} format)")

        # Common request parameters
        request_params = {
          method: :post,
          url: antivirus_url,
          user: ENV["ANTIVIRUS_USERNAME"],
          password: ENV["ANTIVIRUS_PASSWORD"]
        }

        # Platform-specific request configuration
        if is_dbt_scan_url
          # DBT platform uses multipart/form-data
          request_params[:payload] = { file: File.new(file.path, "rb") }
        else
          # GOV.UK PaaS uses application/octet-stream
          file_obj = File.new(file.path, "rb")
          file_content = file_obj.read
          request_params[:headers] = {
            "Content-Type" => "application/octet-stream",
            "Transfer-Encoding" => "chunked",
          }
          request_params[:payload] = file_content
        end

        # Make the request
        response = RestClient::Request.execute(request_params)

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
