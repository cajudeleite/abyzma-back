class Api::V1::CheckoutController < Api::V1::BaseController
	def create
		begin
			# Set Stripe API key
			Stripe.api_key = Rails.application.credentials.stripe[:secret_key]

			session = Stripe::Checkout::Session.create({
				payment_method_types: ['card'],
				line_items: [{
					price_data: {
						currency: 'eur',
						product_data: {
							name: 'Abyzma Ticket',
							description: 'Ticket for the event',
						},
						unit_amount: 2000, # 20.00 in cents
					},
					quantity: 1,
					}],
					mode: 'payment',
					success_url: "#{request.base_url}/checkout?success=true",
					cancel_url: "#{request.base_url}/checkout?canceled=true",
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