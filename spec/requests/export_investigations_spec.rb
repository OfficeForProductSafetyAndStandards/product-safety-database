require "rails_helper"

RSpec.describe "Export investigations as XLSX file", :with_elasticsearch, :with_stubbed_notify, :with_stubbed_mailer, type: :request do
  # rubocop:disable RSpec/ExampleLength
  describe "#index as XLSX" do
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

    context "when logged in as a normal user" do
      let(:user) { create(:user, :activated, :viewed_introduction) }

      it "shows a forbidden error", :with_errors_rendered, :aggregate_failures do
        get investigations_path format: :xlsx

        expect(response).to render_template("errors/forbidden")
        expect(response).to have_http_status(403)
      end
    end

    context "when logged in as a user with the psd_admin role" do
      let(:user) { create(:user, :activated, :psd_admin, :viewed_introduction) }

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

      it "exports categories" do
        product_category = Faker::Hipster.word
        category = Faker::Hipster.word
        create(:allegation, product_category: product_category, products: [create(:product, category: category)])
        Investigation.import refresh: true, force: true

        get investigations_path format: :xlsx

        categories_cell_title = exported_data.cell(1, 6)
        categories_cell_content = exported_data.cell(2, 6)

        aggregate_failures "categories cells values" do
          expect(categories_cell_title).to eq "Product_Category"
          expect(categories_cell_content).to eq "#{product_category}, #{category}"
        end
      end

      it "exports the case risk level" do
        investigation = create(:allegation)
        ChangeCaseRiskLevel.call!(
          investigation: investigation,
          user:
            user,
          risk_level: (Investigation.risk_levels.values - %w[other]).sample
        )

        Investigation.import refresh: true, force: true

        get investigations_path format: :xlsx

        categories_cell_title = exported_data.cell(1, 9)
        categories_cell_content = exported_data.cell(2, 9)

        aggregate_failures "risk level cells values" do
          expect(categories_cell_title).to eq "Risk_Level"
          expect(categories_cell_content).to eq investigation.decorate.risk_level_description
        end
      end

      it "exports owner team and user" do
        user = create(:user)
        team = create(:team)
        case_with_user_owner = create(:allegation, creator: user)
        case_with_team_owner = create(:allegation, creator: user)

        ChangeCaseOwner.call!(investigation: case_with_team_owner, user: user, owner: team)

        Investigation.import refresh: true, force: true

        get investigations_path format: :xlsx

        aggregate_failures do
          expect(exported_data.cell(1, 10)).to eq "Case_Owner_Team"
          expect(exported_data.cell(1, 11)).to eq "Case_Owner_User"

          expect(exported_data.cell(2, 1)).to eq case_with_team_owner.pretty_id
          expect(exported_data.cell(2, 10)).to eq team.name
          expect(exported_data.cell(2, 11)).to be_nil

          expect(exported_data.cell(3, 1)).to eq case_with_user_owner.pretty_id
          expect(exported_data.cell(3, 10)).to eq user.team.name
          expect(exported_data.cell(3, 11)).to eq user.name
        end
      end

      it "exports created_at and updated_at" do
        investigation = create(:allegation)

        Investigation.import refresh: true, force: true

        get investigations_path format: :xlsx

        aggregate_failures do
          expect(exported_data.cell(1, 20)).to eq "Date_Created"
          expect(exported_data.cell(1, 21)).to eq "Last_Updated"
          expect(exported_data.cell(2, 20)).to eq investigation.created_at.strftime("%Y-%m-%d %H:%M:%S %z")
          expect(exported_data.cell(2, 21)).to eq investigation.updated_at.strftime("%Y-%m-%d %H:%M:%S %z")
        end
      end

      context "when investigation is open" do
        it 'date_closed column is empty' do
          investigation = create(:allegation)

          Investigation.import refresh: true, force: true

          get investigations_path format: :xlsx

          aggregate_failures do
            expect(exported_data.cell(1, 22)).to eq "Date_Closed"
            expect(exported_data.cell(2, 22)).to eq nil
          end
        end
      end

      context "when investigation is closed" do
        it 'date_closed column is empty' do
          investigation = create(:allegation, is_closed: true, date_closed: Date.yesterday)

          Investigation.import refresh: true, force: true

          get investigations_path, params: { status_closed: "checked", format: :xlsx }

          aggregate_failures do
            expect(exported_data.cell(1, 22)).to eq "Date_Closed"
            expect(exported_data.cell(2, 22)).to eq Date.yesterday.strftime("%Y-%m-%d %H:%M:%S %z")
          end
        end
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
