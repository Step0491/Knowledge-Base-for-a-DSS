# Knowledge Base for a DSS: Context-Aware Music Recommendation

A Prolog-based Decision Support System (DSS) that recommends music tracks based on user activities and biometric context (heart rate and stress level).

## Overview

Traditional recommendation systems typically rely only on past listening history. This system uses rule-based inference to select music according to the user's current state:

- **Biometric & Activity Context**: Considers the user's current activity (e.g. high stress work, cardio running, study, sleep preparation), current heart rate, stress level, and target goal.
- **Audio Features**: Uses tempo (BPM), energy, valence, and instrumentalness to select appropriate tracks.
- **Rule Constraints**:
  - **Relaxation**: Selects slow, low-energy, and instrumental tracks when stress or heart rate is high.
  - **Cardio**: Selects high-tempo and high-energy tracks during workouts.
  - **Focus/Study**: Filters out vocal tracks to avoid distraction during cognitive tasks.
  - **Safety**: Excludes high-energy/high-BPM tracks if the user exhibits elevated stress and heart rate.
  - **Gradual Relaxation (Iso-Principle)**: Generates a 3-track sequence (Entry -> Bridge -> Target) to gradually guide the user from an elevated tempo down to a resting pace.
- **Utility Scoring**: Ranks candidate tracks based on proximity to the ideal target tempo, genre preferences, and valence.

---

## Project Structure

```
.
├── data/
│   ├── spotify_tracks.json        # Music catalog with audio features
│   └── smartwatch_biometrics.json # User profiles with activity and biometric data
├── generate_kb.py                 # Generates knowledge_base.pl from JSON datasets
├── knowledge_base.pl              # Facts: track/8 and user/7
├── dss_rules.pl                   # Inference rules, constraints, and scoring
├── main.pl                        # Entry point with demo, queries, and unit tests
├── DSS_Project_Documentation.pdf  # Project documentation report
└── README.md
```

---

## Requirements

- **Python 3.8+** (for generating the Prolog knowledge base)
- **SWI-Prolog** (tested on version 9.x / 10.x)

---

## Getting Started

### 1. Generate the Knowledge Base (Optional)
The repository already includes `knowledge_base.pl`. To regenerate it from the JSON datasets in `data/`:

```bash
python generate_kb.py
```

### 2. Run with SWI-Prolog

Start an interactive SWI-Prolog session:

```bash
swipl -s main.pl
```

Available queries:

```prolog
% 1. Recommendations
?- recommend(user_sarah).                 % Single optimal recommendation with rationale
?- recommend_top(user_sarah, 3).          % Top N ranked recommendations with utility scores
?- recommend_session(user_sarah).         % 3-stage gradual relaxation session (Iso-Principle)

% 2. Safety Audit & Feasibility Explanation
?- check_safety(user_sarah, adrenaline_rush_rock).     % Clinical safety contraindication check
?- explain_rejection(user_sarah, adrenaline_rush_rock). % Detailed pass/fail constraint breakdown

% 3. Inverted Query
?- find_users_for_track(clair_de_lune).   % Lists all users eligible for a given track

% 4. Demo & Test Suite
?- demo.                                  % Demonstration across sample profiles
?- run_tests.                             % Automated logic verification tests
```

Or run directly from the command line:

```bash
swipl -s main.pl -g "demo, run_tests, halt."
```
