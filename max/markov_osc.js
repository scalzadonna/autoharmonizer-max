/**
 * Chord generator OSC bridge for Max (protocol v3).
 * Uses node-osc instead of CNMAT externals.
 */

const Max = require("max-api");
const parser = require("./chord_parser.js");

const PYTHON_HOST = "127.0.0.1";
const PYTHON_PORT = 9000;
const MAX_PORT = 9001;
const REPLY_TIMEOUT_MS = 1500;

let client = null;
let server = null;
let replyTimer = null;

// --- chord voicing / sonification (v3 MIDI output) ----------------------
// The returned chord symbol is voiced into MIDI note numbers and emitted as a
// ["notes", ...] list; the Max patch turns that into makenote -> midiout.
const voicingOptions = {
  registerCenter: 60, // ~C4 centre of gravity
  low: 48, // C3
  high: 72, // C5
  voiceLeadingEnabled: true, // keep successive triads close
  triadsOnly: true, // project default: sonify major/minor triads only
};
let previousVoicing = null; // last voicing, for nearest-voicing continuity

const ROOT_NAMES = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

// Voice the returned chord symbol and emit ["notes", ...] (or ["stop"] for N.C.).
function sonifyChord(symbol) {
  let result;
  try {
    result = parser.chordToNotes(symbol, voicingOptions, previousVoicing);
  } catch (err) {
    Max.post(`chord voice error for ${symbol}: ${err.stack || err}`);
    return;
  }
  if (result.error) {
    // Unvoiceable symbol: keep it quiet (the raw symbol is still shown via output).
    Max.post(`cannot voice ${symbol}: ${result.error.code} ${result.error.detail || ""}`);
    return;
  }
  if (result.isNoChord) {
    previousVoicing = null;
    Max.outlet(["stop"]);
    return;
  }
  if (result.notes && result.notes.length) {
    previousVoicing = result.notes;
    Max.outlet(["notes", ...result.notes]);
  }
}

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
    const symbol = String(args[0] ?? "");
    Max.outlet(["output", symbol]);
    if (symbol) sonifyChord(symbol);
    return;
  }

  if (address === "/status/ready" || address === "/status/pong") {
    Max.outlet(["status", "ready"]);
    return;
  }

  if (address === "/status/model") {
    Max.outlet(["model", String(args[0] ?? "markov")]);
    return;
  }

  if (address === "/status/session") {
    const mode = String(args[0] ?? "stateless");
    const step = Number(args[1] ?? 0);
    Max.outlet(["session", `set ${mode} ${step}`]);
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

function chordFromArgs(...args) {
  const parts = args.map((a) => String(a ?? "").trim()).filter(Boolean);
  if (!parts.length) {
    return "";
  }
  if (parts[0] === "text") {
    return parts.slice(1).join(" ").trim();
  }
  if (parts.length === 1 && parts[0] === "text") {
    return "";
  }
  return parts.join(" ").trim();
}

function sendChord(...args) {
  const value = chordFromArgs(...args);
  if (!value) {
    Max.outlet(["error", "empty chord input"]);
    return;
  }

  Max.post(`sending chord: ${value}`);

  try {
    initOsc();
    startReplyTimeout();
    sendOsc("/chord/input", value);
  } catch (err) {
    clearReplyTimeout();
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
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

Max.addHandler("chord", (...args) => {
  sendChord(...args);
});

Max.addHandler("send", (...args) => {
  sendChord(...args);
});

// A note played into the track seeds the chain: its pitch class becomes a
// major-triad root symbol; the Markov reply is what actually sonifies.
Max.addHandler("notein", (note, velocity) => {
  const n = Number(note);
  if (!Number.isFinite(n)) return;
  if (velocity !== undefined && Number(velocity) === 0) return; // ignore note-offs
  const pc = ((Math.round(n) % 12) + 12) % 12;
  sendChord(ROOT_NAMES[pc] + ":maj");
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

Max.addHandler("model", (...args) => {
  const name = args.map((a) => String(a ?? "").trim()).filter(Boolean).join(" ").trim();
  if (!name) {
    Max.outlet(["error", "empty model name"]);
    return;
  }
  previousVoicing = null; // fresh voicing after a model switch
  try {
    initOsc();
    sendOsc("/control/model", name);
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.addHandler("spice", (...args) => {
  const value = Number(args[0]);
  if (!Number.isFinite(value)) {
    Max.outlet(["error", "spice value must be a number"]);
    return;
  }
  const clamped = Math.max(0, Math.min(1, value));
  try {
    initOsc();
    sendOsc("/control/spice", clamped);
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.addHandler("session", (...args) => {
  const mode = args.map((a) => String(a ?? "").trim()).filter(Boolean).join(" ").trim();
  if (!mode) {
    Max.outlet(["error", "empty session mode"]);
    return;
  }
  try {
    initOsc();
    sendOsc("/control/session", mode);
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.addHandler("reset_session", () => {
  previousVoicing = null; // fresh voicing after a session reset
  try {
    initOsc();
    sendOsc("/control/session", "reset");
  } catch (err) {
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
});

Max.post("markov_osc.js loaded (v3) — click npm install once if needed");
