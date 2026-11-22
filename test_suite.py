#!/usr/bin/env python3
"""
test_suite.py
Automated verification suite that executes the real Prolog inference engine
(SWI-Prolog preferred, with automatic fallback to YAP if swipl is not in PATH)
and validates all 10 logical criteria against Prolog's actual outputs.
"""

import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def find_prolog_engine():
    """Locate SWI-Prolog (preferred) or YAP on the local system."""
    swipl = shutil.which("swipl")
    if swipl:
        return "swipl", swipl
    for candidate in (
        Path(r"C:\Program Files\swipl\bin\swipl.exe"),
        Path(r"C:\Program Files (x86)\swipl\bin\swipl.exe"),
        Path.home() / "AppData" / "Local" / "Programs" / "swipl" / "bin" / "swipl.exe",
    ):
        if candidate.exists():
            return "swipl", str(candidate)

    yap = shutil.which("yap")
    if yap:
        return "yap", yap
    for candidate in (
        Path(r"C:\Program Files (x86)\Yap\bin\yap.exe"),
        Path(r"C:\Program Files\Yap\bin\yap.exe"),
    ):
        if candidate.exists():
            return "yap", str(candidate)

    raise FileNotFoundError(
        "No Prolog interpreter found (neither SWI-Prolog 'swipl' nor 'yap'). "
        "Please install SWI-Prolog and ensure 'swipl' is in your PATH."
    )


