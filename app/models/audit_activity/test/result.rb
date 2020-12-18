class AuditActivity::Test::Result < AuditActivity::Test::Base
  def self.build_metadata(test_result)
    { test_result_id: test_result.id }
  end

  def self.from(_test_result)
    raise "Deprecated - use AddTestResultToInvestigation.call instead"
  end

  def title(_viewing_user = nil)
    return super if metadata.nil?

    test_result.decorate.title
  end

  # Returns the actual Test::Result record.
  #
  # This is a hack, as there is currently no direct association between the
  # AuditActivity record and the test result record it is about. So the only
  # way to retrieve this is by relying upon our current behaviour of attaching the
  # same actual file to all of the AuditActivity, Investigation and Test records.
  def test_result
    return if metadata.nil?

    @test_result ||= Test::Result.find(metadata["test_result_id"])
  end

private

  def subtitle_slug
    "Test result recorded"
  end

  # Do not send investigation_updated mail when test result updated. This
  # overrides inherited functionality in the Activity model :(
  def notify_relevant_users; end
end
