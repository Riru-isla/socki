module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :authenticate_admin!

      def create
        tournament = Tournament.find(params[:tournament_id])
        category = tournament.categories.new(category_params)
        if category.save
          render json: category_payload(category), status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def category_params
        params.require(:category).permit(:name, :category_type_id)
      end

      def category_payload(c)
        {
          id: c.id,
          name: c.name,
          category_type: { id: c.category_type.id, name: c.category_type.name, gender: c.category_type.gender },
          shiajo_count: c.shiajos.count,
          shiajos: c.shiajos.map { |s| { id: s.id, name: s.name, active: s.active } }
        }
      end
    end
  end
end
