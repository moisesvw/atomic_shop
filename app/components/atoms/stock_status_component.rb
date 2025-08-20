# frozen_string_literal: true

class Atoms::StockStatusComponent < ViewComponent::Base
  attr_reader :in_stock, :quantity, :low_stock_threshold, :show_quantity, :classes

  def initialize(in_stock:, quantity: nil, low_stock_threshold: 5, show_quantity: false, classes: "")
    @in_stock = in_stock
    @quantity = quantity
    @low_stock_threshold = low_stock_threshold
    @show_quantity = show_quantity
    @classes = classes
  end

  def status_classes
    base_classes = [ "stock-status" ]
    base_classes << status_class
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def status_class
    if !in_stock
      "out-of-stock"
    elsif low_stock?
      "low-stock"
    else
      "in-stock"
    end
  end

  def status_text
    if !in_stock
      "Out of Stock"
    elsif low_stock?
      "Low Stock"
    else
      "In Stock"
    end
  end

  def low_stock?
    in_stock && quantity && quantity <= low_stock_threshold
  end
end
