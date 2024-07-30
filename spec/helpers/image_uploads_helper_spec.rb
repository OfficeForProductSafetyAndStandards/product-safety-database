require "rails_helper"

RSpec.describe ImageUploadsHelper, :with_opensearch, :with_product_form_helper, :with_stubbed_antivirus, :with_stubbed_mailer, type: :helper do
  let(:user) { create(:user, :opss_user, :activated, has_viewed_introduction: true, roles: %w[notification_task_list_user]) }
  let!(:iphone_3g) { create(:product_iphone_3g, brand: "Apple", created_at: 2.days.ago, authenticity: "genuine") }
  let!(:notification) { create(:better_notif) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/testImage.png") }
  let(:image) do
    ActiveStorage::Blob.create_and_upload!(
      io: File.open(image_path, "rb"), # 'rb' mode ensures binary read
      filename: File.basename(image_path),
      content_type: "image/png" # You can use other methods to dynamically determine content type if necessary
    )
  end
  let(:image_upload) do
    ImageUpload.create!(
      file_upload: image, existing_file_upload_file_id: image.signed_id, upload_model: iphone_3g, created_by: user.id
    )
  end
  let(:image_upload_two) do
    ImageUpload.create!(
      file_upload: image, existing_file_upload_file_id: image.signed_id, upload_model: notification, created_by: user.id
    )
  end

  describe "#image_upload_placeholder" do
    it "renders the image upload placeholder partial" do
      allow(helper).to receive(:render).with("image_uploads/placeholder", image: image_upload)
      helper.image_upload_placeholder(image_upload)
      expect(helper).to have_received(:render).with("image_uploads/placeholder", image: image_upload)
    end
  end

  describe "#product_image_preview" do
    it "renders the product image preview partial" do
      allow(helper).to receive(:render).with("products/image_preview", image: image_upload, dimensions: image_upload.file_upload.byte_size)
      helper.product_image_preview(image_upload, image_upload.file_upload.byte_size)
      expect(helper).to have_received(:render).with("products/image_preview", image: image_upload, dimensions: image_upload.file_upload.byte_size)
    end
  end

  describe "#image_upload_file_extension" do
    it "outputs the file type" do
      expect(helper.image_upload_file_extension(image_upload)).to eq "PNG"
    end
  end

  describe "#image_upload_path" do
    it "returns product path when parent is product" do
      expect(helper.image_upload_path(image_upload)).to eq "/products/#{iphone_3g.id}/image_uploads/#{image_upload.id}"
      expect(helper.image_upload_path(image_upload_two)).to eq "/cases/#{notification.pretty_id}/image_uploads/#{image_upload_two.id}"
    end
  end

  describe "#image_upload_filename_with_size" do
    it "returns image name and size" do
      expect(helper.image_upload_filename_with_size(image_upload)).to eq "#{image_upload.file_upload.filename} (#{number_to_human_size(image_upload.file_upload.blob.byte_size)})"
      expect(helper.image_upload_filename_with_size(image_upload)).to eq "#{image_upload.file_upload.filename} (#{number_to_human_size(image_upload.file_upload.blob.byte_size)})"
    end
  end

  describe "#image_upload_pretty_type_description" do
    it "returns image string" do
      expect(helper.image_upload_pretty_type_description).to eq "image"
    end
  end

  describe "#formatted_image_upload_updated_date" do
    it "returns last time time was updated" do
      expect(helper.formatted_image_upload_updated_date(image_upload)).to eq "Updated #{image_upload_updated_date_in_govuk_format image_upload}"
    end
  end
end
