class Api::V1::PaymentSuccessController < Api::V1::BaseController
  def show
    session_id = params[:session_id]
    
    if session_id.present?
      begin
        # Retrieve the session from Stripe to get payment details
        Stripe.api_key = Rails.application.credentials.stripe&.dig(:secret_key) || ENV['STRIPE_SECRET_KEY']
        session = Stripe::Checkout::Session.retrieve(session_id)
        
        # Get the tickets created for this session
        tickets = Ticket.where(payment_id: session.payment_intent)
        
        render json: {
          success: true,
          message: "Payment successful!",
          session_id: session_id,
          tickets_created: tickets.count,
          tickets: tickets.map do |ticket|
            {
              id: ticket.id,
              phase_name: ticket.phase.name,
              client_name: ticket.client_name,
              client_email: ticket.client_email,
              price: ticket.price,
              created_at: ticket.created_at
            }
          end
        }
      rescue Stripe::StripeError => e
        render json: { 
          success: false, 
          error: "Unable to verify payment: #{e.message}" 
        }, status: 400
      end
    else
      render json: { 
        success: false, 
        error: "No session ID provided" 
      }, status: 400
    end
  end
end
