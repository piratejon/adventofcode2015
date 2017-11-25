-module(p22).
-include_lib("eunit/include/eunit.hrl").
-export([play_script/2]).
-record(state, {
  player_hp, player_armor, player_mana
  , boss_hp
  , boss_damage
  , effect_poison , effect_shield, effect_recharge
  , spent_mana
}).

-define(MISSILE_COST, 53).
-define(DRAIN_COST, 73).
-define(SHIELD_COST, 113).
-define(POISON_COST, 173).
-define(RECHARGE_COST, 229).

spell_cost(Spell) ->
  case Spell of
    missile -> ?MISSILE_COST;
    drain -> ?DRAIN_COST;
    shield -> ?SHIELD_COST;
    poison -> ?POISON_COST;
    recharge -> ?RECHARGE_COST
  end.

io_wrapper(Left, Right) -> nil.
  %io:format(Left, Right).

print_state(State) ->
  io_wrapper("- Player has ~w hit points, ~w armor, ~w mana~n- Boss has ~w hit points~n- Effects: Poison ~w, Shield ~w, Recharge ~w~n",
            [State#state.player_hp, State#state.player_armor, State#state.player_mana, State#state.boss_hp, State#state.effect_poison, State#state.effect_shield, State#state.effect_recharge]
           ).

print_turn_header(State, Who) ->
  io_wrapper("~n-- ~w turn --~n", [Who]),
  print_state(State).

player_turn(State, Spell) ->
  io_wrapper("Player casts ~w~n", [Spell]),
  State0 = if
      Spell == poison -> cast_poison(State);
      Spell == missile -> cast_missile(State);
      Spell == drain -> cast_drain(State);
      Spell == recharge -> cast_recharge(State);
      Spell == shield -> cast_shield(State)
  end,
  State0.

boss_turn(State) ->
  io_wrapper("Boss attacks for ~w damage.~n", [State#state.boss_damage]),
  State#state{player_hp=max(1, State#state.player_hp - (State#state.boss_damage - State#state.player_armor))}.

% effects appliers, mana was already spent, decrements counter
apply_poison(State) ->
  if
    State#state.effect_poison == undefined -> State;
    State#state.effect_poison == 1 -> State#state{boss_hp=State#state.boss_hp - 3, effect_poison=undefined};
    State#state.effect_poison > 1 -> State#state{boss_hp=State#state.boss_hp - 3, effect_poison=State#state.effect_poison - 1};
    true -> State
  end.

apply_shield(State) ->
  if
    State#state.effect_shield == undefined -> State;
    State#state.effect_shield == 6 -> State#state{player_armor=State#state.player_armor + 7, effect_shield=State#state.effect_shield - 1};
    State#state.effect_shield == 1 -> State#state{player_armor=State#state.player_armor - 7, effect_shield=undefined};
    State#state.effect_shield > 1 -> State#state{effect_shield=State#state.effect_shield - 1};
    true -> State
  end.

apply_recharge(State) ->
  if
    State#state.effect_recharge == undefined -> State;
    State#state.effect_recharge == 1 -> State#state{player_mana=State#state.player_mana + 101, effect_recharge=undefined};
    State#state.effect_recharge > 1 -> State#state{player_mana=State#state.player_mana + 101, effect_recharge=State#state.effect_recharge - 1};
    true -> State
  end.

% this spends the mana
cast_missile(State) ->
  State#state{
    player_mana=State#state.player_mana - ?MISSILE_COST
    , boss_hp=State#state.boss_hp - 4
    , spent_mana=State#state.spent_mana + ?MISSILE_COST
   }.

cast_drain(State) ->
  State#state{
    player_mana=State#state.player_mana - ?DRAIN_COST
    , player_hp=State#state.player_hp + 2
    , boss_hp=State#state.boss_hp - 2
    , spent_mana=State#state.spent_mana + ?DRAIN_COST
   }.

cast_shield(State) ->
  State#state{
    player_mana=State#state.player_mana - ?SHIELD_COST
    , effect_shield=6
    , spent_mana=State#state.spent_mana + ?SHIELD_COST
   }.