def run_prolog_goal(goal: str) -> str:
    """Execute a Prolog goal against main.pl and return combined stdout."""
    engine_name, engine_bin = find_prolog_engine()
    if engine_name == "swipl":
        cmd = [engine_bin, "-q", "-s", "main.pl", "-g", f"({goal} -> halt(0) ; halt(1))."]
    else:
        cmd = [engine_bin, "-l", "main.pl", "-g", f"(({goal}) -> true ; format('__PROLOG_FAIL__~n')), halt."]

    proc = subprocess.run(
        cmd,
        cwd=str(ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if engine_name == "swipl" and proc.returncode != 0:
        raise RuntimeError(f"SWI-Prolog exited with code {proc.returncode}:\n{proc.stderr}\n{proc.stdout}")
    if "__PROLOG_FAIL__" in proc.stdout:
        raise RuntimeError(f"Prolog goal failed: {goal}\n{proc.stdout}")
    return proc.stdout


def fetch_prolog_results():
    """Query Prolog py_export_all and parse structured inference outputs."""
    raw = run_prolog_goal("py_export_all")
    best_by_user = {}
    playlist = None
    barriers = {}
    pref_check = None

    for line in raw.splitlines():
        parts = line.strip().split("|")
        if not parts:
            continue
        tag = parts[0]
        if tag == "BEST" and len(parts) == 12:
            best_by_user[parts[1]] = {
                "track_id": parts[2],
                "title": parts[3],
                "artist": parts[4],
                "genre": parts[5],
                "bpm": float(parts[6]),
                "valence": float(parts[7]),
                "energy": float(parts[8]),
                "instrumentalness": float(parts[9]),
                "score": float(parts[10]),
                "confidence": float(parts[11]),
            }
        elif tag == "PLAYLIST" and len(parts) == 14:
            playlist = {
                "user_id": parts[1],
                "stages": [
                    {"stage": "entry", "track_id": parts[2], "title": parts[3], "bpm": float(parts[4]), "energy": float(parts[5])},
                    {"stage": "bridge", "track_id": parts[6], "title": parts[7], "bpm": float(parts[8]), "energy": float(parts[9])},
                    {"stage": "target", "track_id": parts[10], "title": parts[11], "bpm": float(parts[12]), "energy": float(parts[13])},
                ],
            }
        elif tag == "BARRIER" and len(parts) == 3:
            barriers[parts[1]] = parts[2]
        elif tag == "PREF_CHECK" and len(parts) == 4:
            pref_check = {
                "with_pref_clair": float(parts[1]),
                "with_pref_weightless": float(parts[2]),
                "without_pref_clair": float(parts[3]),
            }

    return best_by_user, playlist, barriers, pref_check


def main():
    engine_name, engine_bin = find_prolog_engine()
    print("\n" + "=" * 72)
    print(" PROLOG-DRIVEN VERIFICATION SUITE (SEPARATED KB + INFERENCE ENGINE)")
    print(f" Active Prolog Interpreter: {engine_name.upper()} ({engine_bin})")
    print("=" * 72)

    # 1. Execute native Prolog verification predicate first
    native_out = run_prolog_goal("run_tests")
    assert "10/10 Prolog verification checks PASSED" in native_out

    # 2. Fetch structured inference outputs directly from Prolog
    best, playlist, barriers, pref = fetch_prolog_results()

    tests = [
        (
            "1. Stress Relief Pillar (Sarah) -> Slow calm instrumental track",
            lambda: (
                best["user_sarah"]["bpm"] <= 75.0
                and best["user_sarah"]["energy"] <= 0.35
                and best["user_sarah"]["instrumentalness"] >= 0.70
            ),
        ),
        (
            "2. Intense Workout Pillar (Alex) -> Fast beat & high energy",
            lambda: best["user_alex"]["bpm"] >= 120.0 and best["user_alex"]["energy"] >= 0.70,
        ),
        (
            "3. Study Lyric-Free Pillar (Marco) -> Steady instrumental focus track",
            lambda: (
                best["user_marco"]["instrumentalness"] >= 0.70
                and 70.0 <= best["user_marco"]["bpm"] <= 95.0
                and best["user_marco"]["energy"] <= 0.55
            ),
        ),
        (
            "4. Pre-Sleep Pillar (David) -> Very slow & very low energy",
            lambda: (
                best["user_david"]["bpm"] <= 64.0
                and best["user_david"]["energy"] <= 0.20
                and best["user_david"]["instrumentalness"] >= 0.85
            ),
        ),
        (
            "5. Post-Workout Recovery (Elena) -> Balanced moderate pacing",
            lambda: (
                70.0 <= best["user_elena"]["bpm"] <= 115.0
                and best["user_elena"]["energy"] <= 0.65
                and best["user_elena"]["valence"] >= 0.40
            ),
        ),
        (
            "6. Active Commute Vitality (Clara) -> Positive mood & moderate beat",
            lambda: (
                70.0 <= best["user_clara"]["bpm"] <= 115.0
                and best["user_clara"]["valence"] >= 0.40
            ),
        ),
        (
            "7. Gradual Calm Playlist -> Monotonic BPM descent (Entry -> Bridge -> Target)",
            lambda: (
                playlist is not None
                and playlist["stages"][0]["bpm"] >= playlist["stages"][1]["bpm"] >= playlist["stages"][2]["bpm"]
            ),
        ),
        (
            "8. Safety Barrier (Negative Test) -> Block fast/rock track for stressed Sarah",
            lambda: barriers.get("safety_sarah_rock") == "BLOCKED",
        ),
        (
            "9. Study Barrier (Negative Test) -> Block vocal pop track for Marco",
            lambda: barriers.get("study_marco_vocal") == "BLOCKED",
        ),
        (
            "10. Multi-Criteria Utility & Genre Preference -> Preferred genre scores higher",
            lambda: pref is not None and pref["with_pref_clair"] > pref["without_pref_clair"],
        ),
    ]

    passed = 0
    for name, fn in tests:
        try:
            assert fn()
            print(f" [+] {name}: PASSED")
            passed += 1
        except Exception as exc:
            print(f" [!] {name}: FAILED ({exc})")

    print("-" * 72)
    print(f" Test Execution Summary: {passed}/{len(tests)} Passed via {engine_name.upper()}.")
    print("=" * 72 + "\n")
    if passed != len(tests):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
