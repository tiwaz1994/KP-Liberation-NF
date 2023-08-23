/*
    File: fn_addActionsFob.sqf
    Author: KP Liberation Dev Team - https://github.com/KillahPotatoes
    Date: 2020-04-13
    Last Update: 2023-08-23
    License: MIT License - http://www.opensource.org/licenses/MIT

    Description:
        Adds build action to FOB box and repackage action to FOB building.

    Parameter(s):
        _obj - FOB box/truck/building to add the deploy/repack action to [OBJECT, defaults to objNull]

    Returns:
        Function reached the end [BOOL]
*/

params [
    ["_obj", objNull, [objNull]]
];

if (isNull _object) exitWith {["Null object given"] call BIS_fnc_error; false};

if (isNil "FOB_build_in_progress") then {FOB_build_in_progress = false;};

if ((typeOf _obj) isEqualTo FOB_typename) exitWith {
    _obj addAction [
        ["<t color='#FFFF00'>", localize "STR_FOB_REPACKAGE", "</t> <img size='2' image='res\ui_deployfob.paa'/>"] joinString "",
        "scripts\client\actions\do_repackage_fob.sqf",
        nil,
        -754,
        false,
        true,
        "",
        "isNull (objectParent _this) && {player getVariable ['KPLIB_hasDirectAccess', false]}",
        20
    ];

    //sleep action
    _obj addAction [
        "<t color='#FFFF00'>-- Sleep</t>",
        {
            if !(daytime < 16 && daytime > 8) then {
                [9] remoteExecCall ["BIS_fnc_paramdaytime", 2];
                [240, 0] remoteExecCall ["setFog", 2];
                ["Hyvää huomenta."] remoteExec ["hint",0];
            } else {
                ["It is too bright to sleep, but the fog seems to improve."] remoteExec ["hint",0];
                [240, 0] remoteExecCall ["setFog", 2];
            }
        },
        nil,
        -753,
        false,
        true,
        "",
        "isNull (objectParent _this) && {player getVariable ['KPLIB_hasDirectAccess', false]}",
        20
    ];

    // Set custom huron spawn at FOB
    _obj addAction [
        "<t color='#FFFF00'>-- Set huron spawn location</t>",
        "scripts\client\actions\do_setCustomHuronSpawn.sqf",
        nil,
        -751,
        false,
        true,
        "",
        "isNull (objectParent _this) && {player getVariable ['KPLIB_hasDirectAccess', false]}",
        20
    ];
    true
};

if ((typeOf _obj) in [FOB_box_typename, FOB_truck_typename]) exitWith {
    _obj addAction [
        ["<t color='#FFFF00'>", localize "STR_FOB_ACTION", "</t> <img size='2' image='res\ui_deployfob.paa'/>"] joinString "",
        "scripts\client\build\do_build_fob.sqf",
        nil,
        -752,
        false,
        true,
        "",
        "isNull (objectParent _this) && {!FOB_build_in_progress} && {player getVariable ['KPLIB_hasDirectAccess', false] || {[3] call KPLIB_fnc_hasPermission}} && {(player distance2d startbase) > 300} && {!(surfaceIsWater getPos player)}",
        10
    ];
    true
};

false
