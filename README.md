# Abyzma Back - Event Ticketing System

A Rails API backend for an event ticketing system with admin panel, Stripe payment integration, and UUID-based records.

## 🚀 Features

- **UUID Primary Keys**: All records use UUIDs instead of sequential integers
- **Admin Panel**: Password-protected admin interface built with Administrate gem
- **Stripe Integration**: Secure payment processing for ticket purchases
- **CORS Support**: Configured for frontend communication
- **RESTful API**: Clean API endpoints for frontend integration
- **Auto-generated Admin**: Administrate gem provides zero-configuration admin interface

## 📊 Database Schema

### Models Overview

The system consists of three main models:

#### 1. **Phase** (Event Phases)
Represents different phases of ticket sales for an event.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `name` | String | Phase name (e.g., "Early Bird", "Regular") |
| `price` | Integer | Price in cents (e.g., 2000 = €20.00) |
| `ticket_amount` | Integer | Total number of tickets available |
| `start_date` | Date | Phase start date |
| `end_date` | Date | Phase end date |
| `active` | Boolean | Whether this phase is currently active |
| `created_at` | DateTime | Record creation timestamp |
| `updated_at` | DateTime | Record update timestamp |

#### 2. **Cupon** (Discount Coupons)
Represents discount coupons that can be applied to tickets.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `name` | String | Coupon name |
| `type` | String | Coupon type (e.g., "percentage", "fixed") |
| `active` | Boolean | Whether the coupon is active |
| `value` | String | Discount value |
| `amount` | String | Discount amount |
| `end_date` | Date | Coupon expiration date |
| `created_at` | DateTime | Record creation timestamp |
| `updated_at` | DateTime | Record update timestamp |

#### 3. **Ticket** (Purchased Tickets)
Represents individual ticket purchases.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `phase_id` | UUID | Foreign key to Phase |
| `cupon_id` | UUID | Foreign key to Cupon (optional) |
| `client_name` | String | Customer name |
| `client_email` | String | Customer email |
| `payment_id` | String | Stripe payment ID |
| `price` | Integer | Final price paid in cents |
| `created_at` | DateTime | Record creation timestamp |
| `updated_at` | DateTime | Record update timestamp |

### Relationships

- **Phase** `has_many` **Tickets**
- **Cupon** `has_many` **Tickets** (optional)
- **Ticket** `belongs_to` **Phase** (required)
- **Ticket** `belongs_to` **Cupon** (optional)

## 🔐 Admin Panel

The admin panel is built using the **Administrate gem**, which provides a clean, Rails-generated admin interface with minimal configuration.

### Access
- **URL**: `http://localhost:3000/admin`
- **Username**: `admin`
- **Password**: `abyzma123`

### Features
- **Auto-generated Interface**: Administrate automatically creates admin pages based on your models
- **Dashboard**: Overview of all data with search and pagination
- **CRUD Operations**: Full Create, Read, Update, Delete functionality for all models
- **Phases Management**: Create, edit, delete event phases
- **Coupons Management**: Create, edit, delete discount coupons
- **Tickets Management**: View all ticket purchases
- **UUID Support**: All records display with UUID primary keys
- **Customizable**: Easy to customize views and add custom fields

### Navigation
- **Cupons**: Manage discount coupons
- **Phases**: Manage event phases
- **Tickets**: View ticket purchases

### Administrate Gem Benefits
- **Zero Configuration**: Works out of the box with your existing models
- **Rails Integration**: Seamlessly integrates with Rails conventions
- **Responsive Design**: Mobile-friendly admin interface
- **Search & Filtering**: Built-in search and filtering capabilities
- **Pagination**: Automatic pagination for large datasets
- **Customizable**: Easy to override views and add custom functionality

## 💳 Stripe Integration

### Configuration
Stripe is configured using Rails credentials:

```ruby
# config/credentials.yml.enc
stripe:
  secret_key: sk_test_your_secret_key_here
  publishable_key: pk_test_your_publishable_key_here
```

