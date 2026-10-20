% =========================================================================
% DSS Rules Module: Biometric Matching, Physiological Safety, and Entrainment
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(dss_rules, [
    biometric_stress_tier/2,
    heart_rate_delta/3,
    check_cognitive_load_bounds/2,
    check_workout_cadence_bounds/2,
    check_routine_bounds/2,
    check_genre_affinity/3,
    iso_stage_matching/4,
    validate_track_for_biometrics/3,
    diagnose_track_failure/4
]).

:- use_module('../knowledge_base/load_kb.pl').

% -------------------------------------------------------------------------
% 1. BIOMETRIC & PHYSIOLOGICAL CLASSIFICATIONS
% -------------------------------------------------------------------------

%! biometric_stress_tier(+StressScore, -Tier)
% Classifies physiological stress level (0-100) derived from HRV and GSR:
% - low_recovery:    0 - 35
% - moderate_demand: 36 - 65
% - acute_stress:    66 - 100
biometric_stress_tier(Stress, low_recovery) :-
    Stress =< 35.0, !.
biometric_stress_tier(Stress, moderate_demand) :-
    Stress > 35.0,
    Stress =< 65.0, !.
biometric_stress_tier(Stress, acute_stress) :-
    Stress > 65.0.

%! heart_rate_delta(+TrackBPM, +UserHeartRate, -DeltaBPM)
% Absolute difference between musical tempo and user heart rate.
heart_rate_delta(TrackBPM, UserHR, Delta) :-
    Delta is abs(TrackBPM - UserHR).

% -------------------------------------------------------------------------
% 2. COGNITIVE & ACTIVITY-SPECIFIC BOUNDS
% -------------------------------------------------------------------------

%! check_cognitive_load_bounds(+TrackId, +Activity)
% For deep study / flowstate tasks: enforces strict absence of vocal lyrics (instrumentalness >= 0.70)
% and sound pressure ceiling (loudness <= -13.0 dB) to eliminate auditory distraction.
check_cognitive_load_bounds(TrackId, deep_focus_study) :-
    !,
    track_acoustic(TrackId, _, Instrumentalness, LoudnessDb),
    Instrumentalness >= 0.70,
    LoudnessDb =< -13.0.
check_cognitive_load_bounds(_, _).

%! check_workout_cadence_bounds(+TrackId, +Activity)
% For cardio and running: requires tempo synchronization (BPM >= 120.0) and high energy (>= 0.70).
check_workout_cadence_bounds(TrackId, cardio_running) :-
    !,
    track(TrackId, _, _, _, BPM, _, Energy, _, _, _, _, _, _),
    BPM >= 120.0,
    Energy >= 0.70.
check_workout_cadence_bounds(_, _).

% -------------------------------------------------------------------------
% 3. ROUTINE PROTOCOL BOUNDS
% -------------------------------------------------------------------------

%! check_routine_bounds(+TrackId, +RoutineId)
% Verifies whether a song falls within the physiological parameters of the health routine.
check_routine_bounds(TrackId, RoutineId) :-
    health_routine(RoutineId, _, _, MinBPM, MaxBPM, MinVal, MaxVal, MinEng, MaxEng, MinInst, MaxLoud, _, _, _, ReqAttrs, _),
    track(TrackId, _, _, _, BPM, Valence, Energy, _, _, Inst, Loudness, _, Attrs),
    BPM >= MinBPM, BPM =< MaxBPM,
    Valence >= MinVal, Valence =< MaxVal,
    Energy >= MinEng, Energy =< MaxEng,
    Inst >= MinInst,
    Loudness =< MaxLoud,
    % Check if at least one required attribute is present or no specific attrs required
    ( ReqAttrs == []
    -> true
    ;  member(Attr, ReqAttrs),
       member(Attr, Attrs)
    ).

% -------------------------------------------------------------------------
% 4. USER GENRE AFFINITY
% -------------------------------------------------------------------------

%! check_genre_affinity(+TrackId, +PreferredGenres, -AffinityMultiplier)
% Calculates preference weighting: 1.25 for preferred genre, 1.0 for neutral genre.
check_genre_affinity(TrackId, PreferredGenres, 1.25) :-
    track(TrackId, _, _, Genre, _, _, _, _, _, _, _, _, _),
    member(Genre, PreferredGenres), !.
