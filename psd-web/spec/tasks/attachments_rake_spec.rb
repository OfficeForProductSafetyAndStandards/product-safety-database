require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change

# rubocop:disable RSpec/DescribeClass
RSpec.describe "rake attachments:delete_activities_from_investigations", :with_stubbed_antivirus, :with_stubbed_elasticsearch, :with_stubbed_mailer, type: :task do
  def attach_file_to(obj, attachments, filename)
    attachments.attach(
      io: File.open(Rails.root.join("test/fixtures/files/attachment_filename.txt")),
      filename: filename,
      content_type: "application/txt"
    )
    obj.save
  end

  context "with investigation attachments pointing to an activity attachment" do
    let(:investigation) { create(:project, :with_document) }
    let(:correspondence) do
      Correspondence::Email.new(correspondence_date: Date.current, investigation: investigation).tap do |c|
        attach_file_to(c, c.email_file, "correspondence_attachment.txt")
      end
    end

    let(:corrective_action) do
      build(:corrective_action, :with_file).tap do |c|
        attach_file_to(c, c.documents, "corrective_action_attachment.txt")
      end
    end

    let(:product) do
      build(:product_iphone).tap do |p|
        attach_file_to(p, p.documents, "product_attachment.txt")
      end
    end

    before do
      investigation.documents.attach(correspondence.email_file.blob)
      investigation.documents.attach(corrective_action.documents.first.blob)
      investigation.products = [product]
      investigation.save
    end

    # rubocop:disable RSpec/ExampleLength
    it "deletes the activities attachments from the investigation", :aggregate_failures do
      expect {
        task.execute
      }.to change {
        investigation.documents_blobs.where(filename: "correspondence_attachment.txt").count
      }.from(1).to(0).and change {
        investigation.documents_blobs.where(filename: "corrective_action_attachment.txt").count
      }.from(1).to(0).and change {
        investigation.documents.count
      }.from(3).to(1)
    end

    it "does not delete the attachments from the activities or product" do
      expect { task.execute }.to(
        not_change(correspondence, :email_file).and(
          not_change(corrective_action, :documents).and(
            not_change { product.documents.count }
          )
        )
      )
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
# rubocop:enable RSpec/DescribeClass
