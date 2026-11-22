% =========================================================================
% INFERENCE ENGINE & EXPLANATION SHELL: inference_engine.pl
% Domain-Independent Meta-Interpreter + Working Memory + HOW/WHY + Ranking
% Compatible with SWI-Prolog (and ISO-compliant Prolog interpreters)
% =========================================================================

:- consult('knowledge_base.pl').
:- consult('kb_rules.pl').

% -------------------------------------------------------------------------
% 1. WORKING MEMORY (Short-Term Memory for Current Case)
% -------------------------------------------------------------------------

:- dynamic wm_fact/1.
:- dynamic interactive_mode/1.
:- dynamic last_proof/3.

% Default: non-interactive batch mode (for automated queries & test suites)
interactive_mode(false).

%! set_interactive(+Bool)
set_interactive(Bool) :-
    retractall(interactive_mode(_)),
    assertz(interactive_mode(Bool)).

%! reset_wm
% Clears all dynamic case facts from Working Memory.
reset_wm :-
    retractall(wm_fact(_)),
    retractall(last_proof(_, _, _)).

%! load_user_to_wm(+UserId)
% Loads a known smartwatch profile from Long-Term KB into Working Memory.
load_user_to_wm(UserId) :-
    user(UserId, Name, Activity, HR, Stress, Goal, Genres),
    reset_wm,
    assertz(wm_fact(user_name(UserId, Name))),
    assertz(wm_fact(user_activity(UserId, Activity))),
    assertz(wm_fact(user_heart_rate(UserId, HR))),
    assertz(wm_fact(user_stress(UserId, Stress))),
    assertz(wm_fact(user_goal(UserId, Goal))),
    assertz(wm_fact(user_preferred_genres(UserId, Genres))).

%! set_custom_user_wm(+UserId, +Name, +Activity, +HR, +Stress, +Goal, +Genres)
% Populates Working Memory with custom live telemetry entered by the user.
set_custom_user_wm(UserId, Name, Activity, HR, Stress, Goal, Genres) :-
    reset_wm,
    assertz(wm_fact(user_name(UserId, Name))),
    assertz(wm_fact(user_activity(UserId, Activity))),
    assertz(wm_fact(user_heart_rate(UserId, HR))),
    assertz(wm_fact(user_stress(UserId, Stress))),
    assertz(wm_fact(user_goal(UserId, Goal))),
    assertz(wm_fact(user_preferred_genres(UserId, Genres))).

%! in_list(?Elem, ?List)
in_list(X, [X|_]).
in_list(X, [_|T]) :- in_list(X, T).

%! for_each(+Cond, +Action)
for_each(Cond, Action) :-
    \+ (Cond, \+ Action).

%! show_wm
% Displays the current contents of Short-Term Working Memory.
show_wm :-
    format('~n--- CURRENT WORKING MEMORY (Short-Term Case Facts) ---~n'),
    ( wm_fact(_)
    -> for_each(wm_fact(F), format('  fact: ~w~n', [F]))
    ;  format('  (Working Memory is empty)~n')
    ),
    format('-------------------------------------------------------~n').

% -------------------------------------------------------------------------
% 2. TAXONOMY & SENSOR / TRACK PRIMITIVE EVALUATORS
% -------------------------------------------------------------------------

%! ancestor_class(+Concept, ?Ancestor)
ancestor_class(X, Y) :- is_a(X, Y).
ancestor_class(X, Z) :- is_a(X, Y), ancestor_class(Y, Z).

%! primitive_fact(+Goal, -Confidence)
% Evaluates Working Memory facts, taxonomy relationships, and numeric metrics.

% Direct Working Memory lookup
primitive_fact(user_activity(U, A), 1.0) :-
    wm_fact(user_activity(U, A)).
primitive_fact(user_goal(U, G), 1.0) :-
    wm_fact(user_goal(U, G)).
primitive_fact(user_activity_context(U, ContextClass), 1.0) :-
    wm_fact(user_activity(U, Act)),
    ( Act == ContextClass ; ancestor_class(Act, ContextClass) ).

% Cached interactive user answers
primitive_fact(Goal, 0.90) :-
    wm_fact(user_answer(Goal, yes)).

