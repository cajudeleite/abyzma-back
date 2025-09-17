class Api::V1::CheckoutController < Api::V1::BaseController
	def create
		phase = Phase.find_by(active: true)

		if phase.nil?
			return render json: { error: "No active phase found" }, status: :not_found
		end

		quantity = params[:quantity] || 1

		begin
			# Set Stripe API key
			Stripe.api_key = Rails.application.credentials.stripe[:secret_key]

			session = Stripe::Checkout::Session.create({
				payment_method_types: ['card'],
				line_items: [{
					price_data: {
						currency: 'eur',
						product_data: {
							name: "Abyzma Ticket #{phase.name}",
							description: 'Ticket for the event',
						},
						unit_amount: phase.price * 100, # 20.00 in cents
					},
					quantity: quantity,
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