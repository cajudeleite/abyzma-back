class Api::V1::CheckoutController < Api::V1::BaseController
	def create
		phase = Phase.find_by(active: true)

		if phase.nil?
			return render json: { error: "No active phase found" }, status: :not_found
		end

		quantity = params[:quantity] || 1
		customer_email = params[:email]
		customer_name = params[:name]

		# Validate required customer information
		unless customer_email.present?
			return render json: { error: "Customer email is required" }, status: :bad_request
		end

		begin
			# Set Stripe API key
			Stripe.api_key = Rails.application.credentials.stripe&.dig(:secret_key) || ENV['STRIPE_SECRET_KEY']

			session = Stripe::Checkout::Session.create({
				payment_method_types: ['card'],
				customer_email: customer_email,
				line_items: [{
					price_data: {
						currency: 'eur',
						product_data: {
							name: "Abyzma Ticket #{phase.name}",
							description: "Ticket for #{phase.name} phase",
							metadata: {
								phase_id: phase.id,
								phase_name: phase.name
							}
						},
						unit_amount: phase.price * 100, # Convert to cents
					},
					quantity: quantity,
				}],
				mode: 'payment',
				payment_intent_data: {
					capture_method: 'automatic'
				},
				success_url: "http://localhost:5173/success?session_id={CHECKOUT_SESSION_ID}",
				cancel_url: "http://localhost:5173/checkout?canceled=true",
				metadata: {
					phase_id: phase.id,
					phase_name: phase.name,
					customer_name: customer_name,
					customer_email: customer_email,
					quantity: quantity
				}
			})
				
			render json: { 
				checkoutUrl: session.url,
				sessionId: session.id
			}
		rescue Stripe::StripeError => e
			render json: { error: e.message }, status: 400
		end
	end
end