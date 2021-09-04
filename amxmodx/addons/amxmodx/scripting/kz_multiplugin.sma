/**************************************************************************************************
For use with Climbing Maps
http://www.kreedz.com/
And Other Climbing Maps

List Maps & Configurations in climbing.ini


**** CVARS (FEATURES) ****
kz_autoheal    = AutoHeal
kz_autospawn   = AutoSpawn
kz_bunnyjump   = 1 = No slowdown after jumping | 2 = Just hold down jump to bunny hop
kz_godmode     = AutoGodmode
kz_semiclip    = AutoSemiClip
kz_scout       = AutoScout
kz_nightvision = Free NVG
kz_nightmode   = Nightmode
kz_checkpoints = Checkpoints 
kz_timer       = IndividualTimer
kz_top15       = Top15 (BETA)

**** CVARS (CHECKPOINT SYSTEM) ****
kz_checkprice		 = Price of a checkpoint
kz_checkpointdist = Distance from other people you can spawn
kz_checkeffects	 = Some cool teleport effects
kz_limitedcp			= Limit each checkpoint to one use
kz_startmoney		 = Instead of mp_startmoney

**** CVARS (OTHER) ****
kz_grabforce = Grabforce for JediGrab

**** ADMIN COMMANDS ****

ADMIN_LEVEL_A (flag="m")
Setting Noclip			= amx_noclip <authid, nick, @team, @all or #userid> <on/off>
Setting Godmode			= amx_godmode <authid, nick, @team, @all or #userid> <on/off>
Setting Semiclip		= amx_semiclip <authid, nick, @team, @all or #userid> <on/off>
Setting Glow				= amx_glow <authid, nick, @team, @all or #userid> <red> <green> <blue> <alpha>
Setting Origin			= amx_teleport <authid, nick or #userid> <authid, nick or #userid>
Setting Gravity			= amx_gravity <authid, nick, @team, @all or #userid> <Gravity>
Granting Hook/Rope	= amx_granthook <authid, nick, @team, @all or #userid> <on/off>

ADMIN_LEVEL_B (flag="n")
Giving Longjump			= amx_longjump <authid, nick, @team, @all or #userid>
Giving Scout				= amx_scout <authid, nick, @team, @all or #userid>
Giving Money				= amx_money <authid, nick, @team, @all or #userid> <Money>

ADMIN_LEVEL_C (flag="o")
Set Checkpoint			= amx_checkpoint <authid, nick or #userid>
Rem Checkpoint			= amx_remcheckpoint <authid, nick or #userid>

ADMIN_LEVEL_D (flag="p")
Jedi Force Grab by Spacedude (slightly modified)
Grabbing a person		= +grab
Releasing grabbed		= -grab
Toggle Command			= grab_toggle

ADMIN_LEVEL_E (flag="q") || Granted by admin
Ninja Rope by Spacedude (slightly modified) & Hook thingy
Attaching Rope			= +rope
Deattaching Rope		= -rope
Attaching Hook			= +hook
Deattaching Hook		= -hook

**** USER COMMANDS ****

checkpoint					= Use Checkpoint
	/checkpoint
gocheck							= Goto Checkpoint
	/gocheck
lastcheck						= Goto Checkpoint before last (used when stuck)
	/stuck
	/unstuck
	/destuckme

**************************************************************************************************/
#define USING_AMX 0 // 1 = Using AMX \ 0 = Useing AMXX
// #define USP_SCOUT_KILL 1 //Uncomment to activate the automatic removal of usps and scouts. WARNING: MAY CAUSE CRASH

#if USING_AMX
	#include <amxmod>
	#include <amxmisc>
	#include <VexdUM>
	#include <fun>
#else
	#include <amxmodx>
	#include <amxmisc>
	#include <cstrike>
	#include <fun>
	#include <engine>
#endif

#define TE_BEAMENTPOINT 1
#define TE_KILLBEAM 99
#define DELTA_T 0.1				// seconds
#define BEAMLIFE 100			// deciseconds
#define MOVEACCELERATION 150	// units per second^2
#define REELSPEED 300			// units per second

/* Stuff */
new NVGrun[33]
new Cvar[4] // mp_friendlyfire, mp_autoteambalance, mp_teamlimit
new gMoney[33]
new gJoined[33]
new gStartMoney
new gConfigFile[128]
new gScorePath[128]

/* Checkpoint Stuff */
new bool:gCheckpoint[33]
new gCheckpointPos[33][3]
new gLastCheckpointPos[33][3]

/* Hook Stuff */
new gHookLocation[33][3]
new gHookLenght[33]
new bool:gIsHooked[33]
new gAllowedHook[33]
new Float:gBeamIsCreated[33]
new global_gravity
new beam

/* Timer Stuff */
new bool:gHasTimer[33],bool:gHasStoppedTimer[33]
new gSecs[33], gMins[33], gHuns[33], gChecks[33]

/* Top15 Stuff */
new gAuthScore[15][33]
new gNameScore[15][33]
new gMinsScore[15]
new gSecsScore[15]
new gHunsScore[15]
new gChecksScore[15]

