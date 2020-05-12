class AuditActivity::Document::Update < AuditActivity::Document::Base
  def self.from(document, investigation, previous_data)
    return if no_change?(document, previous_data)

    if title_changed?(document, previous_data)
      title = "Updated: #{document.metadata[:title] || 'Untitled document'} (was: #{previous_data[:title] || 'Untitled document'})"
    elsif description_changed?(document, previous_data)
      title = "Updated: Description for #{document.metadata[:title]}"
    end
    super(document, investigation, title)
  end

  def self.no_change?(document, previous_data)
    document.metadata[:title] == previous_data[:title] && document.metadata[:description] == previous_data[:description]
  end

  def self.title_changed?(document, previous_data)
    document.metadata[:title] != previous_data[:title]
  end

  def self.description_changed?(document, previous_data)
    document.metadata[:description] != previous_data[:description]
  end

  def restricted_title
    "Document updated"
  end

  def email_update_text(viewer = nil)
    "Document attached to the #{investigation.case_type.upcase_first} was updated by #{source&.show(viewer)}."
  end

private

  def subtitle_slug
    "#{attachment_type} details updated"
  end
end
