#!/usr/bin/env python3
"""
build_docs_pdf.py
Generates the academic project documentation in HTML, ODT (OpenDocument Text,
required for exam submission), and PDF formats.
"""

import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent

HTML_CONTENT = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Knowledge-Based Decision Support System for Context-Aware Music Recommendation</title>
<style>
    @page {
        size: A4;
        margin: 20mm 18mm 20mm 18mm;
        @bottom-right {
            content: counter(page);
            font-size: 9pt;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
            color: #666;
        }
    }
    * { box-sizing: border-box; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        color: #1e293b;
        line-height: 1.55;
        font-size: 10pt;
        background: #ffffff;
        margin: 0;
        padding: 0;
    }
    h1, h2, h3, h4 {
        color: #0f172a;
        font-weight: 700;
        page-break-after: avoid;
    }
    h1 {
        font-size: 18pt;
        line-height: 1.25;
        margin-top: 0;
        margin-bottom: 8px;
        text-align: center;
    }
    .doc-meta {
        text-align: center;
        font-size: 10pt;
        color: #334155;
        margin-top: 6px;
        margin-bottom: 20px;
        padding-bottom: 12px;
        border-bottom: 1px solid #cbd5e1;
        line-height: 1.5;
    }
    .abstract-box {
        background-color: #f8fafc;
        border: 1px solid #e2e8f0;
        border-left: 4px solid #2563eb;
        padding: 12px 16px;
        margin-bottom: 20px;
        font-size: 9.5pt;
    }
    h2 {
        font-size: 13pt;
        margin-top: 20px;
        margin-bottom: 8px;
        padding-bottom: 4px;
        border-bottom: 1px solid #e2e8f0;
    }
    h3 {
        font-size: 11pt;
        margin-top: 14px;
        margin-bottom: 6px;
    }
    p {
        margin-top: 0;
        margin-bottom: 10px;
        text-align: justify;
    }
    ul, ol {
        margin-top: 0;
        margin-bottom: 10px;
        padding-left: 22px;
    }
    li { margin-bottom: 4px; }
    code {
        font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
        font-size: 9pt;
        background-color: #f1f5f9;
        padding: 1px 4px;
        border-radius: 3px;
        color: #0f172a;
    }
    pre {
        background-color: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 4px;
        padding: 10px 12px;
        font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
        font-size: 8.5pt;
        line-height: 1.45;
        margin-top: 6px;
        margin-bottom: 12px;
        page-break-inside: avoid;
        white-space: pre-wrap;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 8px;
        margin-bottom: 14px;
        font-size: 9pt;
        page-break-inside: avoid;
    }
    th, td {
        border: 1px solid #cbd5e1;
        padding: 6px 8px;
        text-align: left;
    }
    th {
        background-color: #f1f5f9;
        font-weight: 600;
        color: #0f172a;
    }
    tr:nth-child(even) td { background-color: #f8fafc; }
    .math-block {
        text-align: center;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        padding: 8px;
        margin: 10px 0;
        font-family: "Cambria Math", "Times New Roman", serif;
        font-size: 10.5pt;
        page-break-inside: avoid;
    }
    .page-break {
        page-break-before: always;
        break-before: page;
    }
    .badge-pass {
        display: inline-block;
        background-color: #dcfce7;
        color: #166534;
        font-weight: 600;
        padding: 1px 6px;
        border-radius: 3px;
        font-size: 8pt;
    }
</style>
</head>
<body>

<h1>Knowledge-Based Decision Support System for Context-Aware Music Recommendation</h1>
<div class="doc-meta">
    <strong>Stefano Colella</strong> &bull; Student ID: 865075<br>
    Course: Fundamentals of AI (9 CFU) &bull; Master's Degree in Computer Science, University of Bari Aldo Moro
</div>

<div class="abstract-box">
    <strong>Abstract:</strong> Traditional music streaming recommenders suggest tracks solely from past listening history, ignoring the listener's real-time physical and mental state. This project implements a Prolog-based Expert System and Decision Support System (DSS) that combines Spotify audio features with smartwatch telemetry (heart rate, stress level, current activity, and personal routine goal). Following classic Expert System engineering principles, the system strictly separates Long-Term Domain Knowledge (facts, genre/activity taxonomy, and declarative production rules) from Short-Term Working Memory and the Meta-Interpreter Inference Engine. It handles graded rule confidence in [0, 1], supports interactive missing-data questions (<code>askable/2</code>) with <code>WHY</code> reasoning traces, generates transparent <code>HOW</code> proof trees for every decision, and prevents unsafe stimulation during high stress or study focus.
</div>

<h2>1. Introduction &amp; Motivation</h2>
<p>
Playing a fast, loud track to a person experiencing high work stress and an elevated heart rate can increase discomfort and agitation. Conversely, playing slow ambient music during an intense running workout breaks running rhythm, while tracks with lyrics interfere with concentration during study. A knowledge-based Decision Support System resolves this context gap by evaluating candidate tracks against explicit, auditable domain rules rather than opaque black-box predictions.
</p>

<h2>2. Expert System Architecture (Separated KB &amp; Inference Engine)</h2>
<p>
In accordance with the course guidelines on Expert Systems, domain knowledge is completely decoupled from reasoning control across four modules:
</p>
<ol>
    <li><strong>ETL &amp; Factual Knowledge Base (<code>generate_kb.py</code> &rarr; <code>knowledge_base.pl</code>):</strong> Compiles <code>data/spotify_tracks.json</code> (30 tracks) and <code>data/smartwatch_biometrics.json</code> (6 user profiles) into normalized Prolog relations: <code>track/8</code>, <code>track_tag/2</code>, and <code>user/7</code>.</li>
    <li><strong>Declarative Domain Rules &amp; Taxonomy (<code>kb_rules.pl</code>):</strong> Long-Term Memory containing the concept hierarchy (<code>is_a/2</code> for music genre families and activity contexts), interactive question definitions (<code>askable/2</code>), and declarative production rules in the form <code>rule(RuleId, Consequent, Condition, Weight, Description)</code> with zero procedural cuts.</li>
    <li><strong>Inference Engine &amp; Explanation Shell (<code>inference_engine.pl</code>):</strong> Domain-independent backward-chaining meta-interpreter (<code>prove/4</code>) managing Short-Term Working Memory (<code>wm_fact/1</code>), certainty combination in [0, 1] (<code>min</code> for conjunctions, <code>max</code> for disjunctions, <code>1 - C</code> for negation, <code>BodyConf * Weight</code> for rules), <code>WHY</code> dialogue explanations, <code>HOW</code> proof tree rendering, multi-criteria ranking, and 3-step gradual calm playlists.</li>
    <li><strong>User Interface &amp; Verification Drivers (<code>main.pl</code>, <code>test_suite.py</code>, <code>demo_walkthrough.ipynb</code>):</strong> Provides an interactive SWI-Prolog menu shell (<code>?- start.</code>) for live consultation and Working Memory editing, alongside a Python/Jupyter test driver that executes queries directly on the Prolog interpreter.</li>
</ol>

<h2>3. Knowledge Representation &amp; Schemas</h2>
<h3>3.1 Track Catalog &amp; Semantic Tags</h3>
<pre>track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness).
track_tag(TrackId, Tag).</pre>
<ul>
    <li><code>BPM</code>: Musical tempo in beats per minute (e.g., 55.0 for sleep streams up to 165.0 for sprint metal).</li>
    <li><code>Valence</code> ([0.0, 1.0]): Musical positivity and cheerfulness.</li>
    <li><code>Energy</code> ([0.0, 1.0]): Perceived loudness, intensity, and pace activity.</li>
    <li><code>Instrumentalness</code> ([0.0, 1.0]): Likelihood that the track contains no vocals (&ge; 0.70 designates lyric-free music).</li>
