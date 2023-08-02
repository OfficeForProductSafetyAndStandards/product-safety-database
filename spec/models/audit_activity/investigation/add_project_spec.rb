require "rails_helper"

RSpec.describe AuditActivity::Investigation::AddProject, :with_stubbed_mailer do
  let(:factory) { :project }

  it_behaves_like "an audit activity for investigation added"
end
