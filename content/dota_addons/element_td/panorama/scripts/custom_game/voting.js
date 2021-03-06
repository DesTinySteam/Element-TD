"use strict";

GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );			// Heroes and team score at the top of the HUD
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );	// flyout scoreboard
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );			// Endgame scoreboard

var votingUI = $( "#Voting" );
var voteResultsUI = $( '#VoteResults' );
var buttonVote = $( "#Vote" );
var buttonResults = $( "#ResultsButton" );
var info = $( '#Info' );
var votingLiveUI = $( '#VotingLive' );
var currentModeUI = $('#CurrentModePanel')

var notVotedUI = $( '#NotVoted' );

var votingLiveNotVoted = $( '#NotVotedPlayers' );
var votingLiveHasVoted = $( '#HasVotedPlayers' );
var playerVotes = {};

var timer = $( '#Countdown' );

var difficultyModes = ["normal","hard","veryhard","insane"]
var activeDifficulty = "normal"
var healthBonus = {normal:"100%",hard:"150%",veryhard:"200%",insane:"250%"}
var bountyBonus = {normal:"100%",hard:"130%",veryhard:"150%",insane:"170%"}
var bountyBonusExpress = {normal:"100%",hard:"130%",veryhard:"150%",insane:"170%"}
var endlessBountyBonus = 20
var scoreMultipliers = {normal:1,hard:2,veryhard:3,insane:4,chaos:0.25,endless:0.5}

var healthMult = $( '#HealthMult' );
var bountyMult = $( '#BountyMult' );
var scoresMult = $( '#ScoresMult' );
var same_random = $('#same_random')
var all_random = $('#all_random')
var chaos = $('#chaos')
var endless = $('#endless')
var express = $('#express')

function UpdateMultipliers(difficultyName){
    difficultyName = difficultyName || activeDifficulty;
    healthMult.text = GetHP(difficultyName)
    bountyMult.text = GetBounty(difficultyName, endless.checked || endless.hovering, express.checked || express.hovering)
    scoresMult.text = GetScore(difficultyName, endless.checked || endless.hovering, chaos.checked || chaos.hovering)
}

function HoverDifficulty(name) {
    var panel = $("#"+name)

    if (name != activeDifficulty)
        panel.AddClass('Hover')

    Glow(panel)
    UpdateMultipliers(name)
}

function MouseOverDiff(name) {
    var panel = $("#"+name)

    if (name != activeDifficulty)
        RemoveGlow(panel)
    UpdateMultipliers()
}

function SelectDifficulty(name) {
    var panel = $("#"+name)
    activeDifficulty = name
    
    for (var i in difficultyModes)
    {
        var diffPanel = $("#"+difficultyModes[i])
        if (difficultyModes[i] != activeDifficulty)
        {
            RemoveGlow(diffPanel)
        }
    }
    Glow(panel)
    panel.AddClass('Hover')
    UpdateMultipliers()
    Game.EmitSound("ui_generic_button_click");
}

function Glow(panel) {
    panel.visible = false

    var glowPanel = $("#"+panel.id+"_glow")
    glowPanel.RemoveClass("Hidden")
}

function RemoveGlow(panel) {
    var glowPanel = $("#"+panel.id+"_glow")
    glowPanel.AddClass("Hidden")

    panel.visible = true
    panel.RemoveClass('Hover')
}

function HoverCheckbox(name) {
    var panel = $("#"+name)

    panel.hovering = true
    UpdateMultipliers()
}

function MouseOverCheckbox(name) {
    var panel = $("#"+name)
    panel.hovering = false
    UpdateMultipliers()
}

function SelectCheckbox(name) {
    UpdateMultipliers()
    Game.EmitSound("ui_generic_button_click");
    $("#"+name).checked = !$("#"+name).checked
}

function SelectCheckboxClick() {
    Game.EmitSound("ui_generic_button_click");
    UpdateMultipliers()
}

function SelectRadio(name) {
    var panel = $("#"+name)
    if (panel.last_state !== undefined && panel.last_state == panel.checked)
        panel.checked = !panel.checked

    panel.last_state = panel.checked

    //Radio buttons
    if (name == "same_random")
        $("#all_random").last_state = undefined
    else
        $("#same_random").last_state = undefined
}

function ToggleVoteDialog( data )
{
    votingUI.visible = data.visible;
    if (Game.GetAllPlayerIDs().length > 1)
    {
        if (votingUI.visible)
        {
            votingLiveUI.visible = true;
            votingLiveUI.RemoveClass("hidden");
        }
        else
        {
            votingLiveUI.AddClass("hidden");
        }
    }
}