### Checkout Process
1. Frontend calls `/api/v1/create-checkout-session`
2. Backend creates Stripe checkout session
3. Returns checkout URL for redirection
4. User completes payment on Stripe hosted page
5. Stripe redirects back to success/cancel URLs

## 🌐 API Endpoints

### Base URL
```
http://localhost:3000/api/v1
```

### Endpoints

#### 1. Get Current Phase
**GET** `/phases/current`

Returns information about the currently active phase.

**Response:**
```json
{
  "tickets_left": 99,
  "ticket_amount": 100,
  "name": "Phase 1"
}
```

**Error Response:**
```json
{
  "error": "No active phase found"
}
```

#### 2. Create Checkout Session
**POST** `/create-checkout-session`

Creates a Stripe checkout session for ticket purchase.

**Response:**
```json
{
  "checkoutUrl": "https://checkout.stripe.com/c/pay/cs_test_...",
  "sessionId": "cs_test_a1Nd0beGWb4oTSsmqsN30mZBdfprC1DQ7MlWDENgJNZkfEq5cYGEptTAsN"
}
```

**Error Response:**
```json
{
  "error": "Stripe error message"
}
```

## 🛠️ Setup Instructions

### Prerequisites
- Ruby 3.3.0
- Rails 7.2.2
- PostgreSQL
- Stripe account (for payment processing)
- Administrate gem (included in Gemfile)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd abyzma-back
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Generate Administrate admin controllers** (if not already done)
   ```bash
   rails generate administrate:install
   rails generate administrate:resource Cupon
   rails generate administrate:resource Phase
   rails generate administrate:resource Ticket
   ```

5. **Configure Stripe credentials**
   ```bash
   EDITOR="nano" rails credentials:edit
   ```
   Add your Stripe keys:
   ```yaml
   stripe:
     secret_key: sk_test_your_secret_key_here
     publishable_key: pk_test_your_publishable_key_here
   ```

6. **Start the server**
   ```bash
   rails server
   ```

### Environment Variables
- `STRIPE_SECRET_KEY`: Your Stripe secret key
- `STRIPE_PUBLISHABLE_KEY`: Your Stripe publishable key

## 🔧 Configuration

### CORS
Configured to allow requests from `http://localhost:5173` (frontend URL).

### UUID Support
- All models use UUID primary keys
- Foreign keys are also UUIDs
- PostgreSQL `uuid-ossp` extension enabled

### Security
- CSRF protection disabled for API controllers
- HTTP Basic Authentication for admin panel
- CORS properly configured for frontend communication

## 📝 Usage Examples

### Frontend Integration

#### Get Current Phase
```javascript
const response = await fetch('http://localhost:3000/api/v1/phases/current');
const phase = await response.json();
console.log(`${phase.tickets_left} tickets left out of ${phase.ticket_amount}`);
```

#### Create Checkout Session
```javascript
const response = await fetch('http://localhost:3000/api/v1/create-checkout-session', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  }
});

const data = await response.json();
if (data.checkoutUrl) {
  window.location.href = data.checkoutUrl;
}
```

## 🚀 Deployment

### Production Considerations
1. Set up proper Stripe production keys
2. Configure CORS for production domain
3. Set up proper database credentials
4. Configure admin panel credentials
5. Set up SSL/HTTPS

### Environment Variables
```bash
export STRIPE_SECRET_KEY="sk_live_your_production_key"
export STRIPE_PUBLISHABLE_KEY="pk_live_your_production_key"
```

## 📚 API Documentation

### Error Handling
All API endpoints return appropriate HTTP status codes:
- `200`: Success
- `400`: Bad Request (Stripe errors)
- `404`: Not Found (no active phase)
- `422`: Unprocessable Entity (validation errors)

### Response Format
All API responses are in JSON format with consistent structure.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support or questions, please contact the development team or create an issue in the repository.