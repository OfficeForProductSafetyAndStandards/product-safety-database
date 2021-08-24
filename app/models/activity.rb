class Activity < ApplicationRecord
  belongs_to :investigation, touch: true

  has_one :source, as: :sourceable, dependent: :destroy

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

  def subtitle(viewer)
    "#{subtitle_slug} by #{source&.show(viewer)}, #{pretty_date_stamp}"
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
    created_at.to_s(:govuk)
  end

  def subtitle_slug; end
end
