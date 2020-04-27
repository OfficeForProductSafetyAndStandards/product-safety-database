module PermissionNoticeHelper

  def permission_notice(text: text)
    tag.div class: "app-permission-notice" do
      tag.p text, class: "govuk-body"
    end
  end
end
