# frozen_string_literal: true

# ⚛️ Atom: FormFieldComponent
# 
# A reusable form field component that provides consistent styling and behavior
# across all forms in the application. This atom can be composed into molecules
# like login forms, registration forms, etc.
#
# Features:
# - Consistent styling and validation states
# - Accessibility support with proper labels and ARIA attributes
# - Error message display
# - Multiple input types (text, email, password, etc.)
# - Responsive design
#
# Usage:
#   <%= render(Atoms::FormFieldComponent.new(
#     name: "email",
#     label: "Email Address",
#     type: :email,
#     value: @user.email,
#     error: @user.errors[:email].first,
#     required: true
#   )) %>

class Atoms::FormFieldComponent < ViewComponent::Base
  attr_reader :name, :label, :type, :value, :placeholder, :error, :required, 
              :disabled, :autocomplete, :classes, :help_text

  def initialize(
    name:,
    label:,
    type: :text,
    value: nil,
    placeholder: nil,
    error: nil,
    required: false,
    disabled: false,
    autocomplete: nil,
    classes: "",
    help_text: nil
  )
    @name = name
    @label = label
    @type = type
    @value = value
    @placeholder = placeholder || label
    @error = error
    @required = required
    @disabled = disabled
    @autocomplete = autocomplete
    @classes = classes
    @help_text = help_text
  end

  private

  def field_id
    "field_#{name}"
  end

  def field_classes
    base_classes = %w[
      block w-full px-3 py-2 border rounded-md shadow-sm
      focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
      disabled:bg-gray-50 disabled:text-gray-500 disabled:cursor-not-allowed
      transition-colors duration-200
    ]

    state_classes = if has_error?
      %w[border-red-300 text-red-900 placeholder-red-300 focus:ring-red-500 focus:border-red-500]
    else
      %w[border-gray-300 text-gray-900 placeholder-gray-400]
    end

    (base_classes + state_classes + classes.split).join(" ")
  end

  def label_classes
    base_classes = %w[block text-sm font-medium mb-1]
    
    color_classes = if has_error?
      %w[text-red-700]
    else
      %w[text-gray-700]
    end

    (base_classes + color_classes).join(" ")
  end

  def error_classes
    %w[mt-1 text-sm text-red-600].join(" ")
  end

  def help_text_classes
    %w[mt-1 text-sm text-gray-500].join(" ")
  end

  def has_error?
    error.present?
  end

  def input_attributes
    attributes = {
      id: field_id,
      name: name,
      type: input_type,
      value: value,
      placeholder: placeholder,
      class: field_classes,
      required: required,
      disabled: disabled
    }

    attributes[:autocomplete] = autocomplete if autocomplete.present?
    attributes[:"aria-invalid"] = "true" if has_error?
    attributes[:"aria-describedby"] = error_id if has_error?

    attributes
  end

  def input_type
    case type
    when :email
      "email"
    when :password
      "password"
    when :tel
      "tel"
    when :url
      "url"
    when :number
      "number"
    when :search
      "search"
    else
      "text"
    end
  end

  def error_id
    "#{field_id}_error"
  end
end
