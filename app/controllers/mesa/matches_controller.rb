module Mesa
  class MatchesController < ApplicationController
    layout "application"

    def show
       Rails.logger.info "View path: #{lookup_context.find_all('mesa/matches/show').inspect}"
      @match_id = params[:id]
      render :show
    end
  end
end