/************************************************************************************************************************/
public plugin_init() //Called on plugin start
{
	// Plugin Info
	register_plugin("KZ Multiplugin","2.0","AssKicR")
	//CVARS
	register_cvar("kz_autoheal","0")
	register_cvar("kz_autospawn","0")
	register_cvar("kz_checkpoints","0")
	register_cvar("kz_checkprice","500")
	register_cvar("kz_checkpointdist","50")
	register_cvar("kz_checkeffects","0")
	register_cvar("kz_scout","0")
	register_cvar("kz_limitedcp","0")
	register_cvar("kz_nightvision","0")
	register_cvar("kz_grabforce","8")
	register_cvar("kz_godmode","0")
	register_cvar("kz_semiclip","0")
	register_cvar("kz_nightmode","0")
	register_cvar("kz_startmoney","16000")
	register_cvar("kz_timer","1")
	register_cvar("kz_bunnyjump","0")
	register_cvar("kz_top15", "0" )
	#if USING_AMX
	format(gConfigFile,sizeof(gConfigFile),"addons/amx/config")
	format(gScorePath,sizeof(gScorePath),"addons/amx/kz_top15/")
	#else
	get_configsdir(gConfigFile,sizeof(gConfigFile))
	format(gScorePath,sizeof(gScorePath),"addons/amxmodx/kz_top15/")
	#endif
	format (gConfigFile,sizeof(gConfigFile),"%s/climbing.ini",gConfigFile)

	if(ClimbMap()) {
		gStartMoney=get_cvar_num("kz_startmoney")
		//EVENTS
		register_event("StatusValue","spec_event","be","1=2")
		register_event("DeathMsg", "DeathMsg", "a")
		register_event("Damage", "Damage", "b", "2!0")
		register_event("ResetHUD", "ResetHUD", "b")
		#if defined USP_SCOUT_KILL {
			register_clcmd("drop", "gimmetime")
		#endif
		register_event("TextMsg","RestartRound","a","2&#Game_C","2&#Game_w")
		//CLIENT CMDS
		register_clcmd("nightvision","NVGToggle")
		
		register_clcmd("checkpoint","Checkpoint")
		register_clcmd("say /checkpoint","Checkpoint")

		register_clcmd("gocheck","GoCheckpoint")
		register_clcmd("say /gocheck","GoCheckpoint")
		
		register_clcmd("lastcheck","LastCheckpoint")
		register_clcmd("say /stuck","LastCheckpoint")
		register_clcmd("say /unstuck","LastCheckpoint")
		register_clcmd("say /destuckme","LastCheckpoint")

		register_clcmd("say /top15", "show_top15")

		register_clcmd("radio1","blocked")
		register_clcmd("radio2","blocked")
		register_clcmd("radio3","blocked")
		//ADMIN CMDS
		register_clcmd("+rope", "hook_on",ADMIN_LEVEL_E)
		register_clcmd("-rope", "hook_off",ADMIN_LEVEL_E)
		register_clcmd("+hook", "hook_on",ADMIN_LEVEL_E)
		register_clcmd("-hook", "hook_off",ADMIN_LEVEL_E)

		register_clcmd("grab_toggle","grab_toggle",ADMIN_LEVEL_D,"press once to grab and again to release")
		register_clcmd("+grab","grab",ADMIN_LEVEL_D,"bind a key to +grab")
		register_clcmd("-grab","release",ADMIN_LEVEL_D)

		register_concmd("amx_checkpoint","AdminSetCheck",ADMIN_LEVEL_C,"<authid, nick or #userid>")
		register_concmd("amx_remcheckpoint","AdminRemCheck",ADMIN_LEVEL_C,"<authid, nick or #userid>")

		register_concmd("amx_longjump","AdminLongjump",ADMIN_LEVEL_B,"<authid, nick, @team, @all or #userid>") 
		register_concmd("amx_scout","AdminScout",ADMIN_LEVEL_B,"<authid, nick, @team, @all or #userid>")
		register_concmd("amx_money","AdminSetMoney",ADMIN_LEVEL_B,"<authid, nick, @team, @all or #userid> <Money>")
		register_concmd("amx_gravity","AdminGravity",ADMIN_LEVEL_B,"<authid, nick, @team, @all or #userid> <Gravity>")

		register_concmd("amx_noclip","AdminNoclip",ADMIN_LEVEL_A,"<authid, nick, @team, @all or #userid> <on/off>")
		register_concmd("amx_godmode","AdminGodMode",ADMIN_LEVEL_A,"<authid, nick, @team, @all or #userid> <on/off>")
		register_concmd("amx_semiclip","AdminSemiClip",ADMIN_LEVEL_A,"<authid, nick, @team, @all or #userid> <on/off>")
		register_concmd("amx_glow","AdminGlow",ADMIN_LEVEL_A,"<authid, nick, @team or #userid> <red> <green> <blue> <alpha>")	
		register_concmd("amx_teleport","AdminTele",ADMIN_LEVEL_A,"<authid, nick or #userid> [x] [y] [z]")
		register_concmd("amx_granthook","AdminGrantHook",ADMIN_LEVEL_A,"<authid, nick, @team, @all or #userid> <on/off>")

		//CVAR ENFORCING
		Cvar[0]=get_cvar_num("mp_friendlyfire")
		Cvar[1]=get_cvar_num("mp_autoteambalance")
		Cvar[2]=get_cvar_num("mp_limitteams")
		Cvar[3]=get_cvar_num("mp_flashlight")
		set_cvar_num("mp_friendlyfire",0)
		set_cvar_num("mp_autoteambalance",0)
		set_cvar_num("mp_limitteams",99)
		set_cvar_num("mp_flashlight",1)

		set_task(0.1,"gTimerTask",0,"",0,"b")

		read_top15()
	}
}
/************************************************************************************************************************/
public plugin_end() { //Called on plugin end
	if(ClimbMap()) {
		set_cvar_num("mp_friendlyfire",Cvar[0])
		set_cvar_num("mp_autoteambalance",Cvar[1])
		set_cvar_num("mp_teamlimit",Cvar[2])
		set_cvar_num("mp_flashlight",Cvar[3])
	}
}
/************************************************************************************************************************/
public plugin_precache()
{
	precache_model("models/w_longjump.mdl")		//longjump
	precache_model("models/w_longjumpt.mdl")	//---"---
	precache_sound("items/nvg_on.wav") 
	precache_sound("items/nvg_off.wav")

	beam = precache_model("sprites/zbeam4.spr")
	precache_sound("weapons/xbow_hit2.wav")
}
/*************************************************************************************************************************/
/************************************************** USP/SCOUT REMOVE *****************************************************/
/*************************************************************************************************************************/
public gimmetime(id) {
	set_task(0.2, "killevilusp", id+50, "", 0)
}

public killevilusp(Taskid)
{
	new model[32]
	new oid, tEnt, wEnt
	
	tEnt = find_ent_by_class(-1, "weaponbox")
	while (tEnt > 0) {
		entity_get_string(tEnt, EV_SZ_model, model, 32)
		if (equali(model,"models/w_usp.mdl")) {
			oid = entity_get_edict(tEnt, EV_ENT_owner)
			if (oid > 0 && oid < 33) {
				remove_entity(tEnt)
				wEnt = find_ent_by_class(-1, "weapon_usp")
				while (wEnt > -1) {
					oid = entity_get_edict(wEnt, EV_ENT_owner)
					if (oid == tEnt) {
						remove_entity(wEnt)
					}
					wEnt = find_ent_by_class(wEnt, "weapon_usp")
				}
			}
		}
		tEnt = find_ent_by_class(tEnt, "weaponbox")
	}	
	set_task(0.2, "killevilscout", Taskid, "", 0)
}