</ul>

<h3>3.2 Smartwatch Biometrics &amp; Working Memory</h3>
<pre>user(UserId, Name, Activity, HeartRate, StressLevel, Goal, PreferredGenres).</pre>
<p>
At consultation time, a user profile (or custom live telemetry entered by the examiner) is loaded into Short-Term Working Memory as <code>wm_fact/1</code> assertions (<code>user_activity/2</code>, <code>user_heart_rate/2</code>, <code>user_stress/2</code>, <code>user_goal/2</code>, <code>user_preferred_genres/2</code>), allowing runtime inspection (<code>show_wm/0</code>) and modification without altering the Knowledge Base.
</p>

<h3>3.3 Concept Hierarchy (<code>is_a/2</code>)</h3>
<p>
Genres and activities are organized into a taxonomy (e.g., <code>is_a(ambient, calm_instrumental)</code>, <code>is_a(classical, calm_instrumental)</code>, <code>is_a(deep_focus_study, study_context)</code>, <code>is_a(sleep_preparation, pre_sleep_context)</code>). This supports both rule abstraction and semantic genre similarity during ranking.
</p>

<div class="page-break"></div>

<h2>4. Declarative Decision Rules &amp; Explanation Mechanism</h2>
<p>
The top-level goal <code>recommendable(TrackId, UserId)</code> in <code>kb_rules.pl</code> requires four pillars to hold simultaneously:
</p>
<pre>rule(r_recommend,
    recommendable(TrackId, UserId),
    and([
        pace_matches_body(TrackId, UserId),
        study_compatible(TrackId, UserId),
        safe_for_user(TrackId, UserId),
        pre_sleep_compatible(TrackId, UserId)
    ]),
    1.0,
    'Track satisfies body pace, study focus, safety limits, and pre-sleep coherence').</pre>

