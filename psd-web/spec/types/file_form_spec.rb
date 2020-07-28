require "rails_helper"

RSpec.describe FileForm do
  subject(:active_model_type) { described_class.new }

  let(:new_file_description) { "new file description" }

  describe "#cast" do
    let(:file) do
      {
        file: fixture_file_upload(file_fixture("corrective_action.txt")),
        description: new_file_description
      }
    end

    context "with a hash from params" do
      it "casts the file form into a file", :aggregate_failures do
        casted = active_model_type.cast(file)
        expect(casted).to be_instance_of(UploadedFile)
        expect(casted).to have_attributes(file: instance_of(Rack::Test::UploadedFile), description: new_file_description)
      end
    end
  end
end
