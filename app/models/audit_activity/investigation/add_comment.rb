class AuditActivity::Investigation::AddComment < AuditActivity::Base
  def self.build_metadata(body)
    {
      comment_text: body
    }
  end

  def title(*)
    "Comment added"
  end

  def subtitle_slug
    "Comment added"
  end
end
