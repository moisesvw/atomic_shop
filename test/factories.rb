# 🏭 FactoryBot Configuration for Atomic Design Testing
#
# This file defines factories that support our atomic design testing strategy.
# Factories are organized to support testing at different atomic levels:
# - Simple factories for atom testing
# - Composed factories for molecule testing
# - Complex scenarios for organism testing

FactoryBot.define do
  # 👤 User Factory - Foundation for authentication testing
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "SecurePassword123!" }
    first_name { "John" }
    last_name { "Doe" }

    trait :admin do
      # Will be used when we implement role-based authorization
      after(:create) do |user|
        # user.add_role(:admin) - to be implemented with Pundit
      end
    end

    trait :with_addresses do
      after(:create) do |user|
        create_list(:address, 2, addressable: user)
      end
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end

  # 📍 Address Factory - Polymorphic association testing
  factory :address do
    street { "123 Main Street" }
    city { "Anytown" }
    state { "CA" }
    zip { "12345" }
    country { "USA" }

    # Polymorphic association - can belong to user or order
    association :addressable, factory: :user

    trait :shipping_address do
      street { "456 Shipping Lane" }
      city { "Shipping City" }
    end

    trait :billing_address do
      street { "789 Billing Boulevard" }
      city { "Billing City" }
    end
  end

  # 🏷️ Category Factory - Hierarchical data testing
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    description { "A great category for products" }
    sequence(:slug) { |n| "category-#{n}" }
    parent_id { nil }

    trait :with_parent do
      association :parent, factory: :category
    end

    trait :electronics do
      name { "Electronics" }
      slug { "electronics" }
      description { "Electronic devices and accessories" }
    end

    trait :clothing do
      name { "Clothing" }
      slug { "clothing" }
      description { "Fashion and apparel" }
    end
  end

  # 📦 Product Factory - Core domain entity
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { "An amazing product that you'll love" }
    featured { false }
    association :category

    trait :featured do
      featured { true }
    end

    trait :iphone do
      name { "iPhone 15 Pro" }
      description { "The most advanced iPhone ever" }
      association :category, :electronics
    end

    trait :macbook do
      name { "MacBook Pro 16-inch" }
      description { "Supercharged for pros" }
      association :category, :electronics
    end

    trait :with_variants do
      after(:create) do |product|
        create_list(:product_variant, 3, product: product)
      end
    end

    trait :with_reviews do
      after(:create) do |product|
        create_list(:review, 5, product: product)
      end
    end

    trait :complete_product do
      featured { true }
      with_variants
      with_reviews
    end
  end

  # 🔧 ProductVariant Factory - Complex options testing
  factory :product_variant do
    association :product
    sequence(:sku) { |n| "SKU-#{n.to_s.rjust(6, '0')}" }
    price_cents { rand(1000..50000) }
    currency { "USD" }
    stock_quantity { rand(0..100) }
    weight { rand(0.1..5.0).round(2) }
    options { {} }

    trait :in_stock do
      stock_quantity { rand(10..100) }
    end

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :low_stock do
      stock_quantity { rand(1..5) }
    end

    trait :iphone_128gb do
      sku { "IPHONE-15-PRO-128GB" }
      price_cents { 99900 }
      options { { "storage" => "128GB", "color" => "Natural Titanium" } }
      stock_quantity { 25 }
    end

    trait :iphone_256gb do
      sku { "IPHONE-15-PRO-256GB" }
      price_cents { 109900 }
      options { { "storage" => "256GB", "color" => "Natural Titanium" } }
      stock_quantity { 15 }
    end

    trait :macbook_16gb do
      sku { "MACBOOK-PRO-16-16GB" }
      price_cents { 249900 }
      options { { "memory" => "16GB", "storage" => "512GB" } }
      stock_quantity { 8 }
    end
  end

  # ⭐ Review Factory - User-generated content testing
  factory :review do
    association :user
    association :product
    rating { rand(1..5) }
    title { "Great product!" }
    content { "I really enjoyed using this product. Highly recommended!" }

    trait :five_star do
      rating { 5 }
      title { "Absolutely amazing!" }
      content { "This product exceeded all my expectations. Perfect!" }
    end

    trait :one_star do
      rating { 1 }
      title { "Very disappointed" }
      content { "This product did not meet my expectations at all." }
    end

    trait :detailed_review do
      title { "Comprehensive review after 3 months of use" }
      content {
        "After using this product for three months, I can confidently say it's " \
        "one of the best purchases I've made. The build quality is excellent, " \
        "the performance is outstanding, and the customer service has been " \
        "top-notch. I would definitely recommend this to anyone considering " \
        "a similar purchase."
      }
    end
  end

  # 🚚 ShippingMethod Factory - Logistics testing
  factory :shipping_method do
    name { "Standard Shipping" }
    description { "5-7 business days" }
    base_fee_cents { 699 }
    per_kg_fee_cents { 100 }
    distance_multiplier { 1.0 }

    trait :express do
      name { "Express Shipping" }
      description { "2-3 business days" }
      base_fee_cents { 1299 }
      per_kg_fee_cents { 200 }
      distance_multiplier { 1.5 }
    end

    trait :overnight do
      name { "Overnight Shipping" }
      description { "Next business day" }
      base_fee_cents { 2499 }
      per_kg_fee_cents { 300 }
      distance_multiplier { 2.0 }
    end

    trait :free_shipping do
      name { "Free Shipping" }
      description { "7-10 business days" }
      base_fee_cents { 0 }
      per_kg_fee_cents { 0 }
      distance_multiplier { 1.0 }
    end
  end

  # 🛒 Order Factory - Complex workflow testing
  factory :order do
    association :user
    association :shipping_method
    status { :cart }
    subtotal_cents { 0 }
    discount_cents { 0 }
    shipping_cents { 0 }
    tax_cents { 0 }
    total_cents { 0 }
    currency { "USD" }

    trait :with_items do
      after(:create) do |order|
        create_list(:order_item, 3, order: order)
        order.update!(
          subtotal_cents: order.order_items.sum { |item| item.quantity * item.unit_price_cents },
          total_cents: order.subtotal_cents + order.shipping_cents + order.tax_cents - order.discount_cents
        )
      end
    end

    trait :with_addresses do
      after(:create) do |order|
        create(:address, :shipping_address, addressable: order)
        create(:address, :billing_address, addressable: order)
      end
    end

    trait :pending_payment do
      status { :pending_payment }
      with_items
      with_addresses
    end

    trait :paid do
      status { :paid }
      with_items
      with_addresses
      after(:create) do |order|
        create(:payment, :successful, order: order, amount_cents: order.total_cents)
      end
    end

    trait :delivered do
      status { :delivered }
      with_items
      with_addresses
      after(:create) do |order|
        create(:payment, :successful, order: order, amount_cents: order.total_cents)
      end
    end
  end

  # 🛍️ OrderItem Factory - Line item testing
  factory :order_item do
    association :order
    association :product_variant
    quantity { rand(1..5) }
    unit_price_cents { product_variant&.price_cents || rand(1000..10000) }
  end

  # 💳 Payment Factory - Financial transaction testing
  factory :payment do
    association :order
    amount_cents { order&.total_cents || rand(1000..50000) }
    currency { "USD" }
    payment_method { "credit_card" }
    sequence(:transaction_id) { |n| "txn_#{n.to_s.rjust(10, '0')}" }
    status { :pending }

    trait :successful do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :refunded do
      status { :refunded }
    end

    trait :stripe_payment do
      payment_method { "stripe" }
      sequence(:transaction_id) { |n| "pi_#{SecureRandom.hex(12)}" }
    end
  end
end
