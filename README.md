# SM-Admin-Help-EP1
Modified version of the Sourcemod Admin Help plugin to better work on EP1 engine games, **experimental** and may contain bugs (probably works fine in most cases).

## More information  
The default adminhelp plugin in Sourcemod works fine for Source Engine games newer than 2007 it seems, or 2006 (EP1) engine game servers with less commands to print when using `sm_searchcmd`. This is because the fix that prevents console messages from being lost doesn't work on the Source 2006 engine, so when many commands need to be printed, they get lost and an error is displayed, meaning you cannot print all the commands into the console.  

This plugin prints the commands over multiple ticks, but it does mean that only 1 client can use `sm_searchcmd` until the plugin has finished printing all the commands.
