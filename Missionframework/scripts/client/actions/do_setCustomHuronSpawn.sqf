/*
    File: do_setCustomHuronSpawn.sqf
    Author: Tiwaz
    Tiwaz C APL-ND 2023 
    -----
    File Created: 	22nd-08-23
    Last Modified: 	22nd-08-23
    Modified By: Tiwaz
    -----
    Description:
    	ToDo do_setCustomHuronSpawn.sqf
    
    Parameter(s):
    	0:
    
    Returns:
    	NOTHING
*/
params ["_target", "_caller", "_actionId", "_arguments"];
custom_huronspawn = _target;
publicVariable "custom_huronspawn";
["Huron spawn location has been changed"] remoteExec ["hint",2];