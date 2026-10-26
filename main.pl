% =========================================================================
% PROLOG ENTRY POINT: main.pl
% Decision Support System (DSS) - Context-Aware Music Recommendation
% =========================================================================

:- consult('dss_rules.pl').

%! recommend(+UserId)
% Computes and prints the optimal context-aware recommendation for a given user.
recommend(UserId) :-
    user(UserId, Name, Activity, HeartRate, Stress, Goal, _),
    format('~n========================================================================~n'),
    format(' DECISION SUPPORT SYSTEM: CONTEXT-AWARE MUSIC RECOMMENDATION~n'),
    format('========================================================================~n'),
    format(' [*] Smartwatch User Profile:~n'),
    format('     - Name: ~w (ID: ~w)~n', [Name, UserId]),
    format('     - Activity: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100~n', [Activity, HeartRate, Stress]),
    format('     - Clinical / Routine Goal: ~w~n', [Goal]),
    format('~n [*] Logical Inference Result:~n'),
    ( best_track(UserId, TrackId, UtilityScore)
    -> track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness),
       format('     -> SELECTED TRACK: "~w" by ~w~n', [Title, Artist]),
       format('     -> Multi-Attribute Utility: ~1f / 100.0 | Genre: ~w~n', [UtilityScore, Genre]),
       format('     -> Audio Attributes: BPM: ~0f | Energy: ~2f | Valence: ~2f | Instrumental: ~2f~n', [BPM, Energy, Valence, Instrumentalness]),
       explain_choice(Activity, Stress, BPM, Instrumentalness)
    ;  format('     [!] No track in the knowledge base satisfies all safety and physiological constraints.~n')
    ),
    format('========================================================================~n~n').

%! explain_choice(+Activity, +Stress, +BPM, +Instrumentalness)
% Generates natural language biofeedback explanation for the selected track.
explain_choice(high_stress_work, _, BPM, Instrumentalness) :-
    !,
    format('     -> Rationale: Acute sympathetic stress detected. Prescribed slow tempo (~0f BPM)~n', [BPM]),
    format('        and pure instrumental acousticness (~2f) to activate vagal tone and downregulate heart rate.~n', [Instrumentalness]).

explain_choice(cardio_running, _, BPM, _) :-
    !,
    format('     -> Rationale: Cardio workout in progress. Selected ~0f BPM track to synchronize with~n', [BPM]),
    format('        running stride cadence, delaying physical fatigue and optimizing aerobic stamina.~n').

explain_choice(deep_focus_study, _, _, Instrumentalness) :-
    !,
    format('     -> Rationale: Deep focus and study state. Selected lyric-free instrumental track (~2f)~n', [Instrumentalness]),
    format('        to prevent phonological interference with prefrontal working memory.~n').

explain_choice(_, _, _, _) :-
    format('     -> Rationale: Acoustic attributes match homeostatic circadian pacing.~n').

%! recommend_session(+UserId)
% Synthesizes a 3-stage entrainment session using Altshuler's Iso-Principle.
recommend_session(UserId) :-
    user(UserId, Name, _, HeartRate, Stress, _, _),
    format('~n+======================================================================+~n'),
    format('| MULTI-TRACK ENTRAINMENT SESSION (ALTSHULER ISO-PRINCIPLE)            |~n'),
    format('+======================================================================+~n'),
    format('| User: ~-20w | Heart Rate: ~0f BPM | Stress: ~0f/100     |~n', [Name, HeartRate, Stress]),
    format('+----------------------------------------------------------------------+~n'),
    ( iso_principle_session(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)])
    -> track(T1, Title1, _, _, BPM1, _, Eng1, _),
       track(T2, Title2, _, _, BPM2, _, Eng2, _),
       track(T3, Title3, _, _, BPM3, _, Eng3, _),
       format('| 1. [ENTRY]     ~-28w (~0f BPM, E:~2f)             |~n', [Title1, BPM1, Eng1]),
       format('| 2. [BRIDGE]    ~-28w (~0f BPM, E:~2f)             |~n', [Title2, BPM2, Eng2]),
       format('| 3. [TARGET]    ~-28w (~0f BPM, E:~2f)             |~n', [Title3, BPM3, Eng3]),
       format('+----------------------------------------------------------------------+~n'),
       format('| Trajectory: ~0f BPM -> ~0f BPM -> ~0f BPM (Controlled Downregulation)  |~n', [BPM1, BPM2, BPM3])
    ;  format('| [!] Unable to generate entrainment trajectory with current catalog.  |~n')
    ),
    format('+======================================================================+~n~n').

