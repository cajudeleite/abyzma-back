class TicketCreationService
  def initialize(session_data)
    @session_data = session_data
  end

  def create_tickets
    return { success: false, error: 'Invalid session data' } unless valid_session_data?

    begin
      tickets = []
      
      # Get phase and coupon from metadata first (more reliable)
      phase = find_phase_from_metadata
      cupon = find_cupon_from_metadata
      
      if phase
        # Create tickets based on quantity from metadata
        quantity = @session_data.dig('metadata', :quantity)&.to_i || 1
        quantity.times do
          ticket = create_single_ticket(phase, nil, cupon)
          tickets << ticket if ticket
        end
      else
        # Fallback to line items method
        line_items = fetch_line_items
        line_items.each do |line_item|
          phase = find_phase_for_line_item(line_item)
          next unless phase

          quantity = line_item.quantity
          quantity.times do
            ticket = create_single_ticket(phase, line_item, cupon)
            tickets << ticket if ticket
          end
        end
      end

      # Decrement coupon amount if coupon was used
      decrement_cupon_amount(cupon, tickets.length) if cupon && tickets.any?

      # Send confirmation email with tickets
      send_ticket_confirmation_email(tickets) if tickets.any?

      { success: true, tickets: tickets, count: tickets.length }
    rescue StandardError => e
      Rails.logger.error "Error creating tickets: #{e.message}"
      { success: false, error: e.message }
    end
  end

  private

  def valid_session_data?
    @session_data&.dig('id') && @session_data&.dig('customer_details')
  end

  def find_phase_from_metadata
    phase_id = @session_data.dig('metadata', :phase_id)
    return nil unless phase_id.present?
    
    Phase.find_by(id: phase_id, active: true)
  end

  def find_cupon_from_metadata
    cupon_code = @session_data.dig('metadata', :cupon_code)
    return nil unless cupon_code.present?
    
    Cupon.find_by(name: cupon_code, active: true)
  end

  def fetch_line_items
    session_id = @session_data['id']
    Stripe::Checkout::Session.list_line_items(session_id).data
  end

  def find_phase_for_line_item(line_item)
    # First try to get phase from product metadata
    phase_id = line_item.price&.product&.metadata&.dig(:phase_id)
    if phase_id.present?
      phase = Phase.find_by(id: phase_id, active: true)
      return phase if phase
    end

    # Fallback to extracting phase name from product description
    phase_name = extract_phase_name(line_item)
    Phase.find_by(name: phase_name, active: true)
  end

  def extract_phase_name(line_item)
    # Extract phase name from product description
    # Format: "Abyzma Ticket PhaseName"
    description = line_item.description || ''
    description.gsub('Abyzma Ticket ', '')
  end

  def create_single_ticket(phase, line_item = nil, cupon = nil)
    # Calculate final price (discounted if coupon is present)
    final_price = calculate_final_price(phase.price, cupon)
    
    Ticket.create!(
      phase: phase,
      cupon: cupon,
      client_name: customer_name,
      client_email: customer_email,
      payment_id: payment_intent_id,
      price: final_price
    )
  end

  def customer_name
    @session_data.dig('customer_details', 'name')
  end

  def customer_email
    @session_data.dig('customer_details', 'email')
  end

  def payment_intent_id
    @session_data['payment_intent']
  end

  def calculate_final_price(original_price, cupon)
    return original_price unless cupon
    
    if cupon.percentage
      # Apply percentage discount
      discount_amount = (original_price * (1 - (cupon.value.to_i / 100.0))).round
    else
      # Apply fixed amount discount
      cupon.value
    end
  end

  def decrement_cupon_amount(cupon, ticket_count)
    return unless cupon && ticket_count > 0
    
    # Decrement the coupon amount by the number of tickets created
    new_amount = [cupon.amount - ticket_count, 0].max
    cupon.update!(amount: new_amount, active: new_amount != 0)
    
    Rails.logger.info "Decremented coupon '#{cupon.name}' amount by #{ticket_count}. New amount: #{new_amount}"
  end

  def send_ticket_confirmation_email(tickets)
    begin
      TicketMailer.ticket_confirmation(tickets).deliver_now
      Rails.logger.info "Ticket confirmation email sent to #{tickets.first.client_email} for #{tickets.length} tickets"
    rescue StandardError => e
      Rails.logger.error "Failed to send ticket confirmation email: #{e.message}"
      # Don't fail the entire ticket creation process if email fails
    end
  end
end
