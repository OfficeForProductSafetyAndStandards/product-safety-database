require "rails_helper"

RSpec.describe Product do
  it_behaves_like "a batched search model" do
    let(:factory_name) { :product }
  end
end
