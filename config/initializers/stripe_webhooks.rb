# Stripe Webhook Configuration
# 
# To set up webhooks in your Stripe dashboard:
# 1. Go to Developers > Webhooks
# 2. Add endpoint: https://yourdomain.com/api/v1/webhooks/stripe
# 3. Select events: payment_intent.succeeded (primary), checkout.session.completed (logging)
# 4. Copy the webhook signing secret to your credentials
#
# Note: Tickets are created on payment_intent.succeeded to handle async payment methods
#
# Add to your credentials:
# rails credentials:edit
# 
# stripe:
#   secret_key: your_secret_key
#   webhook_secret: your_webhook_signing_secret

Rails.application.configure do
  # Ensure webhook secret is configured
  if Rails.env.production?
    webhook_secret = Rails.application.credentials.stripe&.dig(:webhook_secret) || ENV['STRIPE_WEBHOOK_SECRET']
    unless webhook_secret.present?
      Rails.logger.warn "Stripe webhook secret not configured. Webhooks will not be verified."
    end
  end
end
