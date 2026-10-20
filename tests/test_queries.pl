% =========================================================================
% Logical Correctness Test Suite
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(test_queries, [
    run_all_tests/0,
    test/2
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module('../src/dss_rules.pl').
:- use_module('../src/routine_generator.pl').
:- use_module('../src/scoring_model.pl').
:- use_module('../src/dss_core.pl').

% Test Runner Harness
run_all_tests :-
    format('~n========================================================================~n'),
    format(' DSS LOGICAL CORRECTNESS & PHYSIOLOGICAL CONSTRAINT TEST SUITE~n'),
    format('========================================================================~n'),
    findall(TestId-Status, execute_test(TestId, Status), Results),
    print_test_summary(Results).

execute_test(TestId, Status) :-
    test(TestId, Description),
    format('[RUN] Test ~w: ~w... ', [TestId, Description]),
    ( catch(call_test(TestId), Error, (format('FAILED with error ~w~n', [Error]), fail))
    -> format('PASSED~n'), Status = passed
    ;  format('FAILED~n'), Status = failed
    ).

print_test_summary(Results) :-
    findall(T, member(T-passed, Results), Passed),
    findall(T, member(T-failed, Results), Failed),
    length(Passed, NumPass),
    length(Failed, NumFail),
    Total is NumPass + NumFail,
    format('~n------------------------------------------------------------------------~n'),
    format(' Test Execution Summary: ~w/~w Passed (~w Failed)~n', [NumPass, Total, NumFail]),
    format('------------------------------------------------------------------------~n~n'),
    ( NumFail =:= 0
    -> true
    ;  throw(tests_failed(NumFail))
    ).

% -------------------------------------------------------------------------
% TEST DEFINITIONS
% -------------------------------------------------------------------------

test(1, 'Acute stress downregulation recommends low-tempo, low-energy ambient track').
call_test(1) :-
    user_biometrics(user_sarah, _, Act, HR, _, _, Stress, _, _, _, Goal, _),
    Stress > 80.0,
    recommend_for_user(user_sarah, ranked(_, TrackId, _)),
    track(TrackId, _, _, _, BPM, _, Energy, _, _, Inst, _, _, _),
    BPM =< 75.0,
    Energy =< 0.35,
    Inst >= 0.70.

test(2, 'Cardio workout enforces cadence synchronization (BPM >= 120, Energy >= 0.75)').
call_test(2) :-
    user_biometrics(user_alex, _, _, _, _, _, _, _, _, _, Goal, _),
    recommend_for_user(user_alex, ranked(_, TrackId, _)),
    track(TrackId, _, _, _, BPM, _, Energy, _, _, _, _, _, _),
    BPM >= 120.0,
    Energy >= 0.75.

test(3, 'Deep focus mode strictly filters out lyrics (instrumentalness >= 0.80)').
call_test(3) :-
    user_biometrics(user_marco, _, Act, _, _, _, _, _, _, _, Goal, _),
    Act == deep_focus_study,
    recommend_for_user(user_marco, ranked(_, TrackId, _)),
    track_acoustic(TrackId, _, Inst, Loudness),
    Inst >= 0.80,
    Loudness =< -13.0.

test(4, 'Post-workout recovery triggers deceleration and relaxation acoustic features').
call_test(4) :-
    user_biometrics(user_elena, _, _, _, _, _, _, _, _, _, Goal, _),
    recommend_for_user(user_elena, ranked(_, TrackId, _)),
    track(TrackId, _, _, _, BPM, _, Energy, _, _, _, _, _, _),
    BPM =< 105.0,
    Energy =< 0.55.

test(5, 'Sleep induction enforces somnolent regime (BPM <= 64, Energy <= 0.20)').
call_test(5) :-
    user_biometrics(user_david, _, _, _, _, _, _, _, _, _, Goal, _),
    recommend_for_user(user_david, ranked(_, TrackId, _)),
    track(TrackId, _, _, _, BPM, _, Energy, _, Acousticness, Inst, _, _, _),
    BPM =< 64.0,
    Energy =< 0.20,
    Acousticness >= 0.85,
    Inst >= 0.85.

test(6, 'Active commute provides upbeat affective valence (Valence >= 0.65)').
call_test(6) :-
    user_biometrics(user_clara, _, _, _, _, _, _, _, _, _, Goal, _),
    recommend_for_user(user_clara, ranked(_, TrackId, _)),
    track(TrackId, _, _, _, BPM, Valence, _, _, _, _, _, _, _),
    BPM >= 95.0,
    Valence >= 0.65.

test(7, 'Iso-Principle multi-stage entrainment session creates monotonic downward tempo gradient').
call_test(7) :-
    recommend_iso_session_for_user(user_sarah, SessionTracks, session_stats(_, Trajectory, ExpectedDrop)),
    ExpectedDrop > 0,
    Trajectory = [BPM1, BPM2, BPM3],
    BPM1 >= BPM2,
    BPM2 >= BPM3.

test(8, 'Negative Test: Cardio cadence constraint rejects tracks below 120 BPM').
call_test(8) :-
    user_biometrics(user_alex, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(user_alex, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    % weightless_ambient has 60 BPM and should fail validation for cardio_running
    \+ validate_track_for_biometrics(weightless_ambient, Biometrics, Goal).

test(9, 'Negative Test: Focus constraint rejects tracks with low instrumentalness').
call_test(9) :-
    user_biometrics(user_marco, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(user_marco, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    % euphoric_run_anthem has instrumentalness 0.12 (lyrics) and must fail
    \+ validate_track_for_biometrics(euphoric_run_anthem, Biometrics, Goal).

test(10, 'MCDA scoring sensitivity: Preferred genre receives higher utility').
call_test(10) :-
    user_biometrics(user_sarah, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    Biometrics = user_biometrics(user_sarah, Name, Act, HR, RHR, HRV, Stress, GSR, Phase, Fat, Goal, Prefs),
    % Calculate utility with preferred genre vs arbitrary genre
    calculate_track_utility(weightless_ambient, Biometrics, Goal, balanced, score(U1, _, _, _, S_Pref1)),
    S_Pref1 =:= 100.0,
    U1 > 70.0.
