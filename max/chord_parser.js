/**
 * chord_parser.js — pure-JavaScript chord symbol parser + voicing engine.
 *
 * Responsibilities ONLY (no Max / OSC / lifecycle code lives here):
 *
 *     chord symbol  ->  normalized representation
 *                   ->  root pitch class + interval pattern
 *                   ->  pitch classes
 *                   ->  MIDI voicing (close position or nearest voice-leading)
 *
 * The module is dependency-free CommonJS so it runs unchanged inside
 * Node-for-Max and under plain `node` for the unit tests.
 *
 * Supported input dialects (see README / spec section 8):
 *   - Common jazz/pop notation:  Cmaj7, F#m7, Bb7, Cdim7, Cm7b5, Cmaj7/G ...
 *   - Colon dataset notation:    C:maj, G:7, D:min7, A:hdim7, G:sus4 ...
 *   - Glyphs:                     ♭ ♯ Δ ° ø +  -
 *   - No-chord:                   N.C.  NC  no_chord  (parsed as silence)
 */

"use strict";

/* ------------------------------------------------------------------ *
 * 1. Pitch-class fundamentals
 * ------------------------------------------------------------------ */

// Natural note letter -> semitone within an octave (C = 0).
const NOTE_BASE = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

// Accidental glyph/char -> semitone offset.
const ACCIDENTAL = { "#": 1, "b": -1, "x": 2 };

/* ------------------------------------------------------------------ *
 * 2. Chord quality dictionary
 *
 * Qualities are stored ONCE as interval patterns measured from the
 * root (never as absolute notes and never duplicated per root).  The
 * same table is reused for every one of the 12 roots.
 * ------------------------------------------------------------------ */

const QUALITIES = {
  // --- triads ------------------------------------------------------
  "": [0, 4, 7], // bare symbol = major
  maj: [0, 4, 7],
  major: [0, 4, 7],
  M: [0, 4, 7],
  Maj: [0, 4, 7],
  m: [0, 3, 7],
  min: [0, 3, 7],
  minor: [0, 3, 7],
  Min: [0, 3, 7],
  "-": [0, 3, 7],
  "5": [0, 7], // power chord
  dim: [0, 3, 6],
  o: [0, 3, 6],
  aug: [0, 4, 8],
  Aug: [0, 4, 8],
  "+": [0, 4, 8],
  sus: [0, 5, 7],
  sus4: [0, 5, 7],
  sus2: [0, 2, 7],

  // --- sixth chords ------------------------------------------------
  "6": [0, 4, 7, 9],
  maj6: [0, 4, 7, 9],
  M6: [0, 4, 7, 9],
  m6: [0, 3, 7, 9],
  min6: [0, 3, 7, 9],
  "-6": [0, 3, 7, 9],
  "6/9": [0, 4, 7, 9, 14],
  "69": [0, 4, 7, 9, 14],

  // --- seventh chords ---------------------------------------------
  "7": [0, 4, 7, 10], // dominant 7
  dom7: [0, 4, 7, 10],
  maj7: [0, 4, 7, 11],
  M7: [0, 4, 7, 11],
  ma7: [0, 4, 7, 11],
  Maj7: [0, 4, 7, 11],
  m7: [0, 3, 7, 10],
  min7: [0, 3, 7, 10],
  Min7: [0, 3, 7, 10],
  "-7": [0, 3, 7, 10],
  mMaj7: [0, 3, 7, 11],
  mM7: [0, 3, 7, 11],
  minmaj7: [0, 3, 7, 11],
  "-maj7": [0, 3, 7, 11],
  dim7: [0, 3, 6, 9],
  o7: [0, 3, 6, 9],
  m7b5: [0, 3, 6, 10], // half-diminished
  min7b5: [0, 3, 6, 10],
  hdim7: [0, 3, 6, 10], // colon-dataset spelling
  hdim: [0, 3, 6, 10],

  // --- add / extended ---------------------------------------------
  add9: [0, 4, 7, 14],
  add2: [0, 2, 4, 7],
  madd9: [0, 3, 7, 14],
  "9": [0, 4, 7, 10, 14],
  maj9: [0, 4, 7, 11, 14],
  M9: [0, 4, 7, 11, 14],
  m9: [0, 3, 7, 10, 14],
  min9: [0, 3, 7, 10, 14],
  "11": [0, 7, 10, 14, 17], // dom11 (3rd usually dropped)
  maj11: [0, 4, 7, 11, 14, 17],
  m11: [0, 3, 7, 10, 14, 17],
  min11: [0, 3, 7, 10, 14, 17],
  "13": [0, 4, 7, 10, 14, 21], // dom13 (11th dropped)
  maj13: [0, 4, 7, 11, 14, 21],
  m13: [0, 3, 7, 10, 14, 21],
  min13: [0, 3, 7, 10, 14, 21],

  // --- altered dominants (explicit, incl. parenthesised forms) ----
  "7b5": [0, 4, 6, 10],
  "7#5": [0, 4, 8, 10],
  "7b9": [0, 4, 7, 10, 13],
  "7#9": [0, 4, 7, 10, 15],
  "7#11": [0, 4, 7, 10, 18],
  "7b13": [0, 4, 7, 10, 20],
  "9#11": [0, 4, 7, 10, 14, 18],
  "13#11": [0, 4, 7, 10, 14, 18, 21],
  "maj7#11": [0, 4, 7, 11, 18],
  "M7#11": [0, 4, 7, 11, 18],
};