% Biometric thresholds (with graded confidence in [0.75, 1.0])
primitive_fact(high_heart_rate(U), Conf) :-
    wm_fact(user_heart_rate(U, HR)),
    HR >= 100.0,
    Conf is min(1.0, 0.80 + (HR - 100.0) / 100.0).

primitive_fact(very_high_heart_rate(U), 1.0) :-
    wm_fact(user_heart_rate(U, HR)),
    HR > 110.0.

primitive_fact(workout_heart_rate(U), Conf) :-
    wm_fact(user_heart_rate(U, HR)),
    HR >= 120.0,
    Conf is min(1.0, 0.85 + (HR - 120.0) / 100.0).

primitive_fact(high_stress(U), Conf) :-
    wm_fact(user_stress(U, S)),
    S >= 65.0,
    Conf is min(1.0, 0.80 + (S - 65.0) / 100.0).

primitive_fact(very_high_stress(U), 1.0) :-
    wm_fact(user_stress(U, S)),
    S > 75.0.

primitive_fact(severe_stress(U), 1.0) :-
    wm_fact(user_stress(U, S)),
    S > 80.0.

% Track acoustic primitives
primitive_fact(slow_beat(T), Conf) :-
    track(T, _, _, _, BPM, _, _, _),
    BPM =< 75.0,
    Conf is min(1.0, 0.85 + (75.0 - BPM) / 100.0).

primitive_fact(very_slow_beat(T), Conf) :-
    track(T, _, _, _, BPM, _, _, _),
    BPM =< 64.0,
    Conf is min(1.0, 0.85 + (64.0 - BPM) / 100.0).

primitive_fact(steady_study_beat(T), 1.0) :-
    track(T, _, _, _, BPM, _, _, _),
    BPM >= 70.0, BPM =< 95.0.

primitive_fact(moderate_beat(T), 1.0) :-
    track(T, _, _, _, BPM, _, _, _),
    BPM >= 70.0, BPM =< 115.0.

primitive_fact(fast_beat(T), Conf) :-
    track(T, _, _, _, BPM, _, _, _),
    BPM >= 120.0,
    Conf is min(1.0, 0.85 + (BPM - 120.0) / 150.0).

primitive_fact(low_energy(T), Conf) :-
    track(T, _, _, _, _, _, E, _),
    E =< 0.35,
    Conf is min(1.0, 0.85 + (0.35 - E)).

primitive_fact(very_low_energy(T), 1.0) :-
    track(T, _, _, _, _, _, E, _),
    E =< 0.20.

primitive_fact(moderate_or_low_energy(T), 1.0) :-
    track(T, _, _, _, _, _, E, _),
    E =< 0.55.

primitive_fact(controlled_energy(T), 1.0) :-
    track(T, _, _, _, _, _, E, _),
    E =< 0.65.

primitive_fact(high_energy(T), Conf) :-
    track(T, _, _, _, _, _, E, _),
    E >= 0.70,
    Conf is min(1.0, 0.80 + (E - 0.70)).

primitive_fact(mostly_instrumental(T), Conf) :-
    track(T, _, _, _, _, _, _, Inst),
    Inst >= 0.70,
    Conf is min(1.0, 0.80 + (Inst - 0.70)).

primitive_fact(pure_instrumental(T), 1.0) :-
    track(T, _, _, _, _, _, _, Inst),
    Inst >= 0.85.

primitive_fact(positive_mood(T), 1.0) :-
    track(T, _, _, _, _, Val, _, _),
    Val >= 0.40.

primitive_fact(gentle_sleep_ceiling(T), 1.0) :-
    track(T, _, _, _, BPM, _, E, _),
    BPM =< 68.0, E =< 0.30.

primitive_fact(fast_or_intense_track(T), 1.0) :-
    track(T, _, _, _, BPM, _, E, _),
    ( BPM > 100.0 ; E > 0.60 ).

primitive_fact(energy_above_half(T), 1.0) :-
    track(T, _, _, _, _, _, E, _),
    E > 0.50.

% -------------------------------------------------------------------------
% 3. META-INTERPRETER WITH PROOF TREE, UNCERTAINTY & WHY/HOW DIALOGUE
% -------------------------------------------------------------------------

%! prove(+Goal, +Trace, -ProofTree, -Confidence)
% Separates inference control from declarative KB rules.

prove(and([]), _, empty_and, 1.0) :- !.

