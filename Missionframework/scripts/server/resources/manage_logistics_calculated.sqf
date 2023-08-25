#define MOVETIMEINMETERSPERSECOND 0.01
waitUntil {!isNil "save_is_loaded"};
waitUntil {!isNil "KP_liberation_production"};
waitUntil {save_is_loaded};

["Calculated logistic management started", "LOGISTIC"] call KPLIB_fnc_log;
twz_boxes_in_transit = createHashMap;
manage_logistics_calculated_active = false;
while {GRLIB_endgame == 0} do {
    if (((count (allPlayers - entities "HeadlessClient_F")) > 0)) then {
        waitUntil {sleep 0.5; !manage_logistics_calculated_active};
        manage_logistics_calculated_active = true;

        KP_liberation_production apply
        {
            private _factoryMarker = _x # 1;
            private _factoryPos = markerPos [_factoryMarker,true];
            nearestObjects [_factoryPos, [KP_liberation_small_storage_building, KP_liberation_large_storage_building], 150] apply 
            {
                private _storage = _x;
                attachedObjects _x select 
                {
                    toLower typeOf _x in [toLower KP_liberation_supply_crate,toLower KP_liberation_ammo_crate,toLower KP_liberation_fuel_crate]
                    && !(_x getVariable ["twz_box_in_transit",false])
                } apply 
                {
                    private _box = _x;
                    private _boxType = typeOf _x;
                    private _bestFobs = [];
                    private _alternativeFobs = [];
                    GRLIB_all_fobs apply 
                    {
                        private _fobPos = _x;
                        private _fobBuilding = ((_fobPos nearobjects [FOB_typename, 250]) select {getObjectType _x >= 8}) # 0;
                        private _spaceSum = 0;
                        private _spaceUsedForThisKindOfBox = 0;
                        private _largeMaxSpace = count KP_liberation_large_storage_positions;
                        private _smallMaxSpace = count KP_liberation_small_storage_positions;
                        private _storages = (_fobPos nearobjects GRLIB_fob_range) select {(_x getVariable ["KP_liberation_storage_type",-1]) == 0}; 
                        _storages apply 
                        {
                            private _storageArea = _x;
                            private _attachedBoxes = attachedObjects _storageArea;
                            if (typeOf _x == KP_liberation_large_storage_building) then {
                                _spaceSum = _spaceSum + _largeMaxSpace - (count _attachedBoxes);
                            };
                            if (typeOf _x == KP_liberation_small_storage_building) then {
                                _spaceSum = _spaceSum + _smallMaxSpace - (count _attachedBoxes);
                            };
                            _attachedBoxes apply 
                            {
                                private _storedBox = _x;
                                if (typeOf _storedBox == _boxType) then
                                {
                                    _spaceUsedForThisKindOfBox = _spaceUsedForThisKindOfBox + 1;
                                };
                            };
                        };
                        //add boxes still in transit to the counts
                        twz_boxes_in_transit getOrDefault [hashValue _fobBuilding,[],true] apply 
                        {
                            if (!alive _x) then {continue;};
                            private _boxInTransit = _x;
                            if (typeOf _boxInTransit == _boxType) then
                            {
                                _spaceUsedForThisKindOfBox = _spaceUsedForThisKindOfBox + 1;
                            };
                            _spaceSum = _spaceSum + 1;
                        };
                        private _priority = 0;
                        private _perfectTarget = ceil (_spaceSum / 3);
                        if (_spaceSum > 0) then
                        {
                            if (_spaceUsedForThisKindOfBox < _perfectTarget) then
                            {
                                _bestFobs pushback _fobBuilding;
                            } 
                            else
                            {
                                _alternativeFobs pushback _fobBuilding;
                            };
                        };
                    };
                    private _fobsToWorkWith = [];
                    if (count _bestFobs > 0) then
                    {
                        _fobsToWorkWith = _bestFobs;
                    }
                    else
                    {
                        _fobsToWorkWith = _alternativeFobs;
                    };
                    if (count _fobsToWorkWith > 0) then
                    {
                        _fobsToWorkWith = _fobsToWorkWith apply {[_x distance _box,_x]};
                        _fobsToWorkWith sort true;
                        private _selectedElement = _fobsToWorkWith # 0;
                        private _selectedFob = _selectedElement # 1;
                        private _distance = _selectedElement # 0;
                        private _timeInTransit = _distance * MOVETIMEINMETERSPERSECOND;
                        twz_boxes_in_transit getOrDefault [hashValue _selectedFob,[],true] pushback _box;
                        _box setVariable ["twz_box_in_transit",true];
                        [
                            {
                                _this params ["_box","_fob"];
                                if (!alive _box) exitWith {};
                                if (!alive _fob) exitWith 
                                {
                                    twz_boxes_in_transit deleteAt _fob;
                                    _box setVariable ["twz_box_in_transit",false];
                                };
                                if !(_box getVariable ["twz_box_in_transit",false]) exitWith
                                {
                                    private _arr = twz_boxes_in_transit getOrDefault [hashValue _fob,[],true];
                                    _arr deleteAt (_arr find _box);
                                };

                                (_fob nearobjects GRLIB_fob_range) select {(_x getVariable ["KP_liberation_storage_type",-1]) == 0} apply
                                {
                                    private _storage = _x;
                                    private _attachedBoxes = attachedObjects _storage;
                                    private _space = 0;
                                    private _largeMaxSpace = count KP_liberation_large_storage_positions;
                                    private _smallMaxSpace = count KP_liberation_small_storage_positions;
                                    if (typeOf _x == KP_liberation_large_storage_building) then 
                                    {
                                        _space = _largeMaxSpace - (count _attachedBoxes);
                                    };
                                    if (typeOf _x == KP_liberation_small_storage_building) then 
                                    {
                                        _space = _smallMaxSpace - (count _attachedBoxes);
                                    };
                                    if (_space > 0) then
                                    {
                                        ([_storage] call KPLIB_fnc_getStoragePositions) params ["_storagePositions", "_unloadDist"];

                                        // Fetch all stored crates
                                        private _storedCrates = attachedObjects _storage;
                                        reverse _storedCrates;

                                        // Unload crate
                                        detach _box;
                                        [_box, true] call KPLIB_fnc_clearCargo;
                                        [_box, true] remoteExec ["enableRopeAttach"];
                                        if (KP_liberation_ace) then {[_box, true, [0, 1.5, 0], 0] remoteExec ["ace_dragging_fnc_setCarryable"];};

                                        private _arr = twz_boxes_in_transit getOrDefault [hashValue _fob,[],true];
                                        _arr deleteAt (_arr find _box);
                                        _box setVariable ["twz_box_in_transit",false];
                                        [_box,_storage,true] call KPLIB_fnc_crateToStorage;

                                        // Fill the possible gap in the storage area
                                        reverse _storedCrates;
                                        _i = 0;
                                        {
                                            detach (_x select 0);
                                            (_x select 0) attachTo [_storage, [(_storagePositions select _i) select 0, (_storagePositions select _i) select 1, _x select 1]];
                                            _i = _i + 1;
                                        } forEach (_storedCrates apply {[_x, [typeOf _x] call KPLIB_fnc_getCrateHeight]});
                                    };
                                };
                            },
                            [_box,_selectedFob],
                            _timeInTransit
                        ] call CBA_fnc_waitAndExecute;
                    };
                };
            };
        };
    };
    uiSleep 20;
    manage_logistics_calculated_active = false;
};
