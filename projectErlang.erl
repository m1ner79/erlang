%%% ----------------------------------------
%%% @author Michal Gornicki
%%% @copywright (C) 2023, Michal Gornicki
%%% @doc
%%% misc
%%% @end
%%% Created: 13/03/2023 by Michal Gornicki
%%% ----------------------------------------

-module(projectErlang).

-export([launchNode/1, connectNode/4, printTable/1, computeNthPrime/5, receiveAnswer/6, updateRT/1, getINL/1]).

% Launches a node with a given nickname
launchNode(Nickname) ->
    Pid = spawn(fun() -> loop(Nickname, [], []) end),
    {Pid, Nickname}.

% Connects two nodes with their respective nicknames and PIDs
connectNode(NicknameOne, PidOne, NicknameTwo, PidTwo) ->
    PidOne ! {connect, PidTwo, NicknameTwo},
    PidTwo ! {connect, PidOne, NicknameOne},
    true.

% Prints the routing table of a node with the given PID
printTable(Pid) ->
    Pid ! {printTable, self()},
    receive
        {printTable, INL, RT} ->  % Receive both INL and RT
            io:format("Immediate Neighbour List: ~p~n", [INL]),
            io:format("Routing Table:~n"),
            lists:foreach(fun({Nickname, _, Hops}) ->  % RT now contains tuples with Nickname and Hops
            io:format("~s -> ~s, Hops: ~p~n", [atom_to_list(Pid), Nickname, Hops]);
                (_) ->  % clause to handle the case when the element isn't a tuple
                    ok
            end, RT)
    end.

% Starts the process to compute the nth prime number
computeNthPrime(N, DestinationNickname, SenderNickname, Hops, INL) ->
    case lookup(DestinationNickname, INL) of
        Pid when is_pid(Pid) ->
            Pid ! {computeNthPrime, N, DestinationNickname, SenderNickname, Hops},
            receive
                {result, Prime} ->
                    io:format("The ~pth prime is ~p~n", [N, Prime]);
                _ ->
                    ok
            end,
            Pid;
        undefined ->
            io:format("Destination ~p not found in INL~n", [DestinationNickname])
    end.

% Sends the answer of the computed prime number to the destination
receiveAnswer(N, M, DestinationNickname, SenderNickname, Hops, INL) ->
    case lookup(DestinationNickname, INL) of
        Pid when is_pid(Pid) ->
            Pid ! {receiveAnswer, N, M, DestinationNickname, SenderNickname, Hops};
        undefined ->
            io:format("Destination ~p not found in INL~n", [DestinationNickname])
    end.

% Updates the routing table for the given PID
updateRT(Pid) ->
    Pid ! {updateRT}.

% Gets the Immediate Neighbour List (INL) for a given PID
getINL(Pid) ->
    Pid ! {getINL, self()},
    io:format("Sent getINL message~n"),
    receive
        {ok, INL} ->
            io:format("Received INL: ~p~n", [INL]),
            INL
    after 10000 ->
        io:format("Timeout in getINL~n"),
        timeout
    end.

% The main loop for handling messages in a node
loop(Nickname, INL, RT) ->
    io:format("~p: Entering loop/3~n", [Nickname]),
    receive
        {requestRT, _RequesterNickname, RequesterPid} ->
            RequesterPid ! {ok, RT},
            loop(Nickname, INL, RT);
        {connect, Pid, OtherNickname} ->
            NewINL = add_neighbour(OtherNickname, Pid, INL),
            loop(Nickname, NewINL, RT);
        {printINL, SenderPid} ->
            SenderPid ! {ok, INL},
            loop(Nickname, INL, RT);
        {printTable, From} ->
            From ! {printTable, INL, RT}, 
            loop(Nickname, INL, RT);
        {computeNthPrime, N, DestinationNickname, SenderNickname, Hops} ->
            if Hops =< 15 ->
                if DestinationNickname =:= Nickname ->
                    M = compute_prime(N),
                    receiveAnswer(N, M, SenderNickname, Nickname, Hops + 1, INL);
                true ->
                    route(computeNthPrime, N, undefined, DestinationNickname, SenderNickname, Hops + 1, INL, RT)
                end;
            true ->
                loop(Nickname, INL, RT)
            end;
            {receiveAnswer, N, M, DestinationNickname, SenderNickname, Hops} ->
                if Hops =< 15 ->
                    if DestinationNickname =:= Nickname ->
                        io:format("The ~pth prime is ~p~n", [N, M]),
                        SenderPid = lookup(SenderNickname, INL),
                        SenderPid ! {result, M}
                    ;
                        true ->
                            route(receiveAnswer, N, M, DestinationNickname, SenderNickname, Hops + 1, INL, RT)
                    end;
                true ->
                    loop(Nickname, INL, RT)
                end;
        {updateRT} ->
            NewRT = rip(Nickname, INL, RT),
            receive
                done -> ok
            end,
            loop(Nickname, INL, NewRT);
        {getINL, SenderPid} ->
            io:format("~p: Received getINL message~n", [Nickname]),
                SenderPid ! {ok, INL},
                loop(Nickname, INL, RT)
    end.
    
    rip(Nickname, INL, RT) ->
    io:format("~p: Starting rip with INL: ~p, RT: ~p~n", [Nickname, INL, RT]),
    NewRT = lists:foldl(fun({NeighbourNickname, NeighbourPid}, Acc) ->
        NeighbourPid ! {requestRT, Nickname, self()},
        receive
            {ok, NeighbourRT} ->
                mergeRT(Acc, NeighbourRT, NeighbourNickname)
        end
    end, RT, INL),
    io:format("~p: Finished rip with INL: ~p, RT: ~p~n", [Nickname, INL, NewRT]),
    self() ! done,
    NewRT.

        mergeRT(RT1, RT2, NeighbourNickname) ->
    lists:foldl(fun({Dest, Hops}, Acc) ->
                    case lists:keytake(Dest, 1, Acc) of
                        {value, {_, _, OldHops}, AccWithoutDest} ->
                            if Hops + 1 < OldHops ->
                                AccWithoutDest ++ [{Dest, NeighbourNickname, Hops + 1}];
                            true ->
                                Acc
                            end;
                        false ->
                            case lists:keyfind(Dest, 1, RT1) of
                                false ->
                                    Acc ++ [{Dest, NeighbourNickname, Hops + 1}];
                                _ ->
                                    Acc
                            end
                    end;
                    (_, Acc) -> % Add this clause to handle the empty lists case
                        Acc
                end, RT1, RT2).
    
    add_neighbour(Nickname, Pid, INL) ->
        [{Nickname, Pid} | INL].
    
    lookup(Nickname, INL) ->
        case lists:keyfind(Nickname, 1, INL) of
            {Nickname, Pid} ->
                Pid;
            false ->
                io:format("Lookup failed for ~p in ~p~n", [Nickname, INL]),
                undefined
        end.
    
    compute_prime(N) ->
        compute_prime(N, 2, 1, 3).
    
    compute_prime(N, _, PrimeCount, CurrentNumber) when PrimeCount > N ->
        CurrentNumber - 1;
    compute_prime(N, Divisor, PrimeCount, CurrentNumber) ->
        case (Divisor * Divisor) > CurrentNumber of
            true ->
                compute_prime(N, 2, PrimeCount + 1, CurrentNumber + 1);
            false ->
                case CurrentNumber rem Divisor of
                    0 ->
                        compute_prime(N, 2, PrimeCount, CurrentNumber + 1);
                    _ ->
                        compute_prime(N, Divisor + 1, PrimeCount, CurrentNumber)
                end
        end.
    
        route(MessageType, N, M, DestinationNickname, SenderNickname, Hops, INL, RT) ->
    NextHopNickname = lookup_next_hop(DestinationNickname, RT),
    case NextHopNickname of
        undefined ->
            io:format("Destination ~p is unreachable~n", [DestinationNickname]);
        _ ->
            NextHopPid = lookup(NextHopNickname, INL),
            case MessageType of
                computeNthPrime ->
                    NextHopPid ! {computeNthPrime, N, DestinationNickname, SenderNickname, Hops};
                receiveAnswer ->
                    io:format("The ~pth prime is ~p~n", [N, M]),
                    NextHopPid ! {receiveAnswer, N, M, DestinationNickname, SenderNickname, Hops}
            end
    end.
    
    lookup_next_hop(DestinationNickname, RT) ->
        case lists:keyfind(DestinationNickname, 1, RT) of
            {_, NextHopNickname, _} -> NextHopNickname;
            false -> undefined
        end.