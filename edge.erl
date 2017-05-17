-module(edge).
-export([min_val/1, del/2, get/2, find/2]).

% Helper functions to handle the edges in Min weight spanning tree

% find smallest value
min_val([E|Edges]) -> min_val(Edges,E).

min_val([{E,V}|Edges],{EM,Min}) when V < Min -> min_val(Edges,{E,V});
min_val([E|Edges],Min) -> min(Edges,Min);
min_val([],Min) -> Min.

% delete edge J
del(Edges, J) -> del(Edges,J,[]).

del([{N,V}|Edges],J,Ack) when N == J -> del(Edges,J,Ack);
del([H|Edges],J,Ack) -> del(Edges,J,Ack++[H]);
del([],J,Ack) -> Ack.

% get value of node J
get([{N,V}|Edges],J) when N == J -> V;
get([H|Edges],J) -> get(Edges,J);
get([],J) -> io:fwrite("Not in list\n").

% Get node with value N
find([{N,V}|Edges],Key) when V == Key -> N;
find([H|Edges],Key) -> find(Edges,Key);
find([],_) -> 
    io:fwrite("Not in list\n"),
    none.  