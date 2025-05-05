class Organisms::ProductDetailComponent < ViewComponent::Base
  attr_reader :product, :variants, :available_options, :selected_variant,
              :selected_options, :reviews, :classes

  def initialize(product:, variants:, available_options:, selected_variant:,
                 selected_options: {}, reviews: [], classes: "")
    @product = product
    @variants = variants
    @available_options = available_options
    @selected_variant = selected_variant
    @selected_options = selected_options
    @reviews = reviews
    @classes = classes
  end

  def detail_classes
    base_classes = [ "product-detail" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def product_image
    # In a real application, this would handle product images
    # For now, we'll use a placeholder
    "https://via.placeholder.com/600x600"
  end

  def in_stock?
    selected_variant&.in_stock? || false
  end

  def available_quantity
    selected_variant&.stock_quantity || 0
  end

  def low_stock?
    in_stock? && available_quantity <= 5
  end

  def has_reviews?
    reviews.any?
  end

  def average_rating
    product.average_rating
  end
end
