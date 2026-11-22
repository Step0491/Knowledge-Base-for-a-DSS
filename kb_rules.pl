% =========================================================================
% DECLARATIVE DOMAIN KNOWLEDGE BASE: kb_rules.pl
% Long-Term Memory (Separated from Inference Engine Control)
% Architecture: Production Rules (GIE-style) + Concept Taxonomy + Askables
% =========================================================================

% -------------------------------------------------------------------------
% 1. DOMAIN TAXONOMY / CONCEPT HIERARCHY (is_a/2)
% -------------------------------------------------------------------------

% Music Genre Hierarchy
is_a(ambient, calm_instrumental).
is_a(classical, calm_instrumental).
is_a(lofi, steady_instrumental).
is_a(jazz, steady_instrumental).
is_a(cinematic, steady_instrumental).
is_a(acoustic, gentle_acoustic).
is_a(indie, upbeat_vocal).
is_a(pop, upbeat_vocal).
is_a(deep_house, rhythmic_electronic).
is_a(synthwave, rhythmic_electronic).
is_a(electronic, rhythmic_electronic).
is_a(techno, high_energy_beat).
is_a(rock, high_energy_vocal).
is_a(metal, high_energy_vocal).

is_a(calm_instrumental, instrumental_family).
is_a(steady_instrumental, instrumental_family).
is_a(rhythmic_electronic, workout_family).
is_a(high_energy_beat, workout_family).
is_a(high_energy_vocal, workout_family).

% User Activity / Routine Hierarchy
is_a(high_stress_work, stress_context).
is_a(cardio_running, intense_workout_context).
is_a(deep_focus_study, study_context).
is_a(sleep_preparation, pre_sleep_context).
is_a(post_workout_recovery, recovery_context).
is_a(active_commute, commute_context).

% -------------------------------------------------------------------------
% 2. ASKABLE USER QUESTIONS (Used interactively if Working Memory lacks info)
% -------------------------------------------------------------------------

askable(user_feels_tired(_),
    'Does the user feel physically or mentally exhausted right now').
askable(requires_no_lyrics(_),
    'Does the user task require lyric-free music to stay focused').
askable(preparing_for_sleep(_),
    'Is the user preparing to go to sleep soon').

% -------------------------------------------------------------------------
% 3. DECLARATIVE PRODUCTION RULES
% Format: rule(RuleId, Consequent, Condition, Weight, HumanDescription).
% -------------------------------------------------------------------------

% --- LEVEL 0: TOP-LEVEL RECOMMENDATION GOAL ---

rule(r_recommend,
    recommendable(TrackId, UserId),
    and([
        pace_matches_body(TrackId, UserId),
        study_compatible(TrackId, UserId),
        safe_for_user(TrackId, UserId),
        pre_sleep_compatible(TrackId, UserId)
    ]),
    1.0,
    'Track satisfies body pace, study focus, safety limits, and pre-sleep coherence').

% --- LEVEL 1: FOUR CORE EVALUATION PILLARS ---

% Pillar 1: Body Pace & Energy Alignment
rule(r_pace_stress,
    pace_matches_body(TrackId, UserId),
    and([need_stress_relief(UserId), calm_track(TrackId)]),
    1.0,
    'Selected calm, slow, instrumental music to relieve high stress').

rule(r_pace_workout,
    pace_matches_body(TrackId, UserId),
    and([need_workout_boost(UserId), workout_track(TrackId)]),
    1.0,
    'Selected fast, energetic music to match running workout pace').

rule(r_pace_sleep,
    pace_matches_body(TrackId, UserId),
    and([need_pre_sleep(UserId), sleep_track(TrackId)]),
    1.0,
    'Selected ultra-gentle, slow instrumental music for pre-sleep rest').

rule(r_pace_balanced,
    pace_matches_body(TrackId, UserId),
    and([need_balanced_music(UserId), balanced_track(TrackId)]),
    0.95,
    'Selected balanced, positive music for normal recovery or commuting').

% Pillar 2: Study Focus (Lyric-Free Protection)
rule(r_study_active,
    study_compatible(TrackId, UserId),
    and([need_study_focus(UserId), no_lyrics_for_study(TrackId)]),
    1.0,
    'Protected study concentration with steady, lyric-free music').

rule(r_study_inactive,
    study_compatible(_TrackId, UserId),
    and([not(need_study_focus(UserId))]),
    1.0,
    'No study lyric restriction applies outside study routines').

% Pillar 3: Safety Checks Against Overstimulation
rule(r_safe_all,
    safe_for_user(TrackId, UserId),
    and([not(unsafe_fast_beat(TrackId, UserId)), not(unsafe_high_energy(TrackId, UserId))]),
    1.0,
    'Verified that track tempo and energy are safe for current heart rate and stress').

rule(r_unsafe_fast_beat,
    unsafe_fast_beat(TrackId, UserId),
    and([very_high_heart_rate(UserId), very_high_stress(UserId), fast_or_intense_track(TrackId)]),
    1.0,
    'Safety block: HR > 110 BPM and stress > 75 forbid fast (>100 BPM) or intense (>0.60 energy) tracks').

