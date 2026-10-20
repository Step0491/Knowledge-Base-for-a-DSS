% =========================================================================
% Interactive Advisor CLI: Smart Travel Advisor Console Interface
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(interactive_advisor, [
    start_advisor/0
]).

:- use_module('knowledge_base/load_kb').
:- use_module('src/dss_core').
:- use_module('src/dss_rules').
:- use_module('src/scoring_model').
:- use_module('src/explanation_engine').

start_advisor :-
    format('~n=============================================================================~n'),
    format('    SMART TRAVEL ADVISOR - DECISION SUPPORT SYSTEM (DSS) IN PROLOG           ~n'),
    format('    Tourism, Cultural Heritage & Education Optimization                      ~n'),
    format('=============================================================================~n~n'),
    
    prompt_read_number('Enter your total travel budget in EUR (e.g., 850.0): ', 850.0, Budget),
    prompt_read_integer('Enter total number of travel days (e.g., 3, 5, 7): ', 3, Days),
    prompt_read_atom('Enter travel season (spring, summer, autumn, winter, or any): ', spring, Season),
    prompt_read_atom('Enter preferred pace (relaxed, moderate, intensive): ', moderate, Pace),
    prompt_read_atom('Enter educational level (elementary, high_school, university_research, all): ', all, EduLevel),
    prompt_read_topics('Enter educational topic(s) separated by commas (or "any"): ', [ancient_history, architecture], Topics),
    prompt_read_integer('Enter minimum acceptable site educational score (1 - 10): ', 8, MinEduScore),
    
    UserPref = user_pref(Budget, Days, Season, Pace, Topics, EduLevel, MinEduScore),
    format('~nPreferences received: ~w~n', [UserPref]),
    query_advisor(UserPref).

prompt_read_number(Prompt, Default, Value) :-
    format('~w [default: ~w]: ', [Prompt, Default]),
    read_line_to_string(user_input, Input),
    ( Input == ""
    ->  Value = Default
    ;   ( number_string(Parsed, Input) -> Value is float(Parsed) ; Value = Default )
    ).

prompt_read_integer(Prompt, Default, Value) :-
    format('~w [default: ~w]: ', [Prompt, Default]),
    read_line_to_string(user_input, Input),
    ( Input == ""
    ->  Value = Default
    ;   ( number_string(Parsed, Input) -> Value = Parsed ; Value = Default )
    ).

prompt_read_atom(Prompt, Default, Value) :-
    format('~w [default: ~w]: ', [Prompt, Default]),
    read_line_to_string(user_input, Input),
    ( Input == ""
    ->  Value = Default
    ;   atom_string(Value, Input)
    ).

prompt_read_topics(Prompt, Default, Topics) :-
    format('~w [default: ~w]: ', [Prompt, Default]),
    read_line_to_string(user_input, Input),
    ( Input == ""
    ->  Topics = Default
    ;   ( Input == "any"
        ->  Topics = [any]
        ;   split_string(Input, ",", " ", Parts),
            maplist(atom_string, Topics, Parts)
        )
    ).
