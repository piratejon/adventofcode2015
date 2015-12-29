var assert = require('assert');
var p22 = require('./p22');

describe('p22_part1', function () {
    describe('example1', function () {
        it('initializes a player', function () {
            var player, boss;

            player = new p22.Player({hp: 10, armor: 0, mana: 250, dmg: 0});
            boss = new p22.Player({hp: 13, armor: 0, mana: 0, dmg: 8});

            assert.equal(player.hp, 10);
            assert.equal(player.armor, 0);
            assert.equal(player.mana, 250);
            assert.equal(player.dmg, 0);

            assert.equal(boss.hp, 13);
            assert.equal(boss.armor, 0);
            assert.equal(boss.mana, 0);
            assert.equal(boss.dmg, 8);
        });

        it('initializes a game', function () {
            var game, player, boss;

            player = new p22.Player({hp: 10, armor: 0, mana: 250, dmg: 0});
            boss = new p22.Player({hp: 13, armor: 0, mana: 0, dmg: 8});

            game = new p22.Game({p1: player, p2: boss});

            assert.equal(game.p1, player);
            assert.equal(game.p2, boss);
        });

        it('plays the first example', function () {
            var game, player, boss;

            player = new p22.Player({hp: 10, armor: 0, mana: 250, dmg: 0});
            boss = new p22.Player({hp: 13, armor: 0, mana: 0, dmg: 8});

            game = new p22.Game({p1: player, p2: boss});

            // initial state
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 250);
            assert.equal(game.p2.hp, 13);
            assert.deepEqual(game.effects, []);

            // no effects at first
            game.apply_effects();

            // turn 1
            game.cast({caster: game.p1, spell: 'Poison', target: game.p2});
            assert.deepEqual(game.effects, [{spell: 'Poison', ttl: 6, caster: game.p1, target: game.p2}]);
            assert.equal(game.p1, game.effects[0].caster);
            assert.equal(game.p2, game.effects[0].target);

            // turn 2
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 77);
            assert.equal(game.p2.hp, 13);
            game.apply_effects();
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 77);
            assert.equal(game.p2.hp, 10);
            game.attack({player: game.p2, target: game.p1});

            // turn 3
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 77);
            assert.equal(game.p2.hp, 10);
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 77);
            assert.equal(game.p2.hp, 7);
            game.cast({caster: game.p1, target: game.p2, spell: 'Magic Missile'});

            // turn 4
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 24);
            assert.equal(game.p2.hp, 3);
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 24);
            assert.equal(game.p2.mana, 0);
        });

        it('plays the second example', function () {
            var game, player, boss;

            player = new p22.Player({hp: 10, armor: 0, mana: 250, dmg: 0});
            boss = new p22.Player({hp: 14, armor: 0, mana: 0, dmg: 8});

            game = new p22.Game({p1: player, p2: boss});

            // initial state
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 250);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, []);

            // no effects at first
            game.apply_effects();

            // turn 1
            game.cast({caster: game.p1, spell: 'Recharge'});
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 21);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [{spell: 'Recharge', ttl: 5, caster: game.p1}]);

            // turn 2
            game.apply_effects();
            assert.equal(game.p1.hp, 10);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 122);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [{spell: 'Recharge', ttl: 4, caster: game.p1}]);
            game.attack({player: game.p2, target: game.p1});
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 122);
            assert.equal(game.p2.hp, 14);

            // turn 3
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 223);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [{spell: 'Recharge', ttl: 3, caster: game.p1}]);
            game.cast({caster: game.p1, spell: 'Shield'});
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.mana, 110);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [
                {spell: 'Recharge', ttl: 3, caster: game.p1},
                {spell: 'Shield', ttl: 6, caster: game.p1}
            ]);

            // turn 4
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 211);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [
                {spell: 'Recharge', ttl: 2, caster: game.p1},
                {spell: 'Shield', ttl: 5, caster: game.p1}
            ]);
            game.attack({player: game.p2, target: game.p1});
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 211);
            assert.equal(game.p2.hp, 14);

            // turn 5
            game.apply_effects();
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 312);
            assert.equal(game.p2.hp, 14);
            assert.deepEqual(game.effects, [
                {spell: 'Recharge', ttl: 1, caster: game.p1},
                {spell: 'Shield', ttl: 4, caster: game.p1}
            ]);
            game.cast({caster: game.p1, target: game.p2, spell: 'Drain'});
            assert.equal(game.p1.hp, 3);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 239);
            assert.equal(game.p2.hp, 12);

            // turn 6
            game.apply_effects();
            assert.equal(game.p1.hp, 3);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 340);
            assert.equal(game.p2.hp, 12);
            assert.deepEqual(game.effects, [
                {spell: 'Recharge', ttl: 0, caster: game.p1},
                {spell: 'Shield', ttl: 3, caster: game.p1}
            ]);
            game.attack({player: game.p2, target: game.p1});
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 340);
            assert.equal(game.p2.hp, 12);

            // turn 7
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 340);
            assert.equal(game.p2.hp, 12);
            assert.deepEqual(game.effects, [
                {spell: 'Shield', ttl: 2, caster: game.p1}
            ]);
            game.cast({caster: game.p1, target: game.p2, spell: 'Poison'});
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 167);
            assert.equal(game.p2.hp, 12);

            // turn 8
            game.apply_effects();
            assert.equal(game.p1.hp, 2);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 167);
            assert.equal(game.p2.hp, 9);
            assert.deepEqual(game.effects, [
                {spell: 'Shield', ttl: 1, caster: game.p1},
                {spell: 'Poison', ttl: 5, caster: game.p1, target: game.p2}
            ]);
            game.attack({player: game.p2, target: game.p1});
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 167);
            assert.equal(game.p2.hp, 9);

            // turn 9
            game.apply_effects();
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 167);
            assert.equal(game.p2.hp, 6);
            assert.deepEqual(game.effects, [
                {spell: 'Shield', ttl: 0, caster: game.p1},
                {spell: 'Poison', ttl: 4, caster: game.p1, target: game.p2}
            ]);
            game.cast({caster: game.p1, target: game.p2, spell: 'Magic Missile'});
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 114);
            assert.equal(game.p2.hp, 2);

            // turn 10
            game.apply_effects();
            assert.equal(game.p1.hp, 1);
            assert.equal(game.p1.armor, 0);
            assert.equal(game.p1.effective_armor, 7);
            assert.equal(game.p1.mana, 114);
            assert.equal(game.p2.hp, -1);
            assert.deepEqual(game.effects, [
                {spell: 'Poison', ttl: 3, caster: game.p1, target: game.p2}
            ]);
        });
    });
});
