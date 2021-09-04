#include <amxmodx>
#include <amxmisc>

/* Player Menus	*/
#define	MAX_MENU_NUM 60

new g_MenuName[MAX_MENU_NUM][100];
new g_MenuCmd[MAX_MENU_NUM][32];

new g_cNum;
new g_menuPosition[33];

public plugin_init() {
	register_plugin("PlayerMenu", "1.1", "VAN.CY");
	register_menucmd(register_menuid("MainMenu"), 1023, "actionPlMenu");
	register_clcmd("say pplmenu", "PlMenu", ADMIN_ALL, "display player menu");
	register_clcmd("menu", "PlMenu");
	register_clcmd("amx_menu", "PlMenu");

	register_dictionary("kz.txt");

	new configs[64];
	get_configsdir(configs,	63);
	format(configs,	63, "%s/%s", configs, "plmenu.ini");
	loadSettings(configs);
}

loadSettings(plmenuconfig[])
{
	if (!file_exists(plmenuconfig))
		return 0;
	new temp[256];
	new a, pos = 0;
	while (g_cNum < MAX_MENU_NUM && read_file(plmenuconfig,pos++,temp,255,a))
	{	      
		if (temp[0] == ';' || temp[0] == '#' || (temp[0] == '/' && temp[1] == '/'))
			continue;
		if (parse(temp,g_MenuName[g_cNum], 31, g_MenuCmd[g_cNum], 31) < 2)
			continue;
		++g_cNum;
	}
	return 1;
}

public PlMenu(id){
	if (is_user_connected(id))
		disPlayerMenu(id, g_menuPosition[id] = 0)
	return PLUGIN_HANDLED
}

disPlayerMenu(id,pos)
{
	if (pos	< 0) 
		return;

	new menuBody[512];
	new b =	0;
	new start = pos * 8;

	if (start >= g_cNum )
		start = pos = g_menuPosition[id] = 0;

	new len = format(menuBody,511,"%L^n\r%L Plugin Author:VAN.CY\y  %d/%d^n^n", id, "MAIN_MENU_CONSOLE", "bind f1 menu", id, "MAIN_MENU", pos + 1 ,(g_cNum / 8 + ((g_cNum % 8) ? 1 : 0)));

	new end = start + 8;
	new keys = MENU_KEY_0;

	if (end > g_cNum)
		end = g_cNum;

	for (new a = start; a < end; ++a)
	{
		keys |= (1 << b);
		len += format(menuBody[len],511-len,"\r%d. \w%L^n", ++b, id, g_MenuName[a]);
	}

	if (end != g_cNum)
	{
		format(menuBody[len],511-len,"^n\r9. \w%L...^n\r0. \w%L", id, "MAIN_MENU_NEXT", id, pos ? "MAIN_MENU_BACK" : "MAIN_MENU_EXIT");
		keys |= MENU_KEY_9;
	}
	else
		format(menuBody[len],511-len,"^n\r0. \w%L", id, pos ? "MAIN_MENU_BACK" : "MAIN_MENU_EXIT");

	show_menu(id, keys, menuBody, -1, "MainMenu");
}

public actionPlMenu(id,key)
{
	switch(key)
	{
		case 8:
		{
			disPlayerMenu(id,++g_menuPosition[id]);
		}
		case 9:
		{
			disPlayerMenu(id,--g_menuPosition[id]);
		}
		default:
		{
			new menuitem = g_menuPosition[id] * 8 +	key;
			client_cmd(id,"%s",g_MenuCmd[menuitem]);
		}
	}
	return PLUGIN_HANDLED;
}