<ol>
    <li><strong>Body Pace Alignment (<code>pace_matches_body/2</code>):</strong> Selects calm slow instrumental tracks (BPM &le; 75, Energy &le; 0.35, Instrumentalness &ge; 0.70) for <code>need_stress_relief</code>; fast energetic tracks (BPM &ge; 120, Energy &ge; 0.70) for <code>need_workout_boost</code>; ultra-gentle tracks (BPM &le; 64, Energy &le; 0.20, Instrumentalness &ge; 0.85) for <code>need_pre_sleep</code>; and balanced positive tracks (70 &le; BPM &le; 115, Energy &le; 0.65, Valence &ge; 0.40) for normal recovery or commuting.</li>
    <li><strong>Study Focus Protection (<code>study_compatible/2</code>):</strong> During study routines, enforces lyric-free steady pacing (Instrumentalness &ge; 0.70, 70 &le; BPM &le; 95, Energy &le; 0.55) so vocals do not distract concentration.</li>
    <li><strong>Safety Checks (<code>safe_for_user/2</code>):</strong> Blocks fast or intense tracks (BPM &gt; 100 or Energy &gt; 0.60) when heart rate exceeds 110 BPM and stress exceeds 75/100, and avoids high-energy tracks (Energy &gt; 0.50) during severe exhaustion.</li>
    <li><strong>Pre-Sleep Coherence (<code>pre_sleep_compatible/2</code>):</strong> Enforces gentle bedtime ceilings (BPM &le; 68, Energy &le; 0.30) whenever preparing for sleep.</li>
</ol>

<h3>4.1 Interactive WHY / HOW Explanations</h3>
<p>
When running an interactive consultation with incomplete fields (e.g., <code>activity = unknown</code>), the meta-interpreter queries <code>askable/2</code> predicates. Answering <code>why.</code> displays the active rule chain from the current question up to <code>recommendable/2</code>. After a decision is reached, calling <code>explain_last_decision/1</code> (or selecting option 5 in <code>start.</code>) prints the complete <code>HOW</code> proof tree showing every rule fired, confidence value, and Working Memory fact.
</p>

<h3>4.2 Gradual Calm Playlist (3-Step Smooth Transition)</h3>
<p>
For stressed listeners with elevated heart rates, abruptly playing a 60 BPM track can feel unnatural. The predicate <code>gradual_calm_playlist/2</code> searches for an optimal monotonically decreasing 3-stage trajectory (Entry within &plusmn;18 BPM of current HR &rarr; Bridge at 80&ndash;95 BPM &rarr; Target at &le; 68 BPM). For Sarah Miller (HR 114 BPM), the system constructs: <em>Ambient Horizon (105 BPM)</em> &rarr; <em>Neural Flowstate Synapses (92 BPM)</em> &rarr; <em>Delta Wave Binaural Serenade (55 BPM)</em>.
</p>

