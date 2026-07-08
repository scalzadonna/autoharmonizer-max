/**
 * Markov chord OSC bridge for Max (protocol v1).
 * Uses node-osc instead of CNMAT externals.
 */

const Max = require("max-api");

const PYTHON_HOST = "127.0.0.1";
const PYTHON_PORT = 9000;
const MAX_PORT = 9001;
const REPLY_TIMEOUT_MS = 500;

let client = null;
let server = null;
let replyTimer = null;

function clearReplyTimeout() {
  if (replyTimer) {
    clearTimeout(replyTimer);
    replyTimer = null;
  }
}

function startReplyTimeout() {
  clearReplyTimeout();
  replyTimer = setTimeout(() => {
    Max.outlet(["error", "reply timeout"]);
  }, REPLY_TIMEOUT_MS);
}

function emit(address, args) {
  if (address === "/chord/output") {
    clearReplyTimeout();
    Max.outlet(["output", String(args[0] ?? "")]);
    return;
  }

  if (address === "/status/ready" || address === "/status/pong") {
    Max.outlet(["status", "ready"]);
    return;
  }

  if (address === "/error") {
    Max.outlet(["error", String(args[0] ?? "unknown error")]);
    return;
  }

  if (address.startsWith("/debug/")) {
    Max.post(`debug ${address} ${args.join(" ")}`);
  }
}

function parseOscMessage(msg) {
  if (Array.isArray(msg)) {
    return { address: msg[0], args: msg.slice(1) };
  }
  if (msg && typeof msg === "object" && msg.address) {
    return { address: msg.address, args: (msg.args || []).map((a) => a.value ?? a) };
  }
  return { address: String(msg), args: [] };
}

function sendOsc(address, ...args) {
  if (!client) {
    Max.outlet(["error", "OSC client not ready — run npm install"]);
    return;
  }
  client.send(address, ...args);
}

function initOsc() {
  if (client && server) {
    return;
  }

  const { Client, Server } = require("node-osc");

  client = new Client(PYTHON_HOST, PYTHON_PORT);
  server = new Server(MAX_PORT, "127.0.0.1", () => {
    Max.post(`listening on ${MAX_PORT}, sending to ${PYTHON_HOST}:${PYTHON_PORT}`);
    Max.outlet(["status", "waiting"]);
  });

  server.on("message", (msg) => {
    const parsed = parseOscMessage(msg);
    emit(parsed.address, parsed.args);
  });

  server.on("error", (err) => {
    Max.post(`OSC server error: ${err}`);
    Max.outlet(["error", String(err.message || err)]);
  });
}

Max.addHandler("init", () => {
  try {
    initOsc();
    sendOsc("/control/ping");
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet([
      "error",
      "node-osc missing — click npm install, then ping",
    ]);
  }
});

Max.addHandler("ping", () => {
  try {
    initOsc();
    sendOsc("/control/ping");
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

function chordFromArgs(args) {
  const parts = args.map((a) => String(a ?? "").trim()).filter(Boolean);
  if (parts.length > 1 && parts[0] === "text") {
    return parts.slice(1).join(" ").trim();
  }
  return parts.join(" ").trim();
}

Max.addHandler("send", (...args) => {
  const value = chordFromArgs(args);
  if (!value) {
    Max.outlet(["error", "empty chord input"]);
    return;
  }

  try {
    initOsc();
    startReplyTimeout();
    sendOsc("/chord/input", value);
  } catch (err) {
    clearReplyTimeout();
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.addHandler("reload", () => {
  try {
    initOsc();
    sendOsc("/control/reload");
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.post("markov_osc.js loaded — click npm install once if needed");
