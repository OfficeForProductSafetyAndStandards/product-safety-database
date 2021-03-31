namespace :products do
  desc "Updates category for products with categroy of motor vehicles"
  task update_motor_vehicle_category: :environment do
    Product.where(category: "Motor vehicles").update_all(category: "Motor vehicles (including spare parts)")
  end
end
