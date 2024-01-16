RSpec.describe "Accessibility statement page", type: :request do
  before { get help_accessibility_path }

  it "renders the page" do
    expect(response).to render_template(:accessibility)
  end
end
