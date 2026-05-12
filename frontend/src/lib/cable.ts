// src/lib/cable.ts
import { createConsumer } from "@rails/actioncable";

let consumer: ReturnType<typeof createConsumer> | null = null;

export function getConsumer() {
  if (!consumer) consumer = createConsumer("/cable"); // Vite proxies to Rails
  return consumer;
}

export function subscribeMatch(
  matchId: string | number,
  handlers: {
    received?: (data: any) => void;
    connected?: () => void;
    disconnected?: () => void;
  } = {},
) {
  const sub = getConsumer().subscriptions.create(
    { channel: "MatchChannel", match_id: matchId },
    {
      received: handlers.received ?? (() => {}),
      connected: handlers.connected ?? (() => {}),
      disconnected: handlers.disconnected ?? (() => {}),
    },
  );
  return () => sub.unsubscribe();
}

export function subscribeShiajo(
  shiajoId: string | number,
  handlers: { received?: (data: any) => void } = {},
) {
  const sub = getConsumer().subscriptions.create(
    { channel: "ShiajoChannel", shiajo_id: shiajoId },
    { received: handlers.received ?? (() => {}) },
  );
  return () => sub.unsubscribe();
}
