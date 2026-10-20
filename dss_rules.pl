% =========================================================================
% REGOLE DI DECISIONE GERARCHICHE: dss_rules.pl
% Knowledge-Based Decision Support System (Magistrale Computer Science)
% Architettura di Inferenza ad Albero AND-OR (Backward Chaining)
% =========================================================================

:- consult('knowledge_base.pl').

% -------------------------------------------------------------------------
% LIVELLO 0: META-REGOLA DI AMMISSIBILITÀ COMPLESSIVA
% -------------------------------------------------------------------------

%! brano_raccomandabile(+BranoId, +UtenteId)
% Un brano è raccomandabile se e solo se soddisfa simultaneamente tutti e 4
% i pilastri di valutazione ortogonali del sistema esperto.
brano_raccomandabile(BranoId, UtenteId) :-
    compatibile_fisiologico(BranoId, UtenteId),
    compatibile_cognitivo(BranoId, UtenteId),
    sicurezza_e_controindicazioni(BranoId, UtenteId),
    coerenza_circadiana(BranoId, UtenteId).

% -------------------------------------------------------------------------
% LIVELLO 1: PILASTRO FISIOLOGICO & BIOMETRICO
% -------------------------------------------------------------------------

%! compatibile_fisiologico(+BranoId, +UtenteId)
% Valuta la sincronizzazione tra stato autonomico dell'utente e profilo musicale.

% Caso 1: Utente in stato simpatico acuto (Stress/Battito alto) -> brano sedativo
compatibile_fisiologico(BranoId, UtenteId) :-
    stato_simpatico_acuto(UtenteId),
    !,
    brano_azione_sedativa(BranoId).

% Caso 2: Utente in regime aerobico intenso (Corsa) -> brano ad effetto ergogenico
compatibile_fisiologico(BranoId, UtenteId) :-
    regime_aerobico_cardio(UtenteId),
    !,
    brano_azione_ergogenica(BranoId).

% Caso 3: Utente in preparazione al riposo/sonno -> brano ipno-inducente
compatibile_fisiologico(BranoId, UtenteId) :-
    stato_induzione_sonno(UtenteId),
    !,
    brano_azione_somnolente(BranoId).

% Caso 4: Stato omeostatico ordinario / camminata / recupero
compatibile_fisiologico(BranoId, UtenteId) :-
    stato_omeostatico(UtenteId),
    brano_moderata_attivazione(BranoId).

% --- SOTTO-REGOLE LIVELLO 2: Riconoscimento dello Stato Fisiologico ---

stato_simpatico_acuto(UtenteId) :-
    utente(UtenteId, _, _, Battito, Stress, Obiettivo, _),
    ( Obiettivo == stress_downregulation
    ; battito_elevato(Battito), stress_critico(Stress) ).

regime_aerobico_cardio(UtenteId) :-
    utente(UtenteId, _, Attivita, Battito, _, Obiettivo, _),
    ( Obiettivo == cardio_peak_performance
    ; Attivita == cardio_running, Battito >= 120.0 ).

stato_induzione_sonno(UtenteId) :-
    utente(UtenteId, _, Attivita, _, _, Obiettivo, _),
    ( Obiettivo == sleep_induction
    ; Attivita == sleep_preparation ).

stato_omeostatico(UtenteId) :-
    \+ stato_simpatico_acuto(UtenteId),
    \+ regime_aerobico_cardio(UtenteId),
    \+ stato_induzione_sonno(UtenteId).

% --- SOTTO-REGOLE LIVELLO 3: Proprietà Acustiche Funzionali ---

brano_azione_sedativa(BranoId) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    tempo_lento(BPM),
    energia_bassa(Energia),
    Strumentale >= 0.70.

brano_azione_ergogenica(BranoId) :-
    brano(BranoId, _, _, _, BPM, _, Energia, _),
    tempo_rapido(BPM),
    energia_alta(Energia).

brano_azione_somnolente(BranoId) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    BPM =< 64.0,
    Energia =< 0.20,
    Strumentale >= 0.85.