public killevilscout(Taskid)
{
	new model[32]
	new oid, tEnt, wEnt
	
	tEnt = find_ent_by_class(-1, "weaponbox")
	while (tEnt > 0) {
		entity_get_string(tEnt, EV_SZ_model, model, 32)
		if (equali(model,"models/w_scout.mdl")) {
			oid = entity_get_edict(tEnt, EV_ENT_owner)
			if (oid > 0 && oid < 33) {
				remove_entity(tEnt)
				wEnt = find_ent_by_class(-1, "weapon_scout")
				while (wEnt > -1) {
					oid = entity_get_edict(wEnt, EV_ENT_owner)
					if (oid == tEnt) {
						remove_entity(wEnt)
					}
					wEnt = find_ent_by_class(wEnt, "weapon_scout")
				}
			}
		}
		tEnt = find_ent_by_class(tEnt, "weaponbox")
	}	
}
/*************************************************************************************************************************/
/**************************************************** HOOKED EVENTS ******************************************************/
/*************************************************************************************************************************/
public DeathMsg() 
{ 
	new id = read_data(2) 
	// User died, do they need to respawn???
	if(get_cvar_num("kz_autospawn") == 0) {
		// No Need, remove his timer
		if (gHasTimer[id]) gHasTimer[id]=false
		return PLUGIN_CONTINUE 
	}
	// Yep, needs to respawn.	Postpone with set_task for 0.5...	
	NVGcmd(id,0)
	set_task(0.5,"respawn",id+123)
	#if defined USP_SCOUT_KILL {
		gimmetime(id)
	#endif
	return PLUGIN_CONTINUE 
} 
/************************************************************************************************************************/
public respawn(TaskID) 
{ 
	//Respawn user...
	new id = TaskID-123
	if(get_user_team(id) != 2 || is_user_alive(id)) return PLUGIN_CONTINUE 
	//Show a message to user that he is respawning
	client_print(id,print_chat,"[KZ] Respawning!!!") 
	#if USING_AMX
		user_spawn(id)
	#else
		spawn(id)
	#endif
	return PLUGIN_CONTINUE 
} 
/************************************************************************************************************************/
public ResetHUD(id) {
	//Check if Checkpoints are on...
	if (get_cvar_num("kz_checkpoints") != 0) {
		//Check if user has a Checkpoint
		if (gCheckpoint[id]) {
			//Yep he has one... Move him to it...
			if (CheckCheckpoint(id)) move_to_check(id)
			cs_set_user_money(id,0)
			//Check if limited Checkpointuse is on
			if (get_cvar_num("kz_limitedcp") != 0) {
				//Yep.. It is on... Delete Checkpoint
				gCheckpoint[id]=false
				client_print(id,print_chat,"[KZ] Checkpoint Used...") 
			}
		}else{
			if (gHasTimer[id]) ResetTimer(id,1)
		}
	}else{
		if (gHasTimer[id]) ResetTimer(id,1)
	}
	//Chech if he just joined
	if (gJoined[id]) {
		get_user_origin(id,gLastCheckpointPos[id])
		gJoined[id]=false
		if (get_cvar_num("kz_checkpoints")==1) {
			client_print(id,print_chat,"* ^"KZ Multiplugin^" is enabled")
			client_print(id,print_chat,"* Use checkpoints by typing ^"checkpoint^" & ^"gocheck^" in console")
			client_print(id,print_chat,"* if you get stuck say ^"/stuck^" to jump back to last checkpoint")
		}else{
			client_print(id,print_chat,"* ^"KZ Multiplugin^" is disabled")
		}
	}

	//Check if he gets godmode
	if (get_cvar_num("kz_godmode") != 0) {
		//Yep, it's on... Give it too him...
		set_user_godmode(id,1)
	}
	//Check if auto scout give is on...
	if (get_cvar_num("kz_scout") != 0) {
		//Yep, it's on... Give it too him...
		GiveScout(id)
	}
	//Check if he gets semiclip...
	if (get_cvar_num("kz_semiclip") != 0) {
		//Yep, it's on... Give it too him...
		entity_set_int(id, EV_INT_solid, SOLID_TRIGGER)
	}else{
		//Nope, it's off... Make sure he has clip
		entity_set_int(id, EV_INT_solid, SOLID_BBOX)
	}

	//Check if nightmode is on...
	if (get_cvar_num("kz_nightmode") != 0) {
		//Yep, it's on...
		set_lights("a")
	}else{
		//Nope, it's off...
		set_lights("n")
	}
	//Check if he is hooked to something
	if (gIsHooked[id]) RopeRelease(id)

	cs_set_user_money(id,gMoney[id])
}
/************************************************************************************************************************/
public Damage() {
	if(get_cvar_num("kz_autoheal") == 0) return PLUGIN_CONTINUE 

	new victim = read_data(0)
	set_user_health(victim, 100)

	return PLUGIN_CONTINUE
} 
/************************************************************************************************************************/
public RestartRound() {
	for (new id=1; id<33; id++) {
		if (is_user_connected(id)) {
			gCheckpoint[id]=false
			if (gHasTimer[id]) client_print(id,print_chat,"[KZ] Timer Reset...")
			ResetTimer(id,0)
		}
	}
}
/************************************************************************************************************************/
public Checkpoint(id) {
	if (get_cvar_num("kz_checkpoints") != 1) {
		client_print(id,print_console,"[KZ] Sry Server has diabled this command")
		client_print(id,print_chat,"[KZ] Sry Server has diabled this command")
		return PLUGIN_CONTINUE
	}
	if (cs_get_user_money(id)<get_cvar_num("kz_checkprice")) {
		client_print(id,print_console,"[KZ] Sry, but a checkpoint costs %i$",get_cvar_num("kz_checkprice"))
		client_print(id,print_chat,"[KZ] Sry, but a checkpoint costs %i$",get_cvar_num("kz_checkprice"))
		return PLUGIN_CONTINUE
	}
	if (get_user_button(id)&IN_DUCK) {
		client_print(id,print_console,"[KZ] You cannot place a checkpoint while ducking")
		client_print(id,print_chat,"[KZ] You cannot place a checkpoint while ducking")
		return PLUGIN_CONTINUE	
	}

	client_print(id,print_console,"[KZ] Saving Position...")
	client_print(id,print_chat,"[KZ] Saving Position...") 
	cs_set_user_money(id,cs_get_user_money(id)-get_cvar_num("kz_checkprice"))
	gMoney[id]=cs_get_user_money(id)
	if (gCheckpoint[id]) {
		gLastCheckpointPos[id][0]=gCheckpointPos[id][0]
		gLastCheckpointPos[id][1]=gCheckpointPos[id][1]
		gLastCheckpointPos[id][2]=gCheckpointPos[id][2]
	}
	get_user_origin(id,gCheckpointPos[id])
	gCheckpointPos[id][2] += 5
	gCheckpoint[id]=true
	gChecks[id] += 1
	return PLUGIN_HANDLED
}

public LastCheckpoint(id) {
	if (get_cvar_num("kz_checkpoints") != 1) {
		client_print(id,print_console,"[KZ] Sry Server has diabled this command")
		client_print(id,print_chat,"[KZ] Sry Server has diabled this command")
		return PLUGIN_CONTINUE
	}
	if (!gCheckpoint[id]) {
		client_print(id,print_console,"[KZ] You don't have a checkpoint to revert to")
		client_print(id,print_chat,"[KZ] You don't have a checkpoint to revert to")
		return PLUGIN_CONTINUE
	}
	client_print(id,print_console,"[KZ] Reverting to last Checkpoint")
	client_print(id,print_chat,"[KZ] Reverting to last Checkpoint")

	gCheckpointPos[id][0]=gLastCheckpointPos[id][0]
	gCheckpointPos[id][1]=gLastCheckpointPos[id][1]
	gCheckpointPos[id][2]=gLastCheckpointPos[id][2]
	gCheckpoint[id]=true

	if (CheckCheckpoint(id)) move_to_check(id)

	return PLUGIN_HANDLED
}

public GoCheckpoint(id) {
	if (get_cvar_num("kz_checkpoints") != 1) {
		client_print(id,print_console,"[KZ] Sry Server has diabled this command")
		client_print(id,print_chat,"[KZ] Sry Server has diabled this command")
		return PLUGIN_CONTINUE
	}
	if (!gCheckpoint[id]) {
		client_print(id,print_console,"[KZ] You don't have a checkpoint")
		client_print(id,print_chat,"[KZ] You don't have a checkpoint")
		return PLUGIN_CONTINUE
	}
	if (CheckCheckpoint(id)) move_to_check(id)
	return PLUGIN_HANDLED
}

public CheckCheckpoint(id) {
	// Check if they can respawn
	new origin[33][3]
	new dist = 9999
	for(new a = 0; a < 33; a++) {
		if (is_user_connected(a)) {
			get_user_origin(a,origin[a])
			dist = get_distance(origin[a],gCheckpointPos[id])
			if (dist<=get_cvar_num("kz_checkpointdist")) {
				client_print(id,print_console,"[KZ] You will respawn too close to another person.. plz wait...")
				client_print(id,print_chat,"[KZ] You will respawn too close to another person.. plz wait...")
				return false			
			}
		}
	}
	return true
}

public blocked(id) {
	return PLUGIN_HANDLED
}
/*************************************************************************************************************************/
/**************************************************** STOCK COMMANDS *****************************************************/
/*************************************************************************************************************************/
stock ClimbMap()
{
	if(file_exists(gConfigFile) == 1) { 
		new line, stxtsize 
		new data[192] 
		new cMap[32]
		get_mapname(cMap, 31)
		new MapName[32],aHeal[6]=0,aSpawn[6]=0,aBunny[6]=0,aGodmode[6]=0,aScout[6]=0,aSemiClip[6]=0,aNVG[6]=0,nMode[6]=0,cTimer[6]=0,cTopS[6]=0,cPoints[6]=0,cPrice[6]=0,cDist[6]=0,cEffects[6]=0,cLimited[6]=0
		while((line=read_file(gConfigFile,line,data,191,stxtsize))!=0)
		{ 
			if ( data[0] == ';' ) continue
			parse(data,MapName,31,aHeal,5,aSpawn,5,aBunny,5,aGodmode,5,aScout,5,aSemiClip,5,aNVG,5,nMode,5,cTimer,5,cTopS,5,cPoints,5,cPrice,5,cDist,5,cEffects,5,cLimited,5)
			if (equal(MapName,cMap)) {
				set_cvar_num("kz_autoheal",str_to_num(aHeal))
				set_cvar_num("kz_autospawn",str_to_num(aSpawn))
				set_cvar_num("kz_bunnyjump",str_to_num(aBunny))
				set_cvar_num("kz_godmode",str_to_num(aGodmode))
				set_cvar_num("kz_scout",str_to_num(aScout))
				set_cvar_num("kz_semiclip",str_to_num(aSemiClip))
				set_cvar_num("kz_nightvision",str_to_num(aNVG))
				set_cvar_num("kz_nightmode",str_to_num(nMode))
				set_cvar_num("kz_timer",str_to_num(cTimer))
				set_cvar_num("kz_top15",str_to_num(cTopS))
				set_cvar_num("kz_checkpoints",str_to_num(cPoints))
				set_cvar_num("kz_checkprice",str_to_num(cPrice))
				set_cvar_num("kz_checkpointdist",str_to_num(cDist))
				set_cvar_num("kz_checkeffects",str_to_num(cEffects))
				set_cvar_num("kz_limitedcp",str_to_num(cLimited))
				return true
			}
		}
		return false
	}else{
		server_cmd("echo [KZ] Error!!! Failed To Load climbing.ini!!!")
		log_message("[KZ] Error!!! Failed To Load climbing.ini!!!")
		return false
	}
	return false
}

