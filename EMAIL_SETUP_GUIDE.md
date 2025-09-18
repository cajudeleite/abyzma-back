# Email Setup Guide for Production

## Current Status
✅ Email system is implemented and working  
✅ QR codes are generated correctly  
❌ **Email delivery not configured for production**

## Quick Setup Options

### Option 1: SendGrid (Recommended - Free 100 emails/day)

1. **Sign up for SendGrid:**
   - Go to [sendgrid.com](https://sendgrid.com)
   - Create a free account (100 emails/day free)

2. **Get API Key:**
   - Go to Settings > API Keys
   - Create API Key with "Mail Send" permissions
   - Copy the API key

3. **Set Environment Variables:**
   ```bash
   heroku config:set SMTP_PASSWORD=your_sendgrid_api_key --app abyzma
   heroku config:set SMTP_DOMAIN=abyzma.com --app abyzma
   ```

4. **Deploy:**
   ```bash
   git add . && git commit -m "Add email configuration" && git push heroku master
   ```

### Option 2: Gmail SMTP (Free but limited)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password:**
   - Go to Google Account settings
   - Security > 2-Step Verification > App passwords
   - Generate password for "Mail"

3. **Set Environment Variables:**
   ```bash
   heroku config:set SMTP_ADDRESS=smtp.gmail.com --app abyzma
   heroku config:set SMTP_PORT=587 --app abyzma
   heroku config:set SMTP_USERNAME=your_email@gmail.com --app abyzma
   heroku config:set SMTP_PASSWORD=your_app_password --app abyzma
   heroku config:set SMTP_DOMAIN=gmail.com --app abyzma
   ```

### Option 3: Mailgun (Free 5,000 emails/month)

1. **Sign up for Mailgun:**
   - Go to [mailgun.com](https://mailgun.com)
   - Create free account

2. **Get SMTP Credentials:**
   - Go to Sending > Domains
   - Copy SMTP credentials

3. **Set Environment Variables:**
   ```bash
   heroku config:set SMTP_ADDRESS=smtp.mailgun.org --app abyzma
   heroku config:set SMTP_PORT=587 --app abyzma
   heroku config:set SMTP_USERNAME=your_mailgun_username --app abyzma
   heroku config:set SMTP_PASSWORD=your_mailgun_password --app abyzma
   heroku config:set SMTP_DOMAIN=your_domain.mailgun.org --app abyzma
   ```

## Testing Email Delivery

After setting up email service:

1. **Test with a real payment** - Complete a test purchase
2. **Check email delivery** - Look for the ticket email
3. **Check logs** - Verify no email errors in Heroku logs

## Current Email Features

- ✅ **Beautiful HTML emails** with professional design
- ✅ **QR codes** for each ticket (containing ticket UUID)
- ✅ **Responsive design** that works on all devices
- ✅ **Plain text fallback** for email clients that don't support HTML
- ✅ **Automatic sending** after successful payment
- ✅ **Error handling** - won't break ticket creation if email fails

## Troubleshooting

If emails still don't arrive:

1. **Check spam folder**
2. **Verify environment variables:**
   ```bash
   heroku config --app abyzma
   ```
3. **Check Heroku logs:**
   ```bash
   heroku logs --tail --app abyzma
   ```
4. **Test email service** with a simple test

## Next Steps

1. Choose an email service (SendGrid recommended)
2. Set up the environment variables
3. Deploy the changes
4. Test with a real payment
5. Verify email delivery

Your ticket system is ready - just needs email delivery configured! 🎫📧
