# frozen_string_literal: true

class CartsController < ApplicationController
  before_action :set_cart
  before_action :set_cart_item, only: [:update_item, :remove_item]

  def show
    @cart_items = @cart.cart_items.includes(product_variant: :product)
  end

  def add_item
    @product_variant = ProductVariant.find(params[:product_variant_id])
    quantity = params[:quantity].to_i.positive? ? params[:quantity].to_i : 1

    if @product_variant.stock_quantity >= quantity
      @cart.add_item(@product_variant, quantity)
      flash[:notice] = "#{@product_variant.product.name} added to cart!"
    else
      flash[:alert] = "Sorry, only #{@product_variant.stock_quantity} items available."
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: cart_summary }
    end
  end

  def update_item
    quantity = params[:quantity].to_i

    if quantity > 0 && @cart_item.product_variant.stock_quantity >= quantity
      @cart_item.update(quantity: quantity)
      flash[:notice] = "Cart updated!"
    elsif quantity <= 0
      @cart_item.destroy
      flash[:notice] = "Item removed from cart!"
    else
      flash[:alert] = "Sorry, only #{@cart_item.product_variant.stock_quantity} items available."
    end

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.json { render json: cart_summary }
    end
  end

  def remove_item
    product_name = @cart_item.product_variant.product.name
    @cart_item.destroy
    flash[:notice] = "#{product_name} removed from cart!"

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.json { render json: cart_summary }
    end
  end

  def clear
    @cart.clear
    flash[:notice] = "Cart cleared!"
    redirect_to cart_path
  end

  private

  def set_cart
    @cart = current_cart
  end

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end

  def current_cart
    if user_signed_in?
      Cart.find_or_create_for_user(current_user)
    else
      Cart.find_or_create_for_session(session.id.to_s)
    end
  end

  def cart_summary
    {
      total_items: @cart.total_items,
      total_price: @cart.total_price,
      items: @cart.cart_items.includes(product_variant: :product).map do |item|
        {
          id: item.id,
          product_name: item.product_variant.product.name,
          variant_name: item.product_variant.name,
          quantity: item.quantity,
          unit_price: item.unit_price,
          total_price: item.total_price
        }
      end
    }
  end
end
