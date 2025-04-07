class MasterAnalyzer < ActiveStorage::Analyzer
  def self.accept?(_blob)
    true
  end

  def metadata
    combined_metadata = {}

    @blob.open do |_file|
      Rails.application.config.document_analyzers.each do |analyzer_class|
        next unless analyzer_class.accept?(@blob)

        analyzer = analyzer_class.new(@blob)
        begin
          Rails.logger.debug("MasterAnalyzer: Running #{analyzer_class.name} on blob #{@blob.id}")
          metadata = analyzer.metadata
          if metadata.present?
            Rails.logger.debug("MasterAnalyzer: #{analyzer_class.name} returned #{metadata.inspect}")
            combined_metadata.merge!(metadata)
          else
            Rails.logger.debug("MasterAnalyzer: #{analyzer_class.name} returned no metadata")
          end
        rescue ActiveStorage::FileNotFoundError => e
          Rails.logger.warn("MasterAnalyzer: File not found for blob #{@blob.id}: #{e.message}")
          next
        rescue StandardError => e
          Rails.logger.error("MasterAnalyzer: Error in #{analyzer_class.name} for blob #{@blob.id}: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          # Add error information to metadata
          error_key = "#{analyzer_class.name.underscore}_error".to_sym
          combined_metadata[error_key] = e.message
        end
      end
    end

    Rails.logger.debug("MasterAnalyzer: Combined metadata for blob #{@blob.id}: #{combined_metadata.inspect}")
    combined_metadata
  end
end
