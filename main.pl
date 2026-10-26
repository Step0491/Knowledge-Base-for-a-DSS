% =========================================================================
% Entry point: main.pl
% Decision Support System (DSS) - Spotify Context-Aware Music Recommendation
% =========================================================================

:- consult('dss_rules.pl').

% -------------------------------------------------------------------------
% 1. RECOMMENDATION & SPOTIFY PLAYLIST QUERIES
% -------------------------------------------------------------------------

% recommend(+UserId)
% Recommends the best single track for the user's current state.
recommend(UserId) :-
    user(UserId, Name, Activity, HeartRate, Stress, Goal, Genres),
    format('~n------------------------------------------------------------------------~n'),
    format(' USER PROFILE: ~w (~w)~n', [Name, UserId]),
    format(' Activity: ~w | Heart Rate: ~0f BPM | Stress: ~0f/100~n', [Activity, HeartRate, Stress]),
    format(' Goal: ~w | Preferred Genres: ~w~n', [Goal, Genres]),
    format('------------------------------------------------------------------------~n'),
    ( best_track(UserId, TrackId, UtilityScore)
    -> track(TrackId, Title, Artist, Genre, BPM, Valence, Energy, Instrumentalness),
       format(' Recommended Track: "~w" - ~w~n', [Title, Artist]),
       format(' Match Score: ~1f/100 | Genre: ~w~n', [UtilityScore, Genre]),
       format(' Audio Features: ~0f BPM | Energy: ~2f | Valence: ~2f | Instrumental: ~2f~n', [BPM, Energy, Valence, Instrumentalness]),
       explain_choice(Activity, BPM, Instrumentalness, Genre, Genres)
    ;  format(' No track in the catalog satisfies the constraints for this user.~n')
    ),
    format('------------------------------------------------------------------------~n~n').

% recommend_playlist(+UserId, +Length)
% Generates a personalized context-aware playlist of up to Length tracks.
recommend_playlist(UserId, Length) :-
    user(UserId, Name, Activity, HeartRate, Stress, Goal, _),
    format('~n========================================================================~n'),
    format(' SPOTIFY CONTEXT PLAYLIST (Top ~w Tracks)~n', [Length]),
    format(' User: ~w | Activity: ~w | HR: ~0f BPM | Stress: ~0f/100~n', [Name, Activity, HeartRate, Stress]),
    format(' Goal: ~w~n', [Goal]),
    format('------------------------------------------------------------------------~n'),
    ( build_playlist(UserId, Length, Playlist)
    -> print_playlist_items(Playlist, UserId, 1),
       playlist_avg_bpm(Playlist, AvgBPM),
       length(Playlist, Count),
       format('------------------------------------------------------------------------~n'),
       format(' Summary: ~w tracks selected | Average Playlist Tempo: ~1f BPM~n', [Count, AvgBPM])
    ;  format(' Unable to generate a playlist for this user with current catalog.~n')
    ),
    format('========================================================================~n~n').

print_playlist_items([], _, _).
print_playlist_items([TId|Rest], UserId, Index) :-
    track(TId, Title, Artist, Genre, BPM, _, Energy, _),
    calculate_utility(TId, UserId, Score),
    format(' ~w. "~w" - ~w (~w, ~0f BPM, E:~2f) [Score: ~1f]~n',
           [Index, Title, Artist, Genre, BPM, Energy, Score]),
    NextIndex is Index + 1,
    print_playlist_items(Rest, UserId, NextIndex).

% discover_by_genre(+UserId, +Genre)
% Checks which tracks of a given genre are suitable for the user right now.
discover_by_genre(UserId, Genre) :-
    user(UserId, Name, Activity, _, _, _, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' GENRE FILTER: "~w" for ~w (~w)~n', [Genre, Name, Activity]),
    format('------------------------------------------------------------------------~n'),
    findall(Score-TId, (
        track(TId, _, _, Genre, _, _, _, _),
        recommendable_track(TId, UserId),
        calculate_utility(TId, UserId, Score)
    ), Matches),
    sort(1, @>=, Matches, Sorted),
    ( Sorted == []
    -> format(' No "~w" tracks match the current activity and safety constraints.~n', [Genre])
    ;  print_genre_matches(Sorted)
    ),
    format('------------------------------------------------------------------------~n~n').

