/**
 * Markov chord OSC bridge for Max (protocol v1 + chord sonification).
 * Uses node-osc instead of CNMAT externals.
 *
 * OSC protocol to Python is UNCHANGED (v1):
 *   Max -> Python : /chord/input <string>, /control/ping, /control/reload
 *   Python -> Max : /chord/output <string>, /status/ready|/status/pong, /error
 *
 * Node -> Max message protocol (extended, backward compatible):
 *   status <word>           (unchanged)
 *   output <symbol>         (unchanged — raw Markov reply for the rest of the system)
 *   error  <code> [detail]  (unchanged shape; parser errors add a detail atom)
 *   chord  <normalized>     (NEW — normalized Markov chord symbol for display)
 *   notes  <midi ...>       (NEW — playable MIDI note list)
 *   stop                    (NEW — silence currently sounding notes, e.g. N.C.)
 *
 * PROJECT CONSTRAINT: only MAJOR or MINOR triads are sonified. `chord`
 * always shows the full symbol the Markov system returned (e.g. Cmaj7); the
 * `notes` are the reduced major/minor triad (C E G). Toggle with `triadsonly`.
 *
 * The returned chord that is sonified is ALWAYS the chord returned by the
 * Markov/Python system — never merely the chord the user typed. A separate,
 * clearly-labelled `testparse` handler exists for parser debugging only.
 */

const Max = require("max-api");
const parser = require("./chord_parser.js");

const PYTHON_HOST = "127.0.0.1";
const PYTHON_PORT = 9000;
const MAX_PORT = 9001;
const REPLY_TIMEOUT_MS = 500;

let client = null;
let server = null;
let replyTimer = null;

// --- chord voicing / sonification state ---------------------------------
const voicingOptions = {
  registerCenter: 60, // approx C4
  low: 48, // C3
  high: 72, // C5
  voiceLeadingEnabled: true,
  // PROJECT CONSTRAINT: only major/minor triads are sonified. The parser
  // still recognises the full symbol; the voicing engine reduces it to a
  // plain triad. Toggle with the `triadsonly` message.
  triadsOnly: true,
};
let previousVoicing = null; // last MIDI voicing, for nearest-voicing mode

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

/**
 * Parse a returned chord symbol, voice it, and emit the display + MIDI
 * branch messages. Used by BOTH the real Markov reply path and the manual
 * TEST PARSER path. Never throws.
 */
function sonifyChord(symbol, source) {
  let result;
  try {
    result = parser.chordToNotes(symbol, voicingOptions, previousVoicing);
  } catch (err) {
    Max.post(`chord parse crash: ${err.stack || err}`);
    Max.outlet(["error", "parser_exception", String(symbol)]);
    return;
  }

  // Show the normalized symbol regardless of outcome (helps debugging).
  Max.outlet(["chord", result.normalizedSymbol]);

  if (result.error) {
    // Do NOT emit MIDI, do NOT replay the previous chord.
    Max.outlet(["error", result.error.code, result.error.detail]);
    return;
  }

  if (result.isNoChord) {
    // N.C. — stop currently sounding notes and generate nothing new.
    previousVoicing = null;
    Max.outlet(["stop"]);
    Max.post(`${source}: no-chord -> silence`);
    return;
  }

  previousVoicing = result.notes;
  Max.outlet(["notes", ...result.notes]);
  Max.post(
    `${source}: ${result.normalizedSymbol} -> ${result.triadQuality} triad ` +
      `notes ${result.notes.join(" ")}`
  );
}

function emit(address, args) {
  if (address === "/chord/output") {
    clearReplyTimeout();
    const symbol = String(args[0] ?? "");
    // 1) backward-compatible raw symbol out for the rest of the system
    Max.outlet(["output", symbol]);
    // 2) NEW: interpret -> voice -> sonify the Markov-returned chord
    sonifyChord(symbol, "markov");
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

/**
 * Collapse the atoms a `send` message carries into one chord string.
 * A Max `textedit` emits its contents as `text <word> <word> ...`; the Send
 * button and the Enter key both route through here, so we accept:
 *   - a leading "text" selector (strip it),
 *   - multiple atoms (join with a space),
 *   - a single symbol.
 * Surrounding quotes are stripped again by the parser as a second defence.
 */
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

// --- NEW handlers -------------------------------------------------------

/**
 * TEST PARSER — parse/voice/sonify a chord DIRECTLY, bypassing Markov.
 * For debugging the parser + MIDI branch without Python running.
 * This does NOT touch the OSC / Markov path.
 */
Max.addHandler("testparse", (...atoms) => {
  const symbol = chordFromArgs(atoms);
  if (!symbol) {
    Max.outlet(["error", "empty test chord"]);
    return;
  }
  sonifyChord(symbol, "test");
});

/** Set the register centre used by the voicing engine (Max-side control). */
Max.addHandler("register", (value) => {
  const v = Number(value);
  if (Number.isFinite(v)) {
    voicingOptions.registerCenter = v;
    // keep the comfortable window centred on the requested register
    voicingOptions.low = Math.max(0, Math.round(v - 12));
    voicingOptions.high = Math.min(127, Math.round(v + 12));
    Max.post(`register center -> ${v} (range ${voicingOptions.low}..${voicingOptions.high})`);
  }
});

/** Toggle nearest-voicing (voice leading) on/off. */
Max.addHandler("voiceleading", (value) => {
  voicingOptions.voiceLeadingEnabled = Number(value) !== 0;
  Max.post(`voice leading -> ${voicingOptions.voiceLeadingEnabled ? "on" : "off"}`);
});

/**
 * Toggle major/minor-triads-only sonification. Default ON (project
 * constraint). When OFF the full parsed chord is voiced instead.
 */
Max.addHandler("triadsonly", (value) => {
  voicingOptions.triadsOnly = Number(value) !== 0;
  previousVoicing = null; // voice count changes -> reset voice-leading history
  Max.post(`triads only -> ${voicingOptions.triadsOnly ? "on" : "off"}`);
});

/** Manual panic: forget history and tell Max to stop sounding notes. */
Max.addHandler("panic", () => {
  previousVoicing = null;
  Max.outlet(["stop"]);
});

Max.post("markov_osc.js loaded — click npm install once if needed");
