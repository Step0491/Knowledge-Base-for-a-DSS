% =========================================================================
% DSS Core Module: Smart Travel Advisor Façade
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(dss_core, [
    recommend_itineraries/2,
    recommend_best_itinerary/2,
    query_advisor/1,
    query_advisor/7
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).
:- use_module(scoring_model).
:- use_module(itinerary_generator).
:- use_module(explanation_engine).

%! recommend_itineraries(+Preferences, -RankedResults)
% High-level inference entry point.
recommend_itineraries(Preferences, RankedResults) :-
    generate_candidate_itineraries(Preferences, Candidates),
    rank_itineraries(Candidates, Preferences, RankedResults).

%! recommend_best_itinerary(+Preferences, -BestItinerary)
recommend_best_itinerary(Preferences, Best) :-
    recommend_itineraries(Preferences, [Best|_]).

%! query_advisor(+MaxBudget, +Days, +Season, +Pace, +DesiredTopics, +EduLevel, +MinEduScore)
% Convenience query wrapper that computes and prints the recommendation or diagnostics.
query_advisor(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore) :-
    UserPref = user_pref(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore),
    query_advisor(UserPref).

%! query_advisor(+UserPref)
query_advisor(UserPref) :-
    format('~n[*] Searching for optimal travel itineraries satisfying all constraints...~n'),
    recommend_itineraries(UserPref, Results),
    ( Results = [Best|_]
    ->  length(Results, TotalFound),
        format('[+] Found ~w candidate itineraries meeting all constraints.~n', [TotalFound]),
        print_itinerary_card(Best)
    ;   format('[!] No itineraries found matching all constraints.~n'),
        diagnose_failure(UserPref, Diagnostics),
        format('--- Failure Diagnosis & Bottlenecks ---~n'),
        forall(member(Diag, Diagnostics), format(' * ~w~n', [Diag]))
    ).