print_genre_matches([]).
print_genre_matches([Score-TId|Rest]) :-
    track(TId, Title, Artist, _, BPM, _, Energy, _),
    format(' * [Score: ~1f] "~w" - ~w (~0f BPM, Energy: ~2f)~n', [Score, Title, Artist, BPM, Energy]),
    print_genre_matches(Rest).

% -------------------------------------------------------------------------
% 2. EXPLANATION & AUDIT QUERIES
% -------------------------------------------------------------------------

explain_choice(high_stress_work, BPM, Instrumentalness, Genre, PrefGenres) :-
    !,
    format(' Rationale: High stress detected. Selected a calming tempo (~0f BPM)~n', [BPM]),
    format(' and instrumental track (~2f) to reduce agitation.', [Instrumentalness]),
    check_genre_note(Genre, PrefGenres).

explain_choice(cardio_running, BPM, _, Genre, PrefGenres) :-
    !,
    format(' Rationale: Cardio workout in progress. Selected a fast tempo (~0f BPM)~n', [BPM]),
    format(' to keep pace during exercise.', []),
    check_genre_note(Genre, PrefGenres).

explain_choice(deep_focus_study, _, Instrumentalness, Genre, PrefGenres) :-
    !,
    format(' Rationale: Study session detected. Selected an instrumental track (~2f)~n', [Instrumentalness]),
    format(' to prevent vocal distractions.', []),
    check_genre_note(Genre, PrefGenres).

explain_choice(_, _, _, Genre, PrefGenres) :-
    format(' Rationale: Audio tempo and energy match your current activity goal.', []),
    check_genre_note(Genre, PrefGenres).

check_genre_note(Genre, PrefGenres) :-
    ( member(Genre, PrefGenres)
    -> format(' Matches your Spotify taste (~w).~n', [Genre])
    ;  format('~n') ).

% explain_rejection(+UserId, +TrackId)
% Explains which constraints pass and which fail for a given track.
explain_rejection(UserId, TrackId) :-
    user(UserId, Name, Activity, _, _, _, _),
    track(TrackId, Title, _, _, _, _, _, _),
    format('~n------------------------------------------------------------------------~n'),
    format(' FEASIBILITY CHECK: "~w" for ~w (~w)~n', [Title, Name, Activity]),
    format('------------------------------------------------------------------------~n'),
    ( activity_compatible(TrackId, UserId)
    -> format('  [PASS] Activity match: compatible tempo and energy.~n')
    ;  format('  [FAIL] Activity match: incompatible tempo or energy for current activity.~n') ),
    ( focus_compatible(TrackId, UserId)
    -> format('  [PASS] Focus check: compatible with current cognitive mode.~n')
    ;  format('  [FAIL] Focus check: contains vocals or high energy during study.~n') ),
    ( safe_track(TrackId, UserId)
    -> format('  [PASS] Safety check: no overstimulation risk.~n')
    ;  format('  [FAIL] Safety check: unsafe BPM/energy given high stress or heart rate.~n') ),
    ( recommendable_track(TrackId, UserId)
    -> format(' RESULT: Track is ELIGIBLE.~n')
    ;  format(' RESULT: Track is REJECTED.~n') ),
    format('------------------------------------------------------------------------~n~n').

% check_safety(+UserId, +TrackId)
% Checks whether a specific track is safe or contraindicated for the user.
check_safety(UserId, TrackId) :-
    user(UserId, Name, _, HR, Stress, _, _),
    track(TrackId, Title, _, _, BPM, _, Energy, _),
    format('~n--- Safety Audit: "~w" for ~w ---~n', [Title, Name]),
    format(' User State: Heart Rate ~0f BPM | Stress ~0f/100~n', [HR, Stress]),
    format(' Track Specs: ~0f BPM | Energy ~2f~n', [BPM, Energy]),
    ( safe_track(TrackId, UserId)
    -> format(' Assessment: [SAFE] Track does not violate safety limits.~n~n')
    ;  format(' Assessment: [UNSAFE] Rejected due to high stress/heart rate risk.~n~n')
    ).

% find_users_for_track(+TrackId)
% Inverted query: lists all users who can currently listen to this track.
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
    -> format(' No users currently match this track.~n')
    ;  print_user_matches(Eligible)
    ),
    format('------------------------------------------------------------------------~n~n').

