# app/services/shiajos/projector_payload.rb
module Shiajos
  class ProjectorPayload
    Result = Struct.new(:mode, :current_match, :next_two, :just_finished, :banner_until, keyword_init: true)

    DEFAULT_NEXT_LIMIT = 2

    def initialize(shiajo, limit_next: DEFAULT_NEXT_LIMIT)
      @shiajo = shiajo
      @limit_next = limit_next
    end

    # mode_hint: :in_progress | :match_finished | :standby | nil
    # (We’ll usually pass a hint from controller on start/finish;
    # if nil, we derive mode from DB state.)
    def call(mode_hint: nil)
      current = current_match
      upcoming = next_two_matches(current)
      last_fin = latest_finished

      derived_mode =
        if mode_hint
          mode_hint
        elsif current.present?
          :in_progress
        elsif last_fin.present?
          # We *always* include last finished; client decides banner timing (10s)
          :match_finished
        else
          :standby
        end

      Result.new(
        mode: derived_mode,
        current_match: current,
        next_two: upcoming,
        just_finished: last_fin,
        banner_until: nil # client owns the 10s timer; we keep this nil
      )
    end

    private

    attr_reader :shiajo, :limit_next

    def current_match
      shiajo.matches.in_progress_only.order(:started_at, :position, :id)
            .includes(:red_side, :blue_side) # <-- change to your assoc names
            .first
    end

    def next_two_matches(current)
      scope = shiajo.matches.scheduled_only.ordered
      scope = scope.where("position > ?", current.position) if current.present?
      scope.limit(limit_next)
           .includes(:red_side, :blue_side) # <-- change to your assoc names
           .to_a
    end

    def latest_finished
      shiajo.matches.finished_only
            .order(Arel.sql("COALESCE(ended_at, updated_at) DESC"), position: :desc, id: :desc)
            .includes(:red_side, :blue_side) # <-- change to your assoc names
            .first
    end
  end
end
