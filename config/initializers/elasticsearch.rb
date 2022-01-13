Elasticsearch::Model.client = Elasticsearch::Client.new(Rails.application.config_for(:opensearch))
Elasticsearch::Model.client.instance_variable_set("@verified", true)
# .merge(trace: true, logger: Rails.logger, log_level: Logger::DEBUG)
