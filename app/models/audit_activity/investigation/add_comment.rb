class AuditActivity::Investigation::AddComment < AuditActivity::Base
  def self.build_metadata(body)
    {
      comment_text: body
    }
  end

  def title(*)
    "Add comment"
  end

  def subtitle_slug
    "Added"
  end
end
