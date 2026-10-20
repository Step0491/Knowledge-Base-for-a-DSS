% =========================================================================
% REGOLE DI DECISIONE: dss_rules.pl
% Decision Support System (DSS) - Music & Health Recommendation
% =========================================================================

:- consult('knowledge_base.pl').

% -------------------------------------------------------------------------
% 1. REGOLE DI AMMISSIBILITÀ BASATE SULL'ATTIVITÀ CORRENTE
% -------------------------------------------------------------------------

%! ammissibile_per_attivita(+BranoId, +Attivita)
% Verifica che il brano rispetti i vincoli cognitivi o motori dell'attività.

% In caso di studio o lavoro profondo: il brano DEVE essere strumentale (>= 0.70)
% per evitare che le parole cantate interferiscano con la memoria verbale.
ammissibile_per_attivita(BranoId, deep_focus_study) :-
    !,
    brano(BranoId, _, _, _, _, _, _, Strumentale),
    Strumentale >= 0.70.

% In caso di corsa cardio: il brano deve avere un tempo sufficientemente rapido
% (BPM >= 120) e una carica energetica elevata (Energia >= 0.70) per sincronizzarsi col passo.
ammissibile_per_attivita(BranoId, cardio_running) :-
    !,
    brano(BranoId, _, _, _, BPM, _, Energia, _),
    BPM >= 120.0,
    Energia >= 0.70.

% Per tutte le altre attività non vi sono vincoli restrittivi specifici.
ammissibile_per_attivita(_, _).

% -------------------------------------------------------------------------
% 2. REGOLE DI AMMISSIBILITÀ BASATE SULL'OBIETTIVO DI SALUTE
% -------------------------------------------------------------------------

%! ammissibile_per_obiettivo(+BranoId, +Obiettivo)
% Verifica che le caratteristiche acustiche del brano soddisfino l'obiettivo clinico.

% Riduzione dello stress acuto: ritmo calmo (BPM <= 75), bassa energia e brano strumentale.
ammissibile_per_obiettivo(BranoId, stress_downregulation) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    BPM =< 75.0,
    Energia =< 0.35,
    Strumentale >= 0.70.

% Massimizzazione performance cardio: ritmo veloce (>= 120 BPM) e massima energia.
ammissibile_per_obiettivo(BranoId, cardio_peak_performance) :-
    brano(BranoId, _, _, _, BPM, _, Energia, _),
    BPM >= 120.0,
    Energia >= 0.75.

% Stato di focus e concentrazione (Flow): tempo medio (70-95 BPM) e musica strumentale.
ammissibile_per_obiettivo(BranoId, deep_focus_flow) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    BPM >= 70.0, BPM =< 95.0,
    Energia =< 0.55,
    Strumentale >= 0.70.

% Induzione del sonno: ritmo molto lento (<= 64 BPM), energia quasi azzerata e acustico.
ammissibile_per_obiettivo(BranoId, sleep_induction) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    BPM =< 64.0,
    Energia =< 0.20,
    Strumentale >= 0.85.

% Recupero post allenamento: ritmo in decelerazione (<= 105 BPM) ed energia controllata.
ammissibile_per_obiettivo(BranoId, post_workout_recovery) :-
    brano(BranoId, _, _, _, BPM, _, Energia, _),
    BPM =< 105.0,
    Energia =< 0.55.

% Spostamento / Commute attivo: ritmo allegro (>= 95 BPM) e tono emotivo positivo (Valenza >= 0.60).
ammissibile_per_obiettivo(BranoId, active_commute_energizer) :-
    brano(BranoId, _, _, _, BPM, Valenza, _, _),
    BPM >= 95.0,
    Valenza >= 0.60.

% -------------------------------------------------------------------------
% 3. CALCOLO DEL PUNTEGGIO DI UTILITÀ (SCORING)
% -------------------------------------------------------------------------

