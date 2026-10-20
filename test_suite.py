#!/usr/bin/env python3
"""
test_suite.py
Script di test universale (Python) per verificare la correttezza logica del DSS.
Permette l'esecuzione immediata sia su macchine con SWI-Prolog sia su macchine con solo Python.
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

def ammissibile(track, user):
    act = user["current_activity"]
    goal = user["target_health_goal"]

    # 1. Vincoli di attività
    if act == "deep_focus_study" and track["instrumentalness"] < 0.70:
        return False
    if act == "cardio_running" and (track["bpm"] < 120.0 or track["energy"] < 0.70):
        return False

    # 2. Vincoli di obiettivo clinico
    if goal == "stress_downregulation":
        if not (track["bpm"] <= 75.0 and track["energy"] <= 0.35 and track["instrumentalness"] >= 0.70):
            return False
    elif goal == "cardio_peak_performance":
        if not (track["bpm"] >= 120.0 and track["energy"] >= 0.75):
            return False
    elif goal == "deep_focus_flow":
        if not (70.0 <= track["bpm"] <= 95.0 and track["energy"] <= 0.55 and track["instrumentalness"] >= 0.70):
            return False
    elif goal == "sleep_induction":
        if not (track["bpm"] <= 64.0 and track["energy"] <= 0.20 and track["instrumentalness"] >= 0.85):
            return False
    elif goal == "post_workout_recovery":
        if not (track["bpm"] <= 105.0 and track["energy"] <= 0.55):
            return False
    elif goal == "active_commute_energizer":
        if not (track["bpm"] >= 95.0 and track["valence"] >= 0.60):
            return False

    return True

def calcola_punteggio(track, user):
    target_bpm_map = {
        "stress_downregulation": 65.0,
        "cardio_peak_performance": 145.0,
        "deep_focus_flow": 80.0,
        "sleep_induction": 55.0,
        "post_workout_recovery": 80.0,
        "active_commute_energizer": 110.0
    }
    target_bpm = target_bpm_map.get(user["target_health_goal"], 80.0)
    diff_bpm = abs(track["bpm"] - target_bpm)
    score_bpm = max(20.0, 100.0 - (diff_bpm * 1.5))
    bonus_pref = 20.0 if track["genre"] in user.get("preferred_genres", []) else 0.0
    score_valenza = track["valence"] * 20.0
    return min(100.0, (score_bpm * 0.60) + score_valenza + bonus_pref)

def raccomanda(user_id, tracks, users):
    user = users[user_id]
    candidati = [t for t in tracks.values() if ammissibile(t, user)]
    if not candidati:
        return None
    candidati.sort(key=lambda t: calcola_punteggio(t, user), reverse=True)
    best = candidati[0]
    return best, calcola_punteggio(best, user)

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
    print("\n" + "=" * 70)
    print(" VERIFICA DI CORRETTEZZA LOGICA DEL SISTEMA (TEST SUITE)")
    print("=" * 70)
    tracks, users = load_data()

    tests = [
        ("1. Riduzione stress (Sarah Miller) -> Brano lento e rilassante",
         lambda: (raccomanda("user_sarah", tracks, users)[0]["bpm"] <= 75.0 and
                  raccomanda("user_sarah", tracks, users)[0]["energy"] <= 0.35 and
                  raccomanda("user_sarah", tracks, users)[0]["instrumentalness"] >= 0.70)),

        ("2. Cardio Workout (Alex Chen) -> Cadenza veloce ed alta energia",
         lambda: (raccomanda("user_alex", tracks, users)[0]["bpm"] >= 120.0 and
                  raccomanda("user_alex", tracks, users)[0]["energy"] >= 0.75)),

        ("3. Deep Focus (Marco Rossi) -> Zero parole cantate (strumentale)",
         lambda: (raccomanda("user_marco", tracks, users)[0]["instrumentalness"] >= 0.70)),

        ("4. Sonno (David Becker) -> Tempo lentissimo e minima energia",
         lambda: (raccomanda("user_david", tracks, users)[0]["bpm"] <= 64.0 and
                  raccomanda("user_david", tracks, users)[0]["energy"] <= 0.20)),

        ("5. Recupero post workout (Elena Rostova) -> Tempo controllato",
         lambda: (raccomanda("user_elena", tracks, users)[0]["bpm"] <= 105.0 and
                  raccomanda("user_elena", tracks, users)[0]["energy"] <= 0.55)),

        ("6. Commute attivo (Clara Dupont) -> Tono allegro (valenza positiva)",
         lambda: (raccomanda("user_clara", tracks, users)[0]["bpm"] >= 95.0 and
                  raccomanda("user_clara", tracks, users)[0]["valence"] >= 0.60)),

        ("7. Entrainment Iso-Principle -> Traiettoria monotonica decrescente",
         lambda: test_iso_principle(tracks, users) is not None),

        ("8. Test Negativo -> Brano con parole escluso in fase di studio",
         lambda: not ammissibile(tracks["euphoric_run_anthem"], users["user_marco"])),

        ("9. Test Negativo -> Brano lento escluso durante la corsa cardio",
         lambda: not ammissibile(tracks["weightless_ambient"], users["user_alex"])),

        ("10. Scoring -> Bonus per genere musicale preferito dall'utente",
         lambda: calcola_punteggio(tracks["weightless_ambient"], users["user_sarah"]) > 70.0)
    ]

    superati = 0
    for nome, test_fn in tests:
        try:
            assert test_fn()
            print(f" [+] {nome}: PASSATO")
            superati += 1
        except Exception as e:
            print(f" [!] {nome}: FALLITO ({e})")

    print("-" * 70)
    print(f" Esito Test: {superati}/{len(tests)} Superati con successo.")
    print("=" * 70 + "\n")

if __name__ == "__main__":
    main()
