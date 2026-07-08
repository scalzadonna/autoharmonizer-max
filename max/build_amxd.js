/**
 * build_amxd.js — wrap chord_markov_device.maxpat into a Max for Live
 * MIDI-Effect device (Chord Markov Device.amxd).
 *
 * Run from this folder:
 *   node build_amxd.js                                  # main device
 *   node build_amxd.js <input.maxpat> <output.amxd>     # any patch
 *
 * .amxd container format (the minimal variant Live also writes, e.g. as seen
 * in stock/3rd-party MIDI devices):
 *
 *   "ampf" | uint32(4) | "mmmm" | "ptch" | uint32(payloadSize) | <JSON> | 0x00
 *
 * - "mmmm" is the device-type code for a MIDI Effect (audio = "aaaa",
 *   instrument = "iiii").
 * - The trailing 0x00 byte IS included in the ptch payload size.
 * - The patcher JSON is the plain .maxpat with a few Max-for-Live device
 *   metadata keys injected (parameters/openrect/…) so Live loads it cleanly.
 */
"use strict";
const fs = require("fs");
const path = require("path");

const DIR = __dirname;
// Optional args: input .maxpat and output .amxd (names or paths).
const SRC = path.resolve(DIR, process.argv[2] || "chord_markov_device.maxpat");
const OUT = path.resolve(DIR, process.argv[3] || "Chord Markov Device.amxd");

function u32(n) { const b = Buffer.alloc(4); b.writeUInt32LE(n >>> 0, 0); return b; }

const doc = JSON.parse(fs.readFileSync(SRC, "utf8"));
const P = doc.patcher;

// --- Max for Live device metadata (added only in the .amxd, not the .maxpat) ---
P.openrect = [0.0, 0.0, 860.0, 400.0];   // device window in Live's device strip
P.latency = 0;
P.is_mpe = 0;
P.external_mpe_tuning_enabled = 0;
P.minimum_live_version = "";
P.minimum_max_version = "";
P.platform_compatibility = 0;
P.saved_attribute_attributes = { default_plcolor: { expression: "" } };
// This device exposes no live.* parameters -> an empty, Live-format bank.
P.parameters = {
  parameterbanks: { "0": { index: 0, name: "", parameters: ["-", "-", "-", "-", "-", "-", "-", "-"] } },
  inherited_shortname: 1,
};

const jsonText = JSON.stringify(doc, null, "\t");
const payload = Buffer.concat([Buffer.from(jsonText, "utf8"), Buffer.from([0x00])]);
const amxd = Buffer.concat([
  Buffer.from("ampf", "latin1"),
  u32(4),
  Buffer.from("mmmm", "latin1"), // MIDI Effect
  Buffer.from("ptch", "latin1"),
  u32(payload.length),
  payload,
]);
fs.writeFileSync(OUT, amxd);

// self-check: round-trip the container back to valid JSON
const b = fs.readFileSync(OUT);
if (b.slice(8, 12).toString("latin1") !== "mmmm") throw new Error("bad device type");
const i = b.indexOf(Buffer.from("ptch"));
const size = b.readUInt32LE(i + 4);
const parsed = JSON.parse(b.slice(i + 8, i + 8 + size - 1).toString("utf8"));
if (20 + payload.length !== amxd.length) throw new Error("size mismatch");
console.log(
  `wrote "${path.basename(OUT)}"  (${amxd.length} bytes, type mmmm, ` +
    `${parsed.patcher.boxes.length} boxes, ${parsed.patcher.lines.length} lines)`
);
