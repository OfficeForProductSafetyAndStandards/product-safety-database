ENV["OPENSEARCH_URL"] = Rails.application.config_for(:opensearch).fetch(:url, "http://localhost:9200")