function UpdateVoteTimer( data )
{
    timer.text = data.time;
}

function UpdateNotVoted()
{
    var players = Game.GetAllPlayerIDs();
    votingLiveNotVoted.RemoveAndDeleteChildren();
    var position = 0;
    for (var playerID in players) {
        if (!playerVotes[playerID]) {
            var playerData = Game.GetPlayerInfo(parseInt(playerID));
            var notVoted = $.CreatePanel('DOTAAvatarImage', votingLiveNotVoted, '');
            notVoted.AddClass('VotingAvatar');
            notVoted.AddClass('NotVoted');
            notVoted.steamid = playerData.player_steamid;
            position += 1;
        }
    };
    if (position == 0)
    {
        notVotedUI.style['visibility'] = "collapse";
        $.Schedule(3, function(){votingLiveUI.visible = false;});
    }
}

function PlayerVoted( data )
{
    $.Msg(data);
    var playerID = data.playerID;
    var playerData = Game.GetPlayerInfo(parseInt(playerID));
    var vote = $.CreatePanel('Panel', votingLiveHasVoted, '');
    vote.AddClass('VotedPlayer');

    var avatar = $.CreatePanel('DOTAAvatarImage', vote, '');
    avatar.AddClass('VotingAvatar');
    avatar.steamid = playerData.player_steamid;

    var votes = $.CreatePanel('Panel', vote, '');
    votes.AddClass('VotedPlayerVotes');

    /*var gamemode = $.CreatePanel('Label', votes, '');
    gamemode.AddClass('PlayerVote');
    gamemode.text = $.Localize(data.gamemode.replace(/([a-z])([A-Z])/g, '$1 $2'));*/

    var difficulty = $.CreatePanel('Label', votes, '');
    difficulty.AddClass('PlayerVote');
    difficulty.text = $.Localize("difficulty_"+data.difficulty.toLowerCase());

    if (data.elements == "SameRandom")
    {
        var elements = $.CreatePanel('Label', votes, '');
        elements.AddClass('PlayerVote');
        elements.text = $.Localize("element_"+data.elements.toLowerCase());
    }

    if (data.elements == "AllRandom")
    {
        var elements = $.CreatePanel('Label', votes, '');
        elements.AddClass('PlayerVote');
        elements.text = $.Localize("element_"+data.elements.toLowerCase());
    }

    if (data.endless == "Endless")
    {
        var endless = $.CreatePanel('Label', votes, '');
        endless.AddClass('PlayerVote');
        endless.text = $.Localize("horde_"+data.endless.toLowerCase());
    }

    if (data.order == "Chaos")
    {
        var order = $.CreatePanel('Label', votes, '');
        order.AddClass('PlayerVote');
        order.text = $.Localize("order_"+data.order.toLowerCase());
    }

    if (data.length == "Express")
    {
        var length = $.CreatePanel('Label', votes, '');
        length.AddClass('PlayerVote');
        length.text = $.Localize("length_"+data.length.toLowerCase());
    }

    playerVotes[playerID] = true;
    votingLiveHasVoted.ScrollToBottom();
    UpdateNotVoted();
}

function ConfirmVote()
{
    Game.EmitSound("ui_generic_button_click");

    buttonVote.visible = false;
    info.visible = true;

    var data = {};

    data['difficultyVote'] = difficultyModes.indexOf(activeDifficulty)
    
    data['elementsVote'] = 0
    if (same_random.checked)
        data['elementsVote'] = 1
    else if (all_random.checked)
        data['elementsVote'] = 2

    data['orderVote'] = chaos.checked
    data['endlessVote'] = endless.checked
    data['lengthVote'] = express.checked

    $.Msg(data)

    GameEvents.SendCustomGameEventToServer( "etd_player_voted", { "data" : data } );
}