prove(and([G|Gs]), Trace, and_proof(P1, P2), Conf) :-
    !,
    prove(G, Trace, P1, C1),
    prove(and(Gs), Trace, P2, C2),
    Conf is min(C1, C2).

prove(or([G|_]), Trace, Proof, Conf) :-
    prove(G, Trace, Proof, Conf).
prove(or([_|Gs]), Trace, Proof, Conf) :-
    !,
    prove(or(Gs), Trace, Proof, Conf).

prove(not(G), Trace, not_proof(G, Conf), Conf) :-
    !,
    ( prove(G, Trace, _, C)
    -> C < 0.5,
       Conf is 1.0 - C
    ;  Conf = 1.0
    ).

% Case A: Fact in Working Memory or base domain evaluator
prove(Goal, _Trace, fact_proof(Goal, Conf), Conf) :-
    primitive_fact(Goal, Conf),
    !.

% Case B: Declarative rule in Long-Term KB
prove(Goal, Trace, rule_proof(RuleId, Desc, Goal, SubProof, Conf), Conf) :-
    rule(RuleId, Goal, Body, Weight, Desc),
    prove(Body, [trace_step(RuleId, Goal, Desc)|Trace], SubProof, BodyConf),
    Conf is BodyConf * Weight.

% Case C: Interactive Askable (only if interactive_mode(true) and not yet answered)
prove(Goal, Trace, asked_proof(Goal, yes, 0.90), 0.90) :-
    interactive_mode(true),
    askable(Goal, Question),
    \+ wm_fact(user_answer(Goal, _)),
    ask_user_why(Goal, Question, Trace, Ans),
    assertz(wm_fact(user_answer(Goal, Ans))),
    Ans == yes.

%! ask_user_why(+Goal, +Question, +Trace, -Answer)
% Handles yes/no/why dialogue inspired by Ferilli's ES shell.
ask_user_why(Goal, Question, Trace, Answer) :-
    format('~n[?] ~w? (yes. / no. / why.): ', [Question]),
    read(Input),
    ( Input == why
    -> print_why_trace(Goal, Trace),
       ask_user_why(Goal, Question, Trace, Answer)
    ; Input == yes
    -> Answer = yes
    ; Input == no
    -> Answer = no
    ; format('    Please answer yes., no., or why.~n'),
      ask_user_why(Goal, Question, Trace, Answer)
    ).

print_why_trace(Goal, Trace) :-
    format('~n    [WHY] Asking about "~w" to evaluate:~n', [Goal]),
    ( Trace == []
    -> format('          -> Top-level goal.~n')
    ;  for_each(in_list(trace_step(RId, G, Desc), Trace),
                format('          -> Rule [~w] (~w): ~w~n', [RId, G, Desc]))
    ).

% -------------------------------------------------------------------------
% 4. HOW EXPLANATION PRINTER (Renders Actual Proof Tree)
% -------------------------------------------------------------------------

%! print_proof_tree(+ProofTree, +Indent)
print_proof_tree(empty_and, _).
print_proof_tree(and_proof(P1, P2), Indent) :-
    print_proof_tree(P1, Indent),
    print_proof_tree(P2, Indent).
print_proof_tree(not_proof(G, Conf), Indent) :-
    indent_spaces(Indent),
    format('NOT(~w) holds [confidence: ~2f]~n', [G, Conf]).
print_proof_tree(fact_proof(Goal, Conf), Indent) :-
    indent_spaces(Indent),
    format('FACT: ~w [confidence: ~2f]~n', [Goal, Conf]).
print_proof_tree(asked_proof(Goal, Ans, Conf), Indent) :-
    indent_spaces(Indent),
    format('USER INPUT: ~w = ~w [confidence: ~2f]~n', [Goal, Ans, Conf]).
print_proof_tree(rule_proof(RuleId, Desc, Goal, SubProof, Conf), Indent) :-
    indent_spaces(Indent),
    format('RULE [~w] -> ~w [conf: ~2f] (~w)~n', [RuleId, Goal, Conf, Desc]),
    NextIndent is Indent + 2,
    print_proof_tree(SubProof, NextIndent).

indent_spaces(0) :- !.
indent_spaces(N) :-
    N > 0,
    write(' '),
    N1 is N - 1,
    indent_spaces(N1).

