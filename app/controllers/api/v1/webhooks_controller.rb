class Api::V1::WebhooksController < Api::V1::BaseController
  # CSRF protection is already disabled in BaseController
  
  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.stripe[:webhook_secret]
    
    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: 400
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: 400
      return
    end

    case event.type
    when 'checkout.session.completed'
      handle_checkout_session_completed(event.data.object)
    when 'payment_intent.succeeded'
      handle_payment_intent_succeeded(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    render json: { status: 'success' }
  end

  private

  def handle_checkout_session_completed(session)
    Rails.logger.info "Processing checkout session completed: #{session.id}"
    # Tickets will be created when payment_intent.succeeded fires (after capture)
    # This handles async payment methods where capture happens after session completion
  end

  def handle_payment_intent_succeeded(payment_intent)
    Rails.logger.info "Payment intent succeeded: #{payment_intent.id}"
    
    # Check if tickets already exist for this payment intent to prevent duplicates
    existing_tickets = Ticket.where(payment_id: payment_intent.id)
    if existing_tickets.exists?
      Rails.logger.info "Tickets already exist for payment intent #{payment_intent.id}, skipping creation"
      return
    end
    
    # Get the checkout session associated with this payment intent
    checkout_session = find_checkout_session_by_payment_intent(payment_intent.id)
    
    if checkout_session
      # Convert session object to hash format expected by service
      session_data = {
        'id' => checkout_session.id,
        'customer_details' => {
          'email' => checkout_session.customer_details&.email,
          'name' => checkout_session.customer_details&.name
        },
        'payment_intent' => payment_intent.id,
        'metadata' => checkout_session.metadata.to_h || {}
      }
      
      # Use the service to create tickets
      service = TicketCreationService.new(session_data)
      result = service.create_tickets
      
      if result[:success]
        Rails.logger.info "Successfully created #{result[:count]} tickets for payment intent #{payment_intent.id}"
      else
        Rails.logger.error "Failed to create tickets for payment intent #{payment_intent.id}: #{result[:error]}"
      end
    else
      Rails.logger.error "No checkout session found for payment intent #{payment_intent.id}"
    end
  end

  def find_checkout_session_by_payment_intent(payment_intent_id)
    # Search for checkout sessions with this payment intent
    sessions = Stripe::Checkout::Session.list(limit: 100)
    
    sessions.data.find do |session|
      session.payment_intent == payment_intent_id
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Error finding checkout session for payment intent #{payment_intent_id}: #{e.message}"
    nil
  end
end