function ShowVoteResults( data )
{
    votingUI.visible = false;
    voteResultsUI.visible = true;
    votingLiveUI.AddClass("hidden");

    var difficultyName = data.difficulty.toLowerCase()
    $("#DifficultyResult").text = $.Localize("difficulty_"+difficultyName+"_mode")
    $("#DifficultyView").text = $.Localize("difficulty_"+difficultyName+"_mode")

    // Only show the options that were accepted
    var random = data.elements == "SameRandom" || data.elements == "AllRandom"
    var endless = data.endless == "Endless"
    var chaos = data.order == "Chaos"
    var express = data.length == "Express"

    if (!random)
    {
        $( '#ElementsResult' ).GetParent().DeleteAsync(0)
        $( '#ElementsView' ).AddClass("Hidden") //This can become visible if the player does -random afterwards
    }
    else
    {
        $( '#ElementsResult' ).text = $.Localize(data.elements.toLowerCase()+"_mode");
    }

    if (!endless)
    {
        $( '#EndlessResult' ).GetParent().DeleteAsync(0)
        $( '#EndlessView' ).DeleteAsync(0)
    }

    if (!chaos)
    {
        $( '#OrderResult' ).GetParent().DeleteAsync(0)
        $( '#OrderView' ).DeleteAsync(0)
    }

    if (!express)
    {
        $( '#LengthResult' ).GetParent().DeleteAsync(0)
        $( '#LengthView' ).DeleteAsync(0)
    }

    // Update HP-Bounty-Scores results
    $("#HealthResult").text = GetHP(difficultyName)
    $("#BountyResult").text = GetBounty(difficultyName, endless, express)
    $("#ScoresResult").text = GetScore(difficultyName, endless, chaos)

    // Show current mode UI
    currentModeUI.visible = true;
    $("#diff_image").SetImage("file://{images}/custom_game/vote_menu/difficulties/"+difficultyName+".png")
    $("#diff_image_glow").SetImage("file://{images}/custom_game/vote_menu/difficulties/"+difficultyName+"_glow.psd")
}

function GetHP(difficultyName) {
    return "Health: "+healthBonus[difficultyName]
}

function GetBounty(difficultyName, bEndless, bExpress) {
    var bounty = bExpress ? bountyBonusExpress[difficultyName] : bountyBonus[difficultyName]
    if (bEndless)
    {
        bounty = Number(bounty.substring(0,bounty.length-1)) + endlessBountyBonus
        bounty = bounty + "%"
    }
    return "Bounty: "+bounty
}

function GetScore(difficultyName, bEndless, bChaos) {
    var scoring = scoreMultipliers[difficultyName]
    var additive = 1;
    if (bEndless)
        additive+=scoreMultipliers['endless']

    if (bChaos)
        additive+=scoreMultipliers['chaos']

    return "Score Multiplier: x"+scoring*additive
}    

function ResultsClose()
{
    Game.EmitSound("ui_generic_button_click");
    voteResultsUI.visible = false;
    votingLiveUI.AddClass("Hidden");
}

var currentlyLocked = false
function ShowCurrentModes() {
    $("#CurrentModePanel").RemoveClass("resize")
    $("#DiffLabels").RemoveClass("hide")
    $("#DiffLabels").RemoveClass("Slide")
    $("#DiffImage").AddClass("Hover")
}

function HideCurrentModes() {
    if (!currentlyLocked)
    {
        $("#CurrentModePanel").AddClass("resize")
        $("#DiffLabels").AddClass("hide")
        $("#DiffLabels").AddClass("Slide")
        $("#DiffImage").RemoveClass("Hover")
    }
}

function ToggleCurrentModeVisibility(){
    Game.EmitSound("ui_generic_button_click")
    currentlyLocked = !currentlyLocked
    if (currentlyLocked)
    {
        Glow($("#diff_image"))
        ShowCurrentModes()
    }
    else
        RemoveGlow($("#diff_image"))
    HideCurrentModes()
}

function UpdateRandomMode() {
    $( '#ElementsView' ).RemoveClass("Hidden")
}

function Setup()
{
    SelectDifficulty("normal")
    UpdateMultipliers()
    voteResultsUI.visible = false;
    votingUI.visible = false;
    info.visible = false;
    votingLiveUI.visible = false;
    currentModeUI.visible = false;
    votingLiveUI.AddClass("hidden");
    UpdateNotVoted();
}


(function () {
    Setup();
    GameEvents.Subscribe( "etd_toggle_vote_dialog", ToggleVoteDialog );
    GameEvents.Subscribe( "etd_update_vote_timer", UpdateVoteTimer );
    GameEvents.Subscribe( "etd_vote_display", PlayerVoted );
    GameEvents.Subscribe( "etd_vote_results", ShowVoteResults );
    GameEvents.Subscribe( "etd_player_random_enable", UpdateRandomMode );
})();