% -------------------------------------------------------------------------
% 5. MULTI-ATTRIBUTE UTILITY RANKING (Exact 0.50 / 0.30 / 0.20 Formula)
% -------------------------------------------------------------------------

ideal_target_bpm(stress_downregulation, 65.0).
ideal_target_bpm(cardio_peak_performance, 145.0).
ideal_target_bpm(deep_focus_flow, 80.0).
ideal_target_bpm(sleep_induction, 55.0).
ideal_target_bpm(post_workout_recovery, 80.0).
ideal_target_bpm(active_commute_energizer, 110.0).

effective_goal(UserId, EffectiveGoal) :-
    wm_fact(user_goal(UserId, Goal)),
    Goal \== unknown,
    !,
    EffectiveGoal = Goal.
effective_goal(UserId, sleep_induction) :-
    wm_fact(user_answer(preparing_for_sleep(UserId), yes)),
    !.
effective_goal(UserId, deep_focus_flow) :-
    wm_fact(user_answer(requires_no_lyrics(UserId), yes)),
    !.
effective_goal(UserId, stress_downregulation) :-
    wm_fact(user_heart_rate(UserId, HR)), HR >= 100.0,
    wm_fact(user_stress(UserId, S)), S >= 65.0,
    !.
effective_goal(_, post_workout_recovery).

%! calculate_utility(+TrackId, +UserId, +RuleConfidence, -UtilityScore)
% U(t, u) = 100 * (0.50 * S_bio + 0.30 * S_mood + 0.20 * S_pref) * (0.85 + 0.15 * RuleConf)
calculate_utility(TrackId, UserId, RuleConf, FinalScore) :-
    effective_goal(UserId, Goal),
    wm_fact(user_preferred_genres(UserId, PreferredGenres)),
    track(TrackId, _, _, Genre, BPM, Valence, Energy, Instrumentalness),

    % 1. S_bio: Tempo proximity to ideal goal BPM
    ( ideal_target_bpm(Goal, TargetBPM) -> true ; TargetBPM = 80.0 ),
    S_bio is max(0.0, 1.0 - (abs(BPM - TargetBPM) / 60.0)),

    % 2. S_mood: Goal-aligned affective/acoustic match
    mood_score(Goal, Valence, Energy, Instrumentalness, S_mood),

    % 3. S_pref: Direct genre match (1.0) or semantic family similarity (0.5)
    genre_similarity(Genre, PreferredGenres, S_pref),

    BaseUtility is 100.0 * ((0.50 * S_bio) + (0.30 * S_mood) + (0.20 * S_pref)),
    FinalScore is min(100.0, BaseUtility * (0.85 + (0.15 * RuleConf))).

mood_score(cardio_peak_performance, Valence, Energy, _, Score) :-
    !,
    Score is (0.50 * Valence) + (0.50 * Energy).
mood_score(active_commute_energizer, Valence, Energy, _, Score) :-
    !,
    Score is (0.70 * Valence) + (0.30 * Energy).
mood_score(_, Valence, _, Instrumentalness, Score) :-
    Score is (0.60 * Instrumentalness) + (0.40 * Valence).

genre_similarity(Genre, PreferredGenres, 1.0) :-
    in_list(Genre, PreferredGenres),
    !.
genre_similarity(Genre, PreferredGenres, 0.5) :-
    is_a(Genre, Family),
    in_list(Pref, PreferredGenres),
    is_a(Pref, Family),
    !.
genre_similarity(_, _, 0.0).

% -------------------------------------------------------------------------
% 6. DESCENDING SORT (ISO / SWI / YAP Portable via keysort + reverse)
% -------------------------------------------------------------------------

reverse_list(List, Rev) :-
    reverse_acc(List, [], Rev).

reverse_acc([], Acc, Acc).
reverse_acc([H|T], Acc, Rev) :-
    reverse_acc(T, [H|Acc], Rev).

sort_candidates_desc(Pairs, DescPairs) :-
    keysort(Pairs, AscPairs),
    reverse_list(AscPairs, DescPairs).

% -------------------------------------------------------------------------
% 7. TOP-LEVEL INFERENCE QUERIES
% -------------------------------------------------------------------------

