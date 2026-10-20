% =========================================================================
% Test Suite: Logical Correctness of Decision Constraints
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% Tests all constraints: Financial, Temporal, Educational, Feasibility, MCDA.
% =========================================================================

:- module(test_queries, [
    run_all_tests/0,
    test_financial_constraint/0,
    test_temporal_duration/0,
    test_temporal_pacing/0,
    test_temporal_seasonality/0,
    test_educational_topics/0,
    test_educational_levels/0,
    test_educational_min_score/0,
    test_transit_corridors/0,
    test_unsatisfiable_query_diagnosis/0,
    test_mcda_ranking_monotonicity/0
]).

:- use_module('../knowledge_base/load_kb').
:- use_module('../src/dss_core').
:- use_module('../src/dss_rules').
:- use_module('../src/scoring_model').
:- use_module('../src/itinerary_generator').
:- use_module('../src/explanation_engine').

run_all_tests :-
    format('~n============================================================~n'),
    format('     SMART TRAVEL ADVISOR DSS - LOGICAL TEST SUITE          ~n'),
    format('============================================================~n~n'),
    run_test(test_financial_constraint,        'Test 1: Strict Financial Budget Bounds Enforcement'),
    run_test(test_temporal_duration,           'Test 2: Exact Trip Duration Matching'),
    run_test(test_temporal_pacing,             'Test 3: Daily Pace & Visit Hours Capacity Limits'),
    run_test(test_temporal_seasonality,        'Test 4: Destination Seasonality Compatibility'),
    run_test(test_educational_topics,          'Test 5: Educational Topic Coverage & Semantic Subsumption'),
    run_test(test_educational_levels,          'Test 6: Educational Level Matching (Family/HighSchool/Univ)'),
    run_test(test_educational_min_score,       'Test 7: Minimum Educational Quality Threshold'),
    run_test(test_transit_corridors,           'Test 8: Multi-City Transit Corridor & Cost Accounting'),
    run_test(test_unsatisfiable_query_diagnosis,'Test 9: Graceful Failure Diagnosis on Unsatisfiable Bounds'),
    run_test(test_mcda_ranking_monotonicity,    'Test 10: Multi-Criteria Utility Bounds & Descending Rank'),
    format('~n============================================================~n'),
    format('All logical correctness test queries executed.~n'),
    format('============================================================~n~n').

run_test(Predicate, Description) :-
    format('[RUN] ~w... ', [Description]),
    ( catch(call(Predicate), E, (format('FAILED with error: ~w~n', [E]), fail))
    ->  format('PASSED [OK]~n')
    ;   format('FAILED [FAIL]~n')
    ).

% -------------------------------------------------------------------------
% TEST 1: Strict Financial Budget Bounds Enforcement
% -------------------------------------------------------------------------
test_financial_constraint :-
    MaxBudget = 450.0,
    Days = 3,
    Season = spring,
    Pace = moderate,
    Topics = [ancient_history],
    Pref = user_pref(MaxBudget, Days, Season, Pace, Topics, all, 7),
    recommend_itineraries(Pref, Results),
    Results \= [],
    % Every recommended candidate must strictly satisfy Cost =< MaxBudget
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(CityDays, Sites, Transits, _),
        total_itinerary_financials(CityDays, Sites, Transits, TotalCost, _),
        TotalCost =< MaxBudget
    )).

% -------------------------------------------------------------------------
% TEST 2: Exact Trip Duration Matching
% -------------------------------------------------------------------------
test_temporal_duration :-
    RequestedDays = 4,
    Pref = user_pref(1000.0, RequestedDays, spring, moderate, [architecture], all, 7),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(CityDays, _, _, _),
        findall(D, member(city(_, D), CityDays), DaysList),
        sum_list(DaysList, TotalDays),
        TotalDays =:= RequestedDays
    )).

% -------------------------------------------------------------------------
% TEST 3: Daily Pace & Visit Hours Capacity Limits
% -------------------------------------------------------------------------
test_temporal_pacing :-
    Pace = relaxed,
    pace_max_daily_hours(Pace, MaxHours),
    pace_max_daily_sites(Pace, MaxSites),
    Pref = user_pref(800.0, 3, autumn, Pace, [art_history], all, 7),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(_, _, _, DailyAllocations),
        forall(member(day(_, DaySites), DailyAllocations), (
            length(DaySites, Count),
            Count =< MaxSites,
            maplist(dss_rules:site_duration, DaySites, Durations),
            sum_list(Durations, TotalDayHours),
            TotalDayHours =< MaxHours
        ))
    )).

