/*
Welcome to Plugin running server:
97Club BHOP  - 219.147.250.62:27016
97Club Climb - 219.147.250.62:27017

Visit to http://www.27015.com/kztop/
*/
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <geoip>
#include <engine>
#if AMXX_VERSION_NUM < 183
#include <colorchat>
#include <dhudmessage>
#else
#define ColorChat client_print_color
#define GREEN print_team_default
#define BLUE print_team_blue
#define RED print_team_red
#define GREY print_team_grey
#endif

#define PLUGIN_NAME	"ProKreedz"
//#include <pluginchk>
#include <sqlx>

#define VERSION "2.4.7.0482"

#define ZZCOUNT		1
new const zzList[ZZCOUNT][] = {"97Club^^HomeLink"};

#if !defined USE_SQL
#include <sockets>//下载wr数据需要的头文件
#endif
//#include <dhudmessage>//hud大字体

#define USE_SQL

#if defined USE_SQL
 #include <sqlx>
#endif

#define KZ_LEVEL ADMIN_KICK
#define MSG MSG_ONE_UNRELIABLE
#define MAX_ENTITYS 4096
#define IsOnLadder(%1) (pev(%1, pev_movetype) == MOVETYPE_FLY)
//#define VERSION "2.31"

#define UPDATEINTERVAL		1.0
#define UPDATEINTERVALB		1.0

#define INDEX_CN			0
#define INDEX_EN			1

#define SCOREATTRIB_NONE	0
#define SCOREATTRIB_DEAD	(1 << 0)
#define SCOREATTRIB_BOMB	(1 << 1)
#define SCOREATTRIB_VIP		(1 << 2)

#define TASK_CALLREADTOP		434000
#define TASK_GETMORE			434001
#define TASK_GETCUPROUTE		434002
#define TASK_MSGINFO			434100
//#define TASK_KZUID				434200
#define TASK_NVG				434300
#define TASK_GIVEWPN			434400
#define TASK_SETCOLOR			434500
#define TASK_PAUSE				434600
#define TASK_GOSTART			434700
#define TASK_CHKWPN				434800
#define TASK_DELAYALLOWSTART	434900
#define TASK_LOCKCURWPNCHK		435000
#define TASK_ACCEPTMENU			435100
#define TASK_COUNTDOWN_FREEZE	435200
#define TASK_CHALLENGEALL		435300
#define TASK_DELAYREADY			435400
#define TASK_SHOWOPPONENT		435500
#define TASK_SHOWOPPONENTEX		435600
#define TASK_ACCEPTCONFIRMMENU	435700
#define TASK_CONNSQL			435800
#define TASK_CHALLENGEDELAY		435900
#define TASK_CHECKCHALLENGETEAM	436000

#define OFFSET_AWP_AMMO				377 
#define OFFSET_SCOUT_AMMO			378
#define OFFSET_USP_AMMO				382

// weapons offsets 
#define XO_WEAPONS 4 
#define m_pPlayer 41 
#define m_iId 43 
#define m_flNextPrimaryAttack 46 
#define m_flNextSecondaryAttack 47

// players offsets 
#define XO_PLAYER 5
#define m_flNextAttack 83 

enum  // STRING 必须放在最后
{
	ID = 0, TYPE, ACTION, CPNUM, GPNUM, STRING
}

new bool:g_HamPlayerSpawned[33] = false

#define KZ_UID ADMIN_LEVEL_F//获取UID权限
new g_nDzUid[33]		//论坛UID
new website[] = "http://www.27015.com/kztop/"

new g_iPlayers[32], g_iNum, g_iPlayer;
new const g_szAliveFlags[] = "a" 
#define RefreshPlayersList()   get_players(g_iPlayers, g_iNum, g_szAliveFlags)

new const FL_ONGROUND2 = (FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER | FL_CONVEYOR | FL_FLOAT)
new const KZ_SURFSTART[] = "models/www.iwan.pro/start.mdl"
new const KZ_SURFSTOP[] = "models/www.iwan.pro/stop.mdl"
new const KZ_ROUTEMDL[] = "models/gib_skull.mdl"

new const NULLSTR[] = ""//Top15和玩家状态换行
new bool:gHooked[33] //修复光波bug

/* 小广告 */
new g_szTga[10][128]
new g_nTga = 0

new g_hltv_id;
new g_cangetwpn[] = "计时中不允许使用其它武器, 输入 /reset清除计时"
new g_szGroupStart[] = "挑战中，无法使用其它武器"
#if defined USE_SQL
/** hosen *
new g_TOP_SQL_ADDR[] = {0x2D3F3031, 0x2D363330, 0x2D2F3431, 0x36393135, 0xFF323236};
new g_TOP_SQL_USER[] = {0x6A6E716F, 0x63646471, 0xFEFEFF79};
new g_TOP_SQL_PASS[] = {0x64236745, 0x3F235E37, 0xFEFEFEFF};
/ 97Club **
new g_TOP_SQL_ADDR[] = {0x2DA13130, 0x2D333030, 0x312D3235, 0x32392F34, 0xFF352F32}
new g_TOP_SQL_USER[] = {0xFF6CDF61}
new g_TOP_SQL_PASS[] = {0x47CE6049, 0x6D554D37, 0xFEFA4460}
*/
new bool:g_SqlReady;
new Handle:g_SqlTuple
new Handle:g_SqlConnection
new g_Error[512]
new kz_sql_name
new g_wpnorder[] = "speed, "
#else
new Float:Pro_Times[24]
//new Pro_AuthIDS[24][32]
new Pro_Names[24][32]
new Pro_Date[24][32]
new Pro_Country[24][8]
new Float:Noob_Tiempos[24]
//new Noob_AuthIDS[24][32]
new Noob_Names[24][32]
//new Noob_Date[24][32]
new Noob_CheckPoints[24]
new Noob_GoChecks[24]
//new Noob_Weapon[24][32]
new Noob_Country[24][3]
new Pro_Counts[24]//裸跳完成次数
new Noob_Counts[24]//存点完成次数
new Top_DZUserID[24]
#define RANKLEN 2//对齐排名行数
new num = 20 //调整Top15排名数量
#endif
new procount[33]//裸跳完成次数
new nubcount[33]//存点完成次数

//世界记录
//new Float:sztimez[33]
//new arry[33]
new e_MapName[64]
new e_Message[2][512]
new bool:ShowMSGs[33]
new e_TopName[32]
new e_TopType
new e_TopTime[10]
new e_Weapon[10]
new e_WpnSpeed
new Float:e_WRtime
new Float:e_fTopTime;
new g_szServer[16];

new Float:timer_timed[33]		// 理论时间 
new Float:timer_stime[33][2]	// 存点到读点之间的时间
new Float:timer_save[33][2]	// 存点到读点之间的时间
//new Float:timer_save[33][2]	// stuck用的变量
new Float:g_pausestime[33]		// 存点到读点之间暂停时间
new Float:g_pausestimez[33]		// 再次读点后的暂停时间
new Float:g_pausetimed[33]		// 理论暂停时间
//new Float:g_fSubtime[33][2]		// 上一个读点到上上个点的时间差
//new bool:g_bSubtime[33]

/*
new Float:g_timer_time[33]
new Float:g_timer_saved[33]
new Float:g_timer_pausetime[33]
*/

#define STATUS_NONE 1//进服状态
#define STATUS_CLIMBING 2//攀登中
#define STATUS_FINISHED 3//完成
#define STATUS_PAUSED 4//暂停中
#define STATUS_CHEAT 5//计时清零
new climber_status[33]
new STATUS_PATH[100]//状态html缓存文件
new Float:oldtimed[33]//按计时器显示最快记录

#if !defined USE_SQL
//Top缓存文件
new PRO_PATH[100]
new NUB_PATH[100]
new RDS_PATH[100]
#endif

new Float:Checkpoints[33][2][3]
new Float:timer_time[33]
new Float:g_pausetime[33]
new Float:anticheat[33]
new Float:SpecLoc[33][3]
new Float:NoclipPos[33][3]
new Float:PauseOrigin[33][3]
new Float:SavedStart[33][3]
new hookorigin[33][3]
new Float:DefaultStartPos[3]
new Float:ProStart[33][3]
new Float:g_finish_time[33]
new bool:GetDefaultStart

/*new Float:SavedTime[33]
new Float:SavedTimed[33]//保存理论时间
new SavedChecks[33]
new SavedGoChecks[33]
new SavedOrigins[33][3]
*/

new bool:g_bCpAlternate[33]
new bool:timer_started[33]
new bool:IsPaused[33]
new bool:WasPaused[33]
new bool:firstspawn[33]
new bool:canusehook[33]
new bool:ishooked[33]
new bool:NightVisionUse[33]
new bool:HealsOnMap
new bool:gViewInvisible[33]
new bool:gMarkedInvisible[33] = {true, ...};
new bool:gWaterInvisible[33]
new bool:gWaterEntity[MAX_ENTITYS]
new bool:gWaterFound
new bool:DefaultStart
new bool:AutoStart[33]
new bool:plugin_status = true;
new bool:stopstart = false;
new bool:allowstart[33] = {true, ...};
new bool:g_lockcurwpnchk[33]

new Trie:g_tStarts
new Trie:g_tStops
new Float:g_flStartDelay

new user_use_wpn[33]
new checknumbers[33]
new gochecknumbers[33]
new chatorhud[33]
new ShowTime[33]
new MapName[64]
new Kzdir[128]
//new SavePosDir[128]
new prefix[33]
#if !defined USE_SQL
new Topdir[128]
#endif

new kz_cup
new kz_cup_start
new kz_issurf
new kz_cheatdetect
//new kz_spawn_mainmenu
new kz_show_timer
new kz_chatorhud
new kz_hud_color
new kz_chat_prefix
new kz_other_weapons
new kz_maxspeedmsg
new kz_drop_weapons
new kz_remove_drops
new kz_use_radio
new kz_hook_prize
//new kz_hook_sound
new kz_hook_speed
new kz_pause
new kz_noclip_pause
new kz_nvg
new kz_nvg_colors
new kz_vip
new kz_respawn_ct
//new kz_save_pos
//new kz_save_pos_gochecks
new kz_semiclip
new kz_spec_saves
new kz_save_autostart
//new kz_top15_authid
new g_SrvIdle
//声音
new kz_stats_sound//起点
new statsz[33]
new kz_complete_sound//终点
new completez[33]
new kz_top1_sound//进入Top1
new rankz[33]
//new kz_cps100_sound//存点超过100
//new cpsz[33]

new Sbeam = 0

//new Float:g_fps[33]	// 锁定fps

#define IsPlayer(%0)	( 1 <= %0 <= g_iMaxPlayers )
new g_iMaxPlayers;

//g_nGrouparray

#define CUP_MAX_ROUTE	6		// 多一个，0维为{0,0,0}(终点)
new bool:g_bCupRoute = false
new Float:g_fCupCustomPos[CUP_MAX_ROUTE][3];
new g_fCupCusPosNum;
new Float:g_fTopFastTime = -1.0;
new Float:g_fWRTime = -1.0;

#define GROUP_REMAINING_DEFAULT		60
new Float:g_fSourcePos[33][3];
new Float:g_nGroupShowOppo[17];
new Float:g_nGroupTimer[17];
new bool:g_bWait[33] = {true, ...};
new bool:g_bAccept[33] = {true, ...};
new bool:g_bAccepting[33];
new bool:g_bInvite[33];
new bool:g_bAllAccepting[33][32];
new bool:g_nGroupPoint[17];
new bool:g_nGetScore[33];
//new bool:g_bCustomFinish[17];
new bool:g_bGroupStart[17];
new g_nGroupEndTag[17];
new g_nGroupPeople[17][2];
new g_nPeopleName[33][32];
new g_nGroupCountDownFreeze[17];
new g_nGroupVoice[17];
new g_nGroupWeapon[17];
new g_nGroupRoute[17];
new g_nGroupId[33];
new g_nGroupUid[17][2];
new g_nGroupGiveUp[33];
new g_nTmpGroupId[33];
new g_nGroupRemaining[33];
enum group_tag {SENDER, RECVER, ESCAPE, GIVEUP, FINISH, REJECT, TIMEOUT, NONOTIFY};
enum score_tag {WIN, LOSE, DRAW, INVITE, ACCEPT, REJECT, ESCAPE, SCORE, CHALLENGE, LEVEL};
new g_nGroupScore[33][10];

new g_menuPlayers[33][32];
new g_menuPlayersNum[33];
new g_nPage[33];

new g_szTopOneName[3][32];
//new g_iRender[3]
new Float:g_fCurFasterTimer = 9999.0;
new g_iCurFasterID;
new g_szCurFaterName[32];

new const newversion[] = "<html><head></head><body><p><meta charset=UTF-8>正在跳转中</p><script type='text/javascript'>window.location.href='%s%s?subtype=%s&map=%s&nohead=yes&dzuid=%d&authid=%s&lang=%s';</script></body></html>"

new const oldversion[] = "<html><head><meta http-equiv='Refresh' content='0;url=%s%s?subtype=%s&map=%s&nohead=yes&dzuid=%d&authid=%s&lang=%s'></head><body><p><meta charset=UTF-8>亲，正版秒刷有木有。</p></body></html>"

#define OTHER_WPN_SIZE		6
new const other_weapons[OTHER_WPN_SIZE] = 
{
	CSW_SCOUT, CSW_USP, CSW_FAMAS, CSW_M4A1, CSW_M249, CSW_AWP
}

new const other_weapons_enname[OTHER_WPN_SIZE][] = 
{
	"SCOUT", "USP", "FAMAS", "M4A1", "M249", "AWP"
}

new const weapons_speeds[OTHER_WPN_SIZE] = 
{
	260, 250, 240, 230, 220, 210
}

new const other_weapons_name[OTHER_WPN_SIZE][] = 
{
	"weapon_scout", "weapon_usp", "weapon_famas", "weapon_m4a1", "weapon_m249", "weapon_awp"
}

new const g_weaponsnames[][] = 
{
	"", // NULL
	"p228", "shield", "scout", "hegrenade", "xm1014", "c4",
	"mac10", "aug", "smokegrenade", "elite", "fiveseven",
	"ump45", "sg550", "galil", "famas", "usp", "glock18",
	"awp", "mp5navy", "m249", "m3", "m4a1", "tmp", "g3sg1",
	"flashbang", "deagle", "sg552", "ak47", "knife", "p90",
	"glock", "elites", "fn57", "mp5", "vest", "vesthelm", 
	"flash", "hegren", "sgren", "defuser", "nvgs", "primammo", 
	"secammo", "km45", "9x19mm", "nighthawk", "228compact", 
	"12gauge", "autoshotgun", "mp", "c90", "cv47", "defender", 
	"clarion", "krieg552", "bullpup", "magnum", "d3au1", 
	"krieg550"
}

new const g_block_commands[][] = 
{
	"buy", "buyammo1", "buyammo2", "buyequip",
	"cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy"
}

//下载声音文件列表
new dlFilesList[][] = 
{
    "kzsound/tutor_msg.wav",//起点 
	"kzsound/doop.wav",//终点
	"kzsound/task_complete.wav"//,//进入TOP1
   // "kzsound/friend_died.wav"//存点超过100提示
}

#define ROUTESIZE	15
new g_szSelRoute[33][16]
new g_szRoute[10][33]
new bool:g_bRoute = false
new g_szRouteCHN[][] = {"裸跳", "武器", "存点"}
new g_nSelRoute[33]
new g_szHotMap[64]

new g_szSpawnFile[256];

enum
{
	PRO_TOP,				// 0
	WPN_TOP,				// 1
	NUB_TOP,				// 2
	TOP_NUL,				// 3
	LASTTOP,				// 4
	PRO_RECORDS,			// 5
	PLAYERS_CLEANLIST,		// 6
	PLAYERS_RANKING,		// 7
	MAPS_STATISTIC,			// 8
	GETRECORD,				// 9
	UPDRECORD,				// 10
	SETBUTTON,				// 11
	GETTOPONE,				// 12
	GETROUTE,				// 13
	GETSTART,				// 14
	SETSTART,				// 15
	UPDSTART,				// 16
	GETSCORE,				// 17
	ADDSCORE,				// 18
	UPDSCORE,				// 19
	READTOP,				// 20
	SHOWHELP,				// 21
	GETCUPROUTE,			// 22
	GETHOTMAP,				// 23
	CHALLENGETOP,			// 24
	CHALLENGETOP_LOG,		// 25
	SYNC_SPAWN_DATA,		// 26
	GET_SPAWN_DATA,			// 27
}

// 不要改变顺序
#define PROOFFSET	0
#define WPNOFFSET	1
#define NUBOFFSET	2

#define CURRENT		0														// 紫0
#define ONLYPRO		(1 << PROOFFSET)										// 青1
#define ONLYWPN		(1 << WPNOFFSET)										// 蓝2
#define PROWPN		(1 << PROOFFSET) + (1 << WPNOFFSET)						// 橙3
#define ONLYNUB		(1 << NUBOFFSET)										// 绿4
#define PRONUB		(1 << PROOFFSET) + (1 << NUBOFFSET)						// 白5
#define WPNNUB		(1 << WPNOFFSET) + (1 << NUBOFFSET)						// 黄6
#define ALLTOP		(1 << PROOFFSET) + (1 << WPNOFFSET) + (1 << NUBOFFSET)	// 红7
new const g_fTopColor[8][3] = {
		  {255, 0, 255},	// 紫
		  {0, 255, 255},	// 青
		  {0, 0, 255},		// 蓝
		  {255, 165, 0},	// 橙
		  {0, 255, 0},		// 绿
		  {255, 255, 255},	// 白
		  {255, 255, 0},	// 黄
		  {255, 0, 0}		// 红
}
// =================================================================================================
 
public plugin_init()
{
	register_plugin("ProKreedz", VERSION, "VANCY & nucLeaR & p4ddY")
	
	//server_print("-------------   %f %f %f", g_fTopColor[CURRENT][0], g_fTopColor[CURRENT][1], g_fTopColor[CURRENT][2]);

	kz_cup = register_cvar("kz_cup", "0")
	kz_cup_start = register_cvar("kz_cup_start", "0")
	kz_issurf = register_cvar("kz_issurf", "0")
	kz_cheatdetect = register_cvar("kz_cheatdetect", "1")
	kz_show_timer = register_cvar("kz_show_timer", "1")
	kz_chatorhud = register_cvar("kz_chatorhud", "2")
	kz_chat_prefix = register_cvar("kz_chat_prefix", "[97Club]")
	kz_hud_color = register_cvar("kz_hud_color", "64 64 64")
	kz_other_weapons = register_cvar("kz_other_weapons", "1")
	kz_drop_weapons = register_cvar("kz_drop_weapons", "0")
	kz_remove_drops = register_cvar("kz_remove_drops", "1")
	kz_maxspeedmsg = register_cvar("kz_maxspeedmsg", "1")
	kz_hook_prize = register_cvar("kz_hook_prize", "1")
	//kz_hook_sound = register_cvar("kz_hook_sound", "1")
	kz_hook_speed = register_cvar("kz_hook_speed", "300.0")
	kz_use_radio = register_cvar("kz_use_radio", "0")
	kz_pause = register_cvar("kz_pause", "1")
	kz_noclip_pause = register_cvar("kz_noclip_pause", "1")
	kz_nvg = register_cvar("kz_nvg", "1")
	kz_nvg_colors = register_cvar("kz_nvg_colors", "5 0 255")
	kz_vip = register_cvar("kz_vip", "1")
	kz_respawn_ct = register_cvar("kz_respawn_ct", "1")
	kz_semiclip = register_cvar("kz_semiclip", "1")
	kz_spec_saves = register_cvar("kz_spec_saves", "1")
	kz_save_autostart = register_cvar("kz_save_autostart", "1")
	//kz_top15_authid = register_cvar("kz_top15_authid", "0")
	//kz_save_pos = register_cvar("kz_save_pos", "1")
	//kz_save_pos_gochecks = register_cvar("kz_save_pos_gochecks", "1")

	//声音
	kz_stats_sound = register_cvar("kz_stats_sound", "kzsound/tutor_msg.wav")
	kz_complete_sound = register_cvar("kz_complete_sound", "kzsound/doop.wav")
	kz_top1_sound = register_cvar("kz_top1_sound", "kzsound/task_complete.wav")
	//kz_cps100_sound = register_cvar("kz_cps100_sound", "kzsound/friend_died.wav")

	#if defined USE_SQL
	kz_sql_name = register_cvar("kz_sql_server", "")// Name of server
	get_pcvar_string(kz_sql_name, g_szServer, 15);
	set_task(7.0, "check_sql_name");
	#endif

	//register_clcmd("say", "SetFps")

	register_clcmd("/cp", "CheckPoint")
	register_clcmd("drop", "BlockDrop")
	register_clcmd("/gc", "GoCheck")
	register_clcmd("+hook", "hook_on", KZ_LEVEL)
	register_clcmd("-hook", "hook_off", KZ_LEVEL)
	register_concmd("kz_hook", "give_hook",  KZ_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")
	register_concmd("nightvision", "ToggleNVG")
	register_clcmd("radio1", "BlockRadio")
	register_clcmd("radio2", "BlockRadio")
	register_clcmd("radio3", "BlockRadio")
	register_clcmd("/tp", "GoCheck")
	
	register_clcmd("cp", "CheckPoint")
	register_clcmd("/cp", "CheckPoint")
	register_clcmd(".cp", "CheckPoint")
	register_clcmd("say /cp", "CheckPoint")
	register_clcmd("say /checkpoint", "CheckPoint")
	register_clcmd("say /stopstart", "StopStart")
	register_clcmd("say /lang", "cmdMulLang");
	
	
	register_clcmd("gc", "GoCheck")
	register_clcmd("/gc", "GoCheck")
	register_clcmd(".gc", "GoCheck")
	register_clcmd("say /gc", "GoCheck")
	register_clcmd("say /ss", "SetProStart")
	register_clcmd("say /cs", "ClearProStart")
	register_clcmd("say /gocheck", "GoCheck")	
	register_clcmd("top15", "top15menu")
	register_clcmd("say /challenge", "ChallengeMenu");
	register_clcmd("say /1v1", "ChallengeMenu");
	register_clcmd("say /challengeall", "ChallengeAllMenu");
	register_clcmd("say /1vn", "ChallengeAllMenu");
	register_clcmd("say /battlemenu", "BattleMenu");
	register_clcmd("battlemenu", "BattleMenu");
	register_clcmd("say /accept", "CmdAccept");
	register_clcmd("say /gg", "GiveUp");
	register_clcmd("say /zz", "ZzListMenu");

	register_menu("ConfirmMenu", -1, "ConfirmMenuAction", 0);
	
	register_clcmd("say /status", "ct_status")//注册查看玩家状态命令

	set_task(UPDATEINTERVAL, "Tick", 0,_,_, "b")
	//set_task(60.0, "ChkSrvNum", 0, _, _, "b");
	#if !defined USE_SQL
	register_clcmd("say /me", "ShowMeRank")//注册查看自己排名命令
	kz_register_saycmd("rdslist", "Rewards_show", 0)
	#endif
	
	kz_register_saycmd("cp", "CheckPoint",0)
	kz_register_saycmd("checkpoint", "CheckPoint",0)
	kz_register_saycmd("chatorhud", "ChatHud", 0)
	kz_register_saycmd("ct", "ct",0)
	kz_register_saycmd("gc", "GoCheck",0)
	kz_register_saycmd("gocheck", "GoCheck",0)
	kz_register_saycmd("god", "GodMode",0)
	kz_register_saycmd("godmode", "GodMode", 0)
	kz_register_saycmd("invis", "InvisMenu", 0)
	register_clcmd("invis", "InvisMenu", 0)
	kz_register_saycmd("kz", "kz_menu", 0)
	kz_register_saycmd("menu", "kz_menu", 0)
	register_clcmd("say menu", "kz_menu", 0)
	kz_register_saycmd("nc", "noclip", 0)
	kz_register_saycmd("noclip", "noclip", 0)
	kz_register_saycmd("noob10", "NoobTop_show", 0)
	kz_register_saycmd("noob15", "NoobTop_show", 0)
	kz_register_saycmd("nub10", "NoobTop_show", 0)
	kz_register_saycmd("nub15", "NoobTop_show", 0)
	kz_register_saycmd("pause", "Pause", 0)
	kz_register_saycmd("pinvis", "cmdInvisible", 0)
	kz_register_saycmd("pro10", "ProTop_show", 0)
	kz_register_saycmd("pro15", "ProTop_show", 0)
	kz_register_saycmd("wpn10", "WpnTop_show", 0)
	kz_register_saycmd("wpn15", "WpnTop_show", 0)
	kz_register_saycmd("reset", "reset_checkpoints", 0)
	kz_register_saycmd("respawn", "goStart", 0)
	//kz_register_saycmd("savepos", "SavePos", 0)
	register_clcmd("say /awp", "cmdAwp", 0)
	register_clcmd("say /m249", "cmdM249", 0)
	register_clcmd("say /m4a1", "cmdM4a1", 0)
	register_clcmd("say /famas", "cmdFamas", 0)
	register_clcmd("say /usp", "cmdUsp", 0)
	register_clcmd("say /knife", "cmdUsp", 0)
	register_clcmd("say /scout", "cmdScout", 0)
	kz_register_saycmd("setstart", "setStart", KZ_LEVEL)
	kz_register_saycmd("showtimer", "ShowTimer_Menu", 0)
	kz_register_saycmd("spec", "ct", 0)
	register_clcmd("spec", "ct", 0)
	register_clcmd("/spec", "ct", 0)
	//register_menucmd(register_menuid("Team_Select", true), MENU_KEY_1|MENU_KEY_5, "ct");
	register_clcmd("jointeam 1", "ct", 0)
	register_clcmd("jointeam 2", "ct", 0)
	register_clcmd("jointeam 5", "ct", 0)
	kz_register_saycmd("start", "goStart", 0)
	kz_register_saycmd("stuck", "Stuck", 0)
	register_clcmd("stuck", "Stuck", 0)
	kz_register_saycmd("teleport", "GoCheck", 0)
	kz_register_saycmd("timer", "ShowTimer_Menu", 0)
	kz_register_saycmd("top15", "top15menu",0)
	kz_register_saycmd("top10", "top15menu",0)
	kz_register_saycmd("tp", "GoCheck",0)
	kz_register_saycmd("weapons", "weapons", 0)
	kz_register_saycmd("guns", "weapons", 0)	
	kz_register_saycmd("winvis", "cmdWaterInvisible", 0)
	
	register_clcmd("say /reloadcr", "GetCupRoute");
	register_clcmd("kz_uid", "cmdShowUID");
	
	register_event("CurWeapon", "curweapon", "be", "1=1")
	register_event("StatusValue", "EventStatusValue", "b", "1>0", "2>0");
	
	register_clcmd("chooseteam", "ct");//按M切换到观察者
	//register_message(get_user_msgid("Health"), "message_Health");
	register_event("Damage", "Event_Damage", "b", "1=0", "2>0", "3=0", "4=0", "5=0", "6=0")//显示掉血

	register_forward(FM_GetGameDescription, "changeGameClass")//游戏类型
	register_forward(FM_CmdStart, "CmdStart");
	register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)
	set_task(7.0, "disable_flashlight");
	
	remove_entity_name("armoury_entity");
	remove_entity_name("env_sound");
	remove_entity_name("game_player_equip");
	remove_entity_name("player_weaponstrip");

	RegisterHam(Ham_Player_PreThink, "player", "Ham_CBasePlayer_PreThink_Post", 1)
	RegisterHam(Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", 1)
	RegisterHam(Ham_Spawn, "player", "FwdHamPlayerSpawn", 1)
	RegisterHam(Ham_Touch, "weaponbox", "GroundWeapon_Touch")
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack");

	register_touch("iwan_route", "player", "SelectRoute");
	register_touch("vancy_cup", "player", "CupRoute");

	register_message(get_user_msgid("ScoreAttrib"), "MessageScoreAttrib")
	register_dictionary("kz.txt")
	get_pcvar_string(kz_chat_prefix, prefix, 31)

	get_pcvar_string(kz_stats_sound, statsz, 31)
	get_pcvar_string(kz_complete_sound, completez, 31)
	get_pcvar_string(kz_top1_sound, rankz, 31)
	//get_pcvar_string(kz_cps100_sound, cpsz, 31)
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	set_task(UPDATEINTERVALB, "timer_task",2000, "", 0, "ab")
	//set_task(7.0, "plugin_sql", TASK_CONNSQL, _, _, "b");
	set_task(0.2, "plugin_sql", TASK_CONNSQL);
	set_task(1.0, "TaskReadTop", TASK_CALLREADTOP, _, _, "b");
	set_task(1.0, "GetMore", TASK_GETMORE, _, _, "b");
	set_task(1.0, "GetCupRoute", TASK_GETCUPROUTE, _, _, "b");	// 获取起点
	if (get_pcvar_num(kz_issurf))
		set_task(1.0, "SetButton")

	set_task(0.1, "GroupDraw", _, _ , _ , "d");

	g_iMaxPlayers = get_maxplayers();

	register_clcmd("say /wr", "PutRecord")
	register_clcmd("say /cc", "PutRecord")
	register_clcmd("say /cr", "PutRecord")
	register_clcmd("say /showhelp", "ShowHelp")
	register_clcmd("amx_yh", "yhextend")

	get_mapname(e_MapName, 63)
	strtolower(e_MapName)

	new kreedz_cfg[128], ConfigDir[64]
	get_configsdir(ConfigDir, 64)
	formatex(Kzdir,128, "%s/kz", ConfigDir)
	if (!dir_exists(Kzdir))
		mkdir(Kzdir)
	
	#if !defined USE_SQL
	formatex(Topdir,128, "%s/top15", Kzdir)
	if (!dir_exists(Topdir))
		mkdir(Topdir)

	//创建top缓存文件
	formatex(STATUS_PATH, 99, "%s/climb_status.html", Kzdir)
	formatex(NUB_PATH, 99, "%s/nub_top.html", Kzdir)
	formatex(PRO_PATH, 99, "%s/pro_top.html", Kzdir)
	formatex(RDS_PATH, 99, "%s/Rewards.html", Kzdir)
	#endif
	
	/*formatex(SavePosDir, 128, "%s/savepos", Kzdir)
	if (!dir_exists(SavePosDir))
		mkdir(SavePosDir)*/
    
	formatex(kreedz_cfg,128, "%s/kreedz.cfg", Kzdir)
        
	if (file_exists(kreedz_cfg))
	{
		server_exec()
		server_cmd("exec %s",kreedz_cfg)
	}
	
	for (new i = 0; i < sizeof(g_block_commands); i++)
		register_clcmd(g_block_commands[i], "BlockBuy")

	g_tStarts = TrieCreate()
	g_tStops  = TrieCreate()

	new const szStarts[10][21] =
	{
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo", "some_noob"
	}

	new const szStops[][]  =
	{
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	}
	
	if (equali(MapName, "kz_a2_bhop_corruo_ez")
    ||  equali(MapName, "kz_a2_bhop_corruo_h")
    ||  equali(MapName, "kz_a2_godspeed"))
        RegisterHam(Ham_Touch, "func_button", "FwdHamButtonTouch")
	else
	{ 
		if (equali(MapName, "kz_cup_start_storage"))
			g_flStartDelay = 5.0; 

		RegisterHam(Ham_Use, "func_button", "fwdUse", 0)
	}

	for (new i = 0; i < sizeof szStarts; i++)
	{
		if (szStarts[i][0] != 0x0)
			TrieSetCell(g_tStarts, szStarts[i], 1)
	}

	for (new i = 0; i < sizeof szStops; i++)
		TrieSetCell(g_tStops, szStops[i], 1)

	get_mapname(MapName, 63)
	// 锁定武器右键
	//new szWeaponName[20]
	//for (new i=CSW_P228; i<=CSW_P90; i++)
		//if (get_weaponname(i, szWeaponName, charsmax(szWeaponName)))
		
	for (new i = 0; i < OTHER_WPN_SIZE; i++)
	{
		RegisterHam(Ham_Weapon_PrimaryAttack, other_weapons_name[i], "Weapons_Deploy", true)// block scout
		RegisterHam(Ham_Item_Deploy, other_weapons_name[i], "Weapons_Deploy", true)	// block scout
	}

//	PLUGIN_CHECK
}

#if defined USE_SQL
public plugin_sql()
{
	/*new SQL_ADDR[64];
	new SQL_USER[64];
	new SQL_PASS[64];
	Decode(SQL_ADDR, g_TOP_SQL_ADDR, sizeof g_TOP_SQL_ADDR, 63);
	Decode(SQL_USER, g_TOP_SQL_USER, sizeof g_TOP_SQL_USER, 63);
	Decode(SQL_PASS, g_TOP_SQL_PASS, sizeof g_TOP_SQL_PASS, 63);

	g_SqlTuple = SQL_MakeDbTuple(SQL_ADDR, SQL_USER, SQL_PASS, "iwan", 5);*/
	g_SqlTuple = SQL_MakeDbTuple(SQL_ADDR, SQL_USER, SQL_PASS, SQL_DB, 5);

	g_SqlReady = false;

	new ErrorCode
	g_SqlConnection = SQL_Connect(g_SqlTuple, ErrorCode, g_Error, 511);
	
	if (!g_SqlConnection)
	{
		plugin_status = false
		g_SqlReady = false;
		set_task(5.0, "plugin_sql", TASK_CONNSQL);
	}
	else
	{
		if (task_exists(TASK_CONNSQL))
			remove_task(TASK_CONNSQL);
		g_SqlReady = true;
	}
	return PLUGIN_CONTINUE
}

public QueryHandle(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if (iFailState != TQUERY_SUCCESS)
	{
		log_amx("[KZ] TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
		ColorChat(0, GREEN, "^4[KZ]^1: Warning the SQL Tops can not be saved.")
	}

	return PLUGIN_CONTINUE
}
#endif

public plugin_precache()
{
	RegisterHam(Ham_Spawn, "func_door", "FwdHamDoorSpawn", 1)
	//precache_sound("weapons/xbow_hit2.wav")
	Sbeam = precache_model("sprites/laserbeam.spr")

	//plugin_sql();
	//plugin_readyroute();
	//plugin_readybutton();
	//plugin_readyads();
	precache_model(KZ_ROUTEMDL);
	g_nTga=1;
	copy(g_szTga[0], 126, "gfx/97Club/97club.tga");
	precache_generic("gfx/97Club/97club.tga");
	//下载声音文件
	for (new File = 0; File < sizeof(dlFilesList); File++)
		precache_sound(dlFilesList[File]);
}

public plugin_readyads()
{
	static szQuery[] = "SELECT filename FROM kz_specads WHERE available = '1' AND (type = 'kz' OR type = '')"

	new Handle:hQuery = SQL_PrepareQuery(g_SqlConnection, szQuery);
	SQL_Execute(hQuery);

	while (SQL_MoreResults(hQuery))
	{
		SQL_ReadResult(hQuery, 0, g_szTga[g_nTga], 127)
		if (g_szTga[g_nTga][0] != 0x0)
		{
			precache_generic(g_szTga[g_nTga]);
			if (g_nTga++ > 10)
				break;
		}
		SQL_NextRow(hQuery)
	}

	SQL_FreeHandle(hQuery);
}

/*public plugin_readyroute()
{
	new szQuery[256];
	format(szQuery, 255, "SELECT * FROM kz_maproute WHERE mapname = '%s' ORDER BY SEQNO", MapName);
	
	new Handle:hQuery = SQL_PrepareQuery(g_SqlConnection, szQuery);
	SQL_Execute(hQuery);

	if (SQL_NumResults(hQuery) > 0)
	{
		precache_model(KZ_ROUTEMDL);
	}

	SQL_FreeHandle(hQuery);
}*/

/*public plugin_readybutton()
{
	new szQuery[256]
	format(szQuery, 255, "SELECT * FROM kz_surfbutton WHERE mapname = '%s'", MapName)

	new Handle:hQuery = SQL_PrepareQuery(g_SqlConnection, szQuery);
	SQL_Execute(hQuery);

	if (SQL_NumResults(hQuery) > 0)
	{
		precache_model(KZ_SURFSTART)
		precache_model(KZ_SURFSTOP)
	}

	SQL_FreeHandle(hQuery);
}*/

public plugin_end()
{
	TrieDestroy(g_tStarts); 
	TrieDestroy(g_tStops);
	if (g_SqlTuple)
        SQL_FreeHandle(g_SqlTuple)
}

public check_sql_name()
{
	if (g_szServer[0] == 0x0)
	{
		//server_cmd("exec addons/amxmodx/configs/amxx.cfg");
		if (g_szHotMap[0] != 0x0)
		{
			server_cmd("changelevel %s", g_szHotMap);
		}
		else
		{
			server_cmd("restart");
		}
	}
}

public SetAds(id)
{
	new index = random_num(0, g_nTga - 1);

	// send show tga command to client
	message_begin(MSG_ONE, SVC_DIRECTOR, _, id);
	write_byte(strlen(g_szTga[index]) + 2);
	write_byte(DRC_CMD_BANNER);
	write_string(g_szTga[index]);
	message_end();
}

public GetCupRoute(id)
{
	if (!g_SqlReady)
		return PLUGIN_HANDLED;

	if (task_exists(id))
		remove_task(id);

	if (IsPlayer(id) && !(get_user_flags(id) & ADMIN_CFG))
		return PLUGIN_HANDLED
	new cData[3]
	cData[ACTION] = GETCUPROUTE

	new szQuery[256]
	format(szQuery, 255, "SELECT * FROM kz_maproute WHERE mapname = '%s' AND route = 'vancy_cup' ORDER BY SEQNO", MapName)
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3)
	return PLUGIN_HANDLED
}

public SyncData(sql_result)
{
	new szQuery[256];
	new configdir[128];
	get_configsdir(configdir, 127);
	format(g_szSpawnFile, 255,"%s/spawns/%s_spawns.cfg", configdir, MapName);
	server_print("====find spawns sql_result[%d]", sql_result);
	if (file_exists(g_szSpawnFile) && sql_result > 0)
	{
		server_print("====find spawns both > 0");
		return;
	}
	else if (sql_result > 0)
	{
		new cData[3]
		cData[ACTION] = SYNC_SPAWN_DATA;

		format(szQuery, 255, "SELECT * FROM kz_spawn WHERE mapname = '%s'", MapName);
		SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);
		server_print("====find spawns sql_result > 0");
	}
	else if (file_exists(g_szSpawnFile))
	{
		new Data[128], len, line = 0, index = 0;
		new team[8], p_origin[3][8], p_angles[3][8];
		server_print("====find spawns file_exists > 0");

		while ((line = read_file(g_szSpawnFile , line , Data , 127 , len) ) != 0)
		{
			if (strlen(Data) < 2)
				continue;

			parse(Data, team,7, p_origin[0],7, p_origin[1],7, p_origin[2],7, p_angles[0],7, p_angles[1],7, p_angles[2],7)

			format(szQuery, 255, "INSERT INTO kz_spawn VALUES ('%s','%s',%d,%s,%s,%s,%s,%s,%s)", MapName, team, index++,
				p_origin[0], p_origin[1], p_origin[2], p_angles[0], p_angles[1], p_angles[2]);
			SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
		}

		if (index > 0)
		{
			server_print("====================SyncSpawnFileToSql[%d]", index);
		}
	}
}

