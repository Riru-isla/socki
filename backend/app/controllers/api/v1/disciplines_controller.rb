module Api
  module V1
    class DisciplinesController < ApplicationController
      def index
        disciplines = Discipline.order(:name)
        render json: disciplines.map { |d| { id: d.id, name: d.name } }
      end
    end
  end
end