brano_moderata_attivazione(BranoId) :-
    brano(BranoId, _, _, _, BPM, Valenza, Energia, _),
    BPM >= 70.0, BPM =< 115.0,
    Energia =< 0.65,
    Valenza >= 0.40.

% -------------------------------------------------------------------------
% LIVELLO 1: PILASTRO COGNITIVO (PROTEZIONE MEMORIA DI LAVORO)
% -------------------------------------------------------------------------

%! compatibile_cognitivo(+BranoId, +UtenteId)
% Nei task ad alto impegno intellettivo, protegge il loop fonologico da interferenze.

compatibile_cognitivo(BranoId, UtenteId) :-
    richiede_focus_cognitivo(UtenteId),
    !,
    protezione_loop_fonologico(BranoId).

compatibile_cognitivo(_, _). % Nessun vincolo cognitivo se non è in studio

richiede_focus_cognitivo(UtenteId) :-
    utente(UtenteId, _, Attivita, _, _, Obiettivo, _),
    ( Attivita == deep_focus_study ; Obiettivo == deep_focus_flow ).

protezione_loop_fonologico(BranoId) :-
    brano(BranoId, _, _, _, BPM, _, Energia, Strumentale),
    Strumentale >= 0.70,        % Assoluto divieto di parti vocali cantate
    BPM >= 70.0, BPM =< 95.0,   % Frequenza coerente con onde alfa cerebrali
    Energia =< 0.55.

% -------------------------------------------------------------------------
% LIVELLO 1: PILASTRO DI SICUREZZA MEDICA & CONTROINDICAZIONI
% -------------------------------------------------------------------------

%! sicurezza_e_controindicazioni(+BranoId, +UtenteId)
% Regole di sbarramento negative per prevenire eventi avversi o sovraccarico.

sicurezza_e_controindicazioni(BranoId, UtenteId) :-
    \+ controindicazione_tachicardia(BranoId, UtenteId),
    \+ controindicazione_iperstimolazione(BranoId, UtenteId).

% Controindicazione 1: vietato proporre musica eccitante/veloce a chi ha battito tachicardico e stress critico
controindicazione_tachicardia(BranoId, UtenteId) :-
    utente(UtenteId, _, _, Battito, Stress, _, _),
    Battito > 110.0,
    Stress > 75.0,
    brano(BranoId, _, _, _, BPM, _, Energia, _),
    ( BPM > 100.0 ; Energia > 0.60 ).

% Controindicazione 2: vietato stimolare utenti con fatica severa (rischio esaurimento)
controindicazione_iperstimolazione(BranoId, UtenteId) :-
    utente(UtenteId, _, Attivita, _, Stress, _, _),
    Attivita == high_stress_work,
    Stress > 80.0,
    brano(BranoId, _, _, _, _, _, Energia, _),
    Energia > 0.50.

% -------------------------------------------------------------------------
% LIVELLO 1: PILASTRO DI COERENZA CIRCADIANA (RITMO BIOLOGICO)
% -------------------------------------------------------------------------

%! coerenza_circadiana(+BranoId, +UtenteId)
% Regola i limiti di tempo e intensità in base al contesto temporale.

coerenza_circadiana(BranoId, UtenteId) :-
    utente(UtenteId, _, Attivita, _, _, Obiettivo, _),
    ( (Attivita == sleep_preparation ; Obiettivo == sleep_induction)
    -> brano(BranoId, _, _, _, BPM, _, Energia, _),
       BPM =< 68.0,
       Energia =< 0.30
    ;  true
    ).

% -------------------------------------------------------------------------
% LIVELLO 3: PREDICATI PRIMITIVI E SOGLIE FISIOLOGICHE
% -------------------------------------------------------------------------

battito_elevato(HR)   :- HR >= 100.0.
stress_critico(S)     :- S >= 65.0.
tempo_lento(BPM)      :- BPM =< 75.0.
tempo_rapido(BPM)     :- BPM >= 120.0.
energia_bassa(E)      :- E =< 0.35.
energia_alta(E)       :- E >= 0.70.

