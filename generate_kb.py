#!/usr/bin/env python3
"""
generate_kb.py
Script di utilità per caricare i dataset JSON (Spotify + Smartwatch)
e generare il file di fatti Prolog 'knowledge_base.pl'.
"""

import json
from pathlib import Path

def sanitize(text: str) -> str:
    """Formatta una stringa come atomo Prolog valido."""
    text = str(text).strip().replace("'", "\\'")
    return f"'{text}'"

def format_list(items) -> str:
    """Formatta una lista Python come lista Prolog."""
    elements = [sanitize(x) for x in items]
    return "[" + ", ".join(elements) + "]"

def main():
    root = Path(__file__).resolve().parent
    tracks_file = root / "data" / "spotify_tracks.json"
    users_file = root / "data" / "smartwatch_biometrics.json"
    kb_file = root / "knowledge_base.pl"

    print("[*] Caricamento dataset JSON...")
    with open(tracks_file, "r", encoding="utf-8") as f:
        tracks = json.load(f)
    with open(users_file, "r", encoding="utf-8") as f:
        users = json.load(f)

    print(f"[*] Generazione fatti Prolog in {kb_file.name}...")
    with open(kb_file, "w", encoding="utf-8") as f:
        f.write("% =========================================================================\n")
        f.write("% KNOWLEDGE BASE PROLOG: Decision Support System (DSS)\n")
        f.write("% Generato automaticamente da generate_kb.py a partire dai dati Spotify e Smartwatch\n")
        f.write("% =========================================================================\n\n")

        f.write("% --- Fatti: brano(Id, Titolo, Artista, Genere, BPM, Valenza, Energia, Strumentale) ---\n")
        f.write(":- dynamic brano/8.\n\n")
        for t in tracks:
            t_id = t["track_id"]
            title = sanitize(t["title"])
            artist = sanitize(t["artist"])
            genre = t["genre"]
            bpm = float(t["bpm"])
            val = float(t["valence"])
            eng = float(t["energy"])
            inst = float(t["instrumentalness"])
            f.write(f"brano({t_id}, {title}, {artist}, {genre}, {bpm:.1f}, {val:.2f}, {eng:.2f}, {inst:.2f}).\n")

        f.write("\n% --- Fatti: utente(Id, Nome, Attivita, BattitoCardiaco, LivelloStress, Obiettivo, GeneriPreferiti) ---\n")
        f.write(":- dynamic utente/7.\n\n")
        for u in users:
            u_id = u["user_id"]
            name = sanitize(u["name"])
            act = u["current_activity"]
            hr = float(u["heart_rate_bpm"])
            stress = float(u["stress_level"])
            goal = u["target_health_goal"]
            genres = format_list(u.get("preferred_genres", []))
            f.write(f"utente({u_id}, {name}, {act}, {hr:.1f}, {stress:.1f}, {goal}, {genres}).\n")

    print(f"[+] Generazione completata con successo: {len(tracks)} brani e {len(users)} profili utente scritti in {kb_file.name}.")

if __name__ == "__main__":
    main()
