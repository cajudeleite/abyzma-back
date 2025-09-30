class Api::V1::CheckoutController < Api::V1::BaseController
	def create
		phase = Phase.find_by(active: true)

		if phase.nil?
			return render json: { error: "No active phase found" }, status: :not_found
		end

		quantity = (params[:quantity] || 1).to_i
		customer_email = params[:email]
		customer_name = params[:name]
		cupon_code = params[:cuponCode]

		# Validate required customer information
		unless customer_email.present?
			return render json: { error: "Customer email is required" }, status: :bad_request
		end

		cupon = find_cupon(cupon_code) if cupon_code

		# If a coupon code was provided but no valid coupon was found, return error
		if cupon_code.present? && cupon.nil?
			return render json: { error: "There aren't enough available cupons for that quantity of tickets" }, status: :bad_request
		end

		if cupon && cupon.amount < quantity
			return render json: { error: "There aren't enough available cupons for that quantity of tickets" }, status: :bad_request
		end

		# Calculate unit amount (in cents), applying discount if a valid cupon is present
		unit_amount_cents = phase.price.to_i * 100
		if cupon
			if cupon.percentage
				discount_cents = (unit_amount_cents * (1 - (cupon.value.to_i / 100.0))).round
			else
				discount_cents = cupon.value.to_i * 100
			end
			unit_amount_cents = discount_cents
		end

		# Handle 0 euro checkouts - create tickets immediately
		if unit_amount_cents == 0
			begin
				# Create tickets directly for 0 euro checkouts
				tickets = []
				quantity.times do
					ticket = Ticket.create!(
						phase: phase,
						cupon: cupon,
						client_name: customer_name,
						client_email: customer_email,
						payment_id: "free_#{SecureRandom.hex(8)}", # Generate unique ID for free tickets
						price: 0
					)
					tickets << ticket
				end

				# Decrement coupon amount if coupon was used
				if cupon && tickets.any?
					new_amount = [cupon.amount - tickets.length, 0].max
					cupon.update!(amount: new_amount, active: new_amount != 0)
				end

				# Send confirmation email with tickets
				begin
					TicketMailer.ticket_confirmation(tickets).deliver_now
					Rails.logger.info "Free ticket confirmation email sent to #{customer_email} for #{tickets.length} tickets"
				rescue StandardError => e
					Rails.logger.error "Failed to send ticket confirmation email: #{e.message}"
				end

				render json: { 
					success: true,
					message: "Free tickets created successfully",
					tickets: tickets.map { |t| { id: t.id, price: t.price } }
				}
			rescue StandardError => e
				render json: { error: "Failed to create free tickets: #{e.message}" }, status: 500
			end
		else
			# Handle paid checkouts through Stripe
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
							unit_amount: unit_amount_cents, # Already in cents (discount applied if any)
						},
						quantity: quantity,
					}],
					mode: 'payment',
					payment_intent_data: {
						capture_method: 'automatic'
					},
					success_url: "#{ENV['HOST']}/success?session_id={CHECKOUT_SESSION_ID}",
					cancel_url: "#{ENV['HOST']}/checkout?canceled=true",
					metadata: {
						phase_id: phase.id,
						phase_name: phase.name,
						customer_name: customer_name,
						customer_email: customer_email,
						quantity: quantity,
						cupon_code: cupon_code
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

	private

	def find_cupon(name)
		Cupon.available.find_by(name: name)
	end
end