% -------------------------------------------------------------------------
% TEST 4: Destination Seasonality Compatibility
% -------------------------------------------------------------------------
test_temporal_seasonality :-
    Season = winter,
    Pref = user_pref(900.0, 3, Season, moderate, [any], all, 7),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(CityDays, _, _, _),
        forall(member(city(DestId, _), CityDays), (
            destination(DestId, _, _, _, _, _, _, BestSeasons),
            member(Season, BestSeasons)
        ))
    )).

% -------------------------------------------------------------------------
% TEST 5: Educational Topic Coverage & Semantic Subsumption
% -------------------------------------------------------------------------
test_educational_topics :-
    Topics = [ancient_history, architecture],
    Pref = user_pref(900.0, 3, spring, moderate, Topics, all, 8),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(_, Sites, _, _),
        check_educational_constraint(Sites, Topics, all, 8, edu_report(Coverage, _, _)),
        Coverage >= 0.50
    )).

% -------------------------------------------------------------------------
% TEST 6: Educational Level Matching (Family/Elementary)
% -------------------------------------------------------------------------
test_educational_levels :-
    EduLevel = elementary,
    Pref = user_pref(900.0, 3, spring, moderate, [any], EduLevel, 7),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(_, Sites, _, _),
        forall(member(SiteId, Sites), (
            heritage_site(SiteId, _, _, _, _, _, _, TargetLevel, _, _, _),
            ( TargetLevel == elementary ; TargetLevel == all )
        ))
    )).

% -------------------------------------------------------------------------
% TEST 7: Minimum Educational Quality Threshold
% -------------------------------------------------------------------------
test_educational_min_score :-
    MinScore = 9,
    Pref = user_pref(900.0, 3, spring, moderate, [any], all, MinScore),
    recommend_itineraries(Pref, Results),
    Results \= [],
    forall(member(score_entry(_, _, Itin), Results), (
        Itin = itinerary(_, Sites, _, _),
        itinerary_avg_edu_score(Sites, AvgScore),
        AvgScore >= MinScore
    )).

% -------------------------------------------------------------------------
% TEST 8: Multi-City Transit Corridor & Cost Accounting
% -------------------------------------------------------------------------
test_transit_corridors :-
    Pref = user_pref(1200.0, 5, spring, moderate, [art_history], all, 7),
    recommend_itineraries(Pref, Results),
    % Find at least one multi-city candidate
    include(is_multi_city, Results, MultiCityResults),
    MultiCityResults \= [],
    forall(member(score_entry(_, _, Itin), MultiCityResults), (
        Itin = itinerary(CityDays, Sites, Transits, _),
        length(CityDays, NCities),
        NCities >= 2,
        Transits \= [],
        total_itinerary_financials(CityDays, Sites, Transits, TotalCost, cost_breakdown(_, _, TransitCost, _)),
        TransitCost > 0.0,
        TotalCost =< 1200.0
    )).

is_multi_city(score_entry(_, _, itinerary(CityDays, _, _, _))) :-
    length(CityDays, N), N >= 2.

% -------------------------------------------------------------------------
% TEST 9: Graceful Failure Diagnosis on Unsatisfiable Bounds
% -------------------------------------------------------------------------
test_unsatisfiable_query_diagnosis :-
    % 30 EUR for 7 days is impossible for any European destination
    ImpossiblePref = user_pref(30.0, 7, spring, moderate, [architecture], all, 8),
    recommend_itineraries(ImpossiblePref, Results),
    Results == [],
    diagnose_failure(ImpossiblePref, Diagnostics),
    Diagnostics \= [],
    member(Reason, Diagnostics),
    sub_atom(Reason, _, _, _, 'BUDGET_TOO_LOW').

% -------------------------------------------------------------------------
% TEST 10: Multi-Criteria Utility Bounds & Descending Rank
% -------------------------------------------------------------------------
test_mcda_ranking_monotonicity :-
    Pref = user_pref(1200.0, 4, autumn, moderate, [architecture, art_history], all, 7),
    recommend_itineraries(Pref, Results),
    Results = [score_entry(TopScore, _, _)|Rest],
    TopScore >= 0.0,
    TopScore =< 100.0,
    check_descending_utility(Rest, TopScore).

check_descending_utility([], _).
check_descending_utility([score_entry(Score, _, _)|Rest], PrevScore) :-
    Score =< PrevScore,
    Score >= 0.0,
    check_descending_utility(Rest, Score).
