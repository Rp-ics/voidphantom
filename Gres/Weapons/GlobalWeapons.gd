extends Node

# =========================
# GLOBAL WEAPONS - RARITY SYSTEM
# =========================
var gun_info := ""

# =========================
# INVENTARIO TEMPORANEO (run corrente)
# =========================

signal gun_found(weapon_name: String, rarity: String)

var inventory: Array = []

var weapons: Dictionary = {

	# ============================================================
	# == STANDARD WEAPONS  (Common / Rare / Epic)
	# ============================================================

	"SOLBREAKER": {
		"common": {
			"suffix": "Solar Spark",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_0C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/blaster_bulletC.png",
			"damage": 24.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.4,
			"bullet_consume": 1,
			"projectile_type": "line",
			"sound": "res://Gres/Music/SE/gun_1.ogg",
			"info": "A compact blaster forged from crystallized sunlight. Basic, reliable, lethal."
		},
		"rare": {
			"suffix": "Radiant Core",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_0R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/blaster_bulletR.png",
			"damage": 30.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "ImplosionBurst",
			"sound": "res://Gres/Music/SE/gun_2.ogg",
			"info": "The core overloads on impact — every shot collapses inward, then detonates outward in a burst of shrapnel."
		},
		"epic": {
			"suffix": "Ascendant Core",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_0E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/blaster_bulletE.png",
			"damage": 38.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "ImplosionBurst",
			"sound": "res://Gres/Music/SE/gun_3.ogg",
			"info": "Ascended beyond physics. Each implosion shred pulls nearby enemies before blasting them apart. Stars fear this gun."
		}
	},
	
	"AEGIS TEMPEST": {
		"common": {
			"suffix": "Storm Edge",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_1C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/rapid_shot_bulletC.png",
			"damage": 45.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.3,
			"bullet_consume": 1,
			"projectile_type": "line",
			"sound": "res://Gres/Music/SE/gun_4.ogg",
			"info": "High-cycle rapid fire. Shreds light armor like paper in a hurricane."
		},
		"rare": {
			"suffix": "Thunder Veil",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_1R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/rapid_shot_bulletR.png",
			"damage": 60.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.28,
			"bullet_consume": 1,
			"projectile_type": "cone_3",
			"sound": "res://Gres/Music/SE/gun_5.ogg",
			"info": "Three bolts per pull. Each fired in a crackling spread that overwhelms dodge patterns."
		},
		"epic": {
			"suffix": "Storm Revelation",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_1E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/rapid_shot_bulletE.png",
			"damage": 75.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.20,
			"bullet_consume": 1,
			"projectile_type": "wave_split",
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "The shot blooms mid-air into a fan of splitting plasma. One bullet becomes five. Five becomes carnage."
		}
	},

	"HELLWING": {
		"common": {
			"suffix": "Ember Shard",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_2C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_3_bulletC.png",
			"damage": 5 * 3 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "cone_3",
			"sound": "res://Gres/Music/SE/gun_7.ogg",
			"info": "A shotgun born in the inferno. Close range is a death sentence."
		},
		"rare": {
			"suffix": "Flame Surge",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_2R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_3_bulletR.png",
			"damage": 10 * 3 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.28,
			"bullet_consume": 1,
			"projectile_type": "cone_3",
			"sound": "res://Gres/Music/SE/gun_8.ogg",
			"info": "The surge of flame is wide enough to swallow a formation whole. Burns aren't applied — they're guaranteed."
		},
		"epic": {
			"suffix": "Infernal Reign",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_2E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_3_bulletE.png",
			"damage": 16 * 3 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.50,
			"bullet_consume": 1,
			"projectile_type": "ImplosionBurst",
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "Hellwing at its apex. The blast implodes first — sucking enemies inward — then erupts in pure hellfire."
		}
	},

	"NEBULAR STORM": {
		"common": {
			"suffix": "Stellar Drift",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_3C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_5_bulletC.png",
			"damage": 75 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "cone_5",
			"sound": "res://Gres/Music/SE/gun_10.ogg",
			"info": "Five-pronged cosmic spray. Nowhere to run when the nebula opens fire."
		},
		"rare": {
			"suffix": "Cosmic Flare",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_3R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_5_bulletR.png",
			"damage": 78 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "cone_5",
			"sound": "res://Gres/Music/SE/gun_11.ogg",
			"info": "The flare expands before it dies. Tight corridors become coffins."
		},
		"epic": {
			"suffix": "Ecliptic Veil",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_3E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/spread_5_bulletE.png",
			"damage": 80 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.24,
			"bullet_consume": 1,
			"projectile_type": "cone_5",
			"sound": "res://Gres/Music/SE/gun_12.ogg",
			"info": "The Veil doesn't fire bullets — it fires the edge of a collapsing star. Enemies caught in the outer ring get dragged toward center."
		}
	},

	"VOIDLANCE": {
		"common": {
			"suffix": "Shadow Pierce",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_4C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/piercer_bulletC.png",
			"damage": 50.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.28,
			"bullet_consume": 1,
			"projectile_type": "line",
			"sound": "res://Gres/Music/SE/gun_13.ogg",
			"info": "A single bolt of condensed void. What it touches, it erases."
		},
		"rare": {
			"suffix": "Abyss Spear",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_4R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/piercer_bulletR.png",
			"damage": 150.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.9,
			"bullet_consume": 1,
			"projectile_type": "Orbitals",
			"sound": "res://Gres/Music/SE/gun_14.ogg",
			"info": "Three orbital blades materialize and orbit your ship, shredding anything that dares to close in."
		},
		"epic": {
			"suffix": "Oblivion Spear",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_4E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/piercer_bulletE.png",
			"damage": 99.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.38,
			"bullet_consume": 1,
			"projectile_type": "VoidRift",
			"sound": "res://Gres/Music/SE/gun_15.ogg",
			"info": "The shot tears space itself — leaving a rift that enemies are pulled through and destroyed inside."
		}
	},

	"ASTRIX REBOUND": {
		"common": {
			"suffix": "Echo Shot",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_5C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletC.png",
			"damage": 110.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "bounce",
			"sound": "res://Gres/Music/SE/gun_16.ogg",
			"info": "Ricochets off the arena walls. Every bounce is another chance to kill."
		},
		"rare": {
			"suffix": "Mirror Burst",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_5R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletR.png",
			"damage": 140.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.28,
			"bullet_consume": 1,
			"projectile_type": "VoidRift",
			"sound": "res://Gres/Music/SE/gun_17.ogg",
			"info": "Every impact spawns a micro-rift. Enemies near the rift get a second helping of pain."
		},
		"epic": {
			"suffix": "Gravity Mirror",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_5E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletE.png",
			"damage": 180.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.20,
			"bullet_consume": 1,
			"projectile_type": "ImplosionBurst",
			"sound": "res://Gres/Music/SE/gun_18.ogg",
			"info": "On impact it folds space — hurling everything nearby toward the epicenter, then detonating outward. Physics is optional here."
		}
	},

	"PHANTOM SEEKER": {
		"common": {
			"suffix": "Ghost Trace",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_6C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/homing_shot_bulletC.png",
			"damage": 90.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.30,
			"bullet_consume": 1,
			"projectile_type": "homing",
			"sound": "res://Gres/Music/SE/gun_19.ogg",
			"info": "It knows where you're going before you do. Evasion is an illusion."
		},
		"rare": {
			"suffix": "Soul Tracer",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_6R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/homing_shot_bulletR.png",
			"damage": 120.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.24,
			"bullet_consume": 1,
			"projectile_type": "homing",
			"sound": "res://Gres/Music/SE/gun_20.ogg",
			"info": "Locks on to the nearest soul and refuses to let go. Not even teleporting enemies escape it."
		},
		"epic": {
			"suffix": "Soul Hunter",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_6E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/homing_shot_bulletE.png",
			"damage": 160.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.14,
			"bullet_consume": 1,
			"projectile_type": "homing",
			"sound": "res://Gres/Music/SE/gun_21.ogg",
			"info": "The hunter does not miss. The hunter does not tire. The hunter has never lost its prey. You are the hunter."
		}
	},

	"OMNIVORE": {
		"common": {
			"suffix": "Void Bite",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_7C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/follow_bullet_bulletC.png",
			"damage": 120.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.40,
			"bullet_consume": 1,
			"projectile_type": "follow_stop",
			"sound": "res://Gres/Music/SE/gun_22.ogg",
			"info": "Fires a short-lunge bolt that lunges toward the nearest target — then vanishes. One bite. One kill."
		},
		"rare": {
			"suffix": "Hunger Swarm",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_7R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/follow_bullet_bulletR.png",
			"damage": 150.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "follow_stop",
			"sound": "res://Gres/Music/SE/gun_23.ogg",
			"info": "The swarm hungers. Each shot locks briefly and lunges with terrifying speed. You just point. It does the rest."
		},
		"epic": {
			"suffix": "Dimension Feast",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_7E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/follow_bullet_bulletE.png",
			"damage": 200.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.22,
			"bullet_consume": 1,
			"projectile_type": "follow_stop",
			"sound": "res://Gres/Music/SE/gun_24.ogg",
			"info": "It feasts across dimensions. The bullet phases through space to reach its target. Shields are skin. Armor is paper."
		}
	},

	"SUPERNOVA CORE": {
		"common": {
			"suffix": "Flare Pulse",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_8C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/exploding_shot_bulletC.png",
			"damage": 280.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.48,
			"bullet_consume": 1,
			"projectile_type": "explode_after",
			"sound": "res://Gres/Music/SE/gun_25.ogg",
			"info": "A delayed detonation round. It travels far, then decides it's done waiting."
		},
		"rare": {
			"suffix": "Nova Bloom",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_8R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/exploding_shot_bulletR.png",
			"damage": 360.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.38,
			"bullet_consume": 1,
			"projectile_type": "explode_after",
			"sound": "res://Gres/Music/SE/gun_26.ogg",
			"info": "The bloom detonates in a perfect radial bloom of plasma. Clean. Devastating. Beautiful."
		},
		"epic": {
			"suffix": "Final Collapse",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_8E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/exploding_shot_bulletE.png",
			"damage": 500.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "explode_after",
			"sound": "res://Gres/Music/SE/gun_27.ogg",
			"info": "The final collapse of a miniature star, bottled and fired. The explosion radius is not a suggestion."
		}
	},

	"ECLIPSE FRACTAL": {
		"common": {
			"suffix": "Split Wave",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_9C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/wave_split_shot_bulletC.png",
			"damage": 130.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "wave_split",
			"sound": "res://Gres/Music/SE/gun_28.ogg",
			"info": "One becomes many. The wave splits on command, fanning into a wall of projectiles."
		},
		"rare": {
			"suffix": "Paradox Weave",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_9R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/wave_split_shot_bulletR.png",
			"damage": 180.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.28,
			"bullet_consume": 1,
			"projectile_type": "wave_split",
			"sound": "res://Gres/Music/SE/gun_29.ogg",
			"info": "The weave splits AND loops — a second wave curves back from behind. Enemies are caught between two fronts."
		},
		"epic": {
			"suffix": "Paradox Bloom",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_9E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/wave_split_shot_bulletE.png",
			"damage": 200.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.18,
			"bullet_consume": 1,
			"projectile_type": "wave_split",
			"sound": "res://Gres/Music/SE/gun_30.ogg",
			"info": "The Paradox Bloom doesn't split — it fractures reality. Every splinter finds a target. There are no wasted rounds."
		}
	},

	"VOID REAVER": {
		"common": {
			"suffix": "Void Fang",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_10C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletC.png",
			"damage": 120.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.50,
			"bullet_consume": 1,
			"projectile_type": "line",
			"sound": "res://Gres/Music/SE/gun_31.ogg",
			"info": "A weapon that tastes the void with every shot. Heavy. Relentless. Hungry."
		},
		"rare": {
			"suffix": "World Cleaver",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_10R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletR.png",
			"damage": 140.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.42,
			"bullet_consume": 1,
			"projectile_type": "piercing_burn",
			"sound": "res://Gres/Music/SE/gun_32.ogg",
			"info": "The cleaver passes through enemies — leaving a trail of burning void in its wake. It doesn't stop for anyone."
		},
		"epic": {
			"suffix": "Eater of Worlds",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_10E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletE.png",
			"damage": 155.0 * Global.player_damage,
			"speed": Global.player_bullet_speed,
			"fire_rate": 0.32,
			"bullet_consume": 1,
			"projectile_type": "zigzag",
			"sound": "res://Gres/Music/SE/gun_33.ogg",
			"info": "The Eater is not aimed — it hunts. The bolt zigzags between targets, consuming everything it touches. Entire formations collapse."
		}
	},

	# ============================================================
	# == CONSTELLATION WEAPONS  (Legendary)
	# ============================================================

	"VULRATH IGNIS-SUNDER": {
		"legendary": {
			"suffix": "Burning Vortex of Ruin",
			"texture": "res://Gres/Assets/player/canon/aries.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletE.png",
			"damage": 152.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.3,
			"fire_rate": 0.38,
			"bullet_consume": 2,
			"projectile_type": "piercing_burn",
			"sound": "res://Gres/Music/SE/gun_34.ogg",
			"info": "Born from the Ram constellation. Its rounds burn through shields, armor, and hope simultaneously. Each piercing bolt leaves a corridor of searing void that persists for 2 seconds — lethal to anything crossing it. Passive: +18% fire rate when below 40% HP. Active: every 8 kills triggers a free Hellfire Surge — 12 burning bolts in all directions."
		}
	},

	"GORHAL IRONBREAKER": {
		"legendary": {
			"suffix": "Seismic Pulse of Dominion",
			"texture": "res://Gres/Assets/player/canon/taurus.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletE.png",
			"damage": 168.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.9,
			"fire_rate": 0.60,
			"bullet_consume": 2,
			"projectile_type": "seismic_bounce",
			"sound": "res://Gres/Music/SE/gun_35.ogg",
			"info": "Gorhal was forged from the bones of a dead star under the sign of the Bull. Fires a massive seismic slug that bounces off arena walls, releasing a shockwave on every impact that stuns and damages all enemies in a 150-unit radius. Passive: +22% max HP. Each kill has a 15% chance to instantly restore 8 HP. This weapon hits like a god. Because it is one."
		}
	},

	"SHYREL DUAL-FATE": {
		"legendary": {
			"suffix": "Twinstream Echo of Fate",
			"texture": "res://Gres/Assets/player/canon/gemini.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletE.png",
			"damage": 200.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.1,
			"fire_rate": 0.22,
			"bullet_consume": 2,
			"projectile_type": "dual_beam",
			"child_projectile_type": "homing",
			"sound": "res://Gres/Music/SE/gun_36.ogg",
			"info": "The Twins fire two homing beams simultaneously — one for each soul. Each beam tracks independently. If both hit the same target, they resonate and the second deals 200% damage. Passive: Critical hit chance +12%. Each critical spawns a ghost copy of the projectile that fires once before vanishing. The fates have already decided. You're just delivering the verdict."
		}
	},

	"ANONYMOUSE MAELKRITH": {
		"legendary": {
			"suffix": "Tidefall Whisper of Tech",
			"texture": "res://Gres/Assets/player/canon/cancer.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/reaver_shot_bulletE.png",
			"damage": 144.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.2,
			"fire_rate": 0.40,
			"bullet_consume": 2,
			"projectile_type": "tide_homing",
			"sound": "res://Gres/Music/SE/gun_37.ogg",
			"info": "Cancer — the silent sign. Maelkrith's rounds whisper through space, guided by alien tide-patterns that no enemy AI can predict. The shots curve wildly before snapping to target with terrifying precision. Passive: +25% damage against shielded enemies. On hit, 20% chance to steal the enemy's shield and apply it to you for 3 seconds."
		}
	},

	# ============================================================
	# == BOSS WEAPONS  (Legendary — Drops / Crafted)
	# ============================================================

	"GAEA CORE": {
		"legendary": {
			"suffix": "Suffer",
			"texture": "res://Gres/Assets/Icons/craft/gaea_core.png",
			"bullet_texture": "res://Gres/Assets/Effects/64x64_Aura_3.png",
			"damage": 195.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.9,
			"fire_rate": 0.55,
			"bullet_consume": 1,
			"projectile_type": "gaea_core_main",
			"sound": "res://Gres/Music/SE/gaea_core_shot.ogg",
			"info": "Ripped from the body of the Gaea boss. Four orbital fragments circle your ship and intercept incoming projectiles. Each main shot is a miniature planet that explodes into a shockwave (radius 600) on impact. Passive: 6 living fragments orbit you at all times — each deals 20 damage on contact. Active: every 5 shots, triggers GAIA PULSE — a screen-wide energy discharge that deals 120x your damage to ALL enemies simultaneously. This is not a gun. It is a world-ending event.",
			"special_power": {
				"passive": "4–6 orbital fragments circle the player intercepting enemy bullets. Each fragment pulses damage to nearby enemies.",
				"active": "Every 5 charged shots triggers GAIA PULSE — a full-screen shockwave dealing 120x player damage to all enemies."
			},
			"fragments_count": 6,
			"fragment_orbit_speed": 140.0,
			"pulse_radius": 600.0,
			"pulse_damage": 120 * Global.player_damage,
		}
	},

	"BLOOD_NEXUS": {
		"legendary": {
			"suffix": "Harrow",
			"texture": "res://Gres/Assets/Icons/craft/blood_mother_weapon.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/blood_bullet.png",
			"damage": 188.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.4,
			"fire_rate": 0.50,
			"bullet_consume": 4,
			"projectile_type": "blood_nexus_main",
			"sound": "res://Gres/Music/SE/gun_1.ogg",
			"info": "The weapon of the Blood Mother. Every shot creates a living blood-link between up to 4 enemies — they share 50% of any damage dealt to any one of them. Active: RED CONVERGENCE — all linked enemies are magnetically pulled toward the center and crushed for 40 DPS over 2 seconds, then detonated. Passive: kill a linked target and all linked allies take 60% of the killing blow instantly. You don't fight armies. You execute networks.",
			"special_power": {
				"passive": "Enemies linked by blood share 50% of all damage. Killing one triggers a 60% damage echo on all remaining linked targets.",
				"active": "RED CONVERGENCE: pulls all linked enemies to a central point, crushing them for 40 DPS over 2s, then detonates the link."
			},
			"blood_link_time_window": 0.4,
			"blood_link_max_targets": 4,
			"blood_link_damage_share": 0.50,
			"convergence_radius": 600.0,
			"convergence_dps": 40,
			"convergence_duration": 2.0,
			"convergence_pull_force": 900.0
		}
	},

	# ============================================================
	# == VOID WEAPONS  (Legendary — VoidCoins only — Endgame)
	# ============================================================

	"NULLBORN SOVEREIGN": {
		"legendary": {
			"suffix": "Throne of Absolute Zero",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_23E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_ice_bullest.png",
			"damage": 240.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.6,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "nullborn_sovereign_shot",
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "Forged at the event horizon of a dead universe. The NULLBORN SOVEREIGN fires a singularity bolt that freezes space around the impact point\nall enemies within 300 units are suspended in absolute zero for 3.5 seconds, unable to move or attack, then the frozen field shatters into 24 razor shards that pursue nearby enemies independently.\n\nPASSIVE: You are 30% faster while any enemy is frozen. Every frozen kill has a 25% chance to drop a VoidCoin fragment.\n\nACTIVE — SOVEREIGN'S DECREE: Once every 20 seconds, fires an OMNI-WAVE that freezes the ENTIRE screen for 4 seconds while you deal 3x damage.\n\nDuring this window, your bullets do not consume stamina. You are not the player. You are the law."
		}
	},

	"OBLIVION HERALD": {
		"legendary": {
			"suffix": "Last Word Before Silence",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_24E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_2.png",
			"damage": 220.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.85,
			"fire_rate": 0.30,
			"bullet_consume": 1,
			"projectile_type": "oblivion_herald_shot",
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "The gun that erased a civilization in a single shot.\nThe OBLIVION HERALD fires a slow, massive void-shell that leaves a trail of gravitational distortion — any enemy passing through the trail takes 15 damage per second and is slowed 60%.\n\nOn impact, the shell detonates in a VOID NOVA: a black hole opens for 2.8 seconds, pulling ALL enemies toward it at force 1200, dealing 80 damage per second while held.\n\nPASSIVE: Kills near the black hole restore 12 HP each. +40% critical damage. Every 5th shot is automatically a guaranteed critical.\n\nACTIVE — HERALD'S JUDGMENT: Marks all enemies on screen.\nFor 10 seconds, every shot on a marked enemy chains to ALL other marked enemies for 70% damage. This is not a weapon.\n\nThis is an ending."
		}
	},

	"VOIDFATHER'S ECLIPSE": {
		"legendary": {
			"suffix": "The Eye That Watches Eternally",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_22E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_4.png",
			"damage": 260.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.5,
			"fire_rate": 0.30,
			"bullet_consume": 1,
			"projectile_type": "voidfather_eclipse_shot",
			"sound": "res://Gres/Music/SE/gaea_core_shot.ogg",
			"info": "There are stories about who built this. They are wrong.\nThe VOIDFATHER'S ECLIPSE does not fire a bullet — it fires the concept of annihilation. A slow-moving eclipse orb that converts 5% of your current HP into raw bonus damage (capped at +150), then explodes on impact in a\nDIMENSIONAL COLLAPSE: a 500-unit vortex that leave 50% Max HP all non-boss enemies instantly, and strips 2% HP from bosses in a single frame.\n\nPASSIVE: You are immune to damage for 1.5 seconds after each shot. You gain VOID EMPOWERMENT stacks for every kill — each stack adds +3% damage and +1% fire rate, up to 50 stacks. Stacks reset on death.\n\nACTIVE — THE ECLIPSE: Once every 40 seconds, you become the Voidfather for 8 seconds.\n\nDuring this window: invincible, all shots become eclipse orbs at no HP cost, and kill any enemy in one hit regardless of HP.\n\nYour ship turns black. The screen darkens. The music stops. You are the end."
		}
	},

	# ============================================================
	# == 13 NUOVE ARMI VOID  (Legendary — VoidCoins only — Endgame)
	# ============================================================

	# ARMA 1: AEGIS STORM — scudo + scarica esplosiva
	"AEGIS STORM": {
		"legendary": {
			"suffix": "Shield of a Thousand Deaths",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_25E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_5.png",
			"damage": 600.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.8,
			"fire_rate": 1.2,           # lenta perché richiede hold
			"bullet_consume": 1,
			"projectile_type": "aegis_storm_shot",
			# Parametri specifici dell'arma
			"max_charge_time": 5.0,     # secondi massimi di carica
			"min_bullets": 1,           # proiettili se rilasci subito
			"max_bullets": 20,          # proiettili a carica massima
			"shield_deflect_chance": 50, # % respingimento proiettili nemici
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "Hold to charge.\n\nA rotating void-shield engulfs your ship — 80% chance to deflect enemy projectiles.\n\nRelease to unleash a burst of 1–20 bullets in all directions.\n\nThe longer you hold, the more chaos you unleash.\n\nPASSIVE: Shield persists while charging.\n\nACTIVE: Full 5s charge triggers STORM SURGE — bullets gain homing and +60% damage."
		}
	},

	# ARMA 2: MIND FRACTURE — controllo mentale + veleno
	"MIND FRACTURE": {
		"legendary": {
			"suffix": "Puppeteer of the Broken",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_26E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_6.png",
			"damage": 199.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.1,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "mind_fracture_shot",
			"poison_chance": 20,        # % di avvelenare il nemico
			"control_chance": 30,       # % di prendere il controllo
			"control_duration": 10.0,   # secondi di controllo mentale
			"control_hp_drain": 10.0,   # % HP persi al secondo durante controllo
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "20% chance to POISON on hit.\n\n30% chance to MIND CONTROL: the enemy turns against its allies, losing 10% HP every 1 second. Controlled enemies fire as allied units using their own bullet type — not player bullets. When they die from the drain, they explode dealing 200% of their max HP as AoE.\n\nPASSIVE: Each controlled kill permanently increases control chance by 1% (max +15%).\n\nACTIVE: Chaos Create an army of zombies for a few seconds.\n\nAll enemies on the battlefield become your zombies and fight each other."
		}
	},

	# ARMA 3: WALL CASTER — muro difensivo
	"WALL CASTER": {
		"legendary": {
			"suffix": "Fortress of the Void",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_27E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_7.png",
			"damage": 160.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.3,
			"fire_rate": 0.25,
			"bullet_consume": 1,
			"projectile_type": "wall_caster_shot",
			"wall_chance": 10,          # % di creare un muro
			"wall_duration": 4.0,       # secondi che il muro persiste
			"wall_width": 300.0,        # larghezza del muro in pixel
			"sound": "res://Gres/Music/SE/gaea_core_shot.ogg",
			"info": "10% chance on fire: a VOID WALL materializes in front of you, blocking all enemies and projectiles for 4 seconds.\n\nPASSIVE: Wall spawn chance scales to 25% below 30% HP.\n\nACTIVE: Manual wall — costs 30 stamina, guaranteed wall creation with double duration."
		}
	},

	# ARMA 4: PROXIMITY MINE — proiettile-mina stazionaria
	"PROXIMITY MINE": {
		"legendary": {
			"suffix": "Patience of the Abyss",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_28E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_8.png",
			"damage": 180.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.0,
			"fire_rate": 0.35,
			"bullet_consume": 1,
			"projectile_type": "proximity_mine_shot",
			"mine_stop_time": 0.5,      # secondi dopo cui si ferma
			"mine_trigger_radius": 80.0, # raggio di attivazione
			"mine_explosion_radius": 200.0, # raggio esplosione
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "The bullet travels for 0.5s then freezes in space as a VOID MINE.\n\nEnemies within 80px trigger detonation — a 200px AoE explosion dealing full damage.\n\nMines persist until triggered or after 12 seconds.\n\nUp to 8 active mines at once.\n\nPASSIVE: Chain reaction — if two mines explode within 0.5s of each other, the second deals +50% damage.\n\nACTIVE: Detonate ALL mines simultaneously."
		}
	},

	# ARMA 5: GRAVITON PULSE — forza magnetica attrattiva
	"GRAVITON PULSE": {
		"legendary": {
			"suffix": "Singularity's Embrace",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_29E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_9.png",
			"damage": 185.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 0.9,
			"fire_rate": 0.40,
			"bullet_consume": 1,
			"projectile_type": "graviton_pulse_shot",
			"magnet_pull_force": 600.0, # forza di attrazione
			"magnet_tick_damage": 7.0,  # danno ogni 0.5s (5-10 come richiesto)
			"magnet_tick_rate": 0.5,    # secondi tra tick di danno
			"magnet_duration": 3.5,     # secondi di persistenza
			"magnet_radius": 300.0,     # raggio di attrazione
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "Fires a GRAVITON NODE that anchors in place.\n\nAll enemies within 300px are pulled toward it, taking 7 damage every 0.5 seconds. The node lasts 3.5 seconds.\n\nPASSIVE: Enemies crushed at center (within 30px) take 5x damage.\n\nACTIVE: GRAVITON COLLAPSE — next shot creates a node 3x larger and pulls ALL enemies on screen."
		}
	},

	# ARMA 6: PHANTOM ECHO — duplica proiettili, effetto fantasma
	"PHANTOM ECHO": {
		"legendary": {
			"suffix": "Ghost of the Last Shot",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_30E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_10.png",
			"damage": 288.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.4,
			"fire_rate": 0.30,
			"bullet_consume": 1,
			"projectile_type": "phantom_echo_shot",
			"echo_delay": 0.3,          # secondi di delay prima del secondo proiettile
			"echo_damage_mult": 0.75,   # moltiplicatore danno dell'eco
			"echo_count": 3,            # quante copie fantasma vengono spawnate
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "Each shot creates 3 PHANTOM ECHOES — ghost copies that follow 0.3s apart on the same trajectory, dealing 75% damage each.\n\nTotal potential: 325% damage per trigger.\n\nPASSIVE: If all 3 echoes hit the same target, it becomes HAUNTED — takes 20% more damage from all sources for 5s.\n\nACTIVE: ECHO STORM — for 4s, every shot fires 6 echoes instead of 3."
		}
	},

	# ARMA 7: CHRONO RIPPER — rallenta il tempo locale ai nemici
	"CHRONO RIPPER": {
		"legendary": {
			"suffix": "Tear in the Timeline",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_31E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_11.png",
			"damage": 300.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.5,
			"fire_rate": 0.42,
			"bullet_consume": 1,
			"projectile_type": "chrono_ripper_shot",
			"slow_amount": 0.15,        # velocità ridotta al 15% (quasi fermo)
			"slow_duration": 3.0,       # secondi di slow
			"time_field_radius": 150.0, # raggio della bolla temporale
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "On hit, creates a LOCAL TIME FIELD around the target — all enemies within 150px are slowed to 15% speed for 3 seconds.\nThe field is visible as a distortion bubble.\n\nPASSIVE: You move 20% faster while enemies are inside a time field.\nACTIVE: CHRONO BURST — freezes all enemies on screen for 2s, cooldown 25s. During the freeze you deal +100% damage."
		}
	},

	# ARMA 8: SOUL LEECH — drena vita dai nemici
	"SOUL LEECH": {
		"legendary": {
			"suffix": "Hunger Without End",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_32E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_12.png",
			"damage": 378.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.2,
			"fire_rate": 0.38,
			"bullet_consume": 1,
			"projectile_type": "soul_leech_shot",
			"leech_percent": 0.15,      # 15% del danno inflitto torna come HP
			"leech_overheal": true,     # può superare l'HP massimo fino a +20%
			"leech_overheal_max": 1.20, # max HP extra (120% del massimo)
			"sound": "res://Gres/Music/SE/gaea_core_shot.ogg",
			"info": "Every hit with 15% chance restores 15% of damage dealt as HP.\n\nCan OVERHEAL to 120% max HP — excess creates a golden shield.\n\nPASSIVE: When overhealed, deal +25% damage.\n\nACTIVE: SOUL DRAIN — target enemy is drained for 3s, transferring 8% of their current HP to you every second. Cooldown 18s."
		}
	},

	# ARMA 9: ENTROPY CANNON — aumenta il danno quanto più è lontano il bersaglio
	"ENTROPY CANNON": {
		"legendary": {
			"suffix": "Distance is Death",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_33E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_13.png",
			"damage": 370.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.8,
			"fire_rate": 0.50,
			"bullet_consume": 1,
			"projectile_type": "entropy_cannon_shot",
			"min_range_bonus": 0.5,     # danno minimo a corto raggio (50%)
			"max_range_bonus": 3.0,     # danno massimo a lungo raggio (300%)
			"max_range_px": 800.0,      # distanza per danno massimo
			"trail_damage": 8.0,        # danno del trail al passaggio
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "Damage scales with travel distance: 50% at point-blank, up to 300% at 800px.\n\nLeaves a scorching trail that deals 8 damage to enemies it passes through.\n\nPASSIVE: Fully-powered shots (max range) cause ENTROPY COLLAPSE — target is stunned for 1s and takes +40% damage for 3s.\n\nACTIVE: LONG SHOT — next shot travels infinitely and gains max range bonus regardless of actual distance."
		}
	},

	# ARMA 10: NECRO PULSE — riattiva i cadaveri come alleati temporanei
	"NECRO PULSE": {
		"legendary": {
			"suffix": "Rise From the Void",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_34E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_1.png",
			"damage": 382.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.0,
			"fire_rate": 0.45,
			"bullet_consume": 1,
			"projectile_type": "necro_pulse_shot",
			"revive_chance": 25,        # % di rianimare un nemico appena ucciso
			"revive_duration": 8.0,     # secondi come alleato
			"revive_hp_percent": 0.30,  # HP del rianimato (30% del massimo)
			"revive_damage_mult": 0.5,  # danno dei rianimati (50% normale)
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "25% chance to REANIMATE a freshly killed enemy as your thrall for 8s (30% HP, 50% damage).\n\nThralls fight for you and explode on death dealing 100% of their max HP as AoE.\n\nPASSIVE: Each active thrall grants +5% damage.\nMax 4 simultaneous thralls.\n\nACTIVE: NECRO SURGE — reanimates ALL enemies killed in the last 3 seconds.\nCooldown 30s."
		}
	},

	# ARMA 11: RIFT BLADE — proiettile che taglia la mappa in due con una linea di danno
	"RIFT BLADE": {
		"legendary": {
			"suffix": "Scar Across Reality",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_21C.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_2.png",
			"damage": 415.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 2.0,
			"fire_rate": 0.55,
			"bullet_consume": 1,
			"projectile_type": "rift_blade_shot",
			"rift_width": 40.0,         # larghezza della scia taglio
			"rift_persist_time": 2.0,   # secondi che la scia persiste
			"rift_scar_dps": 30.0,      # danno al secondo nella scia
			"sound": "res://Gres/Music/SE/gaea_core_shot.ogg",
			"info": "Fires at 2x speed leaving a VOID SCAR — a 40px wide cut in space that persists 2s dealing 30 DPS.\n\nEnemies crossing the scar take damage and are briefly destabilized (can't dodge).\n\nPASSIVE: Scars from the same shot stack, creating a crosshatch of death.\n\nACTIVE: RIFT CASCADE — fires 5 rift blades in a fan simultaneously, covering the entire screen width."
		}
	},

	# ARMA 12: STORM CALLER — chiama fulmini casuali durante il fuoco continuo
	"STORM CALLER": {
		"legendary": {
			"suffix": "Wrath of Dead Stars",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_21E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_3.png",
			"damage": 465.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.3,
			"fire_rate": 0.25,          # tiro rapidissimo
			"bullet_consume": 1,
			"projectile_type": "storm_caller_shot",
			"lightning_chance": 20,     # % di fulmine per ogni proiettile
			"lightning_damage": 40.0 * Global.player_damage,  # danno fulmine
			"lightning_chain": 3,       # numero di nemici in catena
			"lightning_chain_decay": 0.7, # danno ridotto ad ogni anello
			"sound": "res://Gres/Music/SE/gun_6.ogg",
			"info": "High-speed fire. 20% chance per bullet to call a CHAIN LIGHTNING on the target — chains to 3 additional enemies, each taking 70% of the previous hit.\n\nPASSIVE: Hitting the same enemy 5+ times in 2s triggers THUNDERCLAP — a stun + 3x lightning for free.\n\nACTIVE: STORM APEX — for 6s, every bullet triggers lightning guaranteed.\nEnemies explode on death during Storm Apex."
		}
	},

	# ARMA 13: DIMENSIONAL SWAP — scambia posizione con i nemici
	"DIMENSIONAL SWAP": {
		"legendary": {
			"suffix": "You Are Where I Was",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_21R.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/void_bullet_1.png",
			"damage": 430.0 * Global.player_damage,
			"speed": Global.player_bullet_speed * 1.6,
			"fire_rate": 0.60,
			"bullet_consume": 1,
			"projectile_type": "dimensional_swap_shot",
			"swap_chance": 15,          # % di scambiare posizione con il nemico colpito
			"swap_stun_duration": 1.5,  # nemico è stordito dopo lo swap
			"swap_invincible_time": 0.8, # player immune durante il teletrasporto
			"sound": "res://Gres/Music/SE/gun_9.ogg",
			"info": "15% chance on hit to SWAP POSITIONS with the enemy — you teleport where they were, they appear where you were (stunned for 1.5s). You are invincible for 0.8s post-swap. PASSIVE: After each swap, your next 3 shots deal +100% damage. ACTIVE: MASS SWAP — swaps ALL enemies with random positions on screen simultaneously, confusing formations. Cooldown 20s."
		}
	},
	# ============================================================
	# == PVP WEAPONS (bilanciali, danni e velocità fissi)
	# ============================================================

	# ----- TIER 1 (danno base, alta cadenza) -----
	"PVP_RAZOR": {
		"common": {
			"suffix": "Quickfang",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_1.png",
			"bullet_texture": "res://Gres/Assets/Icons/bullet_1.png",
			"damage": 18.0,
			"speed": 250.0,
			"fire_rate": 0.5,
			"bullet_consume": 1,
			"projectile_type": "line",
			"pvp_tier": 1,
			"info": "High fire rate, low damage. Perfect for aggressive players."
		}
	},
	
	"PVP_BOLT": {
		"common": {
			"suffix": "Thunderstrike",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_2.png",
			"bullet_texture": "res://Gres/Assets/Icons/bullet_2.png",
			"damage": 20.0,
			"speed": 300.0,
			"fire_rate": 0.49,
			"bullet_consume": 1,
			"projectile_type": "line",
			"pvp_tier": 1,
			"info": "Slow but hard-hitting. Rewards accuracy."
		}
	},

	# ----- TIER 2 (danno medio, effetti leggeri) -----
	"PVP_SPLITTER": {
		"rare": {
			"suffix": "Fracture",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_3.png",
			"bullet_texture": "res://Gres/Assets/Icons/bullet_skill_1.png",
			"damage": 25.0,
			"speed": 310.0,
			"fire_rate": 0.48,
			"bullet_consume": 1,
			"projectile_type": "explode_after",
			"pvp_tier": 2,
			"info": "Splits into 4-6 bullets after 400px. Covers more area."
		}
	},
	
	"PVP_BOUNCE": {
		"rare": {
			"suffix": "Ricochet",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_4.png",
			"bullet_texture": "res://Gres/Assets/Icons/bullet_skill_2.png",
			"damage": 28.0,
			"speed": 320.0,
			"fire_rate": 0.47,
			"bullet_consume": 1,
			"projectile_type": "bounce",
			"pvp_tier": 2,
			"info": "Bounces off walls once. Great for tight spaces."
		}
	},

	# ----- TIER 3 (danno alto, un effetto speciale) -----
	"PVP_PIERCE": {
		"epic": {
			"suffix": "Executioner",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_5.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/boomerang_bulletC.png",
			"damage": 30.0,
			"speed": 330.0,
			"fire_rate": 0.46,
			"bullet_consume": 1,
			"projectile_type": "line",
			"pvp_tier": 3,
			"info": "Pierces through the first target hit. Double kills possible."
		}
	},
	
	"PVP_HOMING": {
		"epic": {
			"suffix": "Seeker",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_6.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/boomerang_bulletE.png",
			"damage": 32.0,
			"speed": 340.0,
			"fire_rate": 0.45,
			"bullet_consume": 1,
			"projectile_type": "bounce",
			"pvp_tier": 3,
			"info": "Moderate damage but bullets bounce."
		}
	},

	# ----- TIER 4 (danno molto alto, effetti forti) -----
	"PVP_EXPLODE": {
		"legendary": {
			"suffix": "Nova",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_7.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/boomerang_bulletR.png",
			"damage": 35.0,
			"speed": 350.0,
			"fire_rate": 0.44,
			"bullet_consume": 2,
			"projectile_type": "explode_after",
			"pvp_tier": 4,
			"info": "Delayed explosion on hit. Damages nearby enemies (120px radius)."
		}
	},
	
	"PVP_FREEZE": {
		"legendary": {
			"suffix": "Cryo",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_8.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletC.png",
			"damage": 40.0,
			"speed": 360.0,
			"fire_rate": 0.43,
			"bullet_consume": 1,
			"projectile_type": "line",
			"freeze_chance": 25,
			"freeze_duration": 1.2,
			"pvp_tier": 4,
			"info": "25% chance to freeze the target for 1.2 seconds. Slows movement."
		}
	},

	# ----- TIER 5 (danno altissimo, effetti molto forti, alto consumo) -----
	"PVP_MAGNET": {
		"legendary": {
			"suffix": "Singularity",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_9.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletE.png",
			"damage": 43.0,
			"speed": 370.0,
			"fire_rate": 0.42,
			"bullet_consume": 2,
			"projectile_type": "graviton_pulse_shot",
			"pvp_tier": 5,
			"info": "On hit, pulls the target toward you for 0.8 seconds. Disrupts positioning."
		}
	},
	
	"PVP_SHOTGUN": {
		"legendary": {
			"suffix": "Breaker",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/MPgun_10.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/bouncer_bulletR.png",
			"damage": 50.0,
			"speed": 380.0,
			"fire_rate": 0.41,
			"bullet_consume": 3,
			"projectile_type": "cone_5",
			"pvp_tier": 5,
			"info": "Fires 5 pellets in a spread. Each pellet deals 15 damage. Massive close-range burst."
		}
	},

	# == EXCLUSIVE WEAPON (Offline only, single Steam user) ==
	"OBEY_THE_FIST": {
		"GOD": {
			"suffix": "Divine",
			"texture": "res://Gres/Assets/player/weapons/common/rotated/gun_8E.png",
			"bullet_texture": "res://Gres/Assets/player/bullets/boomerang_bulletR.png",
			"damage": 9999999.0,
			"speed": 9999.0,
			"fire_rate": 0.01,
			"bullet_consume": 0,
			"projectile_type": "fist_of_god",
			"pvp_tier": 6,
			"info": "EXCLUSIVE: Obey the Fist! — Devastating single-shot projectile that obliterates everything in its path. Offline mode only."
		}
	}
} # weapons Dictionary end

