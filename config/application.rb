require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AbyzmaBack
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    
    # Configure UUID as primary key
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
    
    # Configure CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://localhost:5173', ENV['HOST'] # Your frontend URL
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true
      end
    end
    
    # Configure Stripe
    config.stripe = {
      secret_key: Rails.application.credentials.stripe&.dig(:secret_key) || ENV['STRIPE_SECRET_KEY'],
      publishable_key: Rails.application.credentials.stripe&.dig(:publishable_key) || ENV['STRIPE_PUBLISHABLE_KEY']
    }
  end
end
