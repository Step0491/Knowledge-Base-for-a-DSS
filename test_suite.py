#!/usr/bin/env python3
"""
test_suite.py
Suite di Test di Correttezza Logica per il Decision Support System.
Riflette l'albero di inferenza gerarchico (Meta-regole, Sotto-regole e Vincoli di Sicurezza).
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

# --- SOTTO-REGOLE DI LIVELLO 2 E 3 ---

def stato_simpatico_acuto(u):
    return u["target_health_goal"] == "stress_downregulation" or (u["heart_rate_bpm"] >= 100.0 and u["stress_level"] >= 65.0)

def regime_aerobico_cardio(u):
    return u["target_health_goal"] == "cardio_peak_performance" or (u["current_activity"] == "cardio_running" and u["heart_rate_bpm"] >= 120.0)

def stato_induzione_sonno(u):
    return u["target_health_goal"] == "sleep_induction" or u["current_activity"] == "sleep_preparation"

def brano_azione_sedativa(t):
    return t["bpm"] <= 75.0 and t["energy"] <= 0.35 and t["instrumentalness"] >= 0.70

def brano_azione_ergogenica(t):
    return t["bpm"] >= 120.0 and t["energy"] >= 0.70

def brano_azione_somnolente(t):
    return t["bpm"] <= 64.0 and t["energy"] <= 0.20 and t["instrumentalness"] >= 0.85

def brano_moderata_attivazione(t):
    return 70.0 <= t["bpm"] <= 115.0 and t["energy"] <= 0.65 and t["valence"] >= 0.40

# --- PILASTRI DI LIVELLO 1 ---

def compatibile_fisiologico(t, u):
    if stato_simpatico_acuto(u):
        return brano_azione_sedativa(t)
    if regime_aerobico_cardio(u):
        return brano_azione_ergogenica(t)
    if stato_induzione_sonno(u):
        return brano_azione_somnolente(t)
    return brano_moderata_attivazione(t)

def compatibile_cognitivo(t, u):
    if u["current_activity"] == "deep_focus_study" or u["target_health_goal"] == "deep_focus_flow":
        return t["instrumentalness"] >= 0.70 and (70.0 <= t["bpm"] <= 95.0) and t["energy"] <= 0.55
    return True

def sicurezza_e_controindicazioni(t, u):
    # Controindicazione tachicardica: vietato stimolare utenti in forte stress tachicardico
    if u["heart_rate_bpm"] > 110.0 and u["stress_level"] > 75.0:
        if t["bpm"] > 100.0 or t["energy"] > 0.60:
            return False
    # Controindicazione fatica: vietata alta energia se spossato
    if u["current_activity"] == "high_stress_work" and u["stress_level"] > 80.0:
        if t["energy"] > 0.50:
            return False
    return True

def coerenza_circadiana(t, u):
    if u["current_activity"] == "sleep_preparation" or u["target_health_goal"] == "sleep_induction":
        return t["bpm"] <= 68.0 and t["energy"] <= 0.30
    return True

# --- META-REGOLA DI LIVELLO 0 ---

def brano_raccomandabile(t, u):
    return (compatibile_fisiologico(t, u) and
            compatibile_cognitivo(t, u) and
            sicurezza_e_controindicazioni(t, u) and
            coerenza_circadiana(t, u))

def calcola_utilita(t, u):
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
    score_frequenza = max(20.0, 100.0 - (delta_bpm * 1.5))
    score_genere = 25.0 if t["genre"] in u.get("preferred_genres", []) else 0.0
    score_affettivo = (t["valence"] * 15.0) + (t["instrumentalness"] * 10.0)
    return min(100.0, (score_frequenza * 0.50) + score_genere + score_affettivo)

def raccomanda(user_id, tracks, users):
    user = users[user_id]
    candidati = [t for t in tracks.values() if brano_raccomandabile(t, user)]
    if not candidati:
        return None
    candidati.sort(key=lambda t: calcola_utilita(t, user), reverse=True)
    best = candidati[0]
    return best, calcola_utilita(best, user)

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
    print(" VERIFICA DI CORRETTEZZA LOGICA DEL SISTEMA (ALBERO DI REGOLE GERARCHICO)")
    print("=" * 72)
    tracks, users = load_data()

    tests = [
        ("1. Pilastro Fisiologico Sedativo (Sarah) -> Brano lento, strumentale",
         lambda: (raccomanda("user_sarah", tracks, users)[0]["bpm"] <= 75.0 and
                  raccomanda("user_sarah", tracks, users)[0]["energy"] <= 0.35 and
                  raccomanda("user_sarah", tracks, users)[0]["instrumentalness"] >= 0.70)),

        ("2. Pilastro Fisiologico Ergogenico (Alex) -> Cadenza rapida ed alta energia",
         lambda: (raccomanda("user_alex", tracks, users)[0]["bpm"] >= 120.0 and
                  raccomanda("user_alex", tracks, users)[0]["energy"] >= 0.70)),

        ("3. Pilastro Cognitivo (Marco) -> Protezione loop fonologico (strumentale puro)",
         lambda: (raccomanda("user_marco", tracks, users)[0]["instrumentalness"] >= 0.70 and
                  70.0 <= raccomanda("user_marco", tracks, users)[0]["bpm"] <= 95.0)),

        ("4. Coerenza Circadiana (David) -> Regime ipno-inducente serale (BPM <= 64)",
         lambda: (raccomanda("user_david", tracks, users)[0]["bpm"] <= 64.0 and
                  raccomanda("user_david", tracks, users)[0]["energy"] <= 0.20)),

        ("5. Omeostasi / Recupero (Elena) -> Attivazione moderata e controllata",
         lambda: (raccomanda("user_elena", tracks, users)[0]["bpm"] <= 115.0 and
                  raccomanda("user_elena", tracks, users)[0]["energy"] <= 0.65)),

        ("6. Vitalità Commute (Clara) -> Valenza positiva ed attivazione moderata",
         lambda: (raccomanda("user_clara", tracks, users)[0]["bpm"] >= 70.0 and
                  raccomanda("user_clara", tracks, users)[0]["valence"] >= 0.40)),

        ("7. Entrainment Iso-Principle -> Monotonia decrescente (Entry -> Bridge -> Target)",
         lambda: test_iso_principle(tracks, users) is not None),

        ("8. Controindicazione Sicurezza Medica (Negativo) -> No brani ad alta energia per Sarah",
         lambda: not sicurezza_e_controindicazioni(tracks["adrenaline_rush_rock"], users["user_sarah"])),

        ("9. Controindicazione Cognitiva (Negativo) -> No brani con cantato per Marco in studio",
         lambda: not compatibile_cognitivo(tracks["euphoric_run_anthem"], users["user_marco"])),

        ("10. Scoring Multi-Attributo -> Bonus per genere affine all'utente",
         lambda: calcola_utilita(tracks["weightless_ambient"], users["user_sarah"]) > 70.0)
    ]

    superati = 0
    for nome, test_fn in tests:
        try:
            assert test_fn()
            print(f" [+] {nome}: PASSATO")
            superati += 1
        except Exception as e:
            print(f" [!] {nome}: FALLITO ({e})")

    print("-" * 72)
    print(f" Esito Test: {superati}/{len(tests)} Superati con successo.")
    print("=" * 72 + "\n")

if __name__ == "__main__":
    main()
