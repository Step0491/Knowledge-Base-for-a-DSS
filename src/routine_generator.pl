% =========================================================================
% Routine Generator Module: Music Sequence Planning & Iso-Principle Staging
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(routine_generator, [
    generate_candidate_tracks/3,
    generate_iso_routine_session/4,
    generate_steady_routine_session/4
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).

%! generate_candidate_tracks(+Biometrics, +RoutineId, -Candidates)
% Finds all single tracks in the knowledge base that strictly fulfill the physiological constraints.
generate_candidate_tracks(Biometrics, RoutineId, Candidates) :-
    findall(TrackId, (
        track(TrackId, _, _, _, _, _, _, _, _, _, _, _, _),
        validate_track_for_biometrics(TrackId, Biometrics, RoutineId)
    ), Candidates).

%! generate_iso_routine_session(+Biometrics, +RoutineId, -SessionTracks, -SessionStats)
% Synthesizes an adaptive 3-stage entrainment session using the Iso-Principle:
% Stage 1 (Entry): Meets the user at their elevated physiological state.
% Stage 2 (Bridge): Moderate tempo taper, calming autonomic activation.
% Stage 3 (Target Lock): Deep parasympathetic / rest stabilization.
generate_iso_routine_session(Biometrics, RoutineId, SessionTracks, SessionStats) :-
    Biometrics = user_biometrics(_, _, _, UserHR, _, _, _, _, _, _, _, _),
    health_routine(RoutineId, _, _, _, _, _, _, _, _, _, _, TargetMinHR, TargetMaxHR, _, _, _),
    TargetMidHR is (TargetMinHR + TargetMaxHR) / 2.0,

    % Stage 1: Entry
    iso_stage_matching(entry, UserHR, TargetMidHR, TrackEntry),
    
    % Stage 2: Bridge (must not be identical to entry)
    iso_stage_matching(transition, UserHR, TargetMidHR, TrackBridge),
    TrackBridge \= TrackEntry,

    % Stage 3: Target (must not be identical to entry or bridge)
    iso_stage_matching(target, UserHR, TargetMidHR, TrackTarget),
    TrackTarget \= TrackEntry,
    TrackTarget \= TrackBridge,

    SessionTracks = [
        stage(entry, TrackEntry),
        stage(transition, TrackBridge),
        stage(target, TrackTarget)
    ],

    % Compute aggregate duration and metrics
    track(TrackEntry, _, _, _, BPM1, _, _, _, _, _, _, Dur1, _),
    track(TrackBridge, _, _, _, BPM2, _, _, _, _, _, _, Dur2, _),
    track(TrackTarget, _, _, _, BPM3, _, _, _, _, _, _, Dur3, _),
    
    TotalDurationS is Dur1 + Dur2 + Dur3,
    TotalDurationMin is TotalDurationS / 60.0,
    TempoTrajectory = [BPM1, BPM2, BPM3],
    ExpectedHRDrop is UserHR - TargetMidHR,
    
    SessionStats = session_stats(TotalDurationMin, TempoTrajectory, ExpectedHRDrop).

%! generate_steady_routine_session(+Biometrics, +RoutineId, +TargetDurationMin, -SessionTracks)
% Synthesizes a steady-state routine session (for cardio pacing, active commute, or deep focus)
% assembling compatible tracks until the target duration (in minutes) is satisfied.
generate_steady_routine_session(Biometrics, RoutineId, TargetDurationMin, SessionTracks) :-
    generate_candidate_tracks(Biometrics, RoutineId, Candidates),
    Candidates \= [],
    TargetDurationSec is TargetDurationMin * 60,
    accumulate_steady_tracks(Candidates, TargetDurationSec, 0, [], SessionTracks).

accumulate_steady_tracks([], _, _, Acc, Result) :-
    reverse(Acc, Result).
accumulate_steady_tracks([T|Rest], TargetSec, CurrSec, Acc, Result) :-
    CurrSec >= TargetSec,
    !,
    reverse(Acc, Result).
accumulate_steady_tracks([T|Rest], TargetSec, CurrSec, Acc, Result) :-
    track(T, _, _, _, _, _, _, _, _, _, _, Dur, _),
    NewSec is CurrSec + Dur,
    accumulate_steady_tracks(Rest, TargetSec, NewSec, [T|Acc], Result).
