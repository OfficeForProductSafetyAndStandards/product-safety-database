class SendReminderEmailDraftNotificationsJob < ApplicationJob
  DRAFT_NOTIFICATION_RULES = [
    { days_old: 75, remaining_days: 15, last_reminder: false },
    { days_old: 80, remaining_days: 10, last_reminder: false },
    { days_old: 87, remaining_days: 3, last_reminder: true }
  ].freeze

  def perform
    return unless Flipper.enabled?(:submit_notification_reminder)

    send_reminder_emails
  end

private

  def send_reminder_emails
    DRAFT_NOTIFICATION_RULES.each do |rule|
      days_old = rule[:days_old]
      remaining_days = rule[:remaining_days]
      last_reminder = rule[:last_reminder]
      last_line = reminder_last_line(last_reminder)
      drafts = fetch_drafts(days_old)
      send_mails(drafts, days_old, remaining_days, last_reminder, last_line)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send reminder emails for drafts days old due to: #{e.message}"
  end

  def fetch_drafts(days_old)
    Investigation::Notification
    .where(state: "draft")
    .where(updated_at: days_old.days.ago.beginning_of_day..days_old.days.ago.end_of_day)
  end

  def send_mails(drafts, days_old, remaining_days, last_reminder, last_line)
    drafts.each do |draft|
      next unless (user = find_user(draft))

      draft_title = get_draft_title(draft)
      NotifyMailer.send_email_reminder(
        user: user,
        remaining_days: remaining_days,
        days: days_old,
        title: draft_title,
        pretty_id: draft.pretty_id,
        last_reminder: last_reminder,
        last_line: last_line
      )
    end
  end

  def find_user(draft)
    User.find_by(id: draft.creator_user.id) unless draft.creator_user.nil?
  end

  def get_draft_title(draft)
    draft.user_title? ? draft.user_title : "Untitled Draft Notification - Last updated #{draft&.updated_at&.to_formatted_s(:govuk)}"
  end

  def reminder_last_line(last_reminder)
    if last_reminder
      "This will be the final reminder before the notification will be automatically deleted in 3 days, if the status remains on 'Draft'."
    else
      "If the status of this notification remains in 'Draft', another reminder email will be sent in the next coming days."
    end
  end
end
