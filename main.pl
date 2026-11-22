% =========================================================================
% PROLOG ENTRY POINT & EXPERT SYSTEM SHELL: main.pl
% Knowledge-Based Decision Support System (Fundamentals of AI - 9 CFU)
% Separates Facts (knowledge_base.pl), Rules (kb_rules.pl), and
% Meta-Interpreter (inference_engine.pl).
% =========================================================================

:- consult('inference_engine.pl').

% -------------------------------------------------------------------------
% 1. INTERACTIVE EXPERT SYSTEM SHELL FOR EXAM DEMO (?- start.)
% -------------------------------------------------------------------------

:- dynamic current_user/1.
current_user(user_sarah).

%! start
% Launches the interactive Expert System shell for live consultation.
start :-
    load_user_to_wm(user_sarah),
    retractall(current_user(_)),
    assertz(current_user(user_sarah)),
    shell_loop.

shell_loop :-
    current_user(U),
    format('~n========================================================================~n'),
    format(' EXPERT SYSTEM SHELL: CONTEXT-AWARE MUSIC DSS (Active User: ~w)~n', [U]),
    format('========================================================================~n'),
    format('  1. Select smartwatch user profile (sarah/alex/marco/elena/david/clara)~n'),
    format('  2. Enter custom live smartwatch readings (supports "unknown" fields)~n'),
    format('  3. Recommend best track (automatic inference from Working Memory)~n'),
    format('  4. Interactive consultation (asks missing info; supports yes/no/why)~n'),
    format('  5. Explain HOW the last recommendation was deduced (Proof Tree)~n'),
    format('  6. Show top-5 alternative tracks for active user~n'),
    format('  7. Generate 3-step Gradual Calm Playlist (entry -> bridge -> target)~n'),
    format('  8. Inspect Working Memory (Short-Term Case Facts)~n'),
    format('  9. Inspect Knowledge Base Rules (Long-Term Domain Rules)~n'),
    format(' 10. Run 10-point Prolog Logical Verification Suite~n'),
    format('  0. Exit shell~n'),
    format('------------------------------------------------------------------------~n'),
    format('Choose option (e.g., 3.): '),
    read(Choice),
    handle_menu(Choice).

handle_menu(0) :-
    !,
    format('Exiting Expert System shell.~n').

handle_menu(1) :-
    !,
    format('Available profiles:~n'),
    for_each(user(Id, Name, Act, HR, Stress, Goal, _),
             format('  - ~w : ~w (Activity: ~w, HR: ~0f, Stress: ~0f, Goal: ~w)~n',
                    [Id, Name, Act, HR, Stress, Goal])),
    format('Enter profile atom (e.g., user_sarah.): '),
    read(UserId),
    ( user(UserId, _, _, _, _, _, _)
    -> load_user_to_wm(UserId),
       retractall(current_user(_)),
       assertz(current_user(UserId)),
       format('[+] Loaded ~w into Working Memory.~n', [UserId])
    ;  format('[!] Unknown profile: ~w~n', [UserId])
    ),
    shell_loop.

handle_menu(2) :-
    !,
    format('Enter custom readings as Prolog terms ending with a dot (.).~n'),
    format('Heart Rate BPM (number, e.g., 112.): '), read(HRNum),
    format('Stress Level 0-100 (number, e.g., 78.): '), read(StressNum),
    format('Activity (e.g., high_stress_work. / deep_focus_study. / cardio_running. / sleep_preparation. / unknown.): '), read(Act),
    format('Goal (e.g., stress_downregulation. / deep_focus_flow. / cardio_peak_performance. / sleep_induction. / unknown.): '), read(Goal),
    format('Preferred genre list (e.g., [ambient, classical].): '), read(Genres),
    HR is float(HRNum),
    Stress is float(StressNum),
    set_custom_user_wm(custom_user, 'Live Smartwatch User', Act, HR, Stress, Goal, Genres),
    retractall(current_user(_)),
    assertz(current_user(custom_user)),
    format('[+] Custom telemetry loaded into Working Memory as custom_user.~n'),
    shell_loop.

