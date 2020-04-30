return if Rails.env.production?

require "coveralls"
require "simplecov"

desc "Submit code coverage to Coveralls"
task :submit_coverage do # rubocop:disable Rails/RakeEnvironment
  ENV["COVERALLS_PARALLEL"] = "true"
  SimpleCov.merge_timeout(48 * 60 * 60) # Set time allowed between runs to 48 hours
  Coveralls.push!
end
