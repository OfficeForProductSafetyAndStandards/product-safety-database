RSpec.describe AuditActivity::Investigation::AddAllegation, :with_stubbed_mailer do
  let(:factory) { :allegation_unsafe }

  it_behaves_like "an audit activity for investigation added"
end
