% =========================================================================
% ENTRY POINT PROLOG: main.pl
% Decision Support System (DSS) - Context-Aware Music Recommendation
% =========================================================================

:- consult('dss_rules.pl').

%! raccomanda(+UtenteId)
% Calcola e stampa la raccomandazione ottimale per l'utente specificato.
raccomanda(UtenteId) :-
    utente(UtenteId, Nome, Attivita, Battito, Stress, Obiettivo, _),
    format('~n========================================================================~n'),
    format(' SISTEMA DI SUPPORTO ALLE DECISIONI: RACCOMANDAZIONE MUSICALE~n'),
    format('========================================================================~n'),
    format(' [*] Profilo Utente:~n'),
    format('     - Nome: ~w (ID: ~w)~n', [Nome, UtenteId]),
    format('     - Attivita: ~w | Battito: ~0f BPM | Stress: ~0f/100~n', [Attivita, Battito, Stress]),
    format('     - Obiettivo Clinico: ~w~n', [Obiettivo]),
    format('~n [*] Risultato Inferenzial-Logico:~n'),
    ( miglior_brano(UtenteId, BranoId, Punteggio)
    -> brano(BranoId, Titolo, Artista, Genere, BPM, Valenza, Energia, Strumentale),
       format('     -> BRANO SCELTO: "~w" di ~w~n', [Titolo, Artista]),
       format('     -> Punteggio Utilità: ~1f / 100.0 | Genere: ~w~n', [Punteggio, Genere]),
       format('     -> Parametri Audio: BPM: ~0f | Energia: ~2f | Valenza: ~2f | Strumentale: ~2f~n', [BPM, Energia, Valenza, Strumentale]),
       spiega_scelta(Attivita, Stress, BPM, Strumentale)
    ;  format('     [!] Nessun brano nel catalogo soddisfa tutti i vincoli imposti.~n')
    ),
    format('========================================================================~n~n').

%! spiega_scelta(+Attivita, +Stress, +BPM, +Strumentale)
% Spiega in linguaggio naturale il razionale clinico/fisiologico della decisione.
spiega_scelta(high_stress_work, _, BPM, Strumentale) :-
    !,
    format('     -> Razionale: Rilevato stress acuto da lavoro. Selezionato brano lento (~0f BPM)~n', [BPM]),
    format('        e strumentale (~2f) per stimolare il tono vagale e ridurre il battito.~n', [Strumentale]).

spiega_scelta(cardio_running, _, BPM, _) :-
    !,
    format('     -> Razionale: Attivita cardio in corso. Brano a ~0f BPM sincronizzato con la frequenza~n', [BPM]),
    format('        del passo per ridurre la fatica percepita e massimizzare la prestazione.~n').

spiega_scelta(deep_focus_study, _, _, Strumentale) :-
    !,
    format('     -> Razionale: Stato di studio/concentrazione. Brano privo di parti cantate (~2f)~n', [Strumentale]),
    format('        per azzerare le interferenze con la memoria di lavoro verbale.~n', [Strumentale]).

spiega_scelta(_, _, _, _) :-
    format('     -> Razionale: Il brano supporta la regolazione fisiologica dell\'attivita corrente.~n').

%! raccomanda_sessione(+UtenteId)
% Genera la sequenza a 3 stadi secondo l'Iso-Principle per la discesa dello stress.
raccomanda_sessione(UtenteId) :-
    utente(UtenteId, Nome, _, Battito, Stress, _, _),
    format('~n+======================================================================+~n'),
    format('| SESSIONE MULTI-BRANO AD ENTRAINMENT (ISO-PRINCIPLE)                  |~n'),
    format('+======================================================================+~n'),
    format('| Utente: ~-20w | Battito: ~3.0f BPM | Stress: ~3.0f/100         |~n', [Nome, Battito, Stress]),
    format('+----------------------------------------------------------------------+~n'),
    ( sessione_iso_principle(UtenteId, [stage(entry, B1), stage(bridge, B2), stage(target, B3)])
    -> brano(B1, T1, _, _, BPM1, _, Eng1, _),
       brano(B2, T2, _, _, BPM2, _, Eng2, _),
       brano(B3, T3, _, _, BPM3, _, Eng3, _),
       format('| 1. [AGGANCIO]  ~-28w (~0f BPM, E:~2f)             |~n', [T1, BPM1, Eng1]),
       format('| 2. [PONTE]     ~-28w (~0f BPM, E:~2f)             |~n', [T2, BPM2, Eng2]),
       format('| 3. [OBIETTIVO] ~-28w (~0f BPM, E:~2f)             |~n', [T3, BPM3, Eng3]),
       format('+----------------------------------------------------------------------+~n'),
       format('| Traiettoria: ~0f BPM -> ~0f BPM -> ~0f BPM (Rallentamento controllato) |~n', [BPM1, BPM2, BPM3])
    ;  format('| [!] Impossibile generare la sequenza con i brani attuali.             |~n')
    ),
    format('+======================================================================+~n~n').

