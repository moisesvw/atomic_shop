namespace :db do
  desc "Seed the database with consistent data for models (layer 1)"
  task seed_models_layer1: :environment do
    puts "Seeding database with consistent data for models (layer 1)..."

    # Clear existing data
    puts "Clearing existing data..."
    Review.destroy_all
    Payment.destroy_all
    OrderItem.destroy_all
    Order.destroy_all
    ProductVariant.destroy_all
    Product.destroy_all
    Category.destroy_all
    Address.destroy_all
    User.destroy_all
    ShippingMethod.destroy_all

    # Create categories
    puts "Creating categories..."
    electronics = Category.create!(name: "Electronics", description: "Electronic devices and gadgets")
    clothing = Category.create!(name: "Clothing", description: "Apparel and fashion items")
    books = Category.create!(name: "Books", description: "Books and publications")
    home = Category.create!(name: "Home & Kitchen", description: "Home and kitchen products")

    # Create subcategories
    puts "Creating subcategories..."
    smartphones = Category.create!(name: "Smartphones", description: "Mobile phones and accessories", parent: electronics)
    laptops = Category.create!(name: "Laptops", description: "Notebook computers", parent: electronics)
    mens_clothing = Category.create!(name: "Men's Clothing", description: "Clothing for men", parent: clothing)
    womens_clothing = Category.create!(name: "Women's Clothing", description: "Clothing for women", parent: clothing)
    fiction = Category.create!(name: "Fiction", description: "Fiction books", parent: books)
    non_fiction = Category.create!(name: "Non-Fiction", description: "Non-fiction books", parent: books)
    kitchen = Category.create!(name: "Kitchen", description: "Kitchen appliances and utensils", parent: home)
    furniture = Category.create!(name: "Furniture", description: "Home furniture", parent: home)

    # Create products
    puts "Creating products..."
    # Smartphones
    iphone = Product.create!(
      name: "iPhone 14 Pro",
      description: "Apple's latest flagship smartphone with advanced features.",
      category: smartphones,
      featured: true
    )

    samsung = Product.create!(
      name: "Samsung Galaxy S23",
      description: "Samsung's premium smartphone with cutting-edge technology.",
      category: smartphones,
      featured: true
    )

    # Laptops
    macbook = Product.create!(
      name: "MacBook Pro 16",
      description: "Powerful laptop for professionals with stunning display.",
      category: laptops,
      featured: true
    )

    dell_xps = Product.create!(
      name: "Dell XPS 15",
      description: "Premium Windows laptop with excellent build quality.",
      category: laptops,
      featured: false
    )

    # Men's Clothing
    mens_tshirt = Product.create!(
      name: "Classic Cotton T-Shirt",
      description: "Comfortable cotton t-shirt for everyday wear.",
      category: mens_clothing,
      featured: false
    )

    mens_jeans = Product.create!(
      name: "Slim Fit Jeans",
      description: "Stylish slim fit jeans for a modern look.",
      category: mens_clothing,
      featured: true
    )

    # Women's Clothing
    womens_dress = Product.create!(
      name: "Summer Floral Dress",
      description: "Light and airy dress perfect for summer days.",
      category: womens_clothing,
      featured: true
    )

    womens_blouse = Product.create!(
      name: "Silk Blouse",
      description: "Elegant silk blouse for professional or casual settings.",
      category: womens_clothing,
      featured: false
    )

    # Fiction Books
    novel = Product.create!(
      name: "The Great Novel",
      description: "A captivating story of adventure and discovery.",
      category: fiction,
      featured: false
    )

    fantasy = Product.create!(
      name: "Epic Fantasy",
      description: "An epic tale of magic and heroism.",
      category: fiction,
      featured: true
    )

    # Non-Fiction Books
    biography = Product.create!(
      name: "Inspiring Biography",
      description: "The life story of an extraordinary individual.",
      category: non_fiction,
      featured: false
    )

    cookbook = Product.create!(
      name: "Gourmet Cooking",
      description: "Recipes and techniques from world-renowned chefs.",
      category: non_fiction,
      featured: false
    )

    # Kitchen Products
    blender = Product.create!(
      name: "High-Performance Blender",
      description: "Powerful blender for smoothies, soups, and more.",
      category: kitchen,
      featured: true
    )

    knife_set = Product.create!(
      name: "Professional Knife Set",
      description: "High-quality knives for precision cutting.",
      category: kitchen,
      featured: false
    )

    # Furniture
    sofa = Product.create!(
      name: "Modern Sectional Sofa",
      description: "Comfortable and stylish sofa for your living room.",
      category: furniture,
      featured: true
    )

    coffee_table = Product.create!(
      name: "Wooden Coffee Table",
      description: "Elegant coffee table made from sustainable wood.",
      category: furniture,
      featured: false
    )

    # Create product variants
    puts "Creating product variants..."
    # iPhone variants
    ProductVariant.create!(
      product: iphone,
      sku: "IP14P-128-BLK",
      price_cents: 99900,
      currency: "USD",
      stock_quantity: 50,
      weight: 0.2,
      options: "{\"color\": \"Black\", \"storage\": \"128GB\"}"
    )

    ProductVariant.create!(
      product: iphone,
      sku: "IP14P-256-BLK",
      price_cents: 109900,
      currency: "USD",
      stock_quantity: 30,
      weight: 0.2,
      options: "{\"color\": \"Black\", \"storage\": \"256GB\"}"
    )

    ProductVariant.create!(
      product: iphone,
      sku: "IP14P-128-SLV",
      price_cents: 99900,
      currency: "USD",
      stock_quantity: 45,
      weight: 0.2,
      options: "{\"color\": \"Silver\", \"storage\": \"128GB\"}"
    )

    # Samsung variants
    ProductVariant.create!(
      product: samsung,
      sku: "SGS23-128-BLK",
      price_cents: 89900,
      currency: "USD",
      stock_quantity: 60,
      weight: 0.19,
      options: "{\"color\": \"Black\", \"storage\": \"128GB\"}"
    )

    ProductVariant.create!(
      product: samsung,
      sku: "SGS23-256-BLK",
      price_cents: 99900,
      currency: "USD",
      stock_quantity: 40,
      weight: 0.19,
      options: "{\"color\": \"Black\", \"storage\": \"256GB\"}"
    )

    # MacBook variants
    ProductVariant.create!(
      product: macbook,
      sku: "MBP16-512-SLV",
      price_cents: 249900,
      currency: "USD",
      stock_quantity: 25,
      weight: 2.1,
      options: "{\"color\": \"Silver\", \"storage\": \"512GB\", \"ram\": \"16GB\"}"
    )

    ProductVariant.create!(
      product: macbook,
      sku: "MBP16-1TB-SLV",
      price_cents: 279900,
      currency: "USD",
      stock_quantity: 15,
      weight: 2.1,
      options: "{\"color\": \"Silver\", \"storage\": \"1TB\", \"ram\": \"16GB\"}"
    )

    # Dell XPS variants
    ProductVariant.create!(
      product: dell_xps,
      sku: "DXPS15-512-SLV",
      price_cents: 199900,
      currency: "USD",
      stock_quantity: 20,
      weight: 1.9,
      options: "{\"color\": \"Silver\", \"storage\": \"512GB\", \"ram\": \"16GB\"}"
    )

    ProductVariant.create!(
      product: dell_xps,
      sku: "DXPS15-1TB-SLV",
      price_cents: 229900,
      currency: "USD",
      stock_quantity: 10,
      weight: 1.9,
      options: "{\"color\": \"Silver\", \"storage\": \"1TB\", \"ram\": \"32GB\"}"
    )

    # Men's T-shirt variants
    ProductVariant.create!(
      product: mens_tshirt,
      sku: "MT-S-BLK",
      price_cents: 1999,
      currency: "USD",
      stock_quantity: 100,
      weight: 0.2,
      options: "{\"color\": \"Black\", \"size\": \"S\"}"
    )

    ProductVariant.create!(
      product: mens_tshirt,
      sku: "MT-M-BLK",
      price_cents: 1999,
      currency: "USD",
      stock_quantity: 150,
      weight: 0.22,
      options: "{\"color\": \"Black\", \"size\": \"M\"}"
    )

    ProductVariant.create!(
      product: mens_tshirt,
      sku: "MT-L-BLK",
      price_cents: 1999,
      currency: "USD",
      stock_quantity: 120,
      weight: 0.24,
      options: "{\"color\": \"Black\", \"size\": \"L\"}"
    )

    # Add more variants for other products...

    # Create users
    puts "Creating users..."
    admin_user = User.create!(
      email: "admin@example.com",
      password: "password",
      first_name: "Admin",
      last_name: "User"
    )

    customer1 = User.create!(
      email: "john@example.com",
      password: "password",
      first_name: "John",
      last_name: "Doe"
    )

    customer2 = User.create!(
      email: "jane@example.com",
      password: "password",
      first_name: "Jane",
      last_name: "Smith"
    )

    # Create addresses
    puts "Creating addresses..."
    Address.create!(
      addressable: customer1,
      street: "123 Main St",
      city: "Anytown",
      state: "CA",
      zip: "12345",
      country: "USA"
    )

    Address.create!(
      addressable: customer2,
      street: "456 Oak Ave",
      city: "Somewhere",
      state: "NY",
      zip: "67890",
      country: "USA"
    )

    # Create shipping methods
    puts "Creating shipping methods..."
    standard_shipping = ShippingMethod.create!(
      name: "Standard Shipping",
      description: "Delivery within 5-7 business days",
      base_fee_cents: 499,
      per_kg_fee_cents: 100,
      distance_multiplier: 1.0
    )

    express_shipping = ShippingMethod.create!(
      name: "Express Shipping",
      description: "Delivery within 2-3 business days",
      base_fee_cents: 999,
      per_kg_fee_cents: 200,
      distance_multiplier: 1.5
    )

    overnight_shipping = ShippingMethod.create!(
      name: "Overnight Shipping",
      description: "Next day delivery",
      base_fee_cents: 1999,
      per_kg_fee_cents: 300,
      distance_multiplier: 2.0
    )

    # Create orders
    puts "Creating orders..."
    # Completed order for customer1
    order1 = Order.create!(
      user: customer1,
      shipping_method: standard_shipping,
      status: :delivered,
      subtotal_cents: 101900,
      discount_cents: 0,
      shipping_cents: 699,
      tax_cents: 8152,
      total_cents: 110751,
      currency: "USD"
    )

    # Add shipping address to order1
    Address.create!(
      addressable: order1,
      street: "123 Main St",
      city: "Anytown",
      state: "CA",
      zip: "12345",
      country: "USA"
    )

    # Add billing address to order1
    Address.create!(
      addressable: order1,
      street: "123 Main St",
      city: "Anytown",
      state: "CA",
      zip: "12345",
      country: "USA"
    )

    # Add order items to order1
    OrderItem.create!(
      order: order1,
      product_variant: ProductVariant.find_by(sku: "IP14P-128-BLK"),
      quantity: 1,
      unit_price_cents: 99900
    )

    OrderItem.create!(
      order: order1,
      product_variant: ProductVariant.find_by(sku: "MT-L-BLK"),
      quantity: 1,
      unit_price_cents: 1999
    )

    # Add payment to order1
    Payment.create!(
      order: order1,
      amount_cents: 110751,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_" + SecureRandom.hex(10),
      status: :completed
    )

    # Cart order for customer2
    order2 = Order.create!(
      user: customer2,
      shipping_method: express_shipping,
      status: :cart,
      subtotal_cents: 199900,
      discount_cents: 0,
      shipping_cents: 1399,
      tax_cents: 16104,
      total_cents: 217403,
      currency: "USD"
    )

    # Add order items to order2
    OrderItem.create!(
      order: order2,
      product_variant: ProductVariant.find_by(sku: "DXPS15-512-SLV"),
      quantity: 1,
      unit_price_cents: 199900
    )

    # Create reviews
    puts "Creating reviews..."
    Review.create!(
      user: customer1,
      product: iphone,
      rating: 5,
      title: "Amazing phone!",
      content: "This is the best phone I've ever owned. The camera is incredible and the battery life is excellent."
    )

    Review.create!(
      user: customer2,
      product: iphone,
      rating: 4,
      title: "Great but expensive",
      content: "The phone is fantastic but it's quite expensive. Still, the quality is worth it."
    )

    Review.create!(
      user: customer1,
      product: macbook,
      rating: 5,
      title: "Perfect for work",
      content: "This laptop is perfect for my work. Fast, reliable, and the screen is beautiful."
    )

    Review.create!(
      user: customer2,
      product: mens_tshirt,
      rating: 3,
      title: "Decent quality",
      content: "The t-shirt is comfortable but the sizing runs a bit small."
    )

    puts "Seeding completed successfully!"
  end
end
