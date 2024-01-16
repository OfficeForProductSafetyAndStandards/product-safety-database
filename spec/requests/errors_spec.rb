RSpec.describe "Error pages", type: :request do
  describe "/404" do
    before { get "/404" }

    it "returns a 404 Not Found status code" do
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "/500" do
    before { get "/500" }

    it "returns a 500 Internal Server Error status code" do
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "/503" do
    before { get "/503" }

    it "returns a 503 Service Unavailable status code" do
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
