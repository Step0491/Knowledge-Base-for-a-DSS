% =========================================================================
% KNOWLEDGE BASE PROLOG: Decision Support System (DSS)
% Generato automaticamente da generate_kb.py a partire dai dati Spotify e Smartwatch
% =========================================================================

% --- Fatti: brano(Id, Titolo, Artista, Genere, BPM, Valenza, Energia, Strumentale) ---
:- dynamic brano/8.

brano(weightless_ambient, 'Weightless Ambient Drift', 'NeuroHarmonics', ambient, 60.0, 0.35, 0.12, 0.96).
brano(clair_de_lune, 'Clair de Lune (Debussy)', 'Sinfonia Chambers', classical, 64.0, 0.42, 0.18, 0.94).
brano(delta_sleep_stream, 'Delta Wave Binaural Serenade', 'SomnoLab', ambient, 55.0, 0.25, 0.08, 0.99).
brano(gymnopedie_no1, 'Gymnopédie No. 1 (Satie)', 'Aura Piano Quartet', classical, 66.0, 0.38, 0.15, 0.95).
brano(peaceful_mind_breeze, 'Peaceful Mind Breeze', 'Zenith Soundscapes', ambient, 68.0, 0.48, 0.22, 0.91).
brano(lofi_study_rain, 'Raindrops on University Library', 'Coffeehouse Chill', lofi, 76.0, 0.52, 0.34, 0.89).
brano(analog_warmth_lofi, 'Analog Cassette Memory', 'BeatFoundry', lofi, 80.0, 0.58, 0.38, 0.86).
brano(nordic_dawn_acoustic, 'Nordic Dawn Acoustic Solitude', 'Fjord String Ensemble', acoustic, 82.0, 0.62, 0.36, 0.78).
brano(solitary_cello_resonance, 'Resonant Cello in D Minor', 'Klara Varga', classical, 72.0, 0.32, 0.28, 0.98).
brano(midnight_tokyo_chill, 'Midnight Tokyo Neon Lights', 'Urban Lo-Fi Collective', lofi, 84.0, 0.60, 0.40, 0.84).
brano(golden_hour_jazz, 'Golden Hour Muted Trumpet', 'Blue Note Quintet', jazz, 88.0, 0.65, 0.42, 0.88).
brano(floating_synths_reverie, 'Floating Synth Reverie', 'Astral Projection', ambient, 90.0, 0.50, 0.45, 0.92).
brano(deep_work_flowstate, 'Neural Flowstate Synapses', 'Cortex Audio', electronic, 92.0, 0.54, 0.50, 0.95).
brano(sunlit_coastal_drive, 'Sunlit Coastal Drive', 'Pacific Wave', indie, 98.0, 0.72, 0.55, 0.35).
brano(morning_coffee_acoustic, 'Morning Brew Guitar Serenade', 'Oliver Vance', acoustic, 100.0, 0.75, 0.52, 0.25).
brano(steady_stride_groove, 'Steady Stride Metropolitan', 'Metro Beats', deep_house, 108.0, 0.68, 0.62, 0.70).
brano(city_lights_pulse, 'City Lights Pulse', 'Veloce', electronic, 115.0, 0.70, 0.68, 0.65).
brano(retro_synthwave_highway, 'Retro Highway 1984', 'Neon Horizons', synthwave, 120.0, 0.74, 0.76, 0.80).
brano(aerobic_pulse_house, 'Aerobic Equilibrium', 'Strobe Collective', deep_house, 124.0, 0.78, 0.80, 0.50).
brano(euphoric_run_anthem, 'Euphoric Peak Elevation', 'Apex Runner', pop, 128.0, 0.85, 0.88, 0.12).
brano(high_cadence_velocity, 'High Cadence Velocity', 'Pulse Dynamics', electronic, 135.0, 0.76, 0.89, 0.60).
brano(techno_stamina_engine, 'Subterranean Stamina Loop', 'Klangwerk', techno, 140.0, 0.62, 0.92, 0.90).
brano(adrenaline_rush_rock, 'Overdrive Ignition', 'Iron Vanguard', rock, 150.0, 0.80, 0.95, 0.15).
brano(sprint_finish_metal, 'Apex Power Surge', 'Titanium Core', metal, 165.0, 0.58, 0.98, 0.40).
brano(cool_down_sunset_chords, 'Cool Down Sunset Chords', 'Solaris Lounge', deep_house, 102.0, 0.66, 0.52, 0.75).
brano(breathe_exhale_acoustic, 'Breathe and Exhale', 'Mira Chen', acoustic, 74.0, 0.55, 0.28, 0.70).
brano(cinematic_horizon_glow, 'Cinematic Horizon Glow', 'Nordic Orchestra', cinematic, 86.0, 0.64, 0.46, 0.92).
brano(iso_bridge_moderato, 'Iso Bridge Dynamic Transition', 'BioAcoustic Labs', ambient, 105.0, 0.45, 0.55, 0.88).
brano(tempo_taper_andante, 'Tempo Taper Andante', 'BioAcoustic Labs', classical, 85.0, 0.48, 0.38, 0.90).
brano(sleep_prelude_lullaby, 'Twilight Sleep Prelude', 'SomnoLab', ambient, 58.0, 0.30, 0.10, 0.97).

% --- Fatti: utente(Id, Nome, Attivita, BattitoCardiaco, LivelloStress, Obiettivo, GeneriPreferiti) ---
:- dynamic utente/7.

utente(user_sarah, 'Sarah Miller', high_stress_work, 114.0, 84.0, stress_downregulation, ['ambient', 'classical', 'lofi']).
utente(user_alex, 'Alex Chen', cardio_running, 146.0, 45.0, cardio_peak_performance, ['electronic', 'synthwave', 'techno', 'pop']).
utente(user_marco, 'Marco Rossi', deep_focus_study, 74.0, 32.0, deep_focus_flow, ['lofi', 'classical', 'ambient', 'electronic']).
utente(user_elena, 'Elena Rostova', post_workout_recovery, 122.0, 48.0, post_workout_recovery, ['acoustic', 'ambient', 'deep_house']).
utente(user_david, 'David Becker', sleep_preparation, 68.0, 22.0, sleep_induction, ['ambient', 'classical']).
utente(user_clara, 'Clara Dupont', active_commute, 96.0, 38.0, active_commute_energizer, ['indie', 'acoustic', 'pop', 'deep_house']).
