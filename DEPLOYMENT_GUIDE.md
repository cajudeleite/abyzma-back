# Deployment Guide

## Fixed Issues

The deployment was failing due to missing Stripe credentials in production. I've fixed this by:

1. **Made credentials optional** - The app now falls back to environment variables
2. **Added proper nil checking** - Using `&.dig()` to safely access credentials
3. **Environment variable fallbacks** - All Stripe configs now use ENV vars as backup

## Required Environment Variables

Set these environment variables in your production environment (Heroku):

```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Email Configuration (optional)
EMAIL_FROM=noreply@yourdomain.com

# Host Configuration
HOST=yourdomain.com
```

## How to Set Environment Variables in Heroku

```bash
# Set Stripe keys
heroku config:set STRIPE_SECRET_KEY=sk_live_your_key
heroku config:set STRIPE_PUBLISHABLE_KEY=pk_live_your_key
heroku config:set STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Set email configuration
heroku config:set EMAIL_FROM=noreply@yourdomain.com
heroku config:set HOST=yourdomain.com
```

## Deployment Steps

1. **Commit the fixes:**
   ```bash
   git add .
   git commit -m "Fix production deployment - add environment variable fallbacks"
   ```

2. **Deploy to Heroku:**
   ```bash
   git push heroku master
   ```

3. **Set up email delivery (optional):**
   - Configure SMTP settings in production
   - Or use a service like SendGrid, Mailgun, etc.

## What Was Fixed

- ✅ `config/application.rb` - Added safe credential access
- ✅ `checkout_controller.rb` - Added ENV fallback for Stripe key
- ✅ `webhooks_controller.rb` - Added ENV fallback for webhook secret
- ✅ `payment_success_controller.rb` - Added ENV fallback for Stripe key
- ✅ `production.rb` - Added ActionMailer configuration

## Testing

After deployment, test:
1. **Stripe checkout** - Create a test payment
2. **Webhook handling** - Verify tickets are created
3. **Email delivery** - Check if emails are sent (if SMTP configured)

The application should now deploy successfully! 🚀
