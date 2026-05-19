module Api
  module V1
    class SeasonsController < ApplicationController
      before_action :authenticate_admin!, only: [ :create ]

      def index
        seasons = Season.includes(:discipline).order(created_at: :desc)
        render json: seasons.map { |s| { id: s.id, name: s.name, discipline: s.discipline.name } }
      end

      def create
        season = Season.new(season_params)
        if season.save
          render json: { id: season.id, name: season.name, discipline: season.discipline.name }, status: :created
        else
          render json: { errors: season.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def season_params
        params.require(:season).permit(:name, :discipline_id)
      end
    end
  end
end
