class MakeCategoryOptionalForProducts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :products, :category_id, true
  end
end
