-module(opty_remote).
-export([start/6, stop/2]).

%% Clients: Number of concurrent clients in the system
%% Entries: Number of entries in the store
%% Reads: Number of read operations per transaction
%% Writes: Number of write operations per transaction
%% Time: Duration of the experiment (in secs)
%% Node: Remote instance node

start(Clients, Entries, Reads, Writes, Time, Node) ->
	spawn(Node, fun() -> 
		register(s, server:start(Entries)) 
	end),
	timer:sleep(1000),
    L = startClients(Clients, [], Entries, Reads, Writes, Node),
    io:format("Starting: ~w CLIENTS, ~w ENTRIES, ~w RDxTR, ~w WRxTR, DURATION ~w s~n", 
         [Clients, Entries, Reads, Writes, Time]),
    timer:sleep(Time*1000),
    stop(L, Node).

stop(L, Node) ->
    io:format("Stopping...~n"),
    stopClients(L),
    waitClients(L),
    {s, Node} ! stop,
    io:format("Stopped~n").

startClients(0, L, _, _, _, _) -> L;
startClients(Clients, L, Entries, Reads, Writes, Node) ->
    Pid = client:start(Clients, Entries, Reads, Writes, {s, Node}),
    startClients(Clients-1, [Pid|L], Entries, Reads, Writes, Node).

stopClients([]) ->
    ok;
stopClients([Pid|L]) ->
    Pid ! {stop, self()},	
    stopClients(L).

waitClients([]) ->
    ok;
waitClients(L) ->
    receive
        {done, Pid} ->
            waitClients(lists:delete(Pid, L))
    end.
