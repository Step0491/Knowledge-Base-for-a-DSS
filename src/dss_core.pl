% =========================================================================
% DSS Core Module: Music Recommendation & Health Routine Façade
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(dss_core, [
    recommend_for_user/2,
    recommend_for_user/3,
    recommend_iso_session_for_user/3,
    query_smartwatch_advisor/1,
    query_smartwatch_advisor/2,
    evaluate_custom_biometrics/5
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).
:- use_module(routine_generator).
:- use_module(scoring_model).
:- use_module(explanation_engine).

%! recommend_for_user(+UserId, -BestRanked)
recommend_for_user(UserId, BestRanked) :-
    recommend_for_user(UserId, balanced, BestRanked).

%! recommend_for_user(+UserId, +Profile, -BestRanked)
recommend_for_user(UserId, Profile, BestRanked) :-
    user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    generate_candidate_tracks(Biometrics, Goal, Candidates),
    ( Candidates \= []
    -> rank_candidate_tracks(Candidates, Biometrics, Goal, Profile, [BestRanked|_])
    ;  fail
    ).

%! recommend_iso_session_for_user(+UserId, -SessionTracks, -SessionStats)
recommend_iso_session_for_user(UserId, SessionTracks, SessionStats) :-
    user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    generate_iso_routine_session(Biometrics, Goal, SessionTracks, SessionStats).

%! query_smartwatch_advisor(+UserId)
query_smartwatch_advisor(UserId) :-
    query_smartwatch_advisor(UserId, balanced).

%! query_smartwatch_advisor(+UserId, +Profile)
query_smartwatch_advisor(UserId, Profile) :-
    user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(UserId, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    format('~n[*] Querying DSS Cognitive Assistant for User: ~w (~w)...~n', [Name, UserId]),
    generate_candidate_tracks(Biometrics, Goal, Candidates),
    ( Candidates \= []
    -> length(Candidates, Count),
       format('[+] Evaluated ~w candidate tracks satisfying all clinical and acoustic bounds.~n', [Count]),
       rank_candidate_tracks(Candidates, Biometrics, Goal, Profile, [BestRanked|Rest]),
       print_recommendation_card(BestRanked, Biometrics, Goal),
       BestRanked = ranked(_, BestTrackId, _),
       explain_recommendation(BestTrackId, Biometrics, Goal),
       % If Iso routine applies, also demonstrate multi-track entrainment
       ( health_routine(Goal, _, _, _, _, _, _, _, _, _, _, _, _, _, _, true)
       -> ( generate_iso_routine_session(Biometrics, Goal, IsoTracks, IsoStats)
          -> print_iso_session_card(IsoTracks, IsoStats, Biometrics)
          ;  true )
       ; true )
    ;  format('[!] No tracks found satisfying all strict constraints for goal: ~w.~n', [Goal]),
       diagnose_routine_failure(Biometrics, Goal, Diagnostics),
       format('--- Constraint Violation Diagnostics ---~n'),
       forall(member(track_diag(T, Reasons), Diagnostics),
              format(' * Track ~w rejected: ~w~n', [T, Reasons]))
    ).

%! evaluate_custom_biometrics(+Activity, +HR, +Stress, +Goal, -RankedResults)
evaluate_custom_biometrics(Activity, HR, Stress, Goal, RankedResults) :-
    Biometrics = user_biometrics(temp_user, 'Ad-hoc User', Activity, HR, 60.0, 40.0, Stress, 5.0, afternoon, 30.0, Goal, [ambient, classical, lofi, electronic]),
    generate_candidate_tracks(Biometrics, Goal, Candidates),
    rank_candidate_tracks(Candidates, Biometrics, Goal, balanced, RankedResults).