// Which quality-table keys are unambiguous *words* (length >= 3, contain a
// letter run) and may therefore be matched case-insensitively as a fallback.
// Single-letter markers (M / m) are deliberately EXCLUDED so that "M7" is
// never silently lower-cased into "m7" (major vs minor confusion).
const WORDY = /(maj|min|dim|aug|sus|add|hdim|dom)/i;

/* ------------------------------------------------------------------ *
 * 3. Normalization
 * ------------------------------------------------------------------ */

const NO_CHORD_TOKENS = new Set([
  "n.c.",
  "nc",
  "no_chord",
  "nochord",
  "n.c",
  "silence",
  "rest",
  "-",
]);

/**
 * Clean a raw symbol coming off OSC / a text field.
 * Trims whitespace, strips surrounding quotes and stray newlines, and
 * converts unicode accidentals to ASCII.  Does NOT change musical case.
 */
function normalizeSymbol(raw) {
  let s = String(raw == null ? "" : raw);
  // strip newlines / carriage returns / tabs anywhere
  s = s.replace(/[\r\n\t]+/g, " ");
  // collapse internal whitespace, then trim
  s = s.replace(/\s+/g, " ").trim();
  // strip a single layer of surrounding quotes (straight or curly)
  s = s.replace(/^['"‘’“”]+/, "");
  s = s.replace(/['"‘’“”]+$/, "");
  s = s.trim();
  // unicode accidentals -> ascii
  s = s.replace(/♭/g, "b").replace(/♯/g, "#"); // ♭ ♯
  s = s.replace(/𝄫/g, "bb"); // 𝄫 double flat (rare)
  s = s.replace(/𝄪/g, "x"); // 𝄪 double sharp (rare)
  // remove interior spaces entirely for the musical token (keep it compact)
  s = s.replace(/\s+/g, "");
  return s;
}

function isNoChord(normalized) {
  if (normalized === "") return true;
  return NO_CHORD_TOKENS.has(normalized.toLowerCase());
}

/* ------------------------------------------------------------------ *
 * 4. Root parsing
 * ------------------------------------------------------------------ */

/**
 * Parse a leading root (uppercase letter A-G + optional accidentals).
 * Returns { letter, accidental, pitchClass, length } or null.
 *
 * Root letters are REQUIRED to be uppercase so that a lone "B" is never
 * mistaken for a flat "b" and vice-versa.
 */
function parseRoot(str) {
  const m = /^([A-G])([#bx]*)/.exec(str);
  if (!m) return null;
  const letter = m[1];
  const accStr = m[2];
  let pc = NOTE_BASE[letter];
  for (const ch of accStr) pc += ACCIDENTAL[ch] || 0;
  pc = ((pc % 12) + 12) % 12;
  return {
    letter,
    accidental: accStr,
    root: letter + accStr,
    pitchClass: pc,
    length: m[0].length,
  };
}

/* ------------------------------------------------------------------ *
 * 5. Quality parsing
 * ------------------------------------------------------------------ */

/**
 * Canonicalize a quality string: map glyphs, strip parentheses/commas.
 * Order matters (multi-char glyph forms handled before single-char).
 */
function canonicalizeQuality(q) {
  let s = q;
  s = s.replace(/[Δ△]/g, "maj"); // Δ △ -> maj  (so Δ7 -> maj7)
  s = s.replace(/ø7/g, "m7b5").replace(/ø/g, "m7b5"); // ø7 / ø
  s = s.replace(/[°º]7/g, "dim7"); // °7 / º7
  s = s.replace(/[°º]/g, "dim"); // ° / º
  s = s.replace(/[()\[\],\s]/g, ""); // drop brackets / commas / spaces
  return s;
}

/**
 * Resolve a quality string to an interval array, or null if unsupported.
 */
function lookupQuality(rawQuality) {
  const q = canonicalizeQuality(rawQuality);

  // 1. exact (case-sensitive) match — resolves the M7 vs m7 ambiguity.
  if (Object.prototype.hasOwnProperty.call(QUALITIES, q)) {
    return QUALITIES[q].slice();
  }

  // 2. guarded case-insensitive match, ONLY for wordy qualities so that
  //    bare single-letter M/m are never conflated.
  if (WORDY.test(q)) {
    const lower = q.toLowerCase();
    for (const key of Object.keys(QUALITIES)) {
      if (key.toLowerCase() === lower && WORDY.test(key)) {
        return QUALITIES[key].slice();
      }
    }
  }

  return null;
}

/* ------------------------------------------------------------------ *
 * 6. Full chord parsing
 * ------------------------------------------------------------------ */

/**
 * Parse a chord symbol into a structured representation.
 *
 * On success returns:
 *   {
 *     originalSymbol, normalizedSymbol, isNoChord:false,
 *     root, rootPitchClass, quality, intervals, pitchClasses,
 *     bass, bassPitchClass            // bass fields null when no slash
 *   }
 *
 * For a no-chord returns { ..., isNoChord:true, pitchClasses:[] }.
 *
 * On failure returns { ..., error:{ code, detail } } where code is one of
 *   "invalid_root" | "unsupported_chord" | "unsupported_modifier".
 */
function parseChord(raw) {
  const originalSymbol = String(raw == null ? "" : raw);
  const normalizedSymbol = normalizeSymbol(originalSymbol);

  if (isNoChord(normalizedSymbol)) {
    return {
      originalSymbol,
      normalizedSymbol: normalizedSymbol === "" ? "N.C." : normalizedSymbol,
      isNoChord: true,
      root: null,
      rootPitchClass: null,
      quality: null,
      intervals: [],
      pitchClasses: [],
      bass: null,
      bassPitchClass: null,
    };
  }

  // Split off a slash bass (first '/').  Colon notation never uses '/'.
  let main = normalizedSymbol;
  let bassStr = null;
  const slash = main.indexOf("/");
  if (slash !== -1) {
    bassStr = main.slice(slash + 1);
    main = main.slice(0, slash);
  }

  // Colon dataset notation:  Root:quality
  let rootStr;
  let qualityStr;
  const colon = main.indexOf(":");
  if (colon !== -1) {
    rootStr = main.slice(0, colon);
    qualityStr = main.slice(colon + 1);
    const r = parseRoot(rootStr);
    if (!r || r.length !== rootStr.length) {
      return failure(originalSymbol, normalizedSymbol, "invalid_root", normalizedSymbol);
    }
    var rootInfo = r;
  } else {
    const r = parseRoot(main);
    if (!r) {
      return failure(originalSymbol, normalizedSymbol, "invalid_root", normalizedSymbol);
    }
    rootInfo = r;
    qualityStr = main.slice(r.length);
  }

  const intervals = lookupQuality(qualityStr);
  if (!intervals) {
    // Root was valid, so the offending part is the quality/modifier.
    return failure(
      originalSymbol,
      normalizedSymbol,
      "unsupported_modifier",
      normalizedSymbol
    );
  }

  // Optional slash bass.
  let bass = null;
  let bassPitchClass = null;
  if (bassStr !== null) {
    const b = parseRoot(bassStr);
    if (!b || b.length !== bassStr.length) {
      return failure(originalSymbol, normalizedSymbol, "invalid_root", normalizedSymbol);
    }
    bass = b.root;
    bassPitchClass = b.pitchClass;
  }

  const rootPc = rootInfo.pitchClass;
  const pitchClasses = intervals.map((iv) => ((rootPc + iv) % 12 + 12) % 12);

  return {
    originalSymbol,
    normalizedSymbol,
    isNoChord: false,
    root: rootInfo.root,
    rootPitchClass: rootPc,
    quality: canonicalizeQuality(qualityStr) || "maj",
    intervals: intervals.slice(),
    pitchClasses,
    bass,
    bassPitchClass,
  };
}

function failure(originalSymbol, normalizedSymbol, code, detail) {
  return {
    originalSymbol,
    normalizedSymbol,
    isNoChord: false,
    root: null,
    rootPitchClass: null,
    quality: null,
    intervals: [],
    pitchClasses: [],
    bass: null,
    bassPitchClass: null,
    error: { code, detail },
  };
}

/* ------------------------------------------------------------------ *
 * 7. Voicing engine
 * ------------------------------------------------------------------ */

const DEFAULT_VOICING_OPTIONS = {
  registerCenter: 60, // approx C4 — target centre of gravity
  low: 48, // C3   — bottom of the comfortable range
  high: 72, // C5   — top of the comfortable range
  // PROJECT CONSTRAINT: only major or minor triads are ever sonified.  The
  // parser still fully understands the incoming symbol (Cmaj7, Dm7b5, …); the
  // voicing engine collapses it to a plain triad.  Set false to voice the
  // full chord as understood by the parser.
  triadsOnly: true,
};

// The only two chord shapes we ever sonify when triadsOnly is on.
const MAJOR_TRIAD = [0, 4, 7];
const MINOR_TRIAD = [0, 3, 7];

/**
 * Collapse any parsed chord to a MAJOR or MINOR triad.
 *
 * The quality is decided purely by the chord's third relative to the root:
 *   - a major third (interval 4) present anywhere  -> major triad [0,4,7]
 *   - else a minor third (interval 3) present       -> minor triad [0,3,7]
 *   - no third at all (power chords, sus chords)    -> default to major triad
 *
 * Testing 4 before 3 keeps altered dominants such as 7#9 ([0,4,7,10,15],
 * whose #9 is enharmonically a raised minor third) correctly MAJOR.
 *
 * @returns {{ intervals: number[], quality: "major"|"minor" }}
 */
function triadIntervals(parsed) {
  const iv = (parsed && parsed.intervals) || [];
  if (iv.indexOf(4) !== -1) return { intervals: MAJOR_TRIAD.slice(), quality: "major" };
  if (iv.indexOf(3) !== -1) return { intervals: MINOR_TRIAD.slice(), quality: "minor" };
  return { intervals: MAJOR_TRIAD.slice(), quality: "major" };
}

/**
 * Intervals actually used for voicing: the reduced triad when triadsOnly is
 * on (the default), otherwise the full chord the parser understood.
 */
function effectiveIntervals(parsed, opt) {
  return opt && opt.triadsOnly === false ? parsed.intervals : triadIntervals(parsed).intervals;
}

function clampMidi(n) {
  return Math.max(0, Math.min(127, Math.round(n)));
}

/**
 * Close-position (root position) voicing.
 *
 * The chord is stacked from a root placed in the octave starting at
 * `low`, i.e. rootMidi = low + (rootPitchClass mod 12), then each interval
 * is added on top.  A slash bass is placed one octave below the root.
 *
 * With defaults this yields the canonical examples:
 *   Cmaj7 -> 48 52 55 59,  Dm7 -> 50 53 57 60,  G7 -> 55 59 62 65
 * (produced by the algorithm, NOT hard-coded).
 */
function voiceChord(parsed, options) {
  const opt = Object.assign({}, DEFAULT_VOICING_OPTIONS, options || {});
  if (!parsed || parsed.isNoChord || parsed.error) return [];

  const low = opt.low;
  const rootMidi = low + (((parsed.rootPitchClass % 12) + 12) % 12);
  const intervals = effectiveIntervals(parsed, opt);

  const notes = [];

  // Slash bass one octave below the chord root (kept as the lowest note).
  if (parsed.bassPitchClass != null) {
    const bassOctaveStart = low - 12; // e.g. 36 = C2
    let bassMidi = bassOctaveStart + (((parsed.bassPitchClass % 12) + 12) % 12);
    if (bassMidi >= rootMidi) bassMidi -= 12;
    notes.push(clampMidi(bassMidi));
  }

  for (const iv of intervals) {
    notes.push(clampMidi(rootMidi + iv));
  }

  return dedupeSorted(notes);
}

function dedupeSorted(notes) {
  return Array.from(new Set(notes)).sort((a, b) => a - b);
}

/* ------------------------------------------------------------------ *
 * 8. Nearest-voicing (simple voice leading)
 * ------------------------------------------------------------------ */

/**
 * Generate candidate voicings for the chord: every inversion, shifted
 * across a few octaves, kept within (roughly) the target register.
 */
function candidateVoicings(parsed, opt) {
  const pcs = effectiveIntervals(parsed, opt).map(
    (iv) => (((parsed.rootPitchClass + iv) % 12) + 12) % 12
  );
  const uniquePcs = Array.from(new Set(pcs));
  const n = uniquePcs.length;
  const candidates = [];

  for (let inv = 0; inv < n; inv++) {
    // rotate so inversion `inv` is the lowest voice
    const order = [];
    for (let k = 0; k < n; k++) order.push(uniquePcs[(inv + k) % n]);

    for (let baseOct = -1; baseOct <= 1; baseOct++) {
      const startLow = opt.low + baseOct * 12;
      // place the first pc at/above startLow, then stack ascending
      let prev = startLow + (((order[0] - startLow) % 12) + 12) % 12;
      const voicing = [prev];
      for (let k = 1; k < order.length; k++) {
        let note = prev + ((((order[k] - prev) % 12) + 12) % 12);
        if (note <= prev) note += 12;
        voicing.push(note);
        prev = note;
      }
      candidates.push(voicing.map(clampMidi));
    }
  }
  return candidates;
}

/** Movement + register cost of a candidate relative to the previous voicing. */
function voicingCost(candidate, previous, opt) {
  let cost = 0;

  // register penalty: notes outside [low, high] are discouraged
  for (const note of candidate) {
    if (note < opt.low) cost += (opt.low - note) * 0.5;
    if (note > opt.high) cost += (note - opt.high) * 0.5;
  }
  // discourage very wide spreads
  const spread = candidate[candidate.length - 1] - candidate[0];
  if (spread > 24) cost += (spread - 24) * 0.25;

  if (!previous || previous.length === 0) return cost;

  // nearest-note movement: for each candidate voice, distance to the
  // closest previous voice, plus a penalty for voice-count mismatch.
  let movement = 0;
  for (const note of candidate) {
    let best = Infinity;
    for (const p of previous) best = Math.min(best, Math.abs(note - p));
    movement += best;
  }
  cost += movement;
  cost += Math.abs(candidate.length - previous.length) * 2;
  return cost;
}

/**
 * Choose the candidate voicing nearest to `previousVoicing`.
 * Deterministic: ties are broken by the lower/earlier candidate.
 */
function voiceLead(parsed, previousVoicing, options) {
  const opt = Object.assign({}, DEFAULT_VOICING_OPTIONS, options || {});
  if (!parsed || parsed.isNoChord || parsed.error) return [];

  const base = voiceChord(parsed, opt);
  if (!previousVoicing || previousVoicing.length === 0) return base;

  const candidates = candidateVoicings(parsed, opt);
  candidates.push(base); // always consider the plain root-position voicing

  let bestVoicing = base;
  let bestCost = Infinity;
  for (const cand of candidates) {
    const sorted = dedupeSorted(cand);
    const c = voicingCost(sorted, previousVoicing, opt);
    if (c < bestCost) {
      bestCost = c;
      bestVoicing = sorted;
    }
  }

  // Re-apply the slash bass below the chosen voicing, if any.
  if (parsed.bassPitchClass != null) {
    const bassOctaveStart = opt.low - 12;
    let bassMidi = bassOctaveStart + (((parsed.bassPitchClass % 12) + 12) % 12);
    while (bassMidi >= bestVoicing[0]) bassMidi -= 12;
    if (bassMidi >= 0) bestVoicing = dedupeSorted([clampMidi(bassMidi), ...bestVoicing]);
  }

  return bestVoicing;
}

/* ------------------------------------------------------------------ *
 * 9. High-level convenience API used by the Node bridge
 * ------------------------------------------------------------------ */

/**
 * Turn a raw chord symbol into a MIDI note list.
 *
 * @param {string} raw            chord symbol (any supported dialect)
 * @param {object} options        { registerCenter, low, high, voiceLeadingEnabled }
 * @param {number[]|null} prevVoicing  previous voicing for voice-leading
 * @returns {{
 *   normalizedSymbol, parsed, notes:number[],
 *   isNoChord:boolean, error:{code,detail}|null
 * }}
 */
function chordToNotes(raw, options, prevVoicing) {
  const opt = options || {};
  let parsed;
  try {
    parsed = parseChord(raw);
  } catch (e) {
    return {
      normalizedSymbol: normalizeSymbol(raw),
      parsed: null,
      notes: [],
      isNoChord: false,
      error: { code: "parser_exception", detail: String((e && e.message) || e) },
    };
  }

  if (parsed.error) {
    return {
      normalizedSymbol: parsed.normalizedSymbol,
      parsed,
      notes: [],
      isNoChord: false,
      error: parsed.error,
    };
  }

  if (parsed.isNoChord) {
    return {
      normalizedSymbol: parsed.normalizedSymbol,
      parsed,
      notes: [],
      isNoChord: true,
      error: null,
    };
  }

  const notes =
    opt.voiceLeadingEnabled && prevVoicing && prevVoicing.length
      ? voiceLead(parsed, prevVoicing, opt)
      : voiceChord(parsed, opt);

  const triad = triadIntervals(parsed);
  const triadsOnly = opt.triadsOnly !== false;

  return {
    normalizedSymbol: parsed.normalizedSymbol,
    parsed,
    notes,
    isNoChord: false,
    error: null,
    // What was actually voiced: the reduced major/minor triad (default) or
    // the full chord quality when triadsOnly is off.
    triadQuality: triadsOnly ? triad.quality : parsed.quality,
    playedIntervals: triadsOnly ? triad.intervals : parsed.intervals.slice(),
  };
}

/* ------------------------------------------------------------------ */

module.exports = {
  NOTE_BASE,
  QUALITIES,
  MAJOR_TRIAD,
  MINOR_TRIAD,
  DEFAULT_VOICING_OPTIONS,
  normalizeSymbol,
  isNoChord,
  parseRoot,
  canonicalizeQuality,
  lookupQuality,
  parseChord,
  triadIntervals,
  effectiveIntervals,
  voiceChord,
  voiceLead,
  candidateVoicings,
  chordToNotes,
};
