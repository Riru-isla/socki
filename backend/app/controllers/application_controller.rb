class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  before_action :configure_devise_parameters, if: :devise_controller?

  private

  def configure_devise_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password])
  end

  # TODO(auth-restore): admin enforcement is temporarily disabled while the
  # frontend has no login UI. The `before_action :authenticate_admin!` calls
  # across the Api::V1::* controllers stay in place so that re-enabling is a
  # one-line change here — uncomment the body below and drop this todo.
  #
  #   unless user_signed_in? && current_user.is_admin?
  #     render json: { error: "Forbidden" }, status: :forbidden
  #   end
  def authenticate_admin!
  end
end