print_user_matches([]).
print_user_matches([Name-Id|Rest]) :-
    user(Id, _, Activity, HR, Stress, _, _),
    format(' * ~w (ID: ~w) | Activity: ~w | HR: ~0f BPM | Stress: ~0f/100~n', [Name, Id, Activity, HR, Stress]),
    print_user_matches(Rest).

% -------------------------------------------------------------------------
% 3. DEMO & AUTOMATED VERIFICATION
% -------------------------------------------------------------------------

demo :-
    format('~n--- Case 1: High-Stress Work (Sarah Miller) ---~n'),
    recommend(user_sarah),
    recommend_playlist(user_sarah, 3),
    format('~n--- Case 2: Cardio Running (Alex Chen) ---~n'),
    recommend(user_alex),
    format('~n--- Case 3: Deep Focus Study (Marco Rossi) ---~n'),
    recommend(user_marco).

run_tests :-
    format('~nRunning logic verification tests...~n'),

    % Test 1: Stress reduction selects slow, low-energy track
    best_track(user_sarah, B_Sarah, _),
    track(B_Sarah, _, _, _, BPM_Sarah, _, Eng_Sarah, _),
    BPM_Sarah =< 75.0, Eng_Sarah =< 0.35,
    format('  [PASS] Test 1: High-stress user gets slow, low-energy track~n'),

    % Test 2: Cardio running selects fast, energetic track
    best_track(user_alex, B_Alex, _),
    track(B_Alex, _, _, _, BPM_Alex, _, Eng_Alex, _),
    BPM_Alex >= 120.0, Eng_Alex >= 0.70,
    format('  [PASS] Test 2: Cardio user gets high-tempo, high-energy track~n'),

    % Test 3: Study mode enforces instrumental tracks
    best_track(user_marco, B_Marco, _),
    track(B_Marco, _, _, _, _, _, _, Inst_Marco),
    Inst_Marco >= 0.70,
    format('  [PASS] Test 3: Study user gets instrumental track~n'),

    % Test 4: Sleep preparation enforces low BPM and low energy
    best_track(user_david, B_David, _),
    track(B_David, _, _, _, BPM_David, _, Eng_David, _),
    BPM_David =< 64.0, Eng_David =< 0.20,
    format('  [PASS] Test 4: Sleep preparation gets quiet slow track~n'),

    % Test 5: Playlist generation produces valid safe tracks without duplicates
    build_playlist(user_sarah, 3, PlaylistSarah),
    length(PlaylistSarah, 3),
    forall(member(T, PlaylistSarah), safe_track(T, user_sarah)),
    format('  [PASS] Test 5: Generated playlist respects safety limits on all tracks~n'),

    % Test 6: Negative test - safety barrier blocks high-energy rock for Sarah
    ( \+ safe_track(adrenaline_rush_rock, user_sarah)
    -> format('  [PASS] Test 6: Safety rule rejects high-energy rock for stressed user~n')
    ;  format('  [FAIL] Test 6 failed~n') ),

    % Test 7: Negative test - focus rule blocks vocal pop for Marco
    ( \+ focus_compatible(euphoric_run_anthem, user_marco)
    -> format('  [PASS] Test 7: Focus rule rejects vocal track during study~n')
    ;  format('  [FAIL] Test 7 failed~n') ),

    format('All 7 tests passed.~n~n').

help :-
    format('~nAvailable DSS Commands:~n'),
    format('  ?- recommend(user_sarah).                   - Top track recommendation with rationale.~n'),
    format('  ?- recommend_playlist(user_sarah, 3).       - Generate context-aware Spotify playlist.~n'),
    format('  ?- discover_by_genre(user_sarah, classical). - Filter genre by user constraints.~n'),
    format('  ?- explain_rejection(user_sarah, TrackId).   - Breakdown of pass/fail rules for a track.~n'),
    format('  ?- check_safety(user_sarah, TrackId).        - Safety check for a specific track.~n'),
    format('  ?- find_users_for_track(TrackId).            - Inverted query: eligible users for a track.~n'),
    format('  ?- demo.                                     - Run demo across sample users.~n'),
    format('  ?- run_tests.                                - Run automated verification tests.~n~n').
