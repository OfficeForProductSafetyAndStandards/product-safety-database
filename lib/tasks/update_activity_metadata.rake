namespace :activities do
  desc "Updates the metadata for activities where the structure of these has changed"
  task update_metadata: :environment do
    class_to_update = ENV.fetch("CLASS_NAME").constantize

    raise "Error: #{class_to_update} is not a subclass of Activity" unless class_to_update.new.is_a?(Activity)

    succeeded = 0
    failed = 0

    puts "Migrating #{class_to_update.count} records of #{class_to_update}"

    class_to_update.find_each do |activity|
      activity.update!(metadata: activity.metadata)
      succeeded += 1
    rescue StandardError
      puts "Updating activity with ID #{activity.id} failed."
      failed += 1
    end

    puts "Finished: #{succeeded} activities updated successfully. #{failed} activities failed to update; see previous log."
  end
end
