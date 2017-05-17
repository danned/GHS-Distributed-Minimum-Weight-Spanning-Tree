-module(bmst).
-export([init/1, setNbs/2, start/1, s0/0,buildST/10]).
-import(lists, [delete/2, all/2, member/2, foreach/2]).
-import(edge,[min/1, get/2]).

init(Node)    -> spawn_link(Node,bmst,s0,[]).
setNbs(P,Nbs) -> P ! {setNbs, Nbs}.
start(P)      -> P ! wakeup.
	      	
% get the neighbours and go to wait for starting or continue building the spanning tree
s0() -> receive
		{setNbs, WE} -> buildST(WE, sleeping, [ {E,basic} || {E,_} <- WE], 0,0,0, none, none, nil, none)
	end.

% either start or continue building the spanning tree
buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt) ->

    % prioritise internal procedures
	receive

        % internal procedure wakeup
        wakeup -> 
            io:fwrite("Node ~w is awake \n", [self()]),
            {M,_} = edge:min_val(WE),
            M ! {connect, 0, self()},
            buildST(WE, found, edge:del(SE,M) ++ [{M,branch}], 0, 0, 0, BestEdge, InBranch, TestEdge, BestWt);

        % internal procedure test
        test ->
            case edge:find(SE, basic) of
                 none -> 
                    self() ! report,
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, nil, BestWt);
                
                _ -> 
                    BasicWeights = [ {Node,edge:get(WE,Node)} || {Node,State}<-SE, State == basic],
                    {Test,_} = edge:min_val(BasicWeights),
                    Test ! {test, LN, FN, self()},
                    buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, Test, BestWt)
                    
            end;

        % internal procedure report
        report when FindCount == 0, TestEdge == nil -> 
            InBranch ! {report, BestWt, self()},
            buildST(WE, found, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

        report ->
            buildST(WE, found, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

        % internal procedure change_root
        change_root ->
            case edge:get(SE,BestEdge) of
                branch ->
                    T = SE,
                    BestEdge ! {change_root, self()};
                _ -> 
                    T = edge:del(SE,BestEdge) ++ [{BestEdge,branch}],
                    BestEdge ! {connect, LN, self()}
            end,
            buildST(WE, SN, T, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt)
        
        %if no prioritised msgs in queue, receive other functions
        after 0 -> 
        receive
            % on connect message receive
            {connect, L, J} when SN == sleeping ->
                self() ! wakeup,
                self() ! {connect, L, J},
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            {connect, L, J} when L < LN ->
                T = edge:del(SE,J) ++ [J, branch],
                J ! {initiate, LN,FN,SN, self()},
                if
                    SN == find ->
                        buildST(WE, SN, T, LN, FN, FindCount + 1, BestEdge, InBranch, TestEdge, BestWt);
                    true ->
                        buildST(WE, SN, T, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt)
                end;

            {connect, L, J} ->
                case edge:get(SE,J) of
                    basic ->
                        self() ! {connect, L, J};
                    _ ->
                        J ! {initiate, LN + 1, edge:get(WE,J), find, self()}
                end,
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            % on initiate message receive
            {initiate,L,F,S,J} -> 
                [E ! {initiate, L,F,S,self()} ||{E,State} <- SE, E =/= J,State == branch],
                if 
                    S == find ->
                        C = [ 1 ||{E,State} <- SE, E =/= J,State == branch],
                        Count = length(C),
                        self() ! test;

                    true -> 
                        Count = 0
                end,
                buildST(WE, S, SE, L, F, FindCount + Count, nil, J, TestEdge, infinity);
            
            
            % on test message receive
            {test, L, F, J} when SN == sleeping ->
                self() ! wakeup,
                self() ! {test, L, F, J},
                buildST(WE, SN, SE, LN, FN, FindCount, BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} when L > LN ->
                self() ! {test, L, F, J},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} when F =/= FN ->
                J ! {accept, self()},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {test, L, F, J} ->
                case edge:get(SE,J) of
                    basic ->
                        SE_NEW = edge:del(SE,J) ++ [{J,rejected}],
                        if 
                            TestEdge =/= J -> 
                                J ! {reject, self()};

                            true -> self() ! test
                        end;
                    _ -> SE_NEW = SE
                end,
                buildST(WE, SN, SE_NEW, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            % on test message receive
            {accept, J} ->
                WJ = edge:get(WE,J), 
                self() ! report,
                if
                   WJ < BestWt ->
                        buildST(WE, SN, SE, LN, FN, FindCount,J, InBranch, nil, WJ);
                    true ->
                        buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, nil, BestWt)
                end;

            
            % on reject message receive
            {reject, J} ->
                SJ = edge:get(SE,J),
                if
                    SJ == basic ->
                    SE_NEW = edge:del(SE,J) ++ [{J, rejected}],
                    self() ! test;
                    true -> 
                        SE_NEW = SE
                end,
                buildST(WE, SN, SE_NEW, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);


            % on report message receive
            {report, W, J} when J =/= InBranch, W < BestWt-> 
                self() ! report,
                buildST(WE, SN, SE, LN, FN, FindCount -1, J,        InBranch, TestEdge, W);

            {report, W, J} when J =/= InBranch ->
                self() ! report,
                buildST(WE, SN, SE, LN, FN, FindCount -1, BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when SN == find ->
                self() ! {report, W, J},
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when W > BestWt ->
                self() ! change_root,
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            {report, W, J} when W == BestWt, BestWt == infinity ->
                self() ! print_branches,
                [E ! print_branches || {E,S}<-SE],
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);
            
            {change_root, J} -> 
                io:fwrite("Process ~w receive change_root from ~w\n", [self(),J]),
                self() ! change_root,
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            % print current message queue
            print_queue ->
                io:fwrite("Node ~w msg queue: ~w\n" , [self(), erlang:process_info(self(), messages)]),
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt);

            % print all branches of node
            print_branches ->
                io:fwrite("Branches of node ~w are : ~w\n",[self(),SE]),
                buildST(WE, SN, SE, LN, FN, FindCount,BestEdge, InBranch, TestEdge, BestWt)
        end
     end.