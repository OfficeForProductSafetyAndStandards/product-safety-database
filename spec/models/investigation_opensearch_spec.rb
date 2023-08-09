require "rails_helper"

RSpec.describe Investigation, :with_stubbed_mailer, :with_stubbed_notify do
  it_behaves_like "a batched search model" do
    let(:factory_name) { :allegation }
  end
end