rule(r_unsafe_high_energy,
    unsafe_high_energy(TrackId, UserId),
    and([user_exhausted(UserId), energy_above_half(TrackId)]),
    1.0,
    'Safety block: high-energy tracks (>0.50) are avoided during severe exhaustion').

% Pillar 4: Pre-Sleep Routine Compatibility
rule(r_pre_sleep_active,
    pre_sleep_compatible(TrackId, UserId),
    and([need_pre_sleep(UserId), gentle_sleep_ceiling(TrackId)]),
    1.0,
    'Pre-sleep acoustic ceiling verified (BPM <= 68 and Energy <= 0.30)').

rule(r_pre_sleep_inactive,
    pre_sleep_compatible(_TrackId, UserId),
    and([not(need_pre_sleep(UserId))]),
    1.0,
    'Pre-sleep limits not required outside bedtime routines').

% --- LEVEL 2: USER ROUTINE & BIOMETRIC STATE RECOGNITION ---

rule(r_need_stress_goal,
    need_stress_relief(UserId),
    and([user_goal(UserId, stress_downregulation)]),
    1.0,
    'User profile goal explicitly asks for stress relief').

rule(r_need_stress_bio,
    need_stress_relief(UserId),
    and([high_heart_rate(UserId), high_stress(UserId)]),
    0.95,
    'Smartwatch shows high heart rate (>=100 BPM) combined with high stress (>=65/100)').

rule(r_need_workout_goal,
    need_workout_boost(UserId),
    and([user_goal(UserId, cardio_peak_performance)]),
    1.0,
    'User profile goal is intense workout performance').

rule(r_need_workout_bio,
    need_workout_boost(UserId),
    and([user_activity_context(UserId, intense_workout_context), workout_heart_rate(UserId)]),
    0.95,
    'Running activity detected with workout heart rate (>=120 BPM)').

rule(r_need_sleep_goal,
    need_pre_sleep(UserId),
    and([user_goal(UserId, sleep_induction)]),
    1.0,
    'User profile goal is preparing for sleep').

rule(r_need_sleep_act,
    need_pre_sleep(UserId),
    and([user_activity_context(UserId, pre_sleep_context)]),
    0.95,
    'Smartwatch activity indicates pre-sleep preparation').

rule(r_need_sleep_ask,
    need_pre_sleep(UserId),
    and([preparing_for_sleep(UserId)]),
    0.85,
    'User confirmed preparing for sleep').

rule(r_need_study_act,
    need_study_focus(UserId),
    and([user_activity_context(UserId, study_context)]),
    1.0,
    'Smartwatch activity indicates deep focus study').

rule(r_need_study_goal,
    need_study_focus(UserId),
    and([user_goal(UserId, deep_focus_flow)]),
    1.0,
    'User profile goal is deep study focus').

rule(r_need_study_ask,
    need_study_focus(UserId),
    and([requires_no_lyrics(UserId)]),
    0.85,
    'User requested lyric-free concentration support').

rule(r_need_balanced,
    need_balanced_music(UserId),
    and([not(need_stress_relief(UserId)), not(need_workout_boost(UserId)), not(need_pre_sleep(UserId))]),
    0.95,
    'User is in a normal state (post-workout recovery or active commute)').

rule(r_exhausted_bio,
    user_exhausted(UserId),
    and([user_activity_context(UserId, stress_context), severe_stress(UserId)]),
    1.0,
    'Stressful work combined with severe stress (>80/100) indicates exhaustion').

rule(r_exhausted_ask,
    user_exhausted(UserId),
    and([user_feels_tired(UserId)]),
    0.90,
    'User confirmed feeling physically or mentally exhausted').

% --- LEVEL 3: TRACK PROFILE CLASSIFICATION ---

rule(r_calm_track,
    calm_track(TrackId),
    and([slow_beat(TrackId), low_energy(TrackId), mostly_instrumental(TrackId)]),
    0.98,
    'Calm track: slow tempo (<=75 BPM), low energy (<=0.35), instrumental (>=0.70)').

rule(r_workout_track,
    workout_track(TrackId),
    and([fast_beat(TrackId), high_energy(TrackId)]),
    0.98,
    'Workout track: fast tempo (>=120 BPM) and high energy (>=0.70)').

rule(r_sleep_track,
    sleep_track(TrackId),
    and([very_slow_beat(TrackId), very_low_energy(TrackId), pure_instrumental(TrackId)]),
    0.99,
    'Sleep track: very slow (<=64 BPM), very low energy (<=0.20), pure instrumental (>=0.85)').

rule(r_study_track,
    no_lyrics_for_study(TrackId),
    and([mostly_instrumental(TrackId), steady_study_beat(TrackId), moderate_or_low_energy(TrackId)]),
    0.96,
    'Study-safe track: lyric-free (>=0.70), steady tempo (70-95 BPM), energy <=0.55').

rule(r_balanced_track,
    balanced_track(TrackId),
    and([moderate_beat(TrackId), controlled_energy(TrackId), positive_mood(TrackId)]),
    0.95,
    'Balanced track: moderate beat (70-115 BPM), controlled energy (<=0.65), positive mood (>=0.40)').
