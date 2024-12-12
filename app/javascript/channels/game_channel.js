import consumer from "./consumer";

const worldId = document.querySelector("[data-world-id]")?.dataset.worldId;

if (worldId) {
  consumer.subscriptions.create(
    { channel: "GameChannel", world_id: worldId },
    {
      connected() {
        console.log("Connected to channel for world " + worldId);
      },

      disconnected() {
        console.log("Disconnected from channel");
      },

      received(data) {
        console.log("Received data:", data);

        const gridElement = document.querySelector("#world-grid .grid");
        if (gridElement) {
          gridElement.innerHTML = data.html;
        }
      },
    }
  );
}
