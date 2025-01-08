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
          metadata = analyzer.metadata
          combined_metadata.merge!(metadata) if metadata.present?
        rescue ActiveStorage::FileNotFoundError => e
          Rails.logger.warn("File not found for blob #{@blob.id}: #{e.message}")
          next
        end
      end
    end

    combined_metadata
  end
end