handle_menu(3) :-
    !,
    set_interactive(false),
    current_user(U),
    recommend(U),
    shell_loop.

handle_menu(4) :-
    !,
    set_interactive(true),
    current_user(U),
    retractall(wm_fact(user_answer(_, _))),
    recommend(U),
    set_interactive(false),
    shell_loop.

handle_menu(5) :-
    !,
    current_user(U),
    explain_last_decision(U),
    shell_loop.

handle_menu(6) :-
    !,
    set_interactive(false),
    current_user(U),
    show_top_alternatives(U, 5),
    shell_loop.

handle_menu(7) :-
    !,
    current_user(U),
    recommend_session(U),
    shell_loop.

handle_menu(8) :-
    !,
    show_wm,
    shell_loop.

handle_menu(9) :-
    !,
    show_kb_rules,
    shell_loop.

handle_menu(10) :-
    !,
    run_tests,
    shell_loop.

handle_menu(Other) :-
    format('[!] Invalid option: ~w. Please enter a number followed by a dot (e.g. 3.).~n', [Other]),
    shell_loop.

% -------------------------------------------------------------------------
% 2. RECOMMENDATION, ALTERNATIVES & EXPLANATION COMMANDS
% -------------------------------------------------------------------------

%! recommend(+UserId)
% Evaluates the best track for UserId using the separated inference engine.
recommend(UserId) :-
    ( wm_fact(user_name(UserId, Name))
    -> wm_fact(user_activity(UserId, Activity)),
       wm_fact(user_heart_rate(UserId, HeartRate)),
       wm_fact(user_stress(UserId, Stress)),
       wm_fact(user_goal(UserId, Goal))
    ;  load_user_to_wm(UserId),
       wm_fact(user_name(UserId, Name)),
       wm_fact(user_activity(UserId, Activity)),
       wm_fact(user_heart_rate(UserId, HeartRate)),
       wm_fact(user_stress(UserId, Stress)),
       wm_fact(user_goal(UserId, Goal))
    ),
    format('~n========================================================================~n'),
    format(' DECISION SUPPORT SYSTEM: CONTEXT-AWARE MUSIC RECOMMENDATION~n'),
    format('========================================================================~n'),
    format(' [*] Smartwatch Profile (Working Memory):~n'),
    format('     - Name: ~w (ID: ~w)~n', [Name, UserId]),
    format('     - Activity: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100~n', [Activity, HeartRate, Stress]),
    format('     - Routine Goal: ~w~n', [Goal]),
    format('~n [*] Inference Engine Result:~n'),
    ( best_track_with_proof(UserId, TrackId, UtilityScore, Conf, _Proof)
    -> track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness),
       format('     -> SELECTED TRACK: "~w" by ~w~n', [Title, Artist]),
       format('     -> Multi-Criteria Utility: ~1f / 100.0 | Rule Confidence: ~2f | Genre: ~w~n',
              [UtilityScore, Conf, Genre]),
       format('     -> Audio Profile: BPM ~0f | Energy ~2f | Valence ~2f | Instrumental ~2f~n',
              [BPM, Energy, Valence, Instrumentalness]),
       format('     -> Tip: call explain_last_decision(~w). to inspect the full HOW proof tree.~n', [UserId])
    ;  format('     [!] No track satisfies all physiological, study, safety, and sleep rules.~n')
    ),
    format('========================================================================~n~n').

%! recommend_with_how(+UserId)
% Prints recommendation immediately followed by the full Proof Tree (HOW).
recommend_with_how(UserId) :-
    recommend(UserId),
    explain_last_decision(UserId).

%! show_top_alternatives(+UserId, +Limit)
show_top_alternatives(UserId, Limit) :-
    ( wm_fact(user_goal(UserId, _)) -> true ; load_user_to_wm(UserId) ),
    format('~n--- TOP ~w COMPATIBLE TRACKS FOR ~w ---~n', [Limit, UserId]),
    ( evaluate_candidates(UserId, Ranked)
    -> print_ranked_prefix(Ranked, 1, Limit)
    ;  format('  (No compatible tracks found)~n')
    ),
    format('----------------------------------------------------~n').

