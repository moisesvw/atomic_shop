# frozen_string_literal: true

class Molecules::VariantSelectorComponent < ViewComponent::Base
  attr_reader :product, :available_options, :selected_options, :classes

  def initialize(product:, available_options:, selected_options: {}, classes: "")
    @product = product
    @available_options = available_options
    @selected_options = selected_options
    @classes = classes
  end

  def selector_classes
    base_classes = [ "variant-selector" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def option_selected?(option_name, option_value)
    selected_options[option_name.to_s] == option_value.to_s
  end

  def option_url(option_name, option_value)
    new_options = selected_options.dup
    new_options[option_name.to_s] = option_value.to_s

    product_path(product, options: new_options)
  end
end
