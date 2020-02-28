require "rails_helper"

RSpec.describe CommonPasswordValidator do
  subject do
    Class.new {
      include ActiveModel::Validations
      attr_accessor :password
      validates :password, common_password: {
        message: "Choose a less frequently used password"
      }
    }.new
  end

  # To avoid tests depending on the actual file content.
  before do
    allow(File).to receive(:foreach).and_yield("password").and_yield("testpassword")
  end

  it "rejects passwords listed in the common passwords file" do
    subject.password = "testpassword"
    expect(subject).not_to be_valid
    expect(subject.errors.messages[:password])
      .to eq ["Choose a less frequently used password"]
  end

  it "accepts passwords not listed in the common passwords file" do
    subject.password = "notCommonPassword123"
    expect(subject).to be_valid
    expect(subject.errors.messages[:password]).to be_empty
  end
end
