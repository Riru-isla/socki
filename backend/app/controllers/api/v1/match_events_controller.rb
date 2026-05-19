module Api
  module V1
    class MatchEventsController < ApplicationController
      # POST /api/v1/matches/:match_id/events
      def create
        match = Match.includes(:match_events, :red_competitor, :white_competitor).find(params[:match_id])
        verify_competitor_belongs_to_match!(match)
        return if performed?

        event = match.match_events.create!(
          competitor_id: match_event_params[:competitor_id].to_i,
          side: match_event_params[:side],
          event_type: match_event_params[:event_type],
          at_second: match_event_params[:at_second],
          point_index_for_side: next_point_index_for(match, match_event_params[:side], match_event_params[:event_type]),
          match_winning: false
        )

        Rails.logger.info "Broadcasting match update → match_#{match.id}"
        match.reload
        serialized = MatchSerializer.new(match).as_json
        ActionCable.server.broadcast("match_#{match.id}", serialized)

        render json: {
          ok: true,
          event_id: event.id,
          match: serialized
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { ok: false, error: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def match_event_params
        params.require(:event).permit(:competitor_id, :side, :event_type, :at_second)
      end

      def verify_competitor_belongs_to_match!(match)
        unless [ match.red_competitor_id, match.white_competitor_id ].include?(match_event_params[:competitor_id].to_i)
          render json: { ok: false, error: "Competitor does not belong to this match" }, status: :unprocessable_entity
        end
      end

      def next_point_index_for(match, side, event_type)
        return nil unless scoring_event?(event_type)

        existing = match.match_events
          .where(side: side, event_type: scoring_match_event_types)
          .count

        existing + 1
      end

      def scoring_event?(event_type)
        scoring_match_event_types.include?(event_type)
      end

      def scoring_match_event_types
        MatchEvent.scoring_types
      end
    end
  end
end
