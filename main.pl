% =========================================================================
% Master Prolog Entry Point
% Part of: "KB for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization"
% =========================================================================

:- module(main, [
    demo/0,
    run_tests/0,
    run_profiler/0,
    advisor/0,
    help/0
]).

:- use_module('knowledge_base/load_kb.pl').
:- use_module('src/dss_rules.pl').
:- use_module('src/routine_generator.pl').
:- use_module('src/scoring_model.pl').
:- use_module('src/explanation_engine.pl').
:- use_module('src/dss_core.pl').
:- use_module('tests/test_queries.pl').
:- use_module('benchmarks/profiler.pl').
:- use_module('interactive_advisor.pl').

demo :-
    format('~n========================================================================~n'),
    format(' CONTEXT-AWARE DSS COGNITIVE ASSISTANT DEMO EXECUTION~n'),
    format('========================================================================~n'),
    
    % Demo 1: High-Stress Downregulation
    format('~n>>> CASE 1: Acute Stress & Vagal Downregulation (Sarah Miller) <<<~n'),
    query_smartwatch_advisor(user_sarah, health_priority),
    
    % Demo 2: Cardio Aerobic Cadence Lock
    format('~n>>> CASE 2: High-Intensity Aerobic Cadence Synchronization (Alex Chen) <<<~n'),
    query_smartwatch_advisor(user_alex, performance_priority),
    
    % Demo 3: Deep Focus Cognitive Alpha Flow
    format('~n>>> CASE 3: Deep Focus & Lyric-Free Concentration (Marco Rossi) <<<~n'),
    query_smartwatch_advisor(user_marco, balanced),

    format('~n[SUCCESS] End of Cognitive Assistant Demonstration.~n').

run_tests :-
    test_queries:run_all_tests.

run_profiler :-
    profiler:run_profiler.

advisor :-
    interactive_advisor:start_advisor.

help :-
    format('~nAvailable Master Commands:~n'),
    format('  * demo.         - Runs automated recommendations across physiological cases.~n'),
    format('  * run_tests.    - Executes full 10-point logical correctness test suite.~n'),
    format('  * run_profiler. - Executes native computational benchmarks and lips metrics.~n'),
    format('  * advisor.      - Launches the interactive terminal advisor.~n'),
    format('  * help.         - Shows this menu.~n~n').
