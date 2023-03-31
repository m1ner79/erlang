# Project Erlang: Distributed Routing Tables and Prime Number Calculation

This project demonstrates distributed routing tables in an Erlang network and performs prime number calculations using the network nodes. The following steps detail how to compile the project, launch nodes, connect them, update their routing tables, and perform prime number calculations.

## 1. Compile the Erlang module

Before running any command, compile the Erlang module containing the project's code:

```erlang
c(projectErlang).
```
## 2. Launch nodes

Launch three nodes with different nicknames:

```erlang
{Node1, Nickname1} = projectErlang:launchNode("node1").
{Node2, Nickname2} = projectErlang:launchNode("node2").
{Node3, Nickname3} = projectErlang:launchNode("node3").
```
## 3. Connect nodes

Establish connections between the nodes:

```erlang
projectErlang:connectNode(Nickname1, Node1, Nickname2, Node2).
projectErlang:connectNode(Nickname2, Node2, Nickname3, Node3).
```
## 4. Update routing tables

Update the routing tables for all nodes:

```erlang
projectErlang:updateRT(Node1).
projectErlang:updateRT(Node2).
projectErlang:updateRT(Node3).
```
## 5. Print routing tables

Print the immediate neighbor list and routing tables for each node:

```erlang
projectErlang:printTable(Node1).
projectErlang:printTable(Node2).
projectErlang:printTable(Node3).
```
## 6. Get immediate neighbor lists (INL)

Retrieve the immediate neighbor lists (INL) for all nodes:

```erlang
Node1INL = projectErlang:getINL(Node1).
Node2INL = projectErlang:getINL(Node2).
Node3INL = projectErlang:getINL(Node3).
```
## 7. Compute the nth prime number

Perform prime number calculations using the distributed network nodes. In this example, we calculate the 3rd prime number:

```erlang
projectErlang:computeNthPrime(3, Nickname2, Nickname1, 0, Node1INL).
```
This command calculates the 3rd prime number using node2 (Nickname2) and sends the result back to node1 (Nickname1).

Feel free to modify the commands to explore different node configurations and prime number calculations.

### Project License
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.