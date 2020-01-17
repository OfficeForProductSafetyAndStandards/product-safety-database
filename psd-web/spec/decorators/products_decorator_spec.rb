require "rails_helper"

RSpec.describe ProductsDecorator, :with_stubbed_elasticsearch do
  let!(:products) { create_list :product, 3, :with_images }

  subject { described_class.decorate(products) }

  describe "#image_list" do
    let(:image_list) { Capybara.string(subject) }
    context "with 6 images or less" do
      it "lists all the images" do
        products.each do |product|
          expect(subject.image_list).to have_link(product.name, href: product_path(product))
        end
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
