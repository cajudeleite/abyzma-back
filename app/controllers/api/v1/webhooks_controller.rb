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
    
    # Convert session object to hash format expected by service
    session_data = {
      'id' => session.id,
      'customer_details' => {
        'email' => session.customer_details&.email,
        'name' => session.customer_details&.name
      },
      'payment_intent' => session.payment_intent,
      'metadata' => session.metadata.to_h || {}
    }
    
    # Use the service to create tickets
    service = TicketCreationService.new(session_data)
    result = service.create_tickets
    
    if result[:success]
      Rails.logger.info "Successfully created #{result[:count]} tickets for session #{session.id}"
    else
      Rails.logger.error "Failed to create tickets for session #{session.id}: #{result[:error]}"
    end
  end

  def handle_payment_intent_succeeded(payment_intent)
    Rails.logger.info "Payment intent succeeded: #{payment_intent.id}"
    # Additional logic if needed for payment intent events
  end
end
