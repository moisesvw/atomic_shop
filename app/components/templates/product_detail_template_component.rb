# frozen_string_literal: true

class Templates::ProductDetailTemplateComponent < ViewComponent::Base
  attr_reader :product, :variants, :available_options, :selected_variant,
              :selected_options, :reviews, :related_products

  def initialize(product:, variants:, available_options:, selected_variant: nil,
                 selected_options: {}, reviews: [], related_products: [])
    @product = product
    @variants = variants
    @available_options = available_options
    @selected_variant = selected_variant
    @selected_options = selected_options
    @reviews = reviews
    @related_products = related_products
  end

  def has_related_products?
    related_products.any?
  end

  def breadcrumb_items
    [
      { name: "Home", url: "/" },
      { name: product.category.name, url: "/categories/#{product.category.id}" },
      { name: product.name, url: nil }
    ]
  end
end
