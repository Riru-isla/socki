module Api
  module V1
    class TournamentsController < ApplicationController
      before_action :authenticate_admin!, only: [ :create ]

      def index
        tournaments = Tournament.includes(:season).order(created_at: :desc)
        render json: tournaments.map { |t| tournament_payload(t) }
      end

      def show
        tournament = Tournament.includes(
          categories: [
            :shiajos,
            { enrolments: :competitor },
            { matches: [ :shiajo, :red_competitor, :white_competitor ] }
          ]
        ).find(params[:id])
        render json: tournament_detail_payload(tournament)
      end

      def create
        tournament = Tournament.new(tournament_params)
        if tournament.save
          render json: tournament_payload(tournament), status: :created
        else
          render json: { errors: tournament.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def tournament_params
        params.require(:tournament).permit(:title, :region, :tournament_type, :official, :starts_on, :ends_on, :season_id)
      end

      def tournament_payload(t)
        {
          id: t.id,
          title: t.title,
          region: t.region,
          official: t.official,
          tournament_type: t.tournament_type,
          starts_on: t.starts_on,
          ends_on: t.ends_on,
          season: { id: t.season.id, name: t.season.name },
          category_count: t.categories.count
        }
      end

      def tournament_detail_payload(t)
        {
          id: t.id,
          title: t.title,
          region: t.region,
          official: t.official,
          tournament_type: t.tournament_type,
          starts_on: t.starts_on,
          ends_on: t.ends_on,
          season: { id: t.season.id, name: t.season.name },
          categories: t.categories.map { |c| category_payload(c) }
        }
      end

      def category_payload(c)
        {
          id: c.id,
          name: c.name,
          category_type: { id: c.category_type.id, name: c.category_type.name, gender: c.category_type.gender },
          shiajo_count: c.shiajos.count,
          shiajos: c.shiajos.map { |s| { id: s.id, name: s.name, active: s.active } },
          enrolments: c.enrolments.map { |e| enrolment_payload(e) },
          matches: c.matches.sort_by { |m| [ m.position || 0, m.id ] }.map { |m| match_summary(m) }
        }
      end

      def match_summary(m)
        {
          id: m.id,
          position: m.position,
          status: m.status,
          shiajo: { id: m.shiajo.id, name: m.shiajo.name },
          red_competitor: m.red_competitor && { id: m.red_competitor.id, name: m.red_competitor.name },
          white_competitor: m.white_competitor && { id: m.white_competitor.id, name: m.white_competitor.name }
        }
      end

      def enrolment_payload(e)
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
