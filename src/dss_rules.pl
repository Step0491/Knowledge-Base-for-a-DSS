% =========================================================================
% DSS Rules Module: Financial, Temporal, and Educational Constraints
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(dss_rules, [
    % Financial rules
    destination_daily_cost/2,
    budget_tier_destination/2,
    total_itinerary_financials/5,
    check_financial_constraint/3,
    
    % Temporal rules
    pace_max_daily_hours/2,
    pace_max_daily_sites/2,
    destination_season_match/2,
    schedule_days_feasible/3,
    check_temporal_constraint/5,
    
    % Educational rules
    site_satisfies_topic/2,
    site_satisfies_level/2,
    itinerary_topics_covered/2,
    itinerary_avg_edu_score/2,
    check_educational_constraint/5,
    
    % Combined validation
    validate_itinerary_all_constraints/5
]).

:- use_module('../knowledge_base/load_kb.pl').

% -------------------------------------------------------------------------
% 1. FINANCIAL CONSTRAINTS & RULES
% -------------------------------------------------------------------------

%! destination_daily_cost(+DestId, -DailyBaseCost)
% Computes base daily cost of staying in a destination: accommodation + food + local transport.
destination_daily_cost(DestId, DailyBaseCost) :-
    destination(DestId, _, _, _, AccCost, FoodCost, TransCost, _),
    DailyBaseCost is AccCost + FoodCost + TransCost.

%! budget_tier_destination(+DestId, ?Tier)
% Classifies a destination into budget tiers based on daily base cost:
% - budget:   <= 85 EUR/day
% - moderate: 85 - 130 EUR/day
% - luxury:   > 130 EUR/day
budget_tier_destination(DestId, budget) :-
    destination_daily_cost(DestId, Cost),
    Cost =< 85.0.

budget_tier_destination(DestId, moderate) :-
    destination_daily_cost(DestId, Cost),
    Cost > 85.0,
    Cost =< 130.0.

budget_tier_destination(DestId, luxury) :-
    destination_daily_cost(DestId, Cost),
    Cost > 130.0.

%! total_itinerary_financials(+CityDaysList, +SiteIdsList, +TransitPairsList, -TotalCost, -Breakdown)
% CityDaysList: [city(rome, 3), city(florence, 2)]
% SiteIdsList: [colosseum_and_roman_forum, vatican_city, ...]
% TransitPairsList: [transit(rome, florence), ...]
total_itinerary_financials(CityDaysList, SiteIdsList, TransitPairsList, TotalCost, Breakdown) :-
    % 1. Base destination costs (Acc + Food + Local Transit)
    maplist(city_stay_cost, CityDaysList, BaseCosts),
    sum_list(BaseCosts, TotalBaseCost),
    
    % 2. Heritage Site admission fees
    maplist(site_admission_cost, SiteIdsList, SiteFees),
    sum_list(SiteFees, TotalAdmissionFees),
    
    % 3. Inter-city transit tickets
    maplist(transit_ticket_cost, TransitPairsList, TransitCosts),
    sum_list(TransitCosts, TotalTransitCost),
    
    TotalCost is TotalBaseCost + TotalAdmissionFees + TotalTransitCost,
    Breakdown = cost_breakdown(TotalBaseCost, TotalAdmissionFees, TotalTransitCost, TotalCost).

city_stay_cost(city(DestId, Days), Cost) :-
    destination_daily_cost(DestId, DailyBase),
    Cost is DailyBase * Days.

site_admission_cost(SiteId, Fee) :-
    heritage_site(SiteId, _, _, _, _, _, _, _, _, Fee, _).

transit_ticket_cost(transit(Orig, Dest), Cost) :-
    intercity_transit(Orig, Dest, _, Cost, _).

%! check_financial_constraint(+TotalCost, +MaxBudget, -Margin)
% Verifies that total cost is strictly within user max budget.
check_financial_constraint(TotalCost, MaxBudget, Margin) :-
    TotalCost =< MaxBudget,
    Margin is MaxBudget - TotalCost.

% -------------------------------------------------------------------------
% 2. TEMPORAL CONSTRAINTS & RULES
% -------------------------------------------------------------------------

