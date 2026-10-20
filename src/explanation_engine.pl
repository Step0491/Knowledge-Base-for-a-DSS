% =========================================================================
% Explanation Engine Module
% Generates human-interpretable justifications and failure diagnostics.
% Part of: "Knowledge Base for a DSS (Tourism, Cultural Heritage & Education)"
% =========================================================================

:- module(explanation_engine, [
    explain_recommendation/2,
    diagnose_failure/2,
    print_itinerary_card/1
]).

:- use_module('../knowledge_base/load_kb.pl').
:- use_module(dss_rules).
:- use_module(scoring_model).

%! explain_recommendation(+RankedEntry, -ExplanationReport)
explain_recommendation(score_entry(Utility, score(_, SEdu, SFin, STemp, SDiv), Itinerary), Report) :-
    Itinerary = itinerary(CityDays, Sites, Transits, DailyAllocations),
    total_itinerary_financials(CityDays, Sites, Transits, TotalCost, cost_breakdown(BaseCost, SiteFees, TransitCost, _)),
    itinerary_topics_covered(Sites, TopicsCovered),
    itinerary_avg_edu_score(Sites, AvgEdu),
    
    Report = explanation(
        utility(Utility),
        subscores(SEdu, SFin, STemp, SDiv),
        financials(TotalCost, BaseCost, SiteFees, TransitCost),
        educational(AvgEdu, TopicsCovered, Sites),
        schedule(CityDays, DailyAllocations)
    ).

%! print_itinerary_card(+RankedEntry)
% Beautiful ASCII presentation of the recommended itinerary.
print_itinerary_card(score_entry(Utility, score(_, SEdu, SFin, STemp, SDiv), Itinerary)) :-
    Itinerary = itinerary(CityDays, Sites, Transits, DailyAllocations),
    total_itinerary_financials(CityDays, Sites, Transits, TotalCost, cost_breakdown(BaseCost, SiteFees, TransitCost, _)),
    itinerary_avg_edu_score(Sites, AvgEdu),
    itinerary_topics_covered(Sites, TopicsCovered),
    
    format('~n+===========================================================================+~n'),
    format('|                   SMART TRAVEL ADVISOR RECOMMENDATION                     |~n'),
    format('+===========================================================================+~n'),
    format('|  Overall Utility Score:  ~|~t~2f~4+ / 100                                        |~n', [Utility]),
    format('|  Dimension Scores:       Edu: ~2f | Fin: ~2f | Temp: ~2f | Div: ~2f    |~n', [SEdu, SFin, STemp, SDiv]),
    format('+---------------------------------------------------------------------------+~n'),
    format('|  DESTINATIONS VISITED:                                                    |~n'),
    forall(member(city(CId, D), CityDays), (
        destination(CId, CName, Country, Region, _, _, _, _),
        format('|    * ~w, ~w (~w) - ~w days~n', [CName, Country, Region, D])
    )),
    ( Transits \= []
    ->  format('|  INTER-CITY TRANSIT:                                                      |~n'),
        forall(member(transit(O, D), Transits), (
            intercity_transit(O, D, H, C, Mode),
            format('|    * ~w -> ~w: ~1f hrs via ~w (~2f EUR)~n', [O, D, H, Mode, C])
        ))
    ;   true
    ),
    format('+---------------------------------------------------------------------------+~n'),
    format('|  FINANCIAL SUMMARY:                                                       |~n'),
    format('|    Total Itinerary Cost: ~2f EUR~n', [TotalCost]),
    format('|    - Accommodation, Meals & Local Transit: ~2f EUR~n', [BaseCost]),
    format('|    - UNESCO Site Admissions:               ~2f EUR~n', [SiteFees]),
    format('|    - Inter-City Travel Tickets:            ~2f EUR~n', [TransitCost]),
    format('+---------------------------------------------------------------------------+~n'),
    format('|  EDUCATIONAL MERIT & TOPICS COVERED:                                      |~n'),
    format('|    Average Educational Value: ~1f / 10~n', [AvgEdu]),
    format('|    Key Disciplines Covered:~n'),
    forall(member(Top, TopicsCovered), format('|      - ~w~n', [Top])),
    format('+---------------------------------------------------------------------------+~n'),
    format('|  DAY-BY-DAY ITINERARY:                                                    |~n'),
    forall(member(day(DayNum, DaySites), DailyAllocations), (
        format('|    Day ~w:~n', [DayNum]),
        ( DaySites == []
        ->  format('|      [Rest or cultural immersion day]~n')
        ;   forall(member(SId, DaySites), (
                heritage_site(SId, SName, _, _, _, Era, _, _, Dur, Fee, EScore),
                format('|      * ~w~n', [SName]),
                format('|        Duration: ~1fh | Fee: ~2f EUR | Era: ~w | EduScore: ~w/10~n', [Dur, Fee, Era, EScore])
            ))
        )
    )),
    format('+===========================================================================+~n~n').

%! diagnose_failure(+UserPreferences, -DiagnosticList)
% Identifies bottlenecks when no itinerary satisfies all constraints.
diagnose_failure(user_pref(MaxBudget, Days, Season, _Pace, DesiredTopics, _EduLevel, MinEduScore), Diagnostics) :-
    findall(Reason, (
        % 1. Check budget vs duration
        findall(Base, destination_daily_cost(_, Base), AllBases),
        min_list(AllBases, MinDaily),
        MinPossibleStay is MinDaily * Days,
        ( MaxBudget < MinPossibleStay
        ->  format(atom(Reason), 'BUDGET_TOO_LOW: Maximum budget (~2f EUR) is lower than minimal stay cost (~2f EUR) for ~w days across all destinations.', [MaxBudget, MinPossibleStay, Days])
        ;   true
        )
        ;
        % 2. Check season availability
        findall(D, destination_season_match(D, Season), MatchingSeasonDests),
        ( MatchingSeasonDests == []
        ->  format(atom(Reason), 'SEASON_MISMATCH: No destinations operate in season "~w". Available seasons: spring, summer, autumn, winter.', [Season])
        ;   true
        )
        ;
        % 3. Check topic availability
        ( DesiredTopics \= [], DesiredTopics \= [any]
        ->  findall(S, (member(T, DesiredTopics), site_satisfies_topic(S, T)), MatchingTopicSites),
            ( MatchingTopicSites == []
            ->  format(atom(Reason), 'TOPICS_UNAVAILABLE: No UNESCO sites found matching desired topics ~w.', [DesiredTopics])
            ;   true
            )
        ;   true
        )
        ;
        % 4. Check educational quality threshold
        ( MinEduScore > 10
        ->  format(atom(Reason), 'INVALID_EDU_SCORE: MinEduScore (~w) exceeds maximum possible rating (10).', [MinEduScore])
        ;   true
        )
    ), RawDiagnostics),
    ( RawDiagnostics == []
    ->  Diagnostics = ['CONSTRAINTS_MUTUALLY_EXCLUSIVE: The combination of pace, season, budget, and topics leaves no candidate satisfying all simultaneous bounds. Try increasing budget, relaxing pace, or broadening topics.']
    ;   Diagnostics = RawDiagnostics
    ).
