require "rails_helper"
require "prawn"
require "prawn/table"

RSpec.describe GenerateProductRecallPdf, type: :service do
  let(:params) do
    {
      "pdf_title" => "Test PDF Title",
      "alert_number" => "12345",
      "product_type" => "Toy",
      "subcategory" => "Stuffed Animals",
      "product_identifiers" => "123-ABC",
      "product_description" => "A fluffy stuffed bear.",
      "country_of_origin" => "GB",
      "counterfeit" => "counterfeit",
      "risk_type" => "Choking Hazard",
      "risk_level" => "High",
      "risk_description" => "Small parts may be ingested.",
      "corrective_actions" => "Remove from shelves.",
      "online_marketplace" => true,
      "other_marketplace_name" => "Etsy",
      "notified_by" => "John Doe",
      "type" => "product_safety_report",
      "product_image_ids" => %w[1 2]
    }
  end

  let(:product) { instance_double(Product, id: 1, owning_team: instance_double(Team, name: "Safety Team")) }
  let(:file) { Tempfile.new(["product_recall", ".pdf"]) }

  let(:generate_product_recall_pdf) { described_class.new(params, product, file) }

  after do
    file.close
    file.unlink
  end

  describe ".generate_pdf" do
    it "calls the instance method generate_pdf" do
      instance = described_class.new(params, product, file)
      allow(instance).to receive(:generate_pdf)
      instance.generate_pdf
      expect(instance).to have_received(:generate_pdf)
    end
  end

  describe "#generate_pdf" do
    let(:pdf) { Prawn::Document.new }

    let(:document_options) do
      {
        page_size: "A4",
        font_size: 11,
        info: {
          Title: "OPSS - Product Safety Report - Test PDF Title",
          Author: "Safety Team",
          Subject: "Product Safety Report",
          Creator: "Product Safety Database",
          Producer: "Prawn",
          CreationDate: kind_of(Time)
        }
      }
    end

    let(:expected_metadata) do
      {
        Title: "OPSS - Product Safety Report - Test PDF Title",
        Author: "Safety Team",
        Subject: "Product Safety Report",
        Creator: "Product Safety Database",
        Producer: "Prawn",
        CreationDate: kind_of(Time)
      }
    end

    before do
      allow(Prawn::Document).to receive(:new).and_return(pdf)
      allow(pdf).to receive(:font_families).and_return({})
      allow(pdf).to receive(:font)
      allow(pdf).to receive(:table)
      allow(pdf).to receive(:repeat)
      allow(pdf).to receive(:render)
      allow(pdf).to receive(:bounding_box)
      allow(pdf).to receive(:text_box)
      allow(pdf).to receive(:make_cell)
      allow(File).to receive(:open).and_call_original
      generate_product_recall_pdf.generate_pdf
    end

    it "creates a new PDF document" do
      expect(Prawn::Document).to have_received(:new).with(hash_including(page_size: "A4"))
    end

    it "sets the correct font size" do
      expect(Prawn::Document).to have_received(:new).with(hash_including(font_size: 11))
    end

    it "includes the correct metadata" do
      expect(Prawn::Document).to have_received(:new).with(hash_including(info: hash_including(expected_metadata)))
    end
  end

  describe "private methods" do
    describe "#title" do
      it 'returns "Product Safety Report" when type is product_safety_report' do
        expect(generate_product_recall_pdf.send(:title)).to eq("Product Safety Report")
      end

      it 'returns "Product Recall" for other types' do
        params["type"] = "other"
        expect(generate_product_recall_pdf.send(:title)).to eq("Product Recall")
      end
    end

    describe "#country_from_code" do
      it "returns the country name from the code" do
        allow(Country).to receive(:all).and_return([["United Kingdom", "GB"]])
        expect(generate_product_recall_pdf.send(:country_from_code, "GB")).to eq("United Kingdom")
      end

      it "returns the code if the country is not found" do
        allow(Country).to receive(:all).and_return([["United Kingdom", "GB"]])
        expect(generate_product_recall_pdf.send(:country_from_code, "FR")).to eq("FR")
      end
    end

    describe "#counterfeit" do
      it 'returns "Yes" for counterfeit' do
        expect(generate_product_recall_pdf.send(:counterfeit)).to eq("Yes")
      end

      it 'returns "No" for genuine' do
        params["counterfeit"] = "genuine"
        expect(generate_product_recall_pdf.send(:counterfeit)).to eq("No")
      end

      it 'returns "Unsure" for unsure' do
        params["counterfeit"] = "unsure"
        expect(generate_product_recall_pdf.send(:counterfeit)).to eq("Unsure")
      end

      it 'returns "Unknown" for nil' do
        params["counterfeit"] = nil
        expect(generate_product_recall_pdf.send(:counterfeit)).to eq("Unknown")
      end
    end

    describe "#online_marketplace" do
      it 'returns "N/A" if online_marketplace is nil' do
        params["online_marketplace"] = nil
        expect(generate_product_recall_pdf.send(:online_marketplace)).to eq("N/A")
      end

      it 'returns "No" if online_marketplace is false' do
        params["online_marketplace"] = false
        expect(generate_product_recall_pdf.send(:online_marketplace)).to eq("No")
      end

      it "returns the other marketplace name if present" do
        expect(generate_product_recall_pdf.send(:online_marketplace)).to eq("Etsy")
      end

      it "returns the online marketplace id if other marketplace name is not present" do
        params["other_marketplace_name"] = nil
        params["online_marketplace_id"] = "123"
        expect(generate_product_recall_pdf.send(:online_marketplace)).to eq("123")
      end
    end
  end
end
