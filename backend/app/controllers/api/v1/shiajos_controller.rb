module Api
  module V1
    class ShiajosController < ApplicationController
      before_action :authenticate_admin!, only: [ :create ]

      def projector
        shiajo = Shiajo.find(params[:id])
        result = Shiajos::ProjectorPayload.new(shiajo).call
        render json: ProjectorSerializer.new(result).as_json
      end

      def summary
        shiajo = Shiajo.find(params[:id])
        matches = shiajo.matches.order(:position, :id)

        current   = matches.find_by(status: "in_progress")
        finished  = matches.where(status: "finished").order(updated_at: :desc).first
        upcoming  = matches.where(status: "upcoming").limit(3)

        render json: {
          shiajo: { id: shiajo.id, name: shiajo.name },
          current_match: current && match_payload(current),
          just_finished: (finished && recent?(finished)) ? match_payload(finished) : nil,
          next_matches: upcoming.map { |m| match_payload(m) }
        }
      end

      def create
        category = Category.find(params[:category_id])
        shiajo = category.shiajos.new(shiajo_params)
        if shiajo.save
          render json: { id: shiajo.id, name: shiajo.name, active: shiajo.active }, status: :created
        else
          render json: { errors: shiajo.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def shiajo_params
        params.require(:shiajo).permit(:name, :position)
      end

      def recent?(match)
        match.updated_at >= 10.minutes.ago
      end

      def match_payload(m)
        {
          id: m.id,
          status: m.status,
          category: { id: m.category.id, name: m.category.name },
          competitors: {
            red:   m.red_competitor && { id: m.red_competitor.id, name: m.red_competitor.name },
            white: m.white_competitor && { id: m.white_competitor.id, name: m.white_competitor.name }
          },
          score: { red: m.score_for("red"), white: m.score_for("white") },
          rule_set: { id: m.rule_set.id, max_time: m.rule_set.max_time }
        }
      end
    end
  end
end