public plugin_cfg()
{
	#if !defined USE_SQL
	for (new i = 0 ; i < num; ++i)
	{
		Pro_Times[i] = 999999999.00000;
		Noob_Tiempos[i] = 999999999.00000;
	}

	read_pro15()
	read_Noob15()
	#endif

	new ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_water")) != 0)
	{
		if (!gWaterFound)
		{
			gWaterFound = true;
		}

		if (ent > -1)
			gWaterEntity[ent] = true;
	}
	
	ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_illusionary")) != 0)
	{
		if (pev(ent, pev_skin) ==  CONTENTS_WATER)
		{
			if (!gWaterFound)
			{
				gWaterFound = true;
			}

			if (ent > -1)
				gWaterEntity[ent] = true;
		}
	}

	ent = -1;
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_conveyor")) != 0)
	{
		if (pev(ent, pev_spawnflags) == 3)
		{
			if (!gWaterFound)
			{
				gWaterFound = true;
			}

			if (ent > -1)
				gWaterEntity[ent] = true;
		}
	}
}

public disable_flashlight()
{
	server_cmd("mp_flashlight 0");
}

public CmdStart(id, uc_handle, seed)
{
	if (get_cvar_num("mp_flashlight") == 0)
		if (get_uc(uc_handle, UC_Impulse) == 100)
			ToggleNVG(id);
}

public client_command(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	new sArg[13];
	if (read_argv(0, sArg, 12)> 11)
		return PLUGIN_CONTINUE;
	
	for (new i = 0; i < sizeof(g_weaponsnames); i++)
		if (equali(g_weaponsnames[i], sArg, 0))
			return PLUGIN_HANDLED;

	return PLUGIN_CONTINUE;
}

public Event_Damage(id)
{
	new hp = get_user_health(id)
	if (hp > 255 && (hp % 256) == 0)
		set_user_health(id, ++hp)
	//set_hudmessage(255, 200, 0, 0.03, 0.91, 0, 3.0, 3.0, 0.1, 1.5)
	//show_lang_hudmessage(id, "Damage %d HP %i", read_data(2),health);
	return PLUGIN_CONTINUE
}

/*
public message_Health(msgid, dest, id)
{
	if (!is_user_alive(id))
		return PLUGIN_CONTINUE;

	static hp;
	hp = get_msg_arg_int(1);

	if (hp > 255 && (hp % 256) == 0)
		set_msg_arg_int(1, ARG_BYTE, ++hp);

	return PLUGIN_CONTINUE;
}*/

//游戏类型
public changeGameClass()
{
	new GameClass[64];
	if (get_pcvar_num(kz_cup) == 0)
		formatex(GameClass, 64, "KZ v%s", VERSION)
	else
		formatex(GameClass, 64, "CUP v%s", "1.1.0.0086")
	forward_return(FMV_STRING, GameClass)

	return FMRES_SUPERCEDE
}
// =================================================================================================
// Global Functions
// =================================================================================================

public Pause(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_HANDLED;

	if (get_pcvar_num(kz_pause) == 0)
	{	
		kz_chat(id, "%L", id, "DISABLE_FUNCTION")
		
		return PLUGIN_HANDLED
	}
	
	if (g_bAccepting[id])
	{
		kz_chat(id, "%L", id, "HAVE_TO_CHOICE");
		return PLUGIN_HANDLED
	}
	
	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_PAUSE_SPEC");
		return PLUGIN_HANDLED
	}
	
	static entname[33];
	pev(pev(id, pev_groundentity), pev_classname, entname, 32)
	if (equal(entname, "func_door"))
	{
		kz_chat(id, "%L", id, "CANT_PAUSE_BHOP")
		return PLUGIN_HANDLED
	}

	if (!IsPaused[id])
	{
		if (!timer_started[id])
		{
			kz_chat(id, "%L", id, "CANT_PAUSE_NO_START")
			return PLUGIN_HANDLED
		}

		g_pausetime[id] = get_gametime() - timer_time[id]
		g_pausetimed[id] = get_gametime() - timer_timed[id] //理论时间
		g_pausestime[id] = get_gametime() - timer_stime[id][g_bCpAlternate[id] ? 1 : 0]//理论时间
		g_pausestimez[id] = get_gametime() - timer_stime[id][ !g_bCpAlternate[id] ]//理论时间
		timer_timed[id] = timer_time[id] = 0.0 //理论时间
		timer_time[id] = 0.0
		timer_stime[id][g_bCpAlternate[id] ? 1 : 0] = 0.0//理论时间
		timer_stime[id][ !g_bCpAlternate[id] ] = 0.0//理论时间
		IsPaused[id] = true
		kz_chat(id, "%L", id, "PAUSE_TIMER_TTL")
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
		pev(id, pev_origin, PauseOrigin[id])
		climber_status[id] = STATUS_PAUSED
			
	}
	else
	{
		if (timer_started[id])
		{
			kz_chat(id, "%L", id, "UNPAUSE_TIMER_TTL")
			if (get_user_noclip(id))
				noclip(id)
			timer_time[id] = get_gametime() - g_pausetime[id] 
			timer_timed[id] = get_gametime() - g_pausetimed[id] + timer_timed[id] //理论时间
			timer_stime[id][g_bCpAlternate[id] ? 1 : 0] = get_gametime() - g_pausestime[id] //理论时间
			timer_stime[id][ !g_bCpAlternate[id] ] = get_gametime() - g_pausestimez[id] //理论时间
			climber_status[id] = STATUS_CLIMBING
		}
		IsPaused[id] = false
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
		set_pev(id, pev_origin, PauseOrigin[id])
	}

	return PLUGIN_HANDLED
}

public timer_task()
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return;

	if (get_pcvar_num(kz_show_timer) > 0)
	{
		new Alive[32], Dead[32], alivePlayers, deadPlayers;
		get_players(Alive, alivePlayers, "ach")
		get_players(Dead, deadPlayers, "bch")
		for (new i=0;i<alivePlayers;i++)
		{
			if (timer_started[Alive[i]])
			{
				new Float:kreedztime = get_gametime()- (IsPaused[Alive[i]] ? get_gametime()- g_pausetime[Alive[i]] : timer_time[Alive[i]])
				new Float:kreedztimed = get_gametime()- (IsPaused[Alive[i]] ? get_gametime()- g_pausetimed[Alive[i]] : timer_timed[Alive[i]])//理论时间

				if (ShowTime[Alive[i]] == 1)
				{
					new colors[12], r[4], g[4], b[4];
					new imin = floatround(kreedztime / 60.0,floatround_floor)
					new isec = floatround(kreedztime - imin * 60.0,floatround_floor)
					new imind = floatround(kreedztimed / 60.0,floatround_floor)//理论时间
					new isecd = floatround(kreedztimed - imind * 60.0,floatround_floor)//理论时间
					get_pcvar_string(kz_hud_color, colors, 11)
					parse(colors, r, 3, g, 3, b, 4)

					set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.00, 0, 0.0, 1.0, 0.0, 0.0, -1)
					show_lang_hudmessage(Alive[i], "%L", Alive[i], "SPEC_HUD_TIMER", imin, isec, imind, isecd)
				}
				else
				if (ShowTime[Alive[i]] == 2)
				{
					kz_showtime_roundtime(Alive[i], floatround(kreedztime))
				}
			}
		}

		new colors[12], r[4], g[4], b[4];
		get_pcvar_string(kz_hud_color, colors, 11);
		parse(colors, r, 3, g, 3, b, 4);

		for (new i = 0; i < deadPlayers; i++)
		{
			new id = Dead[i];
			new specmode = pev(id, pev_iuser1)
			if (specmode == 2 || specmode == 4)
			{
				new target = pev(id, pev_iuser2);
				if (target != id)
					if (is_user_alive(target))
					{
						new Opponent, OpponentInfo[64];
						new nGroupId = g_nGroupId[target];
						if (nGroupId > 0)
						{
							if (g_nGroupPeople[nGroupId][SENDER] == target)
								Opponent = g_nGroupPeople[nGroupId][RECVER];
							else
								Opponent = g_nGroupPeople[nGroupId][SENDER];
							formatex(OpponentInfo, 63, "%L", id, "SPEC_HUD_CHL_OPPO", g_nPeopleName[Opponent]);
						}

						if (timer_started[target])
						{
							new Float:kreedztime = get_gametime()- (IsPaused[target] ? get_gametime()- g_pausetime[target] : timer_time[target])
							new Float:kreedztimed = get_gametime()- (IsPaused[target] ? get_gametime()- g_pausetimed[target] : timer_timed[target])//理论时间
							new imin = floatround(kreedztime / 60.0,floatround_floor)
							new isec = floatround(kreedztime - imin * 60.0,floatround_floor)
							new imind = floatround(kreedztimed / 60.0,floatround_floor)//理论时间
							new isecd = floatround(kreedztimed - imind * 60.0,floatround_floor)//理论时间

							set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), 0.02, 0.14, 0, 0.0, UPDATEINTERVALB + 0.1, 0.0, 0.0, -1)
							
							//show_lang_hudmessage(Dead[i], "[%s] 时间:%02d:%02d 理论时间:%02d:%02d 完成%d次 %s%s", (checknumbers[target] > 0 ? "存点" : "裸跳"), imin, isec, imind, isecd, (checknumbers[target] > 0 ? nubcount[target] : procount[target]), (IsPaused[target] ? " *暂停中*" : ""), OpponentInfo);
							show_lang_hudmessage(id, "[%L] %L %L %L%s",
								id, (checknumbers[target] > 0 ? "CP" : "NC"),
								id, "SPEC_HUD_TIMER", imin, isec, imind, isecd,
								id, "DONE_COUNT", (checknumbers[target] > 0 ? nubcount[target] : procount[target]),
								id, (IsPaused[target] ? "SPEC_HUD_PAUSING" : "NULL"),
								OpponentInfo);
						}
						else if (nGroupId > 0)
						{
							set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), 0.02, 0.14, 0, 0.0, UPDATEINTERVALB + 0.1, 0.0, 0.0, -1)
							show_lang_hudmessage(id, "%s", OpponentInfo);
						}
					}
			}
		}
	}
}

// ============================ Block Commands ================================


public BlockRadio(id)
{
	if (get_pcvar_num(kz_use_radio) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockDrop(id)
{
	if (get_pcvar_num(kz_drop_weapons) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockBuy(id)
{
	return PLUGIN_HANDLED
}

public CmdRespawn(id)
{
	if (is_user_hltv(id))
		return PLUGIN_HANDLED;
	//if (get_user_team(id) == 3)
	//	return PLUGIN_HANDLED
	//else
	ExecuteHamB(Ham_CS_RoundRespawn, id)

	return PLUGIN_HANDLED;
}

public ChatHud(id)
{
	if (get_pcvar_num(kz_chatorhud) == 0)
	{
		return PLUGIN_CONTINUE
	}

	if (chatorhud[id] == -1)
		++chatorhud[id];

	++chatorhud[id];
	
	if (chatorhud[id] == 3)
		chatorhud[id] = 0;
	else
		kz_chat(id, "%L", id, "MSG_MODE_TTL", chatorhud[id] == 1 ? "Chat" : "HUD")

	return PLUGIN_HANDLED
}

stock IsNormal(id)
{
	return (user_use_wpn[id] == CSW_USP || user_use_wpn[id] == CSW_KNIFE) ? true : false
}

stock wpnspeed(id)
{
	for (new i = 0; i < OTHER_WPN_SIZE; i++)
		if (other_weapons[i] == user_use_wpn[id])
			return weapons_speeds[i]
	return 250
}

stock set_user_wpn(id, speed)
{
	for (new i = 0; i < OTHER_WPN_SIZE; i++)
		if (weapons_speeds[i] == speed)
			user_use_wpn[id] = other_weapons[i]
}

stock num_to_wpnname(name[], len, speed)
{
	for (new i = 0; i < OTHER_WPN_SIZE; i++)
		if (weapons_speeds[i] == speed)
			copy(name, len, g_weaponsnames[other_weapons[i]])
}

public set_user_weapons(id, wpn)
{
	if (!wpn || !is_user_alive(id))
		return PLUGIN_CONTINUE;

	new item;
	new wpnname[32];
	formatex(wpnname, 31, "weapon_%s", g_weaponsnames[wpn]);

	set_pev(id, pev_weapons, pev(id, pev_weapons) | (1 << 31));
	if (wpn == CSW_SCOUT)
	{
		if (pev(id, pev_weapons) != ((1 << CSW_KNIFE) | (1 << CSW_USP) | (1 << 31) | (1 << CSW_SCOUT)))
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			item = give_item(id, "weapon_usp");
			cs_set_weapon_ammo(item, 12);
			cs_set_user_bpammo(id, CSW_USP, 120);
			item = give_item(id, wpnname);
			cs_set_weapon_ammo(item, 0);
		}
	}
	else if (wpn == CSW_USP || wpn == CSW_KNIFE)
	{
		if (pev(id, pev_weapons) != ((1 << CSW_KNIFE) | (1 << CSW_USP) | (1 << 31)))
		{
			strip_user_weapons(id);
			give_item(id, "weapon_knife");
			item = give_item(id, "weapon_usp");
			cs_set_weapon_ammo(item, 12);
			cs_set_user_bpammo(id, CSW_USP, 120);
		}
	}
	else
	{
		if (pev(id, pev_weapons) != ((1 << wpn) | (1 << 31)))
		{
			strip_user_weapons(id);
			item = give_item(id, wpnname);
			cs_set_weapon_ammo(item, 15);
		}
	}
	/*
	strip_user_weapons(id);
	new item;
	new wpnname[32];
	formatex(wpnname, 31, "weapon_%s", g_weaponsnames[wpn]);

	if (wpn == CSW_SCOUT)
	{
		set_pev(id ,pev_weapons, pev(id, pev_weapons) & ~(1<<CSW_KNIFE));
		give_item(id, "weapon_knife");
		item = give_item(id, "weapon_usp");
		cs_set_weapon_ammo(item, 12);
		cs_set_user_bpammo(id, CSW_USP, 120);
		item = give_item(id, wpnname);
		cs_set_weapon_ammo(item, 0);
	}
	else if (wpn == CSW_USP || wpn == CSW_KNIFE)
	{
		set_pev(id, pev_weapons, (1<<CSW_KNIFE) + (1<<CSW_USP));
		if (!user_has_weapon(id, CSW_KNIFE) && is_user_alive(id))
			give_item(id, "weapon_knife")
		give_item(id, "weapon_knife");
		item = give_item(id, "weapon_usp");
		cs_set_weapon_ammo(item, 12);
		cs_set_user_bpammo(id, CSW_USP, 120);
	}
	else
	{
		set_pev(id, pev_weapons, (1<<wpn));
		item = give_item(id, wpnname);
		cs_set_weapon_ammo(item, 15);
	}*/

	return PLUGIN_CONTINUE
}

public ct(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, "%L", id, "CANT_CHG_TEAM_CHLING");
		return PLUGIN_HANDLED;
	}

	new noclip = get_user_noclip(id)
	if (noclip)
	{
		kz_chat(id, "%L", id, "CANT_CHG_TEAM_NOCLIP");
		return PLUGIN_HANDLED;
	}

	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_CT)
	{
		if (!(pev(id, pev_flags) & FL_ONGROUND2) && timer_started[id])
			return PLUGIN_HANDLED
		//防止mpbhop bug
		new szName[32];
		/*new userids = get_user_userid(id)*/
		get_user_name(id, szName, 31);
		static entname[33];
		pev(pev(id, pev_groundentity), pev_classname, entname, 32)

		if (equal(entname, "func_door"))
		{
			client_cmd(id, "say /reset")
			for (new i = 1; i <= g_iMaxPlayers; i++)
				if (is_user_connected(i))
					ColorChat(i, GREEN, "^4%s %L", prefix, i, "TRY_TO_BUG", szName)
			return PLUGIN_HANDLED
		}

		if (get_pcvar_num(kz_spec_saves) == 1)
		{
			pev(id, pev_origin, SpecLoc[id])

			if (timer_started[id])
			{
				if (IsPaused[id])
				{
					Pause(id)
					WasPaused[id]=true
				}

				g_pausetime[id] =   get_gametime() - timer_time[id]
				g_pausetimed[id] =   get_gametime() - timer_timed[id] //理论时间
				g_pausestime[id] = get_gametime() - timer_stime[id][g_bCpAlternate[id] ? 1 : 0]//理论时间
				g_pausestimez[id] = get_gametime() - timer_stime[id][ !g_bCpAlternate[id] ]//理论时间
				timer_time[id] = 0.0
				timer_timed[id] = timer_time[id] = 0.0 //理论时间
				timer_stime[id][0] = 0.0;//理论时间
				timer_stime[id][1] = 0.0;//理论时间

				kz_chat(id, "%L", id, "PAUSE_TIMER_TTL");
			}
		}

		if (gViewInvisible[id])
			gViewInvisible[id] = false	

		JoinSpec(id);
	}
	else 
	{
		JoinCT(id);

		CtEx(id);
	}

	return PLUGIN_HANDLED
}

public CtEx(id)
{
	set_user_weapons(id, user_use_wpn[id])

	if (get_pcvar_num(kz_spec_saves) == 1)
	{
		set_pev(id, pev_flags, pev(id, pev_flags)| FL_DUCKING)
		set_pev(id, pev_origin, SpecLoc[id])
		if (timer_started[id])
		{
			timer_time[id] = get_gametime() - g_pausetime[id] + timer_time[id]
			timer_timed[id] = get_gametime() - g_pausetimed[id] + timer_timed[id] //理论时间
			timer_stime[id][g_bCpAlternate[id] ? 1 : 0] = get_gametime() - g_pausestime[id]//理论时间
			timer_stime[id][ !g_bCpAlternate[id] ] = get_gametime() - g_pausestimez[id]//理论时间
		}

		if (WasPaused[id])
		{
			Pause(id)
			WasPaused[id]=false
		}
	}
}

//=================== Weapons ==============
public curweapon(id)
{ 
/*
	if (get_pcvar_num(kz_maxspeedmsg) == 1 && is_user_alive(id))
	{
		new clip, ammo, speed, 
 		switch(get_user_weapon(id,clip,ammo))
		{
			case CSW_SCOUT: speed = 260
			case CSW_C4, CSW_P228, CSW_MAC10, CSW_MP5NAVY, CSW_USP, CSW_TMP, CSW_FLASHBANG, CSW_DEAGLE, CSW_GLOCK18, CSW_SMOKEGRENADE, CSW_ELITE, CSW_FIVESEVEN, CSW_UMP45, CSW_HEGRENADE, CSW_KNIFE:   speed = 250
			case CSW_P90:   speed = 245
			case CSW_XM1014, CSW_AUG, CSW_GALIL, CSW_FAMAS: speed = 240
			case CSW_SG552:  speed = 235
			case CSW_M3, CSW_M4A1:   speed= 230
			case CSW_AK47:   speed = 221
			case CSW_M249:   speed = 220
			case CSW_G3SG1, CSW_SG550, CSW_AWP: speed = 210				
  		}
		kz_hud_message(id, "%L",id, "KZ_WEAPONS_SPEED",speed)
	}
 */
	if (!g_lockcurwpnchk[id])
		return PLUGIN_HANDLED

 	static last_weapon[33]
	static weapon_active, weapon_num
	weapon_active = read_data(1)
	weapon_num = read_data(2)
	
	new wpnspeed2
	if (user_use_wpn[id])
		wpnspeed2 = wpnspeed(id)
	
 	if ((weapon_num != last_weapon[id]) && weapon_active && get_pcvar_num(kz_maxspeedmsg) == 1)
	{
		last_weapon[id] = weapon_num

		static Float:maxspeed
		pev(id, pev_maxspeed, maxspeed)
		
		if (maxspeed < 0.0)
			maxspeed = 250.0

		new curspeed = floatround(maxspeed, floatround_floor)
		if (wpnspeed2 < curspeed && user_use_wpn[id] && timer_started[id])
		{
			new type[10];
			if (curspeed == 250)
				formatex(type, 9, "%L", id, "TOP_NORMAL");
			else
				formatex(type, 9, "%L", id, "WEAPON");

			ColorChat(id, RED, "^4%s %L", prefix, id, "TOP_MOD_CHG", type);
			ColorChat(id, RED, "^4%s %L", prefix, id, "TOP_MOD_CHG", type);
			set_user_wpn(id, curspeed);
		}
		kz_hud_message(id, "%L%d", id, "WEAPON_SPEED", curspeed);
	}
	return PLUGIN_HANDLED
}

