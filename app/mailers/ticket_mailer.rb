require 'base64'
require 'chunky_png'

class TicketMailer < ApplicationMailer
  def ticket_confirmation(tickets)
    @tickets = tickets
    @client_name = tickets.first.client_name
    @client_email = tickets.first.client_email
    
    # Generate QR codes and attach them as inline images
    @tickets.each_with_index do |ticket, index|
      qr_png = generate_qr_code_png(ticket.uuid)
      attachments["qr_code_#{index + 1}.png"] = qr_png
    end
    
    mail(
      to: @client_email,
      subject: "Your Abyzma Tickets - Confirmation #{@tickets.first.created_at.strftime('%Y%m%d')}"
    )
  end

  private

  def generate_qr_code_png(uuid)
    require 'rqrcode'
    require 'chunky_png'
    
    qr = RQRCode::QRCode.new(uuid)
    
    # Generate QR code as PNG
    qr_png = qr.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 200
    )
    
    qr_png.to_s
  end

  def qr_code_cid(ticket_index)
    "qr_code_#{ticket_index + 1}.png"
  end

  helper_method :qr_code_cid
end
