module Api
  module V1
    class CompetitorsController < ApplicationController
      before_action :authenticate_admin!, only: [ :create, :destroy ]

      def index
        competitors = Competitor.order(:name)
        render json: competitors.map { |c| competitor_json(c) }
      end

      def create
        competitor = Competitor.new(competitor_params)
        if competitor.save
          render json: competitor_json(competitor), status: :created
        else
          render json: { errors: competitor.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        competitor = Competitor.find(params[:id])
        competitor.destroy
        head :no_content
      end

      private

      def competitor_params
        params.require(:competitor).permit(:name, :age, :province)
      end

      def competitor_json(c)
        { id: c.id, name: c.name, age: c.age, province: c.province }
      end
    end
  end
end