public weapons(id)	// 发枪
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANTGET_WPN_SEPC");
		return PLUGIN_HANDLED
	}
	
	if (get_pcvar_num(kz_other_weapons) == 0)
	{	
		kz_chat(id, "%L", id, "CANTGET_WPN_DISABLE");
		return PLUGIN_HANDLED
	}
	
	if (timer_started[id])
	{
		ColorChat(id, RED, "^4%s %L", prefix, id, "CANTGET_WPN_ONTIME");
		ColorChat(id, RED, "^4%s %L", prefix, id, "CANTGET_WPN_ONTIME");
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item;
	for (new i = 0; i < OTHER_WPN_SIZE; i++)
	{
		item = give_item(id, other_weapons_name[i]);
		cs_set_weapon_ammo(item, 0);
	}
					
	give_item(id, "weapon_usp")
	item = give_item(id, "weapon_knife")
	cs_set_weapon_ammo(item, 0);

	ColorChat(id, GREEN, "^4%s %L", prefix, id, "TOP_WPN_TTL");
	ColorChat(id, GREEN, "^4%s %L", prefix, id, "TOP_WPN_TTL");

	return PLUGIN_HANDLED
}

// ========================= 武器 =======================
public cmdAwp(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, g_cangetwpn)
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item = give_item(id, "weapon_awp")
	cs_set_weapon_ammo(item, 0)

	ColorChat(id, RED, "^4%s %L", prefix, id, "USE_OTHER_WPN_TTL");
	return PLUGIN_HANDLED
}

public cmdM249(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, g_cangetwpn)
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item = give_item(id, "weapon_m249")
	cs_set_weapon_ammo(item, 0)

	ColorChat(id, RED, "^4%s %L", prefix, id, "USE_OTHER_WPN_TTL");
	return PLUGIN_HANDLED
}

public cmdM4a1(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, g_cangetwpn)
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item = give_item(id, "weapon_m4a1")
	cs_set_weapon_ammo(item, 0)

	ColorChat(id, RED, "^4%s %L", prefix, id, "USE_OTHER_WPN_TTL");
	return PLUGIN_HANDLED
}

public cmdFamas(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, g_cangetwpn)
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item = give_item(id, "weapon_famas")
	cs_set_weapon_ammo(item, 0)

	ColorChat(id, RED, "^4%s %L", prefix, id, "USE_OTHER_WPN_TTL");
	return PLUGIN_HANDLED
}

public cmdUsp(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (timer_started[id])
	{
		kz_chat(id, g_cangetwpn)
		return PLUGIN_HANDLED
	}

	strip_user_weapons(id)
	new item = give_item(id, "weapon_usp")
	give_item(id, "weapon_knife")
	cs_set_weapon_ammo(item, 0)
	
	return PLUGIN_HANDLED
}

public cmdScout(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, g_szGroupStart);
		return PLUGIN_HANDLED
	}

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, "%L", id, "CANTGET_WPN_CHLING");
		return PLUGIN_HANDLED;
	}

	user_use_wpn[id] = CSW_SCOUT;
	set_user_weapons(id, user_use_wpn[id]);

	ColorChat(id, RED, "^4%s %L", prefix, id, "USE_OTHER_WPN_TTL");
	return PLUGIN_HANDLED;
}

public cmdMulLang(id)
{
	new menu = menu_create("\r多语言切换(Multi-language)", "mullang_menu_handler");

	menu_additem(menu, "中文");
	menu_additem(menu, "Englist");
	menu_additem(menu, "Waiting for you to translate.");

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public mullang_menu_handler(id, menu, item)
{
	switch (item)
	{
		case 0:
		{
			client_cmd(id, "setinfo lang cn");
		}
		case 1:
		{
			client_cmd(id, "setinfo lang en");
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
// ========================== Start location =================

public goStart(id)
{
	if (is_user_hltv(id))
		return PLUGIN_HANDLED;
		
	if (get_pcvar_num(kz_cup_start) == 0)
	{
		/*
		if (!is_user_alive(id))
		{
			new szTeamClass[2]
			formatex(szTeamClass, 1, "%d", random_num(1, 4))
			engclient_cmd(id, "jointeam", "2")
			engclient_cmd(id, "joinclass", szTeamClass)
		}*/
		
		if (gHooked[id])
		{
			kz_chat(id, "%L", id, "CANT_BACKSTART_HOOKING");
			return PLUGIN_HANDLED
		}

		if (IsPaused[id])
		{
			kz_chat(id, "%L", id, "CANT_BACKSTART_PAUSING");
			return PLUGIN_HANDLED
		}
	}

	new Float:TargetPos[3]
	if (get_pcvar_num(kz_cup_start) == 1)
		TargetPos = DefaultStartPos
	else if (ProStart[id][0] && g_nGroupId[id] == 0)
	{
		TargetPos = ProStart[id]
		reset_checkpoints(id)
	}
	else if (get_pcvar_num(kz_save_autostart) == 1 && AutoStart[id])
		TargetPos = SavedStart[id]
	else if (DefaultStart)
		TargetPos = DefaultStartPos
	else
	{
		kz_chat(id, "%L", id, "CANT_BACKSTART_NOSET");
		return PLUGIN_HANDLED
    }

	if (get_pcvar_num(kz_cup_start) == 0 && !is_user_alive(id))
		CmdRespawn(id);

	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
	set_pev(id, pev_flags, pev(id, pev_flags)| FL_DUCKING)
	set_pev(id, pev_origin, TargetPos)

	kz_chat(id, "%L", id, "BACK_START");

	return PLUGIN_HANDLED
}

public setStart(id)
{
	if (!(get_user_flags(id) & KZ_LEVEL))
	{
		kz_chat(id, "%L", id, "NOT_ACCESS");
		return PLUGIN_HANDLED
	}

	new Float:origin[3]
	pev(id, pev_origin, origin)
	kz_set_start(DefaultStart == true ? UPDSTART : SETSTART, origin)
	AutoStart[id] = false;

	return PLUGIN_HANDLED
}

public SetProStart(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	pev(id, pev_origin, ProStart[id])
	ColorChat(id, GREEN, "^4%s %L", prefix, id, "TEMP_START_SAVE");

	return PLUGIN_HANDLED
}

public ClearProStart(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	ProStart[id][0] = 0.0
	ColorChat(id, GREEN, "^4%s %L", prefix, id, "TEMP_START_CLEAR");

	return PLUGIN_HANDLED
}

// ========= Respawn CT if dies ========

public Ham_CBasePlayer_Killed_Post(id)
{
	if (get_pcvar_num(kz_respawn_ct) == 1)
	{
		if (cs_get_user_team(id) == CS_TEAM_CT)
		{
			set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
   			cs_set_user_deaths(id, 0)
			set_user_frags(id, 0)
			g_lockcurwpnchk[id] = false
			set_task(1.0, "ReChkCurWpn", id + TASK_LOCKCURWPNCHK)
		}
	}
}

public ReChkCurWpn(taskid)
{
	new id = taskid - TASK_LOCKCURWPNCHK
	g_lockcurwpnchk[id] = true
}
// =============================  NightVision ================================================

public ToggleNVG(id)
{

	if (get_pcvar_num(kz_nvg) == 0/* || !is_user_alive(id)*/)//去掉判断是否活着观察模式也能开夜视仪
		return PLUGIN_CONTINUE;
   
	if (NightVisionUse[id])
		StopNVG(id)
	else
		StartNVG(id)

	return PLUGIN_HANDLED
}

public StartNVG(id)
{
	//emit_sound(id, CHAN_ITEM, "items/nvg_on.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.1, "RunNVG", id + TASK_NVG, _, _, "b")
	NightVisionUse[id] = true
   
	return PLUGIN_HANDLED
}

public StopNVG(id)
{
	//emit_sound(id, CHAN_ITEM, "items/nvg_off.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	remove_task(id + TASK_NVG)
	NightVisionUse[id] = false

	return PLUGIN_HANDLED
}


public RunNVG(taskid)
{
	new id = taskid - TASK_NVG
  
	/*if (!is_user_alive(id))return*/
   
	new origin[3] 
	get_user_origin(id,origin, 3)
   
	new color[17];
	get_pcvar_string(kz_nvg_colors, color, 16)
   
	new iRed[5], iGreen[7], iBlue[5]
	parse(color, iRed, 4, iGreen ,6, iBlue, 4)
   
	message_begin(MSG, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(80)
	write_byte(str_to_num(iRed))
	write_byte(str_to_num(iGreen))
	write_byte(str_to_num(iBlue))
	write_byte(2)
	write_byte(0)
	message_end()
}

// ============================ Hook ==============================================================

public give_hook(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (!( get_user_flags(id) & KZ_LEVEL))
		return PLUGIN_HANDLED

	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if (equal(szarg2, "on"))
		mode = true
		
	if (equal(szarg1, "@ALL"))
	{
		new Alive[32], alivePlayers
		get_players(Alive, alivePlayers, "ach")
		for (new i;i<alivePlayers;i++)
		{
			canusehook[i] = mode
			if (mode)
				ColorChat(i, GREEN, "^4%s %L", prefix, i, "GET_HOOK_TTL");
		}
	}
	else
	{
		new pid = find_player("bl",szarg1);
		if (pid > 0)
		{
			canusehook[pid] = mode
			if (mode)
			{
				ColorChat(pid, GREEN, "^4%s %L", prefix, pid, "GET_HOOK_TTL");
			}
		}
	}

	return PLUGIN_HANDLED
}

public hook_on(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (!canusehook[id] && !(get_user_flags(id) & KZ_LEVEL) || !is_user_alive(id) || g_nGroupId[id] > 0)
		return PLUGIN_HANDLED

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "CANT_HOOK_PAUSING");
		return PLUGIN_HANDLED
	}

	detect_cheat(id, "%L", id, "USE_HOOK_TTL");
	get_user_origin(id,hookorigin[id],3)
	ishooked[id] = true
	anticheat[id] = get_gametime()

	//if (get_pcvar_num(kz_hook_sound) == 1)
	//	emit_sound(id,CHAN_STATIC, "weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

	set_task(0.1, "hook_task", id, "",0, "ab")
	hook_task(id);
	gHooked[id] = true;

	return PLUGIN_HANDLED
}

public hook_off(id)
{
	if (ishooked[id] == true)
		anticheat[id] = get_gametime()
	remove_hook(id);
	gHooked[id] = false;

	return PLUGIN_HANDLED
}

public hook_task(id)
{
	if (!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id)

	remove_beam(id)
	draw_hook(id)
	
	new origin[3], Float:velocity[3]
	get_user_origin(id,origin)
	new distance = get_distance(hookorigin[id],origin)
	velocity[0] = (hookorigin[id][0] - origin[0])* (2.0 * get_pcvar_num(kz_hook_speed)/ distance)
	velocity[1] = (hookorigin[id][1] - origin[1])* (2.0 * get_pcvar_num(kz_hook_speed)/ distance)
	velocity[2] = (hookorigin[id][2] - origin[2])* (2.0 * get_pcvar_num(kz_hook_speed)/ distance)
		
	set_pev(id,pev_velocity,velocity)
}

public draw_hook(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id][0])		// origin
	write_coord(hookorigin[id][1])		// origin
	write_coord(hookorigin[id][2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise					
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,255))		// g
	write_byte(random_num(1,255))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public remove_hook(id)
{
	if (task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id] = false
}

public remove_beam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99)// TE_KILLBEAM
	write_short(id)
	message_end()
}


//============================ VIP In ScoreBoard =================================================

public MessageScoreAttrib(iMsgID, iDest, iReceiver)
{
	if (get_pcvar_num(kz_vip))
	{
		new iPlayer = get_msg_arg_int(1)
		if (is_user_alive(iPlayer) && (get_user_flags(iPlayer) & KZ_LEVEL))
		{
			set_msg_arg_int(2, ARG_BYTE, SCOREATTRIB_VIP);
		}
	}
}

public EventStatusValue(const id)
{
			
	new szMessage[34], Target, aux;
	get_user_aiming(id, Target, aux);
	if (is_user_alive(Target))
	{
		formatex(szMessage, 33, "1 %L: %%p2", id, (get_user_flags(Target) & KZ_LEVEL ? "ADMIN" : "PLAERY"));
		message_begin(MSG, get_user_msgid("StatusText"), _, id)
		write_byte(0)
		write_string(szMessage)
		message_end()
	}
}

public detect_cheat(id, const message[], {Float,Sql,Result,_}:...)
{
	new msg[64];
	if (timer_started[id] && get_pcvar_num(kz_cheatdetect) == 1)
	{
		timer_started[id] = false;
		if (IsPaused[id])
		{
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
			IsPaused[id] = false
		}
		if (get_pcvar_num(kz_show_timer)> 0 && ShowTime[id] == 2)
			kz_showtime_roundtime(id, 0)
		climber_status[id] = STATUS_CHEAT//状态		
		vformat(msg, 179, message, 3);
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "RESET_TIMER_BY", msg);
	}
}
 
// =================================================================================================
// Cmds
// =================================================================================================

public CheckPoint(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_bAccepting[id])
	{
		kz_chat(id, "%L", id, "CANT_CP_CHLING");
		return PLUGIN_HANDLED;
	}

	if (g_nGroupId[id] > 0 && !g_nGroupPoint[g_nGroupId[id]])
	{
		kz_chat(id, "%L", id, "CANT_CP_GROUP");
		return PLUGIN_HANDLED;
	}

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_CP_SPEC");
		return PLUGIN_HANDLED;
	}

	if (!(pev(id, pev_flags) & FL_ONGROUND2) && !IsOnLadder(id))
	{
		kz_chat(id, "%L", id, "CANT_CP_AIR");
		return PLUGIN_HANDLED;
	}
		
	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "CANT_CP_PAUSING");
		return PLUGIN_HANDLED;
	}
	
	static entname[33];
	pev(pev(id, pev_groundentity), pev_classname, entname, 32)
	if (equal(entname, "func_door"))
	{
		kz_chat(id, "%L", id, "CANT_CP_BHOP");
		return PLUGIN_HANDLED;
	}

	pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id] ? 1 : 0])
	timer_stime[id][g_bCpAlternate[id] ? 1 : 0] = get_gametime() - g_pausestime[id];
	timer_save[id][g_bCpAlternate[id] ? 1 : 0] = get_gametime() - g_pausestime[id] - timer_timed[id];//理论时间

	g_bCpAlternate[id] = !g_bCpAlternate[id];
	checknumbers[id]++

	if (timer_started[id])
		kz_chat(id, "%L", id, "CP_COUNT", checknumbers[id]);
	else
		kz_chat(id, "%L", id, "CP_NOSTART");

	return PLUGIN_HANDLED
}

public GoCheck(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_GC_SPEC");
		return PLUGIN_HANDLED;
	}

	if (gHooked[id])
	{
		kz_chat(id, "%L", id, "CANT_GC_HOOK");
		return PLUGIN_HANDLED;
	}

	if (checknumbers[id] == 0)
	{
		kz_chat(id, "%L", id, "CANT_GC_NO_CP");
		return PLUGIN_HANDLED;
	}

	if (g_nGroupId[id] > 0 && !g_nGroupPoint[g_nGroupId[id]])
	{
		kz_chat(id, "%L", id, "CANT_GC_GROUP");
		return PLUGIN_HANDLED;
	}

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "CANT_GC_PAUSING");
		return PLUGIN_HANDLED;
	}
	
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_view_ofs, Float:{  0.0,  0.0, 12.0 });
	set_pev(id, pev_flags, pev(id, pev_flags)| FL_DUCKING);
	set_pev(id, pev_fuser2, 0.0);
	engfunc(EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 });
	set_pev(id, pev_origin, Checkpoints[id][!g_bCpAlternate[id]])
	//timer_timed[id]= timer_timed[id] + (get_gametime() - timer_stime[id][!g_bCpAlternate[id]]); //理论时间	
	//timer_stime[id][!g_bCpAlternate[id]] = get_gametime() - g_pausestimez[id]; //理论时间

	timer_timed[id] = get_gametime() - g_pausestimez[id] - timer_save[id][!g_bCpAlternate[id]];	//理论时间
	gochecknumbers[id]++;

	if (timer_started[id])
		kz_chat(id, "%L", id, "GC_COUNT", gochecknumbers[id])
	else
		kz_chat(id, "%L", id, "GC_NOSTART");

	g_pausestime[id] = 0.0;		//理论时间
	g_pausestimez[id] = 0.0;		//理论时间

	return PLUGIN_HANDLED
}

public Stuck(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_GC_SPEC");
		return PLUGIN_HANDLED
	}

	if (checknumbers[id] < 2)
	{
		kz_chat(id, "%L", id, "CANT_GC_LACK");
		return PLUGIN_HANDLED
	}

	if (gHooked[id])
	{
		kz_chat(id, "%L", id, "CANT_GC_HOOK");
		return PLUGIN_HANDLED;
	}

	if (g_nGroupId[id] > 0 && !g_nGroupPoint[g_nGroupId[id]])
	{
		kz_chat(id, "%L", id, "CANT_GC_GROUP");
		return PLUGIN_HANDLED;
	}

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "CANT_GC_PAUSING");
		return PLUGIN_HANDLED;
	}

	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_view_ofs, Float:{  0.0,  0.0, 12.0 });
	set_pev(id, pev_flags, pev(id, pev_flags)| FL_DUCKING);
	set_pev(id, pev_fuser2, 0.0);
	engfunc(EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 });
	set_pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id]])
	//timer_timed[id]= timer_timed[id] + (get_gametime() - timer_stime[id][g_bCpAlternate[id]]);	//理论时间	
	//timer_stime[id][g_bCpAlternate[id]] = get_gametime() - g_pausestimez[id];					//理论时间

	timer_timed[id] = get_gametime() - g_pausestimez[id] - timer_save[id][g_bCpAlternate[id]];	//理论时间
	gochecknumbers[id]++;

	if (timer_started[id])
		kz_chat(id, "%L", id, "GC_COUNT", gochecknumbers[id])
	else
		kz_chat(id, "%L", id, "GC_NOSTART");

	g_pausestime[id] = 0.0;		//理论时间
	g_pausestimez[id] = 0.0;		//理论时间
	
	return PLUGIN_HANDLED;
}
 
// =================================================================================================
 
public reset_checkpoints(id)
{
	if (get_pcvar_num(kz_cup_start) == 1 || !IsPlayer(id))
		return PLUGIN_CONTINUE;

	timer_started[id] = false
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	timer_time[id] = 0.0
	timer_timed[id] = 0.0 //理论时间
	if (IsPaused[id])
	{
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
		IsPaused[id] = false
	}

	if (get_pcvar_num(kz_show_timer)> 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)

	g_szSelRoute[id][0] = 0x0

	return PLUGIN_HANDLED
}

//===== Invis =======

public cmdInvisible(id)
{
	gViewInvisible[id] = !gViewInvisible[id]
	kz_chat(id, "%L %L", id, "INVIS_MODEL_PLAYER", id, (gViewInvisible[id] ? "ON" : "OFF"));

	return PLUGIN_CONTINUE
}

public cmdWaterInvisible(id)
{
	if (!gWaterFound)
	{
		kz_chat(id, "%L", id, "NO_WATER");
		return PLUGIN_HANDLED
	}
	
	gWaterInvisible[id] = !gWaterInvisible[id];
	kz_chat(id, "%L %L", id, "INVIS_MODEL_WATER", id, (gWaterInvisible[id] ? "ON" : "OFF"));
		
	return PLUGIN_CONTINUE
}

public cmdShowUID(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_A)
	{
		new name[32], authid[32];
		client_print(id, print_console, "==========================admin_kz_v1==========================^nUid    Steamid         Name");
		for (new i = 1; i < g_iMaxPlayers; i++)
		{
			if (is_user_connected(i) && g_nDzUid[i] > 0)
			{
				get_user_authid(i, authid, 31);
				get_user_name(i, name, 31);
				client_print(id, print_console, " %8d %16s %s", g_nDzUid[i], authid, name);
			}
		}
	}
	return PLUGIN_HANDLED
}

//======================Semiclip / Invis==========================

public FM_client_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{ 
	if (player)
	{
		if (get_pcvar_num(kz_semiclip) == 1)
		{
			if (host != ent && get_orig_retval() && is_user_alive(host))
    		{
				if (entity_range(host, ent) < 128)
				{
					set_es(es, ES_Solid, SOLID_NOT)
					set_es(es, ES_RenderMode, kRenderTransAlpha)
					set_es(es, ES_RenderAmt, 85);
				}
				else
				{
					set_es(es, ES_Solid, SOLID_SLIDEBOX);
				}
			} 
		}

		if (gMarkedInvisible[ent] && gViewInvisible[host])
		{
 		  	set_es(es, ES_RenderMode, kRenderTransTexture)
			set_es(es, ES_RenderAmt, 0)
			set_es(es, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 })
		}
	}
	else if (gWaterInvisible[host] && gWaterEntity[ent])
	{
		set_es(es, ES_Effects, get_es(es, ES_Effects)| EF_NODRAW)
	}
	
	return FMRES_IGNORED
} 

public Ham_CBasePlayer_PreThink_Post(id)
{ 
	if (!is_user_alive(id))
		return;

	RefreshPlayersList();

	if (get_pcvar_num(kz_semiclip) == 1)
	{
		for (new i = 0; i < g_iNum; i++)
		{ 
			g_iPlayer = g_iPlayers[i] 
			if (id != g_iPlayer)
			{
				set_pev(g_iPlayer, pev_solid, SOLID_NOT);
			}
		} 
	}
}

public client_PostThink(id)
{ 
	if (!is_user_alive(id))
		return

	RefreshPlayersList()

	if (get_pcvar_num(kz_semiclip) == 1)
		for (new i = 0; i<g_iNum; i++)
   		{ 
			g_iPlayer = g_iPlayers[i] 
			if (g_iPlayer != id)
				set_pev(g_iPlayer, pev_solid, SOLID_SLIDEBOX)
   		} 
} 

public noclip(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, "%L", id, "CANT_NC_CHLING");
		return PLUGIN_HANDLED;
	}

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_NC_SPEC");
		return PLUGIN_HANDLED;
	}

	new noclip = !get_user_noclip(id)

	set_user_noclip(id, noclip)

	if (IsPaused[id] && (get_pcvar_num(kz_noclip_pause) == 1))
	{
		if (noclip)
		{
			pev(id, pev_origin, NoclipPos[id])
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
		}
		else
		{
			set_pev(id, pev_origin, NoclipPos[id])
			set_pev(id, pev_flags, pev(id, pev_flags)| FL_FROZEN)
		}
	}
	else if (noclip)
		detect_cheat(id, "%L", id, "NOCLIP");
	kz_chat(id, "%L %L", id, "NOCLIP", id, (noclip ? "ON" : "OFF"));
    
	return PLUGIN_HANDLED
}

public GodMode(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	if (g_nGroupId[id] > 0)
	{
		kz_chat(id, "挑战中，不允许使用上帝模式");
		return PLUGIN_HANDLED;
	}

	if (!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "CANT_GOD_CHLING");
		return PLUGIN_HANDLED
	}
	
	new godmode = !get_user_godmode(id)
	set_user_godmode(id, godmode)
	if (godmode)
		detect_cheat(id, "%L", id, "GOD_MOD");
	kz_chat(id, "%L %L", id, "GOD_MOD", id, (godmode ? "ON" : "OFF"));
	
	return PLUGIN_HANDLED;
}
 
// =================================================================================================

public kz_set_start(oper_flag, Float:origin[3])
{
	DefaultStartPos = origin
	new cData[3]
	cData[ACTION] = oper_flag
	new szQuery[256]
	if (oper_flag == SETSTART)
		format(szQuery, 255, "INSERT INTO kz_startpos VALUES ('%s', %f, %f, %f)", MapName, origin[0], origin[1], origin[2])
	else
		format(szQuery, 255, "UPDATE kz_startpos SET x=%f, y=%f, z=%f WHERE mapname='%s'", origin[0], origin[1], origin[2], MapName)
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3)
}

stock kz_showtime_roundtime(id, time)
{
	if (is_user_connected(id))
	{
		message_begin(MSG, get_user_msgid("RoundTime"), _, id);
		write_short(time + 1);
		message_end();
	}
}

stock kz_chat(id, const message[], {Float,Sql,Result,_}:...)
{
	new cvar = get_pcvar_num(kz_chatorhud)
	if (cvar == 0)
		return PLUGIN_HANDLED
		
	new msg[180], final[192], i
	if (cvar == 1 && chatorhud[id] == -1 || chatorhud[id] == 1)
	{
		vformat(msg, 179, message, 3)
		formatex(final, 191, "%s ^1%s", prefix, msg)
		kz_remplace_colors(final, 191)
		ColorChat(id, GREEN, "^4%s", final)
	}
	else if (cvar == 2 && chatorhud[id] == -1 || chatorhud[id] == 2)
	{
			vformat(msg, 179, message, 3)
			i = strlen(msg)
			i -= replace_all(msg, i, "^1", "")
			i -= replace_all(msg, i, "^3", "")
			i -= replace_all(msg, i, "^4", "")
			i -= replace_all(msg, i, ".", "")
			kz_hud_message(id, "%s", msg)
	}
	
	return 1
}

stock kz_print_config(id, const msg[])
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, id);
	write_byte(id);
	write_string(msg);
	message_end();
}

stock kz_remplace_colors(message[], len)
{
	replace_all(message, len, "!g", "^4")
	replace_all(message, len, "!t", "^3")
	replace_all(message, len, "!y", "^1")
}

stock kz_hud_message(id, const message[], {Float,Sql,Result,_}:...)
{
	static msg[128], colors[12], r[4], g[4], b[4];
	vformat(msg, 127, message, 3);
	
	get_pcvar_string(kz_hud_color, colors, 11)
	parse(colors, r, 3, g, 3, b, 4)
	
	set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.91, 0, 0.0, 2.0, 0.0, 1.0, -1);
	show_lang_hudmessage(id, msg);
}

stock kz_dhud_message(id, Float:holdtime, Float:y, const message[], {Float,Sql,Result,_}:...)
{
	static msg[128];
	vformat(msg, 191, message, 5);

	replace_all(msg, 127, "!g", "");
	replace_all(msg, 127, "!t", "");
	replace_all(msg, 127, "!y", "");

	set_dhudmessage(255, 255, 255, -1.0, y, 0, 0.0, holdtime, 0.0, 1.0);
	show_dhudmessage(id, msg);
}

stock kz_register_saycmd(const saycommand[], const function[], flags)
{
	new temp[64]
	formatex(temp, 63, "say /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say .%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team .%s", saycommand)
	register_clcmd(temp, function, flags)
}

/*stock get_configsdir(name[],len)
{
	return get_localinfo("amxx_configsdir",name,len);
}*/

#if defined USE_SQL
stock GetNewRank(id, type)
{
	new createinto[1024],authid[32]
	get_user_authid(id, authid, 31)
	
	new cData[3], table[10]
	cData[ID] = id
	cData[TYPE] = type
	switch (type)
	{
		case PRO_TOP:
			copy(table, 9, "kz_pro15")
		case NUB_TOP:
			copy(table, 9, "kz_nub15")
		case WPN_TOP:
			copy(table, 9, "kz_wpn15")
	}

	new tmpRoute[64]
	if (g_bRoute)
		formatex(tmpRoute, 63, " AND route = '%s' ", g_szSelRoute[id])

	if (valid_steam(authid))
		formatex(createinto, 1023, "SELECT authid FROM `%s` WHERE mapname='%s'%s ORDER BY %stime LIMIT 15", table, MapName, tmpRoute, type == WPN_TOP ? g_wpnorder : "")
	else
		formatex(createinto, 1023, "SELECT name FROM `%s` WHERE mapname='%s'%s ORDER BY %stime LIMIT 15", table, MapName, tmpRoute, type == WPN_TOP ? g_wpnorder : "")
	SQL_ThreadQuery(g_SqlTuple, "GetNewRank_QueryHandler", createinto, cData, 3)
}

stock kz_update_plrname(id)
{
	new createinto[1001], authid[32], name[128]
	get_user_authid(id, authid, 20)
	get_user_name(id, name, 31)

	SqlEncode(name)

	if (valid_steam(authid) && g_nDzUid[id] > 0)
	{
		////////////////////////////0123456789012345
		formatex(createinto, 1000, "UPDATE `kz_pro15` SET dzuid=%d,name=CAST('%s' AS BINARY) WHERE authid='%s'",
			g_nDzUid[id], name, authid);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
		createinto[11] = 'n'
		createinto[12] = 'u'
		createinto[13] = 'b'
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
		createinto[11] = 'w'
		createinto[12] = 'p'
		createinto[13] = 'n'
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
	}


	return 1
}
#endif

