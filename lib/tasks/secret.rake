task secret: :environment do
  require "securerandom"
  puts SecureRandom.hex(64)
end
