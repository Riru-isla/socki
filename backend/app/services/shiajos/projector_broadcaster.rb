# app/services/shiajos/projector_broadcaster.rb
module Shiajos
  class ProjectorBroadcaster
    CHANNEL_PREFIX = "projector_shiajo_"

    def self.broadcast!(shiajo, mode_hint: nil)
      result = Shiajos::ProjectorPayload.new(shiajo).call(mode_hint: mode_hint)
      payload = ProjectorSerializer.new(result).as_json
      ActionCable.server.broadcast(stream_name(shiajo.id), payload)
      payload
    end

    def self.stream_name(shiajo_id)
      "#{CHANNEL_PREFIX}#{shiajo_id}"
    end
  end
end