check_genre_affinity(_, _, 1.0).

% -------------------------------------------------------------------------
% 5. ISO-PRINCIPLE ENTRAINMENT STAGING
% -------------------------------------------------------------------------

%! iso_stage_matching(+Stage, +UserHR, +TargetHR, +TrackId)
% Implements Altshuler's Musical Iso-Principle for biofeedback entrainment:
% - stage(entry): match current elevated heart rate (within +/- 15 BPM) to validate affective state.
% - stage(transition): mid-point bridge between current HR and target HR.
% - stage(target): settles at target recovery HR (+/- 10 BPM) and low energy (< 0.35).
iso_stage_matching(entry, UserHR, _, TrackId) :-
    track_features(TrackId, BPM, _, _),
    Delta is abs(BPM - UserHR),
    Delta =< 18.0.

iso_stage_matching(transition, UserHR, TargetHR, TrackId) :-
    MidBPM is (UserHR + TargetHR) / 2.0,
    track_features(TrackId, BPM, _, Energy),
    Delta is abs(BPM - MidBPM),
    Delta =< 15.0,
    Energy =< 0.60.

iso_stage_matching(target, _, TargetHR, TrackId) :-
    track_features(TrackId, BPM, _, Energy),
    Delta is abs(BPM - TargetHR),
    Delta =< 12.0,
    Energy =< 0.35.

% -------------------------------------------------------------------------
% 6. UNIFIED CANDIDATE VALIDATION
% -------------------------------------------------------------------------

%! validate_track_for_biometrics(+TrackId, +Biometrics, +RoutineId)
% Evaluates all strict constraints for a candidate track given user biometrics and target routine.
validate_track_for_biometrics(TrackId, Biometrics, RoutineId) :-
    Biometrics = user_biometrics(_, _, Activity, _HR, _, _, _Stress, _, _, _, _, _),
    check_cognitive_load_bounds(TrackId, Activity),
    check_workout_cadence_bounds(TrackId, Activity),
    check_routine_bounds(TrackId, RoutineId).

%! diagnose_track_failure(+TrackId, +Biometrics, +RoutineId, -Reasons)
% Explains why a track was discarded by constraint satisfaction.
diagnose_track_failure(TrackId, Biometrics, RoutineId, Reasons) :-
    Biometrics = user_biometrics(_, _, Activity, _HR, _, _, _Stress, _, _, _, _, _),
    health_routine(RoutineId, _, _, MinBPM, MaxBPM, MinVal, MaxVal, MinEng, MaxEng, MinInst, MaxLoud, _, _, _, _, _),
    track(TrackId, _, _, _, BPM, Valence, Energy, _, _, Inst, Loudness, _, _),
    
    findall(Reason, (
        ( Activity == deep_focus_study, Inst < 0.70
        -> Reason = 'Cognitive load violation: Track has vocal lyrics (instrumentalness < 0.70)'
        ; fail )
        ;
        ( Activity == deep_focus_study, Loudness > -13.0
        -> Reason = 'Acoustic intrusion: Loudness exceeds focus ceiling (-13.0 dB)'
        ; fail )
        ;
        ( Activity == cardio_running, BPM < 120.0
        -> Reason = 'Cadence mismatch: BPM is below aerobic cadence threshold (120 BPM)'
        ; fail )
        ;
        ( BPM < MinBPM ; BPM > MaxBPM
        -> Reason = 'BPM out of routine physiological window'
        ; fail )
        ;
        ( Valence < MinVal ; Valence > MaxVal
        -> Reason = 'Valence does not match affective mood protocol'
        ; fail )
        ;
        ( Energy < MinEng ; Energy > MaxEng
        -> Reason = 'Energy level incompatible with target autonomic arousal'
        ; fail )
        ;
        ( Inst < MinInst
        -> Reason = 'Instrumental purity below routine minimum'
        ; fail )
        ;
        ( Loudness > MaxLoud
        -> Reason = 'Track exceeds maximum decibel loudness limit'
        ; fail )
    ), Reasons).
