% =========================================================================
% Scoring Model Module: Multi-Criteria Decision Analysis (MCDA)
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(scoring_model, [
    calculate_itinerary_utility/4,
    rank_itineraries/3
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).

%! calculate_itinerary_utility(+Itinerary, +UserPreferences, +ProfileWeight, -ScoreBreakdown)
% Profiles:
% - balanced:         edu=0.40, fin=0.30, temp=0.15, div=0.15
% - education_first:  edu=0.60, fin=0.15, temp=0.10, div=0.15
% - budget_conscious: edu=0.25, fin=0.55, temp=0.10, div=0.10
calculate_itinerary_utility(Itinerary, UserPreferences, Profile, ScoreBreakdown) :-
    Itinerary = itinerary(CityDays, Sites, Transits, DailyAllocations),
    UserPreferences = user_pref(MaxBudget, Days, _Season, Pace, DesiredTopics, EduLevel, MinEduScore),
    
    % Fetch weights
    profile_weights(Profile, W_Edu, W_Fin, W_Temp, W_Div),
    
    % 1. Educational Sub-Score (0 - 100)
    score_educational(Sites, DesiredTopics, EduLevel, MinEduScore, S_Edu),
    
    % 2. Financial Sub-Score (0 - 100)
    total_itinerary_financials(CityDays, Sites, Transits, TotalCost, _),
    score_financial(TotalCost, MaxBudget, S_Fin),
    
    % 3. Temporal Sub-Score (0 - 100)
    score_temporal(DailyAllocations, Pace, Transits, Days, S_Temp),
    
    % 4. Diversity & Logistics Sub-Score (0 - 100)
    score_diversity(CityDays, Sites, S_Div),
    
    % Combined Weighted Utility
    FinalUtility is (W_Edu * S_Edu) + (W_Fin * S_Fin) + (W_Temp * S_Temp) + (W_Div * S_Div),
    ScoreBreakdown = score(FinalUtility, S_Edu, S_Fin, S_Temp, S_Div).

profile_weights(balanced,         0.40, 0.30, 0.15, 0.15).
profile_weights(education_first,  0.60, 0.15, 0.10, 0.15).
profile_weights(budget_conscious, 0.25, 0.55, 0.10, 0.10).
profile_weights(_,                0.40, 0.30, 0.15, 0.15). % default balanced

% --- Sub-Score Computations ---

score_educational([], _, _, _, 0.0) :- !.
score_educational(Sites, DesiredTopics, _EduLevel, _MinScore, Score) :-
    % Average site educational score (1-10 -> 0-50 pts)
    itinerary_avg_edu_score(Sites, AvgSiteScore),
    BaseEduScore is (AvgSiteScore / 10.0) * 50.0,
    
    % Topic coverage (0-30 pts)
    ( DesiredTopics == [] ; DesiredTopics == [any]
    ->  TopicScore = 30.0
    ;   findall(Req, (
            member(Req, DesiredTopics),
            member(SiteId, Sites),
            site_satisfies_topic(SiteId, Req)
        ), Matched),
        sort(Matched, UniqueMatched),
        length(UniqueMatched, NMatched),
        length(DesiredTopics, NTotal),
        TopicScore is (NMatched / NTotal) * 30.0
    ),
    
    % Academic depth & UNESCO criteria density bonus (0-20 pts)
    findall(CritCount, (
        member(SiteId, Sites),
        heritage_site(SiteId, _, _, _, Criteria, _, _, _, _, _, _),
        length(Criteria, CritCount)
    ), AllCrits),
    sum_list(AllCrits, TotalCriteria),
    length(Sites, NSites),
    AvgCriteria is TotalCriteria / NSites,
    CritBonus is min(20.0, (AvgCriteria / 4.0) * 20.0),
    
    Score is BaseEduScore + TopicScore + CritBonus.

score_financial(TotalCost, MaxBudget, Score) :-
    MaxBudget > 0,
    CostRatio is TotalCost / MaxBudget,
    ( CostRatio =< 1.0
    ->  % Ideal utilization between 60% and 90%
        SavingsRatio is 1.0 - CostRatio,
        % Reward staying under budget without being empty
        Score is 50.0 + (SavingsRatio * 50.0)
    ;   % Over budget receives heavy penalty
        OverRatio is CostRatio - 1.0,
        Score is max(0.0, 50.0 - (OverRatio * 200.0))
    ).

score_temporal(DailyAllocations, Pace, Transits, TotalDays, Score) :-
    pace_max_daily_hours(Pace, MaxDailyHours),
    % Measure daily utilization
    findall(DayUtil, (
        member(day(_, DaySites), DailyAllocations),
        maplist(dss_rules:site_duration, DaySites, Durations),
        sum_list(Durations, DayHours),
        DayUtil is min(1.0, DayHours / MaxDailyHours)
    ), Utils),
    ( Utils == []
    ->  AvgUtil = 0.5
    ;   sum_list(Utils, SumUtil),
        length(Utils, NDays),
        AvgUtil is SumUtil / NDays
    ),
    BaseUtilScore is AvgUtil * 70.0,
    
    % Penalty for excessive transit travel time
    findall(Hours, (member(transit(O, D), Transits), intercity_transit(O, D, Hours, _, _)), TransitTimes),
    sum_list(TransitTimes, TotalTransitHours),
    TransitPenalty is min(30.0, (TotalTransitHours / TotalDays) * 10.0),
    
    Score is max(0.0, BaseUtilScore + 30.0 - TransitPenalty).

score_diversity(CityDays, Sites, Score) :-
    % Historical eras variety (0-40 pts)
    findall(Era, (
        member(SiteId, Sites),
        heritage_site(SiteId, _, _, _, _, Era, _, _, _, _, _)
    ), Eras),
    sort(Eras, UniqueEras),
    length(UniqueEras, NEras),
    EraScore is min(40.0, NEras * 15.0),
    
    % Destination walkability and logistics (0-60 pts)
    findall(Walk, (
        member(city(DestId, _), CityDays),
        destination_logistics(DestId, Walk, _, _)
    ), Walks),
    ( Walks == []
    ->  AvgWalk = 8.0
    ;   sum_list(Walks, SumWalk),
        length(Walks, NCities),
        AvgWalk is SumWalk / NCities
    ),
    LogisticsScore is (AvgWalk / 10.0) * 60.0,
    
    Score is EraScore + LogisticsScore.

%! rank_itineraries(+CandidateItineraries, +UserPreferences, -RankedPairs)
% Sorts candidate itineraries in descending order of calculated utility.
rank_itineraries(Candidates, UserPreferences, RankedPairs) :-
    maplist(score_candidate(UserPreferences), Candidates, ScoredList),
    % Sort in descending order of utility score (first element)
    sort(1, @>=, ScoredList, RankedPairs).

score_candidate(UserPreferences, Itinerary, score_entry(Utility, ScoreObj, Itinerary)) :-
    calculate_itinerary_utility(Itinerary, UserPreferences, balanced, ScoreObj),
    ScoreObj = score(Utility, _, _, _, _).
