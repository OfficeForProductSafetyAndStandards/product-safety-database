require "rails_helper"

RSpec.describe ProductsDecorator, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_antivirus do
  let(:investigation) { create(:project) }
  let!(:products) { create_list :product, 3, :with_images, image_count: image_count, investigations: [investigation] }
  let(:products_remaining) { image_count - described_class::PRODUCT_IMAGE_DISPLAY_LIMIT }

  subject { described_class.decorate(products) }

  describe "#image_list" do
    let(:image_list) { Capybara.string(subject) }
    context "with 6 images or less" do
      let(:image_count) { 6 }

      it "lists all the images" do
        products.each do |product|
          expect(subject.image_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not displays a link to see all attached images" do
        expect(subject.image_list).to_not have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with 7 images" do
      let(:image_count) { 7 }

      it "list all the images" do
        products.each do |product|
          expect(subject.image_list).to have_link(product.name, href: product_path(product))
        end
      end

      it "does not displays a link to see all attached images" do
        expect(subject.image_list).to_not have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end

    context "with more than 8 images" do
      let(:image_count) { 6 }
      let!(:products_not_to_display) { create_list :product, 2, :with_images, investigations: [investigation] }

      it "lists the first 6 images" do
        products.each do |product|
          expect(subject.image_list).to have_link(product.name, href: product_path(product))
        end
        products_not_to_display.each do |product|
          expect(subject.image_list).to_not have_link(product.name, href: product_path(product))
        end
      end

      it "displays a link to see all attached images" do
        expect(subject.image_list).to have_link("View #{products_remaining} more products...", href: investigation_products_path(investigation))
      end
    end
  end
end
