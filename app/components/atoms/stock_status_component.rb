# frozen_string_literal: true

class Atoms::StockStatusComponent < ViewComponent::Base
  attr_reader :stock_quantity, :low_stock_threshold, :show_quantity, :size, :classes

  def initialize(stock_quantity:, low_stock_threshold: 5, show_quantity: false, size: :medium, classes: "")
    @stock_quantity = stock_quantity
    @low_stock_threshold = low_stock_threshold
    @show_quantity = show_quantity
    @size = size
    @classes = classes
  end

  def status_classes
    base_classes = [ "stock-status" ]
    base_classes << status_class
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def status_class
    if out_of_stock?
      "out-of-stock"
    elsif low_stock?
      "low-stock"
    else
      "in-stock"
    end
  end

  def status_text
    if out_of_stock?
      "Out of Stock"
    elsif low_stock?
      "Low Stock"
    else
      "In Stock"
    end
  end

  def in_stock?
    stock_quantity && stock_quantity > 0
  end

  def out_of_stock?
    !in_stock?
  end

  def low_stock?
    in_stock? && stock_quantity <= low_stock_threshold
  end
end
