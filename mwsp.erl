-module(mwsp).
-export([build/0]).
%-import(bstDebug, [init/1, setNbs/2, start/1]).

-import(bmst, [init/1, setNbs/2, start/1]).
%-import(bDFSst, [init/0, setNbs/2, start/1]).

build() ->
  % nodes
  N0 = 'n0@192.168.10.128',	 % this node
  N1 = 'n1@10.0.1.38',
  N2 = 'n2@10.0.1.38',
  %net_adm:ping(N1),
  %net_adm:ping(N2),	
  io:format("\nThe active nodes are ~w\n\n", [[node() | nodes()]]),
  io:format("The network building process is ~w on node ~w\n\n", [self(), node()]),
  A = init(N0),io:fwrite("Process ~w is graph node ~w\n",[A,'A']),
  B = init(N0),io:fwrite("Process ~w is graph node ~w\n",[B,'B']),
  C = init(N0),io:fwrite("Process ~w is graph node ~w\n",[C,'C']),
  D = init(N0),io:fwrite("Process ~w is graph node ~w\n",[D,'D']),
  E = init(N0),io:fwrite("Process ~w is graph node ~w\n",[E,'E']),
  %F = init(N0),io:fwrite("Process ~w is graph node ~w\n",[F,'F']),
  %D = init(N1),io:fwrite("Process ~w is graph node ~w\n",[D,'D']),
  %E = init(N1),io:fwrite("Process ~w is graph node ~w\n",[E,'E']),
  %F = init(N2),io:fwrite("Process ~w is graph node ~w\n",[F,'F']),
  %G = init(N2),io:fwrite("Process ~w is graph node ~w\n",[G,'G']),
  %H = init(N2),io:fwrite("Process ~w is graph node ~w\n",[H,'H']),
  io:format("\n\n"),
  % the graph in figure 2.23 in the book.
  setNbs(A,[{B,0.2},{C,0.9}]),
  setNbs(B,[{A,0.2},{C,0.3}]),
  setNbs(C,[{A,0.9},{B,0.3},{D, 0.1},{E,0.2}]),
  setNbs(D,[{C,0.1},{E,0.1}]),
  setNbs(E,[{D,0.1}, {C,0.2}]),
  %setNbs(B,[{A,0.3},{C,0.2}]),%,{D,0.1},{E,0.8}]),
 % setNbs(C,[{A,0.9},{B,0.2},{D,0.4},{E,0.9}]),%,{F,0.2}),
  %setNbs(A,[{B,0.3},{C,0.9}]),
  %setNbs(B,[{A,0.3},{C,0.2}]),%,{D,0.1},{E,0.8}]),
 % setNbs(C,[{A,0.9},{B,0.2},{D,0.4},{E,0.9}]),%,{F,0.2}),
  %setNbs(D,[{C,0.4},{E,0.1},{F,0.9}]),
  %setNbs(E,[{D,0.1},{C,0.9},{F,0.5}]),
  %setNbs(F,[{D,0.9},{E,0.5}]),
  %setNbs(D,[{B,0.1}),
  %setNbs(E,[{B,0.8},{F,0.2},{G,0.4},{H,0.7}]),
  %setNbs(F,[{C,0.2},{E,0.2},{G,0.7},{H,0.2}]),
  %setNbs(G,[{E,0.4},{F,0.7},{H,0.2}]),
  %setNbs(H,[{G,0.2},{E,0.4},{F,0.2}]),

  start(A),
  {A,B,C,D,E}.
  
 	
  
  
		
  
  