print_ranked_prefix([], _, _).
print_ranked_prefix(_, N, Limit) :- N > Limit, !.
print_ranked_prefix([item(Score, TId, Conf, _)|Rest], N, Limit) :-
    track(TId, Title, Artist, Genre, BPM, _, Energy, Inst),
    format('  ~w. "~w" by ~w [~w] | Score: ~1f | Conf: ~2f | ~0f BPM, E:~2f, Inst:~2f~n',
           [N, Title, Artist, Genre, Score, Conf, BPM, Energy, Inst]),
    N1 is N + 1,
    print_ranked_prefix(Rest, N1, Limit).

%! show_kb_rules
show_kb_rules :-
    format('~n--- DECLARATIVE DOMAIN KNOWLEDGE BASE (kb_rules.pl) ---~n'),
    for_each(rule(Id, Head, Body, Weight, Desc),
             format('  [~w] (w=~2f) ~w :- ~w~n      // ~w~n', [Id, Weight, Head, Body, Desc])),
    format('-------------------------------------------------------~n').

%! recommend_session(+UserId)
% Synthesizes a 3-step Gradual Calm Playlist (Entry -> Bridge -> Target).
recommend_session(UserId) :-
    ( wm_fact(user_name(UserId, Name))
    -> wm_fact(user_heart_rate(UserId, HeartRate)),
       wm_fact(user_stress(UserId, Stress))
    ;  load_user_to_wm(UserId),
       wm_fact(user_name(UserId, Name)),
       wm_fact(user_heart_rate(UserId, HeartRate)),
       wm_fact(user_stress(UserId, Stress))
    ),
    format('~n+======================================================================+~n'),
    format('| 3-STEP GRADUAL CALM PLAYLIST (ENTRY -> BRIDGE -> TARGET)             |~n'),
    format('+======================================================================+~n'),
    format('| User: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100~n', [Name, HeartRate, Stress]),
    format('+----------------------------------------------------------------------+~n'),
    ( gradual_calm_playlist(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)])
    -> track(T1, Title1, _, _, BPM1, _, Eng1, _),
       track(T2, Title2, _, _, BPM2, _, Eng2, _),
       track(T3, Title3, _, _, BPM3, _, Eng3, _),
       format('| 1. [ENTRY]  ~w (~0f BPM, Energy: ~2f)~n', [Title1, BPM1, Eng1]),
       format('| 2. [BRIDGE] ~w (~0f BPM, Energy: ~2f)~n', [Title2, BPM2, Eng2]),
       format('| 3. [TARGET] ~w (~0f BPM, Energy: ~2f)~n', [Title3, BPM3, Eng3]),
       format('+----------------------------------------------------------------------+~n'),
       format('| Trajectory: ~0f BPM -> ~0f BPM -> ~0f BPM (Smooth Calming Curve)~n', [BPM1, BPM2, BPM3])
    ;  format('| [!] Unable to build a 3-step calming sequence from current catalog.~n')
    ),
    format('+======================================================================+~n~n').

% -------------------------------------------------------------------------
% 3. DEMONSTRATION & MACHINE-READABLE PYTHON BRIDGE
% -------------------------------------------------------------------------

%! demo
% Executes demonstration across three representative cases with HOW proof trees.
demo :-
    set_interactive(false),
    format('~n>>> CASE 1: High Work Stress & Gradual Calming (Sarah Miller) <<<~n'),
    recommend_with_how(user_sarah),
    recommend_session(user_sarah),
    format('~n>>> CASE 2: Intense Running Workout (Alex Chen) <<<~n'),
    recommend(user_alex),
    format('~n>>> CASE 3: Lyric-Free Deep Study Focus (Marco Rossi) <<<~n'),
    recommend(user_marco).

