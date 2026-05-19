module Api
  module V1
    class RuleSetsController < ApplicationController
      def index
        rule_sets = RuleSet.order(:name)
        render json: rule_sets.map { |rs| rule_set_json(rs) }
      end

      private

      def rule_set_json(rs)
        {
          id: rs.id,
          name: rs.name,
          max_time: rs.max_time,
          best_of_points: rs.best_of_points,
          draw_system: rs.draw_system
        }
      end
    end
  end
end
