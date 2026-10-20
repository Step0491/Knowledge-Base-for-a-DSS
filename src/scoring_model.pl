% =========================================================================
% Scoring Model Module: Multi-Criteria Decision Analysis (MCDA)
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(scoring_model, [
    calculate_track_utility/5,
    rank_candidate_tracks/5
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).

%! profile_weights(+ProfileName, -W_Bio, -W_Mood, -W_Goal, -W_Pref)
% Weights sum to 1.0.
profile_weights(health_priority,      0.45, 0.25, 0.20, 0.10).
profile_weights(performance_priority, 0.30, 0.20, 0.40, 0.10).
profile_weights(acoustic_first,       0.25, 0.35, 0.15, 0.25).
profile_weights(balanced,             0.35, 0.25, 0.25, 0.15).
profile_weights(_,                    0.35, 0.25, 0.25, 0.15). % default fallback

%! calculate_track_utility(+TrackId, +Biometrics, +RoutineId, +Profile, -ScoreBreakdown)
% Evaluates multi-criteria utility U(t) for a given track in [0, 100].
calculate_track_utility(TrackId, Biometrics, RoutineId, Profile, ScoreBreakdown) :-
    Biometrics = user_biometrics(_, _, _, UserHR, _, _, Stress, _, _, Fatigue, _, PreferredGenres),
    health_routine(RoutineId, _, _, _, _, _, _, _, _, _, _, TargetMinHR, TargetMaxHR, _, _, _),
    profile_weights(Profile, W_Bio, W_Mood, W_Goal, W_Pref),

    track(TrackId, _, _, _, BPM, Valence, Energy, _, Acousticness, Inst, _, _, Attrs),

    % 1. Biometric Alignment Sub-Score S_bio (0 - 100)
    TargetMidHR is (TargetMinHR + TargetMaxHR) / 2.0,
    BpmDiff is abs(BPM - TargetMidHR),
    ( BpmDiff =< 40.0
    -> RawBioScore is 100.0 - (BpmDiff / 40.0 * 60.0)
    ;  RawBioScore is 40.0
    ),
    % Bonus for high acousticness/instrumentalness under elevated stress
    ( Stress > 65.0
    -> S_Bio is min(100.0, RawBioScore + (Acousticness * 10.0) + (Inst * 10.0))
    ;  S_Bio is RawBioScore
    ),

    % 2. Mood & Affective Modulation Sub-Score S_mood (0 - 100)
    % When fatigued or stressed, higher valence improves affective recovery
    ( (Stress > 50.0 ; Fatigue > 50.0)
    -> S_Mood is (Valence * 70.0) + 30.0
    ;  S_Mood is (Valence * 50.0) + 50.0
    ),

    % 3. Health Routine Goal Sub-Score S_goal (0 - 100)
    % Reward energy matching and required attributes
    health_routine(RoutineId, _, _, _, _, _, _, MinEng, MaxEng, _, _, _, _, _, ReqAttrs, _),
    ( (Energy >= MinEng, Energy =< MaxEng) -> EngScore = 60.0 ; EngScore = 30.0 ),
    intersection(ReqAttrs, Attrs, CommonAttrs),
    length(CommonAttrs, NumMatched),
    AttrBonus is min(40.0, NumMatched * 40.0),
    S_Goal is EngScore + AttrBonus,

    % 4. User Preference Sub-Score S_pref (0 - 100)
    track(TrackId, _, _, Genre, _, _, _, _, _, _, _, _, _),
    ( member(Genre, PreferredGenres) -> S_Pref = 100.0 ; S_Pref = 50.0 ),

    % Multi-Attribute Utility Function
    FinalUtility is (W_Bio * S_Bio) + (W_Mood * S_Mood) + (W_Goal * S_Goal) + (W_Pref * S_Pref),
    ScoreBreakdown = score(FinalUtility, S_Bio, S_Mood, S_Goal, S_Pref).

%! rank_candidate_tracks(+CandidateIds, +Biometrics, +RoutineId, +Profile, -RankedResults)
% Computes utilities and sorts candidate tracks in descending order of utility.
rank_candidate_tracks(Candidates, Biometrics, RoutineId, Profile, RankedResults) :-
    findall(ranked(Utility, TrackId, ScoreBreakdown), (
        member(TrackId, Candidates),
        calculate_track_utility(TrackId, Biometrics, RoutineId, Profile, ScoreBreakdown),
        ScoreBreakdown = score(Utility, _, _, _, _)
    ), ScoredList),
    sort(1, @>=, ScoredList, RankedResults).
