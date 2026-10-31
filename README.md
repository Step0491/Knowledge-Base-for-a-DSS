# Knowledge Base for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization

[![Prolog](https://img.shields.io/badge/Prolog-SWI--Prolog-blue.svg)](https://www.swi-prolog.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)
[![Tests](https://img.shields.io/badge/Tests-10%2F10_Passing-brightgreen.svg)]()
[![Notebook](https://img.shields.io/badge/Notebook-Jupyter_Walkthrough-orange.svg)](demo_walkthrough.ipynb)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Abstract:** Conventional music recommendation systems suffer from the *"context-blind recommendation"* flaw: they suggest songs based on historical listening logs or aggregate popularity, completely disregarding the user's immediate psychophysiological state.
>
> This **Decision Support System (DSS)** overcomes this limitation by merging mathematical audio features from **Spotify** (BPM, affective valence, energy intensity, instrumental purity) with real-time biometric telemetry from a **Smartwatch** (heart rate, stress score, physical/cognitive activity).
> 
> Leveraging **Prolog first-order logic** and a **hierarchical AND-OR inference tree**, the DSS acts as an automated real-time cognitive assistant: it evaluates candidate feasibility across physiological, cognitive, circadian, and medical safety pillars to prescribe the optimal track or synthesize a relaxation routine (*Altshuler's Iso-Principle*), providing feedback explanations.

---

## 1. System Architecture & Repository Structure

```
Knowledge-Base-for-a-DSS/
├── data/
│   ├── spotify_tracks.json        # Curated catalog of 30 tracks with Spotify acoustic attributes
│   └── smartwatch_biometrics.json # 6 realistic user telemetry profiles (Heart Rate, Stress, Activity)
├── generate_kb.py                 # ETL pipeline: compiles JSON catalogs into normalized Prolog facts
├── knowledge_base.pl              # Emitted Prolog facts: track/8 and user/7
├── dss_rules.pl                   # Hierarchical inference engine: meta-rules, sub-rules, and scoring
├── main.pl                        # Main Prolog entry point with intuitive user queries (e.g. ?- recommend(user_sarah).)
├── test_suite.py                  # Standalone automated verification suite (10/10 tests passed)
├── demo_walkthrough.ipynb         # Interactive Jupyter Notebook walkthrough (pre-executed for oral exams)
├── LICENSE                        # MIT License
└── README.md                      # Academic project documentation
```

---

## 2. Knowledge Base Data Model

### 2.1 Spotify Audio Features (`data/spotify_tracks.json` $\rightarrow$ `track/8`)
Each song is represented by the normalized Prolog relation:
```prolog
track(Id, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness).
```
* **BPM (Beats Per Minute):** Musical tempo (e.g. 60.0 ambient, 140.0 techno).
* **Valence ($[0.0, 1.0]$):** Musical positiveness and cheerfulness.
* **Energy ($[0.0, 1.0]$):** Perceptual measure of acoustic intensity and activity.
* **Instrumentalness ($[0.0, 1.0]$):** Confidence that the track contains no vocal lyrics ($> 0.70$ signifies lyric-free instrumental music).

### 2.2 Smartwatch Telemetry Log (`data/smartwatch_biometrics.json` $\rightarrow$ `user/7`)
Captures the real-time psychophysiological state:
```prolog
user(Id, Name, Activity, HeartRate, StressLevel, TargetGoal, PreferredGenres).
```
* **Activity:** `high_stress_work`, `cardio_running`, `deep_focus_study`, `sleep_preparation`, `active_commute`.
* **Heart Rate (BPM):** Live PPG sensor readings.
* **Stress Level ($[0, 100]$):** Autonomic arousal derived from Heart Rate Variability (HRV) and Galvanic Skin Response (GSR).

---

## 3. Inference Engine: Hierarchical AND-OR Goal Tree (`dss_rules.pl`)

The expert system decomposes high-level goals into multi-tiered backward chaining rules:

```
[Level 0: Meta-Rule]
       recommendable_track(Track, User)
            |
            +---> physiologically_compatible/2  ---> [Level 2: acute_sympathetic_state, cardio_aerobic_regime, ...]
            |                                         |--> [Level 3: slow_tempo, low_energy, fast_tempo]
            |
            +---> cognitively_compatible/2      ---> [Level 2: phonological_loop_protection (Inst >= 0.70)]
            |
            +---> safety_and_contraindications/2 -> [Level 2: tachycardia barrier & fatigue overstimulation check]
            |
            +---> circadian_coherent/2          ---> [Level 2: biological sleep window acoustic ceilings]
```

### A. The Four Evaluation Pillars (Level 1)
1. **Physiological Compatibility (`physiologically_compatible/2`):**  
   Evaluates autonomic balance. An acute sympathetic state requires sedative acoustic parameters (`BPM <= 75`, `Energy <= 0.35`). Cardio running activates ergogenic synchronization (`BPM >= 120`, `Energy >= 0.70`).
2. **Cognitive Protection (`cognitively_compatible/2`):**  
   During intellectual tasks (`deep_focus_study`), protects working memory from lyrical phonological interference by enforcing `Instrumentalness >= 0.70`.
3. **Medical Safety Barriers (`safety_and_contraindications/2`):**  
   Implements negative barriers (*primum non nocere*): categorically prohibits high-arousal tracks ($>100$ BPM or $>0.60$ energy) for users exhibiting acute stress tachycardia ($>110$ BPM and $>75$ stress).
4. **Circadian Coherence (`circadian_coherent/2`):**  
   Enforces tempo and acoustic ceilings during sleep induction routines.

### B. Altshuler's Iso-Principle (Clinical Music Therapy)
For patients in acute sympathetic distress (e.g. 114 BPM), directly playing a 60 BPM ambient track causes affective rejection. The predicate `iso_principle_session/2` generates a 3-stage entrainment session:
$$\text{Entry (105 BPM)} \longrightarrow \text{Bridge (85 BPM)} \longrightarrow \text{Target Resting Lock (60 BPM)}$$

---

## 4. Usage & Execution Guide

### Option 1: Jupyter Notebook
Open [`demo_walkthrough.ipynb`](demo_walkthrough.ipynb):
```bash
jupyter notebook demo_walkthrough.ipynb
```
The notebook is fully pre-executed, showcasing exploratory data analysis, KB compilation, recommendation scenarios, and the test suite.

### Option 2: Automated Verification from Terminal (Python)
Run the 10-point logical verification test suite:
```bash
python test_suite.py
```
To re-compile Prolog facts from the raw JSON catalogs:
```bash
python generate_kb.py
```
---

## 5. Logical Verification Results

Executing `test_suite.py` validates all 10 formal criteria with zero errors:
```
========================================================================
 LOGICAL VERIFICATION TEST SUITE (HIERARCHICAL AND-OR GOAL TREE)
========================================================================
 [+] 1. Physiological Sedative Pillar (Sarah) -> Slow, instrumental ambient track: PASSED
 [+] 2. Physiological Ergogenic Pillar (Alex) -> High cadence and maximal energy: PASSED
 [+] 3. Cognitive Protection Pillar (Marco) -> Zero vocal intrusion (instrumental): PASSED
 [+] 4. Circadian Sleep Coherence (David) -> Somnolent acoustic regime (BPM <= 64): PASSED
 [+] 5. Post-Workout Homeostatic Recovery (Elena) -> Moderate controlled activation: PASSED
 [+] 6. Active Commute Vitality (Clara) -> Positive valence and moderate pacing: PASSED
 [+] 7. Iso-Principle Entrainment -> Downward monotonicity (Entry -> Bridge -> Target): PASSED
 [+] 8. Medical Safety Barrier (Negative Test) -> Prohibit high-energy track for Sarah: PASSED
 [+] 9. Cognitive Barrier (Negative Test) -> Prohibit lyrical track for Marco in study: PASSED
 [+] 10. Multi-Attribute Scoring -> Affirmative bonus for user genre affinity: PASSED
------------------------------------------------------------------------
 Test Execution Summary: 10/10 Passed successfully.
========================================================================
```

---
