# frozen_string_literal: true

# ⚛️ Atom: SubmitButtonComponent
#
# A specialized button component for form submissions with loading states,
# accessibility features, and consistent styling.
#
# Features:
# - Loading state with spinner
# - Disabled state handling
# - Accessibility support
# - Consistent styling
# - Form submission handling
# - Multiple variants and sizes
#
# Usage:
#   <%= render(Atoms::SubmitButtonComponent.new(
#     text: "Sign In",
#     loading_text: "Signing in...",
#     variant: :primary,
#     size: :large,
#     disabled: false
#   )) %>

class Atoms::SubmitButtonComponent < ViewComponent::Base
  attr_reader :text, :loading_text, :variant, :size, :disabled, :classes, :form_id

  def initialize(
    text:,
    loading_text: nil,
    variant: :primary,
    size: :medium,
    disabled: false,
    classes: "",
    form_id: nil
  )
    @text = text
    @loading_text = loading_text || "#{text}..."
    @variant = variant
    @size = size
    @disabled = disabled
    @classes = classes
    @form_id = form_id
  end

  private

  def button_classes
    base_classes = %w[
      inline-flex items-center justify-center
      font-medium rounded-md transition-all duration-200
      focus:outline-none focus:ring-2 focus:ring-offset-2
      disabled:opacity-50 disabled:cursor-not-allowed
      relative overflow-hidden
    ]

    variant_classes = case variant
    when :primary
      %w[
        bg-blue-600 text-white border border-transparent
        hover:bg-blue-700 focus:ring-blue-500
        disabled:bg-blue-400
      ]
    when :secondary
      %w[
        bg-white text-gray-700 border border-gray-300
        hover:bg-gray-50 focus:ring-blue-500
        disabled:bg-gray-100
      ]
    when :danger
      %w[
        bg-red-600 text-white border border-transparent
        hover:bg-red-700 focus:ring-red-500
        disabled:bg-red-400
      ]
    when :success
      %w[
        bg-green-600 text-white border border-transparent
        hover:bg-green-700 focus:ring-green-500
        disabled:bg-green-400
      ]
    else
      %w[
        bg-gray-600 text-white border border-transparent
        hover:bg-gray-700 focus:ring-gray-500
        disabled:bg-gray-400
      ]
    end

    size_classes = case size
    when :small
      %w[px-3 py-2 text-sm]
    when :large
      %w[px-6 py-3 text-lg]
    else
      %w[px-4 py-2 text-base]
    end

    (base_classes + variant_classes + size_classes + classes.split).join(" ")
  end

  def button_attributes
    attributes = {
      type: "submit",
      class: button_classes,
      disabled: disabled,
      "data-loading-text": loading_text,
      "data-submit-button": true
    }

    attributes[:form] = form_id if form_id.present?

    attributes
  end

  def spinner_classes
    base_size = case size
    when :small
      "w-4 h-4"
    when :large
      "w-6 h-6"
    else
      "w-5 h-5"
    end

    "#{base_size} animate-spin mr-2 hidden"
  end

  def button_id
    @button_id ||= "submit_button_#{SecureRandom.hex(4)}"
  end
end
