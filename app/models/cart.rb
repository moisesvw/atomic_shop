# frozen_string_literal: true

class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items

  validates :session_id, presence: true, unless: :user_id?

  scope :active, -> { where(status: 'active') }
  scope :abandoned, -> { where(status: 'abandoned') }

  enum status: { active: 0, completed: 1, abandoned: 2 }

  def total_items
    cart_items.sum(:quantity)
  end

  def total_price_cents
    cart_items.sum { |item| item.quantity * item.product_variant.price_cents }
  end

  def total_price
    total_price_cents / 100.0
  end

  def add_item(product_variant, quantity = 1)
    existing_item = cart_items.find_by(product_variant: product_variant)
    
    if existing_item
      existing_item.update(quantity: existing_item.quantity + quantity)
      existing_item
    else
      cart_items.create(product_variant: product_variant, quantity: quantity)
    end
  end

  def remove_item(product_variant)
    cart_items.find_by(product_variant: product_variant)&.destroy
  end

  def update_item_quantity(product_variant, quantity)
    item = cart_items.find_by(product_variant: product_variant)
    return unless item

    if quantity <= 0
      item.destroy
    else
      item.update(quantity: quantity)
    end
  end

  def empty?
    cart_items.empty?
  end

  def clear
    cart_items.destroy_all
  end

  def self.find_or_create_for_user(user)
    find_or_create_by(user: user, status: 'active')
  end

  def self.find_or_create_for_session(session_id)
    find_or_create_by(session_id: session_id, status: 'active')
  end
end
