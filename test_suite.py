#!/usr/bin/env python3
"""
test_suite.py
Automated logical verification test harness for the Decision Support System.
Validates the hierarchical AND-OR inference tree (meta-rules, sub-rules, and safety barriers).
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def load_data():
    with open(ROOT / "data" / "spotify_tracks.json", "r", encoding="utf-8") as f:
        tracks = {t["track_id"]: t for t in json.load(f)}
    with open(ROOT / "data" / "smartwatch_biometrics.json", "r", encoding="utf-8") as f:
        users = {u["user_id"]: u for u in json.load(f)}
    return tracks, users

# --- LEVEL 2 & 3 SUB-RULES ---

def acute_sympathetic_state(u):
    return u["target_health_goal"] == "stress_downregulation" or (u["heart_rate_bpm"] >= 100.0 and u["stress_level"] >= 65.0)

def cardio_aerobic_regime(u):
    return u["target_health_goal"] == "cardio_peak_performance" or (u["current_activity"] == "cardio_running" and u["heart_rate_bpm"] >= 120.0)

def sleep_induction_state(u):
    return u["target_health_goal"] == "sleep_induction" or u["current_activity"] == "sleep_preparation"

def sedative_track(t):
    return t["bpm"] <= 75.0 and t["energy"] <= 0.35 and t["instrumentalness"] >= 0.70

def ergogenic_track(t):
    return t["bpm"] >= 120.0 and t["energy"] >= 0.70

def somnolent_track(t):
    return t["bpm"] <= 64.0 and t["energy"] <= 0.20 and t["instrumentalness"] >= 0.85

def moderate_activation_track(t):
    return 70.0 <= t["bpm"] <= 115.0 and t["energy"] <= 0.65 and t["valence"] >= 0.40

# --- LEVEL 1 EVALUATION PILLARS ---

def physiologically_compatible(t, u):
    if acute_sympathetic_state(u):
        return sedative_track(t)
    if cardio_aerobic_regime(u):
        return ergogenic_track(t)
    if sleep_induction_state(u):
        return somnolent_track(t)
    return moderate_activation_track(t)

def cognitively_compatible(t, u):
    if u["current_activity"] == "deep_focus_study" or u["target_health_goal"] == "deep_focus_flow":
        return t["instrumentalness"] >= 0.70 and (70.0 <= t["bpm"] <= 95.0) and t["energy"] <= 0.55
    return True

def safety_and_contraindications(t, u):
    # Tachycardia barrier: prohibit high-tempo/high-energy stimulation during acute stress tachycardia
    if u["heart_rate_bpm"] > 110.0 and u["stress_level"] > 75.0:
        if t["bpm"] > 100.0 or t["energy"] > 0.60:
            return False
    # Fatigue exhaustion barrier
    if u["current_activity"] == "high_stress_work" and u["stress_level"] > 80.0:
        if t["energy"] > 0.50:
            return False
    return True

def circadian_coherent(t, u):
    if u["current_activity"] == "sleep_preparation" or u["target_health_goal"] == "sleep_induction":
        return t["bpm"] <= 68.0 and t["energy"] <= 0.30
    return True

# --- LEVEL 0 META-RULE ---

def recommendable_track(t, u):
    return (physiologically_compatible(t, u) and
            cognitively_compatible(t, u) and
            safety_and_contraindications(t, u) and
            circadian_coherent(t, u))

def calculate_utility(t, u):
    target_bpm_map = {
        "stress_downregulation": 65.0,
        "cardio_peak_performance": 145.0,
        "deep_focus_flow": 80.0,
        "sleep_induction": 55.0,
        "post_workout_recovery": 80.0,
        "active_commute_energizer": 110.0
    }
    target_bpm = target_bpm_map.get(u["target_health_goal"], 80.0)
    delta_bpm = abs(t["bpm"] - target_bpm)
    frequency_score = max(20.0, 100.0 - (delta_bpm * 1.5))
    genre_bonus = 25.0 if t["genre"] in u.get("preferred_genres", []) else 0.0
    affective_score = (t["valence"] * 15.0) + (t["instrumentalness"] * 10.0)
    return min(100.0, (frequency_score * 0.50) + genre_bonus + affective_score)

def recommend(user_id, tracks, users):
    user = users[user_id]
    candidates = [t for t in tracks.values() if recommendable_track(t, user)]
    if not candidates:
        return None
    candidates.sort(key=lambda t: calculate_utility(t, user), reverse=True)
    best = candidates[0]
    return best, calculate_utility(best, user)

def test_iso_principle(tracks, users):
    user = users["user_sarah"]
    entry = [t for t in tracks.values() if abs(t["bpm"] - user["heart_rate_bpm"]) <= 18.0]
    bridge = [t for t in tracks.values() if 80.0 <= t["bpm"] <= 95.0 and t["energy"] <= 0.50]
    target = [t for t in tracks.values() if t["bpm"] <= 68.0 and t["energy"] <= 0.25]
    assert entry and bridge and target
    t1 = entry[0]
    t2 = bridge[0]
    t3 = target[0]
    assert t1["bpm"] >= t2["bpm"] >= t3["bpm"]
    return t1, t2, t3

def main():
    print("\n" + "=" * 72)
    print(" LOGICAL VERIFICATION TEST SUITE (HIERARCHICAL AND-OR GOAL TREE)")
    print("=" * 72)
    tracks, users = load_data()

    tests = [
        ("1. Physiological Sedative Pillar (Sarah) -> Slow, instrumental ambient track",
         lambda: (recommend("user_sarah", tracks, users)[0]["bpm"] <= 75.0 and
                  recommend("user_sarah", tracks, users)[0]["energy"] <= 0.35 and
                  recommend("user_sarah", tracks, users)[0]["instrumentalness"] >= 0.70)),

        ("2. Physiological Ergogenic Pillar (Alex) -> High cadence and maximal energy",
         lambda: (recommend("user_alex", tracks, users)[0]["bpm"] >= 120.0 and
                  recommend("user_alex", tracks, users)[0]["energy"] >= 0.70)),

        ("3. Cognitive Protection Pillar (Marco) -> Zero vocal intrusion (instrumental)",
         lambda: (recommend("user_marco", tracks, users)[0]["instrumentalness"] >= 0.70 and
                  70.0 <= recommend("user_marco", tracks, users)[0]["bpm"] <= 95.0)),

        ("4. Circadian Sleep Coherence (David) -> Somnolent acoustic regime (BPM <= 64)",
         lambda: (recommend("user_david", tracks, users)[0]["bpm"] <= 64.0 and
                  recommend("user_david", tracks, users)[0]["energy"] <= 0.20)),

        ("5. Post-Workout Homeostatic Recovery (Elena) -> Moderate controlled activation",
         lambda: (recommend("user_elena", tracks, users)[0]["bpm"] <= 115.0 and
                  recommend("user_elena", tracks, users)[0]["energy"] <= 0.65)),

        ("6. Active Commute Vitality (Clara) -> Positive valence and moderate pacing",
         lambda: (recommend("user_clara", tracks, users)[0]["bpm"] >= 70.0 and
                  recommend("user_clara", tracks, users)[0]["valence"] >= 0.40)),

        ("7. Iso-Principle Entrainment -> Downward monotonicity (Entry -> Bridge -> Target)",
         lambda: test_iso_principle(tracks, users) is not None),

        ("8. Medical Safety Barrier (Negative Test) -> Prohibit high-energy track for Sarah",
         lambda: not safety_and_contraindications(tracks["adrenaline_rush_rock"], users["user_sarah"])),

        ("9. Cognitive Barrier (Negative Test) -> Prohibit lyrical track for Marco in study",
         lambda: not cognitively_compatible(tracks["euphoric_run_anthem"], users["user_marco"])),

        ("10. Multi-Attribute Scoring -> Affirmative bonus for user genre affinity",
         lambda: calculate_utility(tracks["weightless_ambient"], users["user_sarah"]) > 70.0)
    ]

    passed = 0
    for name, test_fn in tests:
        try:
            assert test_fn()
            print(f" [+] {name}: PASSED")
            passed += 1
        except Exception as e:
            print(f" [!] {name}: FAILED ({e})")

    print("-" * 72)
    print(f" Test Execution Summary: {passed}/{len(tests)} Passed successfully.")
    print("=" * 72 + "\n")

if __name__ == "__main__":
    main()
