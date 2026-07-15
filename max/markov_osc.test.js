/**
 * markov_osc.test.js — self-contained tests for the unified bridge's SEQUENCER
 * engine and the generator's immediate-sonify path. No external framework.
 * Run with:  node markov_osc.test.js   (or `npm test`)  — exits non-zero on fail.
 *
 * `max-api` and `node-osc` only exist inside Max at runtime, so we stub them via
 * a module-resolution override, load the REAL markov_osc.js, and drive it:
 * capturing its Max.addHandler handlers, Max.outlet emissions, and OSC sends.
 * chord_parser.js runs for real (pure JS).
 */
"use strict";

const Module = require("module");
const origRequire = Module.prototype.require;

const handlers = {};
const outlets = [];
let sends = [];
const servers = [];

const fakeMax = {
  addHandler: (name, fn) => { handlers[name] = fn; },
  outlet: (...a) => {
    const msg = a.length === 1 && Array.isArray(a[0]) ? a[0] : a;
    outlets.push(msg);
  },
  post: () => {},
};
class FakeClient { send(...a) { sends.push(a); } }
class FakeServer {
  constructor(_port, _host, cb) { this.cbs = {}; servers.push(this); if (cb) cb(); }
  on(ev, cb) { this.cbs[ev] = cb; }
}
Module.prototype.require = function (id) {
  if (id === "max-api") return fakeMax;
  if (id === "node-osc") return { Client: FakeClient, Server: FakeServer };
  return origRequire.apply(this, arguments);
};

require("./markov_osc.js");

const clearOutlets = () => { outlets.length = 0; };
const findTag = (t) => outlets.filter((o) => o[0] === t);
const pythonReply = (symbol) => servers[0].cbs.message(["/chord/output", symbol]);

let pass = 0;
let fail = 0;
const failures = [];
const assert = (cond, msg) => { if (cond) pass++; else { fail++; failures.push(msg); } };

// boot the bridge
handlers["init"]();
assert(servers.length === 1, "init creates one OSC server");
assert(sends.some((s) => s[0] === "/control/ping"), "init pings python");

// --- generator-immediate: reply sonifies at once when not playing -----------
clearOutlets(); sends = [];
pythonReply("C:maj7");
assert(findTag("output")[0] && findTag("output")[0][1] === "C:maj7", "generator: output emitted");
assert(findTag("chord").length === 1, "generator: chord display emitted");
const n1 = findTag("notes")[0];
assert(n1 && n1.slice(1).length === 3, "generator: sonifies immediately (triad)");

// --- sequencer-hold: reply is held, sounds on the beat ----------------------
handlers["length"](4);
clearOutlets(); handlers["rhythm"](1); // four_quarters => onset every beat
assert(findTag("rhythmname")[0][1] === "four_quarters", "rhythm 1.0 -> four_quarters");
clearOutlets(); sends = [];
handlers["play"](1);
assert(findTag("status").some((s) => s[1] === "playing"), "play -> status playing");
assert(sends.some((s) => s[0] === "/chord/input"), "play prefetches the seed");
clearOutlets(); sends = [];
pythonReply("A:min7");
assert(findTag("notes").length === 0, "sequencer: reply HELD while playing (no notes)");
assert(findTag("output").length === 1, "sequencer: reply still shown in output");
clearOutlets(); sends = [];
handlers["beat"](); // b=0 is an onset for four_quarters
const held = findTag("notes")[0];
assert(held && held.slice(1).length === 3, "sequencer: held chord sounds on the beat");
assert(sends.some((s) => s[0] === "/chord/input"), "sequencer: onset fetches successor");
handlers["play"](0);

// --- density gating: dense vs sparse templates ------------------------------
function onsetsOver(rhythmVal, nBeats) {
  handlers["play"](0);
  handlers["rhythm"](rhythmVal);
  handlers["length"](8);
  handlers["play"](1);
  pythonReply("C:maj");
  let c = 0;
  for (let i = 0; i < nBeats; i++) { clearOutlets(); handlers["beat"](); if (findTag("notes").length) c++; }
  handlers["play"](0);
  return c;
}
const dense = onsetsOver(1, 8);
const sparse = onsetsOver(0, 8);
assert(dense === 8, "four_quarters sonifies every beat (8/8)");
assert(sparse <= 2 && sparse < dense, "static_2bar much sparser than four_quarters");

// --- rhythm dial sparse->dense mapping --------------------------------------
const nameFor = (v) => { clearOutlets(); handlers["rhythm"](v); return findTag("rhythmname")[0][1]; };
assert(nameFor(0) === "static_2bar", "rhythm 0.0 -> static_2bar (sparsest)");
assert(nameFor(1) === "four_quarters", "rhythm 1.0 -> four_quarters (densest)");

// --- v3 protocol handlers intact --------------------------------------------
sends = []; handlers["spice"](0.7);
assert(sends.some((s) => s[0] === "/control/spice" && Math.abs(s[1] - 0.7) < 1e-9), "spice -> /control/spice 0.7");
sends = []; handlers["model"]("rnn");
assert(sends.some((s) => s[0] === "/control/model" && s[1] === "rnn"), "model -> /control/model rnn");
sends = []; handlers["session"]("stateless");
assert(sends.some((s) => s[0] === "/control/session" && s[1] === "stateless"), "session -> /control/session");
sends = []; handlers["reset_session"]();
assert(sends.some((s) => s[0] === "/control/session" && s[1] === "reset"), "reset_session -> reset");

// --- queued rhythm sweep lands on the bar downbeat, not mid-bar -------------
handlers["play"](0); handlers["rhythm"](1); handlers["length"](8); handlers["play"](1);
pythonReply("C:maj");
handlers["beat"](); // b=0
handlers["beat"](); // b=1
handlers["rhythm"](0); // queue static_2bar mid-bar
clearOutlets(); handlers["beat"](); const b2 = findTag("notes").length > 0; // b=2 still dense
clearOutlets(); handlers["beat"](); const b3 = findTag("notes").length > 0; // b=3 still dense
clearOutlets(); handlers["beat"](); const b4 = findTag("notes").length > 0; // b=4 downbeat -> sparse applies (not onset)
assert(b2 && b3, "queued sweep does NOT apply mid-bar (b2,b3 still dense)");
assert(!b4, "sweep applies on downbeat: sparse template suppresses non-onset b4");
handlers["play"](0);

console.log(`markov_osc engine tests: ${pass} passed, ${fail} failed`);
if (fail) { failures.forEach((f) => console.log("  FAIL: " + f)); console.log("FAILURES"); process.exit(1); }
console.log("ALL PASS");
