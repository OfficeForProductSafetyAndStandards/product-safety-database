desc "Task that replicates rails secret, required for Clound Foundry buildpack. Can be removed once PSD has been migrated off PaaS."
task :secret do
  require "securerandom"
  puts SecureRandom.hex(64)
end
