class Activity < ApplicationRecord
  belongs_to :investigation, touch: true

  has_one :source, as: :sourceable, dependent: :destroy

  after_save :notify_relevant_users

  def attached_image?
    nil
  end

  def has_attachment?
    false
  end

  def attachments
    {}
  end

  def subtitle
    "#{subtitle_slug} by #{source&.show}, #{pretty_date_stamp}"
  end

  def search_index;  end

  def self.sanitize_text(text)
    return text.to_s.strip.gsub(/[*_~]/) { |match| "\\#{match}" } if text
  end

  def can_display_all_data?(_user)
    true
  end

  def restricted_title
    # where necessary should be implemented by subclasses
  end

  def email_update_text(viewer = nil); end

  def email_subject_text
    "#{investigation.case_type.upcase_first} updated"
  end

  # Used to determine which view template to use for new records with metadata
  # instead of pre-generated HTML
  def template_name
    self.class.name.delete_prefix("AuditActivity::").underscore
  end

private

  def pretty_date_stamp
    created_at.to_s(:govuk)
  end

  def subtitle_slug; end

  def notify_relevant_users
    entities_to_notify.each do |entity|
      email = entity.is_a?(Team) ? entity.team_recipient_email : entity.email
      NotifyMailer.investigation_updated(investigation.pretty_id, entity.name, email, email_update_text(entity), email_subject_text).deliver_later
    end
  end

  def entities_to_notify
    entities = users_to_notify

    teams_to_notify.each do |team|
      if team.team_recipient_email.present?
        entities << team
      else
        users_from_team = team.users.active
        entities.concat(users_from_team)
      end
    end

    entities.uniq
  end

  def users_to_notify
    return [] unless investigation.owner.is_a? User
    return [] if source&.user == investigation.owner

    [investigation.owner]
  end

  def teams_to_notify
    return [] unless investigation.owner.is_a? Team
    return [] if source&.user&.team == investigation.owner

    [investigation.owner]
  end
end
