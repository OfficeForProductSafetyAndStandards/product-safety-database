module LoginHelpers
  module Features
  end
end

RSpec.configure do |config|
  config.include LoginHelpers::Features, type: :feature
  config.before do
    OmniAuth.config.test_mode = true
  end
end
