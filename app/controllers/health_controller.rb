class HealthController < ApplicationController
  skip_before_action :authenticate_user!, :authorize_user, :has_accepted_declaration, :has_viewed_introduction, :require_secondary_authentication

  http_basic_authenticate_with name: ENV.fetch("HEALTH_CHECK_USERNAME", "health"), password: ENV.fetch("HEALTH_CHECK_PASSWORD", "check")

  def show
    # Check redis services
    Redis.new(Rails.application.config_for(:redis_session)).info
    Redis.new(Rails.application.config_for(:redis_store)).info

    # Check database connection
    ActiveRecord::Migrator.current_version

    elasticsearch_client = Elasticsearch::Client.new(Rails.application.config_for(:elasticsearch))

    # Check Elasticsearch cluster health
    raise "Elasticsearch is down" if elasticsearch_client.cluster.health[:status] == "red"

    raise "No cases in Elasticsearch index" if elasticsearch_client.count(index: Investigation.index_name)["count"].zero?

    # Check Sidekiq queue length (in time) is within an acceptable limit
    raise "Sidekiq queue latency is above 30 seconds" if Sidekiq::Queue.new(ENV["SIDEKIQ_QUEUE"] || "psd").latency > 30

    # Check investigations being present in the database
    raise "Database does not contain any investigation" if Investigation.count.zero?

    render plain: "OK"
  end
end
