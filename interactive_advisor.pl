% =========================================================================
% Interactive Cognitive Advisor CLI
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(interactive_advisor, [
    start_advisor/0
]).

:- use_module('knowledge_base/load_kb.pl').
:- use_module('src/dss_rules.pl').
:- use_module('src/routine_generator.pl').
:- use_module('src/scoring_model.pl').
:- use_module('src/explanation_engine.pl').
:- use_module('src/dss_core.pl').

%! start_advisor
% Entry point to the interactive terminal assistant.
start_advisor :-
    format('~n========================================================================~n'),
    format(' DSS CONTEXT-AWARE MUSIC & HEALTH-ROUTINE ADVISOR~n'),
    format(' Real-Time Cognitive Decision Support System~n'),
    format('========================================================================~n'),
    format(' Choose an option:~n'),
    format('  [1] Select Existing Smartwatch User Profile~n'),
    format('  [2] Enter Live Ad-Hoc Biometrics (Simulate Smartwatch)~n'),
    format('  [3] Exit~n'),
    format(' Selection (1-3): '),
    read_line_to_string(user_input, ChoiceStr),
    process_main_choice(ChoiceStr).

process_main_choice("1") :-
    format('~n--- Available Smartwatch Profiles ---~n'),
    forall(user_biometrics(Uid, Name, Act, HR, _, _, Stress, _, _, _, Goal, _),
           format('  * ~w: ~w (Activity: ~w, HR: ~0f BPM, Stress: ~0f/100, Goal: ~w)~n', [Uid, Name, Act, HR, Stress, Goal])),
    format('~n Enter User ID (e.g., user_sarah, user_alex, user_marco): '),
    read_line_to_string(user_input, UserStr),
    atom_string(UserId, UserStr),
    ( user_biometrics(UserId, _, _, _, _, _, _, _, _, _, _, _)
    -> prompt_profile_and_run(UserId)
    ;  format('[!] Invalid User ID: ~w~n', [UserId]),
       start_advisor
    ).

process_main_choice("2") :-
    format('~n--- Live Smartwatch Simulation ---~n'),
    format(' Select Activity (cardio_running, deep_focus_study, high_stress_work, sleep_preparation, active_commute): '),
    read_line_to_string(user_input, ActStr),
    atom_string(Activity, ActStr),
    format(' Current Heart Rate in BPM (e.g., 115): '),
    read_line_to_string(user_input, HRStr),
    number_string(HR, HRStr),
    format(' Current Stress Level [0-100] (e.g., 78): '),
    read_line_to_string(user_input, StressStr),
    number_string(Stress, StressStr),
    format(' Target Routine (stress_downregulation, cardio_peak_performance, deep_focus_flow, sleep_induction, active_commute_energizer): '),
    read_line_to_string(user_input, GoalStr),
    atom_string(Goal, GoalStr),
    
    evaluate_custom_biometrics(Activity, HR, Stress, Goal, RankedResults),
    ( RankedResults = [Best|_]
    -> Biometrics = user_biometrics(simulated_user, 'Simulated Smartwatch', Activity, HR, 60.0, 35.0, Stress, 6.0, afternoon, 40.0, Goal, [ambient, classical, lofi]),
       print_recommendation_card(Best, Biometrics, Goal),
       Best = ranked(_, TrackId, _),
       explain_recommendation(TrackId, Biometrics, Goal)
    ;  format('[!] No candidate tracks satisfied the physiological bounds for the specified parameters.~n')
    ),
    ask_restart.

process_main_choice("3") :-
    format('~nExiting Cognitive Advisor. Stay healthy and balanced!~n~n').

process_main_choice(_) :-
    format('[!] Invalid choice. Please try again.~n'),
    start_advisor.

prompt_profile_and_run(UserId) :-
    format('~n Select MCDA Weighting Profile:~n'),
    format('  [1] balanced (default)~n'),
    format('  [2] health_priority (strongest biometric entrainment weight)~n'),
    format('  [3] performance_priority (workout & arousal emphasis)~n'),
    format('  [4] acoustic_first (mood & aesthetic focus)~n'),
    format(' Profile choice (1-4): '),
    read_line_to_string(user_input, ProfStr),
    decode_profile(ProfStr, Profile),
    query_smartwatch_advisor(UserId, Profile),
    ask_restart.

decode_profile("2", health_priority) :- !.
decode_profile("3", performance_priority) :- !.
decode_profile("4", acoustic_first) :- !.
decode_profile(_, balanced).

ask_restart :-
    format('~n Would you like to run another consultation? (y/n): '),
    read_line_to_string(user_input, Ans),
    ( (Ans == "y" ; Ans == "Y")
    -> start_advisor
    ;  format('Exiting Cognitive Advisor. Goodbye!~n~n')
    ).