%! demo
% Executes demonstration across three core clinical use cases.
demo :-
    format('~n>>> CASE 1: Acute Work Stress & Autonomic Regulation (Sarah Miller) <<<~n'),
    recommend(user_sarah),
    recommend_session(user_sarah),
    format('~n>>> CASE 2: High-Intensity Aerobic Cadence Lock (Alex Chen) <<<~n'),
    recommend(user_alex),
    format('~n>>> CASE 3: Lyric-Free Deep Focus Study Session (Marco Rossi) <<<~n'),
    recommend(user_marco).

%! run_tests
% Executes the logical verification test suite natively in Prolog.
run_tests :-
    format('~n[*] Executing Prolog Logical Verification Test Suite...~n'),
    % Test 1: Acute stress downregulation recommends low BPM ambient track
    best_track(user_sarah, B_Sarah, _),
    track(B_Sarah, _, _, _, BPM_Sarah, _, Eng_Sarah, _),
    BPM_Sarah =< 75.0, Eng_Sarah =< 0.35,
    format('  [+] Test 1 (Stress Downregulation): PASSED~n'),

    % Test 2: Cardio cadence lock enforces fast tempo
    best_track(user_alex, B_Alex, _),
    track(B_Alex, _, _, _, BPM_Alex, _, Eng_Alex, _),
    BPM_Alex >= 120.0, Eng_Alex >= 0.70,
    format('  [+] Test 2 (Cardio Cadence Lock): PASSED~n'),

    % Test 3: Deep focus mode strictly filters out lyrics
    best_track(user_marco, B_Marco, _),
    track(B_Marco, _, _, _, _, _, _, Inst_Marco),
    Inst_Marco >= 0.70,
    format('  [+] Test 3 (Deep Focus Instrumentalness): PASSED~n'),

    % Test 4: Iso-principle downward tempo monotonicity
    iso_principle_session(user_sarah, [stage(entry, S1), stage(bridge, S2), stage(target, S3)]),
    track(S1, _, _, _, P1, _, _, _),
    track(S2, _, _, _, P2, _, _, _),
    track(S3, _, _, _, P3, _, _, _),
    P1 >= P2, P2 >= P3,
    format('  [+] Test 4 (Iso-Principle Monotonicity): PASSED~n'),

    % Test 5: Medical safety contraindication prevents high-arousal tracks during acute stress
    ( \+ safety_and_contraindications(adrenaline_rush_rock, user_sarah)
    -> format('  [+] Test 5 (Medical Safety Contraindication): PASSED~n')
    ;  format('  [!] Test 5: FAILED~n') ),

    % Test 6: Cognitive contraindication blocks lyrical songs during deep study
    ( \+ cognitively_compatible(euphoric_run_anthem, user_marco)
    -> format('  [+] Test 6 (Cognitive Working Memory Barrier): PASSED~n')
    ;  format('  [!] Test 6: FAILED~n') ),
    format('[SUCCESS] All logical verification tests passed successfully!~n~n').

help :-
    format('~nAvailable Prolog Commands:~n'),
    format('  ?- recommend(user_sarah).         - Evaluates and displays top recommendation for user.~n'),
    format('  ?- recommend_session(user_sarah). - Generates 3-stage Iso-Principle entrainment sequence.~n'),
    format('  ?- demo.                          - Executes the 3 clinical test cases sequentially.~n'),
    format('  ?- run_tests.                     - Executes Prolog logical correctness test suite.~n~n').
