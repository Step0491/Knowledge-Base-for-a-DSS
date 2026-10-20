#!/usr/bin/env python3
"""
test_verification.py
Standalone Python verification test harness for the Knowledge Base & DSS logic.
Mirrors the 10 SWI-Prolog test specifications to ensure cross-platform test execution.

Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
"""

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def load_data():
    with open(ROOT / "data" / "raw" / "spotify_tracks.json", "r", encoding="utf-8") as f:
        tracks = {t["track_id"]: t for t in json.load(f)}
    with open(ROOT / "data" / "raw" / "smartwatch_biometrics.json", "r", encoding="utf-8") as f:
        users = {u["user_id"]: u for u in json.load(f)}
    with open(ROOT / "data" / "raw" / "health_routines.json", "r", encoding="utf-8") as f:
        routines = {r["routine_id"]: r for r in json.load(f)}
    return tracks, users, routines

def validate_track(track, user, routine):
    act = user["current_activity"]
    # Cognitive load bound
    if act == "deep_focus_study":
        if track["instrumentalness"] < 0.70 or track["loudness_db"] > -13.0:
            return False
    # Workout cadence bound
    if act == "cardio_running":
        if track["bpm"] < 120.0 or track["energy"] < 0.70:
            return False
    # Routine bounds
    if not (routine["min_bpm"] <= track["bpm"] <= routine["max_bpm"]):
        return False
    if not (routine["min_valence"] <= track["valence"] <= routine["max_valence"]):
        return False
    if not (routine["min_energy"] <= track["energy"] <= routine["max_energy"]):
        return False
    if track["instrumentalness"] < routine["min_instrumentalness"]:
        return False
    if track["loudness_db"] > routine["max_loudness_db"]:
        return False
    # Required attributes
    req_attrs = routine.get("required_attributes", [])
    if req_attrs:
        track_attrs = set(track.get("health_attributes", []))
        if not any(a in track_attrs for a in req_attrs):
            return False
    return True

def calculate_mcda_utility(track, user, routine, profile="balanced"):
    weights = {
        "health_priority": (0.45, 0.25, 0.20, 0.10),
        "performance_priority": (0.30, 0.20, 0.40, 0.10),
        "acoustic_first": (0.25, 0.35, 0.15, 0.25),
        "balanced": (0.35, 0.25, 0.25, 0.15)
    }.get(profile, (0.35, 0.25, 0.25, 0.15))
    w_bio, w_mood, w_goal, w_pref = weights

    target_mid_hr = sum(routine["target_hr_range"]) / 2.0
    bpm_diff = abs(track["bpm"] - target_mid_hr)
    raw_bio = max(40.0, 100.0 - (bpm_diff / 40.0 * 60.0)) if bpm_diff <= 40.0 else 40.0
    s_bio = min(100.0, raw_bio + track["acousticness"] * 10.0 + track["instrumentalness"] * 10.0) if user["stress_level"] > 65 else raw_bio

    s_mood = (track["valence"] * 70.0 + 30.0) if (user["stress_level"] > 50 or user["fatigue_index"] > 50) else (track["valence"] * 50.0 + 50.0)

    eng_score = 60.0 if (routine["min_energy"] <= track["energy"] <= routine["max_energy"]) else 30.0
    matched_attrs = set(routine.get("required_attributes", [])) & set(track.get("health_attributes", []))
    s_goal = eng_score + min(40.0, len(matched_attrs) * 40.0)

    s_pref = 100.0 if track["genre"] in user.get("preferred_genres", []) else 50.0

    utility = w_bio * s_bio + w_mood * s_mood + w_goal * s_goal + w_pref * s_pref
    return utility, s_bio, s_mood, s_goal, s_pref

def recommend(user_id, tracks, users, routines, profile="balanced"):
    user = users[user_id]
    routine = routines[user["target_health_goal"]]
    candidates = [t for t in tracks.values() if validate_track(t, user, routine)]
    if not candidates:
        return None
    scored = []
    for c in candidates:
        u, sb, sm, sg, sp = calculate_mcda_utility(c, user, routine, profile)
        scored.append((u, c, (sb, sm, sg, sp)))
    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[0]

