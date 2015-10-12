DECLARE FUNCTION CheckLever& ()
DECLARE FUNCTION MidnightCorrection()

DECLARE SUB WaitForTime(wait_time as SINGLE)    'Runs for designated time - basically pauses the scrip

DECLARE SUB DoDRLExperiment(loop_start_time as SINGLE,cycle as TCycle)
DECLARE SUB DoBasicExperiment(loop_start_time as SINGLE, cycle as TCycle)

DECLARE SUB RewardEachLever()
DECLARE SUB RewardEachNthLever(nth%)

DECLARE SUB TryWrite(last_time as SINGLE)
DECLARE SUB FillCycles(n_cycles%,c_dur!)

OPTION BASE 1
'----------------------------------------------------------------------------
'       Define user types
'----------------------------------------------------------------------------
TYPE TExperiment
    type AS STRING * 10 'sets the type of the experiment to DRL, BASIC ...
    reward AS STRING * 10 'sets the reward scenario to NTH, EACH ...
    reward_duration AS SINGLE '
    reward_number AS INTEGER 'number to define either nth reward or time during which
    inter_trial_time AS SINGLE
END TYPE

TYPE TCycle
    duration AS SINGLE 'cycle duration in seconds
END TYPE

TYPE TLever
    status AS INTEGER 'lever status
    last_status AS INTEGER 'last known status
    last_time_changed AS SINGLE 'last time the lever changed status
    sensitivity AS SINGLE '(10msec)
    address AS LONG 'parallel port address
    bit AS LONG 'which bit on the port is used?
END TYPE

TYPE TFeeder
    duration AS SINGLE 'duration (10msec) of feeder activation
    delay AS SINGLE 'activation delay (10msec)
    last_time_activated AS SINGLE 'time (10msec) of the last activation
    status AS INTEGER '0..no activated, -1 or 1..activated
    address AS LONG 'parallel port address
    bit AS LONG 'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
DIM time_since_start AS SINGLE
DIM SHARED lever AS TLever
DIM SHARED feeder AS TFeeder
DIM experiment AS TExperiment
DIM current_cycle AS TCycle
DIM write_interval AS SINGLE 'how often do we want to log stuff
DIM num_cycles AS INTEGER 'number of cycles in the experimental session
DIM fstr$ 'output file format string

'-----------------------------------
'       BASIC INICIALIZATIONS
'-----------------------------------

lever.sensitivity = 0.01
feeder.delay = 0.2
feeder.duration = 2

select_computer:
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
        GOTO select_computer
END SELECT

'----------------------------------------------------------------------------
'       PORT ACTIVATION
'----------------------------------------------------------------------------

IF feeder.address = &H302 THEN OUT &H303, &H92
'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------
feeder.status = 0
lever.last_status = 0
lever.status = 0
time_reset! = 0
DO
    time_since_start = GetTime
    IF time_reset! + 0.1 <= time_since_start THEN
		key$ = INKEY$
		IF key$ = CHR$(97) THEN
			lever.status = 1
		ELSE
			lever.status = 0
		END IF
		check% = CheckLever
		PRINT check%
		time_reset! = time_since_start
    END IF
	IF key$ = CHR$(98) THEN CLS
	If check% = 1 THEN ActivateFeeder
    s% = CheckFeeder
LOOP UNTIL key$ = CHR$(27)
'----------------------------------------------------------------------------
'       FUNCTIONS
'----------------------------------------------------------------------------
FUNCTION GetTime
GetTime = TIMER(.01)
END FUNCTION

FUNCTION CheckLever	'returns 1 =lever pressed for sure, or 0 lever surely untouched or 3 lever nor touched nor untouched
	SHARED lever AS TLever, feeder AS TFeeder
	SHARED time_since_start
	
  	CheckLever = 3				'if it was 1, it turns to 2

	IF lever.last_status <> lever.status THEN		'if the new status is different from the old one
		'lever was released or pressed including bouncing
		lever.last_time_changed = time_since_start
	END IF
	
	'if the time since last change is bigger than sensitivity of the lever, we take a look on what the value is
	
	IF time_since_start - lever.last_time_changed >= lever.sensitivity THEN 	'if there was a lever press, and it was before the time we set for sensitivity
		lever.last_time_changed = 0
		CheckLever = lever.status
	END IF
	
	lever.last_status = lever.status 'resets the status
	
END FUNCTION

FUNCTION CheckFeeder
SHARED feeder AS TFeeder
SHARED time_since_start

CheckFeeder = feeder.status * 2 'What is this?
IF feeder.status < 0 THEN 'this happens in the activate feeder
    'if we want to activate the feeder and the time of activation was set in the ActivateFeeder function
    IF time_since_start >= feeder.last_time_activated THEN
        feeder.status = 1 'sets the status to activated
        'actually turns on the feeder or BEEPS in case the parallel port does not exist
        IF feeder.address >= 0 THEN OUT feeder.address, 2 ^ feeder.bit - 1 ELSE PRINT "Activated"
        CheckFeeder = 1
    END IF
    'if we wanted to have the feeder activated, but it's already running for its duration, we turn it off
ELSEIF feeder.status = 1 AND time_since_start - feeder.last_time_activated > feeder.duration THEN
    'this allows the feeder to be turned on
    feeder.status = 0
    'InitLever          'do I need it? don't think so
    IF feeder.address >= 0 THEN OUT feeder.address, 0 ELSE PRINT "Deactivated" 'turns the feeder off
    CheckFeeder = 3
END IF
END FUNCTION

SUB ActivateFeeder 'only changes the status, CheckFeeder actually turns it on
SHARED feeder AS TFeeder
SHARED time_since_start
'if the feeder is not running, we can turn it on
IF feeder.status = 0 THEN
    feeder.last_time_activated = time_since_start + feeder.delay
    feeder.status = -1
END IF
END SUB