%! pace_max_daily_hours(?Pace, ?MaxHours)
% Defines maximum recommended active heritage visit hours per day by pace.
pace_max_daily_hours(relaxed, 4.5).
pace_max_daily_hours(moderate, 6.5).
pace_max_daily_hours(intensive, 8.5).

%! pace_max_daily_sites(?Pace, ?MaxSites)
% Defines maximum recommended sites visited per day by pace.
pace_max_daily_sites(relaxed, 2).
pace_max_daily_sites(moderate, 3).
pace_max_daily_sites(intensive, 4).

%! destination_season_match(+DestId, +TravelSeason)
% Verifies if the travel season is among the destination's recommended seasons.
destination_season_match(DestId, TravelSeason) :-
    destination(DestId, _, _, _, _, _, _, BestSeasons),
    ( TravelSeason == any
    ; member(TravelSeason, BestSeasons)
    ).

%! schedule_days_feasible(+DaysList, +Pace, +DaySitesAllocation)
% Verifies that for each day, the allocated sites do not exceed daily pace hours.
% DaySitesAllocation: [day(1, [site1, site2]), day(2, [site3]), ...]
schedule_days_feasible([], _, []).
schedule_days_feasible([day(DayNum, Sites)|RestDays], Pace, [report(DayNum, TotalHours, SiteCount)|RestReports]) :-
    pace_max_daily_hours(Pace, MaxHours),
    pace_max_daily_sites(Pace, MaxSites),
    length(Sites, SiteCount),
    SiteCount =< MaxSites,
    maplist(site_duration, Sites, Durations),
    sum_list(Durations, TotalHours),
    TotalHours =< MaxHours,
    schedule_days_feasible(RestDays, Pace, RestReports).

site_duration(SiteId, Duration) :-
    heritage_site(SiteId, _, _, _, _, _, _, _, Duration, _, _).

%! check_temporal_constraint(+CityDaysList, +RequestedDays, +Season, +Pace, +DailyAllocations)
check_temporal_constraint(CityDaysList, RequestedDays, Season, Pace, DailyAllocations) :-
    % Check total days match
    findall(Days, member(city(_, Days), CityDaysList), DaysCounts),
    sum_list(DaysCounts, TotalDays),
    TotalDays =:= RequestedDays,
    
    % Check season validity for all visited destinations
    forall(member(city(DestId, _), CityDaysList), destination_season_match(DestId, Season)),
    
    % Check daily pace feasibility
    schedule_days_feasible(DailyAllocations, Pace, _).

% -------------------------------------------------------------------------
% 3. EDUCATIONAL CONSTRAINTS & RULES
% -------------------------------------------------------------------------

%! site_satisfies_topic(+SiteId, +DesiredTopic)
% Checks whether a heritage site covers the desired educational topic.
site_satisfies_topic(SiteId, DesiredTopic) :-
    heritage_site(SiteId, _, _, _, _, _, Topics, _, _, _, _),
    ( DesiredTopic == any
    ; member(DesiredTopic, Topics)
    ; topic_subsumes(DesiredTopic, Topics)
    ).

% Educational topic subsumption / semantic hierarchy
topic_subsumes(ancient_history, Topics) :-
    member(T, Topics), member(T, [ancient_rome, classical_antiquity, archaeology, classical_greek_philosophy, roman_law_and_statecraft]).
topic_subsumes(art_history, Topics) :-
    member(T, Topics), member(T, [renaissance_humanism, baroque_art, fine_arts_curation, modernist_architecture, byzantine_mosaic_art, art_nouveau]).
topic_subsumes(architecture, Topics) :-
    member(T, Topics), member(T, [classical_architecture, renaissance_architecture, baroque_architecture, gothic_architecture, modernist_architecture, mudejar_architecture]).
topic_subsumes(engineering, Topics) :-
    member(T, Topics), member(T, [civil_engineering, dome_engineering, hydraulic_engineering, biomimetic_structural_engineering, iron_bridge_engineering]).
topic_subsumes(urban_planning, Topics) :-
    member(T, Topics), member(T, [enlightenment_urbanism, ringstrasse_urban_planning, water_management, graeco_roman_street_grids]).

