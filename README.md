# Knowledge Base for a DSS: Context-Aware Music Recommendation & Health-Routine Optimization

[![Prolog](https://img.shields.io/badge/Prolog-SWI--Prolog-blue.svg)](https://www.swi-prolog.org/)
[![Python](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)
[![Tests](https://img.shields.io/badge/Tests-10%2F10_Passing-brightgreen.svg)]()
[![Notebook](https://img.shields.io/badge/Notebook-Jupyter_Walkthrough-orange.svg)](demo_walkthrough.ipynb)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Abstract:** I sistemi convenzionali di raccomandazione musicale soffrono del limite della *"raccomandazione cieca al contesto"*: suggeriscono canzoni in base allo storico di ascolto o alla popolarità globale, senza considerare lo stato psicofisico effettivo dell'ascoltatore.
>
> Questo **Decision Support System (DSS)** supera tale limite integrando le caratteristiche acustiche matematiche del catalogo **Spotify** (BPM, valenza emotiva, livello energetico, strumentalità) con la telemetria biometrica real-time di uno **Smartwatch** (frequenza cardiaca, indice di stress, attività in corso). 
> 
> Utilizzando la **programmazione logica in Prolog** e criteri di matching fisiologico, il DSS agisce come un assistente cognitivo in tempo reale: valuta l'ammissibilità dei brani ed eroga la traccia ottimale per ridurre lo stress acuto, favorire la concentrazione o sostenere l'allenamento cardio, spiegando sempre all'utente il razionale clinico della decisione.

---

## 1. Architettura & Struttura del Progetto

Il progetto è strutturato in modo compatto, lineare e facilmente navigabile:

```
Knowledge-Base-for-a-DSS/
├── data/
│   ├── spotify_tracks.json        # Catalogo musicale con parametri acustici Spotify
│   └── smartwatch_biometrics.json # Log di telemetria e profili utente smartwatch
├── generate_kb.py                 # Script ETL: compila i dati JSON in fatti Prolog
├── knowledge_base.pl              # Fatti Prolog: brano/8 e utente/7
├── dss_rules.pl                   # Regole di inferenza logica, vincoli e scoring
├── main.pl                        # Entry point Prolog con query intuitive (es: ?- raccomanda(user_sarah).)
├── test_suite.py                  # Test automatici di verifica formale (10/10 test)
├── demo_walkthrough.ipynb         # NOTEBOOK JUPYTER completo e illustrativo (per l'orale)
├── LICENSE                        # Licenza MIT
└── README.md                      # Questa relazione di progetto
```

---

## 2. Modello dei Dati (Knowledge Base)

### 2.1 Catalogo Spotify (`data/spotify_tracks.json` $\rightarrow$ `brano/8`)
Ogni brano è rappresentato dal predicato Prolog:
```prolog
brano(Id, Titolo, Artista, Genere, BPM, Valenza, Energia, Strumentale).
```
* **BPM (Beats Per Minute):** Velocità del tempo musicale (es. 60.0 ambient, 140.0 techno).
* **Valenza (0.0 - 1.0):** Positività e allegria percepita del brano.
* **Energia (0.0 - 1.0):** Intensità, attività ed eccitazione sonora.
* **Strumentale (0.0 - 1.0):** Confidenza dell'assenza di parti vocali/cantate ($> 0.70$ = brano solo strumentale).

### 2.2 Telemetria Smartwatch (`data/smartwatch_biometrics.json` $\rightarrow$ `utente/7`)
Ogni profilo utente rileva lo stato psicofisico corrente:
```prolog
utente(Id, Nome, Attivita, BattitoCardiaco, LivelloStress, Obiettivo, GeneriPreferiti).
```
* **Attività:** `high_stress_work`, `cardio_running`, `deep_focus_study`, `sleep_preparation`, `active_commute`.
* **Battito Cardiaco (BPM):** Frequenza rilevata dal sensore ottico PPG.
* **Livello di Stress (0 - 100):** Indice derivato dalla variabilità della frequenza cardiaca (HRV) e risposta galvanica della pelle (GSR).

---

## 3. Motore di Inferenza: Albero Gerarchico delle Regole (`dss_rules.pl`)

Il motore logico adotta un'architettura ad **albero di inferenza AND-OR (Backward Chaining)** articolata su livelli di astrazione successivi, tipica dei sistemi esperti accademici:

```
[Livello 0: Meta-Regola]
       brano_raccomandabile(Brano, Utente)
            |
            +---> compatibile_fisiologico/2  ---> [Livello 2: stato_simpatico_acuto, regime_aerobico_cardio, ...]
            |                                      |--> [Livello 3: tempo_lento, energia_bassa, tempo_rapido]
            |
            +---> compatibile_cognitivo/2    ---> [Livello 2: protezione_loop_fonologico (Strumentale >= 0.70)]
            |
            +---> sicurezza_e_controindicazioni/2 -> [Livello 2: sbarramento tachicardia ed esaurimento da fatica]
            |
            +---> coerenza_circadiana/2      ---> [Livello 2: sbarramento orario per induzione al sonno]
```

### A. I Quattro Pilastri Ortogonali (Livello 1)
1. **Compatibilità Fisiologica (`compatibile_fisiologico/2`):**  
   Valuta lo stato autonomico (simpatico vs parasimpatico). Se l'utente è in stress o battito accelerato, richiede un brano ad azione sedativa (`BPM <= 75`, `Energia <= 0.35`). Se è in corsa cardio, richiede azione ergogenica (`BPM >= 120`, `Energia >= 0.70`).
2. **Compatibilità Cognitiva (`compatibile_cognitivo/2`):**  
   In attività di studio o lavoro intellettuale profondo (`deep_focus_study`), preserva il loop fonologico della memoria di lavoro imponendo il vincolo categorico di brani puramente strumentali (`Strumentale >= 0.70`).
3. **Sicurezza Medica & Sbarramenti Negativi (`sicurezza_e_controindicazioni/2`):**  
   Previene il sovraccarico: vieta categoricamente brani ad alto tempo o energia ($>100$ BPM o $>0.60$ energia) per utenti già in tachicardia e stress acuto ($>110$ BPM e $>75$ stress).
4. **Coerenza Circadiana (`coerenza_circadiana/2`):**  
   Allinea la selezione alla fase biologica: vieta brani eccitanti durante la preparazione al sonno.

### B. Altshuler's Iso-Principle (Musicoterapia Applicata)
Per soggetti con forte agitazione (es. 114 BPM), proporre immediatamente musica a 60 BPM induce rifiuto. Il predicato `sessione_iso_principle/2` costruisce una sequenza guidata a 3 scalini:
$$\text{Aggancio (105 BPM)} \longrightarrow \text{Ponte (85 BPM)} \longrightarrow \text{Obiettivo Riposo (60 BPM)}$$

---

## 4. Guida all'Uso & Esecuzione

### Opzione 1: Notebook Jupyter (Consigliato per l'Esame Orale)
Apri il file [`demo_walkthrough.ipynb`](demo_walkthrough.ipynb) con VS Code o Jupyter:
```bash
jupyter notebook demo_walkthrough.ipynb
```
Il notebook illustra passo dopo passo il caricamento dei dati, la compilazione dei fatti Prolog, la raccomandazione dei tre casi clinici e l'esecuzione dei test.

### Opzione 2: Verifica Immediata da Terminale (Python)
Esegui la suite di test completa:
```bash
python test_suite.py
```
Per rigenerare i fatti Prolog dai JSON:
```bash
python generate_kb.py
```

### Opzione 3: Esecuzione Interattiva con SWI-Prolog
Avvia il terminale Prolog caricando il file principale:
```bash
swipl -s main.pl
```
Query eseguibili nel prompt `?-`:
```prolog
% Mostra la raccomandazione e il razionale per Sarah (stress acuto da lavoro)
?- raccomanda(user_sarah).

% Mostra la sequenza a 3 gradini Iso-Principle per la discesa del battito
?- raccomanda_sessione(user_sarah).

% Esegue la demo per tutti e 3 i casi clinici (Stress, Corsa, Studio)
?- demo.

% Esegue i test logici integrati in Prolog
?- esegui_test.
```

---

## 5. Risultati dei Test di Correttezza Logica

L'esecuzione del file `test_suite.py` valida 10 criteri formali con il seguente esito:
```
======================================================================
 VERIFICA DI CORRETTEZZA LOGICA DEL SISTEMA (TEST SUITE)
======================================================================
 [+] 1. Riduzione stress (Sarah Miller) -> Brano lento e rilassante: PASSATO
 [+] 2. Cardio Workout (Alex Chen) -> Cadenza veloce ed alta energia: PASSATO
 [+] 3. Deep Focus (Marco Rossi) -> Zero parole cantate (strumentale): PASSATO
 [+] 4. Sonno (David Becker) -> Tempo lentissimo e minima energia: PASSATO
 [+] 5. Recupero post workout (Elena Rostova) -> Tempo controllato: PASSATO
 [+] 6. Commute attivo (Clara Dupont) -> Tono allegro (valenza positiva): PASSATO
 [+] 7. Entrainment Iso-Principle -> Traiettoria monotonica decrescente: PASSATO
 [+] 8. Test Negativo -> Brano con parole escluso in fase di studio: PASSATO
 [+] 9. Test Negativo -> Brano lento escluso durante la corsa cardio: PASSATO
 [+] 10. Scoring -> Bonus per genere musicale preferito dall'utente: PASSATO
----------------------------------------------------------------------
 Esito Test: 10/10 Superati con successo.
======================================================================
```

---

## 6. Licenza
Distribuito sotto licenza **MIT**. Consulta il file [LICENSE](LICENSE) per i dettagli.