stock kz_velocity_set(id,vel[3]) {
	//Set Their Velocity to 0 so that they they fall straight down from
	new Float:Ivel[3]
	Ivel[0]=float(vel[0])
	Ivel[1]=float(vel[1])
	Ivel[2]=float(vel[2])
	entity_set_vector(id, EV_VEC_velocity, Ivel)
}

stock FormatTime(iMins,iSecs,iHuns,sMins[],sSecs[],sHuns[]) {
	if (iHuns==0) {
		format(sHuns,2,"00",iHuns)
	} else {
		format(sHuns,2,"%d",iHuns)
	}
	if (iSecs<10) {
		format(sSecs,2,"0%d",iSecs)
	} else {
		format(sSecs,2,"%d",iSecs)
	}
	if (iMins<10) {
		format(sMins,2,"0%d",iMins)
	} else {
		format(sMins,2,"%d",iMins)
	}
	return 1
}

stock kz_velocity_get(id,vel[3]) {
	//Set Their Velocity to 0 so that they they fall straight down from
	new Float:Ivel[3]

	entity_get_vector(id, EV_VEC_velocity, Ivel)
	vel[0]=floatround(Ivel[0])
	vel[1]=floatround(Ivel[1])
	vel[2]=floatround(Ivel[2])
}

stock move_to_check(id) {
	new vel[3]={0,0,0}
	kz_velocity_set(id,vel)
	//Check if Effects are enabled
	if (get_cvar_num("kz_checkeffects")==1) {
		//Yep They Are
		new CurOrig[3]
		get_user_origin(id,CurOrig)
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte(11) 
		write_coord(CurOrig[0]) 
		write_coord(CurOrig[1]) 
		write_coord(CurOrig[2]) 
		message_end() 
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte(11) 
		write_coord(gCheckpointPos[id][0]) 
		write_coord(gCheckpointPos[id][1]) 
		write_coord(gCheckpointPos[id][2]) 
		message_end() 
	}
	//Move To Checkpoint
	set_user_origin(id,gCheckpointPos[id])
}

stock GiveScout(id)
{
	// Check If They Already Have Scout
	new iwpn, iwpns[32] 
	new ownWeapon[32]
	new bool:HasScout
	get_user_weapons(id, iwpns,iwpn) 
	for(new a = 0; a < iwpn; a++) 
	{ 
		get_weaponname(iwpns[a],ownWeapon,31)
		if ( equali(ownWeapon, "weapon_scout") ) HasScout=true
	}
	// They Don't Got It
	if (!HasScout) give_item(id,"weapon_scout")
}

stock CheatDetect(id,cheat[]) {
	if (gHasTimer[id]) {
		client_print(id,print_chat,"[KZ] %s Detected.. Timer Terminated",cheat)
		ResetTimer(id,0)
	}
}
/************************************************************************************************************************/
/**************************************************** ADMIN COMMANDS ****************************************************/
/************************************************************************************************************************/
public AdminLongjump(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,1) ) 
		return PLUGIN_HANDLED 

	new arg1[32]
	read_argv(1,arg1,31) 

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++)
		{
			give_item(plist[i],"item_longjump")
			CheatDetect(plist[i],"Longjump")
		}

		console_print(id,"[KZ] Gave all players longjump") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
		{
			give_item(plist[i],"item_longjump")
			CheatDetect(plist[i],"Longjump")

		}
		console_print(id,"[KZ] Gave all %ss longjump",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		give_item(player,"item_longjump") 
		CheatDetect(player,"Longjump")

		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Gave ^"%s^" longjump",pName) 
	} 

	return PLUGIN_HANDLED 
} 

public AdminGrantHook(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,1) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new onoff = str_to_num(arg2)

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) { 
			gAllowedHook[plist[i]]=onoff
			if (gIsHooked[plist[i]]==true && onoff==0)
			{
				RopeRelease(plist[i])
			}
		}

		console_print(id,"[KZ] %s all players access to hook/rope",onoff ? "Gave":"Removed") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) {
			gAllowedHook[plist[i]]=onoff
			if (gIsHooked[plist[i]]==true && onoff==0)
			{
				RopeRelease(plist[i])
			}
		}
		console_print(id,"[KZ] %s all %ss access to hook/rope",onoff ? "Gave":"Removed",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 

		gAllowedHook[player]=onoff
		if (gAllowedHook[player]==0 && onoff==0)
		{
			RopeRelease(player)
		}

		
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] %s ^"%s^" access to hook/rope",onoff ? "Gave":"Removed",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminScout(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,1) ) 
		return PLUGIN_HANDLED 

	new arg1[32]
	read_argv(1,arg1,31) 

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			GiveScout(plist[i]) 

		console_print(id,"[KZ] Gave all players scout") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			GiveScout(plist[i]) 
		console_print(id,"[KZ] Gave all %ss scouts",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		GiveScout(player) 
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Gave ^"%s^" scout",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminGravity(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,3) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new Float:gravalue = floatstr(arg2) / 100.0

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++)
		{
			set_user_gravity(plist[i],gravalue) 
			CheatDetect(plist[i],"GravityChange")
		}

		console_print(id,"[KZ] Set everyones gravity to %f",gravalue) 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++)
		{
			set_user_gravity(plist[i],gravalue)
			CheatDetect(plist[i],"GravityChange")
		}
		console_print(id,"[KZ] Set all %ss gravity to %f ",arg1[1],gravalue) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		set_user_gravity(player,gravalue) 
		CheatDetect(player,"GravityChange")
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set ^"%s^" gravity to %f",pName,gravalue) 
	} 

	return PLUGIN_HANDLED 
}

public AdminSetCheck(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,1) ) 
		return PLUGIN_HANDLED 

	new arg1[32]
	read_argv(1,arg1,31)

	new pName[32] 
	new player = cmd_target(id,arg1,6) 
	if (!player) return PLUGIN_HANDLED 
	get_user_origin(id,gCheckpointPos[player])
	gCheckpointPos[player][2] += 20
	gCheckpoint[player]=true
	gChecks[player]+=1
	CheatDetect(id,"Admin Checkpoint Change")
	get_user_name(player,pName,31)
	console_print(id,"[KZ] Set ^"%s^" checkpoint",pName) 
	return PLUGIN_HANDLED 
}

public AdminRemCheck(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,1) ) 
		return PLUGIN_HANDLED 

	new arg1[32]
	read_argv(1,arg1,31)

	new pName[32] 
	new player = cmd_target(id,arg1,6) 
	if (!player) return PLUGIN_HANDLED 
	gCheckpoint[player]=false
	gChecks[player]=0
//	CheatDetect(id,"Admin Checkpoint Removal")
	get_user_name(player,pName,31)
	console_print(id,"[KZ] Removed ^"%s^" checkpoint",pName) 
	return PLUGIN_HANDLED 
}

public AdminSetMoney(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,3) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new money = str_to_num(arg2)

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			cs_set_user_money(plist[i],money) 

		console_print(id,"[KZ] Set everyones money to %d",money) 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			cs_set_user_money(plist[i],money)
		console_print(id,"[KZ] Set all %ss money to %d ",arg1[1],money) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		cs_set_user_money(player,money)
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set ^"%s^" money to %d",pName,money) 
		gMoney[player]=money
	} 

	return PLUGIN_HANDLED 
}

