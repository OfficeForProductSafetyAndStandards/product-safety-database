require "rails_helper"

RSpec.describe "Export investigations as XLSX file", :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  # rubocop:disable RSpec/ExampleLength
  describe "#index as XLSX" do
    let(:user) { create(:user, :activated, :psd_user, :viewed_introduction) }
    let(:temp_dir) { "spec/tmp/" }
    let(:export_path) { Rails.root + temp_dir + "export_cases.xlsx" }
    let(:exported_data) do
      File.open(export_path, "w") { |f| f.write response.body }
      Roo::Excelx.new(export_path).sheet("Cases")
    end

    before do
      Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)
      sign_in(user)
    end

    after { File.delete(export_path) }

    it "exports all the investigations into a XLSX file" do
      create_list(:allegation, 5)
      Investigation.import refresh: true, force: true

      get investigations_path format: :xlsx

      expect(exported_data.last_row).to eq(Investigation.count + 1)
    end

    it "treats formulas as text" do
      create(:allegation, description: "=A1")
      Investigation.import refresh: true, force: true

      get investigations_path format: :xlsx, params: { q: "A1" }

      cell_a1 = exported_data.cell(1, 1)
      cell_with_formula_as_description = exported_data.cell(2, 5)

      aggregate_failures "cell value checks" do
        expect(cell_with_formula_as_description).to eq "=A1"
        expect(cell_with_formula_as_description).not_to eq cell_a1
        expect(cell_with_formula_as_description).not_to eq nil
      end
    end

    it "exports coronavirus flag" do
      create(:allegation, coronavirus_related: true)
      Investigation.import refresh: true, force: true

      get investigations_path format: :xlsx

      coronavirus_cell_title = exported_data.cell(1, 8)
      coronavirus_cell_content = exported_data.cell(2, 8)

      aggregate_failures "coronavirus cells values" do
        expect(coronavirus_cell_title).to eq "Coronavirus_Related"
        expect(coronavirus_cell_content).to eq "true"
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
