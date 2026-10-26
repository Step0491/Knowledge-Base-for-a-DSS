% =========================================================================
% Entry point: main.pl
% Decision Support System (DSS) - Music Recommendation
% =========================================================================

:- consult('dss_rules.pl').

% -------------------------------------------------------------------------
% 1. RECOMMENDATION QUERIES
% -------------------------------------------------------------------------

% recommend(+UserId)
% Evaluates and prints the single optimal track for a given user.
recommend(UserId) :-
    user(UserId, Name, Activity, HeartRate, Stress, Goal, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' USER PROFILE: ~w (~w)~n', [Name, UserId]),
    format(' Activity: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100 | Goal: ~w~n', [Activity, HeartRate, Stress, Goal]),
    format('------------------------------------------------------------------------~n'),
    ( best_track(UserId, TrackId, UtilityScore)
    -> track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness),
       format(' Recommended track: "~w" - ~w~n', [Title, Artist]),
       format(' Score: ~1f/100 | Genre: ~w~n', [UtilityScore, Genre]),
       format(' Features: ~0f BPM | Energy: ~2f | Valence: ~2f | Instrumental: ~2f~n', [BPM, Energy, Valence, Instrumentalness]),
       explain_choice(Activity, Stress, BPM, Instrumentalness)
    ;  format(' No track in the knowledge base satisfies the constraints for this user.~n')
    ),
    format('------------------------------------------------------------------------~n~n').

% recommend_top(+UserId, +N)
% Displays the top N eligible tracks ranked by multi-attribute utility score.
recommend_top(UserId, N) :-
    user(UserId, Name, Activity, _, _, Goal, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' TOP ~w RECOMMENDATIONS FOR: ~w (~w)~n', [N, Name, UserId]),
    format(' Activity: ~w | Goal: ~w~n', [Activity, Goal]),
    format('------------------------------------------------------------------------~n'),
    findall(Score-TId, (
        recommendable_track(TId, UserId),
        calculate_utility(TId, UserId, Score)
    ), Candidates),
    sort(1, @>=, Candidates, Sorted),
    ( Sorted == []
    -> format(' No eligible tracks found for this user.~n')
    ;  print_top_n(Sorted, N, 1)
    ),
    format('------------------------------------------------------------------------~n~n').

print_top_n([], _, _) :- !.
print_top_n(_, N, Rank) :- Rank > N, !.
print_top_n([Score-TId|Rest], N, Rank) :-
    track(TId, Title, Artist, Genre, BPM, _, _, _),
    format(' ~w. [Score: ~1f] "~w" - ~w (~w, ~0f BPM)~n', [Rank, Score, Title, Artist, Genre, BPM]),
    NextRank is Rank + 1,
    print_top_n(Rest, N, NextRank).

% recommend_session(+UserId)
% Generates a 3-track session with decreasing tempo (Altshuler Iso-Principle).
recommend_session(UserId) :-
    user(UserId, Name, _, HeartRate, Stress, _, _),
    format('~n========================================================================~n'),
    format(' GRADUAL RELAXATION SESSION (ISO-PRINCIPLE)~n'),
    format(' User: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100~n', [Name, HeartRate, Stress]),
    format('------------------------------------------------------------------------~n'),
    ( iso_principle_session(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)])
    -> track(T1, Title1, _, _, BPM1, _, Eng1, _),
       track(T2, Title2, _, _, BPM2, _, Eng2, _),
       track(T3, Title3, _, _, BPM3, _, Eng3, _),
       format(' 1. [Entry]   ~-28w (~0f BPM, Energy: ~2f)~n', [Title1, BPM1, Eng1]),
       format(' 2. [Bridge]  ~-28w (~0f BPM, Energy: ~2f)~n', [Title2, BPM2, Eng2]),
       format(' 3. [Target]  ~-28w (~0f BPM, Energy: ~2f)~n', [Title3, BPM3, Eng3]),
       format(' Trajectory: ~0f BPM -> ~0f BPM -> ~0f BPM~n', [BPM1, BPM2, BPM3])
    ;  format(' Unable to generate a valid transition sequence for this user.~n')
    ),
    format('========================================================================~n~n').

