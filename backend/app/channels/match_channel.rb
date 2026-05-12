class MatchChannel < ApplicationCable::Channel
  def subscribed
    match_id = params[:match_id]
    stream_from "match_#{match_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