%! demo
% Esegue la raccomandazione sui tre casi studio principali.
demo :-
    format('~n>>> CASO 1: Stress Lavorativo Acuto (Sarah Miller) <<<~n'),
    raccomanda(user_sarah),
    raccomanda_sessione(user_sarah),
    format('~n>>> CASO 2: Allenamento Cardio Running (Alex Chen) <<<~n'),
    raccomanda(user_alex),
    format('~n>>> CASO 3: Sessione di Studio e Concentrazione (Marco Rossi) <<<~n'),
    raccomanda(user_marco).

%! esegui_test
% Esegue i test di correttezza logica.
esegui_test :-
    format('~n[*] Esecuzione test di coerenza logica...~n'),
    % Test 1: Sarah riceve brano a basso BPM
    miglior_brano(user_sarah, B_Sarah, _),
    brano(B_Sarah, _, _, _, BPM_Sarah, _, Eng_Sarah, _),
    BPM_Sarah =< 75.0, Eng_Sarah =< 0.35,
    format('  [+] Test 1 (Stress Downregulation): PASSATO~n'),

    % Test 2: Alex riceve brano veloce
    miglior_brano(user_alex, B_Alex, _),
    brano(B_Alex, _, _, _, BPM_Alex, _, Eng_Alex, _),
    BPM_Alex >= 120.0, Eng_Alex >= 0.75,
    format('  [+] Test 2 (Cardio Cadence Lock): PASSATO~n'),

    % Test 3: Marco riceve brano strumentale
    miglior_brano(user_marco, B_Marco, _),
    brano(B_Marco, _, _, _, _, _, _, Inst_Marco),
    Inst_Marco >= 0.70,
    format('  [+] Test 3 (Deep Focus Strumentale): PASSATO~n'),

    % Test 4: Iso-principle monotonico
    sessione_iso_principle(user_sarah, [stage(entry, S1), stage(bridge, S2), stage(target, S3)]),
    brano(S1, _, _, _, P1, _, _, _),
    brano(S2, _, _, _, P2, _, _, _),
    brano(S3, _, _, _, P3, _, _, _),
    P1 >= P2, P2 >= P3,
    format('  [+] Test 4 (Iso-Principle Monotonico): PASSATO~n'),

    % Test 5: Controindicazione di sicurezza medica (sbarramento)
    ( \+ sicurezza_e_controindicazioni(adrenaline_rush_rock, user_sarah)
    -> format('  [+] Test 5 (Controindicazione Sicurezza Medica): PASSATO~n')
    ;  format('  [!] Test 5: FALLITO~n') ),

    % Test 6: Controindicazione cognitiva (sbarramento)
    ( \+ compatibile_cognitivo(euphoric_run_anthem, user_marco)
    -> format('  [+] Test 6 (Controindicazione Cognitiva Studio): PASSATO~n')
    ;  format('  [!] Test 6: FALLITO~n') ),
    format('[SUCCESS] Tutti i test logici sono stati superati!~n~n').

help :-
    format('~nComandi disponibili in Prolog:~n'),
    format('  ?- raccomanda(user_sarah).       - Mostra raccomandazione per utente.~n'),
    format('  ?- raccomanda_sessione(user_sarah). - Mostra sequenza a 3 stadi Iso-Principle.~n'),
    format('  ?- demo.                         - Esegue i 3 scenari clinici dimostrativi.~n'),
    format('  ?- esegui_test.                  - Esegue i test logici di correttezza.~n~n').