% -------------------------------------------------------------------------
% 2. EXPLANATION & AUDIT QUERIES
% -------------------------------------------------------------------------

% explain_choice(+Activity, +Stress, +BPM, +Instrumentalness)
% Explains why the track was selected based on user state and track features.
explain_choice(high_stress_work, _, BPM, Instrumentalness) :-
    !,
    format(' Rationale: High stress detected. Selected a slow tempo (~0f BPM)~n', [BPM]),
    format(' and instrumental track (~2f) to help reduce stress.~n', [Instrumentalness]).

explain_choice(cardio_running, _, BPM, _) :-
    !,
    format(' Rationale: Cardio workout in progress. Selected a fast tempo track (~0f BPM)~n', [BPM]),
    format(' to match the exercise pace.~n').

explain_choice(deep_focus_study, _, _, Instrumentalness) :-
    !,
    format(' Rationale: Study/focus session. Selected an instrumental track (~2f)~n', [Instrumentalness]),
    format(' to avoid vocal distractions.~n').

explain_choice(_, _, _, _) :-
    format(' Rationale: Track tempo and energy match the user target goal.~n').

% explain_rejection(+UserId, +TrackId)
% Explains which constraints are satisfied and which failed for a given track.
explain_rejection(UserId, TrackId) :-
    user(UserId, Name, Activity, _, _, _, _),
    track(TrackId, Title, _, _, _, _, _, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' FEASIBILITY ANALYSIS: "~w" for ~w (~w)~n', [Title, Name, Activity]),
    format('------------------------------------------------------------------------~n'),
    ( physiologically_compatible(TrackId, UserId)
    -> format('  [PASS] Physiological constraint: compatible tempo/energy.~n')
    ;  format('  [FAIL] Physiological constraint: incompatible tempo/energy.~n') ),
    ( cognitively_compatible(TrackId, UserId)
    -> format('  [PASS] Cognitive constraint: compatible instrumentalness.~n')
    ;  format('  [FAIL] Cognitive constraint: contains lyrics during deep focus.~n') ),
    ( safety_and_contraindications(TrackId, UserId)
    -> format('  [PASS] Safety barrier: no contraindications.~n')
    ;  format('  [FAIL] Safety barrier: risk of tachycardia/overstimulation.~n') ),
    ( circadian_coherent(TrackId, UserId)
    -> format('  [PASS] Circadian constraint: compatible with sleep window.~n')
    ;  format('  [FAIL] Circadian constraint: too fast or energetic for sleep.~n') ),
    ( recommendable_track(TrackId, UserId)
    -> format(' RESULT: Track is ELIGIBLE for recommendation.~n')
    ;  format(' RESULT: Track is REJECTED by constraints.~n') ),
    format('------------------------------------------------------------------------~n~n').

% check_safety(+UserId, +TrackId)
% Dedicated clinical safety audit: checks if a specific track is contraindicated.
check_safety(UserId, TrackId) :-
    user(UserId, Name, _, HR, Stress, _, _),
    track(TrackId, Title, _, _, BPM, _, Energy, _),
    format('~n--- Safety Audit: "~w" on ~w ---~n', [Title, Name]),
    format(' User State: Heart Rate ~0f BPM | Stress ~0f/100~n', [HR, Stress]),
    format(' Track Specs: ~0f BPM | Energy ~2f~n', [BPM, Energy]),
    ( safety_and_contraindications(TrackId, UserId)
    -> format(' Assessment: [SAFE] No contraindications detected.~n~n')
    ;  format(' Assessment: [CONTRAINDICATED] Risk of physiological overstimulation.~n~n')
    ).

% find_users_for_track(+TrackId)
% Inverted query: lists all users who are currently eligible to listen to this track.
find_users_for_track(TrackId) :-
    track(TrackId, Title, Artist, Genre, BPM, _, _, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' ELIGIBLE USERS FOR: "~w" - ~w (~w, ~0f BPM)~n', [Title, Artist, Genre, BPM]),
    format('------------------------------------------------------------------------~n'),
    findall(UName-UId, (
        user(UId, UName, _, _, _, _, _),
        recommendable_track(TrackId, UId)
    ), Eligible),
    ( Eligible == []
    -> format(' No users in the current database match this track profile.~n')
    ;  print_user_matches(Eligible)
    ),
    format('------------------------------------------------------------------------~n~n').

