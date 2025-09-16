class Api::V1::PhasesController < ApplicationController
  def current_phase
    # Find the current active phase
    phase = Phase.find_by(active: true)

    if phase.nil?
      return render json: { error: "No active phase found" }, status: :not_found
    end

    tickets_left = phase.ticket_amount - phase.tickets.count

    render json: { 
      tickets_left:, 
      phase_ticket_amount: phase.ticket_amount,
      phase_name: phase.name
    }, status: :ok
  end
end
