# Knowledge Base for a DSS: Context-Aware Music Recommendation

[![Prolog](https://img.shields.io/badge/Prolog-SWI--Prolog-blue.svg)](https://www.swi-prolog.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)
[![Tests](https://img.shields.io/badge/Tests-10%2F10_Passing-brightgreen.svg)]()
[![Documentation ODT](https://img.shields.io/badge/Documentation-ODT_Source-blue.svg)](DSS_Project_Documentation.odt)
[![Documentation PDF](https://img.shields.io/badge/Documentation-PDF_Report-red.svg)](DSS_Project_Documentation.pdf)
[![Notebook](https://img.shields.io/badge/Notebook-Jupyter_Walkthrough-orange.svg)](demo_walkthrough.ipynb)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Author:** Stefano Colella (865075) &bull; Fundamentals of AI (9 CFU), Master's Degree in Computer Science, University of Bari Aldo Moro

> **Abstract:** This Knowledge-Based Decision Support System solves context-blind music recommendation by combining Spotify acoustic features with real-time smartwatch telemetry (heart rate, stress level, activity, and routine goal). Built as a classic **Expert System**, it strictly separates domain facts, declarative rules, short-term Working Memory, and a backward-chaining meta-interpreter with confidence scoring, `WHY`/`HOW` explanations, and safety barriers.

---

## 1. System Architecture (Separated KB & Inference Engine)

Following the Expert System architecture taught in the course (`applian.gie` pattern — separating Knowledge Base from Inference Engine):

```
Knowledge-Base-for-a-DSS/
├── data/
│   ├── spotify_tracks.json         # 30 curated tracks with Spotify audio features & tags
│   └── smartwatch_biometrics.json  # 6 smartwatch biometric profiles
├── generate_kb.py                  # ETL compiler: JSON -> knowledge_base.pl
├── knowledge_base.pl               # Long-Term Facts: track/8, track_tag/2, user/7
├── kb_rules.pl                     # Long-Term Declarative KB: is_a/2 taxonomy, askable/2, rule/5
├── inference_engine.pl             # Separated Meta-Interpreter, Working Memory, WHY/HOW, MAUT
├── main.pl                         # Interactive Expert System Shell (?- start.) & test runner
├── test_suite.py                   # Automated Python test driver invoking the Prolog engine (10/10)
├── demo_walkthrough.ipynb          # Pre-executed Jupyter Notebook calling Prolog
├── build_docs_pdf.py               # Documentation compiler (HTML -> ODT + PDF)
├── documentation.html              # Report HTML source
├── DSS_Project_Documentation.odt   # Editable OpenDocument Text source (exam deliverable)
├── DSS_Project_Documentation.pdf   # Academic project technical report (PDF)
└── LICENSE                         # MIT License
```

---

## 2. How to Run & Demonstrate (For the Examiner)

### Option A: Interactive SWI-Prolog Shell (Recommended for Exam Demo)
```bash
swipl -s main.pl
```
Inside Prolog, launch the interactive shell:
```prolog
?- start.
```
The menu allows the examiner to:
1. Select any smartwatch profile (`user_sarah`, `user_alex`, `user_marco`, `user_elena`, `user_david`, `user_clara`).
2. Enter custom live smartwatch readings (including `unknown.` for missing activity or goal).
3. Run automatic recommendation (`recommend/1`).
4. Run an **interactive consultation** where missing context triggers `askable/2` questions supporting `yes.`, `no.`, and **`why.`** (explaining which rule chain needs that answer).
5. Print the **`HOW` Proof Tree** (`explain_last_decision/1`) showing the exact rules fired, confidence values, and Working Memory facts.
6. Inspect Top-5 alternatives, generate a **3-step Gradual Calm Playlist** (`entry -> bridge -> target`), inspect Working Memory (`show_wm/0`), inspect KB rules (`show_kb_rules/0`), or execute the 10-point Prolog test suite (`run_tests/0`).

Direct one-line queries are also available:
```prolog
?- recommend_with_how(user_sarah).
?- recommend_session(user_sarah).
?- demo.
?- run_tests.
```

### Option B: Python Automated Verification (Invokes Real Prolog)
`test_suite.py` does **not** re-implement rules in Python; it executes `swipl` (or `yap` fallback if `swipl` is not in PATH) directly on `main.pl` and checks all 10 criteria:
```bash
python test_suite.py
```

### Option C: Rebuild KB & Documentation (ODT + PDF)
```bash
python generate_kb.py
python build_docs_pdf.py
```

---

## 3. Logical Verification Summary (10/10 Passed via Prolog)

1. **Stress Relief Pillar (Sarah Miller):** Recommends *Clair de Lune (Debussy)* (64 BPM, Energy 0.18, Score 90.3, Conf 0.94).
2. **Intense Workout Pillar (Alex Chen):** Recommends *Subterranean Stamina Loop* (140 BPM, Energy 0.92, Score 88.4, Conf 0.96).
3. **Study Lyric-Free Pillar (Marco Rossi):** Recommends *Analog Cassette Memory* (80 BPM, Instrumental 0.86, Score 91.1, Conf 0.96).
4. **Pre-Sleep Pillar (David Becker):** Recommends *Delta Wave Binaural Serenade* (55 BPM, Energy 0.08, Score 89.9, Conf 0.93).
5. **Post-Workout Recovery (Elena Rostova):** Recommends *Nordic Dawn Acoustic Solitude* (82 BPM, Energy 0.36, Score 88.5, Conf 0.90).
6. **Active Commute Vitality (Clara Dupont):** Recommends *Steady Stride Metropolitan* (108 BPM, Valence 0.68, Score 86.9, Conf 0.90).
7. **Gradual Calm Playlist:** 3-step downward tempo curve `105 BPM -> 92 BPM -> 55 BPM`.
8. **Safety Barrier (Negative Test):** Blocks `adrenaline_rush_rock` (150 BPM) for stressed Sarah.
9. **Study Barrier (Negative Test):** Blocks `euphoric_run_anthem` (vocal pop) for studying Marco.
10. **Preference & Proof Tree:** Preferred genre affinity yields strictly higher utility (`90.3 > 70.5`) with a non-empty verifiable Proof Tree.