%! py_export_all
% Machine-readable output invoked by Python test_suite.py and demo_walkthrough.ipynb
% so that Python inspects actual SWI-Prolog/Prolog inference results.
py_export_all :-
    set_interactive(false),
    for_each(user(UId, _, _, _, _, _, _), (
        best_track_with_proof(UId, TId, Score, Conf, _),
        track(TId, Title, Artist, Genre, BPM, Val, Eng, Inst),
        format('BEST|~w|~w|~w|~w|~w|~1f|~2f|~2f|~2f|~2f|~2f~n',
               [UId, TId, Title, Artist, Genre, BPM, Val, Eng, Inst, Score, Conf])
    )),
    ( gradual_calm_playlist(user_sarah, [stage(entry, S1), stage(bridge, S2), stage(target, S3)])
    -> track(S1, N1, _, _, B1, _, E1, _),
       track(S2, N2, _, _, B2, _, E2, _),
       track(S3, N3, _, _, B3, _, E3, _),
       format('PLAYLIST|user_sarah|~w|~w|~0f|~2f|~w|~w|~0f|~2f|~w|~w|~0f|~2f~n',
              [S1, N1, B1, E1, S2, N2, B2, E2, S3, N3, B3, E3])
    ;  true
    ),
    load_user_to_wm(user_sarah),
    ( \+ prove(safe_for_user(adrenaline_rush_rock, user_sarah), [], _, _)
    -> format('BARRIER|safety_sarah_rock|BLOCKED~n')
    ;  format('BARRIER|safety_sarah_rock|ALLOWED~n')
    ),
    load_user_to_wm(user_marco),
    ( \+ prove(study_compatible(euphoric_run_anthem, user_marco), [], _, _)
    -> format('BARRIER|study_marco_vocal|BLOCKED~n')
    ;  format('BARRIER|study_marco_vocal|ALLOWED~n')
    ),
    load_user_to_wm(user_sarah),
    calculate_utility(clair_de_lune, user_sarah, 0.94, ScorePref),
    calculate_utility(weightless_ambient, user_sarah, 0.96, ScorePref2),
    set_custom_user_wm(sarah_nopref, 'Sarah NoPref', high_stress_work, 114.0, 84.0, stress_downregulation, []),
    calculate_utility(clair_de_lune, sarah_nopref, 0.94, ScoreNoPref),
    format('PREF_CHECK|~2f|~2f|~2f~n', [ScorePref, ScorePref2, ScoreNoPref]).

% -------------------------------------------------------------------------
% 4. NATIVE PROLOG 10-POINT LOGICAL VERIFICATION SUITE
% -------------------------------------------------------------------------