public FwdHamDoorSpawn(iEntity)
{
	static const szNull[] = "common/null.wav";
	
	new Float:flDamage;
	pev(iEntity, pev_dmg, flDamage);

	if (flDamage < -999.0){
		set_pev(iEntity, pev_noise1, szNull);
		set_pev(iEntity, pev_noise2, szNull);
		set_pev(iEntity, pev_noise3, szNull);

		if (!HealsOnMap)
			HealsOnMap = true
	}
}

public goStart_task(taskid)
{
	new id = taskid - TASK_GOSTART
	firstspawn[id] = false
	goStart(id)
	if (get_pcvar_num(kz_cup) == 0)
		client_cmd(id, "say /menu");
}

public chkweapons_task(taskid)
{
	new id = taskid - TASK_CHKWPN

	if (g_nGroupId[id] == 0)
		if (!user_has_weapon(id, CSW_KNIFE) && is_user_alive(id))
			give_item(id, "weapon_knife")

	if (user_use_wpn[id])
		set_user_weapons(id, user_use_wpn[id]);
}

public FwdHamPlayerSpawn(id)
{
	if (!IsPlayer(id))
		return;
	if (get_pcvar_num(kz_cup_start) == 1)
	{
		if (HealsOnMap)
			set_pev(id, pev_health, 52014.0)

		set_task(0.5, "goStart_task", id + TASK_GOSTART)
		set_user_weapons(id, CSW_USP);
		return;
	}

	if (g_HamPlayerSpawned[id] == true)
		return;

	new taskid
	g_HamPlayerSpawned[id] = true

	if (firstspawn[id])
	{
		//set_pev(id, pev_health, 5320.0)

		/*if (Verif (id,1) && get_pcvar_num(kz_save_pos) == 1)
			savepos_menu(id)
		else if (get_pcvar_num(kz_spawn_mainmenu) == 1)
			kz_menu (id)*/
		//cs_set_user_nvg(id, 1);
		new authid[32]
		get_user_authid(id, authid, 31)
		if (valid_steam(authid))
			ColorChat(id, GREEN, "^4%s ^1正版用户请升级到Beta版解决某些地图闪退。重启Steam->库->CS属性->测试->Beta", prefix);
		taskid = id + TASK_GOSTART
		if (task_exists(taskid))
			remove_task(taskid)
		set_task(0.5, "goStart_task", id + TASK_GOSTART)
	}

	firstspawn[id] = false
	
	taskid = id + TASK_CHKWPN
	if (task_exists(taskid))
		remove_task(taskid)

	set_task(0.01, "chkweapons_task", id + TASK_CHKWPN)
	set_user_weapons(id, user_use_wpn[id]);

	if (HealsOnMap)
	{
		set_pev(id, pev_health, 52014.0)
	}

	if (IsPaused[id])
	{
		set_pev(id, pev_flags, pev(id, pev_flags)| FL_FROZEN)
		set_pev(id, pev_origin, PauseOrigin[id])
	}
	
	if (get_pcvar_num(kz_use_radio) == 0)
	{
		#define XO_PLAYER				5
		#define	m_iRadiosLeft			192
		set_pdata_int(id, m_iRadiosLeft, 0, XO_PLAYER)
	}
	
	if (g_nTga > 0)
		SetAds(id)

	g_HamPlayerSpawned[id] = false
}

public GroundWeapon_Touch(iWeapon, id)
{
	if (get_pcvar_num(kz_remove_drops) == 1)
	{
		set_pev(iWeapon, pev_flags, FL_KILLME)
		dllfunc(DLLFunc_Think, iWeapon)
	}

	if (IsPlayer(id) && timer_started[id])
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public TraceAttack(id, iAttacker)
{
	if (IsPlayer(id) && IsPlayer(iAttacker))
	{
		return HAM_SUPERCEDE;
	}
	return HAM_IGNORED;
}
 
// ==================================Save positions=================================================
 /*
public SavePos(id)
{
	if (!IsNormal(id))
	{
		ColorChat(id, GREEN, "^4%s ^3使用特殊武器时，暂不开放此功能", prefix)
		return PLUGIN_HANDLED
	}

	new authid[33];
	get_user_authid(id, authid, 32)
	if (get_pcvar_num(kz_save_pos) == 0)
	{
		kz_chat(id, "%L", id, "KZ_SAVEPOS_DISABLED")
		return PLUGIN_HANDLED
	}

	if (!valid_steam(authid))
	{
		ColorChat(id, GREEN, "^4%s ^3保存位置功能只对正版玩家开放。", prefix)
		return PLUGIN_HANDLED
	}	
		
	if (!(pev(id, pev_flags) & FL_ONGROUND2))
	{
		kz_chat(id, "空中禁止使用保存位置")
		
		return PLUGIN_HANDLED
	}
	
	if (!timer_started[id])
	{
		kz_chat(id, "您还没开始计时")
		return PLUGIN_HANDLED
	}
	
	if (Verif (id,1))
	{
		ColorChat(id, GREEN, "^4%s ^3您的位置已成功保存。", prefix)
		savepos_menu(id)
		return PLUGIN_HANDLED
	}
	
	if (get_user_noclip(id))
	{
		ColorChat(id, GREEN, "^4%s ^3鬼魂模式禁止保存位置", prefix)
		return PLUGIN_HANDLED
	}
	
	new Float:origin[3], scout
	pev(id, pev_origin, origin)
	new Float:Time,Float:Timed,check,gocheck 
	if (IsPaused[id])
	{
		Time = g_pausetime[id]
		Timed = g_pausetimed[id]//理论时间
		Pause(id)
	}
	else
	{
		Time=get_gametime()- timer_time[id]
		Timed=get_gametime()- timer_timed[id]//理论时间
	}
	check=checknumbers[id]
	gocheck=gochecknumbers[id]
	ColorChat(id, GREEN, "^4%s ^3保存位置成功。", prefix)
	kz_savepos(id, Time, Timed, check, gocheck, origin, scout)
	reset_checkpoints(id)
	
	return PLUGIN_HANDLED
}

public GoPos(id)
{
	remove_hook(id)
	set_user_godmode(id, 0)
	set_user_noclip(id, 0)
	if (Verif (id,0))
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_flags, pev(id, pev_flags)| FL_DUCKING)
		set_pev(id, pev_origin, SavedOrigins[id])
	}
	
	checknumbers[id]=SavedChecks[id]
	gochecknumbers[id]=SavedGoChecks[id]+((get_pcvar_num(kz_save_pos_gochecks)>0) ? 1 : 0)
	CheckPoint(id)
	CheckPoint(id)
	strip_user_weapons(id)
	give_item(id, "weapon_usp")
	give_item(id, "weapon_knife")
	timer_time[id]=get_gametime()-SavedTime[id]
	timer_timed[id]=get_gametime()-SavedTimed[id]//理论时间
	timer_started[id]=true
	Pause(id)
	
}

public Verif (id, action)
{
	new realfile[128], tempfile[128], authid[32], map[64]
	new bool:exist = false
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(tempfile, 127, "%s/temp.ini", SavePosDir)
	
	if (!file_exists(realfile))
		return 0

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")
	new data[150], sid[32], time[25],timed[25], checks[5], gochecks[5], x[25], y[25], z[25], scout[5]
	while(!feof(vault))
	{
		fgets(vault, data, 149)
		parse(data, sid, 31, time, 24, timed, 24, checks, 4, gochecks, 4, x, 24, y, 24, z, 24, scout, 4)
		
		if (equal(sid, authid) && !exist)// ma aflu in fisier?
		{
			if (action == 1)
				fputs(file, data)
			exist= true 
			SavedChecks[id] = str_to_num(checks)
			SavedGoChecks[id] = str_to_num(gochecks)
			SavedTime[id] = str_to_float(time)
			SavedTimed[id] = str_to_float(timed)//理论时间
			SavedOrigins[id][0]=str_to_num(x)
			SavedOrigins[id][1]=str_to_num(y)
			SavedOrigins[id][2]=str_to_num(z)
		}
		else
		{
			fputs(file, data)
		}
	}

	fclose(file)
	fclose(vault)
	
	delete_file(realfile)
	if (file_size(tempfile) == 0)
		delete_file(tempfile)
	else	
		while(!rename_file(tempfile, realfile, 1)){}
	
	
	if (!exist)
		return 0
	
	return 1
}

public kz_savepos(id, Float:time,Float:timed, checkpoints, gochecks, Float:origin[3], scout)
{
	new realfile[128], formatorigin[128], map[64], authid[32]
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(formatorigin, 127, "%s %f %f %d %d %d %d %d %d", authid, time, timed, checkpoints, gochecks, origin[0], origin[1], origin[2], scout)
	
	new vault = fopen(realfile, "rt+")
	write_file(realfile, formatorigin)// La sfarsit adaug datele mele
	
	fclose(vault)
	
}
*/
stock sb_add_tabszz(str[], size)//ID对齐->状态
{
	new len = strlen(str)// > 7 ? 1 : 2
	add(str[len], size, "^t")
	if (len < 8)add(str[len+1], size, "^t^t^t")
	else
	if (len < 11)add(str[len+1], size, "^t^t")
	else
	if (len < 16)add(str[len+1], size, "^t^t")
	else
	if (len < 24)add(str[len+1], size, "^t")

}

#if !defined USE_SQL
stock sb_add_tabs(str[], size)//ID对齐->Top15
{
	new len = strlen(str)// > 7 ? 1 : 2
	add(str[len], size, "^t")
	if (len < 6)add(str[len+1], size, "^t^t^t^t")
	else
	if (len < 9)add(str[len+1], size, "^t^t^t")
	else
	if (len < 14)add(str[len+1], size, "^t^t^t")
	else
	if (len < 22)add(str[len+1], size, "^t^t")
	else
	if (len < 25)add(str[len+1], size, "^t")
	else
	if (len < 30)add(str[len+1], size, "^t")
}
#endif

//玩家状态
public ct_status(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	new fh = fopen(STATUS_PATH, "w")
	fprintf(fh, "<meta charset=UTF-8>")
	fprintf(fh, "<link rel=stylesheet href=http://iwan.pro/kztop/sv/css><table><tr><td id=a>")
	fprintf(fh, "<pre>玩家^t^t^t^t^t状态^t^t时间^t^t存点^t读点^t完成</pre>")
	fprintf(fh, "</td></tr><tr id=e><td></td></tr><tr><td><pre>")
	
	new line[151],/* written_len,*/players[32], inum, btime_str[4]

	get_players(players, inum)
	for (new i = 0; i < inum; i++)
	{
		new name[32],status[13]
		get_user_name(players[i], name, 30)
		sb_add_tabszz(name, 29)		

		switch (climber_status[players[i]])
			{
				case STATUS_CLIMBING: 
				{
					format(status, 12, "攀登中")
				}
				case STATUS_FINISHED: 
				{
					if (checknumbers[players[i]] > 0)
					format(status, 12, "存点完成")
					else
					format(status, 12, "裸跳完成")
				}
				case STATUS_PAUSED: 
				{
					format(status, 12, "暂停中")
				}
				
				case STATUS_CHEAT: 
				{

					 format(status, 12, "未计时")
				}
				default: format(status, 12, "未计时")
			}
		if (!is_user_alive(players[i]))
				         format(status, 12, "观察中")

		new currenttime[32]
		new Float:kreedztime = get_gametime()- (IsPaused[players[i]] ? get_gametime()- g_pausetime[players[i]] : timer_time[players[i]])
		new imin = floatround(kreedztime / 60.0,floatround_floor)
		new isec = floatround(kreedztime - imin * 60.0,floatround_floor)
		new ims = floatround((kreedztime - (imin * 60.0 + isec))* 100.0, floatround_floor)

		new imindz = floatround(oldtimed[players[i]] / 60.0, floatround_floor)
		new isecdz = floatround(oldtimed[players[i]]  - imindz * 60.0,floatround_floor)
		new imsdz = floatround((oldtimed[players[i]]  - (imindz * 60.0 + isecdz))* 100.0, floatround_floor)

		

		if (is_user_alive(players[i]))
		{
			if (climber_status[players[i]] == STATUS_FINISHED)
			{
				format(currenttime, 8, "%02i:%02i.%02i",imindz,isecdz,imsdz)		
			}	
			else if (climber_status[players[i]] == STATUS_NONE)			
			{	
				format(currenttime, 8, "--:--.--")
			}
			else if (climber_status[players[i]] == STATUS_CHEAT)			
			{	
				format(currenttime, 8, "--:--.--")
			}
			else
			{
				format(currenttime, 8, "%02i:%02i.%02i",imin,isec,ims)	
			}
		}
		else
		       {
			        format(currenttime, 8, "--:--.--")	
		       }
		
		/*if (strlen(name)>= STATUSNAMELEN)               
		name[STATUSNAMELEN] = 0x0;
		else
		setc(name[strlen(name)], STATUSNAMELEN - strlen(name), 0x20);
		sb_add_tabsz(status, 11)
		
		setc(status[strlen(status)], STATUSLEN - strlen(status), 0x20);	*/	
		
		if (checknumbers[players[i]] > 0)
		format(btime_str, 3, "%d",nubcount[players[i]])
		else
		format(btime_str, 3, "%d",procount[players[i]])
        		
		SqlDecode(name)
		formatex(line, 150, "%s%s^t%s^t^t%s^t%d^t%d^t%s%s",
		(i+1)% 2 ? NULLSTR : "<div>",
		name,
		status, 
		currenttime,
		checknumbers[players[i]], 
		gochecknumbers[players[i]],
		btime_str,
		(i+1)% 2 ? NULLSTR : "</div>")
		//written_len += strlen(inum)
		//if (inum > 22)break//大于22人返回
		fprintf(fh, line)			
		
	}
	new cust_msg[30]
	if (!strlen(cust_msg))formatex(cust_msg, 29, "Plugin Modify by PcHun")	
	fprintf(fh, "</pre></td></tr><tr id=d><td></td></tr><tr><td id=e></td></tr><tr>")
	fprintf(fh, "<td id=a>%s</td></tr></table>", cust_msg)
	fclose(fh)
	show_motd(id, STATUS_PATH, "玩家即时状态")
	return PLUGIN_HANDLED
} 
 
// =================================================================================================
// Events / Forwards
// =================================================================================================
 
//=================================================================================================

public client_disconnect(id)
{
	if (get_pcvar_num(kz_cup_start) == 0)
	{
		checknumbers[id] = 0
		gochecknumbers[id] = 0
		procount[id] = 0
		nubcount[id] = 0
		anticheat[id] = 0.0
		chatorhud[id] = -1
		timer_started[id] = false
		ShowTime[id] = get_pcvar_num(kz_show_timer)
		firstspawn[id] = true
		NightVisionUse[id] = false
		IsPaused[id] = false
		WasPaused[id] = false
		gHooked[id] = false
		ProStart[id][0] = 0.0
		remove_hook(id)
		ShowMSGs[id] = false;
		allowstart[id] = true
		//g_fps[id] = 0.0
		g_lockcurwpnchk[id] = true
		user_use_wpn[id] = 0
		g_bWait[id] = true;
		g_bAccept[id] = true;
		g_bAccepting[id] = false;
		g_bInvite[id] = false;
		g_nGetScore[id] = false;
		new nGroupId = g_nGroupId[id];
		g_nGroupId[id] = 0;
		if (nGroupId > 0)
		{
			new Recver;
			Recver = g_nGroupPeople[nGroupId][RECVER];
			if (g_bAccepting[id]) // 受邀中
			{
				CleanGroup(0, Recver, nGroupId, group_tag:REJECT);
			}
			else // 挑战中
			{
				if (get_timeleft() > 10.0)
					ChallengeEnd(0, id, group_tag:ESCAPE);
			}
		}
	}
	if (is_user_hltv(id) && id == g_hltv_id)
		g_hltv_id = 0;
}

public CheckChallengeTeam(taskid)
{
	if (get_timeleft() < 11.0)
		return;

	new nGroupId = taskid - TASK_CHECKCHALLENGETEAM;
	if (g_nGroupTimer[nGroupId] > 0.0)
	{
		new Sender, Recver;
		Sender = g_nGroupPeople[nGroupId][SENDER];
		Recver = g_nGroupPeople[nGroupId][RECVER];
		if (Recver > 0 && Sender > 0)
		{
			if (!is_user_connected(Recver))
			{
				ChallengeEnd(Sender, Recver, group_tag:ESCAPE);
			}
			if (!is_user_connected(Sender))
			{
				ChallengeEnd(Recver, Sender, group_tag:ESCAPE);
			}
		}
	}
}

public GroupDraw()
{
	for (new i = 0; i < 17; i++)
	{
		if (g_nGroupId[i] > 0)
		{
			new Sender = g_nGroupPeople[i][SENDER];
			new Recver = g_nGroupPeople[i][Recver];
			new nGroupId = g_nGroupId[Sender];
			if (Sender != 0 && Recver != 0 && g_nGroupUid[nGroupId][SENDER] > 0 && g_nGroupUid[nGroupId][RECVER] > 0)
			{
				ChallengeScoreChg(g_nGroupUid[nGroupId][SENDER], "draw");
				ChallengeScoreChg(g_nGroupUid[nGroupId][RECVER], "draw");
			}
		}
	}
}

public client_connect(id)
{
	g_nDzUid[id] = 0;
}

public client_putinserver(id)
{
	if (g_nTga > 0)
		SetAds(id)

	// 锁FPS在siri里。
	/*new taskid = id + TASK_SETFPS
	if (task_exists(taskid))
		remove_task(taskid)
	set_task(2.0, "tskFps", taskid, "", 0, "b", 0)*/
	if (is_user_hltv(id))
	{
		new hltv_address[32];
		get_user_ip(id, hltv_address, 31);

		if (equal(hltv_address, "219.147.250.62:27050"))
		{
			g_hltv_id = id;
		}
	}

	if (get_pcvar_num(kz_cup_start) == 0)
	{
		checknumbers[id] = 0
		gochecknumbers[id] = 0
		anticheat[id] = 0.0
		chatorhud[id] = -1
		timer_started[id] = false
		ShowTime[id] = get_pcvar_num(kz_show_timer)
		firstspawn[id] = true
		NightVisionUse[id] = false
		IsPaused[id] = false
		WasPaused[id] = false
		remove_hook(id)
		gHooked[id] = false
		ProStart[id][0] = 0.0
		climber_status[id]	= STATUS_NONE//状态
		allowstart[id] = true
		g_HamPlayerSpawned[id] = false
		//g_fps[id] = 0.0
		g_lockcurwpnchk[id] = true
		user_use_wpn[id] = 0
		g_bWait[id] = true;
		g_bAccept[id] = true;
		g_bAccepting[id] = false;
		g_bInvite[id] = false;
		g_nGroupId[id] = 0;
		g_nGetScore[id] = false;

		for (new i = 0; i < 10; i++)
		{
			g_nGroupScore[id][i] = 0;
		}

		new taskid = id + TASK_SETCOLOR
		if (task_exists(taskid))
			remove_task(taskid)
		set_task(5.0, "SetPlrColor", taskid)

		taskid = id + TASK_GOSTART
		if (task_exists(taskid))
			remove_task(taskid)
		set_task(8.0, "goStart_task", id + TASK_GOSTART)
	}
}

public server_frame()
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return;

	if (get_pcvar_num(kz_issurf) == 0 && get_cvar_num("sv_airaccelerate") != 10)
		set_cvar_num("sv_airaccelerate", 10)
	else if (get_pcvar_num(kz_issurf) == 1)
	{
		new set_aa = (containi(MapName, "surf") != -1 && !equali(MapName, "dr0_surfari")) ? 100 : 10

		if (get_cvar_num("sv_airaccelerate") != set_aa)
			set_cvar_num("sv_airaccelerate", set_aa)
	}
}

/*
public tskFps(taskid)
{
	new id;
	id = taskid - TASK_SETFPS
	new authid[32];
	get_user_authid(id, authid, 31)

	if (get_pcvar_num(kz_issurf) == 0)
	{
		if (valid_steam(authid))
			client_cmd(id, "developer 0;fps_max 99.5;gl_vsync 0;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400")
		else
			client_cmd(id, "developer 0;fps_max 101;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400")
	}
	else
	{
		if (valid_steam(authid))
		{
			if (containi(MapName, "surf") != -1 && !equali(MapName, "dr0_surfari"))
			{
				client_cmd(id, "fps_max %f;fps_override 1;gl_vsync 0;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400", g_fps[id] ? g_fps[id] - 1.5 : 99.5)
			}
			else
				client_cmd(id, "developer 0;fps_max 99.5;gl_vsync 0;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400;")
		}
		else
		{
			if (containi(MapName, "surf") != -1 && !equali(MapName, "dr0_surfari"))
			{
				new Float:fps = g_fps[id] ? g_fps[id] - 1 : 100.0
				client_cmd(id, "developer 1;fps_max %f;fps_modem %f;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400;", fps, fps)
			}
			else
				client_cmd(id, "developer 0;fps_max 101;cl_forwardspeed 400;cl_sidespeed 400;cl_backspeed 400")
		}
	}
}

public SetFps(id)
{
	if (get_pcvar_num(kz_issurf) == 0)
		return PLUGIN_CONTINUE

	new arg[32]
	read_args(arg, 31)
	remove_quotes(arg)
	if (containi(arg, "/fpsmax") != -1 || containi(arg, "/fps_max") != -1)
	{
		if (containi(MapName, "surf") != -1 && !equali(MapName, "dr0_surfari"))
		{
			replace_all(arg, 31, "/fpsmax", "")
			replace_all(arg, 31, "/fps_max", "")
			replace_all(arg, 31, " ", "")
			if (arg[0] == 0x0)
			{
				ColorChat(id, RED, "^4%s ^3请输入fpsmax值", prefix)
			}

			new fps = str_to_num(arg)
			if (fps < 85 || fps > 131)
				ColorChat(id, RED, "^4%s^3 fpsmax值最小值：^1 85 ^3最大值：^1 131", prefix)
			else
			{
				g_fps[id] = fps - 0.0
				ColorChat(id, RED, "^4%s ^3已锁定fps_max %d", prefix, floatround(g_fps[id]))
			}
		}
		else
		{
			ColorChat(id, RED, "^4%s^3 非Surf系列地图，无法设置fpsmax", prefix)
		}
	}
	
	return PLUGIN_CONTINUE
}*/

public GetUserInfo(id, UID)
{
	g_nDzUid[id] = UID;
	if (g_nDzUid[id] > 0)
	{
		kz_update_plrname(id);

		GetChallengePoint(id);
	}
}

public GetChallengePoint(id)
{
	new cData[3];
	cData[ID] = id;
	cData[ACTION] = GETSCORE;
	g_nGetScore[id] = true;

	new szQuery[256];
	format(szQuery, 255, "SELECT * FROM kz_challenge WHERE uid = %d", g_nDzUid[id]);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);
}

public CloseMsgInfo(const taskid)
{
	new id = taskid - TASK_MSGINFO;
	ShowMSGs[id] = false;
}

public PutRecord(const id)
{
	ShowMSGs[id] = true;
	new taskid = id + TASK_MSGINFO;
	if (task_exists(taskid))
		remove_task(taskid);
	set_task(15.0, "CloseMsgInfo", taskid);
	
	return PLUGIN_CONTINUE
}

