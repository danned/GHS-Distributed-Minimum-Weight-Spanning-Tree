-module(bmst).
-export([init/1, setNbs/2, start/1, s0/0,buildST/10]).
-import(lists, [delete/2, all/2, member/2, foreach/2]).
-import(edge,[min/1, get/2]).

init(Node)    -> spawn_link(Node,bmst,s0,[]).
setNbs(P,Nbs) -> P ! {setNbs, Nbs}.
start(P)      -> P ! wakeup.
	      	
% the states and transitions.

% get the neighbours and go to wait for starting or continue building the spanning tree
s0() -> receive
		{setNbs, WE} -> buildST(WE, sleeping, [ {E,basic} || {E,_} <- WE], 0,0,0, none, none, nil, none)
	end.

% either start or continue building the spanning tree
buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt) ->

    %io:fwrite("Node ~w listening for priority msgs \n", [self()]),
	receive
        % prioritise, used to execute internal procedures

        wakeup -> 
            io:fwrite("Node ~w is awake \n", [self()]),
            io:fwrite("SE = ~w\n",[WE]),
            {M,_} = edge:min_val(WE),
            M ! {connect, 0, self()},
            io:fwrite("Node ~w sent connect to node ~w \n", [self(), M]),
            buildST(WE, found, edge:del(SE,M) ++ [{M,branch}], 0, 0, 0, BestEdge, InBranch, TestEdge, BestWt);

        test ->
            %io:fwrite("Internal procedure Test on node ~w\n", [self()]),
            case edge:find(SE, basic) of
                 none -> 
                    io:fwrite("Following test basic not found \n", []),
                    self() ! report,
                    buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, nil, BestWt);
                 %{report(SN, FindCount,TestEdge,BestWt,InBranch), nil}
                _ -> 
                    BasicWeights = [ {Node,edge:get(WE,Node)} || {Node,State}<-SE, State == basic],
                    {Test,_} = edge:min_val(BasicWeights),
                    %BasicWeights = [edge:get(W,)
                    %Test = edge:find(basic, SE),
                    io:fwrite("Following basic found\n", []),
                    io:fwrite("~w sending test, ~w, ~w, to ~w \n", [self(),LN, FN, Test]),
                    %{test, L, F, J}
                    Test ! {test, LN, FN, self()},
                    buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, Test, BestWt)%,
                    %{SN,TestEdge};
                    
            end;

        report when FindCount == 0, TestEdge == nil -> 
            io:fwrite("internal procedure report first case\n", []),
            io:fwrite("Sending ~w ! {report, ~w, ~w}\n", [InBranch, BestWt, self()]),
            %io:fwrite("node ~w before: ~w\n" , [InBranch, erlang:process_info(InBranch, messages)]),
            InBranch ! {report, BestWt, self()},
            %io:fwrite("node ~w after: ~w\n" , [InBranch, erlang:process_info(InBranch, messages)]),
            buildST(WE, found, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

        report ->
            io:fwrite("internal procedure Report else\n", []),
            buildST(WE, found, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

        change_root ->
            io:fwrite("Process ~w executing internal procedure Change root\n", [self()]),
            case edge:get(SE,BestEdge) of
                branch ->
                    io:fwrite("Process ~w sending Change root to ~w\n", [self(), BestEdge]),
                    T = SE,
                    BestEdge ! {change_root, self()};
                _ -> 
                    io:fwrite("Process ~w sending connect, ~w to ~w\n", [self(), LN, BestEdge]),
                    T = edge:del(SE,BestEdge) ++ [{BestEdge,branch}],
                    BestEdge ! {connect, LN, self()}
            end,
            buildST(WE, SN, T, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt)

        
                
           % report(SN, FindCount, TestEdge, BestWt, InBranch) ->
            %if  FindCount == 0, TestEdge == nil ->
            %    
            %true -> SN
            %end.

        after 0 -> %if none prioritised msgs in queue, do rest
        %io:fwrite("Node ~w listening for normal msgs \n", [self()]),
        %io:fwrite("Node ~w mesg queue: ~w\n" , [self(), erlang:process_info(self(), messages)]),
        receive
            {connect, L, J} when SN == sleeping ->
                io:fwrite("Node ~w received Connect(~w) on edge ~w while sleeping\n", [self(), L, J]),
                self() ! wakeup,
                self() ! {connect, L, J},
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            {connect, L, J} when L < LN ->
                io:fwrite("Node ~w received Connect(~w) on edge ~w\n", [self(), L, J]),
                T = edge:del(SE,J) ++ [J, branch],
                J ! {initiate, LN,FN,SN, self()},
                io:fwrite("Node ~w sending initiate on edge ~w L < LN case\n", [self(), J]),
                if
                    SN == find ->
                        buildST(WE, SN, T, LN, FN, FindCount + 1, BestEdge, InBranch, TestEdge, BestWt);
                    true ->
                        buildST(WE, SN, T, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt)
                end;

            {connect, L, J} ->
                %io:fwrite("Node ~w received Connect(~w) on edge ~w, LN = ~w \n", [self(), L, J,LN]),
                %io:fwrite("SE = ~w \n", [SE]),
                case edge:get(SE,J) of
                    basic ->
                        %TODO: Is this really correct?
                        %io:fwrite("Node ~w received Connect(~w) on edge ~w \n", [self(), L, J]),
                        %io:fwrite("Node ~w was assessed to be in basic state\n", [J]),
                        %io:fwrite("node ~w place received message on end of queue\n", [self()]),
                        self() ! {connect, L, J};
                    _ ->
                        io:fwrite("Node ~w sending initiate on edge ~w else case\n", [self(), J]),
                        J ! {initiate, LN + 1, edge:get(WE,J), find, self()}
                        %buildST(W, SN, SE, LN, FN, FindCount, BestEdge, InBranch)
                end,
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            {initiate,L,F,S,J} -> 
            io:fwrite("Process ~w received {initiate,~w,~w,~w,~w} on edge ~w \n", [self(), L,F,S,J,J]),
            [E ! {initiate, L,F,S,self()} ||{E,State} <- SE, E =/= J,State == branch],
            if 
                S == find ->
                    C = [ 1 ||{E,State} <- SE, E =/= J,State == branch],
                    Count = length(C),
                    io:fwrite("Process ~w Edges = ~w, branch count = ~w\n",[self(), SE, Count]),
                    self() ! test;

                true -> 
                    Count = 0
            end,
            buildST(WE, S, SE, L, F, FindCount + Count, nil, J, TestEdge, infinity);

            

            {test, L, F, J} when SN == sleeping ->
                io:format( "Process ~w received Test by node ~w when sleeping\n",[self(),J]),
                self() ! wakeup,
                self() ! {test, L, F, J},
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} when L > LN ->
                %io:format(user, "Process ~w L = ~w LN = ~w\n",[self(),L, LN]),
                io:format( "Process ~w received Test by node ~w when L > LN\n",[self(),J]),
                self() ! {test, L, F, J},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} when F =/= FN ->%L < LN, F =/= FN ->
                io:format( "Process ~w received Test by node ~w when F=/=FN\n",[self(),J]),
                io:format( "Process ~w sending accept to process ~w\n",[self(),J]),
                J ! {accept, self()},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} ->% when L < LN ->
                io:format( "Process ~w received Test by node ~w in else\n",[self(),J]),
                io:format( "L = ~w, F = ~w, J = ~w, FN = ~w\n",[L, F, J, FN]),
                case edge:get(SE,J) of
                    basic ->
                        SE_NEW = edge:del(SE,J) ++ [{J,rejected}],
                        if 
                            TestEdge =/= J -> 
                                io:format( "Process ~w sending reject to node ~w\n",[self(),J]),
                                J ! {reject, self()};

                            true -> self() ! test%{SNew, Test} = test(SN, SE_NEW, LN, FN, FindCount, TestEdge, BestWt, InBranch) 
                        end;
                    _ -> SE_NEW = SE
                end,
                buildST(WE, SN, SE_NEW, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);


            {accept, J} ->
                io:format( "Process ~w received accept by node ~w\n",[self(),J]),
                WJ = edge:get(WE,J), 
                self() ! report, % deferred to next receive
                if
                   WJ < BestWt ->
                        buildST(WE, SN, SE, LN, FN, FindCount,J, InBranch, nil, WJ);
                    true ->
                        buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, nil, BestWt)
                end;

            {reject, J} ->
                io:format( "Process ~w received reject by node ~w\n",[self(),J]),
                SJ = edge:get(SE,J),
                if
                    SJ == basic ->
                    SE_NEW = edge:del(SE,J) ++ [{J, rejected}],
                    self() ! test;
                    true -> 
                        SE_NEW = SE
                end,
                buildST(WE, SN, SE_NEW, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);


            {report, W, J} when J =/= InBranch, W < BestWt-> 
                io:fwrite("Process ~w received report by node ~w when J =/= InBranch, W < BestWt\n",[self(),J]),
                self() ! report,
                buildST(WE, SN, SE, LN, FN, FindCount -1, J,        InBranch, TestEdge, W);

            {report, W, J} when J =/= InBranch ->
                io:fwrite("Process ~w received report by node ~w when J =/= InBranch\n",[self(),J]),
                self() ! report,
                buildST(WE, SN, SE, LN, FN, FindCount -1, BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when SN == find ->
                io:fwrite("Process ~w received report by node ~w when SN == find\n",[self(),J]),
                self() ! {report, W, J},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when W > BestWt ->
                io:fwrite("Process ~w received report by node ~w when W > BestWt\nW = ~w > BestWt = ~w\n",[self(),J,W,BestWt]),
                %io:fwrite("",[W,BestWt]),
                self() ! change_root,
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when W == BestWt, BestWt == infinity ->
                io:fwrite("Process ~w received report by node ~w when W == BestWt, BestWt == 2\n",[self(),J]),
                io:fwrite("Halt\n"),
                self() ! print_branches,
                [E ! print_branches || {E,S}<-SE],
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);
             
            %{report, W, J} ->
            %    io:fwrite("Process ~w received report from ~w in else\n",[self(),J]),
            %    io:fwrite("Message, {report, ~w, ~w} is discarded\n", [W,J]),
            %    buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);
            
            {change_root, J} -> 
                io:fwrite("Process ~w receive change_root from ~w\n", [self(),J]),
                self() ! change_root,
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            print_queue ->
                io:fwrite("Node ~w msg queue: ~w\n" , [self(), erlang:process_info(self(), messages)]),
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            print_branches ->
                io:fwrite("Branches of node ~w are : ~w\n",[self(),SE]),
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt)
                %[E ! print_branches||{E,S}<-Branches]
        end
     end.
    %buildST(W, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt).