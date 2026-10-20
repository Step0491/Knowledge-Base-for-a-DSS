% =========================================================================
% Central Knowledge Base Loader Module
% Part of: Context-Aware Music Recommendation & Health-Routine Optimization DSS
% =========================================================================

:- module(load_kb, [
    track/13,
    track_acoustic/4,
    track_features/4,
    track_has_attribute/2,
    user_biometrics/12,
    user_baseline/3,
    activity_target_profile/5,
    health_routine/16
]).

:- consult('kb_tracks.pl').
:- consult('kb_biometrics.pl').
:- consult('kb_routines.pl').