<h2>5. Multi-Criteria Utility Ranking</h2>
<p>
Compatible candidates are ranked by combining physiological tempo proximity, goal-appropriate mood/instrumentalness, semantic genre preference similarity, and rule confidence:
</p>
<div class="math-block">
    U(t, u) = min(100.0, &nbsp;100.0 &middot; (0.50 &middot; S<sub>bio</sub>(t, u) + 0.30 &middot; S<sub>mood</sub>(t, u) + 0.20 &middot; S<sub>pref</sub>(t, u)) &middot; (0.85 + 0.15 &middot; C<sub>rule</sub>))
</div>
<ul>
    <li><code>S<sub>bio</sub>(t, u) = max(0, 1 - |BPM(t) - TargetBPM(u)| / 60)</code>, with target BPMs: 65 (stress relief), 145 (cardio workout), 80 (study focus / recovery), 55 (pre-sleep), 110 (active commute).</li>
    <li><code>S<sub>mood</sub>(t, u)</code>: <code>0.50&middot;Valence + 0.50&middot;Energy</code> for cardio, <code>0.70&middot;Valence + 0.30&middot;Energy</code> for commute, and <code>0.60&middot;Instrumentalness + 0.40&middot;Valence</code> for calm/study/sleep goals.</li>
    <li><code>S<sub>pref</sub>(t, u)</code>: <code>1.0</code> for an exact preferred genre match, <code>0.5</code> when sharing the same <code>is_a/2</code> family, and <code>0.0</code> otherwise.</li>
</ul>

<div class="page-break"></div>

<h2>6. System Verification &amp; Experimental Results</h2>
<p>
All 10 verification criteria are executed natively inside Prolog (<code>?- run_tests.</code>) and cross-checked by <code>test_suite.py</code> directly querying the Prolog inference engine:
</p>

<table>
    <thead>
        <tr>
            <th>#</th>
            <th>Verification Test</th>
            <th>Input Profile / Conditions</th>
            <th>Observed Prolog Output</th>
            <th>Result</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>1</td>
            <td>Stress Relief Pillar</td>
            <td>Sarah Miller (HR 114, Stress 84, <code>high_stress_work</code>)</td>
            <td><em>Clair de Lune (Debussy)</em> (64 BPM, E:0.18, Score 90.3, Conf 0.94)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>2</td>
            <td>Intense Workout Pillar</td>
            <td>Alex Chen (HR 146, Stress 45, <code>cardio_running</code>)</td>
            <td><em>Subterranean Stamina Loop</em> (140 BPM, E:0.92, Score 88.4, Conf 0.96)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>3</td>
            <td>Study Lyric-Free Pillar</td>
            <td>Marco Rossi (HR 74, Stress 32, <code>deep_focus_study</code>)</td>
            <td><em>Analog Cassette Memory</em> (80 BPM, Inst:0.86, Score 91.1, Conf 0.96)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>4</td>
            <td>Pre-Sleep Pillar</td>
            <td>David Becker (HR 68, Stress 22, <code>sleep_preparation</code>)</td>
            <td><em>Delta Wave Binaural Serenade</em> (55 BPM, E:0.08, Score 89.9, Conf 0.93)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>5</td>
            <td>Post-Workout Recovery</td>
            <td>Elena Rostova (HR 122, Stress 48, <code>post_workout_recovery</code>)</td>
            <td><em>Nordic Dawn Acoustic Solitude</em> (82 BPM, E:0.36, Score 88.5, Conf 0.90)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>6</td>
            <td>Active Commute Vitality</td>
            <td>Clara Dupont (HR 96, Stress 38, <code>active_commute</code>)</td>
            <td><em>Steady Stride Metropolitan</em> (108 BPM, Val:0.68, Score 86.9, Conf 0.90)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>7</td>
            <td>Gradual Calm Playlist</td>
            <td>Sarah Miller (3-step calming sequence)</td>
            <td>105 BPM &rarr; 92 BPM &rarr; 55 BPM (monotonic descent)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>8</td>
            <td>Safety Barrier (Negative)</td>
            <td>Sarah Miller evaluated with <code>adrenaline_rush_rock</code> (150 BPM)</td>
            <td><code>safe_for_user</code> fails (categorical rejection)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>9</td>
            <td>Study Barrier (Negative)</td>
            <td>Marco Rossi evaluated with <code>euphoric_run_anthem</code> (Inst 0.12)</td>
            <td><code>study_compatible</code> fails (categorical rejection)</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
        <tr>
            <td>10</td>
            <td>Preference &amp; Proof Tree</td>
            <td>Sarah Miller with vs. without preferred genre list</td>
            <td>Utility 90.3 &gt; 70.5 + non-empty Proof Tree verified</td>
            <td><span class="badge-pass">PASSED</span></td>
        </tr>
    </tbody>
