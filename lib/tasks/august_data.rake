namespace :data do
  desc "Change case type to allegations"
  task change_case_allegations: :environment do
    case_ids = %w[
      2111-0322
      2111-0325
      2111-0352
      2111-0353
      2112-0462
      2112-0463
      2201-0346
      2201-0410
      2201-0413
      2201-0417
      2201-0421
      2201-0426
      2201-0434
      2201-0438
      2201-0460
      2201-0462
      2201-0463
      2202-0193
      2202-0198
      2202-0229
      2202-0231
      2202-0316
      2202-0326
      2202-0329
      2202-0335
      2202-0337
      2202-0338
      2202-0339
      2202-0341
      2202-0343
      2202-0344
      2202-0345
      2202-0347
      2202-0395
      2204-0124
      2204-0206
      2204-0207
      2204-0243
      2204-0273
      2204-0277
      2204-0281
      2206-0003
      2206-0064
      2206-0145
      2206-0151
      2206-0282
      2207-0011
      2207-0014
      2207-0028
      2207-0029
      2207-0058
      2208-0013
      2208-0015
      2208-0032
      2208-0033
      2208-0036
      2208-0041
      2208-0043
      2208-0046
      2208-0048
      2208-0050
      2208-0051
      2208-0054
      2208-0055
      2208-0060
      2208-0087
      2208-0089
      2208-0090
      2208-0091
      2208-0092
      2208-0127
      2208-0230
      2208-0235
      2208-0251
      2208-0253
      2208-0258
      2208-0264
      2208-0268
      2208-0322
      2209-0108
      2301-0014
      2107-0076
      2111-0057
      2112-0549
      2106-0083
      2108-0271
      2201-0401
      2205-0014
      2204-0288
      2206-0419
      2205-0187
      2205-0006
      2205-0115
      2205-0117
      2205-0215
    ]

    Investigation.where(pretty_id: case_ids).update_all(type: "Investigation::Allegation")
  end

  desc "Change case type to notifications"
  task change_case_notifications: :environment do
    case_ids = %w[2112-0571 2201-0277 2201-0309 2201-0311 2203-0104 2203-0299 2204-0275 2206-0016 2206-0335 2208-0242]
    Investigation.where(pretty_id: case_ids).update_all(type: "Investigation::Case")
  end

  desc "Soft delete cases"
  task soft_delete_case: :environment do
    case_ids = %w[2203-0371]
    Investigation.where(pretty_id: case_ids).update_all(deleted_at: Time.zone.now)
  end

  desc "Update product categories"
  task update_product_categories: :environment do
    ids = %w[5484]
    Product.where(id: ids).update_all(category: "Food imitation product")

    product_ids = %w[6540 6541]
    Product.where(id: product_ids).update_all(category: "Laser pointers")

    old_category = "Childcare articles and children’s equipment"
    new_category = "Childcare articles and children's equipment"
    Product.where(category: old_category).update_all(category: new_category)

    Product.where(category: "Hand sanitiser").update_all(category: "Chemical products")
    Product.where(category: "Low voltage equipment (including plugs and sockets)").update_all(category: "Electrical appliances and equipment")
    Product.where(category: "Lasers").update_all(category: "Laser pointers")
    Product.where(category: "Baby/children's products").update_all(category: "Childcare articles and children's equipment")
  end
end
