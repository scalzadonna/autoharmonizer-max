/**
 * Chord OSC bridge for Max — unified generator + sequencer (protocol v3).
 *
 * Two devices load this one file, each in its OWN Node process:
 *   - chord_generator_device.maxpat  — single-chord generator; sonifies every
 *     Python reply immediately.
 *   - chord_sequencer_device.maxpat  — auto-play Markov sequencer; HOLDS each
 *     reply and plays it on the beat per a harmonic-rhythm template.
 * The two behaviours are gated by `player.active`, which is set only by the
 * sequencer's `play` message. The generator process never sends `play`, so it
 * always takes the immediate path and is byte-for-byte unaffected by the
 * sequencer code below.
 *
 * The OSC wire protocol to Python is v3 (/control/spice, /control/session, …).
 * The sequencer adds NO new OSC — its clock and templates are entirely Max-side.
 * Uses node-osc instead of CNMAT externals.
 */

const Max = require("max-api");
const parser = require("./chord_parser.js");

const PYTHON_HOST = "127.0.0.1";
const PYTHON_PORT = 9000;
const MAX_PORT = 9001;
// Generous so neural models (rnn/lstm) don't false-timeout. NB: on very dense
// templates at fast tempo a late reply can still trip a spurious "reply timeout".
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
  colorMajor: 0, // sequencer colour dials: chance of forcing a major 3rd
  colorMinor: 0, // chance of forcing a minor 3rd
  color7th: 0, // chance of adding a flat-7th (all 0 = natural triad)
};
let previousVoicing = null; // last voicing, for nearest-voicing continuity

const ROOT_NAMES = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

// --- harmonic-rhythm sequencer (used only by the sequencer device) -------
// Each template lists chord onsets (in quarter-note beats) within a 1- or 2-bar
// 4/4 cycle. This is the authoritative copy; data/harmonic_templates.csv mirrors
// it as reference data (nothing loads the CSV at runtime).
const TEMPLATES = {
  1: { name: "whole_bar", spanBars: 1, onsets: [0] },
  2: { name: "half_half", spanBars: 1, onsets: [0, 2] },
  3: { name: "four_quarters", spanBars: 1, onsets: [0, 1, 2, 3] },
  4: { name: "half_qtr_qtr", spanBars: 1, onsets: [0, 2, 3] },
  5: { name: "qtr_qtr_half", spanBars: 1, onsets: [0, 1, 2] },
  6: { name: "qtr_half_qtr", spanBars: 1, onsets: [0, 1, 3] },
  7: { name: "static_2bar", spanBars: 2, onsets: [0] },
};
// Rhythm-dial order, sparse -> dense: 0.0 = one chord / 2 bars, 1.0 = every beat.
const RHYTHM_ORDER = [7, 1, 2, 4, 6, 5, 3];

const player = {
  active: false, // transport running — ALSO the gate for held sonification
  templateId: 2, // half_half (matches the rhythm dial's 0.333 default)
  pendingTemplateId: null, // queued template, applied on the next bar downbeat
  lengthBars: 4, // phrase length in bars; stops at lengthBars*4 beats
  beat: -1, // global beat counter; first clock tick -> 0
  pending: null, // latest Python reply, held to sound on the next onset
  seed: "C:maj", // chord the chain (re)starts from
};

function clamp01(v) {
  const n = Number(v);
  return Number.isFinite(n) ? Math.max(0, Math.min(1, n)) : 0;
}

