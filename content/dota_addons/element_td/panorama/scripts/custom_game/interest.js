"use strict";

var INTEREST_INTERVAL = 0;
var INTEREST_RATE = 0.02;
var INTEREST_REFRESH = 0.05;

var interest = $( "#Interest" );
var interestBarGold = $( "#InterestBarGold" );
var interestBarDisabled = $( "#InterestBarDisabled" );
var tooltipAmount = $( "#TooltipAmount" );

var timerEnd = 0;
var totalGoldEarned = 0;
var enabled = false;
var timerStart = 0;

function UpdateInterest() {
	if (enabled) {
		if ( Game.GetGameTime() > timerEnd ) {
			timerStart = timerEnd;
			timerEnd += INTEREST_INTERVAL;
		}
		var widthPercentage = 100 - Math.floor((timerEnd - Game.GetGameTime())/INTEREST_INTERVAL * 100);
		interestBarGold.style["width"] = widthPercentage+"%";
	}
	$.Schedule(INTEREST_REFRESH, function() { UpdateInterest(); });
}

function DisplayInterest( table ) {
	timerStart = Game.GetGameTime();
	INTEREST_INTERVAL = table.interval;
	timerEnd = Game.GetGameTime() + INTEREST_INTERVAL;
	interestBarDisabled.visible = false;
	interest.visible = true;
	enabled = table.enabled;
	INTEREST_RATE = table.rate;
	if (!enabled)
		interestBarGold.style["width"] = "0%";
}

function InterestEarned( table ) {
	enabled = true;
	interest.visible = true;
	// Sync
	timerStart = Game.GetGameTime();
	timerEnd = timerStart + INTEREST_INTERVAL;
	totalGoldEarned += table.goldEarned;
	tooltipAmount.text = totalGoldEarned;
}

function PauseInterest( table ) {
	enabled = false;
	interestBarDisabled.visible = true;
	interestBarDisabled.style["width"] = interestBarGold.style["width"];
	interestBarGold.visible = false;
}

function ResumeInterest( table ) {
	var time = Game.GetGameTime();
	timerStart = time - INTEREST_INTERVAL + table.timeRemaining;
	timerEnd = time + table.timeRemaining;
	interestBarDisabled.visible = false;
	interestBarGold.visible = true;
	
	enabled = true;
}

(function () {
  UpdateInterest();
  interest.visible = false;
  GameEvents.Subscribe( "etd_display_interest", DisplayInterest );
  GameEvents.Subscribe( "etd_earned_interest", InterestEarned );
  GameEvents.Subscribe( "etd_pause_interest", PauseInterest );
  GameEvents.Subscribe( "etd_resume_interest", ResumeInterest );
})();