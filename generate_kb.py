#!/usr/bin/env python3
"""
Convert JSON datasets into Prolog facts in knowledge_base.pl.
"""

import json
from pathlib import Path

def sanitize(text: str) -> str:
    text = str(text).strip().replace("'", "\\'")
    return f"'{text}'"

def format_list(items) -> str:
    elements = [sanitize(x) for x in items]
    return "[" + ", ".join(elements) + "]"

def main():
    root = Path(__file__).resolve().parent
    tracks_file = root / "data" / "spotify_tracks.json"
    users_file = root / "data" / "smartwatch_biometrics.json"
    kb_file = root / "knowledge_base.pl"

    with open(tracks_file, "r", encoding="utf-8") as f:
        tracks = json.load(f)
    with open(users_file, "r", encoding="utf-8") as f:
        users = json.load(f)

    with open(kb_file, "w", encoding="utf-8") as f:
        f.write("% Knowledge Base for DSS\n")
        f.write("% Generated from data/spotify_tracks.json and data/smartwatch_biometrics.json\n\n")
        f.write(":- dynamic track/8.\n")
        f.write(":- dynamic user/7.\n\n")

        f.write("% track(Id, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness)\n")
        for t in tracks:
            t_id = t["track_id"]
            title = sanitize(t["title"])
            artist = sanitize(t["artist"])
            genre = t["genre"]
            bpm = float(t["bpm"])
            val = float(t["valence"])
            eng = float(t["energy"])
            inst = float(t["instrumentalness"])
            f.write(f"track({t_id}, {title}, {artist}, {genre}, {bpm:.1f}, {val:.2f}, {eng:.2f}, {inst:.2f}).\n")

        f.write("\n% user(Id, Name, Activity, HeartRate, StressLevel, TargetGoal, PreferredGenres)\n")
        for u in users:
            u_id = u["user_id"]
            name = sanitize(u["name"])
            act = u["current_activity"]
            hr = float(u["heart_rate_bpm"])
            stress = float(u["stress_level"])
            goal = u["target_health_goal"]
            genres = format_list(u.get("preferred_genres", []))
            f.write(f"user({u_id}, {name}, {act}, {hr:.1f}, {stress:.1f}, {goal}, {genres}).\n")

    print(f"Generated {kb_file.name} ({len(tracks)} tracks, {len(users)} users).")

if __name__ == "__main__":
    main()
