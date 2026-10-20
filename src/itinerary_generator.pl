% =========================================================================
% Itinerary Generator Module
% Synthesizes single-city and multi-city itineraries satisfying constraints.
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(itinerary_generator, [
    generate_candidate_itineraries/2,
    pack_sites_into_days/4
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).

%! generate_candidate_itineraries(+UserPreferences, -CandidatesList)
% Synthesizes candidate itineraries respecting financial, temporal, and educational constraints.
generate_candidate_itineraries(UserPreferences, CandidatesList) :-
    UserPreferences = user_pref(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore),
    
    % Find all single-destination candidates
    findall(Itin, (
        generate_single_destination_itinerary(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore, Itin)
    ), SingleCityCandidates),
    
    % If Days >= 4, also find multi-destination connected corridor itineraries
    ( Days >= 4
    ->  findall(MultiItin, (
            generate_multi_destination_itinerary(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore, MultiItin)
        ), MultiCityCandidates)
    ;   MultiCityCandidates = []
    ),
    
    append(SingleCityCandidates, MultiCityCandidates, AllRawCandidates),
    % Deduplicate and prune
    sort(AllRawCandidates, CandidatesList).

% -------------------------------------------------------------------------
% Single Destination Candidate Generation
% -------------------------------------------------------------------------

generate_single_destination_itinerary(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore, Itinerary) :-
    % 1. Pick a valid destination matching season
    destination(DestId, _, _, _, _, _, _, _),
    destination_season_match(DestId, Season),
    
    % Preliminary daily budget filter to prune impossible branches early
    destination_daily_cost(DestId, BaseDaily),
    BaseDaily * Days < MaxBudget,
    
    % 2. Find all eligible sites in this destination matching education level
    findall(SiteId, (
        heritage_site(SiteId, _, DestId, _, _, _, _, _, _, _, _),
        site_satisfies_level(SiteId, EduLevel)
    ), AvailableSites),
    
    AvailableSites \= [],
    
    % Filter or prioritize sites covering requested topics
    filter_prioritize_sites(AvailableSites, DesiredTopics, ChosenSites),
    ChosenSites \= [],
    
    % 3. Pack sites into Days respecting daily pace limits
    pack_sites_into_days(ChosenSites, Days, Pace, DayAllocations),
    
    % Flatten allocated sites
    findall(S, (member(day(_, DSites), DayAllocations), member(S, DSites)), AllAllocatedSites),
    AllAllocatedSites \= [],
    
    CityDays = [city(DestId, Days)],
    Transits = [],
    Itinerary = itinerary(CityDays, AllAllocatedSites, Transits, DayAllocations),
    
    % Full constraint check
    validate_itinerary_all_constraints(Itinerary, user_pref(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore), _, _, _).

% -------------------------------------------------------------------------
% Multi Destination Candidate Generation (Corridor Tours)
% -------------------------------------------------------------------------

generate_multi_destination_itinerary(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore, Itinerary) :-
    % Corridor connection
    intercity_transit(Dest1, Dest2, _, _, _),
    Dest1 \= Dest2,
    destination_season_match(Dest1, Season),
    destination_season_match(Dest2, Season),
    
    % Split days between two destinations (e.g. 5 days -> 3 + 2, or 4 days -> 2 + 2)
    Days1 is max(2, Days // 2),
    Days2 is Days - Days1,
    Days2 >= 2,
    
    % Destination 1 sites
    findall(S1, (heritage_site(S1, _, Dest1, _, _, _, _, _, _, _, _), site_satisfies_level(S1, EduLevel)), Avail1),
    filter_prioritize_sites(Avail1, DesiredTopics, Chosen1),
    pack_sites_into_days(Chosen1, Days1, Pace, DayAlloc1),
    
    % Destination 2 sites
    findall(S2, (heritage_site(S2, _, Dest2, _, _, _, _, _, _, _, _), site_satisfies_level(S2, EduLevel)), Avail2),
    filter_prioritize_sites(Avail2, DesiredTopics, Chosen2),
    pack_sites_into_days(Chosen2, Days2, Pace, DayAlloc2),
    
    % Combine day allocations with correct sequential numbering
    renumber_day_allocations(DayAlloc2, Days1, ShiftedDayAlloc2),
    append(DayAlloc1, ShiftedDayAlloc2, CombinedAllocations),
    
    findall(S, (member(day(_, DS), CombinedAllocations), member(S, DS)), AllAllocatedSites),
    AllAllocatedSites \= [],
    
    CityDays = [city(Dest1, Days1), city(Dest2, Days2)],
    Transits = [transit(Dest1, Dest2)],
    Itinerary = itinerary(CityDays, AllAllocatedSites, Transits, CombinedAllocations),
    
    % Full constraint check
    validate_itinerary_all_constraints(Itinerary, user_pref(MaxBudget, Days, Season, Pace, DesiredTopics, EduLevel, MinEduScore), _, _, _).

% -------------------------------------------------------------------------
% Site Prioritization & Bin-Packing Algorithm
% -------------------------------------------------------------------------

%! filter_prioritize_sites(+AvailableSites, +DesiredTopics, -PrioritizedSites)
filter_prioritize_sites(AvailableSites, DesiredTopics, PrioritizedSites) :-
    ( DesiredTopics == [] ; DesiredTopics == [any]
    ->  PrioritizedSites = AvailableSites
    ;   % Partition into sites that match topic and others (deduplicated)
        findall(S, (member(S, AvailableSites), site_matches_any_topic(S, DesiredTopics)), MatchingSitesRaw),
        sort(MatchingSitesRaw, MatchingSites),
        findall(S, (member(S, AvailableSites), \+ member(S, MatchingSites)), OtherSites),
        ( MatchingSites \= []
        ->  append(MatchingSites, OtherSites, PrioritizedSites)
        ;   PrioritizedSites = AvailableSites
        )
    ).

site_matches_any_topic(SiteId, DesiredTopics) :-
    member(Topic, DesiredTopics),
    site_satisfies_topic(SiteId, Topic).

%! pack_sites_into_days(+Sites, +TotalDays, +Pace, -DayAllocations)
% Distributes sites into days satisfying daily visit hour capacity.
pack_sites_into_days(Sites, TotalDays, Pace, DayAllocations) :-
    pace_max_daily_hours(Pace, MaxDailyHours),
    pace_max_daily_sites(Pace, MaxDailySites),
    init_empty_days(TotalDays, EmptyDays),
    greedy_bin_pack(Sites, EmptyDays, MaxDailyHours, MaxDailySites, DayAllocations),
    % Ensure at least one site was scheduled
    member(day(_, [_|_]), DayAllocations).

init_empty_days(N, Days) :-
    numlist(1, N, Indices),
    maplist(wrap_day, Indices, Days).

wrap_day(DayNum, day(DayNum, [])).

greedy_bin_pack([], Days, _, _, Days).
greedy_bin_pack([Site|RestSites], CurrentDays, MaxHours, MaxSites, FinalDays) :-
    % Try placing Site into the first day that has enough room
    ( select(day(DNum, ExistingSites), CurrentDays, OtherDays),
      length(ExistingSites, CurrCount),
      CurrCount < MaxSites,
      maplist(dss_rules:site_duration, ExistingSites, Durations),
      sum_list(Durations, CurrHours),
      dss_rules:site_duration(Site, SiteDur),
      CurrHours + SiteDur =< MaxHours
    ->  NewDay = day(DNum, [Site|ExistingSites]),
        % Maintain day ordering
        insert_day_sorted(NewDay, OtherDays, UpdatedDays),
        greedy_bin_pack(RestSites, UpdatedDays, MaxHours, MaxSites, FinalDays)
    ;   % If no day fits this site, skip it and continue
        greedy_bin_pack(RestSites, CurrentDays, MaxHours, MaxSites, FinalDays)
    ).

insert_day_sorted(Day, [], [Day]).
insert_day_sorted(day(N, Sites), [day(M, MSites)|Rest], [day(N, Sites), day(M, MSites)|Rest]) :-
    N < M, !.
insert_day_sorted(Day, [Other|Rest], [Other|NewRest]) :-
    insert_day_sorted(Day, Rest, NewRest).

renumber_day_allocations([], _, []).
renumber_day_allocations([day(DayNum, Sites)|Rest], Offset, [day(NewDayNum, Sites)|NewRest]) :-
    NewDayNum is DayNum + Offset,
    renumber_day_allocations(Rest, Offset, NewRest).
