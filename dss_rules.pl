% =========================================================================
% Decision Support System (DSS) - Spotify Context-Aware Music Rules
% =========================================================================

:- consult('knowledge_base.pl').

% --- 1. Main Feasibility Rule ---

% recommendable_track(?TrackId, ?UserId)
% A track is eligible for a user if it matches their activity context,
% satisfies focus requirements (when studying), and passes safety checks.
recommendable_track(TrackId, UserId) :-
    track(TrackId, _, _, _, _, _, _, _),
    user(UserId, _, _, _, _, _, _),
    activity_compatible(TrackId, UserId),
    focus_compatible(TrackId, UserId),
    safe_track(TrackId, UserId).

% --- 2. Activity & Biometric Context Rules ---

% Matches track profile to the user's current activity and biometric state.
% Cuts (!) ensure mutually exclusive state classification.

activity_compatible(TrackId, UserId) :-
    high_stress_user(UserId),
    !,
    relaxing_track(TrackId).

activity_compatible(TrackId, UserId) :-
    workout_user(UserId),
    !,
    workout_track(TrackId).

activity_compatible(TrackId, UserId) :-
    sleep_user(UserId),
    !,
    sleep_track(TrackId).

activity_compatible(TrackId, UserId) :-
    normal_state_user(UserId),
    moderate_track(TrackId).

% User state classification
high_stress_user(UserId) :-
    user(UserId, _, _, HR, Stress, Goal, _),
    ( Goal == stress_downregulation
    ; high_heart_rate(HR), high_stress(Stress) ).

workout_user(UserId) :-
    user(UserId, _, Activity, HR, _, Goal, _),
    ( Goal == cardio_peak_performance
    ; Activity == cardio_running, HR >= 120.0 ).

sleep_user(UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( Goal == sleep_induction
    ; Activity == sleep_preparation ).

normal_state_user(UserId) :-
    \+ high_stress_user(UserId),
    \+ workout_user(UserId),
    \+ sleep_user(UserId).

% Audio track profiles
relaxing_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    slow_tempo(BPM),
    low_energy(Energy),
    Instrumentalness >= 0.70.

workout_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, _),
    fast_tempo(BPM),
    high_energy(Energy).

sleep_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    BPM =< 64.0,
    Energy =< 0.20,
    Instrumentalness >= 0.85.

moderate_track(TrackId) :-
    track(TrackId, _, _, _, BPM, Valence, Energy, _),
    BPM >= 70.0, BPM =< 115.0,
    Energy =< 0.65,
    Valence >= 0.40.

% --- 3. Focus & Study Constraint ---

% Enforces instrumental music without distracting lyrics during study/deep focus.
focus_compatible(TrackId, UserId) :-
    focus_user(UserId),
    !,
    instrumental_focus_track(TrackId).

focus_compatible(_, _).

