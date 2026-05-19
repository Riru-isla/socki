module Api
  module V1
    class EnrolmentsController < ApplicationController
      before_action :authenticate_admin!, only: [ :create, :destroy ]

      def index
        category = Category.find(params[:category_id])
        enrolments = category.enrolments.includes(:competitor).order("competitors.name")
        render json: enrolments.map { |e| enrolment_json(e) }
      end

      def create
        category = Category.find(params[:category_id])
        enrolment = category.enrolments.new(enrolment_params)
        if enrolment.save
          render json: enrolment_json(enrolment), status: :created
        else
          render json: { errors: enrolment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        enrolment = Enrolment.find(params[:id])
        enrolment.destroy
        head :no_content
      end

      private

      def enrolment_params
        params.require(:enrolment).permit(:competitor_id, :seed)
      end

      def enrolment_json(e)
        {
          id: e.id,
          seed: e.seed,
          competitor: {
            id: e.competitor.id,
            name: e.competitor.name,
            age: e.competitor.age,
            province: e.competitor.province
          }
        }
      end
    end
  end
end
