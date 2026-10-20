% =========================================================================
% Main Entry Point: Knowledge Base for a DSS (Smart Travel Advisor)
% =========================================================================

:- module(main, [
    demo/0,
    run_tests/0,
    run_profiler/0,
    interactive/0
]).

:- use_module('knowledge_base/load_kb').
:- use_module('src/dss_core').
:- use_module('tests/test_queries').
:- use_module('benchmarks/profiler').
:- use_module('interactive_advisor').

demo :-
    format('~n====================================================================~n'),
    format('  DEMO 1: Single-City Educational Tour (Rome, 3 Days, Ancient History)~n'),
    format('====================================================================~n'),
    query_advisor(800.0, 3, spring, moderate, [ancient_history, architecture], all, 8),
    
    format('~n====================================================================~n'),
    format('  DEMO 2: Multi-City Corridor Tour (5 Days, Art History & Renaissance)~n'),
    format('====================================================================~n'),
    query_advisor(1200.0, 5, spring, moderate, [art_history, renaissance_architecture], all, 8).

run_tests :-
    test_queries:run_all_tests.

run_profiler :-
    profiler:run_all_benchmarks.

interactive :-
    interactive_advisor:start_advisor.
