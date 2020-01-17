require "rails_helper"

RSpec.describe ProductsDecorator do
  let(:produts) { create_list :product, 3 }

  describe "#image_list" do
    context "with 6 images or less" do
      it "lists all the images" do
      end
    end

    context "with 7 images" do
      it "list all the images" do
      end
    end

    context "with more than 8 images" do
      it "lists the first 6 images" do
      end

      it "displays a link to see all attached images"
    end
  end
end