public GetMore(taskid)
{
	if (!g_SqlReady)
		return PLUGIN_HANDLED;

	remove_task(taskid);

	new szQuery[512], cData[3];
	cData[ACTION] = GET_SPAWN_DATA;
	format(szQuery, 255, "SELECT * FROM kz_spawn WHERE mapname = '%s' LIMIT 1", MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[ACTION] = GETRECORD;
	format(szQuery, 255, "SELECT * FROM kz_record WHERE mapname = '%s' OR mapname LIKE '%s[\1\2\3' ORDER BY type DESC", MapName, MapName);
	replace_all(szQuery, 255, "\1\2\3", "%");
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[ACTION] = GETTOPONE;
	cData[TYPE] = PRO_TOP;
	format(szQuery, 255, "SELECT name FROM kz_pro15 WHERE mapname = '%s' ORDER BY time LIMIT 1", MapName)
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[TYPE] = WPN_TOP;
	format(szQuery, 255, "SELECT name FROM kz_wpn15 WHERE mapname = '%s' AND speed <> 260 ORDER BY speed, time LIMIT 1", MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[TYPE] = NUB_TOP;
	format(szQuery, 255, "SELECT name FROM kz_nub15 WHERE mapname = '%s' ORDER BY time LIMIT 1", MapName)
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[ACTION] = GETROUTE;
	format(szQuery, 255, "SELECT * FROM kz_maproute WHERE mapname = '%s' AND route <> 'vancy_cup' ORDER BY SEQNO", MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[ACTION] = SETBUTTON;
	format(szQuery, 255, "SELECT * FROM kz_surfbutton WHERE mapname = '%s'", MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	GetDefaultStart = true;
	cData[ACTION] = GETSTART;
	format(szQuery, 255, "SELECT * FROM kz_startpos WHERE mapname = '%s'", MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);

	cData[ACTION] = GETHOTMAP;
	format(szQuery, 511, "SELECT * FROM `kz_hotmap` AS t1 JOIN (SELECT ROUND(RAND() * ((SELECT MAX(id) FROM `kz_hotmap`)-(SELECT MIN(id) FROM `kz_hotmap`))+(SELECT MIN(id) FROM `kz_hotmap`)) AS id) AS t2 WHERE t1.server = '%s' AND t1.mapname <> '%s' AND t1.id >= t2.id ORDER BY t1.id LIMIT 1", g_szServer, MapName);
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);
	return PLUGIN_HANDLED;
}

public TaskReadTop(taskid)
{
	if (!g_SqlReady)
		return;
	remove_task(taskid);
	ReadTop(PRO_TOP);
}

public ReadTop(type)
{
	if (!g_SqlReady)
		return;

	new cData[3], table[10], szQuery[256];
	cData[TYPE] = type
	cData[ACTION] = READTOP
	switch (type)
	{
		case PRO_TOP:
			copy(table, 9, "kz_pro15")
		case NUB_TOP:
			copy(table, 9, "kz_nub15")
		case WPN_TOP:
			copy(table, 9, "kz_wpn15")
	}

	format(szQuery, 127, "SELECT * FROM %s WHERE mapname='%s' ORDER BY %stime ASC LIMIT 1", table, MapName, type == WPN_TOP ? g_wpnorder : "")
	SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3)

	return;
}

public DataQueryHandle(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	new iAction = cData[ACTION]
	new iType = cData[TYPE]
	new id = cData[ID]
	if (iFailState != TQUERY_SUCCESS)
	{
		static logerr[] = "ProKreedz QueryHandle SQL: SQL Error #%d - %s^nType:[%d] Action[%d]"
		log_amx(logerr, iErrnum, szError, iType, iAction)
		server_print(logerr, iErrnum, szError, iType, iAction)
	}

	new i, j, k, l;
	switch (iAction)
	{
		case UPDRECORD:
			GetNewRank(id, iType)
		case READTOP:
		{
			if (SQL_NumResults(hQuery) != 0)
			{
				SQL_ReadResult(hQuery, 4, e_TopName, 31)
				SqlDecode(e_TopName)
				new szTmp[11]
				SQL_ReadResult(hQuery, 6, szTmp, 10)
				e_fTopTime = str_to_float(szTmp)
				ClimbtimeToString(e_fTopTime, e_TopTime)
				e_TopType = iType
				if (e_TopType == WPN_TOP)
				{
					SQL_ReadResult(hQuery, 8, szTmp, 10)
					formatex(e_Weapon, 9, "(%s)", szTmp)
					SQL_ReadResult(hQuery, 13, szTmp, 10)
					e_WpnSpeed = str_to_num(szTmp)
					ReadTop(NUB_TOP)
				}
			}
			else
			{
				if (iType == PRO_TOP)
					ReadTop(WPN_TOP)
				else if (iType == WPN_TOP)
					ReadTop(NUB_TOP)
				else if (iType == NUB_TOP)
				{
					g_fTopFastTime = 0.0;
					copy(e_TopName, 4, "N/A")
					copy(e_TopTime, 9, "**:**.**")
					e_fTopTime = 0.0
					e_TopType = TOP_NUL
					e_WpnSpeed = 270
				}
			}
			if (e_fTopTime > 0.0)
			{
				g_fTopFastTime = e_fTopTime;
			}
		}
		case GETRECORD:
		{
			#define WRRECORD	0
			#define CNRECORD	1
			#define CNTYPE	0
			new mapname[64], holder[32], time[9], type, country_sort[3]
			new szTmp[64]
			new flag[2]
			new Float:fTmp = 0.00
			new iLen[2];
			new Handle:query
			new szQuery[128];

			new Float:fCRTime, Float:fWRTime;
			while (SQL_MoreResults(hQuery))
			{
				SQL_ReadResult(hQuery, 4, szTmp, 1)
				type = str_to_num(szTmp)
				if (type == CNTYPE)
					flag[CNRECORD] = 1
				else
					flag[WRRECORD] = 1

				SQL_ReadResult(hQuery, 0, szTmp, 63)
				SQL_ReadResult(hQuery, 1, holder, 31)
				SQL_ReadResult(hQuery, 2, country_sort, 2)
				SQL_ReadResult(hQuery, 3, time, 8)

				fTmp = str_to_float(time);
				if (type == CNTYPE)
				{
					fCRTime = fTmp;
				}
				else
				{
					fWRTime = fTmp;
				}

				formatex(szQuery, 127, "SELECT CAST(`cn` AS BINARY),en FROM iwan_country WHERE ensort = '%s'", country_sort);
				query = SQL_PrepareQuery(g_SqlConnection, szQuery);
				
				SQL_Execute(query);

				new country[2][32];
				if (SQL_NumResults(query) > 0)
				{
					SQL_ReadResult(query, 0, country[INDEX_CN], 31)
					SQL_ReadResult(query, 1, country[INDEX_EN], 31);
				}
				else
				{
					copy(country[INDEX_CN], 4, "N/A");
					copy(country[INDEX_EN], 4, "N/A");
				}
				
				replace_all(szTmp, 63, MapName, "")
				new index = findchar(szTmp, 63, '[')
				copy(mapname, 63, szTmp[index])

				if (type != CNTYPE && fTmp < e_WRtime)
					e_WRtime = fTmp

				ClimbtimeToString(fTmp, time)
				iLen[INDEX_CN] = ProcMessage(INDEX_CN, type, fTmp, holder, time, country[INDEX_CN], mapname, iLen[INDEX_CN]);
				iLen[INDEX_EN] = ProcMessage(INDEX_EN, type, fTmp, holder, time, country[INDEX_EN], mapname, iLen[INDEX_EN]);
				SQL_NextRow(hQuery)
			}
			
			g_fWRTime = (fWRTime > 0.0 ? fWRTime : fCRTime);

			/*if (!flag[WRRECORD])
				iLen += formatex(e_Message[iLen], 511 - iLen, "WR: No Map^n")
			if (!flag[CNRECORD])
				iLen += formatex(e_Message[iLen], 511 - iLen, "CR: No Map^n")*/
		}
		case SETBUTTON:
		{
			if (SQL_NumResults(hQuery) != 0)
			{
				new tmp[16];
				k = 1;
				new Float:fVector[4][3] // 0坐标 1角度 2坐标 3角度
				for (i = 0; i < 4; i++)
				{
					for (j = 0; j < 3; j++)
					{
						SQL_ReadResult(hQuery, k++, tmp, 15)
						fVector[i][j] = str_to_float(tmp)
					}
				}
				
				Create_Button(fVector[0], fVector[1], true)
				Create_Button(fVector[2], fVector[3], false)
			}
		}
		case GETROUTE:
		{
			new tmp[33], route[33];
			new Float:fVector[3][3] // 0坐标 1角度
			new lastmap[33] = {-1, ...}
			l = 0
			while (SQL_MoreResults(hQuery))
			{
				k = 3
				SQL_ReadResult(hQuery, 1, route, 32)
				if (!equal(route, "error") && !equal(route, "block") && !equal(route, lastmap))
				{
					copy(lastmap, 32, route)
					if (route[0] == 0x0)
						copy(g_szRoute[l], 32, "normal")
					else
						copy(g_szRoute[l], 32, route)
					l++
				}
				for (i = 0; i < 3; i++)
				{
					for (j = 0; j < 3; j++)
					{
						SQL_ReadResult(hQuery, k++, tmp, 15)
						fVector[i][j] = str_to_float(tmp)
					}
				}

				server_print("====================Set Route[%s]", route);
				CreateRoute("iwan_route", route, fVector[0], fVector[1], fVector[2])
				/*for (new i = 0; i < 10; i++)
				{
					server_print("----%s----", g_szRoute[i]);
				}*/
				SQL_NextRow(hQuery)
			}

			if (l != 0)
			{
				g_bRoute = true
				server_print("====================Load Route[%d]", l);
			}
		}
		case SYNC_SPAWN_DATA:
		{
			new sync_mapname[64], sync_data[33], sync_team[3], sync_buffer[128];
			new Float:sync_fVector[2][3] // 0坐标 1角度
			l = 0;
			while (SQL_MoreResults(hQuery))
			{
				k = 3;
				SQL_ReadResult(hQuery, 0, sync_mapname, 63);
				SQL_ReadResult(hQuery, 1, sync_team, 2);
				for (i = 0; i < 2; i++)
				{
					for (j = 0; j < 3; j++)
					{
						SQL_ReadResult(hQuery, k++, sync_data, 15);
						sync_fVector[i][j] = str_to_float(sync_data);
					}
				}
				formatex(sync_buffer, 127, "%s %d %d %d %d %d %d", sync_team, sync_fVector[0][0], sync_fVector[0][1], sync_fVector[0][2], 0, sync_fVector[1][1], 0);
				write_file(g_szSpawnFile, sync_buffer, -1);
				l++;
				SQL_NextRow(hQuery);
			}

			if (l != 0)
			{
				server_print("====================SyncSpawnFromSql[%d]", l);
			}
		}
		case GETCUPROUTE:
		{
			new szTmpCupRoute[33], szClassName[33];
			new Float:fVector2[3][3] // 0坐标 1角度
			if (g_fCupCusPosNum > 0)
			{
				new entity = -1;
				while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", "vancy_cup")))
					engfunc(EngFunc_RemoveEntity, entity);
			}
			g_fCupCusPosNum = 0
			g_fCupCustomPos[0] = Float:{0.0, 0.0, 0.0};
			while (SQL_MoreResults(hQuery))
			{
				k = 3
				SQL_ReadResult(hQuery, 1, szClassName, 32)
				for (i = 0; i < 3; i++)
				{
					for (j = 0; j < 3; j++)
					{
						SQL_ReadResult(hQuery, k++, szTmpCupRoute, 15)
						fVector2[i][j] = str_to_float(szTmpCupRoute)
					}
				}

				g_fCupCusPosNum++;
				g_fCupCustomPos[g_fCupCusPosNum] = fVector2[0];

				server_print("====================Set Cup Route[%d]", g_fCupCusPosNum);
				format(szTmpCupRoute, 31, "%d", g_fCupCusPosNum);
				CreateRoute(szClassName, szTmpCupRoute, fVector2[0], fVector2[1], fVector2[2])
				SQL_NextRow(hQuery)
			}

			if (g_fCupCusPosNum != 0)
			{
				g_bCupRoute = true;
				server_print("====================Load Cup Route[%d]", g_fCupCusPosNum);
			}
		}
		case GET_SPAWN_DATA:
		{
			new result = SQL_NumResults(hQuery);
			SyncData(result);
		}
		case GETTOPONE:
		{
			if (SQL_NumResults(hQuery) != 0)
				SQL_ReadResult(hQuery, 0, g_szTopOneName[iType], 31)
		}
		case GETHOTMAP:
		{
			if (SQL_NumResults(hQuery) != 0)
				SQL_ReadResult(hQuery, 2, g_szHotMap, 63)
		}
		case GETSTART:
		{
			if (SQL_NumResults(hQuery) != 0)
			{
				new x[13], y[13], z[13];
				SQL_ReadResult(hQuery, 1, x, 12)
				SQL_ReadResult(hQuery, 2, y, 12)
				SQL_ReadResult(hQuery, 3, z, 12)

				DefaultStartPos[0] = str_to_float(x)
				DefaultStartPos[1] = str_to_float(y)
				DefaultStartPos[2] = str_to_float(z)

				//server_print("===========GetDefaultStart(%f,%f,%f)", DefaultStartPos[0], DefaultStartPos[1], DefaultStartPos[2]);
				DefaultStart = true
			}
			
			GetDefaultStart = false;
		}
		case GETSCORE:
		{
			if (SQL_NumResults(hQuery) != 0)
			{
				new tmp[10];
				new index = 0;
				for (new i = 1; i < 10; i++)
				{
					SQL_ReadResult(hQuery, i, tmp, 10);
					g_nGroupScore[id][index] = str_to_num(tmp);
					index++;
				}

				g_nGroupScore[id][score_tag:LEVEL] = g_nGroupScore[id][score_tag:SCORE] / 200 - 5;
				
				new szName[64];
				get_user_name(id, szName, 31);
				SqlEncode(szName);

				new szQuery[128];
				format(szQuery, 127, "UPDATE kz_challenge SET name=CAST('%s' AS BINARY) WHERE uid=%d", szName, g_nDzUid[id]);
				SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
			}
			else
			{
				new cData[3];
				cData[ID] = id;
				cData[ACTION] = ADDSCORE;

				new szQuery[256];
				format(szQuery, 255, "INSERT INTO kz_challenge(uid) VALUE (%d);", g_nDzUid[id]);
				SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", szQuery, cData, 3);
			}

			g_nGetScore[id] = false;
		}
		case ADDSCORE:
		{
			if (SQL_AffectedRows(hQuery) != 0)
				GetChallengePoint(id);
		}
		case SETSTART:
		{
			if (SQL_AffectedRows(hQuery) != 0)
				DefaultStart = true
		}
		case UPDSTART:
		{
			if (SQL_AffectedRows(hQuery) == 0)
				ColorChat(id, GREEN, "^4%s %L", prefix, id, "START_SAVE_FAIL");
			else
			{
				DefaultStart = true;
				ColorChat(id, GREEN, "^4%s %L", prefix, id, "START_SAVE_SUCC");
			}
		}
	}
	
	if (iAction == READTOP || iAction == GETRECORD)
	{
		if (g_fTopFastTime > -1.0 && g_fWRTime > -1.0)
		{
			new Float:fTimelimit = (g_fWRTime > 0.0 ? g_fWRTime : g_fTopFastTime);
			new toptime = floatround(fTimelimit / 60.0);
			new newtime = 15;
			if (toptime > newtime)
			{
				newtime = toptime * (toptime / 70 + 1);
			}
			server_cmd("mp_timelimit %d", newtime);
			set_cvar_num("amx_extendmap_step", newtime);
		}
	}

	return PLUGIN_CONTINUE
}

public Create_Button(Float:fOrigin[3], Float:fAngles[3], isStart)
{
	new ent = create_entity("func_button");
	if (is_valid_ent(ent))
	{
		entity_set_string(ent, EV_SZ_target, isStart ? "but_start" : "but_stop");
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX);
		entity_set_model(ent, isStart ? KZ_SURFSTART : KZ_SURFSTOP);
		entity_set_origin(ent, fOrigin);

		entity_set_size(ent,Float:{-4.0, -4.0, -16.0}, Float:{4.0, 4.0, 8.0})
		entity_set_vector(ent, EV_VEC_angles, fAngles);
		entity_set_int(ent, EV_INT_rendermode, kRenderTransColor);
		entity_set_float(ent, EV_FL_renderamt, 150.0);
	}
}

public ProcMessage(index, type, Float:isHolder, holder[], time[], country[], path[], iLen)
{

	new szType[3] = "WR"
	if (type == CNTYPE)
		szType[0] = 'C'

	new Rtype[5]
	switch (type)
	{
		case 1:
			copy(Rtype, 4, "[XJ]")
		case 2:
			copy(Rtype, 4, "[CC]")
	}

	if (!isHolder)
		iLen += formatex(e_Message[index][iLen], 511 - iLen, "%s%s: N/A^n", path, szType)
	else
	{
		if (type == CNTYPE)
		{
			iLen += formatex(e_Message[index][iLen], 511 - iLen, "%s%s %s: %s by: %s^n", szType, Rtype, path, time, holder)
		}
		else
		{
			iLen += formatex(e_Message[index][iLen], 511 - iLen, "%s%s %s: %s by: %s(%s)^n", szType, Rtype, path, time, holder, country[1] == '-' ? "N/A": country)
		}
	}
	return iLen
}

public Tick()
{
	new type[4];
	switch (e_TopType)
	{
		case PRO_TOP:
			copy(type, 9, "PRO")
		case NUB_TOP:
			copy(type, 9, "NUB")
		case WPN_TOP:
			copy(type, 9, "WPN")
		default:
			copy(type, 9, "NUL")
	}

	new message[512];
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		new id = i;
		if (is_user_connected(id) && ShowMSGs[id] && !is_user_hltv(id))
		{
			new szLang[3];
			get_user_info(id, "lang", szLang, charsmax(szLang));
			new index = (equali(szLang, "cn") ? INDEX_CN : INDEX_EN);
			formatex(message,511, "%L^n%s^n[%s]%s #1: %s by: %s", id, "LT_MSG_INFO", e_Message[index], type, e_TopType == WPN_TOP ? e_Weapon : "", e_TopTime, e_TopName)
			set_hudmessage(64, 64, 64, 0.02, 0.20, 0, 6.0, UPDATEINTERVAL + 0.1, 0.1, 0.2, -1);
			show_lang_hudmessage(id, message);
		}
	}

	return PLUGIN_HANDLED
}
//世界记录
// =================================================================================================
// Menu
// =================================================================================================


public kz_menu(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return PLUGIN_CONTINUE;

	client_cmd(id, "say pplmenu")
	return PLUGIN_HANDLED
}

/*public kz_menu(id)
{
	new title[64];
	formatex(title, 63, "\rProKreedz %s Menu  爱玩社区 -> WwW.iWan.Pro\w", VERSION)
	new menu = menu_create(title, "MenuHandler") 
	
	new msgcheck[64], msggocheck[64], msgpause[64]
	formatex(msgcheck, 63, "存点 - \y#%i", checknumbers[id])
	formatex(msggocheck, 63, "读点 - \y#%i", gochecknumbers[id])
	formatex(msgpause, 63, "暂停 - %s", IsPaused[id] ? "\y是" : "\r否")
	
	menu_additem(menu, msgcheck, "1")
	menu_additem(menu, msggocheck, "2")
	menu_additem(menu, msgpause, "3")
	menu_additem(menu, "返回起点^n", "4")
	menu_additem(menu, "玩家菜单", "5")
	menu_additem(menu, "Top 15", "6")
	menu_additem(menu, "屏蔽菜单", "7")
	menu_additem(menu, "观察者/CT", "8")
	menu_additem(menu, "清除计时^n", "9")
	menu_additem(menu, "关闭菜单", "MENU_EXIT")
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED
}

public MenuHandler(id , menu, item)
{
	if (item == MENU_EXIT){
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 

	switch(item){
		case 0:{
			CheckPoint(id)
			kz_menu(id)
		}
		case 1:{
			GoCheck(id)
			kz_menu(id)
		}
		case 2:{
			Pause(id)
			kz_menu(id)
		}
		case 3:{
			goStart(id)
			kz_menu(id)
		}
		case 4:{
			client_cmd(id, "say pplmenu")
		}
		case 5:{
			top15menu(id)
		}
		case 6:{
			InvisMenu(id)
		}
		case 7:{
			ct(id)
		}
		case 8:{
			reset_checkpoints(id)
			kz_menu(id)
		}
	}

	return PLUGIN_HANDLED
}*/

public InvisMenu(id)
{
	new buffer[256];
	formatex(buffer, 255, "%L^n\r%L\y", id, "MAIN_MENU_CONSOLE", "bind f3 invis", id, "INVIS_MENU_TITLE");
	new menu = menu_create(buffer, "InvisMenuHandler")

	formatex(buffer, 63, "%L - \y%L", id, "INVIS_MODEL_PLAYER", id, (gViewInvisible[id] ? "ON" : "OFF"));
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L - \y%L", id, "INVIS_MODEL_WATER", id, (gWaterInvisible[id] ? "ON" : "OFF"));
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "INVIS_MENU_MIC");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "MAIN_MENU");
	menu_additem(menu, buffer);

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED  
}

public InvisMenuHandler (id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /pinvis")
		}
		case 1:
		{
			client_cmd(id, "say /winvis")
		}
		case 2:
		{
			client_cmd(id, "say /mute")
		}
		case 3:
		{
			client_cmd(id, "say menu")
		}
	}
	return PLUGIN_HANDLED
}

public ShowTimer_Menu(id)
{
	if (get_pcvar_num(kz_show_timer) == 0)
	{
		kz_chat(id, "%L", id, "SHOWTIMER_MENU_CLOSE");
	}
	else 
	{
		new buffer[63];
		formatex(buffer, 63, "\y%L\w", id, "SHOWTIMER_MENU");
		new menu = menu_create(buffer, "TimerHandler");

		formatex(buffer, 63, "%L", id, "SHOWTIMER_MENU_ROUND", (ShowTime[id] == 2 ? "\y x" : ""));
		menu_additem(menu, buffer);
		formatex(buffer, 63, "%L", id, "SHOWTIMER_MENU_HUD", (ShowTime[id] == 1 ? "\y x" : ""));
		menu_additem(menu, buffer);
		formatex(buffer, 63, "%L", id, "SHOWTIMER_MENU_DISABLE", (ShowTime[id] == 0 ? "\y x" : ""));
		menu_additem(menu, buffer);
		formatex(buffer, 63, "%L", id, "MAIN_MENU");
		menu_additem(menu, buffer);

		menu_display(id, menu, 0)
	}

	return PLUGIN_HANDLED;
}

public TimerHandler (id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{

		case 0:
		{
			ShowTime[id]= 2
			ShowTimer_Menu(id)
		}
		case 1:
		{
			ShowTime[id]= 1
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 2:
		{
			ShowTime[id]= 0
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 3:
		{
			client_cmd(id, "say menu")
		}
	}
	return PLUGIN_HANDLED
}
/*
public savepos_menu(id)
{
	new menu = menu_create("保存位置菜单", "SavePosHandler") 
	
	menu_additem(menu, "读取保存位置", "1")
	menu_additem(menu, "重新开始计时", "2")
	
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public SavePosHandler(id, menu, item)
{
	
	switch(item)
	{
		case 0:
		{
			GoPos(id)
		}
		case 1:
		{
			Verif (id,0)
		}
	}
	return PLUGIN_HANDLED
}*/

public top15menu(id)
{
	new buffer[64];
	formatex(buffer, 63, "%L", id, "TOP_MENU_TITLE");
	new menu = menu_create(buffer, "top15handler");

	formatex(buffer, 63, "%L", id, "TOP_MENU_WPN");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "TOP_MENU_NC");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L^n", id, "TOP_MENU_CP");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L^n", id, "TOP_MENU_CHECT");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "TOP_MENU_PS");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "TOP_MENU_PLR");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "TOP_MENU_MAP");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L^n", id, "TOP_MENU_NEW");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "TOP_MENU_READ");
	menu_additem(menu, buffer);
	formatex(buffer, 63, "%L", id, "EXIT");
	menu_additem(menu, buffer);
	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public top15handler(id, menu, item)
{
	switch(item)
	{
		case 0:
		{
			if (g_bRoute)
				routetopmenu(id, WPN_TOP)
			else
			{
				kz_showhtml_motd(id, WPN_TOP, MapName)
				top15menu(id)
			}
		}
		case 1:
		{
			if (g_bRoute)
				routetopmenu(id, PRO_TOP)
			else
			{
				kz_showhtml_motd(id, PRO_TOP, MapName)
				top15menu(id)
			}
		}
		case 2:
		{
			if (g_bRoute)
				routetopmenu(id, NUB_TOP)
			else
			{
				kz_showhtml_motd(id, NUB_TOP, MapName)
				top15menu(id)
			}
		}
		case 3:
		{
			kz_showhtml_motd(id, PLAYERS_CLEANLIST)
			top15menu(id)
		}
		case 4:
		{
			PsRecs_show(id);
			top15menu(id)
		}
		case 5:
		{
			kz_showhtml_motd(id, PLAYERS_RANKING)
			top15menu(id)
		}
		case 6:
		{
			kz_showhtml_motd(id, MAPS_STATISTIC)
			top15menu(id)
		}
		case 7:
		{
			kz_showhtml_motd(id, LASTTOP)
			top15menu(id)
		}
		case 8:
		{
			kz_showhtml_motd(id, SHOWHELP)
			top15menu(id)
		}
	}
	
	return PLUGIN_HANDLED;
}

public routetopmenu(id, type)
{
	new szData[64];
	formatex(szData, 63, "%L", id, "ROUTE_MENU_TITLE", g_szRouteCHN[type]);
	new menu = menu_create(szData, "routetophandler");

	for (new i = 0; i < 10; i++)
	{
		if (g_szRoute[i][0] == 0x0)
			break;
		menu_additem(menu, g_szRoute[i])
	}
	
	g_nSelRoute[id] = type

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public routetophandler(id, menu, item)
{
	new mapname[64]
	if (equal(g_szRoute[item], "normal"))
	{
		formatex(mapname, 63, "%s", MapName)
	}
	else
	{
		formatex(mapname, 63, "%s[%s]", MapName, g_szRoute[item])
	}

	kz_showhtml_motd(id, g_nSelRoute[id], mapname)
	
	top15menu(id)

	return PLUGIN_HANDLED;
}

// =================================================================================================

// 
// Timersystem
// =================================================================================================
public StopStart(id)
{
	new authid[32]
	get_user_authid(id, authid, 31)
	if (equal(authid, "STEAM_0:0:33403241"))
	{
		stopstart = !stopstart
	}
	return PLUGIN_HANDLED;
}

public FwdHamButtonTouch(const iEntity, const id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return;

	if (!is_user_alive(id))
		return

	static const START[] = "gogogo"
	static const START2[] = "some_noob"
	static const STOP[]  = "stop_counter"

	new szTarget[32]
	entity_get_string(iEntity, EV_SZ_target, szTarget, 31)

	if (equal(szTarget, START) || equal(szTarget, START2))
		start_climb(id)
	else if (equal(szTarget, STOP))
		finish_climb(id)
}

public fwdUse(ent, id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return HAM_IGNORED;

	if (!plugin_status)
	{
		ColorChat(0, GREEN, "^4%s ^3插件非法，请重启服或更换地图。", prefix)
		return HAM_IGNORED;
	}

	if (!ent || id > 32 || !is_user_alive(id))
		return HAM_IGNORED;

	if (get_user_noclip(id))
	{
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "CANT_START_NOCLIP");
		return HAM_IGNORED;
	}

	new name[32]
	get_user_name(id, name, 31)

	new szTarget[32];
	pev(ent, pev_target, szTarget, 31);

	if (TrieKeyExists(g_tStarts, szTarget))
		start_climb(id)

	if (TrieKeyExists(g_tStops, szTarget))
		finish_climb(id)

	return HAM_IGNORED
}

public start_climb(id)
{
	if (stopstart)
	{
		client_cmd(id, "spk sound/buttons/button10.wav");
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "CANT_START_ADMIN");
		return;
	}

	if (gHooked[id])
	{
		kz_chat(id, "%L", id, "CANT_START_HOOK");
		return
	}
	
	if (!allowstart[id])
	{
		kz_chat(id, "%L", id, "CANT_START_WAIT_TOP");
		return
	}

	if (get_gametime() - anticheat[id] < 3.0)
	{
		kz_chat(id, "%L", id, "CANT_START_WAIT");
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "CANT_START_WAIT_HOOK");
		return
	}

	/*if (Verif(id,1))
	{
		ColorChat(id, GREEN, "^4%s ^3您必须选择读取保存位置或重新开始计时。", prefix)
		savepos_menu(id)
		return
	}*/

//	if (reset_checkpoints(id) && !timer_started[id])
//	{
	new wpn = get_user_weapon(id)

	// 给当前使用的武器。
	user_use_wpn[id] = wpn	// 记录使用的武器
	set_user_weapons(id, wpn);

	if (get_user_health(id)< 100)
		set_user_health(id, 100)

	pev(id, pev_origin, SavedStart[id])
	if (get_pcvar_num(kz_save_autostart) == 1)
		AutoStart[id] = true;

	if (!DefaultStart && !GetDefaultStart)
	{
		kz_set_start(SETSTART, SavedStart[id])
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "START_SAVE_SUCC");
	}

	remove_hook(id)
//	}
//	else
//		return
	//kz_chat(id, "计时开始Go  Go Go !!!")		

	new fastrecord[64];
	if (oldtimed[id] != 0)
	{	
		new imin = floatround(oldtimed[id] / 60.0, floatround_floor)
		new isec = floatround(oldtimed[id] - imin * 60.0,floatround_floor)
		new ims = floatround((oldtimed[id] - (imin * 60.0 + isec))* 100.0, floatround_floor)
		formatex(fastrecord, 63, "^1%L%02i:%02i.%02i", id, "FAST_RECORD", imin, isec, ims);
	}
	ColorChat(id, GREEN, "^4%s ^3%L Go  Go Go !!! ^1%s%L%02d:%02d", prefix, id, "TIMER_START", fastrecord, id, "TIME_LEFT", (get_timeleft()/ 60), (get_timeleft()% 60));

	if (ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_movetype, MOVETYPE_WALK)
	set_user_godmode(id, 0)
	reset_checkpoints(id)
	IsPaused[id] = false
	timer_started[id] = true
	timer_time[id] = get_gametime()
	timer_timed[id] = timer_time[id] = get_gametime() //理论时间
	timer_stime[id][0] = 0.0;
	timer_stime[id][1] = 0.0;
	timer_save[id][0] = 0.0;
	timer_save[id][1] = 0.0;
	climber_status[id] = STATUS_CLIMBING
	client_cmd(id, "spk %s;slot10", statsz);
}

public DelayAllowStart(taskid)
{
	new id = taskid - TASK_DELAYALLOWSTART
	allowstart[id] = true
}

public finish_climb(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return;

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "CANT_END_PAUSING");
		return;
	}

	if (!is_user_alive(id) || get_user_noclip(id))
		return;

	if (g_bAccepting[id])
		return;

	if (g_bGroupStart[g_nGroupId[id]])
		ChallengeEnd(id, 0, group_tag:FINISH);
		
	if (timer_started[id])
	{
		if (get_pcvar_num(kz_hook_prize) == 1 && !canusehook[id])
		{
			canusehook[id] = true
			ColorChat(id, GREEN, "^4%s %L", prefix, id, "FINISH_CLIMB");
		}
	}
	else
	{
		kz_hud_message(id, "%L", id, "CANT_END_NOSTART");
		return
	}

	g_finish_time[id] = get_gametime() - timer_time[id] - g_flStartDelay
	show_finish_message(id, g_finish_time[id])
	timer_started[id] = false
	if (get_pcvar_num(kz_show_timer)> 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)

	new steam[32], name[128]
	get_user_name(id, name, 31)
	get_user_authid(id, steam, 31)	
	new createinto[1001]

	new cData[32], table[10]
	cData[ID] = id
	cData[CPNUM] = checknumbers[id]
	cData[GPNUM] = gochecknumbers[id]
	//formatex(cData[STRING], 31, "%.2f", time)

	if (!IsNormal(id))
	{
		cData[TYPE] = WPN_TOP
		copy(table, 9, "kz_wpn15")
	}
	else
	{
		if (checknumbers[id] == 0)
		{
			cData[TYPE] = PRO_TOP
			copy(table, 9, "kz_pro15")
		}
		else
		{
			cData[TYPE] = NUB_TOP
			copy(table, 9, "kz_nub15")
		}
	}
	
	SqlEncode(name)

	if (allowstart[id])
	{
		allowstart[id] = false

		set_task(5.0, "DelayAllowStart", TASK_DELAYALLOWSTART + id)

		new route[32]
		if (g_bRoute)
			formatex(route, 31, " AND route='%s' ", g_szSelRoute[id])

		if (valid_steam(steam))
		{
			formatex(createinto, sizeof createinto - 1, "SELECT * FROM `%s` WHERE mapname='%s' AND authid='%s'%s", table, MapName, steam, route)
		}
		else
		{
			if (g_nDzUid[id] > 0)
			{
				formatex(createinto, sizeof createinto - 1, "SELECT * FROM `%s` WHERE mapname='%s' AND dzuid=%d%s", table, MapName, g_nDzUid[id], route)
			}
			else
			{
				formatex(createinto, sizeof createinto - 1, "SELECT * FROM `%s` WHERE mapname='%s' AND name=CAST('%s' AS BINARY)%s", table, MapName, name, route)
			}
		}

		SQL_ThreadQuery(g_SqlTuple, "Set_QueryHandler", createinto, cData, sizeof cData)
	}

	if (IsNormal(id))
		if (checknumbers[id])
			nubcount[id]++//存点累加完成次数
		else
			procount[id]++//裸跳累加完成次数
	climber_status[id] = STATUS_FINISHED//状态
	//ColorChat(id, GREEN, "^4%s^3 97Club^1巅峰再启 ^3CUP对决 ^1谁与争锋 ^3等你来战 ^1QQ群：^3 204169252", prefix)
	client_cmd(0, "spk %s", completez);//终点音效
}

