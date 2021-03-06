"use strict";

var skip = false
var rangedParticle

function OnUpdateSelectedUnit( event )
{
	if (skip == true){
		skip = false;
		return
	}

	var iPlayerID = Players.GetLocalPlayer();
	var selectedEntities = Players.GetSelectedEntities( iPlayerID );
	var mainSelected = Players.GetLocalPlayerPortraitUnit();

	// Remove old particle
    if (rangedParticle)
        Particles.DestroyParticleEffect(rangedParticle, true)

    // Create range display on the selected ranged attacker
    if (IsCustomBuilding(mainSelected) && Entities.HasAttackCapability(mainSelected))
    {
        var range = Entities.GetAttackRange(mainSelected)
        rangedParticle = Particles.CreateParticle("particles/custom/ui_mouseactions/range_display.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, mainSelected)
        var position = Entities.GetAbsOrigin(mainSelected)
        position[2] = 380
        Particles.SetParticleControl(rangedParticle, 0, position)
        Particles.SetParticleControl(rangedParticle, 1, [range, 0, 0])
    }

	if (selectedEntities.length > 1 && IsMixedBuildingSelectionGroup(selectedEntities) ){
		$.Schedule(1/60, SelectOnlyBuildings)	
	}

	$.Schedule(0.03, SendSelectedEntities);
}

function SelectOnlyBuildings() {
	var iPlayerID = Players.GetLocalPlayer();
	var selectedEntities = Players.GetSelectedEntities( iPlayerID );
	
	skip = true;
	var first = FirstBuildingEntityFromSelection(selectedEntities)
	GameUI.SelectUnit(first, false); // Overrides the selection group

	for (var unit of selectedEntities) {
		skip = true; // Makes it skip an update
		if (IsCustomBuilding(unit) && unit != first){
			GameUI.SelectUnit(unit, true);
		}
	}
}

function FirstBuildingEntityFromSelection( entityList ){
	for (var i = 0; i < entityList.length; i++) {
		if (IsCustomBuilding(entityList[i])){
			return entityList[i]
		}
	}
	return 0
}

function GetFirstUnitFromSelectionSkipUnit ( entityList, entIndex ) {
	for (var i = 0; i < entityList.length; i++) {
		if ((entityList[i]) != entIndex){
			return entityList[i]
		}
	}
	return 0
}

function SendSelectedEntities (params) {
	var newSelectedEntities = Players.GetSelectedEntities( Players.GetLocalPlayer() );
	GameEvents.SendCustomGameEventToServer( "update_selected_entities", { selected_entities: newSelectedEntities })
}

// Returns whether the selection group contains both buildings and non-building units
function IsMixedBuildingSelectionGroup ( entityList ) {
	var buildings = 0
	var nonBuildings = 0
	for (var i = 0; i < entityList.length; i++) {
		if (IsCustomBuilding(entityList[i])){
			buildings++
		}
		else {
			nonBuildings++
		}
	}
	return (buildings>0 && nonBuildings>0)
}

function IsCustomBuilding( entityIndex ){
	var ability_building = Entities.GetAbilityByName( entityIndex, "ability_building")
	var ability_tower = Entities.GetAbilityByName( entityIndex, "ability_tower")
	if (ability_building != -1){
		//$.Msg(entityIndex+" IsCustomBuilding - Ability Index: "+ ability_building)
		return true
	}
	else if (ability_tower != -1){
		//$.Msg(entityIndex+" IsCustomBuilding Tower - Ability Index: "+ ability_tower)
		return true
	}
	else
		return false
}

function IsGoldMine( entityIndex ) {
	return (Entities.GetUnitName(entityIndex) == "gold_mine")
}

function IsMechanical( entityIndex ) {
	var ability_siege = Entities.GetAbilityByName( entityIndex, "ability_siege")
	return (ability_siege != -1)
}

function IsCityCenter( entityIndex ){
	return (Entities.GetUnitLabel( entityIndex ) == "city_center")
}

function AddToSelection ( args ) {
	var entIndex = args.ent_index
	GameUI.SelectUnit(entIndex, true)
	OnUpdateSelectedUnit( args )
}

function NewSelection ( args ) {
	var entIndex = args.ent_index
	GameUI.SelectUnit(entIndex, false)
	OnUpdateSelectedUnit( args )
}

function RemoveFromSelection ( args ) {
	var entIndex = args.ent_index

	var iPlayerID = Players.GetLocalPlayer();
	var selectedEntities = Players.GetSelectedEntities( iPlayerID );

	skip = true;
	GameUI.SelectUnit(GetFirstUnitFromSelectionSkipUnit(selectedEntities, entIndex), false); // Overrides the selection group

	for (var i = 0; i < selectedEntities.length; i++) {
		skip = true; // Makes it skip an update
		if ((selectedEntities[i]) != entIndex){
			GameUI.SelectUnit(selectedEntities[i], true);
		}
	}
	OnUpdateSelectedUnit( args )
}

function OnUpdateQueryUnit( event )
{
}

(function () {
	GameEvents.Subscribe( "add_to_selection", AddToSelection );
	GameEvents.Subscribe( "remove_from_selection", RemoveFromSelection);
	GameEvents.Subscribe( "new_selection", NewSelection);
	GameEvents.Subscribe( "dota_player_update_selected_unit", OnUpdateSelectedUnit );
	GameEvents.Subscribe( "dota_player_update_query_unit", OnUpdateQueryUnit );
})();