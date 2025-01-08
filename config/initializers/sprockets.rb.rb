Rails.application.configure do
  config.assets.configure do |env|
    env.export_concurrent = false
  end
end
