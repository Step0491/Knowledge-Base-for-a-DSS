% =========================================================================
% HIERARCHICAL DECISION RULES: dss_rules.pl
% Knowledge-Based Decision Support System (M.Sc. in Computer Science)
% AND-OR Goal Tree Architecture (Backward Chaining Inference)
% =========================================================================

:- consult('knowledge_base.pl').

% -------------------------------------------------------------------------
% LEVEL 0: META-RULE OF OVERALL FEASIBILITY
% -------------------------------------------------------------------------

%! recommendable_track(+TrackId, +UserId)
% A track is recommendable if and only if it simultaneously satisfies
% all 4 orthogonal evaluation pillars of the expert system.
recommendable_track(TrackId, UserId) :-
    physiologically_compatible(TrackId, UserId),
    cognitively_compatible(TrackId, UserId),
    safety_and_contraindications(TrackId, UserId),
    circadian_coherent(TrackId, UserId).

% -------------------------------------------------------------------------
% LEVEL 1: PHYSIOLOGICAL & BIOMETRIC PILLAR
% -------------------------------------------------------------------------

%! physiologically_compatible(+TrackId, +UserId)
% Evaluates autonomic synchronization between the user's state and audio attributes.

% Case 1: Acute sympathetic arousal (Elevated Heart Rate / Stress) -> Sedative Track
physiologically_compatible(TrackId, UserId) :-
    acute_sympathetic_state(UserId),
    !,
    sedative_track(TrackId).

% Case 2: Intense aerobic cardio workout (Running) -> Ergogenic Track
physiologically_compatible(TrackId, UserId) :-
    cardio_aerobic_regime(UserId),
    !,
    ergogenic_track(TrackId).

% Case 3: Somnolence / sleep preparation -> Somnolent Track
physiologically_compatible(TrackId, UserId) :-
    sleep_induction_state(UserId),
    !,
    somnolent_track(TrackId).

% Case 4: Homeostatic baseline / active commute / recovery -> Moderate Activation Track
physiologically_compatible(TrackId, UserId) :-
    homeostatic_state(UserId),
    moderate_activation_track(TrackId).

% --- LEVEL 2 SUB-RULES: Physiological State Recognition ---

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

% --- LEVEL 3 SUB-RULES: Functional Acoustic Properties ---

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

% -------------------------------------------------------------------------
% LEVEL 1: COGNITIVE PILLAR (WORKING MEMORY PROTECTION)
% -------------------------------------------------------------------------

%! cognitively_compatible(+TrackId, +UserId)
% During cognitively demanding tasks, protects the phonological loop from lyrical interference.

cognitively_compatible(TrackId, UserId) :-
    requires_cognitive_focus(UserId),
    !,
    phonological_loop_protection(TrackId).

cognitively_compatible(_, _). % No cognitive constraint if not studying