/* Old Dropdown code 

var gamemodeDesc = $( '#GamemodeDesc' );
var difficultyDesc = $( '#DifficultyDesc' );
var elementDesc = $( '#ElementsDesc' );
var endlessDesc = $( '#EndlessDesc' );
var orderDesc = $( '#OrderDesc' );
var lengthDesc = $( '#LengthDesc' );

var gamemodeDD = $( '#GamemodeDD' );
var difficultyDD = $( '#DifficultyDD' );
var elementDD = $( '#ElementsDD' );
var endlessDD = $( '#EndlessDD' );
var orderDD = $( '#OrderDD' );
var lengthDD = $( '#LengthDD' );

function Populate( data )
{
    gamesettings = data;

    //=Gamemodes Dropdown================================================================//
    for (var gm in gamesettings.GameModes)
    {
        var gamemode = gamesettings['GameModes'][gm];
        gameModes[parseInt(gamemode['Index'])] = [ gamemode['Name'], gamemode['Description'], gm ];
    }

    PopulateDropDown(gamemodeDD, gameModes);
    gamemodeDD.SetSelected(0);
    gamemodeDesc.text = $.Localize(gameModes[0][1]); // Default Competitive

    //=Difficulty Dropdown================================================================//
    for (var df in gamesettings.Difficulty)
    {
        var difficulty = gamesettings['Difficulty'][df];
        var desc = Math.round(parseFloat(difficulty.Health) * 100) + "% Creep Health, " + parseInt(difficulty.BaseBounty * 1000)/1000+ " Base Bounty (Express Mode: " + parseInt(difficulty.BaseBountyExpress * 1000)/1000+ " Base Bounty)";
        difficultyModes[parseInt(difficulty['Index'])] = [ difficulty['Name'], desc, df ];
    }

    PopulateDropDown(difficultyDD, difficultyModes);
    difficultyDD.SetSelected(0);
    difficultyDesc.text = $.Localize(difficultyModes[0][1]); // Default Normal

    //=Elements Dropdown================================================================//
    for (var ele in gamesettings.ElementModes)
    {
        var element = gamesettings['ElementModes'][ele];
        elementModes[parseInt(element['Index'])] = [ element['Name'], element['Description'], ele ];
    }

    PopulateDropDown(elementDD, elementModes);
    elementDD.SetSelected(0);
    elementDesc.text = $.Localize(elementModes[0][1]); // Default All Pick

    //=Endless Mode Dropdown
    for (var end in gamesettings.HordeMode)
    {
        var endless = gamesettings['HordeMode'][end];
        endlessModes[parseInt(endless['Index'])] = [ endless['Name'], endless['Description'], end ];
    }

    PopulateDropDown(endlessDD, endlessModes);
    endlessDD.SetSelected(0);
    endlessDesc.text = $.Localize(endlessModes[0][1]); // Default Normal

    //=Order Dropdown================================================================//
    for (var ord in gamesettings.CreepOrder)
    {
        var order = gamesettings['CreepOrder'][ord];
        orderModes[parseInt(order['Index'])] = [ order['Name'], order['Description'], ord ];
    }

    PopulateDropDown(orderDD, orderModes);
    orderDD.SetSelected(0);
    orderDesc.text = $.Localize(orderModes[0][1]); // Default Normal

    //=Length Dropdown================================================================//
    for (var lnth in gamesettings.GameLength)
    {
        var gameLength = gamesettings['GameLength'][lnth];
        var desc = "Start at wave " + gameLength.Wave + " with " + gameLength.Gold + " Gold and " + gameLength.Lumber + " Lumber."
        if (lnth == "Express")
            desc += " This mode has 30 waves and no boss.";
        lengthModes[parseInt(gameLength['Index'])] = [ gameLength['Name'], desc, lnth ];
    }

    PopulateDropDown(lengthDD, lengthModes);
    lengthDD.SetSelected(0);
    lengthDesc.text = $.Localize(lengthModes[0][1]); // Default Classic
}


function OnDropDownChanged( setting )
{
    if (setting == "gamemode")
        gamemodeDesc.text = $.Localize(gameModes[parseInt(gamemodeDD.GetSelected().id)][1]); 
    else if (setting == "difficulty")
        difficultyDesc.text = $.Localize(difficultyModes[parseInt(difficultyDD.GetSelected().id)][1]);
    else if (setting == "elements")
        elementDesc.text = $.Localize(elementModes[parseInt(elementDD.GetSelected().id)][1]);
    else if (setting == "endless")
        endlessDesc.text = $.Localize(endlessModes[parseInt(endlessDD.GetSelected().id)][1]);
    else if (setting == "order")
        orderDesc.text = $.Localize(orderModes[parseInt(orderDD.GetSelected().id)][1]);
    else if (setting == "length")
        lengthDesc.text = $.Localize(lengthModes[parseInt(lengthDD.GetSelected().id)][1]);
}

function PopulateDropDown( DropDown, items )
{
    for (var item in items)
    {
        var label = $.CreatePanel("Label", DropDown, item);
        label.text = $.Localize(items[item][0]);
        DropDown.AddOption(label);
    }
}

*/