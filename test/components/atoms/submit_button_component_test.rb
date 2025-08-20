# frozen_string_literal: true

require "test_helper"

class Atoms::SubmitButtonComponentTest < ViewComponent::TestCase
  # 🧪 TDD Excellence: Submit Button Component Testing
  #
  # This test suite validates the submit button component with loading states,
  # accessibility features, and consistent styling across different variants.

  test "renders basic submit button" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit"
    )

    render_inline(component)

    assert_selector "button[type='submit']", text: "Submit"
    assert_selector "button[data-submit-button='true']"
    assert_selector "span[data-button-text]", text: "Submit"
  end

  test "renders with custom loading text" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Sign In",
      loading_text: "Signing in..."
    )

    render_inline(component)

    assert_selector "button[data-loading-text='Signing in...']"
  end

  test "generates default loading text" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Register"
    )

    render_inline(component)

    assert_selector "button[data-loading-text='Register...']"
  end

  test "renders primary variant by default" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit"
    )

    render_inline(component)

    assert_selector "button.bg-blue-600.text-white"
    assert_selector "button.hover\\:bg-blue-700"
    assert_selector "button.focus\\:ring-blue-500"
  end

  test "renders secondary variant" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Cancel",
      variant: :secondary
    )

    render_inline(component)

    assert_selector "button.bg-white.text-gray-700"
    assert_selector "button.border-gray-300"
    assert_selector "button.hover\\:bg-gray-50"
  end

  test "renders danger variant" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Delete",
      variant: :danger
    )

    render_inline(component)

    assert_selector "button.bg-red-600.text-white"
    assert_selector "button.hover\\:bg-red-700"
    assert_selector "button.focus\\:ring-red-500"
  end

  test "renders success variant" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Save",
      variant: :success
    )

    render_inline(component)

    assert_selector "button.bg-green-600.text-white"
    assert_selector "button.hover\\:bg-green-700"
    assert_selector "button.focus\\:ring-green-500"
  end

  test "renders medium size by default" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit"
    )

    render_inline(component)

    assert_selector "button.px-4.py-2.text-base"
  end

  test "renders small size" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit",
      size: :small
    )

    render_inline(component)

    assert_selector "button.px-3.py-2.text-sm"
    assert_selector "svg.w-4.h-4" # Small spinner
  end

  test "renders large size" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit",
      size: :large
    )

    render_inline(component)

    assert_selector "button.px-6.py-3.text-lg"
    assert_selector "svg.w-6.h-6" # Large spinner
  end

  test "renders disabled state" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit",
      disabled: true
    )

    render_inline(component)

    assert_selector "button[disabled]"
    assert_selector "button.disabled\\:opacity-50"
    assert_selector "button.disabled\\:cursor-not-allowed"
  end

  test "applies custom CSS classes" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit",
      classes: "w-full custom-class"
    )

    render_inline(component)

    assert_selector "button.w-full.custom-class"
  end

  test "renders with form association" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit",
      form_id: "my-form"
    )

    render_inline(component)

    assert_selector "button[form='my-form']"
  end

  test "renders loading spinner" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit"
    )

    render_inline(component)

    assert_selector "svg[data-loading-spinner].hidden" # Hidden by default
    assert_selector "svg.animate-spin"
    assert_selector "circle.opacity-25"
    assert_selector "path.opacity-75"
  end

  test "renders JavaScript for form handling" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Submit"
    )

    render_inline(component)

    # Check that JavaScript is included in the rendered output
    content = rendered_content
    assert_includes content, "setButtonLoading"
    assert_includes content, "form.addEventListener('submit'"
    assert_includes content, "data-original-text"
  end

  test "generates unique button ID" do
    component1 = Atoms::SubmitButtonComponent.new(text: "Submit 1")
    component2 = Atoms::SubmitButtonComponent.new(text: "Submit 2")

    # Test that each component generates a unique ID
    id1 = component1.send(:button_id)
    id2 = component2.send(:button_id)

    assert_not_equal id1, id2
    assert_match /submit_button_[a-f0-9]{8}/, id1
    assert_match /submit_button_[a-f0-9]{8}/, id2
  end

  test "maintains accessibility standards" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Create Account",
      variant: :primary,
      size: :large
    )

    render_inline(component)

    # Proper button semantics
    assert_selector "button[type='submit']"

    # Focus management
    assert_selector "button.focus\\:outline-none"
    assert_selector "button.focus\\:ring-2"
    assert_selector "button.focus\\:ring-offset-2"

    # Disabled state accessibility
    assert_selector "button.disabled\\:opacity-50"
    assert_selector "button.disabled\\:cursor-not-allowed"

    # Loading state preparation
    assert_selector "button[data-loading-text]"
    assert_selector "span[data-button-text]"
  end

  test "handles all variant and size combinations" do
    variants = [ :primary, :secondary, :danger, :success ]
    sizes = [ :small, :medium, :large ]

    # Test that all combinations can be instantiated without errors
    variants.each do |variant|
      sizes.each do |size|
        component = Atoms::SubmitButtonComponent.new(
          text: "Test",
          variant: variant,
          size: size
        )

        # Should instantiate without errors
        assert_not_nil component
        assert_equal variant, component.variant
        assert_equal size, component.size
      end
    end
  end

  test "renders with all features enabled" do
    component = Atoms::SubmitButtonComponent.new(
      text: "Complete Registration",
      loading_text: "Creating your account...",
      variant: :success,
      size: :large,
      disabled: false,
      classes: "w-full mt-4",
      form_id: "registration-form"
    )

    render_inline(component)

    # All attributes present
    assert_selector "button[type='submit']"
    assert_selector "button[form='registration-form']"
    assert_selector "button[data-loading-text='Creating your account...']"
    assert_selector "button.bg-green-600.text-white"
    assert_selector "button.px-6.py-3.text-lg"
    assert_selector "button.w-full.mt-4"
    assert_selector "span[data-button-text]", text: "Complete Registration"
    assert_selector "svg[data-loading-spinner].hidden"
  end
end