requires_cognitive_focus(UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( Activity == deep_focus_study ; Goal == deep_focus_flow ).

phonological_loop_protection(TrackId) :-
    track(TrackId, _, _, _, BPM, _, Energy, Instrumentalness),
    Instrumentalness >= 0.70,   % Strict absence of vocal lyrics
    BPM >= 70.0, BPM =< 95.0,   % Tempo aligned with alpha EEG band
    Energy =< 0.55.

% -------------------------------------------------------------------------
% LEVEL 1: MEDICAL SAFETY & CONTRAINDICATION PILLAR
% -------------------------------------------------------------------------

%! safety_and_contraindications(+TrackId, +UserId)
% Negative barrier rules preventing adverse physiological overstimulation.

safety_and_contraindications(TrackId, UserId) :-
    \+ tachycardia_contraindication(TrackId, UserId),
    \+ overstimulation_contraindication(TrackId, UserId).

% Contraindication 1: Prohibit high-arousal tracks if user exhibits tachycardia & critical stress
tachycardia_contraindication(TrackId, UserId) :-
    user(UserId, _, _, HR, Stress, _, _),
    HR > 110.0,
    Stress > 75.0,
    track(TrackId, _, _, _, BPM, _, Energy, _),
    ( BPM > 100.0 ; Energy > 0.60 ).

% Contraindication 2: Prohibit high energy tracks during severe exhaustion
overstimulation_contraindication(TrackId, UserId) :-
    user(UserId, _, Activity, _, Stress, _, _),
    Activity == high_stress_work,
    Stress > 80.0,
    track(TrackId, _, _, _, _, _, Energy, _),
    Energy > 0.50.

% -------------------------------------------------------------------------
% LEVEL 1: CIRCADIAN COHERENCE PILLAR (BIOLOGICAL CLOCK)
% -------------------------------------------------------------------------

%! circadian_coherent(+TrackId, +UserId)
% Enforces tempo and acoustic ceilings during sleep induction windows.

circadian_coherent(TrackId, UserId) :-
    user(UserId, _, Activity, _, _, Goal, _),
    ( (Activity == sleep_preparation ; Goal == sleep_induction)
    -> track(TrackId, _, _, _, BPM, _, Energy, _),
       BPM =< 68.0,
       Energy =< 0.30
    ;  true
    ).

% -------------------------------------------------------------------------
% LEVEL 3: PRIMITIVES & PHYSIOLOGICAL THRESHOLDS
% -------------------------------------------------------------------------

elevated_heart_rate(HR) :- HR >= 100.0.
critical_stress(S)      :- S >= 65.0.
slow_tempo(BPM)         :- BPM =< 75.0.
fast_tempo(BPM)         :- BPM >= 120.0.
low_energy(E)           :- E =< 0.35.
high_energy(E)          :- E >= 0.70.

% -------------------------------------------------------------------------
% LEVEL 4: MULTI-ATTRIBUTE UTILITY SCORING
% -------------------------------------------------------------------------

%! calculate_utility(+TrackId, +UserId, -FinalScore)
% Combines physiological proximity, affective valence, and user genre affinity.
calculate_utility(TrackId, UserId, FinalScore) :-
    user(UserId, _, _, _, _, Goal, PreferredGenres),
    track(TrackId, _, _, Genre, BPM, Valence, _, Instrumentalness),

    % Delta from ideal goal target tempo
    ideal_target_bpm(Goal, TargetBPM),
    DeltaBPM is abs(BPM - TargetBPM),
    FrequencyScore is max(20.0, 100.0 - (DeltaBPM * 1.5)),

    % Genre preference bonus
    ( member(Genre, PreferredGenres) -> GenreBonus = 25.0 ; GenreBonus = 0.0 ),

    % Affective and instrumentalness bonus
    AffectiveScore is (Valence * 15.0) + (Instrumentalness * 10.0),

    RawUtility is (FrequencyScore * 0.50) + GenreBonus + AffectiveScore,
    FinalScore is min(100.0, RawUtility).

ideal_target_bpm(stress_downregulation, 65.0).
ideal_target_bpm(cardio_peak_performance, 145.0).
ideal_target_bpm(deep_focus_flow, 80.0).
ideal_target_bpm(sleep_induction, 55.0).
ideal_target_bpm(post_workout_recovery, 80.0).
ideal_target_bpm(active_commute_energizer, 110.0).

%! best_track(+UserId, -BestTrackId, -MaxScore)
% Selects the candidate track with highest multi-attribute utility.
best_track(UserId, BestTrackId, MaxScore) :-
    findall(Score-TId, (
        recommendable_track(TId, UserId),
        calculate_utility(TId, UserId, Score)
    ), Candidates),
    Candidates \= [],
    sort(1, @>=, Candidates, [MaxScore-BestTrackId|_]).

% -------------------------------------------------------------------------
% CLINICAL ENTRAINMENT MODULE: ALTSHULER'S ISO-PRINCIPLE
% -------------------------------------------------------------------------

%! iso_principle_session(+UserId, -StageSequence)
% Dynamic 3-stage entrainment session for autonomic heart rate downregulation:
% 1. Entry stage:  Pacing user's current elevated tempo (+/- 18 BPM).
% 2. Bridge stage: Moderate tapering tempo (80-95 BPM) with low-mid energy.
% 3. Target stage: Parasympathetic stabilization (< 68 BPM, energy <= 0.25).
iso_principle_session(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)]) :-
    user(UserId, _, _, CurrentHR, _, _, _),
    
    % Entry: matches current elevated tempo
    track(T1, _, _, _, BPM1, _, _, _),
    abs(BPM1 - CurrentHR) =< 18.0,

    % Bridge: intermediate deceleration
    track(T2, _, _, _, BPM2, _, Eng2, _),
    BPM2 >= 80.0, BPM2 =< 95.0,
    Eng2 =< 0.50,
    T2 \= T1,

    % Target: parasympathetic resting target
    track(T3, _, _, _, BPM3, _, Eng3, _),
    BPM3 =< 68.0,
    Eng3 =< 0.25,
    T3 \= T1, T3 \= T2,

    % Strict downward tempo monotonicity invariant
    BPM1 >= BPM2,
    BPM2 >= BPM3,
    !.