%! calcola_punteggio(+BranoId, +UtenteId, -Punteggio)
% Calcola un punteggio da 0 a 100 per valutare quanto il brano è affine all'utente.
calcola_punteggio(BranoId, UtenteId, PunteggioFinale) :-
    utente(UtenteId, _, _, Battito, Stress, Obiettivo, GeneriPreferiti),
    brano(BranoId, _, _, Genere, BPM, Valenza, Energia, Strumentale),

    % 1. Punteggio Biometrico: vicinanza del BPM al target dell'obiettivo
    target_bpm_ideale(Obiettivo, TargetBPM),
    DiffBPM is abs(BPM - TargetBPM),
    ScoreBPM is max(20.0, 100.0 - (DiffBPM * 1.5)),

    % 2. Bonus se il genere musicale appartiene a quelli preferiti dall'utente
    ( member(Genere, GeneriPreferiti) -> BonusPref = 20.0 ; BonusPref = 0.0 ),

    % 3. Bonus per valenza positiva (aiuta la regolazione emotiva se stressato)
    ScoreValenza is Valenza * 20.0,

    % Calcolo pesato complessivo
    PunteggioGrezzo is (ScoreBPM * 0.60) + ScoreValenza + BonusPref,
    PunteggioFinale is min(100.0, PunteggioGrezzo).

% Target ideale di battito/tempo associato a ciascun obiettivo clinico
target_bpm_ideale(stress_downregulation, 65.0).
target_bpm_ideale(cardio_peak_performance, 145.0).
target_bpm_ideale(deep_focus_flow, 80.0).
target_bpm_ideale(sleep_induction, 55.0).
target_bpm_ideale(post_workout_recovery, 80.0).
target_bpm_ideale(active_commute_energizer, 110.0).

% -------------------------------------------------------------------------
% 4. RICERCA DEL BRANO OTTIMALE
% -------------------------------------------------------------------------

%! brano_valido_per_utente(+BranoId, +UtenteId)
% Il brano è valido se rispetta sia l'attività sia l'obiettivo di salute dell'utente.
brano_valido_per_utente(BranoId, UtenteId) :-
    utente(UtenteId, _, Attivita, _, _, Obiettivo, _),
    ammissibile_per_attivita(BranoId, Attivita),
    ammissibile_per_obiettivo(BranoId, Obiettivo).

%! miglior_brano(+UtenteId, -MigliorBranoId, -Punteggio)
% Seleziona il brano con il punteggio di utilità più alto tra tutti quelli validi.
miglior_brano(UtenteId, MigliorBranoId, PunteggioMax) :-
    findall(Punt-BId, (
        brano_valido_per_utente(BId, UtenteId),
        calcola_punteggio(BId, UtenteId, Punt)
    ), ListaScelte),
    ListaScelte \= [],
    sort(1, @>=, ListaScelte, [PunteggioMax-MigliorBranoId|_]).

% -------------------------------------------------------------------------
% 5. ENTRAINMENT MULTI-STADIO (ISO-PRINCIPLE)
% -------------------------------------------------------------------------

%! sessione_iso_principle(+UtenteId, -SequenzaBrani)
% Genera una sequenza a 3 gradini per calmare l'utente senza provocare rifiuto acustico:
% 1. Entry: Brano con BPM simile al battito elevato attuale (+/- 15 BPM).
% 2. Bridge: Brano a tempo intermedio (80-95 BPM) con energia contenuta.
% 3. Target: Brano lento di rilassamento profondo (< 70 BPM).
sessione_iso_principle(UtenteId, [stage(entry, Brano1), stage(bridge, Brano2), stage(target, Brano3)]) :-
    utente(UtenteId, _, _, BattitoAttuale, _, _, _),
    
    % Brano 1: aggancia lo stato eccitato
    brano(Brano1, _, _, _, BPM1, _, _, _),
    Diff1 is abs(BPM1 - BattitoAttuale),
    Diff1 =< 18.0,

    % Brano 2: ponte di rallentamento
    brano(Brano2, _, _, _, BPM2, _, Eng2, _),
    BPM2 >= 80.0, BPM2 =< 95.0,
    Eng2 =< 0.50,
    Brano2 \= Brano1,

    % Brano 3: target di rilassamento totale
    brano(Brano3, _, _, _, BPM3, _, Eng3, _),
    BPM3 =< 68.0,
    Eng3 =< 0.25,
    Brano3 \= Brano1,
    Brano3 \= Brano2,

    % Verifica monotonicità della discesa
    BPM1 >= BPM2,
    BPM2 >= BPM3,
    !.
