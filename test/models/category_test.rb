require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "should not save category without name" do
    category = Category.new
    assert_not category.save, "Saved the category without a name"
  end

  test "should not save category without slug" do
    category = Category.new(name: "Test Category")
    # The before_validation callback should generate a slug
    assert category.save, "Could not save the category with a name but without a slug"
    assert_equal "test-category", category.slug, "Slug was not generated correctly"
  end

  test "should not save category with duplicate slug" do
    Category.create(name: "Test Category", slug: "test-category")
    category = Category.new(name: "Another Test", slug: "test-category")
    assert_not category.save, "Saved the category with a duplicate slug"
  end

  test "should have many products" do
    association = Category.reflect_on_association(:products)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "should belong to parent category" do
    association = Category.reflect_on_association(:parent)
    assert_equal :belongs_to, association.macro
    assert_equal "Category", association.options[:class_name]
    assert association.options[:optional]
  end

  test "should have many subcategories" do
    association = Category.reflect_on_association(:subcategories)
    assert_equal :has_many, association.macro
    assert_equal "Category", association.options[:class_name]
    assert_equal "parent_id", association.options[:foreign_key]
    assert_equal :nullify, association.options[:dependent]
  end

  test "should generate slug from name" do
    category = Category.new(name: "Test Category")
    category.valid?
    assert_equal "test-category", category.slug
  end

  test "should not generate slug if already present" do
    category = Category.new(name: "Test Category", slug: "custom-slug")
    category.valid?
    assert_equal "custom-slug", category.slug
  end
end