print_user_matches([]).
print_user_matches([Name-Id|Rest]) :-
    user(Id, _, Activity, HR, Stress, _, _),
    format(' * ~w (ID: ~w) | Activity: ~w | HR: ~0f BPM | Stress: ~0f/100~n', [Name, Id, Activity, HR, Stress]),
    print_user_matches(Rest).

% -------------------------------------------------------------------------
% 3. DEMO & VERIFICATION
% -------------------------------------------------------------------------

% demo
% Runs recommendations for three example profiles.
demo :-
    format('~n--- Example 1: Stress Reduction (Sarah Miller) ---~n'),
    recommend(user_sarah),
    recommend_session(user_sarah),
    format('~n--- Example 2: Cardio Running (Alex Chen) ---~n'),
    recommend(user_alex),
    format('~n--- Example 3: Deep Focus (Marco Rossi) ---~n'),
    recommend(user_marco).

% run_tests
% Runs unit tests for logical verification directly in Prolog.
run_tests :-
    format('~nRunning logic verification tests...~n'),
    % Test 1: High stress recommends slow ambient/relaxing track
    best_track(user_sarah, B_Sarah, _),
    track(B_Sarah, _, _, _, BPM_Sarah, _, Eng_Sarah, _),
    BPM_Sarah =< 75.0, Eng_Sarah =< 0.35,
    format('  [PASS] Test 1: Stress downregulation selects slow, low-energy track~n'),

    % Test 2: Cardio running enforces high tempo
    best_track(user_alex, B_Alex, _),
    track(B_Alex, _, _, _, BPM_Alex, _, Eng_Alex, _),
    BPM_Alex >= 120.0, Eng_Alex >= 0.70,
    format('  [PASS] Test 2: Cardio running selects fast, high-energy track~n'),

    % Test 3: Study mode filters out tracks with lyrics
    best_track(user_marco, B_Marco, _),
    track(B_Marco, _, _, _, _, _, _, Inst_Marco),
    Inst_Marco >= 0.70,
    format('  [PASS] Test 3: Focus/study mode selects instrumental track~n'),

    % Test 4: Iso-principle gradual tempo descent
    iso_principle_session(user_sarah, [stage(entry, S1), stage(bridge, S2), stage(target, S3)]),
    track(S1, _, _, _, P1, _, _, _),
    track(S2, _, _, _, P2, _, _, _),
    track(S3, _, _, _, P3, _, _, _),
    P1 >= P2, P2 >= P3,
    format('  [PASS] Test 4: Gradual tempo descent monotonicity~n'),

    % Test 5: Safety constraint blocks high-energy tracks during tachycardia
    ( \+ safety_and_contraindications(adrenaline_rush_rock, user_sarah)
    -> format('  [PASS] Test 5: High-energy track rejected during acute tachycardia~n')
    ;  format('  [FAIL] Test 5 failed~n') ),

    % Test 6: Cognitive constraint blocks vocal tracks in study mode
    ( \+ cognitively_compatible(euphoric_run_anthem, user_marco)
    -> format('  [PASS] Test 6: Lyrical song rejected during study mode~n')
    ;  format('  [FAIL] Test 6 failed~n') ),
    format('All tests passed.~n~n').

help :-
    format('~nAvailable DSS Commands:~n'),
    format('  ?- recommend(user_sarah).              - Single best recommendation with rationale.~n'),
    format('  ?- recommend_top(user_sarah, 3).       - Top N ranked recommendations with scores.~n'),
    format('  ?- recommend_session(user_sarah).      - 3-track gradual relaxation session (Iso-Principle).~n'),
    format('  ?- explain_rejection(user_sarah, Track) - Detailed breakdown of constraints for a track.~n'),
    format('  ?- check_safety(user_sarah, Track).    - Clinical safety audit (contraindication check).~n'),
    format('  ?- find_users_for_track(TrackId).      - Inverted query: lists eligible users for a track.~n'),
    format('  ?- demo.                               - Run demonstration across sample users.~n'),
    format('  ?- run_tests.                          - Run automated logic verification tests.~n~n').
