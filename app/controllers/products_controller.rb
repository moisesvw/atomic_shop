class ProductsController < ApplicationController
  def index
    @category = params[:category_id] ? Category.find_by(id: params[:category_id]) : nil

    @products = if @category
      Product.where(category_id: @category.id)
    else
      Product.all
    end

    @products = @products.page(params[:page]).per(12)
  end

  def show
    @product_id = params[:id]
    @selected_options = params.fetch(:options, {}).permit(:color, :size, :storage).to_h

    service = Services::Organisms::ProductDetailPageService.new(@product_id, @selected_options)
    @result = service.execute

    if @result[:success]
      @product = @result[:product]
      @variants = @result[:variants]
      @available_options = @result[:available_options]
      @selected_variant = @result[:selected_variant]
      @reviews = @result[:reviews]
      @related_products = @result[:related_products]

      # Create an instance of the product detail page component
      @product_page = Pages::ProductDetailPageComponent.new(
        product: @product,
        selected_variant_id: @selected_variant&.id,
        selected_options: @selected_options
      )
    else
      flash[:alert] = @result[:error]
      redirect_to root_path
    end
  end

  def select_variant
    @product_id = params[:id]
    @selected_options = params.fetch(:options, {}).permit(:color, :size, :storage).to_h

    service = Services::Molecules::VariantSelectionService.new(@product_id, @selected_options)
    @result = service.execute

    respond_to do |format|
      format.json { render json: @result }
      format.html { redirect_to product_path(@product_id, options: @selected_options) }
      format.js { render json: @result } # For XHR requests
    end
  end
end
