// Nurses, they create webs and eggs.
// They're fragile but their attacks can cause horrifying consequences.
/mob/living/simple_mob/animal/giant_spider/nurse
	desc = "Furry and beige, it makes you shudder to look at it. This one has brilliant green eyes."
	icon_state = "nurse"
	icon_living = "nurse"
	icon_dead = "nurse_dead"

	maxHealth = 40
	health = 40

	movement_cooldown = 5	// A bit faster so that they can inject the eggs easier.

	melee_damage_lower = 5	// Doesn't do a lot of damage, since the goal is to make more spiders with egg attacks.
	melee_damage_upper = 10
	poison_per_bite = 5
	poison_type = "stoxin"

	player_msg = "You can spin webs on an adjacent tile, or cocoon an object by clicking on it.<br>\
	You can also cocoon a dying or dead entity by clicking on them, and you will gain charges for egg-laying.<br>\
	To lay eggs, click a nearby tile. Laying eggs will deplete a charge."
	ai_holder_type = /datum/ai_holder/simple_mob/melee/nurse_spider

	var/fed = 0 // Counter for how many egg laying 'charges' the spider has.
	var/egg_inject_chance = 25 // One in four chance to get eggs.
	var/egg_type = /obj/effect/spider/eggcluster/small
	var/web_type = /obj/effect/spider/stickyweb/dark


/mob/living/simple_mob/animal/giant_spider/nurse/inject_poison(mob/living/L, target_zone)
	..() // Inject the stoxin here.
	if(ishuman(L) && prob(egg_inject_chance))
		var/mob/living/carbon/human/H = L
		var/obj/item/organ/external/O = H.get_organ(target_zone)
		if(O)
			var/eggcount = 0
			for(var/obj/effect/spider/eggcluster/E in O.implants)
				eggcount++
			if(!eggcount)
				var/eggs = new egg_type(O, src)
				O.implants += eggs
				to_chat(H, span("critical", "\The [src] injects something into your [O.name]!") ) // Oh god its laying eggs in me!

// Webs target in a web if able to.
/mob/living/simple_mob/animal/giant_spider/nurse/attack_target(atom/A)
	if(isturf(A))
		if(fed)
			return lay_eggs(A)
		return web_tile(A)

	if(isliving(A))
		var/mob/living/L = A
		if(!L.stat)
			return ..()

	if(!istype(A, /atom/movable))
		return
	var/atom/movable/AM = A

	if(AM.anchored)
		return ..()

	return spin_cocoon(AM)

/mob/living/simple_mob/animal/giant_spider/nurse/proc/spin_cocoon(atom/movable/AM)
	if(!istype(AM))
		return FALSE // We can't cocoon walls sadly.
	visible_message(span("notice", "\The [src] begins to secrete a sticky substance around \the [AM].") )

	// Get our AI to stay still.
	set_AI_busy(TRUE)

	if(!do_mob(src, AM, 5 SECONDS))
		set_AI_busy(FALSE)
		to_chat(src, span("warning", "You need to stay still to spin a web around \the [AM]."))
		return FALSE

	set_AI_busy(FALSE)

	if(!AM) // Make sure it didn't get deleted for whatever reason.
		to_chat(src, span("warning", "Whatever you were spinning a web for, its no longer there..."))
		return FALSE

	if(!isturf(AM.loc))
		to_chat(src, span("warning", "You can't spin \the [AM] in a web while it is inside \the [AM.loc]."))
		return FALSE

	if(!Adjacent(AM))
		to_chat(src, span("warning", "You need to be next to \the [AM] to spin it into a web."))
		return FALSE

	// Finally done with the checks.
	var/obj/effect/spider/cocoon/C = new(AM.loc)
	var/large_cocoon = FALSE
	for(var/mob/living/L in C.loc)
		if(istype(L, /mob/living/simple_mob/animal/giant_spider)) // Cannibalism is bad.
			continue
		fed++
		visible_message(span("warning","\The [src] sticks a proboscis into \the [L], and sucks a viscous substance out."))
		to_chat(src, span("notice", "You've fed upon \the [L], and can now lay [fed] cluster\s of eggs."))
		L.forceMove(C)
		large_cocoon = TRUE
		break

	// This part's pretty stupid.
	for(var/obj/O in C.loc)
		if(!O.anchored)
			O.forceMove(C)

	// Todo: Put this code on the cocoon object itself?
	if(large_cocoon)
		C.icon_state = pick("cocoon_large1","cocoon_large2","cocoon_large3")

	return TRUE

/mob/living/simple_mob/animal/giant_spider/nurse/handle_special()
	set waitfor = FALSE
	if(get_AI_stance() == STANCE_IDLE && !is_AI_busy() && isturf(loc))
		if(fed)
			lay_eggs(loc)
		else
			web_tile(loc)

/mob/living/simple_mob/animal/giant_spider/nurse/proc/web_tile(turf/T)
	if(!istype(T))
		return FALSE

	var/obj/effect/spider/stickyweb/W = locate() in T
	if(W)
		return FALSE // Already got webs here.

	visible_message(span("notice", "\The [src] begins to secrete a sticky substance.") )
	// Get our AI to stay still.
	set_AI_busy(TRUE)

	if(!do_mob(src, T, 5 SECONDS))
		set_AI_busy(FALSE)
		to_chat(src, span("warning", "You need to stay still to spin a web on \the [T]."))
		return FALSE

	W = locate() in T
	if(W)
		return FALSE // Spamclick protection.

	set_AI_busy(FALSE)
	new web_type(T)
	return TRUE


/mob/living/simple_mob/animal/giant_spider/nurse/proc/lay_eggs(turf/T)
	if(!istype(T))
		return FALSE

	if(!fed)
		return FALSE

	var/obj/effect/spider/eggcluster/E = locate() in T
	if(E)
		return FALSE // Already got eggs here.

	visible_message(span("notice", "\The [src] begins to lay a cluster of eggs.") )
	// Get our AI to stay still.
	set_AI_busy(TRUE)

	if(!do_mob(src, T, 5 SECONDS))
		set_AI_busy(FALSE)
		to_chat(src, span("warning", "You need to stay still to lay eggs on \the [T]."))
		return FALSE

	E = locate() in T
	if(E)
		return FALSE // Spamclick protection.

	set_AI_busy(FALSE)
	new egg_type(T)
	fed--
	return TRUE


// Variant that 'blocks' light (by being a negative light source).
// This is done to make webbed rooms scary and allow for spiders on the other side of webs to see prey.
/obj/effect/spider/stickyweb/dark
	name = "dense web"
	desc = "It's sticky, and blocks a lot of light."
	light_color = "#FFFFFF"
	light_range = 2
	light_power = -3
