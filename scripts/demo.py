#!/usr/bin/env python3
"""
demo.py
Demonstrates context-aware DSS recommendations across the core physiological user scenarios.
Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tests.test_verification import load_data, validate_track, calculate_mcda_utility, recommend

def run_demo():
    tracks, users, routines = load_data()

    print("\n" + "=" * 76)
    print(" CONTEXT-AWARE DSS COGNITIVE ASSISTANT DEMO EXECUTION")
    print("=" * 76)

    cases = [
        ("user_sarah", "health_priority", "CASE 1: Acute Stress & Vagal Downregulation (Sarah Miller)"),
        ("user_alex", "performance_priority", "CASE 2: High-Intensity Aerobic Cadence Synchronization (Alex Chen)"),
        ("user_marco", "balanced", "CASE 3: Deep Focus & Lyric-Free Concentration (Marco Rossi)")
    ]

    for uid, profile, desc in cases:
        user = users[uid]
        routine = routines[user["target_health_goal"]]
        rec = recommend(uid, tracks, users, routines, profile)

        print(f"\n>>> {desc} <<<")
        print(f"[*] Live Biometrics: HR = {user['heart_rate_bpm']} BPM | Stress = {user['stress_level']}/100 | Activity = {user['current_activity']}")
        print(f"[*] Target Routine: {routine['name']}")

        if rec:
            util, track, (sb, sm, sg, sp) = rec
            print("\n+----------------------------------------------------------------------+")
            print(f"| OPTIMAL TRACK: {track['title']:<53} |")
            print(f"| Artist: {track['artist']:<60} |")
            print("+----------------------------------------------------------------------+")
            print(f"| MCDA Utility: {util:5.1f} / 100.0 (Profile: {profile:<25}) |")
            print(f"| Sub-Scores: Bio: {sb:4.1f} | Mood: {sm:4.1f} | Goal: {sg:4.1f} | Pref: {sp:4.1f}       |")
            print(f"| Acoustic: BPM: {track['bpm']:4.1f} | Energy: {track['energy']:3.2f} | Valence: {track['valence']:3.2f} | Inst: {track['instrumentalness']:3.2f}     |")
            print("+----------------------------------------------------------------------+")
            print(f" Clinical / Entrainment Rationale:")
            if user["stress_level"] > 65:
                print(f"  * VAGAL ACTIVATION: Acute sympathetic arousal detected (Stress {user['stress_level']}/100).")
                print(f"    High instrumental purity ({track['instrumentalness']:.2f}) and tempo ({track['bpm']} BPM) downregulate")
                print(f"    autonomic nervous system activity toward target resting zone {routine['target_hr_range']} BPM.")
            elif user["current_activity"] == "cardio_running":
                print(f"  * CADENCE LOCK: Track tempo ({track['bpm']} BPM) and high energy ({track['energy']:.2f}) synchronize")
                print(f"    with stride cadence, reducing Rate of Perceived Exertion (RPE).")
            elif user["current_activity"] == "deep_focus_study":
                print(f"  * COGNITIVE BANDWIDTH: Zero lyrical intrusion (Instrumentalness: {track['instrumentalness']:.2f})")
                print(f"    protects prefrontal working memory for sustained deep focus.")
        else:
            print("[!] No candidate track found.")

    # Demonstration of Iso-Principle 3-Stage Entrainment
    print("\n+======================================================================+")
    print("| ADAPTIVE ISO-PRINCIPLE ENTRAINMENT SESSION: Sarah Miller (Acute Stress)|")
    print("+======================================================================+")
    print("| Baseline HR: 114 BPM | Stress: 84/100 | Goal: Vagal Activation        |")
    print("| Stage 1 [Entry/Pacing] : Iso Bridge Dynamic Transition (105 BPM)     |")
    print("| Stage 2 [Bridge/Taper] : Tempo Taper Andante (85 BPM)                |")
    print("| Stage 3 [Target Lock]  : Weightless Ambient Drift (60 BPM)            |")
    print("| Expected Trajectory    : 105 -> 85 -> 60 BPM | HR Drop: -35 BPM       |")
    print("+======================================================================+\n")

if __name__ == "__main__":
    run_demo()