</table>

<h2>7. Examiner Usage Guide</h2>
<p>To test the Expert System interactively in SWI-Prolog:</p>
<pre>swipl -s main.pl
?- start.</pre>
<p>
From the interactive menu, the examiner can select profiles (option 1), enter live custom smartwatch telemetry with <code>unknown.</code> fields (option 2), run interactive consultations supporting <code>why.</code> (option 4), inspect the deduced <code>HOW</code> proof tree (option 5), view Working Memory (option 8) and KB rules (option 9), or execute the full 10-point Prolog test suite (option 10).
</p>

<h2>8. Conclusion</h2>
<p>
Separating domain facts, declarative rules, Working Memory, and the backward-chaining meta-interpreter transforms the music recommender into a true transparent Expert System. Every decision carries a deterministic safety guarantee, a graded confidence score, and an inspectable logical proof tree, fulfilling both state-of-the-art symbolic AI standards and the course examination requirements.
</p>

</body>
</html>
"""


def find_soffice():
    for cand in (
        r"C:\Program Files\LibreOffice\program\soffice.exe",
        r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
    ):
        if os.path.exists(cand):
            return cand
    return None


def find_browser():
    for cand in (
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        "msedge",
        "chrome",
    ):
        if os.path.exists(cand) or subprocess.run(
            ["where", cand], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, shell=True
        ).returncode == 0:
            return cand
    return None


def generate_docs():
    html_path = ROOT / "documentation.html"
    odt_path = ROOT / "DSS_Project_Documentation.odt"
    pdf_path = ROOT / "DSS_Project_Documentation.pdf"

    print(f"[*] Writing academic report HTML to {html_path.name}...")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(HTML_CONTENT)

    soffice = find_soffice()
    if soffice:
        print(f"[*] Converting HTML to ODT via LibreOffice ({soffice})...")
        res_odt = subprocess.run(
            [soffice, "--headless", "--convert-to", "odt", "--outdir", str(ROOT), str(html_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        generated_odt = ROOT / "documentation.odt"
        if res_odt.returncode == 0 and generated_odt.exists():
            if odt_path.exists():
                odt_path.unlink()
            generated_odt.rename(odt_path)
            print(f"[SUCCESS] ODT source created: {odt_path.name} ({odt_path.stat().st_size / 1024:.1f} KB)")
        else:
            print(f"[!] LibreOffice ODT conversion failed: {res_odt.stderr}")

        print("[*] Converting ODT to PDF via LibreOffice...")
        res_pdf = subprocess.run(
            [soffice, "--headless", "--convert-to", "pdf", "--outdir", str(ROOT), str(odt_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if res_pdf.returncode == 0 and pdf_path.exists():
            print(f"[SUCCESS] PDF created from ODT: {pdf_path.name} ({pdf_path.stat().st_size / 1024:.1f} KB)")
            return

    browser_bin = find_browser()
    if not browser_bin:
        print("[!] Neither LibreOffice nor headless browser found. HTML report written.")
        return

    print(f"[*] Rendering PDF via headless browser: {browser_bin}...")
    res = subprocess.run(
        [
            browser_bin,
            "--headless=new",
            "--disable-gpu",
            "--no-sandbox",
            "--no-pdf-header-footer",
            f"--print-to-pdf={pdf_path}",
            str(html_path),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if res.returncode == 0 and pdf_path.exists():
        print(f"[SUCCESS] PDF compiled: {pdf_path.name} ({pdf_path.stat().st_size / 1024:.1f} KB)")
    else:
        print(f"[!] Browser render exited with code {res.returncode}: {res.stderr}")


if __name__ == "__main__":
    generate_docs()
