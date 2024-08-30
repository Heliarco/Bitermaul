-- Shit we need to be able to do:
-- Spawn wave, give reward for kills, track progress and reward completed waves
-- Force controller need a "owed cash", and a "award cash" method. 
-- Maybe a "lock in forces / a slash start game command"


TODO: when player leaves, yoink their items and distribute?




# Assumptions
- At max one player per force.
- Once a game is running, a player can drop, but we don't care if they rejoin. Thats on them.

- After every wave, every force is paid out a flat amount. The amount is the same per force, no matter how many are active and have players. 
  - This means having a full roster will increase the amount of coins distributed. But we are assuming the majority of income comes from kills, this is mainly for bootstrapping and catchup. 
  - The economy should be balanced as such.
  

- 