Elasticsearch::Model.client = Elasticsearch::Client.new(
  Rails.application.config_for(:elasticsearch).merge(trace: true, logger: Rails.logger, log_level: Logger::DEBUG)
)
