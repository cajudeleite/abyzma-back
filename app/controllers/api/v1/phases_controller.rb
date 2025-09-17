class Api::V1::PhasesController < Api::V1::BaseController
  def current_phase
    # Find the current active phase
    phase = Phase.find_by(active: true)

    if phase.nil?
      return render json: { error: "No active phase found" }, status: :not_found
    end

    tickets_left = phase.ticket_amount - phase.tickets.count

    render json: { 
      tickets_left:, 
      ticket_amount: phase.ticket_amount,
      name: phase.name
    }, status: :ok
  end

  def index
    phases = Phase.all.order(created_at: :asc)

    render json: { 
      phases: phases.map { |phase| 
        { 
          name: phase.name, 
          price: phase.price, 
          active: phase.active 
        } 
      } 
    }, status: :ok
  end
end
