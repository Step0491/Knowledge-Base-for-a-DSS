% =========================================================================
% Decision Support System (DSS) - Music Recommendation Rules
% =========================================================================

:- consult('knowledge_base.pl').

% --- Track recommendation filter ---

% A track is recommendable if it satisfies physiological, cognitive,
% safety, and time/sleep constraints for the given user.
recommendable_track(TrackId, UserId) :-
    physiologically_compatible(TrackId, UserId),
    cognitively_compatible(TrackId, UserId),
    safety_and_contraindications(TrackId, UserId),
    circadian_coherent(TrackId, UserId).

% --- Activity and physiological constraints ---

% High stress / elevated heart rate: select calming tracks
physiologically_compatible(TrackId, UserId) :-
    acute_sympathetic_state(UserId),
    !,
    sedative_track(TrackId).

% Running / cardio workout: select high energy/tempo tracks
physiologically_compatible(TrackId, UserId) :-
    cardio_aerobic_regime(UserId),
    !,
    ergogenic_track(TrackId).

% Sleep preparation: select low BPM and low energy tracks
physiologically_compatible(TrackId, UserId) :-
    sleep_induction_state(UserId),
    !,
    somnolent_track(TrackId).

% Default / general routine: moderate tempo and balanced energy
physiologically_compatible(TrackId, UserId) :-
    homeostatic_state(UserId),
    moderate_activation_track(TrackId).

% User state detection
acute_sympathetic_state(UserId) :-
    user(UserId, _, _, HR, Stress, Goal, _),
    ( Goal == stress_downregulation
    ; elevated_heart_rate(HR), critical_stress(Stress) ).

cardio_aerobic_regime(UserId) :-
    user(UserId, _, Activity, HR, _, Goal, _),
    ( Goal == cardio_peak_performance
    ; Activity == cardio_running, HR >= 120.0 ).

sleep_induction_state(UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( Goal == sleep_induction
    ; Activity == sleep_preparation ).

homeostatic_state(UserId) :-
    \+ acute_sympathetic_state(UserId),
    \+ cardio_aerobic_regime(UserId),
    \+ sleep_induction_state(UserId).

% Track profile categories
sedative_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    slow_tempo(BPM),
    low_energy(Energy),
    Instrumentalness >= 0.70.

ergogenic_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, _),
    fast_tempo(BPM),
    high_energy(Energy).

somnolent_track(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    BPM =< 64.0,
    Energy =< 0.20,
    Instrumentalness >= 0.85.

moderate_activation_track(TrackId) :-
    track(TrackId, _, _, _, BPM, Valence, Energy, _),
    BPM >= 70.0, BPM =< 115.0,
    Energy =< 0.65,
    Valence >= 0.40.

% --- Cognitive / Focus constraints ---

% When studying or in deep focus, enforce instrumental music
cognitively_compatible(TrackId, UserId) :-
    requires_cognitive_focus(UserId),
    !,
    phonological_loop_protection(TrackId).

cognitively_compatible(_, _).

requires_cognitive_focus(UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( Activity == deep_focus_study ; Goal == deep_focus_flow ).

phonological_loop_protection(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    Instrumentalness >= 0.70,   % Mostly instrumental (no vocal distraction)
    BPM >= 70.0, BPM =< 95.0,
    Energy =< 0.55.

% --- Safety and contraindications ---

safety_and_contraindications(TrackId, UserId) :-
    \+ tachycardia_contraindication(TrackId, UserId),
    \+ overstimulation_contraindication(TrackId, UserId).

% Avoid high-tempo or high-energy tracks if user has high heart rate and high stress
tachycardia_contraindication(TrackId, UserId) :-
    user(UserId, _, _, HR, Stress, _, _),
    HR > 110.0,
    Stress > 75.0,
    track(TrackId, _, _, _, BPM, _, Energy, _),
    ( BPM > 100.0 ; Energy > 0.60 ).

% Avoid loud/intense tracks when already fatigued or stressed at work
overstimulation_contraindication(TrackId, UserId) :-
    user(UserId, _, Activity, _, Stress, _, _),
    Activity == high_stress_work,
    Stress > 80.0,
    track(TrackId, _, _, _, _, _, Energy, _),
    Energy > 0.50.

% --- Sleep / Circadian constraints ---

% Avoid fast or energetic music when preparing for sleep
circadian_coherent(TrackId, UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( (Activity == sleep_preparation ; Goal == sleep_induction)
    -> track(TrackId, _, _, _, BPM, _, Energy, _),
       BPM =< 68.0,
       Energy =< 0.30
    ;  true
    ).

% --- Thresholds ---

elevated_heart_rate(HR) :- HR >= 100.0.
critical_stress(S)      :- S >= 65.0.
slow_tempo(BPM)         :- BPM =< 75.0.
fast_tempo(BPM)         :- BPM >= 120.0.
low_energy(E)           :- E =< 0.35.
high_energy(E)          :- E >= 0.70.

% --- Multi-attribute utility scoring ---

% Calculates track score based on target BPM proximity, preferred genre, and valence.
calculate_utility(TrackId, UserId, FinalScore) :-
    user(UserId, _, _, _, _, Goal, PreferredGenres),
    track(TrackId, _, _, Genre, BPM, Valence, _, Instrumentalness),

    ideal_target_bpm(Goal, TargetBPM),
    DeltaBPM is abs(BPM - TargetBPM),
    FrequencyScore is max(20.0, 100.0 - (DeltaBPM * 1.5)),

    ( member(Genre, PreferredGenres) -> GenreBonus = 25.0 ; GenreBonus = 0.0 ),

    AffectiveScore is (Valence * 15.0) + (Instrumentalness * 10.0),
    RawUtility is (FrequencyScore * 0.50) + GenreBonus + AffectiveScore,
    FinalScore is min(100.0, RawUtility).

ideal_target_bpm(stress_downregulation, 65.0).
ideal_target_bpm(cardio_peak_performance, 145.0).
ideal_target_bpm(deep_focus_flow, 80.0).
ideal_target_bpm(sleep_induction, 55.0).
ideal_target_bpm(post_workout_recovery, 80.0).
ideal_target_bpm(active_commute_energizer, 110.0).

% Selects the recommendable track with the highest score
best_track(UserId, BestTrackId, MaxScore) :-
    findall(Score-TId, (
        recommendable_track(TId, UserId),
        calculate_utility(TId, UserId, Score)
    ), Candidates),
    Candidates \= [],
    sort(1, @>=, Candidates, [MaxScore-BestTrackId|_]).

% --- Iso-Principle: gradual tempo transition ---

% Generates a 3-track session for stress reduction:
% 1. Entry: starts close to user's current heart rate (+/- 18 BPM).
% 2. Bridge: intermediate tempo (80-95 BPM).
% 3. Target: slow relaxing tempo (<= 68 BPM).
iso_principle_session(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)]) :-
    user(UserId, _, _, CurrentHR, _, _, _),

    % Entry track
    track(T1, _, _, _, BPM1, _, _, _),
    abs(BPM1 - CurrentHR) =< 18.0,

    % Bridge track
    track(T2, _, _, _, BPM2, _, Eng2, _),
    BPM2 >= 80.0, BPM2 =< 95.0,
    Eng2 =< 0.50,
    T2 \= T1,

    % Target track
    track(T3, _, _, _, BPM3, _, Eng3, _),
    BPM3 =< 68.0,
    Eng3 =< 0.25,
    T3 \= T1, T3 \= T2,

    % Tempo must decrease gradually
    BPM1 >= BPM2,
    BPM2 >= BPM3,
    !.
