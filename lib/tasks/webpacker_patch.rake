# TODO: Webpacker under Rails 7 no longer runs yarn:install during asset
#   precompilation. this patch is required until we move away from webpacker.
if Rake::Task.task_defined?("webpacker:compile")
  Rake::Task["webpacker:compile"].enhance(["yarn:install"])
end
