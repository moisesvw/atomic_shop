# frozen_string_literal: true

class Pages::ProductDetailPageComponent < ViewComponent::Base
  attr_reader :product, :selected_variant_id, :selected_options

  def initialize(product:, selected_variant_id: nil, selected_options: {})
    @product = product
    @selected_variant_id = selected_variant_id
    @selected_options = selected_options
  end

  def variants
    @variants ||= product.product_variants
  end

  def selected_variant
    @selected_variant ||= if selected_variant_id
                            variants.find { |v| v.id == selected_variant_id.to_i }
    elsif selected_options.present?
                            find_variant_by_options
    else
                            variants.first
    end
  end

  def available_options
    @available_options ||= build_available_options
  end

  def reviews
    @reviews ||= product.reviews.includes(:user).order(created_at: :desc)
  end

  def related_products
    @related_products ||= Product.where(category_id: product.category_id)
                                 .where.not(id: product.id)
                                 .limit(4)
  end

  def page_title
    "#{product.name} - AtomicShop"
  end

  def meta_description
    "Shop #{product.name} at AtomicShop. #{product.description.truncate(100)}"
  end

  private

  def build_available_options
    options = {}

    variants.each do |variant|
      variant_options = variant.options_hash

      variant_options.each do |name, value|
        options[name] ||= []
        options[name] << value unless options[name].include?(value)
      end
    end

    options
  end

  def find_variant_by_options
    variants.find do |variant|
      variant_options = variant.options_hash
      selected_options.all? { |name, value| variant_options[name.to_s] == value.to_s }
    end
  end
end
