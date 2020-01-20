require "rails_helper"

RSpec.describe ProductsDecorator, :with_stubbed_mailer, :with_stubbed_elasticsearch, :with_stubbed_antivirus do
  let(:investigation) { create(:project) }
  let!(:products) { create_list :product, 3, :with_images, image_count: image_count, investigations: [investigation] }
  let(:products_remaining) { image_count - described_class::PRODUCT_IMAGE_DISPLAY_LIMIT }

  subject { described_class.decorate(products) }
end
