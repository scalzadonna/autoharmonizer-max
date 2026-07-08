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
 *   playoff                 (NEW — auto-player finished; stop the transport)
 *
 * Auto-player (sequencer front-end): `play 1|0`, `beat` (quarter-note clock),
 * `template <1..7>`, `length <bars>`, `seed <chord>` walk the Markov chain over
 * a harmonic-rhythm template, feeding each chord back as the next input.
 *
 * PROJECT CONSTRAINT: only MAJOR or MINOR triads are sonified. `chord`
 * always shows the full symbol the Markov system returned (e.g. Cmaj7); the
 * `notes` are the reduced major/minor triad (C E G). Toggle with `triadsonly`.
 *
 * MIDI input: a `notein <pitch>` message (from Ableton via midiin/midiparse)
 * seeds the chain — the played note becomes a major-triad root symbol and is
 * submitted just like a typed chord, so the sonified chord is the Markov reply.
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
  // Performable colour knobs (0..1), driven by live.dials in the sequencer:
  //   colorMajor -> chance of forcing MAJOR, colorMinor -> chance of MINOR,
  //   color7th   -> chance of adding a flat-7th. All 0 => natural triad.
  colorMajor: 0,
  colorMinor: 0,
  color7th: 0,
};
let previousVoicing = null; // last MIDI voicing, for nearest-voicing mode

// --- auto-player state (walks the Markov chain over a harmonic template) --
// Harmonic-rhythm templates: slot ONSETS in quarter-note beats within a
// 1- or 2-bar (4/4) cycle. Chords change at each onset and sustain until the
// next (the MIDI branch flushes held notes before each new chord).
const TEMPLATES = {
  1: { name: "whole_bar", spanBars: 1, onsets: [0] },
  2: { name: "half_half", spanBars: 1, onsets: [0, 2] },
  3: { name: "four_quarters", spanBars: 1, onsets: [0, 1, 2, 3] },
  4: { name: "half_qtr_qtr", spanBars: 1, onsets: [0, 2, 3] },
  5: { name: "qtr_qtr_half", spanBars: 1, onsets: [0, 1, 2] },
  6: { name: "qtr_half_qtr", spanBars: 1, onsets: [0, 1, 3] },
  7: { name: "static_2bar", spanBars: 2, onsets: [0] },
};
const player = {
  active: false,
  templateId: 3, // four_quarters
  lengthBars: 4,
  beat: -1, // first metro tick advances to 0
  pending: null, // next Markov chord to sonify on the beat
  seed: "C:maj", // chord the chain (re)starts from = latest chord handled
};

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
    // 2) remember the latest chord so the auto-player can (re)seed from it
    player.seed = symbol;
    if (player.active) {
      // In auto-play mode the reply is the NEXT slot's chord; the player
      // sonifies on the beat, so just stash it — do not sound it now.
      player.pending = symbol;
    } else {
      // manual / MIDI mode: interpret -> voice -> sonify immediately
      sonifyChord(symbol, "markov");
    }
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

/**
 * Send a chord symbol to the Python Markov service. Shared by the `send`
 * button/Enter path and the MIDI-note-in path so both seed the chain the
 * same way and the sonified chord is always the Markov reply.
 */
function submitChord(value) {
  const v = String(value ?? "").trim();
  if (!v) {
    Max.outlet(["error", "empty chord input"]);
    return;
  }
  try {
    initOsc();
    startReplyTimeout();
    sendOsc("/chord/input", v);
  } catch (err) {
    clearReplyTimeout();
    Max.post(err.stack || err);
    Max.outlet(["error", String(err.message || err)]);
  }
}

