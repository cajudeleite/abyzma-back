require 'base64'

class TicketMailer < ApplicationMailer
  def ticket_confirmation(tickets)
    @tickets = tickets
    @client_name = tickets.first.client_name
    @client_email = tickets.first.client_email
    
    mail(
      to: @client_email,
      subject: "Your Abyzma Tickets - Confirmation #{@tickets.first.created_at.strftime('%Y%m%d')}"
    )
  end

  private

  def generate_qr_code(uuid)
    require 'rqrcode'
    
    qr = RQRCode::QRCode.new(uuid)
    qr.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 4,
      standalone: true
    )
  end

  def qr_code_data_uri(uuid)
    svg_content = generate_qr_code(uuid)
    "data:image/svg+xml;base64,#{Base64.encode64(svg_content).strip}"
  end

  helper_method :qr_code_data_uri
end
