RSpec.configure do |config|
  config.after do
    User.current = nil
  end
end
