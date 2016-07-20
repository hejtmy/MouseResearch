DECLARE FUNCTION CheckLever()
DECLARE FUNCTION MidnightCorrection()

DECLARE SUB WaitForTime(waittime as SINGLE)    'Runs for designated time - basically pauses the scrip

TYPE TCycle
    duration AS SINGLE 'cycle duration in seconds
END TYPE

DECLARE SUB DoDRLExperiment(loopstarttime as SINGLE, cycle as TCycle)
DECLARE SUB DoBasicExperiment(loopstarttime as SINGLE, cycle as TCycle)

DECLARE SUB RewardEachLever()
DECLARE SUB RewardEachNthLever(nth%)

DECLARE SUB TryWrite(lasttime as SINGLE)
DECLARE SUB FillCycles(ncycles%,cdur!)

OPTION BASE 1
'----------------------------------------------------------------------------
'       Define user types
'----------------------------------------------------------------------------
TYPE TExperiment
    type AS STRING * 10 'sets the type of the experiment to DRL, BASIC ...
    reward AS STRING * 10 'sets the reward scenario to NTH, EACH ...
    rewardduration AS SINGLE '
    rewardnumber AS INTEGER 'number to define either nth reward or time during which
    intertrialtime AS SINGLE
END TYPE

TYPE TLever
    status AS INTEGER 'lever status
    laststatus AS INTEGER 'last known status
    lasttimechanged AS SINGLE 'last time the lever changed status
    sensitivity AS SINGLE '(10msec)
    address AS LONG 'parallel port address
    bit AS LONG 'which bit on the port is used?
END TYPE

TYPE TFeeder
    duration AS SINGLE 'duration (10msec) of feeder activation
    delay AS SINGLE 'activation delay (10msec)
    lasttimeactivated AS SINGLE 'time (10msec) of the last activation
    status AS INTEGER '0..no activated, -1 or 1..activated
    address AS LONG 'parallel port address
    bit AS LONG 'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
DIM timesincestart AS SINGLE
DIM SHARED lever AS TLever
DIM SHARED feeder AS TFeeder
DIM experiment AS TExperiment
DIM currentcycle AS TCycle
DIM writeinterval AS SINGLE 'how often do we want to log stuff
DIM numcycles AS INTEGER 'number of cycles in the experimental session
DIM fstr$ 'output file format string

'-----------------------------------
'       BASIC INICIALIZATIONS
'-----------------------------------

lever.sensitivity = 0.01
feeder.delay = 0.01
feeder.duration = 1

selectcomputer:
INPUT ; "Which computer are you runing the experiment on? (right, left, test): ", computer$
SELECT CASE computer$
    CASE "right"
        lever.address = &H300
        lever.bit = 1
        feeder.address = &H302
        feeder.bit = 1
    CASE "left"
        lever.address = &H379
        lever.bit = 5
        feeder.address = &H378
        feeder.bit = 2
    CASE "test"
        lever.address = -1
        lever.bit = 0
        feeder.address = -1
        feeder.bit = 0
    CASE ELSE
        PRINT ("You haven't selected any valid choice")
        GOTO selectcomputer
END SELECT

'----------------------------------------------------------------------------
'       PORT ACTIVATION
'----------------------------------------------------------------------------

IF feeder.address = &H302 THEN OUT &H303, &H92
feeder.status = 0
'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------

DO
	timesincestart = GetTime
    key$ = INKEY$
	print key$
	//if CheckLever = 3 THEN ActivateFeeder
	s% = CheckFeeder
LOOP UNTIL key$ = CHR$(27)
'----------------------------------------------------------------------------
'       FUNCTIONS
'----------------------------------------------------------------------------
FUNCTION GetTime
	GetTime! = TIMER 
END FUNCTION

FUNCTION CheckLever 			'returns 1, 3 or lever.status * 2
	SHARED lever AS TLever, feeder AS TFeeder
	SHARED timesincestart AS SINGLE

	IF lever.address >= 0 THEN 'only if we actually have a lever
		lever.status = INP(lever.address) 				'INPUT from parallel port on designated address - right computer gets 3 on pressed and 2 on left alone
	END IF

	IF lever.laststatus <> lever.status THEN 'if the new status is different from the old one
		'lever was released or pressed including bouncing
		lever.lasttimechanged = timesincestart
	END IF

	CheckLever = 3 'if it was 1, it turns to 2
	'if the time since last change is bigger than sensitivity of the lever, we take a look on what the value is

	IF timesincestart - lever.lasttimechanged >= lever.sensitivity THEN 'if there was a lever press, and it was before the time we set for sensitivity
		IF lever.status = 1 THEN 'lever pressed?
			lever.lasttimechanged = -1
			CheckLever = 3
		ELSE
			lever.lasttimechanged = -1
			CheckLever = 0
		END IF
	END IF

	lever.laststatus = lever.status 'resets the status

END FUNCTION

FUNCTION CheckFeeder
SHARED feeder AS TFeeder
SHARED timesincestart AS SINGLE

CheckFeeder = feeder.status * 2 'What is this?
IF feeder.status < 0 THEN 'this happens in the activate feeder
    'if we want to activate the feeder and the time of activation was set in the ActivateFeeder function
    IF timesincestart >= feeder.lasttimeactivated THEN
        feeder.status = 1 'sets the status to activated
        'actually turns on the feeder or BEEPS in case the parallel port does not exist
        IF feeder.address >= 0 THEN OUT feeder.address, 2 ^ feeder.bit - 1 ELSE SOUND 1000, 2
        CheckFeeder = 1
    END IF
    'if we wanted to have the feeder activated, but it's already running for its duration, we turn it off
ELSEIF feeder.status = 1 AND timesincestart - feeder.lasttimeactivated > feeder.duration THEN
    'this allows the feeder to be turned on
    feeder.status = 0
    'InitLever          'do I need it? don't think so
    IF feeder.address >= 0 THEN OUT feeder.address, 0 ELSE SOUND 500, 2 'turns the feeder off
    CheckFeeder = 3
END IF
END FUNCTION

SUB ActivateFeeder 'only changes the status, CheckFeeder actually turns it on
SHARED feeder AS TFeeder
SHARED timesincestart AS SINGLE
'if the feeder is not running, we can turn it on
IF feeder.status = 0 THEN
    feeder.lasttimeactivated = timesincestart + feeder.delay
    feeder.status = -1
END IF
END SUB