def run_tests():
    tracks, users, routines = load_data()
    tests = [
        ("Test 1: Acute stress downregulation recommends low BPM ambient track",
         lambda: (recommend("user_sarah", tracks, users, routines)[1]["bpm"] <= 75.0 and
                  recommend("user_sarah", tracks, users, routines)[1]["energy"] <= 0.35 and
                  recommend("user_sarah", tracks, users, routines)[1]["instrumentalness"] >= 0.70)),

        ("Test 2: Cardio workout enforces cadence synchronization (BPM >= 120, Energy >= 0.75)",
         lambda: (recommend("user_alex", tracks, users, routines)[1]["bpm"] >= 120.0 and
                  recommend("user_alex", tracks, users, routines)[1]["energy"] >= 0.75)),

        ("Test 3: Deep focus mode strictly filters out lyrics (instrumentalness >= 0.80)",
         lambda: (recommend("user_marco", tracks, users, routines)[1]["instrumentalness"] >= 0.80 and
                  recommend("user_marco", tracks, users, routines)[1]["loudness_db"] <= -13.0)),

        ("Test 4: Post-workout recovery triggers deceleration and relaxation features",
         lambda: (recommend("user_elena", tracks, users, routines)[1]["bpm"] <= 105.0 and
                  recommend("user_elena", tracks, users, routines)[1]["energy"] <= 0.55)),

        ("Test 5: Sleep induction enforces somnolent regime (BPM <= 64, Energy <= 0.20)",
         lambda: (recommend("user_david", tracks, users, routines)[1]["bpm"] <= 64.0 and
                  recommend("user_david", tracks, users, routines)[1]["energy"] <= 0.20 and
                  recommend("user_david", tracks, users, routines)[1]["acousticness"] >= 0.85)),

        ("Test 6: Active commute provides upbeat affective valence (Valence >= 0.65)",
         lambda: (recommend("user_clara", tracks, users, routines)[1]["bpm"] >= 95.0 and
                  recommend("user_clara", tracks, users, routines)[1]["valence"] >= 0.65)),

        ("Test 7: Iso-Principle entrainment creates downward tempo trajectory",
         lambda: (tracks["iso_bridge_moderato"]["bpm"] >= tracks["tempo_taper_andante"]["bpm"] >= tracks["weightless_ambient"]["bpm"])),

        ("Test 8: Negative Test: Cardio constraint rejects tracks below 120 BPM",
         lambda: not validate_track(tracks["weightless_ambient"], users["user_alex"], routines[users["user_alex"]["target_health_goal"]])),

        ("Test 9: Negative Test: Focus constraint rejects tracks with low instrumentalness",
         lambda: not validate_track(tracks["euphoric_run_anthem"], users["user_marco"], routines[users["user_marco"]["target_health_goal"]])),

        ("Test 10: MCDA scoring sensitivity: Preferred genre receives higher utility",
         lambda: (calculate_mcda_utility(tracks["weightless_ambient"], users["user_sarah"], routines[users["user_sarah"]["target_health_goal"]])[0] > 70.0 and
                  calculate_mcda_utility(tracks["weightless_ambient"], users["user_sarah"], routines[users["user_sarah"]["target_health_goal"]])[4] == 100.0))
    ]

    print("\n========================================================================")
    print(" DSS LOGICAL CORRECTNESS & PHYSIOLOGICAL CONSTRAINT TEST SUITE")
    print("========================================================================")
    passed = 0
    for name, fn in tests:
        print(f"[RUN] {name}... ", end="", flush=True)
        try:
            assert fn()
            print("PASSED")
            passed += 1
        except Exception as e:
            print(f"FAILED ({e})")

    print("\n------------------------------------------------------------------------")
    print(f" Test Execution Summary: {passed}/{len(tests)} Passed ({len(tests) - passed} Failed)")
    print("------------------------------------------------------------------------\n")
    if passed != len(tests):
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