cast_poison(State) ->
  State#state{
    player_mana=State#state.player_mana - ?POISON_COST
    , effect_poison=6
    , spent_mana=State#state.spent_mana + ?POISON_COST
   }.

cast_recharge(State) ->
  State#state{
    player_mana=State#state.player_mana - ?RECHARGE_COST
    , effect_recharge=5
    , spent_mana=State#state.spent_mana + ?RECHARGE_COST
   }.

apply_effects(State) ->
  % i hope it doesn't matter what order the effects apply in?
  apply_poison(
    apply_shield(
      apply_recharge(State)
     )
   ).

get_winner(State) ->
  if % player death takes precedence
    State#state.player_hp =< 0 -> boss;
    State#state.boss_hp =< 0 -> player;
    true -> undefined
  end.

has_winner(State) ->
  State#state.player_hp =< 0 orelse State#state.boss_hp =< 0.

play_turn(State0, Spell) ->
  print_turn_header(State0, 'Player'),

  Has_Winner0 = has_winner(State0),
  State1 = if
    Has_Winner0 -> State0;
    true -> apply_effects(State0)
  end,

  Has_Winner1 = has_winner(State1),
  State2 = if
    Has_Winner1 -> State1;
    true -> player_turn(State1, Spell)
  end,

  print_turn_header(State2, 'Boss'),

  Has_Winner2 = has_winner(State2),
  State3 = if
    Has_Winner2 -> State2;
    true -> apply_effects(State2)
  end,

  Has_Winner3 = has_winner(State3),
  if
    Has_Winner3 -> State3;
    true -> boss_turn(State3)
  end.

play_script(State, []) ->
  print_state(State),
  io_wrapper("*** FIN~n", []),
  State;
play_script(State, [Spell | Rest]) ->
  play_script(play_turn(State, Spell), Rest).

try_spell(State, Spell) ->
  Cost = spell_cost(Spell),
  play_next_round(if
    State#state.player_mana >= Cost -> play_turn(State, Spell);
    true -> State
  end).

play_next_round(State) ->
  HasWinner = has_winner(State),
  if not HasWinner ->
    MissileState = try_spell(State, missile),
    DrainState = try_spell(State, drain),
    ShieldState = try_spell(State, shield),
    PoisonState = try_spell(State, poison),
    RechargeState = try_spell(State, recharge);
    true -> State
  end.

blank_state() ->
  #state{
     player_hp=0
     , player_armor=0
     , player_mana=0
     , boss_hp=0
     , boss_damage=0
  }.

part1_start_search() ->
  State = (blank_state()),
  play_next_round(State#state{
    player_hp=50, player_mana=500, boss_hp=51, boss_damage=9
  }).

example_one_test() ->
  Init = blank_state(),
  Result = play_script(
    Init#state{
       player_hp=10
       , player_mana=250
       , boss_hp=13
       , boss_damage=8
       , spent_mana=0
    }
    , [
       poison
       , missile
      ]
   ),
  #state{
     player_hp=2
     , player_armor=0
     , player_mana=24
     , boss_hp=0
     , boss_damage=8
     , effect_poison=3
     , effect_shield=undefined
     , effect_recharge=undefined
     , spent_mana=226
    } = Result,
  player = get_winner(Result).