% -------------------------------------------------------------------------
% LIVELLO 4: SCORING MULTI-ATTRIBUTO DEI BRANI AMMISSIBILI
% -------------------------------------------------------------------------

%! calcola_utilita(+BranoId, +UtenteId, -Punteggio)
% Combina utilità biometrica, affinità emotiva e preferenza di genere.
calcola_utilita(BranoId, UtenteId, PunteggioFinale) :-
    utente(UtenteId, _, _, Battito, _, Obiettivo, GeneriPreferiti),
    brano(BranoId, _, _, Genere, BPM, Valenza, _, Strumentale),

    % Calcolo delta battito-tempo ideale
    target_frequenza_ideale(Obiettivo, TargetBPM),
    DeltaBPM is abs(BPM - TargetBPM),
    ScoreFrequenza is max(20.0, 100.0 - (DeltaBPM * 1.5)),

    % Punteggio preferenza utente (affinità culturale)
    ( member(Genere, GeneriPreferiti) -> ScoreGenere = 25.0 ; ScoreGenere = 0.0 ),

    % Modulazione valenza emotiva e purezza strumentale
    ScoreAffettivo is (Valenza * 15.0) + (Strumentale * 10.0),

    PunteggioGrezzo is (ScoreFrequenza * 0.50) + ScoreGenere + ScoreAffettivo,
    PunteggioFinale is min(100.0, PunteggioGrezzo).

target_frequenza_ideale(stress_downregulation, 65.0).
target_frequenza_ideale(cardio_peak_performance, 145.0).
target_frequenza_ideale(deep_focus_flow, 80.0).
target_frequenza_ideale(sleep_induction, 55.0).
target_frequenza_ideale(post_workout_recovery, 80.0).
target_frequenza_ideale(active_commute_energizer, 110.0).

%! miglior_brano(+UtenteId, -MigliorBranoId, -Punteggio)
% Restituisce il brano a massima utilità tra tutti quelli che superano la meta-regola.
miglior_brano(UtenteId, MigliorBranoId, PunteggioMax) :-
    findall(Punt-BId, (
        brano_raccomandabile(BId, UtenteId),
        calcola_utilita(BId, UtenteId, Punt)
    ), Candidati),
    Candidati \= [],
    sort(1, @>=, Candidati, [PunteggioMax-MigliorBranoId|_]).

% -------------------------------------------------------------------------
% MODULO D'ENTRAINMENT CLINICO: ALTSHULER'S ISO-PRINCIPLE
% -------------------------------------------------------------------------

%! sessione_iso_principle(+UtenteId, -SequenzaStadi)
% Regola di transizione dinamica per la regolazione del battito cardiaco:
% 1. Stadio Entry:   matching con battito accelerato (+/- 18 BPM)
% 2. Stadio Bridge:  decelerazione guidata a ritmo moderato (80-95 BPM)
% 3. Stadio Target:  lock sulla frequenza di riposo (<= 68 BPM)
sessione_iso_principle(UtenteId, [stage(entry, B1), stage(bridge, B2), stage(target, B3)]) :-
    utente(UtenteId, _, _, BattitoAttuale, _, _, _),
    
    % Aggancio stato presente
    brano(B1, _, _, _, BPM1, _, _, _),
    abs(BPM1 - BattitoAttuale) =< 18.0,

    % Ponte intermedio
    brano(B2, _, _, _, BPM2, _, Eng2, _),
    BPM2 >= 80.0, BPM2 =< 95.0,
    Eng2 =< 0.50,
    B2 \= B1,

    % Target parasimpatico
    brano(B3, _, _, _, BPM3, _, Eng3, _),
    BPM3 =< 68.0,
    Eng3 =< 0.25,
    B3 \= B1, B3 \= B2,

    % Invariante di monotonia decrescente del tempo
    BPM1 >= BPM2,
    BPM2 >= BPM3,
    !.
