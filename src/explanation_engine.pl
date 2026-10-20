% =========================================================================
% Explanation Engine Module: Cognitive Assistant Rationale & Diagnostics
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(explanation_engine, [
    explain_recommendation/3,
    print_recommendation_card/3,
    print_iso_session_card/3,
    diagnose_routine_failure/3
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).
:- use_module(scoring_model).

%! explain_recommendation(+TrackId, +Biometrics, +RoutineId)
% Prints an analytical justification of why the track was selected by the DSS.
explain_recommendation(TrackId, Biometrics, RoutineId) :-
    Biometrics = user_biometrics(UserId, UserName, Activity, HR, RestingHR, HRV, Stress, GSR, Phase, Fatigue, _, _),
    track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, _, Acousticness, Inst, Loudness, DurS, _),
    health_routine(RoutineId, RoutineName, _, _, _, _, _, _, _, _, _, MinTHR, MaxTHR, _, _, _),
    biometric_stress_tier(Stress, StressTier),
    
    format('~n========================================================================~n'),
    format(' DSS RECOMMENDATION RATIONALE: ~w (~w)~n', [Title, Artist]),
    format('========================================================================~n'),
    format(' [1] Live Smartwatch Context:~n'),
    format('     * User: ~w (~w) | Current Activity: ~w~n', [UserName, UserId, Activity]),
    format('     * Heart Rate: ~1f BPM (Baseline RHR: ~1f BPM) | HRV: ~1f ms~n', [HR, RestingHR, HRV]),
    format('     * Stress Level: ~1f/100 (Classification: ~w) | GSR: ~1f uS~n', [Stress, StressTier, GSR]),
    format('     * Circadian Phase: ~w | Fatigue Index: ~1f/100~n', [Phase, Fatigue]),
    format('~n [2] Prescription & Health Routine:~n'),
    format('     * Target Protocol: ~w~n', [RoutineName]),
    format('     * Physiological Target Zone: [~1f - ~1f BPM]~n', [MinTHR, MaxTHR]),
    format('~n [3] Acoustic & Entrainment Analysis:~n'),
    format('     * Tempo: ~1f BPM (Frequency matching autonomic rhythm)~n', [BPM]),
    format('     * Energy: ~2f | Valence (Affective Positivity): ~2f~n', [Energy, Valence]),
    format('     * Instrumentalness: ~2f | Acousticness: ~2f | Loudness: ~1f dB~n', [Inst, Acousticness, Loudness]),
    format('     * Duration: ~w seconds (~1f min) | Genre: ~w~n', [DurS, DurS / 60.0, Genre]),
    format('~n [4] Cognitive Assistant Rationale:~n'),
    ( StressTier == acute_stress
    -> format('     * VAGAL ACTIVATION: Patient exhibits acute sympathetic arousal (Stress ~1f).~n', [Stress]),
       format('       High instrumental purity (~2f) and low energy (~2f) prevent sensory overload~n', [Inst, Energy]),
       format('       and induce respiratory sinus arrhythmia to downregulate heart rate.~n')
    ; Activity == cardio_running
    -> format('     * CADENCE LOCK: High tempo (~1f BPM) and maximal energy (~2f) synchronize with~n', [BPM, Energy]),
       format('       stride frequency, reducing Rate of Perceived Exertion (RPE) and delaying fatigue.~n')
    ; Activity == deep_focus_study
    -> format('     * COGNITIVE BANDWIDTH: Instrumentalness (~2f) avoids phonological loop interference,~n', [Inst]),
       format('       allowing sustained prefrontal cortex focus in the alpha/theta EEG waveband.~n')
    ;  format('     * HOMEOSTATIC REGULATION: Harmonic structure supports current circadian phase.~n')
    ),
    format('========================================================================~n~n').

%! print_recommendation_card(+RankedItem, +Biometrics, +RoutineId)
print_recommendation_card(ranked(Utility, TrackId, score(Util, SBio, SMood, SGoal, SPref)), Biometrics, RoutineId) :-
    track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, _, _, Inst, _, DurS, _),
    Biometrics = user_biometrics(_, UserName, Activity, HR, _, _, Stress, _, _, _, _, _),
    
    format('~n+----------------------------------------------------------------------+~n'),
    format('| OPTIMAL TRACK: ~-53w |~n', [Title]),
    format('| Artist: ~-60w |~n', [Artist]),
    format('+----------------------------------------------------------------------+~n'),
    format('| MCDA Utility: ~5.1f / 100.0                                          |~n', [Utility]),
    format('| Sub-Scores: Bio: ~4.1f | Mood: ~4.1f | Goal: ~4.1f | Pref: ~4.1f       |~n', [SBio, SMood, SGoal, SPref]),
    format('| Acoustic: BPM: ~4.1f | Energy: ~3.2f | Valence: ~3.2f | Inst: ~3.2f     |~n', [BPM, Energy, Valence, Inst]),
    format('| User: ~-14w | HR: ~3.0f BPM | Stress: ~3.0f/100 | Act: ~-15w |~n', [UserName, HR, Stress, Activity]),
    format('+----------------------------------------------------------------------+~n').

%! print_iso_session_card(+SessionTracks, +SessionStats, +Biometrics)
print_iso_session_card(SessionTracks, session_stats(TotalMin, Trajectory, Drop), Biometrics) :-
    Biometrics = user_biometrics(_, UserName, Activity, UserHR, _, _, Stress, _, _, _, _, _),
    format('~n+======================================================================+~n'),
    format('| ADAPTIVE ISO-PRINCIPLE ENTRAINMENT SESSION                           |~n'),
    format('+======================================================================+~n'),
    format('| User: ~-20w | Current HR: ~3.0f BPM | Stress: ~3.0f/100       |~n', [UserName, UserHR, Stress]),
    format('| Total Duration: ~4.1f min | Expected HR Reduction: -~4.1f BPM          |~n', [TotalMin, Drop]),
    format('| Tempo Ramp (BPM): ~w                                          |~n', [Trajectory]),
    format('+----------------------------------------------------------------------+~n'),
    forall(member(stage(StageName, TrackId), SessionTracks), (
        track(TrackId, Title, Artist, _, BPM, _, Eng, _, _, _, _, DurS, _),
        format('| [Stage: ~-10w] ~-24w (~1f BPM, Eng:~2f, ~1fm) |~n', [StageName, Title, BPM, Eng, DurS/60.0])
    )),
    format('+======================================================================+~n~n').

%! diagnose_routine_failure(+Biometrics, +RoutineId, -Diagnostics)
% Diagnoses why zero candidates satisfied the constraints.
diagnose_routine_failure(Biometrics, RoutineId, Diagnostics) :-
    findall(track_diag(T, Reasons), (
        track(T, _, _, _, _, _, _, _, _, _, _, _, _),
        diagnose_track_failure(T, Biometrics, RoutineId, Reasons),
        Reasons \= []
    ), Diagnostics).
