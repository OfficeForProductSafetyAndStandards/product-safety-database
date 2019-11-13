Elasticsearch::Model.client = Elasticsearch::Client.new(
  Rails.application.config_for(:elasticsearch)
    .merge(logger: Logger.new(STDOUT), log: true, trace: true)
)
