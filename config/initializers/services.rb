# Ensure the Services module is properly loaded
module Services
  module Atoms
  end

  module Molecules
  end

  module Organisms
  end
end

# Explicitly require all service classes
Dir[Rails.root.join("app", "services", "**", "*.rb")].each { |file| require file }
