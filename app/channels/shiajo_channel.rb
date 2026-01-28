class ShiajoChannel < ApplicationCable::Channel
  def subscribed
    stream_from "shiajo_#{params[:shiajo_id]}"
    stream_from Shiajos::ProjectorBroadcaster.stream_name(shiajo_id)
  end
end
