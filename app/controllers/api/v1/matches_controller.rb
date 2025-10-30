module Api
  module V1
    class MatchesController < ApplicationController
      # later we may want API-only behavior (no CSRF, etc.)
      # for now, keep it simple

      def show
        match = Match.find(params[:id])
        render json: MatchSerializer.new(match).as_json
      end
    end
  end
end
