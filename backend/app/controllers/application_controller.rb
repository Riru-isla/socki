class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  before_action :configure_devise_parameters, if: :devise_controller?

  private

  def configure_devise_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password])
  end

  def authenticate_admin!
    unless user_signed_in? && current_user.is_admin?
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end
end
