require "flipper"

Flipper.configure do |config|
  config.default do
    # choose an adapter - in this case, ActiveRecord
    adapter = Flipper::Adapters::ActiveRecord.new

    # pass adapter to handy DSL instance
    Flipper.new(adapter)
  end
end
