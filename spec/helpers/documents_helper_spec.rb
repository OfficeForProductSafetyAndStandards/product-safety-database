require "rails_helper"

RSpec.describe DocumentsHelper, type: :helper do
  let(:document) { instance_double(Document, filename: "test.pdf", content_type: "application/pdf") }
  let(:file) { FileStruct.new("test_file.pdf", blob) }
  let(:blob) { instance_double(ActiveStorage::Blob, byte_size: 1024, metadata: { updated: "2023-07-30T12:00:00Z" }) }

  FileStruct = Struct.new(:filename, :blob)

  describe "#document_placeholder" do
    it "renders the placeholder partial" do
      allow(helper).to receive(:render).with("documents/placeholder", document:)
      helper.document_placeholder(document)
      expect(helper).to have_received(:render).with("documents/placeholder", document:)
    end
  end

  describe "#document_file_extension" do
    it "returns the file extension in uppercase without a period" do
      expect(helper.document_file_extension(document)).to eq("PDF")
    end
  end

  describe "#filename_with_size" do
    it "returns the filename with human readable size" do
      expect(helper.filename_with_size(file)).to eq("test_file.pdf (1 KB)")
    end
  end

  describe "#pretty_type_description" do
    before do
      allow(document).to receive_messages(audio?: false, image?: false, video?: false, text?: false)
    end

    it "returns 'PDF document' for a pdf file" do
      expect(helper.pretty_type_description(document)).to eq("PDF document")
    end

    it "returns 'Word document' for a pdf file" do
      allow(document).to receive(:content_type).and_return("application/msword")
      expect(helper.pretty_type_description(document)).to eq("Word document")
    end

    it "returns 'Excel document' for a pdf file" do
      allow(document).to receive(:content_type).and_return("application/vnd.ms-excel")
      expect(helper.pretty_type_description(document)).to eq("Excel document")
    end

    it "returns 'PowerPoint document' for a pdf file" do
      allow(document).to receive(:content_type).and_return("application/vnd.ms-powerpoint")
      expect(helper.pretty_type_description(document)).to eq("PowerPoint document")
    end

    it "returns 'audio' for an audio file" do
      allow(document).to receive(:audio?).and_return(true)
      expect(helper.pretty_type_description(document)).to eq("audio")
    end

    it "returns 'image' for an image file" do
      allow(document).to receive(:image?).and_return(true)
      expect(helper.pretty_type_description(document)).to eq("image")
    end

    it "returns 'video' for a video file" do
      allow(document).to receive(:video?).and_return(true)
      expect(helper.pretty_type_description(document)).to eq("video")
    end

    it "returns 'text document' for a text file" do
      allow(document).to receive(:text?).and_return(true)
      expect(helper.pretty_type_description(document)).to eq("text document")
    end
  end

  describe "#spreadsheet?" do
    it "returns true for an Excel file" do
      allow(document).to receive(:content_type).and_return("application/vnd.ms-excel")
      expect(helper).to be_spreadsheet(document)
    end

    it "returns false for a non-Excel file" do
      allow(document).to receive(:content_type).and_return("application/pdf")
      expect(helper).not_to be_spreadsheet(document)
    end
  end

  describe "#formatted_file_updated_date" do
    it "returns formatted updated date" do
      expect(helper.formatted_file_updated_date(file)).to eq("Updated 30 July 2023")
    end
  end

  describe "#file_updated_date_in_govuk_format" do
    it "returns the updated date in GOV.UK format" do
      expect(helper.file_updated_date_in_govuk_format(file)).to eq("30 July 2023")
    end
  end

  describe "#documentable_policy" do
    let(:current_user) { instance_double(User) }
    let(:record) { instance_double(Record) }
    let(:policy) { instance_double(DocumentablePolicy) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
      allow(DocumentablePolicy).to receive(:new).with(current_user, record).and_return(policy)
    end

    it "returns an instance of DocumentablePolicy with current user and record" do
      expect(helper.documentable_policy(record)).to eq(policy)
    end
  end
end