public show_finish_message(id, Float:kreedztime)
{
	new name[32]
	new imin,isec,ims,imind,isecd,imsd
	get_user_name(id, name, 31)
	imin = floatround(kreedztime / 60.0, floatround_floor)
	isec = floatround(kreedztime - imin * 60.0,floatround_floor)
	ims = floatround((kreedztime - (imin * 60.0 + isec))* 100.0, floatround_floor)
	
	new Float:kreedztimed = get_gametime() - timer_timed[id] //理论时间
	imind = floatround(kreedztimed / 60.0, floatround_floor)//理论时间
	isecd = floatround(kreedztimed - imind * 60.0,floatround_floor)//理论时间
	imsd = floatround((kreedztimed - (imind * 60.0 + isecd))* 100.0, floatround_floor)//理论时间

	if (oldtimed[id] == 0)
		oldtimed[id] = kreedztime
	
	if (oldtimed[id] > kreedztime)
		oldtimed[id] = kreedztime
	
	//TAB记分牌显示时间
	new oldminutes60 = (get_user_frags(id)*60)
	new oldtime = oldminutes60+cs_get_user_deaths(id)
	if (oldtime == 0)
	{
		set_user_frags(id, imin)
		cs_set_user_deaths(id, isec)
	} 
	else if (oldtime > kreedztime)
	{
		set_user_frags(id, imin)
		cs_set_user_deaths(id, isec)
	}	
 
	/*kz_dhud_message(id, 6.0, 0.55, "%L", id, "FINISH_CLIMB_WORD");*/
	new szRoute[64];
	new buffer[256];
	if (g_szSelRoute[id][0] != 0x0)
		formatex(szRoute, 63, " ^4%L^1 [%s]", id, "ROUTE", g_szSelRoute[id]);

	if (checknumbers[id] > 0)
	{
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (is_user_connected(i))
			{
				formatex(buffer, 255, "^4%s ^3%s ^4%L^3 %02i:%02i.%02i^4 ", prefix,
					name,
					i, "FINISH_TIME_CP",
					imin, isec, ims);
				formatex(buffer, 255, "%s(^1%02i:%02i.%02i^4) %L:^3%d^4 ", buffer,
					imind, isecd, imsd,
					i, "CHECKPOINT", checknumbers[id]);
				formatex(buffer, 255, "%s%L:^3%d^4 %L ^1[%s]%s", buffer,
					i, "GOCHECK", gochecknumbers[id],
					i, "DONE_COUNT", (nubcount[id] + 1),
					g_weaponsnames[user_use_wpn[id]], szRoute);
				ColorChat(i, GREEN, buffer);
			}
		}
	}
	else
	{
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (is_user_connected(i))
			{
				formatex(buffer, 255, "^4%s ^3%s ^4%L^3 %02i:%02i.%02i^4 ", prefix,
					name,
					i, "FINISH_TIME_NC",
					imin, isec, ims);
				formatex(buffer, 255, "%s%L ^1[%s]%s", buffer,
					i, "DONE_COUNT", (procount[id] + 1),
					g_weaponsnames[user_use_wpn[id]], szRoute);
				ColorChat(i, GREEN, buffer);
			}
		}
	}

	/*if (checknumbers[id] > 100)
	 	ColorChat(id, GREEN, "^4%s ^3存点超过100本次Top15不保存您的记录Sorry!!。", prefix)	*/	
}

//==========================================================
public Set_QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	if (iFailState != TQUERY_SUCCESS)
	{
		log_amx("[KZ] TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
		ColorChat(0, GREEN, "^4%s ^3警告: Top15无法保存数据请通知管理员。", prefix)
	}

	new id = cData[ID]
	new style = cData[TYPE]
	new cpnum = cData[CPNUM]
	new gpnum = cData[GPNUM]
	new table[10], speed[10], wpnwhere[32], wpnset[32]
	new createinto[1024]
	cData[ACTION] = UPDRECORD

	if (g_finish_time[id] < 0.0)
		g_finish_time[id] *= -1;

	switch (style)
	{
		case PRO_TOP:
		{
			copy(table, 9, "kz_pro15")
			if (g_finish_time[id] < e_WRtime)
				client_cmd(0, "speak misc/mod_godlike");
		}
		case NUB_TOP:
			copy(table, 9, "kz_nub15")
		case WPN_TOP:
			copy(table, 9, "kz_wpn15")
	}

	new dia[64], steam[32], name[128], ip[16], country[3], checkpoints[16], gochecks[16]
	new iMin, iSec, iMs
	get_time("%Y%m%d%H%M%S", dia, sizeof dia - 1)
	get_user_authid(id, steam, 31)
	get_user_name(id, name, sizeof name - 1)
	get_user_ip (id, ip, sizeof ip - 1, 1)
	geoip_code2_ex(ip, country)

	SqlEncode(name)

	server_print("===UPD TOP uid[%d] [%s] [%s]", g_nDzUid[id], steam, name);
	new curspeed = wpnspeed(id)
	new oldspeed[4]
	if (SQL_NumResults(hQuery) == 0)
	{
		formatex(checkpoints, 15, ", %d", cpnum)
		formatex(gochecks, 15, ", %d", gpnum)
		formatex(speed, 9, ", %d", curspeed)

		formatex(createinto, sizeof createinto - 1, "INSERT INTO `%s` VALUES(null, '%s', '%s','%s',CAST('%s' AS BINARY),%d,%f,'%s','%s',1,'%s'%s%s%s,'%s')", table, MapName, steam, country, name, g_nDzUid[id], floatabs(g_finish_time[id]), dia, g_weaponsnames[user_use_wpn[id]], g_szServer, style == PRO_TOP ? "" : checkpoints, style == PRO_TOP ? "" : gochecks, style == WPN_TOP ? speed : "", g_szSelRoute[id])
		SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", createinto, cData, 3)
	}
	else
	{
		new Float:oldtime, Float:thetime
		SQL_ReadResult(hQuery, 6, oldtime)
		oldspeed[0] = 0x0		
		new bool:bUpdate = false
		switch (style)
		{
			case PRO_TOP:
			{
				copy(table, 9, "kz_pro15")
				bUpdate = g_finish_time[id] < oldtime
			}
			case NUB_TOP:
			{
				copy(table, 9, "kz_nub15")
				bUpdate = g_finish_time[id] < oldtime
			}
			case WPN_TOP:
			{
				copy(table, 9, "kz_wpn15")
				SQL_ReadResult(hQuery, 13, oldspeed, 3)
				formatex(wpnwhere, 31, " AND speed>=%d", curspeed)
				formatex(wpnset, 31, "speed=%d, ", curspeed)
				//sxerver_print("oldspeed[%d] stroldspeed[%s]", str_to_num(oldspeed), oldspeed)
				bUpdate = curspeed < str_to_num(oldspeed)
				if (!bUpdate)
				{
					//sxerver_print("newtime[%f] oldtime[%f]", newtime, oldtime)
					bUpdate = g_finish_time[id] < oldtime && curspeed == str_to_num(oldspeed)
				}
			}
		}
		
		new stroldspeed[16]
		num_to_wpnname(stroldspeed, 15, str_to_num(oldspeed))

		if (bUpdate)
		{
			thetime = oldtime - g_finish_time[id]
			iMin = floatround(thetime / 60.0, floatround_floor)
			iSec = floatround(thetime - iMin * 60.0,floatround_floor)
			iMs = floatround((thetime - (iMin * 60.0 + iSec))* 100.0, floatround_floor)
			if (style != WPN_TOP)
			{
				ColorChat(id, GREEN, "^4%s ^3%L^4 %02i:%02i.%02i", prefix, id, "UPD_RECORD", id, (style == PRO_TOP ? "PRO" : "NUB"), iMin, iSec, iMs)
			}
			else
			{
				if (curspeed == str_to_num(oldspeed) && g_finish_time[id] < oldtime)
					ColorChat(id, GREEN, "^4%s ^3%L^4 %02i:%02i.%02i", prefix, id, "UPD_WPN_RECORD", iMin, iSec, iMs)
				else
					ColorChat(id, GREEN, "^4%s %L", prefix, id, "UPD_WPN_RECORD_EX", stroldspeed)
			}
			formatex(checkpoints, 31, ", checkpoints='%d'", cpnum)
			formatex(gochecks, 31, ", gochecks='%d'", gpnum)

			if (valid_steam(steam))
				formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET %stime=%f, weapon='%s', date='%s', server='%s',fincnt=fincnt+1 %s %s WHERE authid='%s' AND mapname='%s'%s", table, wpnset, floatabs(g_finish_time[id]), g_weaponsnames[user_use_wpn[id]], dia, g_szServer, style == PRO_TOP ? "" : gochecks, style == PRO_TOP ? "" : checkpoints, steam, MapName, wpnwhere)
			else
				if (g_nDzUid[id] > 0)
					formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET %stime=%f, weapon='%s', date='%s', server='%s',fincnt=fincnt+1 %s %s WHERE dzuid=%d AND mapname='%s'%s", table, wpnset, floatabs(g_finish_time[id]), g_weaponsnames[user_use_wpn[id]], dia, g_szServer, style == PRO_TOP ? "" : gochecks, style == PRO_TOP ? "" : checkpoints, g_nDzUid[id], MapName, wpnwhere)
				else
					formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET %stime=%f, weapon='%s', date='%s', server='%s',fincnt=fincnt+1 %s %s WHERE name=CAST('%s' AS BINARY)AND mapname='%s'%s", table, wpnset, floatabs(g_finish_time[id]), g_weaponsnames[user_use_wpn[id]], dia, g_szServer, style == PRO_TOP ? "" : gochecks, style == PRO_TOP ? "" : checkpoints, name, MapName, wpnwhere)

			SQL_ThreadQuery(g_SqlTuple, "DataQueryHandle", createinto, cData, 3)
		}
		else
		{
			if (style == WPN_TOP && curspeed == str_to_num(oldspeed))
				ColorChat(id, GREEN, "^4%s %L", prefix, id, "UPD_WPN_LOW", g_weaponsnames[user_use_wpn[id]], stroldspeed)
			else
			{
				thetime = g_finish_time[id] - oldtime
				iMin = floatround(thetime / 60.0, floatround_floor)
				iSec = floatround(thetime - iMin * 60.0,floatround_floor)
				iMs = floatround((thetime - (iMin * 60.0 + iSec))* 100.0, floatround_floor)
				ColorChat(id, GREEN, "^4%s ^3%L^4 %02i:%02i.%02i", prefix, id, "UPD_RECORD_SLOWLY", id, (style == PRO_TOP ? "PRO" : "NUB"), iMin, iSec, iMs);
			}

			if (valid_steam(steam))
				formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET fincnt=fincnt+1 WHERE authid='%s' AND mapname='%s'", table, steam, MapName)
			else
				if (g_nDzUid[id] > 0)
					formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET fincnt=fincnt+1 WHERE dzuid=%d AND mapname='%s'", table, g_nDzUid[id], MapName)
				else
					formatex(createinto, sizeof createinto - 1, "UPDATE `%s` SET fincnt=fincnt+1 WHERE name=CAST('%s' AS BINARY)AND mapname='%s'", table, name, MapName)

			SQL_ThreadQuery(g_SqlTuple, "QueryHandle", createinto)
		}
	}

	/*
	PRO_TOP = 0,
	WPN_TOP = 1,
	NUB_TOP = 2,
	TOP_NUL = 3,*/
	new bool:bUpdate1, bUpdate2, bUpdate3;
	bUpdate1 = false;
	bUpdate2 = false;
	bUpdate3 = false;
	if (style < e_TopType)
		bUpdate1 = true;
	if (curspeed < e_WpnSpeed && style == WPN_TOP)
		bUpdate2 = true;
	if (g_finish_time[id] < e_fTopTime && style == e_TopType && curspeed == e_WpnSpeed)
		bUpdate3 = true;
	if (bUpdate1 || bUpdate2 || bUpdate3)
	{
		e_fTopTime = g_finish_time[id]
		ClimbtimeToString(e_fTopTime, e_TopTime)
		copy(e_TopName, 31, name)
		SqlDecode(e_TopName)
		e_TopType = style
		if (e_TopType == WPN_TOP)
		{
			e_WpnSpeed = curspeed
			formatex(e_Weapon, 9, "(%s)", g_weaponsnames[user_use_wpn[id]])
		}
	}

	return PLUGIN_CONTINUE
}

public GetNewRank_QueryHandler(iFailState, Handle:hQuery, szError[], iErrnum, cData[], iSize, Float:fQueueTime)
{
	new id = cData[ID]
	new iType = cData[TYPE]
	new szType[10]
	if (iFailState != TQUERY_SUCCESS)
	{
		return log_amx("TOP15 SQL: SQL Error #%d - %s", iErrnum, szError)
	}

	new steam[32], authid[32], namez[32], name[32], i = 0
	get_user_authid(id, steam, 31)
	get_user_name(id, namez, 31)
	
	new route[32]
	if (g_szSelRoute[id][0] != 0x0)
		formatex(route, 31, "^1[%s]", g_szSelRoute[id])

	new bSteam = valid_steam(steam);
	new bool:bPre15 = false;
	while (SQL_MoreResults(hQuery))
	{
		i++
		if (!bSteam)
		{
			SQL_ReadResult(hQuery, 0, name, 31)
			if (equal(name, namez))
			{
				bPre15 = true;
				break;
			}
		}
		else
		{
			SQL_ReadResult(hQuery, 0, authid, 31)
			if (equal(authid, steam))
			{
				bPre15 = true;
				break;
			}
		}
		SQL_NextRow(hQuery)
	}

	if (bPre15 == true)
	{
		for (new j = 1; j <= g_iMaxPlayers; j++)
		{
			if (is_user_connected(j))
			{
				switch (iType)
				{
					case PRO_TOP:
						formatex(szType, 9, "%L", j, "PRO");
					case NUB_TOP:
						formatex(szType, 9, "%L", j, "NUB");
					case WPN_TOP:
						formatex(szType, 9, "%L", j, "WEAPON");
				}
				ColorChat(j, GREEN, "^4%s %L", prefix, j, "UPD_RECORD_RANK", namez, szType, i, route);
			}
		}
	}
	allowstart[id] = true

	if (i == 1) 
	{
		client_cmd(0, "spk %s", rankz);
		copy(g_szTopOneName[iType], 31, namez)
		SetRender(id, iType)
	}

	return PLUGIN_CONTINUE	
}

public SetRender(id, iType)
{
	if (!IsPlayer(id) || !is_user_connected(id))
		return PLUGIN_HANDLED;
	//SetPlrColor(g_iRender[iType])
	// 如果TOP渲染失败，则渲染类型(当前最快)
	if (SetPlrColor(id) == 0 && iType == PRO_TOP)
	{
		if (g_iCurFasterID != id && g_fCurFasterTimer > timer_time[id])
		{
			// 将上一个玩家染色为普通
			new szName[32];
			if (IsPlayer(g_iCurFasterID))
			{
				get_user_name(g_iCurFasterID, szName, 31);
				server_print("===set normal[%s]", szName);
				set_user_rendering(g_iCurFasterID, kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
			}
			/*entity_set_int(g_iCurFasterID[iType], EV_INT_rendermode, kRenderNormal)
			entity_set_vector(id, EV_VEC_rendercolor, g_fTopColor[CURRENT])
			entity_set_int(id, EV_INT_rendermode, kRenderTransColor)*/
			set_user_rendering(id, kRenderFxGlowShell, g_fTopColor[CURRENT][0], g_fTopColor[CURRENT][1], g_fTopColor[CURRENT][2], kRenderNormal, 40);
			g_fCurFasterTimer = timer_time[id];
			g_iCurFasterID = id;
			get_user_name(g_iCurFasterID, g_szCurFaterName, 31);
		}
	}

	return PLUGIN_CONTINUE;
}

public SetPlrColor(id)
{
	new bool:IsTask = false;
	if (id > TASK_SETCOLOR)
	{
		id -= TASK_SETCOLOR;
		IsTask = true;
	}

	if (!IsPlayer(id) || !is_user_connected(id))
		return -1;

	new iFlag = 0, szName[32];
	get_user_name(id, szName, 31);
	for (new i = 0; i < 3; i++)
		iFlag += ((equali(szName, g_szTopOneName[i]) ? 1 : 0) << i);

	server_print("=============SetPlrColor[%s] flag[%d]", szName, iFlag);

	if (iFlag)
	{
		/*entity_set_vector(id, EV_VEC_rendercolor, g_fTopColor[iFlag])
		entity_set_int(id, EV_INT_rendermode, kRenderTransColor)*/
		set_user_rendering(id, kRenderFxGlowShell, g_fTopColor[iFlag][0], g_fTopColor[iFlag][1], g_fTopColor[iFlag][2], kRenderNormal, 40)
	}
	else
	{
		//entity_set_int(id, EV_INT_rendermode, kRenderNormal)
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	}

	if (iFlag == 0 && IsTask == true && equali(szName, g_szCurFaterName))
	{
		set_user_rendering(id, kRenderFxGlowShell, g_fTopColor[CURRENT][0], g_fTopColor[CURRENT][1], g_fTopColor[CURRENT][2], kRenderNormal, 40);
	}
	
	return iFlag
}

public ChkSrvNum()
{
	new iNum = get_playersnum(1) - (g_hltv_id > 0 ? 1 : 0);
	if (iNum == 0)
	{
		g_SrvIdle++;
	}
	else
	{
		g_SrvIdle = 0;
	}
	if (g_SrvIdle >= 5)
	{
		if (!equali(g_szHotMap, MapName) && is_map_valid(g_szHotMap))
			server_cmd("changelevel %s", g_szHotMap);
		g_SrvIdle = 0;
	}
}

public ProTop_show(id)
{
	if (g_bRoute)
		routetopmenu(id, PRO_TOP)
	else
		kz_showhtml_motd(id, PRO_TOP, MapName)
	return PLUGIN_HANDLED
}

public NoobTop_show(id)
{
	if (g_bRoute)
		routetopmenu(id, NUB_TOP)
	else
		kz_showhtml_motd(id, NUB_TOP, MapName)
	return PLUGIN_HANDLED
}

public WpnTop_show(id)
{
	if (g_bRoute)
		routetopmenu(id, WPN_TOP)
	else
		kz_showhtml_motd(id, WPN_TOP, MapName)
	return PLUGIN_HANDLED
}

public ShowHelp(id)
{
	kz_showhtml_motd(id, SHOWHELP);
	return PLUGIN_HANDLED;
}

public PsRecs_show(id)
{
	new authid[32]
	get_user_authid(id, authid, 31);

	if (g_nDzUid[id] == 0 || !valid_steam(authid))
	{
		ColorChat(id, GREEN, "^4%s %L", prefix, id, "PS_RECORD_TTL");
		return PLUGIN_HANDLED
	}

	kz_showhtml_motd(id, PRO_RECORDS);

	return PLUGIN_HANDLED
}

stock kz_showhtml_motd(id, type, const map[] = "")
{
	new buffer[512], refresh[512], namebuffer[64], szLang[3], authid[32];
	get_user_info(id, "lang", szLang, charsmax(szLang));

	get_user_authid(id, authid, 31)
	if (valid_steam(authid))
		copy(refresh, 511, newversion)
	else
		copy(refresh, 511, oldversion)

	switch (type)
	{
		case WPN_TOP:
		{
			formatex(namebuffer, 63, "%L %s", id, "TOP_MENU_WPN", map)
			formatex(buffer, 511, refresh, website, "top15.php", "wpn", map, 0, "", szLang)
		}
		case PRO_TOP:
		{
			formatex(namebuffer, 63, "%L %s", id, "TOP_MENU_NC", map)
			formatex(buffer, 511, refresh, website, "top15.php", "pro", map, 0, "", szLang)
		}
		case NUB_TOP:
		{
			formatex(namebuffer, 63, "%L %s", id, "TOP_MENU_CP", map)
			formatex(buffer, 511, refresh, website, "top15.php", "nub", map, 0, "", szLang)
		}
		case PLAYERS_CLEANLIST:
		{
			formatex(namebuffer, 63, "%L", id, "TOP_MENU_CHECT")
			formatex(buffer, 511, refresh, website, "cleanlist.php", "", "", 0, "", szLang)
		}
		case PRO_RECORDS:
		{
			formatex(namebuffer, 63, "%L", id, "TOP_MENU_PS")
			new authid[32]
			get_user_authid(id, authid, 31)
			formatex(buffer, 511, refresh, website, "player.php", "", "", g_nDzUid[id], authid, szLang)
		}
		case PLAYERS_RANKING:
		{
			formatex(namebuffer, 63, "%L", id, "TOP_MENU_PLR")
			formatex(buffer, 511, refresh, website, "players.php", "", "", 0, "", szLang)
		}
		case LASTTOP:
		{
			formatex(namebuffer, 63, "%L", id, "TOP_MENU_NEW")
			formatex(buffer, 511, refresh, website, "last15.php", "", map, 0, "", szLang)
		}
		case MAPS_STATISTIC:
		{
			formatex(buffer, 511, refresh, website, "index.php", "", map, 0, "", szLang)
		}
		case SHOWHELP:
		{
			formatex(namebuffer, 63, "%L", id, "TOP_MENU_HELP")
			formatex(buffer, 511, refresh, website, "help.php", "", "", 0, "", szLang)
		}
		case CHALLENGETOP:
		{
			formatex(namebuffer, 63, "%L", id, "CHL_MENU_TOP")
			formatex(buffer, 511, refresh, website, "challenge.php", "", "", 0, "", szLang)
		}
		case CHALLENGETOP_LOG:
		{
			formatex(namebuffer, 63, "%L", id, "CHL_MENU_TOP_LOG")
			formatex(buffer, 511, refresh, website, "challenge.php", "log", "", 0, "", szLang)
		}
	}

	show_motd(id, buffer, namebuffer)
}

ClimbtimeToString(const Float:flClimbTime, szOutPut[]){
	new iLen = 8;
	if (!flClimbTime){
		copy(szOutPut, iLen, "--:--.--");
		return;
	}
	
	new iMinutes = floatround(flClimbTime / 60.0, floatround_floor);
	new iSeconds = floatround(flClimbTime - iMinutes * 60, floatround_floor);
	new iMiliSeconds = floatround((flClimbTime - (iMinutes * 60 + iSeconds))* 100 , floatround_round);
	
	formatex(szOutPut, iLen, "%02i:%02i.%02i", iMinutes, iSeconds, iMiliSeconds);
}

/*
public CreateRoute(szTarget[], Float:fOrigin[3], Float:fAngles[3])
{
	new ent = create_entity("info_target");
	if (is_valid_ent(ent))
	{
		entity_set_string(ent, EV_SZ_classname, "iwan_route");
		entity_set_string(ent, EV_SZ_target, szTarget);
		entity_set_int(ent, EV_INT_solid, equali(szTarget, "block") ? SOLID_BBOX : SOLID_TRIGGER);
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE);
		entity_set_origin(ent, fOrigin);
		entity_set_vector(ent, EV_VEC_angles, fAngles);
		entity_set_model(ent, KZ_ROUTEMDL);
		entity_set_int(ent, EV_INT_rendermode, kRenderTransAlpha);
		entity_set_int(ent, EV_INT_renderfx, kRenderFxGlowShell);
		new Float:fColor[3];
		fColor[0] = random_float(0.0, 255.0);
		fColor[1] = random_float(0.0, 255.0);
		fColor[2] = random_float(0.0, 255.0);
		entity_set_size(ent, Float:{-24.0, -24.0, -24.0}, Float:{24.0, 24.0, 24.0});
		entity_set_vector(ent, EV_VEC_rendercolor, fColor);
		entity_set_int(ent, EV_INT_rendermode, kRenderTransColor);
		entity_set_float(ent, EV_FL_renderamt, 1.0);
	}
}
*/

public CreateRoute(szClassName[], szTarget[], Float:fOrigin[3], Float:fMins[3], Float:fMaxs[3])
{
	new ent = create_entity("info_target");
	if (is_valid_ent(ent))
	{
		entity_set_string(ent, EV_SZ_classname, szClassName);
		entity_set_string(ent, EV_SZ_target, szTarget);
		entity_set_model(ent, KZ_ROUTEMDL);
		entity_set_origin(ent, fOrigin);

		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY);
		entity_set_int(ent, EV_INT_solid, equali(szTarget, "block") ? SOLID_BBOX : SOLID_TRIGGER);
		entity_set_size(ent, fMins, fMaxs);
		entity_set_int(ent, EV_INT_rendermode, kRenderTransAlpha);
		entity_set_float(ent, EV_FL_renderamt, 0.0);
	}
}
/*
public CreateZone(Float:position[3], Float:mins[3], Float:maxs[3], zm) {
	new entity = fm_create_entity("info_target")
	set_pev(entity, pev_classname, "iwan_route")
	fm_entity_set_model(entity, KZ_ROUTEMDL)
	fm_entity_set_origin(entity, position)

	set_pev(entity, pev_movetype, MOVETYPE_FLY)
	new id = pev(entity, ZONEID)
	set_pev(entity, pev_solid, solidtyp[ZONEMODE:id])

	fm_entity_set_size(entity, mins, maxs)
	
	fm_set_entity_visibility(entity, 0)

	set_pev(entity, ZONEID, zm)

	return entity
}*/

public SelectRoute(iEnt, id)
{
	new szTarget[32];
	entity_get_string(iEnt, EV_SZ_target, szTarget, 31);

	if (equali(szTarget, "error"))
	{
		timer_started[id] = false;
		reset_checkpoints(id);
		goStart(id);
		return;
	}
	else if (equali(szTarget, "block"))
	{
		return;
	}

	new nGroupId = g_nGroupId[id];
	if (g_bGroupStart[nGroupId])
	{
		if ((szTarget[0] == 0x0 && g_nGroupRoute[nGroupId] != 0) || (!equal(szTarget, g_szRoute[g_nGroupRoute[nGroupId]])))
		{
			goStart(id);
		}
	}

	if (g_szSelRoute[id][0] != 0x0)
	{
		if (!equal(szTarget, g_szSelRoute[id]))
		{
			goStart(id);
			reset_checkpoints(id);
			kz_chat(id, "%L", id, "RESET_TIMER_ROUTE");
		}
	}
	else
	{
		copy(g_szSelRoute[id], ROUTESIZE, szTarget);
		kz_chat(id, "%L %s", id, "ROUTE", szTarget);
	}
}

public CupRoute(iEnt, id)
{
	new nGroupId = g_nGroupId[id];
	if (g_bCupRoute && g_bGroupStart[nGroupId])
	{
		new szTarget[32];
		entity_get_string(iEnt, EV_SZ_target, szTarget, 31);
		if (str_to_num(szTarget) == g_nGroupEndTag[nGroupId])
			ChallengeEnd(id, 0, group_tag:FINISH);
	}
}

public yhextend(id)
{
	if (get_pcvar_num(kz_cup_start) == 1)
		return;

	if (g_nDzUid[id] != 15253)
		return;
	new arg[32];
	read_argv(1, arg, 31);
	new Float:curlimit = get_cvar_float("mp_timelimit");
	new Float:newlimit = float(abs(floatround(curlimit))) + str_to_float(arg);
	set_cvar_float("mp_timelimit", newlimit);
}

public checkotherplugin(id)
{
	return 456212;
}

public Weapons_Deploy(iWeapon)// 锁定武器功能
{
	// want to filter by player id ?
//	new id = get_pdata_cbase(iWeapon, m_pPlayer, XO_WEAPONS)
	// want to filter by weapon type ?
	// would be better not to register the corresponding weapon classname
	// but you may mix player+weapontype filters...
//	new iId = get_pdata_int(iWeapon, m_iId, XO_WEAPONS)// you can use cs_get_weapon_id as well
	// 99999.0 = 27hours, should be enough.

	// 左键
	//set_pdata_float(iWeapon, m_flNextPrimaryAttack, 99999.0, XO_WEAPONS)

	cs_set_weapon_silen(iWeapon, 1, 0);
	// 右键
	if (iWeapon == CSW_AWP || iWeapon == CSW_M249 || iWeapon == CSW_SCOUT)
		set_pdata_float(iWeapon, m_flNextSecondaryAttack, 99999.0, XO_WEAPONS)

	// also want to block +use ? (may block other things as impulse(impulse are put in a queue))
	// set_pdata_float(id, m_flNextAttack, 99999.0, XO_PLAYER)
}

public JoinCT(id)
{
	set_user_noclip(id);
	cs_set_user_team(id,CS_TEAM_CT);
	set_pev(id, pev_effects, 0);
	set_pev(id, pev_movetype, MOVETYPE_WALK);
	set_pev(id, pev_deadflag, DEAD_NO);
	set_pev(id, pev_takedamage, DAMAGE_AIM);
	CmdRespawn(id);
}

public JoinSpec(id)
{
	cs_set_user_team(id, CS_TEAM_SPECTATOR);
	set_pev(id, pev_solid, SOLID_NOT);
	set_pev(id, pev_movetype, MOVETYPE_FLY);
	set_pev(id, pev_effects, EF_NODRAW);
	set_pev(id, pev_deadflag, DEAD_DEAD);
}

