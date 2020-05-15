class CommentActivity < Activity
  include SanitizationHelper
  before_validation { trim_line_endings(:body) }
  validates :body, presence: true
  validates :body, length: { maximum: 10_000 }

  def title
    "Comment added"
  end

  def search_index
    body
  end

  def email_update_text(viewer = nil)
    "#{source&.show(viewer)} commented on the #{investigation.case_type}."
  end

private

  def subtitle_slug
    "Comment added"
  end
end
