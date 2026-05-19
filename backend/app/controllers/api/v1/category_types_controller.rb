module Api
  module V1
    class CategoryTypesController < ApplicationController
      before_action :authenticate_admin!, only: [ :create ]

      def index
        types = CategoryType.order(:name)
        render json: types.map { |t| { id: t.id, name: t.name, gender: t.gender, team: t.team, rank: t.rank } }
      end

      def create
        type = CategoryType.new(category_type_params)
        if type.save
          render json: { id: type.id, name: type.name, gender: type.gender, team: type.team, rank: type.rank }, status: :created
        else
          render json: { errors: type.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def category_type_params
        params.require(:category_type).permit(:name, :gender, :team, :rank)
      end
    end
  end
end