public BattleMenu(id)
{
	new buffer[512];
	formatex(buffer, 511, "%L^n\r%L\w", id, "MAIN_MENU_CONSOLE", "bind f4 battlemenu", id, "CHL_MENU_TITLE");
	new menu = menu_create(buffer, "BattleMenuHandler");

	formatex(buffer, 511, "%s%L^n", (g_nGetScore[id] ? "\d" : "\w"), id, "CHL_MENU_1V1");
	//menu_additem(menu, buffer);
	//formatex(buffer, 255, "%s发起全体宣战[未开放]    \dsay /1vn^n", (g_nGetScore[id] ? "\d" : "\w"));

	if (g_nGetScore[id])
	{
		formatex(buffer, 511, "%s    \d%L", buffer, id, "CHL_MENU_GETDATA");
	}
	else if (g_nDzUid[id] > 0)
	{
		formatex(buffer, 511, "%s    %L\y%d^n", buffer, id, "CHL_YOUR_LVL", g_nGroupScore[id][score_tag:LEVEL]);
		formatex(buffer, 511, "%s    \w%L^n", buffer, id, "CHL_MEM_EX1", g_nGroupScore[id][score_tag:WIN], g_nGroupScore[id][score_tag:LOSE], g_nGroupScore[id][score_tag:DRAW]);
		formatex(buffer, 511, "%s    \w%L^n", buffer, id, "CHL_MEM_EX2", g_nGroupScore[id][score_tag:INVITE], g_nGroupScore[id][score_tag:ACCEPT], g_nGroupScore[id][score_tag:REJECT]);
		formatex(buffer, 511, "%s    \w%L", buffer, id, "CHL_MEM_EX3", g_nGroupScore[id][score_tag:ESCAPE], g_nGroupScore[id][score_tag:SCORE], g_nGroupScore[id][score_tag:CHALLENGE]);
	}
	else
	{
		formatex(buffer, 511, "%s    \w%L^n", buffer, id, "CHL_MENU_NON_EX1");
		formatex(buffer, 511, "%s    \w%L^n", buffer, id, "CHL_MENU_NON_EX2");
		formatex(buffer, 511, "%s    \w%L^n", buffer, id, "CHL_MENU_NON_EX3");
		formatex(buffer, 511, "%s    \r%L", buffer, id, "CHL_MENU_NON_EX4");
	}
	menu_additem(menu, buffer);
	formatex(buffer, 64, "%L \y%L", id, "CHL_MENU_BLOCK", id, (g_bAccept[id] ? "ON" : "OFF"));
	menu_additem(menu, buffer);
	formatex(buffer, 64, "%L", id, "CHL_MENU_TOP");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "%L", id, "CHL_MENU_TOP_LOG");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "%s等级皮肤", (g_nGroupScore[id][score_tag:LEVEL] > 0 ? "\w" : "\d"));
	menu_additem(menu, buffer);

	menu_display(id, menu);
	return PLUGIN_HANDLED  
}

public BattleMenuHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /1v1");
		}
		/*case 1:
		{
			client_cmd(id, "say /1vn");
		}*/
		case 1:
		{
			g_bAccept[id] = !g_bAccept[id];
			BattleMenu(id);
		}
		case 2:
		{
			kz_showhtml_motd(id, CHALLENGETOP);
			BattleMenu(id);
		}
		case 3:
		{
			kz_showhtml_motd(id, CHALLENGETOP_LOG);
			BattleMenu(id);
		}
		case 4:
		{
			LevelSkinMenu(id);
		}
	}
	return PLUGIN_HANDLED
}

public LevelSkinMenu(id)
{
	if (g_nGroupScore[id][score_tag:LEVEL] <= 0)
	{
		ColorChat(id, GREEN, "^4[97Club] ^1当前等级无可用皮肤");
		BattleMenu(id);
	}
	new buffer[512];
	formatex(buffer, 511, "挑战等级皮肤(暂未开放)");
	new menu = menu_create(buffer, "LevelSkinMenuHandler");

	formatex(buffer, 64, "一级皮肤");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "二级皮肤");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "三级皮肤");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "四级皮肤");
	menu_additem(menu, buffer);
	formatex(buffer, 64, "五级皮肤");
	menu_additem(menu, buffer);

	menu_display(id, menu);
	return PLUGIN_HANDLED  
}

public LevelSkinMenuHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}

public ZzListMenu(id)
{
	new buffer[256];
	formatex(buffer, 255, "%L", id, "ZZ_MENU_TITLE");
	new menu = menu_create(buffer, "zzlist_menu_handler");

	formatex(buffer, 63, "%L", id, "ZZ_MENU_DTL");
	menu_additem(menu, buffer);
	for (new i = 0; i < ZZCOUNT; ++i)
	{
		menu_additem(menu, zzList[i]);
	}

	g_nPage[id] = 0;
	menu_display(id, menu, g_nPage[id]);
	return PLUGIN_CONTINUE;
}

public zzlist_menu_handler(id, menu, item)
{
	switch (item)
	{
		case MENU_EXIT:
		{
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case 0:
		{
			ColorChat(id, GREEN, "^4[97Club-CUP] ^1暂未开通");
		}
	}

	ZzListMenu(id);
	return PLUGIN_HANDLED;
}

public ChallengeEnd(nWinId, nLosId, group_tag:type)
{
	new nGroupId = 0;
	new Losers, Winner, WonUID, LostUID;
	if (nWinId > 0)
	{
		nGroupId = g_nGroupId[nWinId];
		if (g_nGroupPeople[nGroupId][SENDER] == nWinId)
		{
			Losers = g_nGroupPeople[nGroupId][RECVER];
			Winner = g_nGroupPeople[nGroupId][SENDER];
			WonUID = g_nGroupUid[nGroupId][SENDER];
			LostUID = g_nGroupUid[nGroupId][RECVER];
		}
		else
		{
			Losers = g_nGroupPeople[nGroupId][SENDER];
			Winner = g_nGroupPeople[nGroupId][RECVER];
			WonUID = g_nGroupUid[nGroupId][RECVER];
			LostUID = g_nGroupUid[nGroupId][SENDER];
		}
	}
	else if (nLosId > 0)
	{
		nGroupId = g_nGroupId[nLosId];
		if (g_nGroupPeople[nGroupId][SENDER] == nLosId)
		{
			Losers = g_nGroupPeople[nGroupId][SENDER];
			Winner = g_nGroupPeople[nGroupId][RECVER];
			WonUID = g_nGroupUid[nGroupId][RECVER];
			LostUID = g_nGroupUid[nGroupId][SENDER];
		}
		else
		{
			Losers = g_nGroupPeople[nGroupId][RECVER];
			Winner = g_nGroupPeople[nGroupId][SENDER];
			WonUID = g_nGroupUid[nGroupId][SENDER];
			LostUID = g_nGroupUid[nGroupId][RECVER];
		}
	}
	
	if (nGroupId == 0)
		return;


	new buffer[192];
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (is_user_connected(i))
		{
			if (type == group_tag:FINISH)
				formatex(buffer, 191, "%L", i, "CHL_WHOWIN", g_nPeopleName[Winner], g_nPeopleName[Losers]);
			else
				formatex(buffer, 191, "%L", i, "CHL_END", g_nPeopleName[Losers], i, (type == group_tag:ESCAPE ? "CHL_ESCAPE" : "CHL_GIVEUP"), g_nPeopleName[Winner]);
			kz_dhud_message(i, 3.0, 0.3, buffer);
			ColorChat(i, GREEN, "^4[97Club] %s", buffer);
		}
	}

	if (WonUID > 0 && LostUID > 0) // 双方都有积分才做积分加减
	{
		g_nGroupScore[Winner][score_tag:WIN]++;		// 胜利
		g_nGroupScore[Losers][score_tag:LOSE]++;	// 失败
		new Float:challengetime = get_gametime() - g_nGroupTimer[nGroupId];
		ChallengeScoreChg(WonUID, "win");
		// 胜利
		new szQuery[256], szEscape[20];
		//format(szQuery, 255, "UPDATE kz_challenge SET win=win+1 WHERE uid = %d", g_nDzUid[Winner]);
		//SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);

		// 失败 +| 逃跑
		if (type == group_tag:ESCAPE)
		{
			formatex(szEscape, 19, ", `escape`=`escape`+1")
			g_nGroupScore[Losers][score_tag:ESCAPE]++;	// 逃跑
		}
		format(szQuery, 255, "UPDATE kz_challenge SET `lose`=`lose`+1%s WHERE uid = %d", szEscape, LostUID);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);

		// 认输
		if (type == group_tag:GIVEUP)
		{
			ChallengeScoreChg(LostUID, "escape");
			g_nGroupScore[Losers][score_tag:ESCAPE]++;	// 认输算逃跑
		}

		new nLevelSum = g_nGroupScore[Winner][score_tag:LEVEL] - g_nGroupScore[Losers][score_tag:LEVEL];
		new nScore = 50;
		if (nLevelSum > 0)
		{
			nScore = nScore / (nLevelSum + 1);
		}
		else if (nLevelSum < 0)
		{
			nScore = nScore * (abs(nLevelSum) / 3 + 1);
		}
		
		if (g_nGroupScore[Losers][score_tag:SCORE] < nScore)
			nScore = g_nGroupScore[Losers][score_tag:SCORE];

		format(szQuery, 255, "INSERT INTO kz_challenge_log VALUE (%d,%d,%d,%d,%d,%d,'%s','%s',null)",
			WonUID, LostUID,
			g_nPeopleName[Winner], g_nPeopleName[Losers],
			g_nGroupScore[Winner][score_tag:SCORE], g_nGroupScore[Losers][score_tag:SCORE],
			nScore, challengetime, 0, // 0表示赢
			MapName, g_szServer);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
		format(szQuery, 255, "INSERT INTO kz_challenge_log VALUE (%d,%d,%d,%d,%d,%d,'%s','%s',null)",
			LostUID, WonUID,
			g_nPeopleName[Losers], g_nPeopleName[Winner],
			g_nGroupScore[Losers][score_tag:SCORE], g_nGroupScore[Winner][score_tag:SCORE],
			nScore, challengetime, 1, // 0表示输
			MapName, g_szServer);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);

		g_nGroupScore[Winner][score_tag:SCORE] += nScore;
		g_nGroupScore[Losers][score_tag:SCORE] -= nScore;

		g_nGroupScore[Winner][score_tag:LEVEL] = g_nGroupScore[Winner][score_tag:SCORE] / 200 - 5;
		g_nGroupScore[Losers][score_tag:LEVEL] = g_nGroupScore[Losers][score_tag:SCORE] / 200 - 5;

		ColorChat(Winner, GREEN, "^4[97Club] ^1%L^4 %d", Winner, "CHL_INCRS", nScore);
		ColorChat(Losers, GREEN, "^4[97Club] ^1%L^4 %d", Losers, "CHL_DISCRS", nScore);
		format(szQuery, 255, "UPDATE kz_challenge SET score=score+%d WHERE uid = %d", nScore, WonUID);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
		format(szQuery, 255, "UPDATE kz_challenge SET score=score-%d WHERE uid = %d", nScore, LostUID);
		SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
	}
	g_nGroupPeople[nGroupId][SENDER] = 0;
	g_nGroupPeople[nGroupId][RECVER] = 0;
	g_nGroupUid[nGroupId][SENDER] = 0;
	g_nGroupUid[nGroupId][RECVER] = 0;
	g_nGroupTimer[nGroupId] = 0.0;
	g_nGroupId[Losers] = 0;
	g_nGroupId[Winner] = 0;
}

public ChallengeScoreChg(uid, szColumn[])
{
	new szQuery[256];
	format(szQuery, 255, "UPDATE kz_challenge SET `%s`=`%s`+1 WHERE uid = %d", szColumn, szColumn, uid);
	SQL_ThreadQuery(g_SqlTuple, "QueryHandle", szQuery);
}

public GiveUp(id)
{
	if (!g_bGroupStart[g_nGroupId[id]])
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CHL_CANT_GIVEUP");
		return PLUGIN_HANDLED;
	}
	GiveUpMenu(id);
	return PLUGIN_CONTINUE;
}

public GiveUpMenu(id)
{
	new buffer[256];
	formatex(buffer, 255, "%L", id, "GIVEUP_MENU_TITLE");
	new menu = menu_create(buffer, "GiveUpMenuHandler");

	g_nGroupGiveUp[id] = random_num(0, 7);
	for (new i = 0; i < 8; i++)
	{
		formatex(buffer, 255, "%L", id, (i == g_nGroupGiveUp[id] ? "GIVEUP_MENU_YEP" : "GIVEUP_MENU_NOT"));
		menu_additem(menu, buffer);
	}

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(id, menu);
	return PLUGIN_HANDLED  
}

public GiveUpMenuHandler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	if (item == g_nGroupGiveUp[id])
		ChallengeEnd(0, id, group_tag:GIVEUP);

	return PLUGIN_HANDLED
}

public CmdAccept(id)
{
	g_bAccept[id] = !g_bAccept[id];
	ColorChat(id, GREEN, "^4[97Club] %L", id, "CHL_SET_BLOCK", id, (g_bAccept[id] ? "ACCEPT" : "REJECT"));
}

public ChallengeDelay(id)
{
}

// tiaozhan
stock ChallengePreCheck(id)
{
	if (get_pcvar_num(kz_cup) == 1)
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_CUP");
		return -1;
	}

	if (g_fTopFastTime < 90.0 && g_nGetScore[id] == true && g_nGroupScore[id][score_tag:LEVEL] < 0)
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_NOTIME");
		return -1;
	}
	
	new taskid = TASK_CHALLENGEDELAY + id;
	#define CHALLENGE_DELAY_TIME		60
	if (task_exists(taskid))
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_DELAY", CHALLENGE_DELAY_TIME);
		return -1;
	}
	
	set_task(float(60), "ChallengeDelay", taskid);
	
	/*if (timer_started[id])
	{
		ColorChat(id, GREEN, "^4[97Club] ^1计时中，无法使用该功能");
		return -1;
	}*/

	if (!DefaultStart)
	{
		ColorChat(id, RED, "^4[97Club] %L", id, "CANT_CHL_NOSTART");
		return -1;
	}

	if (g_bAccepting[id])
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_CHOOSE");
		return -1;
	}

	if (g_nGroupId[id] > 0)
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_START");
		return -1;
	}

	g_menuPlayersNum[id] = 0;
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i) && i != id)
		{
			g_menuPlayers[id][g_menuPlayersNum[id]++] = i;
		}
	}
	
	if (g_menuPlayersNum[id] < 1)
	{
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_PLRLACK");
		return -1;
	}

	return 0;
}

stock InitGroup(id, Recver)
{
	new nGroupId = g_nGroupId[id];
	if (nGroupId > 0)
	{
		if (Recver > 0)
		{
			g_nGroupPeople[nGroupId][RECVER] = Recver;
			if (g_nDzUid[Recver] > 0)
			{
				g_nGroupUid[nGroupId][RECVER] = g_nDzUid[Recver];
			}
			get_user_name(Recver, g_nPeopleName[Recver], 31);
		}
		if (g_nGroupEndTag[nGroupId] > 0)
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		return nGroupId;
	}
	for (new i = 1; i < 17; i++)
	{
		if (g_nGroupPeople[i][0] == 0 && g_nGroupPeople[i][1] == 0)
		{
			g_nGroupId[id] = i;
			if (g_nDzUid[id] > 0)
			{
				g_nGroupUid[i][SENDER] = g_nDzUid[id];
			}
			else
			{
				g_nGroupUid[i][SENDER] = 0;
			}
			g_nGroupPeople[i][SENDER] = id;
			if (Recver > 0)
			{
				g_nGroupPeople[i][RECVER] = Recver;
				get_user_name(Recver, g_nPeopleName[Recver], 31);
			}
			get_user_name(id, g_nPeopleName[id], 31);
			g_nGroupPoint[i] = false;
			//g_bCustomFinish[i] = false;
			g_bGroupStart[i] = false;
			g_nGroupRoute[i] = 0;
			g_nGroupEndTag[i] = 0;
			g_nGroupWeapon[i] = 1;	// 排除鸟枪
			return i;
		}
	}

	return 0;
}

public ChallengeMenu(id)
{
	if (ChallengePreCheck(id) == -1)
		return PLUGIN_HANDLED;

	new buffer[256], name[32], szPoint[128], szColor[3];
	formatex(buffer, 255, "%L \wWwW.27015.CoM", id, "CHL_1V1_MENU_TITLE");
	new menu = menu_create(buffer, "challenge_menu_handler");

	for (new i = 0; i < g_menuPlayersNum[id]; ++i)
	{
		new iPlayer = g_menuPlayers[id][i];
		get_user_name(iPlayer, name, 31);
		szPoint[0] = 0x0;
		formatex(szColor, 2, "%s", ((g_nGroupId[iPlayer] == 0 && g_bAccept[iPlayer] && !g_bAccepting[iPlayer] && !g_bInvite[iPlayer] && !g_nGetScore[iPlayer]) ? "\w" : "\d"));
		if (g_nDzUid[iPlayer] > 0)
			formatex(szPoint, 127, "%s %L(%d)", szColor, id, "SCORE", g_nGroupScore[iPlayer][score_tag:SCORE]);
		formatex(buffer, 255, "%s[%L]%s %s", szColor, id, (g_nGetScore[iPlayer] ? "CHL_1V1_MENU_GETDATE" : (g_bInvite[iPlayer] ? "CHL_1V1_MENU_INVITE" : (g_nGroupId[iPlayer] > 0 ? (g_bAccepting[iPlayer] ? "CHL_1V1_MENU_ACCEPT" : "CHL_1V1_MENU_CHLING") : (g_bAccept[iPlayer] ? (g_nDzUid[iPlayer] > 0 ? "CHL_1V1_MENU_ENABLE" : "CHL_1V1_MENU_NOSCORE") : "CHL_1V1_MENU_BLOCK")))), name, szPoint);
		menu_additem(menu, buffer);
	}

	g_bInvite[id] = true;

	g_nPage[id] = 0;
	menu_display(id, menu, g_nPage[id]);
	return PLUGIN_HANDLED;
}

public challenge_menu_handler(id, menu, item)
{
	switch (item)
	{
		case MENU_EXIT:
		{
			//new nGroupId = g_nGroupId[id];
			//CleanGroup(id, 0, nGroupId, group_tag:NONOTIFY);
			g_bInvite[id] = false;
			menu_destroy(menu);
			return PLUGIN_HANDLED;
		}
		case MENU_MORE:
		{
			menu_display(id, menu, ++g_nPage[id]);
		}
		case MENU_BACK:
		{
			menu_display(id, menu, --g_nPage[id]);
		}
		case -4:
		{
			g_bInvite[id] = false;
		}
		default:
		{
			new iPlayer = g_menuPlayers[id][item];
			if (IsPlayer(iPlayer) && iPlayer != id)
			{
				if (g_nGroupId[iPlayer] > 0)
				{
					ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_START");
				}
				else if (g_bAccepting[iPlayer])
				{
					ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_ACCEPT");
				}
				else if (g_bInvite[iPlayer])
				{
					ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_INVITE");
				}
				else if (g_nGetScore[iPlayer])
				{
					ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_GETDATA");
				}
				else if (g_fTopFastTime < 90.0 && g_nGetScore[iPlayer] == true && g_nGroupScore[iPlayer][score_tag:LEVEL] < 0)
				{
					ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_TOOLOW");
				}
				else
				{
					if (g_bAccept[iPlayer] == true)
					{
						InitGroup(id, iPlayer);
						ConfirmMenu(id, iPlayer);
						g_bInvite[id] = false;
						return PLUGIN_HANDLED;
					}
					else
						ColorChat(id, GREEN, "^4[97Club] %L", id, "CANT_CHL_OPPO_BLOCK");
				}
			}
		}
	}

	g_bInvite[id] = false;
	menu_destroy(menu);
	ChallengeMenu(id);
	return PLUGIN_HANDLED;
}

public ConfirmMenu(Sender, Recver)
{
	new menu[1024];

	formatex(menu, 1023, "%L", Sender, "CHL_CONFIRM_TITLE", g_nPeopleName[Recver]);
	formatex(menu, 1023, "%s^n\r1\w. %L", menu, Sender, "CHL_CONFIRM_NOT");
	if (g_nDzUid[Recver] <= 0 && g_nDzUid[Sender] > 0)
	{
		client_cmd(Sender, "spk sound/buttons/button10.wav")
		formatex(menu, 1023, "%s%L", menu, Sender, "CHL_CONFIRM_WARNING");
	}
	else
	{
		formatex(menu, 1023, "%s    \w%L\y%d^n", menu, Sender, "CHL_OPPO_LVL", g_nGroupScore[Recver][score_tag:LEVEL]);
		formatex(menu, 1023, "%s    \w%L^n", menu, Sender, "CHL_MEM_EX1", g_nGroupScore[Recver][score_tag:WIN], g_nGroupScore[Recver][score_tag:LOSE], g_nGroupScore[Recver][score_tag:DRAW]);
		formatex(menu, 1023, "%s    \w%L^n", menu, Sender, "CHL_MEM_EX2", g_nGroupScore[Recver][score_tag:INVITE], g_nGroupScore[Recver][score_tag:ACCEPT], g_nGroupScore[Recver][score_tag:REJECT]);
		formatex(menu, 1023, "%s    \w%L^n", menu, Sender, "CHL_MEM_EX3", g_nGroupScore[Recver][score_tag:ESCAPE], g_nGroupScore[Recver][score_tag:SCORE], g_nGroupScore[Recver][score_tag:CHALLENGE]);
	}

	/*if (g_bRoute)
		formatex(menu, 1023, "%s^n\r2\w. \r选择线路分支：[%s]\w", g_szRoute[g_nGroupRoute[g_nGroupId[Sender]]]);*/
	formatex(menu, 1023, "%s^n\r0\w. %L", menu, Sender, "CHL_CONFIRM_YEP");

	show_menu(Sender, MENU_KEY_1 + MENU_KEY_0, menu, -1, "ConfirmMenu");
}

public ConfirmMenuAction(id, key)
{
	new Sender, Recver;
	new nGroupId = g_nGroupId[id];
	Sender = g_nGroupPeople[nGroupId][SENDER];
	Recver = g_nGroupPeople[nGroupId][RECVER];
	if (key == 0)
	{
		g_nGroupPeople[nGroupId][SENDER] = 0;
		g_nGroupPeople[nGroupId][RECVER] = 0;
		g_nGroupId[id] = 0;
	}/*
	else if (key == 1)
	{
		g_nGroupRoute[nGroupId]++;
		if (g_szRoute[g_nGroupRoute[nGroupId]][0] == 0x0)
		{
			g_nGroupRoute[nGroupId] = 0;
		}
	}*/
	else
	{
		new buffer[192];
		g_nGroupId[Recver] = nGroupId;
		g_nGroupRemaining[nGroupId] = GROUP_REMAINING_DEFAULT;
		pev(Sender, pev_origin, g_fSourcePos[Sender]);
		AcceptChallengeMenu(Recver);
		ColorChat(id, GREEN, "^4[97Club] %L", id, "CHL_INVITED");
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (is_user_connected(i))
			{
				formatex(buffer, 191, "%L", i, "CHL_INVITE_TTL", g_nPeopleName[Sender], g_nPeopleName[Recver]);
				kz_dhud_message(i, 3.0, 0.3, buffer);
				ColorChat(i, GREEN, "^4[97Club] %s", buffer);
			}
		}
		set_task(2.0, "tsk_acm", TASK_ACCEPTMENU + nGroupId, _, _, "b");
		if (g_nGroupUid[nGroupId][SENDER] > 0 && g_nGroupUid[nGroupId][RECVER] > 0)
		{
			g_nGroupScore[id][score_tag:INVITE]++;
			ChallengeScoreChg(g_nGroupUid[nGroupId][SENDER], "invite");  // 邀请
		}
	}
}

public tsk_acm(taskid)
{
	new Recver, Sender, nGroupId;
	nGroupId = taskid - TASK_ACCEPTMENU;
	Sender = g_nGroupPeople[nGroupId][SENDER];
	Recver = g_nGroupPeople[nGroupId][RECVER];
	g_nGroupRemaining[nGroupId] -= 2;
	if (g_nGroupRemaining[nGroupId] < 2)
	{
		CleanGroup(Sender, Recver, nGroupId, group_tag:TIMEOUT);
		remove_task(taskid);
		return;
	}

	AcceptChallengeMenu(Recver);
}

public AcceptChallengeMenu(Recver)
{
	new buffer[256], route[128];

	new nGroupId = g_nGroupId[Recver];
	new Sender = g_nGroupPeople[nGroupId][SENDER];
	//new Recver = g_nGroupPeople[nGroupId][RECVER];
	if (g_bAccepting[Recver] == false)
	{
		if (timer_started[Recver] && !IsPaused[Recver])
		{
			Pause(Recver);
			formatex(route, 191, "%L", Recver, "CHL_PAUSED");
		}
		pev(Recver, pev_origin, g_fSourcePos[Recver]);
		formatex(buffer, 191, "%L", Recver, "CHL_CHOOSE", route);
		kz_dhud_message(Recver, 3.0, 0.4, buffer);
		ColorChat(Recver, GREEN, "^4[97Club] %s", buffer);
		if (g_nDzUid[Sender] <= 0 && g_nDzUid[Recver] > 0)
		{
			client_cmd(Recver, "spk sound/buttons/button10.wav");
		}

		g_bAccepting[Recver] = true;
	}

	formatex(buffer, 255, "%L", Recver, "CHL_ACP_MENU_TITLE", g_nPeopleName[Sender]);
	if (g_nDzUid[Sender] <= 0 && g_nDzUid[Recver] > 0)
	{
		format(buffer, 255, "%s%L", buffer, Recver, "CHL_ACP_MENU_WARNING");
	}
	new menu = menu_create(buffer, "accept_challenge_menu_handler");

	new level[256];
	if (g_nDzUid[Sender] > 0 && g_nDzUid[Recver] > 0)
		formatex(level, 255, "       \w%L\y%d^n", Recver, "CHL_OPPO_LVL", g_nGroupScore[Sender][score_tag:LEVEL]);
	else
		formatex(level, 255, "^n");
	// 0
	formatex(buffer, 255, "%L\y%02d%s", Recver, "CHL_ACP_MENU_ACCEPT", g_nGroupRemaining[nGroupId], level);
	if (g_nDzUid[Sender] > 0 && g_nDzUid[Recver] > 0)
		formatex(level, 255, "   \w%L^n", Recver, "CHL_MEM_EX1", g_nGroupScore[Sender][score_tag:WIN], g_nGroupScore[Sender][score_tag:LOSE], g_nGroupScore[Sender][score_tag:DRAW]);
	else
		formatex(level, 255, "^n");
	formatex(buffer, 255, "%s    %L%s", buffer, Recver, "CHL_ACP_MENU_EX1", level);
	if (g_nDzUid[Sender] > 0 && g_nDzUid[Recver] > 0)
		formatex(level, 255, "               \w%L", Recver, "CHL_ACP_MEM_EX", g_nGroupScore[Sender][score_tag:ESCAPE], g_nGroupScore[Sender][score_tag:SCORE]);
	else
		formatex(level, 255, "^n");
	formatex(buffer, 255, "%s    %L%s", buffer, Recver, "CHL_ACP_MENU_EX2", level);
	menu_additem(menu, buffer);
	// 1
	formatex(buffer, 255, "\w%L：\y%L", Recver, "CHL_ACP_MENU_POINT", Recver, ((g_nGroupPoint[nGroupId] == true) ? "ON" : "OFF"));
	menu_additem(menu, buffer);
	// 2
	formatex(buffer, 255, "\w%L\y%s", Recver, "CHL_ACP_MENU_WPN", other_weapons_enname[g_nGroupWeapon[nGroupId]]);
	menu_additem(menu, buffer);
	// 3
	if (g_nGroupEndTag[nGroupId] == 0)
		formatex(route, 127, "%s%L%L", (g_bCupRoute ? "\y" : "\d"), Recver, "CHL_ACP_MENU_ENDTIME", Recver, (g_bCupRoute ? "ALLOW_SET" : "NOT_ALLOW_SET"));
	else
		formatex(route, 127, "\r%L", Recver, "CHL_ACP_MENU_CUSTEM", g_nGroupEndTag[nGroupId]);
	//formatex(buffer, 127, "\w设置终点：%s\r^n    \d选择立即终止计时", route);
	formatex(buffer, 127, "\w%L%s", Recver, "CHL_ACP_MENU_SETEND", route);
	menu_additem(menu, buffer);
	// 4
	formatex(buffer, 63, "\w%L\y%s", Recver, "CHL_ACP_MENU_VOICE", g_nGroupVoice[nGroupId] ? "Female" : "Male");
	menu_additem(menu, buffer);
	// 5
	if (g_bRoute)
	{
		format(buffer, 63, "\w%L\y%s", Recver, "CHL_ACP_MENU_ROUTE", g_szRoute[g_nGroupRoute[nGroupId]]);
		menu_additem(menu, buffer);
	}
	// 5/6
	formatex(buffer, 63, "\w%L", Recver, "REJECT");
	menu_additem(menu, buffer);
	// 6/7
	formatex(buffer, 63, "%L", Recver, "REJECT_AND_BLOCK");
	menu_additem(menu, buffer);

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(Recver, menu);
	return PLUGIN_HANDLED;
}

