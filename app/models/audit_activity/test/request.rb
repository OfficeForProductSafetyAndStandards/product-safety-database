# Recording of test requests is deprecated - existing data is still supported
class AuditActivity::Test::Request < AuditActivity::Test::Base
  def readonly?
    true
  end

private

  def subtitle_slug
    "Testing requested"
  end
end
