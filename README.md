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

## 3. Motore di Inferenza e Regole Logiche (`dss_rules.pl`)

Il DSS valuta due livelli di ammissibilità logica prima di calcolare l'utilità:

### A. Vincoli sull'Attività Corrente
1. **Studio / Lavoro Profondo (`deep_focus_study`):** Per non intasare il loop fonologico della memoria di lavoro, è imposto il vincolo:
   $$\text{Strumentale} \ge 0.70 \quad (\text{zero testo cantato distraente})$$
2. **Corsa Aerobica (`cardio_running`):** Per ottenere l'effetto ergogenico di sincronizzazione col passo:
   $$\text{BPM} \ge 120.0 \quad \land \quad \text{Energia} \ge 0.70$$

### B. Vincoli sull'Obiettivo di Salute
* **Riduzione Stress (`stress_downregulation`):** Richiede $\text{BPM} \le 75$, $\text{Energia} \le 0.35$ e traccia strumentale.
* **Sonno (`sleep_induction`):** Richiede $\text{BPM} \le 64$ ed $\text{Energia} \le 0.20$.
* **Cardio Peak (`cardio_peak_performance`):** Richiede $\text{BPM} \ge 120$ ed $\text{Energia} \ge 0.75$.

### C. Altshuler's Iso-Principle (Entrainment a 3 Stadi)
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
