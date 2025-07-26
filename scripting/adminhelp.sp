#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define COMMANDS_PER_PAGE	10

ArrayList g_cmdList;

bool g_printing;

int g_cmdIndex = 0;
int g_cmdLength = 0;

char noDesc[128];

enum struct cmdEntry
{
	char name[64];
	char desc[255];
}

public Plugin myinfo = 
{
	name = "Admin Help",
	author = "AlliedModders LLC, modified for ep1 by bauxite",
	description = "Display command information",
	version = "1.11 for ep1 engine",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("adminhelp.phrases");
	RegConsoleCmd("sm_help", HelpCmd, "Displays SourceMod commands and descriptions");
	RegConsoleCmd("sm_searchcmd", HelpCmd, "Searches SourceMod commands");
}

public Action HelpCmd(int client, int args)
{
	if (client && !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char arg[64], cmdName[20];
	int pageNum = 1;
	bool doSearch;

	GetCmdArg(0, cmdName, sizeof(cmdName));

	if (args >= 1)
	{
		GetCmdArg(1, arg, sizeof(arg));
		StringToIntEx(arg, pageNum);
		pageNum = (pageNum <= 0) ? 1 : pageNum;
	}

	doSearch = (strcmp("sm_help", cmdName) == 0) ? false : true;

	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[SM] %t", "See console for output");
	}

	char name[64];
	char desc[255];
	CommandIterator cmdIter = new CommandIterator();

	FormatEx(noDesc, sizeof(noDesc), "%T", "No description available", client);

	if (doSearch)
	{
		if(g_printing)
		{
			ReplyToCommand(client, "[SM] Already printing for a client, please try again later");
			return Plugin_Handled;
		}
		
		g_printing = true;

		if (g_cmdList != null)
		{
			delete g_cmdList;
		}
		
		g_cmdList = new ArrayList(sizeof(cmdEntry));
		g_cmdIndex = 0;
		g_cmdLength = 0;
		
		int i = 1;
		while (cmdIter.Next())
		{
			cmdIter.GetName(name, sizeof(name));
			cmdIter.GetDescription(desc, sizeof(desc));

			if ((StrContains(name, arg, false) != -1) && CheckCommandAccess(client, name, cmdIter.Flags))
			{
				cmdEntry entry;
				strcopy(entry.name, sizeof(entry.name), name);
				strcopy(entry.desc, sizeof(entry.desc), desc);
				g_cmdList.PushArray(entry);
				i++;
			}
		}

		if (i == 1)
		{
			PrintToConsole(client, "%t", "No matching results found");
		} else {
			RequestFrame(PrintCmds, GetClientUserId(client));
		}
	} else {
		PrintToConsole(client, "%t", "SM help commands");		

		/* Skip the first N commands if we need to */
		if (pageNum > 1)
		{
			int i;
			int endCmd = (pageNum-1) * COMMANDS_PER_PAGE - 1;
			for (i=0; cmdIter.Next() && i<endCmd; )
			{
				cmdIter.GetName(name, sizeof(name));

				if (CheckCommandAccess(client, name, cmdIter.Flags))
				{
					i++;
				}
			}

			if (i == 0)
			{
				PrintToConsole(client, "%t", "No commands available");
				delete cmdIter;
				return Plugin_Handled;
			}
		}

		/* Start printing the commands to the client */
		int i;
		int StartCmd = (pageNum-1) * COMMANDS_PER_PAGE;
		for (i=0; cmdIter.Next() && i<COMMANDS_PER_PAGE; )
		{
			cmdIter.GetName(name, sizeof(name));
			cmdIter.GetDescription(desc, sizeof(desc));
			
			if (CheckCommandAccess(client, name, cmdIter.Flags))
			{
				i++;
				PrintToConsole(client, "[%03d] %s - %s", i+StartCmd, name, (desc[0] == '\0') ? noDesc : desc);
			}
		}

		if (i == 0)
		{
			PrintToConsole(client, "%t", "No commands available");
		} else {
			PrintToConsole(client, "%t", "Entries n - m in page k", StartCmd+1, i+StartCmd, pageNum);
		}

		/* Test if there are more commands available */
		if (cmdIter.Next())
		{
			PrintToConsole(client, "%t", "Type sm_help to see more", pageNum+1);
		}
	}

	delete cmdIter;

	return Plugin_Handled;
}

public void PrintCmds(int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (client && !IsClientInGame(client)) 
	{
		g_printing = false;
		return;
	}
	
	char buf[1024];
	
	g_cmdLength = 0;
	cmdEntry entry;
	
	while (g_cmdIndex < g_cmdList.Length && g_cmdLength < 1024)
	{
		g_cmdList.GetArray(g_cmdIndex, entry);
		g_cmdLength += Format(buf, sizeof(buf), "[%03d] %s - %s", g_cmdIndex + 1, entry.name, (entry.desc[0] == '\0') ? noDesc : entry.desc);
		PrintToConsole(client, buf);
		g_cmdIndex++;
	}
	
	if (g_cmdIndex < g_cmdList.Length)
	{
		RequestFrame(PrintCmds, GetClientUserId(client));
	}
	else
	{
		delete g_cmdList;
		g_printing = false;
	}
}
