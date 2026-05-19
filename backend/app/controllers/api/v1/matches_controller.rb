module Api
  module V1
    class MatchesController < ApplicationController
      before_action :authenticate_admin!, only: [ :create ]

      def show
        match = Match.find(params[:id])
        render json: MatchSerializer.new(match).as_json
      end

      def create
        category = Category.find(params[:category_id])
        match = category.matches.new(match_params)
        match.position ||= next_position_for(match.shiajo_id)

        if match.save
          render json: match_create_payload(match), status: :created
        else
          render json: { errors: match.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def match_params
        params.require(:match).permit(:shiajo_id, :red_competitor_id, :white_competitor_id, :rule_set_id, :position)
      end

      def next_position_for(shiajo_id)
        return 1 unless shiajo_id
        Match.where(shiajo_id: shiajo_id).maximum(:position).to_i + 1
      end

      def match_create_payload(m)
        {
          id: m.id,
          position: m.position,
          status: m.status,
          shiajo: { id: m.shiajo.id, name: m.shiajo.name },
          red_competitor: m.red_competitor && { id: m.red_competitor.id, name: m.red_competitor.name },
          white_competitor: m.white_competitor && { id: m.white_competitor.id, name: m.white_competitor.name }
        }
      end
    end
  end
end