example_two_b_test() ->
  Result0 = apply_effects(
      #state{
         player_hp=10
         , player_armor=0
         , player_mana=250
         , boss_hp=14
         , boss_damage=8
         , spent_mana=0
        }
    ),
  #state{
     player_hp=10
     , player_armor=0
     , player_mana=250
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=undefined
     , effect_recharge=undefined
    } = Result0,

  Result1 = player_turn(Result0, recharge),
  #state{
     player_hp=10
     , player_armor=0
     , player_mana=21
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=undefined
     , effect_recharge=5
    } = Result1,

  Result2 = apply_effects(Result1),
  #state{
     player_hp=10
     , player_armor=0
     , player_mana=122
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=undefined
     , effect_recharge=4
    } = Result2,

  Result3 = apply_effects(boss_turn(Result2)),
  #state{
     player_hp=2
     , player_armor=0
     , player_mana=223
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=undefined
     , effect_recharge=3
    } = Result3,

  Result4 = player_turn(Result3, shield),
  #state{
     player_hp=2
     , player_armor=0
     , player_mana=110
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=6
     , effect_recharge=3
    } = Result4,

  Result5 = apply_effects(Result4),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=211
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=5
     , effect_recharge=2
    } = Result5,

  Result6 = apply_effects(boss_turn(Result5)),
  #state{
     player_hp=1
     , player_armor=7
     , player_mana=312
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=4
     , effect_recharge=1
    } = Result6,

  Result7 = player_turn(Result6, drain),
  #state{
     player_hp=3
     , player_armor=7
     , player_mana=239
     , boss_hp=12
     , effect_poison=undefined
     , effect_shield=4
     , effect_recharge=1
    } = Result7,

  Result8 = boss_turn(Result7),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=239
     , boss_hp=12
     , effect_poison=undefined
     , effect_shield=4
     , effect_recharge=1
    } = Result8,

  Result9 = apply_effects(Result8),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=340
     , boss_hp=12
     , effect_poison=undefined
     , effect_shield=3
     , effect_recharge=undefined
    } = Result9,

  Result10 = player_turn(Result9, poison),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=167
     , boss_hp=12
     , effect_poison=6
     , effect_shield=3
     , effect_recharge=undefined
    } = Result10,

  Result11 = apply_effects(Result10),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=167
     , boss_hp=9
     , effect_poison=5
     , effect_shield=2
     , effect_recharge=undefined
    } = Result11,

  Result12 = boss_turn(Result11),
  #state{
     player_hp=1
     , player_armor=7
     , player_mana=167
     , boss_hp=9
     , effect_poison=5
     , effect_shield=2
     , effect_recharge=undefined
    } = Result12,

  Result13 = apply_effects(Result12),
  #state{
     player_hp=1
     , player_armor=7
     , player_mana=167
     , boss_hp=6
     , effect_poison=4
     , effect_shield=1
     , effect_recharge=undefined
    } = Result13,

  Result14 = player_turn(Result13, missile),
  #state{
     player_hp=1
     , player_armor=7
     , player_mana=114
     , boss_hp=2
     , effect_poison=4
     , effect_shield=1
     , effect_recharge=undefined
    } = Result14,

  Result15 = apply_effects(Result14),
  #state{
     player_hp=1
     , player_armor=0
     , player_mana=114
     , boss_hp=-1
     , effect_poison=3
     , effect_shield=undefined
     , effect_recharge=undefined
     , spent_mana=641
    } = Result15,

  example_two_b_test_passed.

example_two_test() ->
  Result0 = play_script(
    #state{
       player_hp=10
       , player_armor=0
       , player_mana=250
       , boss_hp=14
       , boss_damage=8
       , spent_mana=0
      }
    , [recharge]
   ),
  #state{
     player_hp=2
     , player_armor=0
     , player_mana=122
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=undefined
     , effect_recharge=4
    } = Result0,

  Result1 = play_script(Result0, [shield]),
  #state{
     player_hp=1
     , player_armor=7
     , player_mana=211
     , boss_hp=14
     , effect_poison=undefined
     , effect_shield=5
     , effect_recharge=2
    } = Result1,

  Result2 = play_script(Result1, [drain]),
  #state{
     player_hp=2
     , player_armor=7
     , player_mana=340
     , boss_hp=12
     , effect_poison=undefined
     , effect_shield=3
     , effect_recharge=undefined
     , spent_mana=415
    } = Result2,

  example_two_test_passed.
