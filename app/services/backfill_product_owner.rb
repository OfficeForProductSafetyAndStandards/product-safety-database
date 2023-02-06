class BackfillProductOwner
  def self.call
    unowned_products = Product.includes(:investigations).where(owning_team_id: nil)

    unowned_products.each do |product|
      next if product.investigations.empty? || product.investigations.first.is_closed

      product.update!(owning_team_id: product.investigations.first.owner_team.id)
    end
  end
end
