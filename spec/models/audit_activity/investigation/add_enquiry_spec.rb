RSpec.describe AuditActivity::Investigation::AddEnquiry, :with_stubbed_mailer do
  let(:factory) { :enquiry }

  it_behaves_like "an audit activity for investigation added"
end
