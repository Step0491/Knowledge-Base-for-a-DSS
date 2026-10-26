# Knowledge Base for a DSS: Spotify Context-Aware Music Recommendation

A Prolog-based Decision Support System (DSS) that integrates biometric context (heart rate, stress level, activity) with Spotify audio features and user genre preferences to recommend suitable music and generate context-aware playlists.

## Overview

Traditional streaming recommenders rely mainly on past listening logs or track popularity. This system uses rule-based inference in SWI-Prolog to evaluate whether a song fits the listener's real-time state:

- **Context & Biometrics**: Combines user activity (`high_stress_work`, `cardio_running`, `deep_focus_study`, `sleep_preparation`, `post_workout_recovery`, `active_commute`), heart rate (BPM), stress index, and preferred Spotify genres.
- **Spotify Audio Features**: Uses tempo (BPM), energy, valence, and instrumentalness.
- **Orthogonal Decision Constraints**:
  - **Activity Match (`activity_compatible/2`)**: Matches audio tempo and energy to the user's current state (relaxing slow tracks for high stress, energetic fast tracks for workouts, quiet tracks for sleep, balanced tracks for normal routines).
  - **Focus Protection (`focus_compatible/2`)**: Enforces lyric-free instrumental music when the user is studying or working in deep focus.
  - **Safety Barrier (`safe_track/2`)**: Uses negation as failure (`\+`) to exclude high-tempo or high-energy tracks when the user exhibits elevated stress and heart rate.
- **Spotify Scoring & Playlist Generation**: Ranks eligible tracks by tempo proximity to the activity goal, user genre affinity, and mood valence, then recursively builds a duplicate-free context playlist (`build_playlist/3`).

---

## Project Structure

```
.
├── data/
│   ├── spotify_tracks.json        # Music catalog with audio features
│   └── smartwatch_biometrics.json # User profiles with activity and biometric data
├── generate_kb.py                 # Generates knowledge_base.pl from JSON datasets
├── knowledge_base.pl              # Unified Prolog facts: track/8 and user/7
├── dss_rules.pl                   # Rules, safety barriers, scoring, and recursive playlist builder
├── main.pl                        # Entry point with queries, explanation, demo, and unit tests
├── DSS_Project_Documentation.pdf  # Project technical documentation
└── README.md
```

---

## Requirements

- **Python 3.8+** (for compiling the JSON datasets into Prolog facts)
- **SWI-Prolog** (tested on version 9.x / 10.x)

---

## Getting Started

### 1. Generate the Knowledge Base (Optional)
The repository already includes `knowledge_base.pl`. To regenerate it from `data/`:

```bash
python generate_kb.py
```

### 2. Run with SWI-Prolog

Start an interactive session:

```bash
swipl main.pl
```

Available queries:

```prolog
% 1. Recommendations & Context Playlists
?- recommend(user_sarah).                      % Single optimal track with rationale
?- recommend_playlist(user_sarah, 3).          % Build a 3-track Spotify context playlist
?- discover_by_genre(user_sarah, classical).   % Filter a genre by current constraints

% 2. Safety Audit & Feasibility Explanation
?- check_safety(user_sarah, adrenaline_rush_rock).     % Safety check on a track
?- explain_rejection(user_sarah, adrenaline_rush_rock). % Detailed pass/fail breakdown

% 3. Inverted Query
?- find_users_for_track(clair_de_lune).        % Find users eligible for a track

% 4. Demo & Test Suite
?- demo.                                       % Demo across sample profiles
?- run_tests.                                  % Run all 7 automated verification tests
```

Or run directly from the command line:

```bash
swipl -s main.pl -g "demo, run_tests, halt."
```
