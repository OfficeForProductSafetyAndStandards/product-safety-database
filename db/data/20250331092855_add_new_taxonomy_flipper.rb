# frozen_string_literal: true

class AddNewTaxonomyFlipper < ActiveRecord::Migration[7.1]
  def up
    Flipper.enable(:new_taxonomy)
  end

  def down
    Flipper.disable(:new_taxonomy)
  end
end
