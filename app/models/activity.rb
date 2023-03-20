class Activity < ApplicationRecord
  belongs_to :investigation, touch: true
  belongs_to :added_by_user, class_name: :User, optional: true

  redacted_export_with :id, :added_by_user_id, :business_id, :correspondence_id,
                       :created_at, :investigation_id, :investigation_product_id,
                       :type, :updated_at

  visitable :ahoy_visit

  def has_attachment?
    false
  end

  def attachments
    {}
  end

  # Can be overridden by child classes but sometimes need to pass in user
  def title(_user = nil)
    super()
  end

  # TODO: Should be moved to the decorator
  def subtitle(viewer)
    "#{subtitle_slug} by #{added_by_user&.decorate&.display_name(viewer:)}, #{pretty_date_stamp}"
  end

  def search_index; end

  def self.sanitize_text(text)
    return text.to_s.strip.gsub(/[*_~]/) { |match| "\\#{match}" } if text
  end

  def can_display_all_data?(_user)
    true
  end

  def restricted_title(_user)
    # where necessary should be implemented by subclasses
  end

  # Used to determine which view template to use for new records with metadata
  # instead of pre-generated HTML
  def template_name
    self.class.name.delete_prefix("AuditActivity::").underscore
  end

private

  def pretty_date_stamp
    created_at.to_formatted_s(:govuk)
  end

  def subtitle_slug; end
end
