module Api
  module V1
    module Users
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          render json: {
            id: resource.id,
            email: resource.email,
            is_admin: resource.is_admin
          }, status: :ok
        end

        def respond_to_on_destroy(non_navigational_status: :no_content)
          head non_navigational_status
        end
      end
    end
  end
end