Max.addHandler("send", (...args) => {
  submitChord(chordFromArgs(args));
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

/**
 * MIDI note-in from Ableton seeds the Markov chain. A played note's pitch
 * class becomes a major-triad root symbol (e.g. 60 -> "C:maj", 66 -> "F#:maj")
 * in the dataset's colon notation and is submitted exactly like a typed chord;
 * the chord the Markov system returns is what gets voiced. Note-offs are
 * filtered upstream by `stripnote`, but we double-guard on velocity 0 here.
 */
const ROOT_NAMES = ["C", "Db", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"];

Max.addHandler("notein", (note, velocity) => {
  const n = Number(note);
  if (!Number.isFinite(n)) return;
  if (velocity !== undefined && Number(velocity) === 0) return; // ignore note-offs
  const pc = ((Math.round(n) % 12) + 12) % 12;
  submitChord(ROOT_NAMES[pc] + ":maj");
});

/* -----------------------------------------------------------------------
 * Auto-player: play along the Markov chain for a set number of bars, using
 * a harmonic-rhythm template to decide when chords change. At each slot we
 * sonify the chord we hold and feed it back to Python; the reply becomes the
 * next slot's chord (output -> input). Dormant until `play 1`.
 * --------------------------------------------------------------------- */

function templateCycleBeats(id) {
  return (TEMPLATES[id] || TEMPLATES[3]).spanBars * 4;
}
function isSlotOnset(id, beatInCycle) {
  return (TEMPLATES[id] || TEMPLATES[3]).onsets.indexOf(beatInCycle) !== -1;
}

function playerStart() {
  player.active = true;
  player.beat = -1;
  player.pending = null;
  const t = TEMPLATES[player.templateId] || TEMPLATES[3];
  Max.post(
    `player: start template ${player.templateId} (${t.name}) for ${player.lengthBars} bars, seed ${player.seed}`
  );
  Max.outlet(["status", "playing"]);
  submitChord(player.seed); // fetch the first chord to play on beat 0
}

function playerStop(reason) {
  if (!player.active) return; // idempotent — avoids playoff/toggle feedback loops
  player.active = false;
  previousVoicing = null;
  Max.outlet(["stop"]); // silence held notes
  Max.outlet(["playoff"]); // stop the transport metro + reset the PLAY toggle
  Max.outlet(["status", reason || "stopped"]);
  Max.post(`player: ${reason || "stopped"}`);
}

function playerBeat() {
  if (!player.active) return;
  player.beat += 1;
  const b = player.beat;
  if (b >= player.lengthBars * 4) {
    playerStop("done");
    return;
  }
  if (!isSlotOnset(player.templateId, b % templateCycleBeats(player.templateId))) return;
  const chord = player.pending || player.seed;
  sonifyChord(chord, "player"); // play the current chord (as a triad)
  submitChord(chord); // ask Markov for its successor -> becomes pending
}

Max.addHandler("play", (value) => {
  if (Number(value) !== 0) playerStart();
  else playerStop("stopped");
});

/** Quarter-note clock tick from a transport-synced metro in Max. */
Max.addHandler("beat", () => {
  playerBeat();
});

/** Choose the harmonic-rhythm template (1..7). */
Max.addHandler("template", (value) => {
  const id = Math.round(Number(value));
  if (TEMPLATES[id]) {
    player.templateId = id;
    Max.post(`player: template ${id} (${TEMPLATES[id].name})`);
  }
});

/** Set the predetermined length in bars. */
Max.addHandler("length", (value) => {
  const n = Math.round(Number(value));
  if (Number.isFinite(n) && n > 0) {
    player.lengthBars = n;
    Max.post(`player: length ${n} bars`);
  }
});

/** Explicit seed override (optional; the chain also tracks the latest chord). */
Max.addHandler("seed", (...atoms) => {
  const s = chordFromArgs(atoms);
  if (s) {
    player.seed = s;
    Max.post(`player: seed ${s}`);
  }
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

/* --- performable colour knobs (live.dials, 0..1) ----------------------- */
function clamp01(v) {
  v = Number(v);
  if (!Number.isFinite(v)) return 0;
  return v < 0 ? 0 : v > 1 ? 1 : v;
}
/** Encourage MAJOR chords (probability 0..1). */
Max.addHandler("colormajor", (v) => {
  voicingOptions.colorMajor = clamp01(v);
});
/** Encourage MINOR chords (probability 0..1). */
Max.addHandler("colorminor", (v) => {
  voicingOptions.colorMinor = clamp01(v);
});
/** Encourage 7th chords — adds a flat-7th (probability 0..1). */
Max.addHandler("color7th", (v) => {
  voicingOptions.color7th = clamp01(v);
});

/** Manual panic: forget history and tell Max to stop sounding notes. */
Max.addHandler("panic", () => {
  previousVoicing = null;
  Max.outlet(["stop"]);
});

Max.post("markov_osc.js loaded — click npm install once if needed");
