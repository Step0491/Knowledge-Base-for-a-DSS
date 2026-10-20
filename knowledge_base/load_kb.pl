% =========================================================================
% Knowledge Base Loader Module
% Loads all modular knowledge base fact files into the Prolog runtime.
% =========================================================================

:- module(load_kb, [
    reload_kb/0,
    kb_stats/0,
    destination/8,
    destination_logistics/4,
    heritage_site/11,
    heritage_site_logistics/3,
    intercity_transit/5
]).

:- dynamic destination/8.
:- dynamic destination_logistics/4.
:- dynamic heritage_site/11.
:- dynamic heritage_site_logistics/3.
:- dynamic intercity_transit/5.

:- consult('kb_destinations.pl').
:- consult('kb_heritage.pl').
:- consult('kb_transit.pl').

reload_kb :-
    consult('kb_destinations.pl'),
    consult('kb_heritage.pl'),
    consult('kb_transit.pl'),
    writeln('[*] Knowledge base successfully reloaded.').

kb_stats :-
    aggregate_all(count, destination(_,_,_,_,_,_,_,_), DestCount),
    aggregate_all(count, heritage_site(_,_,_,_,_,_,_,_,_,_,_), SiteCount),
    aggregate_all(count, intercity_transit(_,_,_,_,_), TransitCount),
    format('~n=== Knowledge Base Statistics ===~n'),
    format('Destinations loaded:       ~w~n', [DestCount]),
    format('UNESCO Sites loaded:       ~w~n', [SiteCount]),
    format('Transit Corridors loaded:  ~w~n', [TransitCount]),
    format('=================================~n~n').