# arma iniziale
var current_weapon: Dictionary = weapons["SOLBREAKER"]["common"]

# =========================
# FUNZIONI INVENTARIO
# =========================
func add_to_inventory(weapon_name: String, rarity: String = "common") -> void:
	# evita duplicati
	for w in inventory:
		if w.name == weapon_name and w.rarity == rarity:
			return
	inventory.append({"name": weapon_name, "rarity": rarity})

	# EMETTI IL SEGNALE GLOBALE PER L'INVENTARIO UI
	emit_signal("gun_found", weapon_name, rarity)

func remove_from_inventory(weapon_name: String, rarity: String = "common") -> void:
	for i in range(inventory.size()):
		var w = inventory[i]
		if w.name == weapon_name and w.rarity == rarity:
			inventory.remove_at(i)
			return

func clear_inventory() -> void:
	inventory.clear()

func get_inventory() -> Array:
	return inventory.duplicate()

# =========================
# GET WEAPON FUNCTION
# =========================
func get_weapon(name: String, rarity: String = "common") -> Dictionary:
	if weapons.has(name) and weapons[name].has(rarity):
		return weapons[name][rarity]
	# fallback: case-insensitive
	for k in weapons.keys():
		if k.to_lower() == name.to_lower():
			if weapons[k].has(rarity):
				return weapons[k][rarity]
			return weapons[k].values()[0] # prima arma disponibile
	return weapons["SOLBREAKER"]["common"]
