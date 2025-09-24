I'm going to admit. I don't feel proud of Heist. The mod has been heavily altered due to criticism, and as much as I tried to please both collectathon and PvP enjoyers, nothing I did cut it, atleast not without massively reworking the mod. This update aims to make my mod truly mine, while improving some aspects of other things, including movesets.

So, it may look like I'm making up words, but I genuinely think calling this a "mechanical refresh" is the best way to go about it. It's like turning off Fang's Heist and turning it on again. The difference is night and day, and I do believe that these changes will make the mod more straight-forward, quicker, and more fun to play. Of course, some people won't prefer this, but it'll be too hard to try and keep going with the old gameplay style I wanted to go for. It felt like there was too much to it. I mean, c'mon now. I had to try and balance collect-a-thon gameplay with fighting, I had to make sure movesets were just right, this, that, hell... I remember I was told to add weapons to PvP, which is something I wanted to do, but felt like it would ruin the mode in it's entirety. This update is just me clogging my ears and turning it MINE, not listening to anyone else. And I hope it's enjoyable to the people I'm trying to attract. If you were turned off by the first release, I'm sorry. Please keep in mind that I am still actively developing the mod, and I won't stop untill I get something acceptable. Enough said, here's the changelog.

• Saxashitter:
	• The Sign now gives $5000 instead of $600, basically guaranteeing a win
	• Treasures now give $5000 / Amount of treasures inside the map, so that means treasures act as fragments to a second sign.
	• The profit variable when you define a Carriable can now accept functions for it's profit gain.
	• Players now have a health percentage, which displays on top of their heads if you are close to them.
	• PVP now works similar to Smash. If you hit a wall when you are over 100%, you will die.
	• Air-dodge no longer locks your inputs if you're not flashing. I should've made this change pre-release.
	• FangsHeist.DrawString now caches font widths, making the mod only run width-getting functions once per string. This optimizes the mod a ton.
	• Damage code in Hooks/Player/Scripts/PVP.lua cleaned up. PlayerHit now runs after everything, allowing you to modify what happens after a player gets hit.
	• Added new hooks: "PlayerCanClash", "PlayerAttackRadius", "PlayerAttackHeight", "PlayerAttackDamage"
	• Because of this, Amy's hitbox has been reduced heavily.
	• Co-op has been added. Cooperate with the server to reach quotas before time runs out!
	• Sonic's Drop Dash has been changed to a modified Thok.
	• Tails' Double Jump has been changed to Flight.
	• Knuckles no longer thoks during Flight.
	• Amy now only does her double jump for a few tics.
	• "2 Teams Left" mechanic added. Aims to end games faster and force a confrontation between the 2 teams.
	• Added more HUD triggers instead of relying on the player's current state (doRound2HUD function)
	• Added hit-lag for more responsive combat.
	• Changed Marvellous Queen and Wario Land portal to rings reminiscent to Sonic Adventure 2.
	• Goal Ring now opens after a certain amount of time.
• Zeko
	• Remade a bunch of THZ2, making the map more polished.
• El3ctr0h3ll
	• Added Aerial Garden Zone
• GLide KS
	• Made Round 2 and Goal Ring sprites.
I want to inform you that something like this will not happen again. This will be the only time I close my ears to everyone, and I will take proper criticism from here on out.