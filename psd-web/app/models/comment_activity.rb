class CommentActivity < Activity
  include SanitizationHelper
  before_validation { trim_line_endings(:body) }
  validates :body, presence: true
  validates_length_of :body, maximum: 10000

  def title
    "Comment added"
  end

  def subtitle_slug
    "Comment added"
  end

  def search_index
    body
  end

  def email_update_text
    "#{source&.show} commented on the #{investigation.case_type}."
  end
end
