module Api
  module V1
    class ShiajosController < ApplicationController

      def projector
        shiajo = Shiajo.find(params[:id])
        result = Shiajos::ProjectorPayload.new(shiajo).call # no hint on GET
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

      private

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
          score: m.score, # you already return {red:, white:}
          rule_set: { id: m.rule_set.id, max_time: m.rule_set.max_time }
        }
      end
    end
  end
end