%! run_tests
% Validates all 10 criteria natively in Prolog; fails if any assertion fails.
run_tests :-
    set_interactive(false),
    format('~n========================================================================~n'),
    format(' PROLOG LOGICAL VERIFICATION SUITE (SEPARATED KB + INFERENCE ENGINE)~n'),
    format('========================================================================~n'),

    % 1. Stress relief pillar (Sarah)
    best_track(user_sarah, T1, _),
    track(T1, _, _, _, BPM1, _, Eng1, Inst1),
    BPM1 =< 75.0, Eng1 =< 0.35, Inst1 >= 0.70,
    format(' [+] 1. Stress Relief Pillar (Sarah): PASSED (~w)~n', [T1]),

    % 2. Workout boost pillar (Alex)
    best_track(user_alex, T2, _),
    track(T2, _, _, _, BPM2, _, Eng2, _),
    BPM2 >= 120.0, Eng2 >= 0.70,
    format(' [+] 2. Workout Pace Pillar (Alex): PASSED (~w)~n', [T2]),

    % 3. Study focus pillar (Marco)
    best_track(user_marco, T3, _),
    track(T3, _, _, _, BPM3, _, Eng3, Inst3),
    Inst3 >= 0.70, BPM3 >= 70.0, BPM3 =< 95.0, Eng3 =< 0.55,
    format(' [+] 3. Study Lyric-Free Pillar (Marco): PASSED (~w)~n', [T3]),

    % 4. Pre-sleep compatibility (David)
    best_track(user_david, T4, _),
    track(T4, _, _, _, BPM4, _, Eng4, Inst4),
    BPM4 =< 64.0, Eng4 =< 0.20, Inst4 >= 0.85,
    format(' [+] 4. Pre-Sleep Pillar (David): PASSED (~w)~n', [T4]),

    % 5. Post-workout recovery (Elena)
    best_track(user_elena, T5, _),
    track(T5, _, _, _, BPM5, Val5, Eng5, _),
    BPM5 >= 70.0, BPM5 =< 115.0, Eng5 =< 0.65, Val5 >= 0.40,
    format(' [+] 5. Recovery Balanced Pillar (Elena): PASSED (~w)~n', [T5]),

    % 6. Active commute vitality (Clara)
    best_track(user_clara, T6, _),
    track(T6, _, _, _, BPM6, Val6, Eng6, _),
    BPM6 >= 70.0, BPM6 =< 115.0, Eng6 =< 0.65, Val6 >= 0.40,
    format(' [+] 6. Active Commute Pillar (Clara): PASSED (~w)~n', [T6]),

    % 7. Gradual calm playlist monotonic tempo descent
    gradual_calm_playlist(user_sarah, [stage(entry, P1), stage(bridge, P2), stage(target, P3)]),
    track(P1, _, _, _, PB1, _, _, _),
    track(P2, _, _, _, PB2, _, _, _),
    track(P3, _, _, _, PB3, _, _, _),
    PB1 >= PB2, PB2 >= PB3,
    format(' [+] 7. Gradual Calm Playlist Monotonicity: PASSED (~0f -> ~0f -> ~0f BPM)~n', [PB1, PB2, PB3]),

    % 8. Safety barrier negative test (Sarah + adrenaline_rush_rock)
    load_user_to_wm(user_sarah),
    \+ prove(safe_for_user(adrenaline_rush_rock, user_sarah), [], _, _),
    format(' [+] 8. Safety Barrier (Negative Test - High Stress + Rock): PASSED~n'),

    % 9. Study focus negative test (Marco + euphoric_run_anthem)
    load_user_to_wm(user_marco),
    \+ prove(study_compatible(euphoric_run_anthem, user_marco), [], _, _),
    format(' [+] 9. Study Lyric Barrier (Negative Test - Study + Vocal Pop): PASSED~n'),

    % 10. Multi-criteria preference bonus + Proof Tree generation
    load_user_to_wm(user_sarah),
    best_track_with_proof(user_sarah, T1, SWithPref, Conf1, Proof1),
    Proof1 \= empty_and, Conf1 > 0.80,
    set_custom_user_wm(sarah_nopref, 'Sarah NoPref', high_stress_work, 114.0, 84.0, stress_downregulation, []),
    calculate_utility(T1, sarah_nopref, Conf1, SWithoutPref),
    SWithPref > SWithoutPref,
    format(' [+] 10. Utility Preference Bonus & Proof Tree: PASSED (~1f > ~1f)~n', [SWithPref, SWithoutPref]),

    format('------------------------------------------------------------------------~n'),
    format(' Summary: 10/10 Prolog verification checks PASSED.~n'),
    format('========================================================================~n~n').

help :-
    format('~nAvailable Commands in SWI-Prolog:~n'),
    format('  ?- start.                         - Launch interactive Expert System menu (recommended for demo).~n'),
    format('  ?- recommend(user_sarah).         - Recommend optimal track for Sarah.~n'),
    format('  ?- recommend_with_how(user_sarah).- Recommend track + print HOW proof tree.~n'),
    format('  ?- explain_last_decision(user_sarah). - Print HOW proof tree for last query.~n'),
    format('  ?- recommend_session(user_sarah). - Generate 3-step Gradual Calm Playlist.~n'),
    format('  ?- show_wm.                       - Inspect Short-Term Working Memory.~n'),
    format('  ?- show_kb_rules.                 - Inspect Declarative Knowledge Base rules.~n'),
    format('  ?- demo.                          - Run 3 representative clinical/routine cases.~n'),
    format('  ?- run_tests.                     - Run 10-point Prolog logical verification suite.~n~n').