public accept_challenge_menu_handler(Recver, menu, item)
{
	if (item == MENU_EXIT)
		return PLUGIN_HANDLED

	new nGroupId = g_nGroupId[Recver];
	if (g_nGroupRemaining[nGroupId] < 1)
	{
		ColorChat(Recver, GREEN, "^4[97Club] %L", Recver, "CHL_ACP_MENU_OUTTIME");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if (!g_bRoute && item > 4)
		item++;

	new Sender;
	Sender = g_nGroupPeople[nGroupId][SENDER];

	switch (item)
	{
		case 0: // start1v1  start 1v1
		{
			new taskid = TASK_ACCEPTMENU + nGroupId;
			if (task_exists(taskid))
				remove_task(taskid);
			AcceptConfirmMenu(Recver);
			set_task(2.0, "tsk_acmconfirm", TASK_ACCEPTCONFIRMMENU + nGroupId, _, _, "b");
			return PLUGIN_HANDLED;
		}
		case 1: // 是否存点
		{
			g_nGroupPoint[nGroupId] = !g_nGroupPoint[nGroupId];
		}
		case 2: // 武器选择
		{
			g_nGroupWeapon[nGroupId]++;
			if (g_nGroupWeapon[nGroupId] >= OTHER_WPN_SIZE)
				g_nGroupWeapon[nGroupId] = 1;	// 排除鸟枪
		}
		case 3: // 终点设置
		{
			if (g_bCupRoute)
				SetFinishPos(Sender, Recver, nGroupId);
		}
		case 4: // 报时声音
		{
			g_nGroupVoice[nGroupId] = !g_nGroupVoice[nGroupId];
		}
		case 5: // 线路选择
		{
			g_nGroupRoute[nGroupId]++;
			if (g_szRoute[g_nGroupRoute[nGroupId]][0] == 0x0)
			{
				g_nGroupRoute[nGroupId] = 0;
			}
		}
		case 6: // 拒绝
		{
			CleanGroup(Sender, Recver, nGroupId, group_tag:REJECT);
			return PLUGIN_HANDLED;
		}
		case 7: // 拒绝且屏蔽挑战
		{
			g_bAccept[Recver] = false;
			CleanGroup(Sender, Recver, nGroupId, group_tag:REJECT);
			return PLUGIN_HANDLED;
		}
	}

	menu_destroy(menu);
	AcceptChallengeMenu(Recver);
	return PLUGIN_HANDLED;
}

public tsk_acmconfirm(taskid)
{
	new Recver, Sender, nGroupId;
	nGroupId = taskid - TASK_ACCEPTCONFIRMMENU;
	Sender = g_nGroupPeople[nGroupId][SENDER];
	Recver = g_nGroupPeople[nGroupId][RECVER];
	g_nGroupRemaining[nGroupId] -= 2;
	if (g_nGroupRemaining[nGroupId] < 2)
	{
		CleanGroup(Sender, Recver, nGroupId, group_tag:TIMEOUT);
		remove_task(taskid);
		return;
	}

	AcceptConfirmMenu(Recver);
}

public AcceptConfirmMenu(Recver)
{
	new buffer[256];

	new nGroupId = g_nGroupId[Recver];

	formatex(buffer, 255, "%L", Recver, "CHL_ACP_MENU_AGAIN");
	new menu = menu_create(buffer, "accept_confirm_menu_handler");

	// 0
	formatex(buffer, 255, "%L\y%02d", Recver, "CHL_ACP_MENU_ACCEPT", g_nGroupRemaining[nGroupId]);
	menu_additem(menu, buffer);
	// 1
	formatex(buffer, 255, "\w%L：\y%L", Recver, "CHL_ACP_MENU_POINT", Recver, ((g_nGroupPoint[nGroupId] == true) ? "ON" : "OFF"));
	menu_additem(menu, buffer);
	// 2
	formatex(buffer, 255, "%L\y%s", Recver, "CHL_ACP_MENU_WPN", other_weapons_enname[g_nGroupWeapon[nGroupId]]);
	menu_additem(menu, buffer);
	// 3
	if (g_bRoute)
	{
		format(buffer, 63, "%L\y%s", Recver, "CHL_ACP_MENU_ROUTE", g_szRoute[g_nGroupRoute[nGroupId]]);
		menu_additem(menu, buffer);
	}

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(Recver, menu);
	return PLUGIN_HANDLED;
}

public accept_confirm_menu_handler(Recver, menu, item)
{
	if (item == MENU_EXIT)
		return PLUGIN_HANDLED

	new nGroupId = g_nGroupId[Recver];
	if (g_nGroupRemaining[nGroupId] < 1)
	{
		ColorChat(Recver, GREEN, "^4[97Club] %L", Recver, "CHL_ACP_MENU_OUTTIME");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new Sender;
	Sender = g_nGroupPeople[nGroupId][SENDER];

	switch (item)
	{
		case 0: // start1v1  confirm 1v1
		{
			new taskid = TASK_ACCEPTCONFIRMMENU + nGroupId;
			if (task_exists(taskid))
				remove_task(taskid);
			StartChallenge(nGroupId, Sender, Recver);
			return PLUGIN_HANDLED;
		}
		case 1: // 是否存点
		{
			g_nGroupPoint[nGroupId] = !g_nGroupPoint[nGroupId];
		}
		case 2: // 武器选择
		{
			g_nGroupWeapon[nGroupId]++;
			if (g_nGroupWeapon[nGroupId] >= OTHER_WPN_SIZE)
				g_nGroupWeapon[nGroupId] = 1;	// 排除鸟枪
		}
		case 3: // 线路选择
		{
			if (g_bRoute)
			{
				g_nGroupRoute[nGroupId]++;
				if (g_szRoute[g_nGroupRoute[nGroupId]][0] == 0x0)
				{
					g_nGroupRoute[nGroupId] = 0;
				}
			}
		}
	}

	menu_destroy(menu);
	AcceptConfirmMenu(Recver);
	return PLUGIN_HANDLED;
}

stock StartChallenge(nGroupId, Sender, Recver)
{
	challenge_countdown(nGroupId, Sender, Recver);
	if (g_nGroupUid[nGroupId][SENDER] > 0 && g_nGroupUid[nGroupId][RECVER] > 0)
	{
		g_nGroupScore[Recver][score_tag:ACCEPT]++;
		ChallengeScoreChg(g_nGroupUid[nGroupId][RECVER], "accept");
	}
}

public countdown_freeze(taskid)
{
	new nGroupId = taskid - TASK_COUNTDOWN_FREEZE;
	new Sender, Recver;
	Sender = g_nGroupPeople[nGroupId][SENDER];
	Recver = g_nGroupPeople[nGroupId][RECVER];
	if ((Sender == 0 && Recver == 0) || (g_nGroupId[Sender] == 0 && g_nGroupId[Recver] == 0))
	{
		remove_task(taskid);
		return;
	}

	g_nGroupCountDownFreeze[nGroupId]--;
	say_time_remaining(g_nGroupCountDownFreeze[nGroupId], Sender, Recver);
	if (g_nGroupCountDownFreeze[nGroupId] < 2)
	{
		remove_task(taskid);
		g_bGroupStart[nGroupId] = true;
		kz_dhud_message(Sender, 2.0, 0.4, "%L", Sender, "CHL_START");
		kz_dhud_message(Recver, 2.0, 0.4, "%L", Recver, "CHL_START");
		set_pev(Sender, pev_flags, pev(Sender, pev_flags) & ~FL_FROZEN);
		set_pev(Recver, pev_flags, pev(Recver, pev_flags) & ~FL_FROZEN);
		client_cmd(Recver, "slot10");
		g_nGroupTimer[nGroupId] = get_gametime();
		set_task(2.0, "CheckChallengeTeam", TASK_CHECKCHALLENGETEAM + nGroupId, _, _, "b");
		//set_task(45.0, "ShowOpponent", TASK_SHOWOPPONENT + nGroupId, _, _, "b");
		/*
		cup_countdown_finish = cup_set_time;
		set_task(1.0, "countdown_finish", TASK_COUNTDOWN_FINISH, "", 0, "b");*/
	}
}

public say_time_remaining(time, Sender, Recver)
{
	if (time < 1)
		return;
	new secs = time % 60;
	new mins = time / 60;
	new say_str[128];
	new voice[6];
	if (g_nGroupVoice[g_nGroupId[Sender]])
		voice = "fvox";
	else
		voice = "vox";
	if (time < 11)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 0.0, 1.1, 0.1, 0.5, 1);
		show_lang_hudmessage(Sender, "%d", secs);
		show_lang_hudmessage(Recver, "%d", secs);
		new sec_str[32];
		num_to_word(secs, sec_str, 31);
		format(say_str, 127, "spk ^"%s/%s^"", voice, sec_str);
	}
	else
	{
		set_hudmessage(255, 255, 255, -1.0, 0.45, 0, 0.0, 3.0, 0.0, 0.5, 1);
		show_lang_hudmessage(Sender, "%L%02d:%02d", Sender, "TIME_LEFT", mins, secs);
		show_lang_hudmessage(Recver, "%L%02d:%02d", Recver, "TIME_LEFT", mins, secs);
		new sec_str[32];
		num_to_word(secs, sec_str, 31);
		if (mins != 0)
		{
			new min_str[32];
			num_to_word(mins, min_str, 31);
			if (secs != 0)
				format(say_str, 127, "spk ^"%s/%sminutes %sseconds remaining ^"", voice, min_str, sec_str);
			else
				format(say_str, 127, "spk ^"%s/%sminutes remaining ^"", voice, min_str);
		}
		else
			format(say_str, 127, "spk ^"%s/%sseconds remaining ^"", voice, sec_str);
	}

	client_cmd(Sender, say_str);
	client_cmd(Recver, say_str);
}

//tiaozhanall
public ChallengeAllMenu(id)
{
	new bool:b = false;
	if (!b)
	{
		ColorChat(id, GREEN, "^4[97Club] ^1暂停开放！");
		return PLUGIN_HANDLED;
	}

	if (g_bAllAccepting[0][0])
	{
		ColorChat(id, GREEN, "^4[97Club] ^1已有玩家发起挑战全体，请稍后！");
		return PLUGIN_HANDLED;
	}

	if (ChallengePreCheck(id) == -1)
		return PLUGIN_HANDLED;

	new menu = menu_create("\r1vAll挑战菜单 \wWwW.27015.CoM [\y测试阶段\w]\y", "challenge_all_handler");

	new nGroupId = InitGroup(id, 0);
	pev(id, pev_origin, g_fSourcePos[id]);

	new buffer[128], route[128];
	// 0
	formatex(buffer, 127, "\r发起宣战^n     \d挑战不影响进入TOP榜^n     \r先到终点为胜");
	menu_additem(menu, buffer);
	// 1
	formatex(buffer, 63, "\w存读裸跳：\y%s", ((g_nGroupPoint[nGroupId] == true) ? "存读" : "裸跳"));
	menu_additem(menu, buffer);
	// 2
	formatex(buffer, 63, "\w武器选择：\y%s", other_weapons_enname[g_nGroupWeapon[nGroupId]]);
	menu_additem(menu, buffer);
	// 3
	if (g_nGroupEndTag[nGroupId] == 0)
		formatex(route, 127, "%s终点计时器%s", (g_bCupRoute ? "\y" : "\d"), (g_bCupRoute ? "\w(\y可设置\w)" : "不可设置(需管理预设)"));
	else
		formatex(route, 127, "\r标记点%d", g_nGroupEndTag[nGroupId]);
	formatex(buffer, 127, "\w设置终点：%s\r^n     \d为防止作弊，选择该项立即终止计时", route);
	menu_additem(menu, buffer);
	// 4
	formatex(buffer, 63, "\w报时声音：\y%s\r", g_nGroupVoice[nGroupId] ? "Female" : "Male");
	menu_additem(menu, buffer);

	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public challenge_all_handler(Sender, menu, item)
{
	new nGroupId = g_nGroupId[Sender];

	switch (item)
	{
		case MENU_EXIT:
		{
			CleanGroup(Sender, 0, nGroupId, group_tag:NONOTIFY);
			//for (i = 0; i < g_menuPlayersNum[Sender]; i++)
			return PLUGIN_HANDLED
		}
		case 0: // 发起全部挑战
		{
			new i, iPlayer, iNum = 0;
			g_bAllAccepting[0][0] = true;
			g_nGroupPeople[nGroupId][RECVER] = 0;
			for (i = 0; i < g_menuPlayersNum[Sender]; i++)
			{
				iPlayer = g_menuPlayers[Sender][i];
				g_bAllAccepting[Sender][iPlayer] = true;
				g_nTmpGroupId[iPlayer] = nGroupId;
				if (g_nGroupId[iPlayer] == 0 && !g_bAccepting[iPlayer] && g_bAccept[iPlayer])
				{
					if (timer_started[iPlayer] && !IsPaused[iPlayer])
						Pause(iPlayer);
					AcceptChallengeAllMenu(nGroupId, iPlayer);
					iNum++;
				}
			}
			new buffer[192], SenderName[32];
			g_nGroupRemaining[g_nGroupId[Sender]] = GROUP_REMAINING_DEFAULT;
			set_task(2.0, "tsk_acam", TASK_CHALLENGEALL + Sender, _, _, "b");
			#define	CH_ALL_STR_SIZE		4
			static szStr[CH_ALL_STR_SIZE][] = {
				"寂寞的", "疯狂的", "叼炸的", "孤独的"
			};
			get_user_name(Sender, SenderName, 31);
			formatex(buffer, 191, "^1%s ^3%s ^1向全体玩家发起挑战", szStr[random_num(0, CH_ALL_STR_SIZE - 1)], SenderName);
			for (i = 1; i <= g_iMaxPlayers; i++)
			{
				if (is_user_connected(i) && i != Sender)
				{
					ColorChat(i, GREEN, "^4[97Club] %s", buffer);
					kz_dhud_message(i, 3.0, 0.3, buffer);
				}
			}
			ColorChat(Sender, GREEN, "^4[97Club] ^1已邀战 ^3%d^1 位玩家，请等待，等待时，无法打开全体挑战菜单！", iNum);
			return PLUGIN_HANDLED;
		}
		case 1: // 是否存点
		{
			g_nGroupPoint[nGroupId] = !g_nGroupPoint[nGroupId];
		}
		case 2: // 武器选择
		{
			g_nGroupWeapon[nGroupId]++;
			if (g_nGroupWeapon[nGroupId] >= OTHER_WPN_SIZE)
				g_nGroupWeapon[nGroupId] = 1;	// 排除鸟枪
		}
		case 3: // 终点设置
		{
			if (g_bCupRoute)
				SetFinishPos(Sender, 0, nGroupId);
		}
		case 4: // 报时声音
		{
			g_nGroupVoice[nGroupId] = !g_nGroupVoice[nGroupId];
		}
	}

	ChallengeAllMenu(nGroupId);
	return PLUGIN_HANDLED;
}

public tsk_acam(taskid)
{
	new i, iPlayer;
	new Sender = taskid - TASK_CHALLENGEALL;
	new nGroupId = g_nGroupId[Sender];
	g_nGroupRemaining[nGroupId] -= 2;
	if (g_nGroupRemaining[nGroupId] < 2 || g_nGroupPeople[nGroupId][RECVER] > 0)
	{
		for (i = 0; i < g_menuPlayersNum[Sender]; i++)
		{
			iPlayer = g_menuPlayers[Sender][i];
			RejectFromAll(iPlayer);
			AcceptChallengeAllMenu(nGroupId, iPlayer);
		}

		g_bAllAccepting[0][0] = false;
		remove_task(taskid);
	}
	else
	{
		if (g_nGroupPeople[nGroupId][RECVER] == 0)
		{
			for (i = 0; i < g_menuPlayersNum[Sender]; i++)
			{
				iPlayer = g_menuPlayers[Sender][i];
				if (g_bAllAccepting[Sender][iPlayer])
					AcceptChallengeAllMenu(nGroupId, iPlayer);
			}
		}
	}
}

public AcceptChallengeAllMenu(nGroupId, Recver)
{
	new buffer[128], route[128];
	new Sender = g_nGroupPeople[nGroupId][SENDER];
	if (timer_started[Recver] && !IsPaused[Recver])
		Pause(Recver);
	
	g_bAccepting[Recver] = true;
	formatex(buffer, 127, "\w%s \r向全体玩家宣战\w[\y测试阶段\w]", g_nPeopleName[Sender]);
	new menu = menu_create(buffer, "accept_ch_all_handler");
	// 0
	formatex(buffer, 127, "\r接受 \w剩余时间：\y%02d^n    \d挑战不影响进入TOP榜^n    \r先到终点为胜", g_nGroupRemaining[nGroupId]);
	menu_additem(menu, buffer);
	// 1
	formatex(buffer, 63, "\w存读裸跳：\d%s", ((g_nGroupPoint[nGroupId] == true) ? "存读" : "裸跳"));
	menu_additem(menu, buffer);
	// 2
	formatex(buffer, 63, "\w武器选择：\d%s", other_weapons_enname[g_nGroupWeapon[nGroupId]]);
	menu_additem(menu, buffer);
	// 3
	if (g_nGroupEndTag[nGroupId] == 0)
		formatex(route, 127, "终点计时器");
	else
		formatex(route, 127, "标记点%d", g_nGroupEndTag[nGroupId]);
	formatex(buffer, 127, "\w设置终点：\d%s\r", route);
	menu_additem(menu, buffer);
	// 4
	formatex(buffer, 63, "\w报时声音：\d%s\r", g_nGroupVoice[nGroupId] ? "Female" : "Male");
	menu_additem(menu, buffer);
	// 5
	formatex(buffer, 63, "\w拒绝");
	menu_additem(menu, buffer);
	// 6
	formatex(buffer, 63, "\w拒绝并屏蔽来自其他玩家挑战");
	menu_additem(menu, buffer);

	menu_setprop(menu, MPROP_PERPAGE, 0);
	menu_display(Recver, menu);
	return PLUGIN_HANDLED;
}

public accept_ch_all_handler(Recver, menu, item)
{
	if (item == MENU_EXIT)
	{
		g_bAccepting[Recver] = false;
		return PLUGIN_HANDLED
	}

	new nGroupId = g_nTmpGroupId[Recver];
	if (g_nGroupRemaining[nGroupId] < 1)
	{
		ColorChat(Recver, GREEN, "^4[97Club] ^1已超时，您不能再选择了！");
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new Sender;
	Sender = g_nGroupPeople[nGroupId][SENDER];

	switch (item)
	{
		case 0: // start1v1  start 1v1
		{
			if (g_nGroupPeople[nGroupId][RECVER] > 0)
			{
				g_bAccepting[Recver] = false;
				ColorChat(Recver, GREEN, "^4[97Club] ^1已有其他玩家接受了挑战。");
				return PLUGIN_HANDLED;
			}
			g_nGroupId[Recver] = nGroupId;
			g_nGroupRemaining[nGroupId] = 0;
			g_nGroupPeople[nGroupId][RECVER] = Recver;
			g_bAllAccepting[0][0] = false;
			challenge_countdown(nGroupId, Sender, Recver);
			return PLUGIN_HANDLED;
		}
		case 5: // 拒绝
		{
			RejectFromAll(Recver);
			return PLUGIN_HANDLED;
		}
		case 6: // 拒绝且屏蔽挑战
		{
			RejectFromAll(Recver);
			g_bAccept[Recver] = false;
			return PLUGIN_HANDLED;
		}
	}

	AcceptChallengeAllMenu(nGroupId, Recver);
	return PLUGIN_HANDLED;
}

stock RejectFromAll(id)
{
	new nGroupId = g_nTmpGroupId[id];
	new Sender = g_nGroupPeople[nGroupId][SENDER];
	g_bAllAccepting[Sender][id] = false;
	g_bAccepting[id] = false;
	if (timer_started[id] && IsPaused[id])
		Pause(id);
}

public showoppobeam_task(taskid, cData[])
{
	new nGroupId = taskid - TASK_SHOWOPPONENTEX;
	new Sender = g_nGroupPeople[nGroupId][SENDER];
	new Recver = g_nGroupPeople[nGroupId][RECVER];
	if (Sender == 0 || Recver == 0 || g_nGroupShowOppo[nGroupId] > 5.0)
	{
		remove_beam(Sender);
		remove_beam(Recver);
		remove_task(taskid);
	}

	g_nGroupShowOppo[nGroupId] += 0.1;
	remove_beam(Sender);
	remove_beam(Recver);

	new fOrigin[3];
	get_user_origin(Recver, fOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(Sender)				// entid
	write_coord(fOrigin[0])		// origin
	write_coord(fOrigin[1])		// origin
	write_coord(fOrigin[2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise					
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,255))		// g
	write_byte(random_num(1,255))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public ShowOpponent(taskid)
{
	new nGroupId = taskid - TASK_SHOWOPPONENT;
	new Sender = g_nGroupPeople[nGroupId][SENDER];
	new Recver = g_nGroupPeople[nGroupId][RECVER];
	if (Sender == 0 || Recver == 0)
		remove_task(taskid);
	else
	{
		g_nGroupShowOppo[nGroupId] = 0.0;
		set_task(0.1, "showoppobeam_task", TASK_SHOWOPPONENTEX + nGroupId, _, _, "b");
	}
}

public GroupReady(taskid)
{
	new id = taskid - TASK_DELAYREADY;
	if (g_nGroupId[id] == 0)
		return;
	reset_checkpoints(id);
	JoinCT(id);
	CmdRespawn(id);
	user_use_wpn[id] = other_weapons[g_nGroupWeapon[g_nGroupId[id]]];
	//set_user_weapons(id, other_weapons[g_nGroupWeapon[g_nGroupId[id]]]);
	set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
	set_pev(id, pev_origin, DefaultStartPos);
	set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
	g_bAccepting[id] = false;
	g_bInvite[id] = false;
}

stock CleanGroup(Sender, Recver, nGroupId, group_tag:type)	// 未开始
{
	client_cmd(Recver, "slot10");
	new taskid = TASK_ACCEPTMENU + nGroupId;
	if (task_exists(taskid))
		remove_task(taskid);
	if (Sender > 0)
	{
		if (timer_started[Sender] && IsPaused[Sender])
			Pause(Sender);
		set_pev(Sender, pev_flags, pev(Sender, pev_flags) & ~FL_FROZEN);
		g_nGroupId[Sender] = 0;
	}
	if (Recver > 0)
	{
		g_bAccepting[Recver] = false;
		if (timer_started[Recver] && IsPaused[Recver])
			Pause(Recver);
		set_pev(Recver, pev_flags, pev(Recver, pev_flags) & ~FL_FROZEN);
		g_nGroupId[Recver] = 0;
	}
	g_nGroupPeople[nGroupId][SENDER] = 0;
	g_nGroupPeople[nGroupId][RECVER] = 0;

	if (type != group_tag:NONOTIFY)
	{
		if (type == group_tag:REJECT)
		{
			ColorChat(Sender, GREEN, "^4[97Club] %L", Sender, "CHL_REJECT_TTL", g_nPeopleName[Recver]);
			if (g_nGroupUid[nGroupId][SENDER] > 0 && g_nGroupUid[nGroupId][RECVER] > 0)
			{
				g_nGroupScore[Recver][score_tag:REJECT]++;
				ChallengeScoreChg(g_nGroupUid[nGroupId][RECVER], "reject");
			}
		}

		new buffer[192];
		for (new i = 1; i <= g_iMaxPlayers; i++)
		{
			if (is_user_connected(i))
			{
				if (type == group_tag:REJECT)
					formatex(buffer, 191, "%L", i, "CHL_REJECT_TTL2", g_nPeopleName[Recver]);
				else
					formatex(buffer, 191, "%L", i, "CHL_CHOOSE_TIMEOUT", g_nPeopleName[Recver], GROUP_REMAINING_DEFAULT);
				kz_dhud_message(i, 3.0, 0.3, buffer);
				ColorChat(i, GREEN, "^4[97Club] %s", buffer);
			}
		}
	}
}

stock SetFinishPos(Sender, Recver, nGroupId)
{
	reset_checkpoints(Sender);
	reset_checkpoints(Recver);
	g_nGroupEndTag[nGroupId]++;
	if (g_nGroupEndTag[nGroupId] > g_fCupCusPosNum)
	{
		g_nGroupEndTag[nGroupId] = 0;
		kz_chat(Sender, "%L", Sender, "CHL_ENDPOINT_ENDTIME");
		kz_chat(Recver, "%L", Recver, "CHL_ENDPOINT_ENDTIME");
		MoveToPlayer(Sender, g_fSourcePos[Sender], false);
		MoveToPlayer(Recver, g_fSourcePos[Recver], false);
	}
	else
	{
		if (!is_user_alive(Sender))
			JoinCT(Sender);
		if (!is_user_alive(Recver))
			JoinCT(Recver);
		kz_chat(Sender, "%L", Sender, "CHL_ENDPOINT_CUSTEM", g_nGroupEndTag[nGroupId]);
		kz_chat(Recver, "%L", Recver, "CHL_ENDPOINT_CUSTEM", g_nGroupEndTag[nGroupId]);
		MoveToPlayer(Sender, g_fCupCustomPos[g_nGroupEndTag[nGroupId]], true);
		MoveToPlayer(Recver, g_fCupCustomPos[g_nGroupEndTag[nGroupId]], true);
	}
}

stock MoveToPlayer(id, Float:fOrigin[3], bool:bFrozen)
{
	if (IsPlayer(id))
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0});
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING);
		set_pev(id, pev_origin, fOrigin);
		if (bFrozen)
			set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		else
			set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
	}
}

stock challenge_countdown(nGroupId, Sender, Recver)
{
	new buffer[192];
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (is_user_connected(i))
		{
			formatex(buffer, 191, "%L", i, "CHL_ACCEPT_TTL", g_nPeopleName[Recver], g_nPeopleName[Sender], other_weapons_enname[g_nGroupWeapon[nGroupId]], i, ((g_nGroupPoint[nGroupId] == true) ? "CP_GC" : "NOCHECKPOINT"));
			kz_dhud_message(i, 3.0, 0.3, buffer);
			ColorChat(i, GREEN, "^4[97Club] %s", buffer);
		}
	}
	kz_dhud_message(Sender, 3.0, 0.4, "%L", Sender, "CHL_START_COUNT_DOWN");
	kz_dhud_message(Recver, 3.0, 0.4, "%L", Recver, "CHL_START_COUNT_DOWN");
	if (g_bRoute)
	{
		kz_dhud_message(Sender, 5.0, 0.5, "%L", Sender, "CHL_ROUTE_REMIND", g_szRoute[g_nGroupRoute[nGroupId]]);
		kz_dhud_message(Recver, 5.0, 0.5, "%L", Recver, "CHL_ROUTE_REMIND", g_szRoute[g_nGroupRoute[nGroupId]]);
	}

	set_task(4.0, "GroupReady", TASK_DELAYREADY + Sender);
	set_task(4.0, "GroupReady", TASK_DELAYREADY + Recver);
	g_nGroupCountDownFreeze[nGroupId] = 10;
	set_task(1.0, "countdown_freeze", TASK_COUNTDOWN_FREEZE + nGroupId, "", 0, "b");
	if (g_nGroupUid[nGroupId][SENDER] > 0 && g_nGroupUid[nGroupId][RECVER] > 0)
	{
		g_nGroupScore[Sender][score_tag:CHALLENGE]++;
		g_nGroupScore[Recver][score_tag:CHALLENGE]++;
		ChallengeScoreChg(g_nGroupUid[nGroupId][SENDER], "challenge");
		ChallengeScoreChg(g_nGroupUid[nGroupId][RECVER], "challenge");
	}
}

public SendUID(id)
{
	return g_nDzUid[id];
}

stock valid_steam(const authid[])
{
	new len = strlen(authid)
	if (len > 18 || len < 16 || !isnumber(authid, 6, 1) || !isnumber(authid, 8, 1))
		return false;

	new steamid[19];
	copy(steamid, 18, authid)
	steamid[6] = '0';
	steamid[8] = '0';
	if (strncmp(steamid, "STEAM_0:0:", 10, false) != 0 || !isnumber(authid, 10, 8))
		return false;
	return true;
}

stock isnumber(const src[], start, count)
{
	for (new i = start; i < count && src[i]; i++)
		if (src[i] < '0' || src[i] > '9')
			return false;
	return true;
}

#if AMXX_VERSION_NUM < 183
stock strncmp(const string1[], const string2[], count, bool:ignorecase = false)
{
	new result = 0;
	for (new i = 0; i < count; i++)
	{
		result = string1[i] - string2[i];
		if (ignorecase && abs(result) == 32)
			continue;
		if (result != 0 || string2[i] == 0)
			break;
	}
	
	return result;
}
#else
stock ColorLangChat(id, type, const message[], any:...)
{
    new buffer[192];
    new numArguments = numargs();

    if (numArguments == 3)
    {
        client_print_color(id, type, message);
    }
    else if (id || numArguments >= 4)
    {
		vformat(buffer, charsmax(buffer), message, 4);
		replace_all(buffer, 191, "!g", "^4");
		replace_all(buffer, 191, "!t", "^3");
		replace_all(buffer, 191, "!y", "^1");
		replace_all(buffer, 191, "!n", " ");
		client_print_color(id, type, buffer);
    }
}
#endif

stock findchar(const string[], count, chr)
{
	for (new i = 0; i < count; i++)
		if (string[i] == chr)
			return i;

	return 0;
}

stock SqlEncode(strSrc[])
{
	new buffer[64];
	copy(buffer, 63, strSrc);
	replace_all(buffer, 63, "<", "&lt;");
	replace_all(buffer, 63, ">", "&gt;");
	replace_all(buffer, 63, "^"", "&quot;");
	replace_all(buffer, 63, "'", "&#039;");
	copy(strSrc, 63, buffer);
}

stock SqlDecode(strSrc[])
{
	replace_all(strSrc, 63, "&lt;", "<");
	replace_all(strSrc, 63, "&gt;", ">");
	replace_all(strSrc, 63, "&quot;", "^"");
	replace_all(strSrc, 63, "&#039;", "'");
	//copy(Dest, 31, strSrc);
}

// Compatible Legacy
stock show_lang_hudmessage(index, const message[], any:...)
{
    new buffer[128];
    new numArguments = numargs();

    if (numArguments == 2)
    {
        show_hudmessage(index, message);
    }
    else if (index || numArguments == 3)
    {
		vformat(buffer, charsmax(buffer), message, 3);
		replace_all(buffer, 127, "!g", "");
		replace_all(buffer, 127, "!t", "");
		replace_all(buffer, 127, "!y", "");
		replace_all(buffer, 191, "!n", " ");
		show_hudmessage(index, buffer);
    }
}