%! evaluate_candidates(+UserId, -RankedList)
% RankedList is a list of item(Score, TrackId, Conf, Proof) sorted descending.
evaluate_candidates(UserId, RankedList) :-
    findall(Score-item(Score, TId, Conf, Proof), (
        track(TId, _, _, _, _, _, _, _),
        prove(recommendable(TId, UserId), [], Proof, Conf),
        calculate_utility(TId, UserId, Conf, Score)
    ), RawPairs),
    RawPairs \= [],
    sort_candidates_desc(RawPairs, SortedPairs),
    extract_items(SortedPairs, RankedList).

extract_items([], []).
extract_items([_-Item|T], [Item|R]) :-
    extract_items(T, R).

%! best_track(+UserId, -BestTrackId, -MaxScore)
% Preserves clean entry point; loads UserId into Working Memory if not already loaded.
best_track(UserId, BestTrackId, MaxScore) :-
    ( wm_fact(user_goal(UserId, _)) -> true ; load_user_to_wm(UserId) ),
    evaluate_candidates(UserId, [item(MaxScore, BestTrackId, Conf, Proof)|_]),
    retractall(last_proof(UserId, _, _)),
    assertz(last_proof(UserId, BestTrackId, proof_info(Conf, Proof))).

%! best_track_with_proof(+UserId, -BestTrackId, -MaxScore, -Conf, -Proof)
best_track_with_proof(UserId, BestTrackId, MaxScore, Conf, Proof) :-
    ( wm_fact(user_goal(UserId, _)) -> true ; load_user_to_wm(UserId) ),
    evaluate_candidates(UserId, [item(MaxScore, BestTrackId, Conf, Proof)|_]),
    retractall(last_proof(UserId, _, _)),
    assertz(last_proof(UserId, BestTrackId, proof_info(Conf, Proof))).

%! explain_last_decision(+UserId)
explain_last_decision(UserId) :-
    ( last_proof(UserId, TrackId, proof_info(Conf, Proof))
    -> track(TrackId, Title, Artist, _, _, _, _, _),
       format('~n=== HOW DEDUCTION WAS REACHED ("~w" by ~w | Conf: ~2f) ===~n', [Title, Artist, Conf]),
       print_proof_tree(Proof, 2),
       format('========================================================================~n')
    ;  format('~n[!] No recent decision found for ~w. Run recommend first.~n', [UserId])
    ).

% -------------------------------------------------------------------------
% 8. GRADUAL CALM PLAYLIST (3-Stage Entrainment / Iso-Principle Search)
% -------------------------------------------------------------------------

%! gradual_calm_playlist(+UserId, -StageSequence)
% Searches for the highest-utility 3-stage downward-tempo trajectory:
% Entry (close to current HR) -> Bridge (80-95 BPM) -> Target (<=68 BPM).
gradual_calm_playlist(UserId, [stage(entry, T1), stage(bridge, T2), stage(target, T3)]) :-
    ( wm_fact(user_heart_rate(UserId, CurrentHR))
    -> true
    ;  load_user_to_wm(UserId),
       wm_fact(user_heart_rate(UserId, CurrentHR))
    ),
    findall(TotalFit-seq(T1, T2, T3), (
        track(T1, _, _, _, BPM1, _, Eng1, Inst1),
        abs(BPM1 - CurrentHR) =< 18.0,
        Eng1 =< 0.60,
        Inst1 >= 0.75,

        track(T2, _, _, _, BPM2, _, Eng2, Inst2),
        BPM2 >= 80.0, BPM2 =< 95.0,
        Eng2 =< 0.50, Inst2 >= 0.70,
        T2 \= T1,

        track(T3, _, _, _, BPM3, _, Eng3, Inst3),
        BPM3 =< 68.0,
        Eng3 =< 0.25, Inst3 >= 0.85,
        T3 \= T1, T3 \= T2,

        BPM1 >= BPM2,
        BPM2 >= BPM3,

        % Score prefers closer entry pacing, gentle energy, and calm instrumental target
        EntryFit is max(0.0, 20.0 - abs(BPM1 - CurrentHR)),
        TotalFit is EntryFit + ((1.0 - Eng1) * 5.0) + (Inst2 * 10.0) + (Inst3 * 15.0)
    ), Sequences),
    Sequences \= [],
    sort_candidates_desc(Sequences, [_-seq(T1, T2, T3)|_]).