public AdminNoclip(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,3) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new onoff = str_to_num(arg2)

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
		{
			set_user_noclip(plist[i],onoff)
			CheatDetect(plist[i],"NoClip")
		}

		console_print(id,"[KZ] Set Noclip on everyone") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
		{
			set_user_noclip(plist[i],onoff)
			CheatDetect(plist[i],"NoClip")
		}
		console_print(id,"[KZ] Set noclip on all %ss",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		set_user_noclip(player,onoff)
		CheatDetect(player,"NoClip")
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set noclip on ^"%s^"",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminSemiClip(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,3) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new onoff = str_to_num(arg2)

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) {
			if (is_user_alive(i)){
				entity_set_int(plist[i], EV_INT_solid, onoff ? 1:2)
			}
		}

		console_print(id,"[KZ] Set SemiClip on everyone") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			entity_set_int(plist[i], EV_INT_solid, onoff ? 1:2)
		console_print(id,"[KZ] Set Semiclip on all %ss",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		entity_set_int(player, EV_INT_solid, onoff ? 1:2)
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set Semiclip on ^"%s^"",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminGodMode(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,3) ) 
		return PLUGIN_HANDLED 

	new arg1[32],arg2[32]
	read_argv(1,arg1,31)
	read_argv(2,arg2,31)
	new onoff = str_to_num(arg2)

	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			set_user_godmode(plist[i],onoff)

		console_print(id,"[KZ] Set Godmode on everyone") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			set_user_godmode(plist[i],onoff)
		console_print(id,"[KZ] Set Godmode on all %ss",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		set_user_godmode(player,onoff)
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set Godmode on ^"%s^"",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminGlow(id,level,cid) 
{ 
	if ( !cmd_access(id,level,cid,5) ) 
		return PLUGIN_HANDLED 

	new arg1[32], sred[8], sgreen[8], sblue[8], salpha[8], name2[32] 
	get_user_name(id,name2,31) 
	read_argv(1,arg1,31) 
	read_argv(2,sred,7) 
	read_argv(3,sgreen,7)	
	read_argv(4,sblue,7)	
	read_argv(5,salpha,7)	
	new ired = str_to_num(sred) 
	new igreen = str_to_num(sgreen) 
	new iblue = str_to_num(sblue) 
	new ialpha = str_to_num(salpha)	
	if ( equali(arg1,"@all") ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"a") 
		if (pnum==0) 
		{ 
		 console_print(id,"[KZ] There are no clients") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
			set_user_rendering(plist[i],kRenderFxGlowShell,ired,igreen,iblue,kRenderTransAlpha,ialpha) 

		console_print(id,"[KZ] Set Glow on everyone") 
	} 
	else if ( arg1[0]=='@' ) 
	{ 
		new plist[32],pnum 
		get_players(plist,pnum,"ae",arg1[1]) 
		if ( pnum==0 ) 
		{ 
		 console_print(id,"[KZ] No clients in such team") 
		 return PLUGIN_HANDLED 
		} 
		for (new i=0; i<pnum; i++) 
		set_user_rendering(plist[i],kRenderFxGlowShell,ired,igreen,iblue,kRenderTransAlpha,ialpha)
		console_print(id,"[KZ] Set Glow on all %ss",arg1[1]) 
	} 
	else 
	{ 
		new pName[32] 
		new player = cmd_target(id,arg1,6) 
		if (!player) return PLUGIN_HANDLED 
		set_user_rendering(player,kRenderFxGlowShell,ired,igreen,iblue,kRenderTransAlpha,ialpha)
		get_user_name(player,pName,31) 
		console_print(id,"[KZ] Set Glow on ^"%s^"",pName) 
	} 

	return PLUGIN_HANDLED 
}

public AdminTele(id,level,cid) {

	if ( !cmd_access(id,level,cid,2) ) 
		return PLUGIN_HANDLED 

	new arg[32],TeleOrigin[3]
	
	read_argv(1,arg,31) 
	new TelePlayer = cmd_target(id,arg,6) 
	if (!TelePlayer) return PLUGIN_HANDLED 

	new argc = read_argc() 
	if (argc == 3) {
		new arg2[32]
		read_argv(2,arg2,31) 
		new OrigPlayer = cmd_target(id,arg2,6) 
		if (!OrigPlayer) return PLUGIN_HANDLED 
		get_user_origin(OrigPlayer,TeleOrigin)
		TeleOrigin[2]+=60
	}else{
		new sx[8], sy[8], sz[8]
		read_argv(2,sx,7) 
		read_argv(3,sy,7)	
		read_argv(4,sz,7)
		TeleOrigin[0] = str_to_num(sx) 
		TeleOrigin[1] = str_to_num(sy) 
		TeleOrigin[2] = str_to_num(sz) 
	}
	set_user_origin(TelePlayer, TeleOrigin)
	
	new pName[32]
	get_user_name(TelePlayer,pName,31) 
	CheatDetect(TelePlayer,"Teleport")
	console_print(id,"[KZ] Teleported ^"%s^" to x:%i y:%i z%i",pName,TeleOrigin[0],TeleOrigin[1],TeleOrigin[2]) 
	return PLUGIN_HANDLED	
} 

/************************************************************************************************************************/
/***************************************************** NVG CONTROL ******************************************************/
/************************************************************************************************************************/

public NVGToggle(id) {
	if (get_cvar_num("kz_nightvision")==0) return PLUGIN_CONTINUE

	if (NVGrun[id]==1) NVGcmd(id,0) 
	else NVGcmd(id,1)
	return PLUGIN_HANDLED
}
/************************************************************************************************************************/
public NVGcmd(id,nvgstate) {
	message_begin(MSG_ONE, get_user_msgid("NVGToggle"), {0,0,0}, id) 
	write_byte( nvgstate ) 
	message_end()
	NVGrun[id]=nvgstate
	emit_sound(id,CHAN_ITEM, NVGrun[id]?"items/nvg_on.wav":"items/nvg_off.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
}
/************************************************************************************************************************/
/******************************************************* JEDIGRAB *******************************************************/
/************************************************************************************************************************/
new grabbed[33]
new grablength[33]
new bool:grabmodeon[33]
new velocity_multiplier

public grabtask(parm[])
{
	new id = parm[0]
	new targetid, body
	if (!grabbed[id])
	{
		get_user_aiming(id, targetid, body)
		if (targetid)
		{
			set_grabbed(id, targetid)
		}
	}
	if (grabbed[id])
	{
		new origin[3], look[3], direction[3], moveto[3], grabbedorigin[3], velocity[3], length

		if (!is_user_alive(grabbed[id]))
		{
			release(id)
			return
		}

		get_user_origin(id, origin, 1)
		get_user_origin(id, look, 3)
		get_user_origin(grabbed[id], grabbedorigin)

		direction[0]=look[0]-origin[0]
		direction[1]=look[1]-origin[1]
		direction[2]=look[2]-origin[2]
		length = get_distance(look,origin)
		if (!length) length=1				// avoid division by 0

		moveto[0]=origin[0]+direction[0]*grablength[id]/length
		moveto[1]=origin[1]+direction[1]*grablength[id]/length
		moveto[2]=origin[2]+direction[2]*grablength[id]/length

		velocity[0]=(moveto[0]-grabbedorigin[0])*velocity_multiplier
		velocity[1]=(moveto[1]-grabbedorigin[1])*velocity_multiplier
		velocity[2]=(moveto[2]-grabbedorigin[2])*velocity_multiplier

		kz_velocity_set(grabbed[id], velocity)
	}
}

public grab_toggle(id)
{
	if (grabmodeon[id])
		release(id)
	else
		grab(id)
	return PLUGIN_HANDLED
}

public grab(id)
{
	if (!(get_user_flags(id)&ADMIN_LEVEL_D))
	{
		client_print(id,print_chat,"[KZ] You have no access to that command")
		return PLUGIN_HANDLED
	}
	if (!grabmodeon[id])
	{
		new targetid, body
		new parm[1]
		parm[0] = id
		velocity_multiplier = get_cvar_num("kz_grabforce")
		grabmodeon[id]=true
		set_task(0.1, "grabtask", 100+id, parm, 1, "b")
		get_user_aiming(id, targetid, body)
		if (targetid)
		{
			set_grabbed(id, targetid)
		}
		else
		{
			client_print(id,print_chat,"[KZ] Searching for a target")
		}
	}
	return PLUGIN_HANDLED
}

public release(id)
{
	if (!(get_user_flags(id)&ADMIN_LEVEL_D))
	{
		client_print(id,print_chat,"[KZ] You have no access to that command")
		return PLUGIN_HANDLED
	}
	if (grabmodeon[id])
	{
		grabmodeon[id]=false
		if (grabbed[id])
		{
			new targname[32]
			set_user_gravity(grabbed[id])
			set_user_rendering(grabbed[id])
			get_user_name(grabbed[id],targname,31)
			client_print(id,print_chat,"[KZ] You have released %s", targname)
		}
		else
		{
			client_print(id,print_chat,"[KZ] No target found")
		}
		grabbed[id]=0
		remove_task(100+id)
	}
	return PLUGIN_HANDLED
}

public spec_event(id)
{
	new targetid = read_data(2)

	if (targetid < 1 || targetid > 32)
		return PLUGIN_CONTINUE

	if (grabmodeon[id] && !grabbed[id])
	{
		set_grabbed(id, targetid)
	}
	return PLUGIN_CONTINUE
}

public set_grabbed(id, targetid)
{
	new origin1[3], origin2[3], targname[32]
	get_user_origin(id, origin1)
	get_user_origin(targetid, origin2)
	grabbed[id]=targetid
	grablength[id]=get_distance(origin1,origin2)
	set_user_gravity(targetid,0.001)
	set_user_rendering(targetid,kRenderFxGlowShell,50,0,0, kRenderNormal, 16)
	get_user_name(targetid,targname,31)
	client_print(id,print_chat,"[KZ] You have grabbed onto %s", targname)
}

/************************************************************************************************************************/
/****************************************************** NINJAROPE *******************************************************/
/************************************************************************************************************************/

public ropetask(parm[])
{
	new id = parm[0]
	new user_origin[3], user_look[3], user_direction[3], move_direction[3]
	new A[3], D[3], buttonadjust[3]
	new acceleration, velocity_towards_A, desired_velocity_towards_A
	new velocity[3], null[3]

	if (!is_user_alive(id))
	{
		RopeRelease(id)
		return
	}

	if (gBeamIsCreated[id] + BEAMLIFE/10 <= get_gametime())
	{
		beamentpoint(id)
	}

	null[0] = 0
	null[1] = 0
	null[2] = 0

	get_user_origin(id, user_origin)
	get_user_origin(id, user_look,2)
	kz_velocity_get(id, velocity)

	buttonadjust[0]=0
	buttonadjust[1]=0

	if (get_user_button(id)&IN_FORWARD)		buttonadjust[0]+=1
	if (get_user_button(id)&IN_BACK)		buttonadjust[0]-=1
	if (get_user_button(id)&IN_MOVERIGHT)	buttonadjust[1]+=1
	if (get_user_button(id)&IN_MOVELEFT)	buttonadjust[1]-=1
	if (get_user_button(id)&IN_JUMP)		buttonadjust[2]+=1
	if (get_user_button(id)&IN_DUCK)		buttonadjust[2]-=1

	if (buttonadjust[0] || buttonadjust[1])
	{
		user_direction[0] = user_look[0] - user_origin[0]
		user_direction[1] = user_look[1] - user_origin[1]

		move_direction[0] = buttonadjust[0]*user_direction[0] + user_direction[1]*buttonadjust[1]
		move_direction[1] = buttonadjust[0]*user_direction[1] - user_direction[0]*buttonadjust[1]
		move_direction[2] = 0

		velocity[0] += floatround(move_direction[0] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
		velocity[1] += floatround(move_direction[1] * MOVEACCELERATION * DELTA_T / get_distance(null,move_direction))
	}

	if (buttonadjust[2])	gHookLenght[id] -= floatround(buttonadjust[2] * REELSPEED * DELTA_T)
	if (gHookLenght[id] < 100) gHookLenght[id] = 100

	A[0] = gHookLocation[id][0] - user_origin[0]
	A[1] = gHookLocation[id][1] - user_origin[1]
	A[2] = gHookLocation[id][2] - user_origin[2]

	D[0] = A[0]*A[2] / get_distance(null,A)
	D[1] = A[1]*A[2] / get_distance(null,A)
	D[2] = -(A[1]*A[1] + A[0]*A[0]) / get_distance(null,A)

	acceleration = - global_gravity * D[2] / get_distance(null,D)

	velocity_towards_A = (velocity[0] * A[0] + velocity[1] * A[1] + velocity[2] * A[2]) / get_distance(null,A)
	desired_velocity_towards_A = (get_distance(user_origin,gHookLocation[id]) - gHookLenght[id] /*- 10*/) * 4

	if (get_distance(null,D)>10)
	{
		velocity[0] += floatround((acceleration * DELTA_T * D[0]) / get_distance(null,D))
		velocity[1] += floatround((acceleration * DELTA_T * D[1]) / get_distance(null,D))
		velocity[2] += floatround((acceleration * DELTA_T * D[2]) / get_distance(null,D))
	}

	velocity[0] += ((desired_velocity_towards_A - velocity_towards_A) * A[0]) / get_distance(null,A)
	velocity[1] += ((desired_velocity_towards_A - velocity_towards_A) * A[1]) / get_distance(null,A)
	velocity[2] += ((desired_velocity_towards_A - velocity_towards_A) * A[2]) / get_distance(null,A)

	kz_velocity_set(id, velocity)
}

public hooktask(parm[])
{ 
	new id = parm[0]
	new velocity[3]

	if ( !gIsHooked[id] ) return 
	
	new user_origin[3],oldvelocity[3]
	parm[0] = id

	if (!is_user_alive(id))
	{
		RopeRelease(id)
		return
	}

	if (gBeamIsCreated[id] + BEAMLIFE/10 <= get_gametime())
	{
		beamentpoint(id)
	}

	get_user_origin(id, user_origin) 
	kz_velocity_get(id, oldvelocity) 
	new distance=get_distance( gHookLocation[id], user_origin )
	if ( distance > 10 ) 
	{ 
		velocity[0] = floatround( (gHookLocation[id][0] - user_origin[0]) * ( 2.0 * REELSPEED / distance ) )
		velocity[1] = floatround( (gHookLocation[id][1] - user_origin[1]) * ( 2.0 * REELSPEED / distance ) )
		velocity[2] = floatround( (gHookLocation[id][2] - user_origin[2]) * ( 2.0 * REELSPEED / distance ) )
	} 
	else
	{
		velocity[0]=0
		velocity[1]=0
		velocity[2]=0
	}

	kz_velocity_set(id, velocity) 
	
} 

public hook_on(id)
{
	if (gAllowedHook[id] || (get_user_flags(id)&ADMIN_LEVEL_E)) {
		if (!gIsHooked[id] && is_user_alive(id))
		{
			new cmd[32]
			read_argv(0,cmd,31)
			if(equal(cmd,"+rope")) RopeAttach(id,0)
			if(equal(cmd,"+hook")) RopeAttach(id,1)
		}
	}else{
		client_print(id,print_chat,"[KZ] You have no access to that command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public hook_off(id)
{
	if (gAllowedHook[id] || (get_user_flags(id)&ADMIN_LEVEL_E)) {
		if (gIsHooked[id])
		{
			RopeRelease(id)
		}
	}else{
		client_print(id,print_chat,"[KZ] You have no access to that command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public RopeAttach(id,hook)
{
	CheatDetect(id,"Hook/Rope")
	new parm[1], user_origin[3]
	parm[0] = id
	gIsHooked[id] = true
	get_user_origin(id,user_origin)
	get_user_origin(id,gHookLocation[id], 3)
	gHookLenght[id] = get_distance(gHookLocation[id],user_origin)
	global_gravity = get_cvar_num("sv_gravity")
	set_user_gravity(id,0.001)
	beamentpoint(id)
	emit_sound(id, CHAN_STATIC, "weapons/xbow_hit2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	if (hook) set_task(DELTA_T, "hooktask", 200+id, parm, 1, "b")
	else set_task(DELTA_T, "ropetask", 200+id, parm, 1, "b")
}

public RopeRelease(id)
{
	gIsHooked[id] = false
	killbeam(id)
	set_user_gravity(id)
	remove_task(200+id)
}

public beamentpoint(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMENTPOINT )
	write_short( id )
	write_coord( gHookLocation[id][0] )
	write_coord( gHookLocation[id][1] )
	write_coord( gHookLocation[id][2] )
	write_short( beam )	// sprite index
	write_byte( 0 )		// start frame
	write_byte( 0 )		// framerate
	write_byte( BEAMLIFE )	// life
	write_byte( 10 )	// width
	write_byte( 0 )		// noise
	if (get_user_team(id)==1)		// Terrorist
	{
		write_byte( 255 )	// r, g, b
		write_byte( 0 )	// r, g, b
		write_byte( 0 )	// r, g, b
	}
	else							// Counter-Terrorist
	{
		write_byte( 0 )	// r, g, b
		write_byte( 0 )	// r, g, b
		write_byte( 255 )	// r, g, b
	}
	write_byte( 150 )	// brightness
	write_byte( 0 )		// speed
	message_end( )
	gBeamIsCreated[id] = get_gametime()
}

public killbeam(id)
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_KILLBEAM )
	write_short( id )
	message_end()
}

/************************************************************************************************************************/
/******************************************************* FORWARDS *******************************************************/
/************************************************************************************************************************/

public client_disconnect(id) {
	gCheckpoint[id]=false
	gJoined[id]=false
	gAllowedHook[id]=0
	ResetTimer(id,0)
}

/*#if defined NO_STEAM() {*/
public client_putinserver(id) {
/*#else
public client_authorized(id) {
#endif*/
	gJoined[id]=true
	gCheckpoint[id]=false
	gMoney[id]=gStartMoney
	ResetTimer(id,0)
}

#if USING_AMX
public client_prethink(id) {
   if (get_cvar_num("kz_bunnyjump")==0)
      return PLUGIN_CONTINUE

   if(!is_user_alive(id)) return PLUGIN_CONTINUE

   entity_set_float(id, EV_FL_fuser2, 0.0)      // Disable slow down after jumping

   if (get_cvar_num("kz_bunnyjump")>=2)
      return PLUGIN_CONTINUE

// Code from CBasePlayer::Jump (player.cpp)      Make a player jump automatically
   if (entity_get_int(id, EV_INT_button) & 2) {   // If holding jump
      new flags = entity_get_int(id, EV_INT_flags)

      if (flags & FL_WATERJUMP)
         return PLUGIN_CONTINUE
      if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
         return PLUGIN_CONTINUE
      if ( !(flags & FL_ONGROUND) )
         return PLUGIN_CONTINUE

      new Float:velocity[3]
      entity_get_vector(id, EV_VEC_velocity, velocity)
      velocity[2] += 250.0
      entity_set_vector(id, EV_VEC_velocity, velocity)

      entity_set_int(id, EV_INT_gaitsequence, 6)   // Play the Jump Animation
   }
   return PLUGIN_CONTINUE
}
#else
public client_PreThink(id) {
   if (get_cvar_num("kz_bunnyjump")==0)
      return PLUGIN_CONTINUE

   if(!is_user_alive(id)) return PLUGIN_CONTINUE

   entity_set_float(id, EV_FL_fuser2, 0.0)      // Disable slow down after jumping

   if (get_cvar_num("kz_bunnyjump")>1)
      return PLUGIN_CONTINUE

// Code from CBasePlayer::Jump (player.cpp)      Make a player jump automatically
   if (entity_get_int(id, EV_INT_button) & 2) {   // If holding jump
      new flags = entity_get_int(id, EV_INT_flags)

      if (flags & FL_WATERJUMP)
         return PLUGIN_CONTINUE
      if ( entity_get_int(id, EV_INT_waterlevel) >= 2 )
         return PLUGIN_CONTINUE
      if ( !(flags & FL_ONGROUND) )
         return PLUGIN_CONTINUE

      new Float:velocity[3]
      entity_get_vector(id, EV_VEC_velocity, velocity)
      velocity[2] += 250.0
      entity_set_vector(id, EV_VEC_velocity, velocity)

      entity_set_int(id, EV_INT_gaitsequence, 6)   // Play the Jump Animation
   }
   return PLUGIN_CONTINUE
}
#endif

public entity_touch(entity1, entity2) {
	DoTouch(entity1,entity2)
}

public pfn_touch(ptr, ptd) {
	DoTouch(ptr,ptd)
}

public DoTouch(pToucher,pTouched) {
	if (pToucher == 0 || pTouched == 0) return PLUGIN_CONTINUE

	new pTouchername[32], pTouchedname[32],pToucherTarget[32],pToucherTargetname[32]
	entity_get_string(pToucher, EV_SZ_classname, pTouchername, 31)
	entity_get_string(pTouched, EV_SZ_classname, pTouchedname, 31)
	entity_get_string(pToucher, EV_SZ_targetname, pToucherTargetname, 31)
	entity_get_string(pToucher, EV_SZ_target, pToucherTarget, 31)

	if(equal(pTouchername, "func_button") && equal(pTouchedname, "player"))
	{
		if (get_cvar_num("kz_timer")==1) {
			if (equal(pToucherTarget, "counter_start") && !gHasTimer[pTouched] || equal(pToucherTargetname, "clockstartbutton") && !gHasTimer[pTouched]) {
				gHasTimer[pTouched]=true
				client_print(pTouched,print_chat,"[KZ] Timer Started")
				gCheckpoint[pTouched]=false
			}
			if (equal(pToucherTarget, "counter_off") && gHasTimer[pTouched] && !gHasStoppedTimer[pTouched] || equal(pToucherTargetname, "clockstopbutton") && gHasTimer[pTouched] && !gHasStoppedTimer[pTouched] ) {
				new gName[33]
				gHasStoppedTimer[pTouched]=true
				gHasTimer[pTouched]=false
				get_user_name(pTouched,gName,32)
				client_print(pTouched,print_chat,"[KZ] Timer Stopped")
				if (get_cvar_num("kz_checkpoints") == 1) client_print(0,print_chat,"[KZ] %s just beat the map in %d:%d:%d (Used %d Checkpoints)",gName,gMins[pTouched],gSecs[pTouched],gHuns[pTouched],gChecks[pTouched])
				else client_print(0,print_chat,"[KZ] %s just beat the map in %d:%d:%d",gName,gMins[pTouched],gSecs[pTouched],gHuns[pTouched])
				check_top15(pTouched)
			}
		}
	}
	return PLUGIN_CONTINUE
}

/************************************************************************************************************************/
/********************************************************* TIMER ********************************************************/
/************************************************************************************************************************/

public gTimerTask() {
	for (new id=1;id<33;id++) {
		if(gHasTimer[id]) {
			gHuns[id]+=10
			if (gHuns[id] == 100) {
				gHuns[id]	= 00
				gSecs[id] += 1
			}
			if (gSecs[id] == 60) {
				gSecs[id]	= 00
				gMins[id] += 1
			}
			if (gMins[id] == 120) {
				gMins[id]	= 00
				ResetTimer(id,1)
				if (is_user_connected(id)) client_print(id,print_center,"Sorry You Used Too Long Time")
			}
			new sMins[33],sSecs[33],sHuns[33]
			FormatTime(gMins[id],gSecs[id],gHuns[id],sMins,sSecs,sHuns)
			if (is_user_connected(id)) client_print(id,print_center,"%s:%s:%s",sMins,sSecs,sHuns)
		}
	}
}

public ResetTimer(id,msg) 
{
	if (msg==1) client_print(id,print_chat,"[KZ] Timer Reset...")
	gHasTimer[id]=false
	gHasStoppedTimer[id]=false
	gSecs[id]=0
	gMins[id]=0
	gHuns[id]=0
	gChecks[id]=0
}

/************************************************************************************************************************/
/************************************************** AMXX -> AMX funcs ***************************************************/
/************************************************************************************************************************/
#if USING_AMX
	stock get_user_button(id) return entity_get_int(id, EV_INT_button)
	stock find_ent_by_class(iIndex, szValue[]) return find_entity(iIndex, szValue)
	stock cs_get_user_money(index) return get_user_money(index) 
	stock cs_set_user_money(index, money, flash = 1) set_user_money(index, money, flash)
#endif

/************************************************************************************************************************/
/******************************************************* Top 15 *********************************************************/
/************************************************************************************************************************/

public check_top15(id) {
	if (get_cvar_num("kz_top15")!=1)
		return
	new name[32],authid[32]
	get_user_name( id, name, 31 )
	get_user_authid( id, authid ,31 )

	new sPlayerScore[10], sHighScore[10], iPlayerScore, iHighScore
	new sMins[33],sSecs[33],sHuns[33]
	new sMinsScore[33],sSecsScore[33],sHunsScore[33]
	FormatTime(gMins[id],gSecs[id],gHuns[id],sMins,sSecs,sHuns)
	format(sPlayerScore,9,"%s%s%s",sMins,sSecs,sHuns)
	FormatTime(gMinsScore[14],gSecsScore[14],gHunsScore[14],sMinsScore,sSecsScore,sHunsScore)
	format(sHighScore,9,"%s%s%s",sMinsScore,sSecsScore,sHunsScore)
	iPlayerScore = str_to_num(sPlayerScore)
	iHighScore = str_to_num(sHighScore)

	if( iPlayerScore < iHighScore) {
		for( new i = 0; i < 15; i++ ) {
			FormatTime(gMinsScore[i],gSecsScore[i],gHunsScore[i],sMinsScore,sSecsScore,sHunsScore)
			format(sHighScore,9,"%s%s%s",sMinsScore,sSecsScore,sHunsScore)
			iHighScore = str_to_num(sHighScore)
			if( iPlayerScore < iHighScore) {
				new pos = i
				while( !equal( gAuthScore[pos], authid ) && pos < 14 )
					pos++
				for( new j = pos; j > i; j-- ) {
					format( gAuthScore[j], 32, gAuthScore[j-1] )
					format( gNameScore[j], 32, gNameScore[j-1] )
					gMinsScore[j] = gMinsScore[j-1]
					gSecsScore[j] = gSecsScore[j-1]
					gHunsScore[j] = gHunsScore[j-1]
					gChecksScore[j] = gChecksScore[j-1]
				}
			
				format( gAuthScore[i], 32, authid )
				format( gNameScore[i], 32, name )
				gMinsScore[i] = gMins[id]
				gSecsScore[i] = gSecs[id]
				gHunsScore[i] = gHuns[id]
				gChecksScore[i] = gChecks[id]

				save_top15()
				return
			}
			if( equal( gAuthScore[i], authid ) )
				return
		}	
	}
	return
}

public save_top15() {
	if (get_cvar_num("kz_top15")!=1)
		return PLUGIN_HANDLED

	new cMap[32]
	get_mapname(cMap, 31)

	new cScoreFile[128]	
	format(cScoreFile, 127, "%s/%s.txt", gScorePath, cMap)

	if( file_exists(cScoreFile) )	
		delete_file(cScoreFile)
	
	for( new i = 0; i < 15; i++ ) {
		if( gMinsScore[i] == 0 && gSecsScore[i] == 0 && gHunsScore[i] == 0)
			return PLUGIN_HANDLED
	
		new TextToSave[1024],sNameScore[33]
		format(sNameScore, 127, "^"%s^"", gNameScore[i])
		format(TextToSave,sizeof(TextToSave),"%s %s %d %d %d %d",gAuthScore[i],sNameScore,gMinsScore[i],gSecsScore[i],gHunsScore[i],gChecksScore[i])
		write_file(cScoreFile, TextToSave)
	}
	return PLUGIN_HANDLED
}

public read_top15() {
	if (get_cvar_num("kz_top15")!=1)
		return PLUGIN_HANDLED

	for( new i = 0 ; i < 15; ++i) {
		gAuthScore[i] = "X"
		gNameScore[i] = "X"
		gMinsScore[i] = 9999999
		gSecsScore[i] = 0
		gHunsScore[i] = 0
		gChecksScore[i] = 9999999
	}
	new cMap[32]
	get_mapname(cMap, 31)

	new cScoreFile[128]	
	format(cScoreFile, 127, "%s/%s.txt", gScorePath, cMap)
		
	if(file_exists(cScoreFile) == 1) { 
		new line, stxtsize 
		new data[192] 
		new tAuth[32],tName[32],tMins[10],tSecs[10],tHuns[10],tChecks[10]
		for(line = 0; line < 15; ++line) {
			read_file(cScoreFile,line,data,191,stxtsize)
			parse(data,tAuth,31,tName,31,tMins,9,tSecs,9,tHuns,9,tChecks,9)
			format(gAuthScore[line],sizeof(gAuthScore),tAuth)
			format(gNameScore[line],sizeof(gNameScore),tName)
			gMinsScore[line] = str_to_num(tMins)
			gSecsScore[line] = str_to_num(tSecs)
			gHunsScore[line] = str_to_num(tHuns)
			gChecksScore[line] = str_to_num(tChecks)
		}
	}else{
		server_cmd("echo [KZ] Error!!! Failed To Load ^"%s^"!!!",cScoreFile)
		log_message("[KZ] Error!!! Failed To Load ^"%s^"!!!",cScoreFile)
	}

	return PLUGIN_HANDLED
}

public show_top15( id ) { 
	if (get_cvar_num("kz_top15")!=1) {
		client_print(id,print_chat,"[KZ] Top15 is disabled ")
		return PLUGIN_HANDLED
	}
		
	new buffer[2048] 
	new line[256]
		
	new len = format( buffer, 2047, "<table cellspacing=0 rules=all border=2 frame=border>" )
	if (get_cvar_num("kz_checkpoints")==1) {
		len += format( buffer[len], 2047-len, "<tr><th> # <th> Nick <th> Climb time <th> Checkpoints" )
	}else{
		len += format( buffer[len], 2047-len, "<tr><th> # <th> Nick <th> Climb time" )
	}
	for(new i = 0; i < 15; ++i) {		
		if( gMinsScore[i] == 9999999 && gSecsScore[i] == 0 && gHunsScore[i] == 0 && gChecksScore[i] == 9999999)
			if (get_cvar_num("kz_checkpoints")==1) {
				format(line, 255, "<tr><td> %d. <td> %s <td> %s <td> %s", (i+1), "&lt;----------&gt;", "&lt;not set&gt;", "&lt;not set&gt;" )
			}else{
				format(line, 255, "<tr><td> %d. <td> %s <td> %s", (i+1), "&lt;----------&gt;", "&lt;not set&gt;" )
			}
		else
			if (get_cvar_num("kz_checkpoints")==1) {
				format(line, 255, "<tr><td> %d. <td> %s <td> (%d:%d:%d) <td> (%d)", (i+1), gNameScore[i], gMinsScore[i] , gSecsScore[i], gHunsScore[i], gChecksScore[i]	)
			}else{
				format(line, 255, "<tr><td> %d. <td> %s <td> (%d:%d:%d)", (i+1), gNameScore[i], gMinsScore[i] , gSecsScore[i], gHunsScore[i]	)			
			}
		len += format( buffer[len], 2047-len, line )
	}
	
	format(line, 255, "</table>" )
	len += format( buffer[len], 2047-len, line )
		
	show_motd( id, buffer, "Top 15 Climbers" )	
	return PLUGIN_HANDLED
}