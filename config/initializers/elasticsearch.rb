Elasticsearch::Model.client = Elasticsearch::Client.new(Rails.application.config_for(:opensearch))
# .merge(trace: true, logger: Rails.logger, log_level: Logger::DEBUG)