focus_user(UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( Activity == deep_focus_study ; Goal == deep_focus_flow ).

instrumental_focus_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    Instrumentalness >= 0.70,
    BPM >= 70.0, BPM =< 95.0,
    Energy =< 0.55.

% --- 4. Safety Constraints (Negation as Failure) ---

% safe_track(+TrackId, +UserId)
% Blocks tracks that could worsen high stress or elevated heart rate.
safe_track(TrackId, UserId) :-
    \+ unsafe_track(TrackId, UserId).

unsafe_track(TrackId, UserId) :-
    user(UserId, _, _, HR, Stress, _, _),
    HR > 110.0,
    Stress > 75.0,
    track(TrackId, _, _, _, BPM, _, Energy, _),
    ( BPM > 100.0 ; Energy > 0.60 ).

unsafe_track(TrackId, UserId) :-
    user(UserId, _, Activity, _, Stress, _, _),
    Activity == high_stress_work,
    Stress > 80.0,
    track(TrackId, _, _, _, _, _, Energy, _),
    Energy > 0.50.

% --- 5. Domain Thresholds ---

high_heart_rate(HR) :- HR >= 100.0.
high_stress(S)      :- S >= 65.0.
slow_tempo(BPM)     :- BPM =< 75.0.
fast_tempo(BPM)     :- BPM >= 120.0.
low_energy(E)       :- E =< 0.35.
high_energy(E)      :- E >= 0.70.

% --- 6. Spotify Scoring & Ranking (Multi-Attribute Utility) ---

% calculate_utility(+TrackId, +UserId, -Score)
% Computes a 0-100 score combining:
%   - Tempo alignment with goal (up to 50 pts)
%   - Spotify user genre affinity (25 pts)
%   - Mood valence & instrumentalness (up to 25 pts)
calculate_utility(TrackId, UserId, FinalScore) :-
    user(UserId, _, _, _, _, Goal, PreferredGenres),
    track(TrackId, _, _, Genre, BPM, Valence, _, Instrumentalness),

    ideal_target_bpm(Goal, TargetBPM),
    DeltaBPM is abs(BPM - TargetBPM),
    TempoScore is max(20.0, 100.0 - (DeltaBPM * 1.5)),

    ( member(Genre, PreferredGenres) -> GenreBonus = 25.0 ; GenreBonus = 0.0 ),

    MoodScore is (Valence * 15.0) + (Instrumentalness * 10.0),
    RawScore is (TempoScore * 0.50) + GenreBonus + MoodScore,
    FinalScore is min(100.0, RawScore).

ideal_target_bpm(stress_downregulation, 65.0).
ideal_target_bpm(cardio_peak_performance, 145.0).
ideal_target_bpm(deep_focus_flow, 80.0).
ideal_target_bpm(sleep_induction, 55.0).
ideal_target_bpm(post_workout_recovery, 80.0).
ideal_target_bpm(active_commute_energizer, 110.0).

% ranked_tracks(+UserId, -SortedCandidates)
% Collects and sorts all eligible tracks by utility score (descending).
ranked_tracks(UserId, SortedCandidates) :-
    findall(Score-TId, (
        recommendable_track(TId, UserId),
        calculate_utility(TId, UserId, Score)
    ), Candidates),
    Candidates \= [],
    sort(1, @>=, Candidates, SortedCandidates).

% best_track(+UserId, -BestTrackId, -MaxScore)
% Returns the top scoring recommendable track for the user.
best_track(UserId, BestTrackId, MaxScore) :-
    ranked_tracks(UserId, [MaxScore-BestTrackId|_]).

% --- 7. Context-Aware Playlist Generation (Recursive List Processing) ---

% build_playlist(+UserId, +MaxLength, -Playlist)
% Builds a personalized Spotify playlist of up to MaxLength eligible tracks
% without duplicates, ordered by descending utility score.
build_playlist(UserId, MaxLength, Playlist) :-
    ranked_tracks(UserId, SortedCandidates),
    take_top_tracks(SortedCandidates, MaxLength, [], Playlist).

take_top_tracks([], _, _, []) :- !.
take_top_tracks(_, N, _, []) :- N =< 0, !.
take_top_tracks([_-TId|Rest], N, Seen, [TId|Tail]) :-
    \+ member(TId, Seen),
    !,
    N1 is N - 1,
    take_top_tracks(Rest, N1, [TId|Seen], Tail).
take_top_tracks([_|Rest], N, Seen, Tail) :-
    take_top_tracks(Rest, N, Seen, Tail).

% playlist_avg_bpm(+Playlist, -AvgBPM)
% Recursively calculates the average BPM of a generated playlist.
playlist_avg_bpm([], 0.0) :- !.
playlist_avg_bpm(Playlist, AvgBPM) :-
    sum_playlist_bpm(Playlist, TotalBPM, Count),
    Count > 0,
    AvgBPM is TotalBPM / Count.

sum_playlist_bpm([], 0.0, 0).
sum_playlist_bpm([TId|Rest], TotalBPM, Count) :-
    track(TId, _, _, _, BPM, _, _, _),
    sum_playlist_bpm(Rest, SubTotal, SubCount),
    TotalBPM is BPM + SubTotal,
    Count is SubCount + 1.