%! site_satisfies_level(+SiteId, +UserEduLevel)
% Verifies if the target education level matches the user.
% Levels: elementary, high_school, university_research, all.
site_satisfies_level(_, all) :- !.
site_satisfies_level(SiteId, UserEduLevel) :-
    heritage_site(SiteId, _, _, _, _, _, _, TargetLevel, _, _, _),
    edu_level_compatible(UserEduLevel, TargetLevel).

edu_level_compatible(_, all) :- !.
edu_level_compatible(elementary, elementary) :- !.
edu_level_compatible(high_school, high_school) :- !.
edu_level_compatible(high_school, elementary) :- !.
edu_level_compatible(university_research, _) :- !. % University researchers can visit any level, prioritizing academic depth.

%! itinerary_topics_covered(+SiteIdsList, -AllCoveredTopics)
itinerary_topics_covered(SiteIdsList, UniqueCoveredTopics) :-
    findall(T, (
        member(SiteId, SiteIdsList),
        heritage_site(SiteId, _, _, _, _, _, Topics, _, _, _, _),
        member(T, Topics)
    ), AllTopicsList),
    sort(AllTopicsList, UniqueCoveredTopics).

%! itinerary_avg_edu_score(+SiteIdsList, -AvgScore)
itinerary_avg_edu_score([], 0.0) :- !.
itinerary_avg_edu_score(SiteIdsList, AvgScore) :-
    findall(Score, (
        member(SiteId, SiteIdsList),
        heritage_site(SiteId, _, _, _, _, _, _, _, _, _, Score)
    ), ScoresList),
    sum_list(ScoresList, Sum),
    length(ScoresList, N),
    N > 0,
    AvgScore is Sum / N.

%! check_educational_constraint(+SiteIdsList, +DesiredTopicsList, +EduLevel, +MinAvgEduScore, -Report)
check_educational_constraint(SiteIdsList, DesiredTopicsList, EduLevel, MinAvgEduScore, Report) :-
    SiteIdsList \= [],
    % 1. Check education level compatibility for each site
    forall(member(SiteId, SiteIdsList), site_satisfies_level(SiteId, EduLevel)),
    
    % 2. Check topic satisfaction
    ( DesiredTopicsList == [] ; DesiredTopicsList == [any]
    ->  TopicCoverage = 1.0
    ;   findall(Req, (
            member(Req, DesiredTopicsList),
            member(SiteId, SiteIdsList),
            site_satisfies_topic(SiteId, Req)
        ), MatchedReqsRaw),
        sort(MatchedReqsRaw, MatchedReqs),
        length(MatchedReqs, MatchedCount),
        length(DesiredTopicsList, TotalReqCount),
        MatchedCount > 0, % At least one required topic matched, or high coverage
        TopicCoverage is MatchedCount / TotalReqCount,
        TopicCoverage >= 0.50 % Must satisfy at least 50% of multiple requested topics
    ),
    
    % 3. Check minimum average educational quality score
    itinerary_avg_edu_score(SiteIdsList, AvgScore),
    AvgScore >= MinAvgEduScore,
    
    itinerary_topics_covered(SiteIdsList, CoveredTopics),
    Report = edu_report(TopicCoverage, AvgScore, CoveredTopics).

% -------------------------------------------------------------------------
% 4. UNIFIED CONSTRAINT VALIDATOR
% -------------------------------------------------------------------------

validate_itinerary_all_constraints(Itinerary, UserPreferences, FinReport, TempReport, EduReport) :-
    Itinerary = itinerary(CityDays, Sites, Transits, DailyAllocations),
    UserPreferences = user_pref(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore),
    
    % 1. Financial check
    total_itinerary_financials(CityDays, Sites, Transits, TotalCost, FinBreakdown),
    check_financial_constraint(TotalCost, MaxBudget, Margin),
    FinReport = financial_ok(TotalCost, MaxBudget, Margin, FinBreakdown),
    
    % 2. Temporal check
    check_temporal_constraint(CityDays, Days, Season, Pace, DailyAllocations),
    TempReport = temporal_ok(Days, Season, Pace),
    
    % 3. Educational check
    check_educational_constraint(Sites, DesiredTopics, EduLevel, MinEduScore, EduReport).