// Voice a chord symbol: emit ["chord", symbol] (display) then ["notes", ...] on
// success or ["stop"] for N.C. `source` is for logging only. The ["chord", ...]
// tag drives the sequencer's readout; the generator's route lacks it, so it
// falls off the generator's unconnected unmatched outlet (no effect there).
function sonifyChord(symbol, source = "markov") {
  let result;
  try {
    result = parser.chordToNotes(symbol, voicingOptions, previousVoicing);
  } catch (err) {
    Max.post(`chord voice error (${source}) for ${symbol}: ${err.stack || err}`);
    return;
  }
  Max.outlet(["chord", result.normalizedSymbol || symbol]);
  if (result.error) {
    // Unvoiceable symbol: keep it quiet (raw symbol is still shown via output).
    Max.post(`cannot voice ${symbol} (${source}): ${result.error.code} ${result.error.detail || ""}`);
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

// --- sequencer clock -----------------------------------------------------
function templateCycleBeats(id) {
  return (TEMPLATES[id] || TEMPLATES[3]).spanBars * 4;
}

function isSlotOnset(id, beatInCycle) {
  return (TEMPLATES[id] || TEMPLATES[3]).onsets.includes(beatInCycle);
}

function rhythmToTemplate(v) {
  const x = clamp01(v);
  const idx = Math.round(x * (RHYTHM_ORDER.length - 1));
  return RHYTHM_ORDER[idx];
}

function playerStart() {
  player.active = true;
  player.beat = -1;
  player.pending = null;
  Max.outlet(["status", "playing"]);
  submitChord(player.seed); // prefetch the beat-0 chord (its successor sounds first)
}

function playerStop(reason) {
  if (!player.active) return; // idempotent: avoids playoff <-> play-toggle loops
  player.active = false;
  previousVoicing = null;
  Max.outlet(["stop"]); // silence held notes
  Max.outlet(["playoff"]); // stop the metro + reset the PLAY toggle in Max
  Max.outlet(["status", reason || "stopped"]);
}

function playerBeat() {
  if (!player.active) return;
  player.beat += 1;
  const b = player.beat;
  if (b >= player.lengthBars * 4) {
    playerStop("done");
    return;
  }
  // Queued rhythm sweep lands musically, on the bar downbeat.
  if (b % 4 === 0 && player.pendingTemplateId != null) {
    player.templateId = player.pendingTemplateId;
    player.pendingTemplateId = null;
  }
  const beatInCycle = b % templateCycleBeats(player.templateId);
  if (!isSlotOnset(player.templateId, beatInCycle)) return; // between onsets: hold
  const chord = player.pending || player.seed;
  sonifyChord(chord, "player"); // sound the held chord as a triad
  submitChord(chord); // one-step lookahead: fetch this chord's successor
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
    player.seed = symbol; // always track the latest chord for reseeding
    if (player.active) {
      player.pending = symbol; // sequencer: hold; playerBeat sounds it on the onset
    } else if (symbol) {
      sonifyChord(symbol, "markov"); // generator / manual: sonify immediately
    }
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
  return parts.join(" ").trim();
}

// Quiet send core (no console spam) — used by sendChord, notein, and the
// sequencer's per-beat feed so playback doesn't flood the Max console.
function submitChord(value) {
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
}

function sendChord(...args) {
  const value = chordFromArgs(...args);
  if (!value) {
    Max.outlet(["error", "empty chord input"]);
    return;
  }
  Max.post(`sending chord: ${value}`);
  submitChord(value);
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
  sendChord(ROOT_NAMES[pc] + ":maj"); // user action → keep the v3 console log
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

// --- sequencer handlers (only the sequencer device sends these) ----------
Max.addHandler("play", (value) => {
  if (Number(value) !== 0) playerStart();
  else playerStop("stopped");
});

Max.addHandler("beat", () => {
  playerBeat();
});

Max.addHandler("template", (value) => {
  const id = Math.round(Number(value));
  if (TEMPLATES[id]) {
    player.templateId = id;
    player.pendingTemplateId = null;
  }
});

Max.addHandler("rhythm", (value) => {
  const id = rhythmToTemplate(value);
  player.pendingTemplateId = id; // applied on the next downbeat while playing
  if (!player.active) player.templateId = id; // immediate when stopped
  Max.outlet(["rhythmname", TEMPLATES[id].name]);
});

Max.addHandler("length", (value) => {
  const n = Math.round(Number(value));
  if (Number.isFinite(n) && n > 0) player.lengthBars = n;
});

Max.addHandler("seed", (...atoms) => {
  const s = chordFromArgs(...atoms);
  if (s) player.seed = s;
});

Max.addHandler("register", (value) => {
  const v = Number(value);
  if (!Number.isFinite(v)) return;
  voicingOptions.registerCenter = v;
  voicingOptions.low = Math.max(0, Math.round(v - 12));
  voicingOptions.high = Math.min(127, Math.round(v + 12));
});

Max.addHandler("voiceleading", (value) => {
  voicingOptions.voiceLeadingEnabled = Number(value) !== 0;
});

Max.addHandler("triadsonly", (value) => {
  voicingOptions.triadsOnly = Number(value) !== 0;
  previousVoicing = null; // voice count changes
});

Max.addHandler("colormajor", (v) => {
  voicingOptions.colorMajor = clamp01(v);
});

Max.addHandler("colorminor", (v) => {
  voicingOptions.colorMinor = clamp01(v);
});

Max.addHandler("color7th", (v) => {
  voicingOptions.color7th = clamp01(v);
});

Max.addHandler("panic", () => {
  previousVoicing = null;
  Max.outlet(["stop"]);
});

Max.addHandler("testparse", (...atoms) => {
  const symbol = chordFromArgs(...atoms);
  if (!symbol) {
    Max.outlet(["error", "empty test chord"]);
    return;
  }
  sonifyChord(symbol, "test");
});

Max.post("markov_osc.js loaded (v3 unified: generator + sequencer)");
