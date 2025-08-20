# frozen_string_literal: true

class Organisms::ProductGridComponent < ViewComponent::Base
  attr_reader :products, :title, :columns

  def initialize(products:, title: nil, columns: 3)
    @products = products
    @title = title
    @columns = columns
  end

  def grid_classes
    "product-grid grid-cols-#{columns}"
  end
end
