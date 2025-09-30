class Api::V1::CuponController < Api::V1::BaseController
  def show
		cupon_code = params[:cupon_code]

		# Validate required cupon information
		unless cupon_code.present?
			return render json: { error: "Cupon code required" }, status: :bad_request
		end

		cupon = Cupon.find_by(name: cupon_code, active: true)

		if cupon.nil?
			return render json: { error: "Cupon code not found" }, status: :not_found
		else
			render json: {
				name: cupon.name,
				amount: cupon.amount,
				value: cupon.value,
				percentage: cupon.percentage
			}
		end
	end
end