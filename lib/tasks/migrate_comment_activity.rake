namespace :comments do
  desc "Updates CommentActivity to the new activity type AuditActivity::Investigation::AddComment"
  task update: :environment do
    comment_activities = Activity.where(type: "CommentActivity")
    puts "Updating #{comment_activities.count} old comments"

    comment_activities.find_each(batch_size: 50) do |comment|
      comment.update!(type: AuditActivity::Investigation::AddComment, metadata: { comment_text: comment.body }, body: nil)
      puts "#{comment.id} updated"
    end
  end
end
