DECLARE FUNCTION CheckLever ()
DECLARE FUNCTION MidnightCorrection()

DECLARE SUB WaitForTime(waittime as SINGLE)	'Runs for designated time - basically pauses the scrip

TYPE TCycle
	duration AS SINGLE	'cycle duration in seconds
END TYPE

DECLARE SUB DoDRLExperiment(loopstarttime as SINGLE,cycle as TCycle)
DECLARE SUB DoBasicExperiment(loopstarttime as SINGLE, cycle as TCycle)

DECLARE SUB RewardEachLever()
DECLARE SUB RewardEachNthLever(nth%)

DECLARE SUB TryWrite(lasttime as SINGLE)
DECLARE SUB FillCycles(ncycles%,cdur)

OPTION BASE 1
'----------------------------------------------------------------------------
'       Define user types
'----------------------------------------------------------------------------
TYPE TExperiment
    exp_type AS INTEGER 'sets the type of the experiment to DRL, BASIC ...
    reward AS INTEGER 'sets the reward scenario to NTH, EACH ...
    rewardduration AS SINGLE '
    rewardnumber AS INTEGER 'number to define either nth reward or time during which
    intertrialtime AS SINGLE
END TYPE

TYPE TLever
  status AS INTEGER				'lever status
  laststatus AS INTEGER		'last known status
  lasttimechanged AS SINGLE	'last time the lever changed status
  sensitivity AS SINGLE			'(10msec)
  address AS LONG				'parallel port address
  bit AS LONG					'which bit on the port is used?
END TYPE

TYPE TFeeder
  duration AS SINGLE				'duration (10msec) of feeder activation
  delay AS SINGLE         			'activation delay (10msec)
  lasttimeactivated AS SINGLE		'time (10msec) of the last activation
  status AS INTEGER					'0..no activated, -1 or 1..activated
  address AS LONG					'parallel port address
  bit AS LONG						'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
DIM timesincestart AS SINGLE
DIM lever AS TLever
DIM feeder AS TFeeder
DIM experiment AS TExperiment
DIM currentcycle as TCycle		
DIM writeinterval as SINGLE	'how often do we want to log stuff
DIM numcycles as INTEGER		'number of cycles in the experimental session
DIM fstr$       				'output file format string
DIM etype AS STRING
DIM cdur AS SINGLE
DIM rtype AS STRING
DIM rdur AS SINGLE
DIM rnum AS INTEGER

'----------------------------------------------------------------------------
'       Open output file
'----------------------------------------------------------------------------

fid = FREEFILE
namefile:
INPUT ; "Type output file name and then press Enter: ", outfile$
IF LEN(outfile$) = 0 THEN
    PRINT "Choose a name, please"
    GOTO namefile
END IF
OPEN outfile$ FOR BINARY AS #fid
IF LOF(fid) <> 0 THEN 'if the file is NOT empty
    CLOSE #fid
    rewritefile: 'gotopoint
    PRINT "File already exists. Overwrite? (Y..yes, N..no):"
    DO
        LET k$ = INKEY$
    LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "y"
            OPEN outfile$ FOR OUTPUT AS #fid
        CASE "n"
            GOTO namefile
        CASE ELSE
            PRINT ("You haven't selected any valid choice")
            GOTO rewritefile
    END SELECT
ELSE
    CLOSE #fid
    OPEN outfile$ FOR OUTPUT AS #fid
END IF
PRINT ""
'-----------------------------------
'       BASIC INICIALIZATIONS
'-----------------------------------
selectcomputer:
INPUT ; "Which computer are you runing the experiment on? (right, left, test): ", computer$
SELECT CASE computer$
	CASE "right"
		Lever.address = &H300
		Lever.bit = 1
		Feeder.address = &H302
		Feeder.bit = 1
	CASE "left"
		Lever.address = &H379
		Lever.bit = 5
		Feeder.address = &H378
		Feeder.bit = 2
	CASE "test"
		Lever.address = -1
		Lever.bit = 0
		Feeder.address = -1
		Feeder.bit = 0
	CASE ELSE
		PRINT ("You havent selected any valid choice")
		GOTO selectcomputer
END SELECT

'PUTS the option to skip all this to either load variables from a different source or to let the defaults take over
PRINT ""
'get the experiment type
getexperimenttype:
INPUT ; "Please enter experiment type (basic, drl): ", etype_inp$
SELECT CASE etype_inp$
	CASE "drl"
		etype = "DRL"
	CASE "basic"
		etype = "BASIC"
	CASE ELSE
		PRINT ("You haven't selected any valid choice")
		GOTO getexperimenttype
END SELECT
PRINT ""
'getexperimentcycles
INPUT "How many cycles should there be in an experiment?: ", inp_numcycles% 			'THIS IS NOT VALIDATED! TODO
numcycles = inp_numcycles%
PRINT ""
'getexperimentduration
INPUT "How long should the experiment cycle cycle last in seconds?: ", inp_cdur! 			'THIS IS NOT VALIDATED! TODO
cdur = imp_cdur!

'INPUT the reward type
getrewardtype:
PRINT ""
INPUT ; "Please enter reward type (each, nth, first): ", rtype_inp$
SELECT CASE rtype_inp$
	CASE "first"
		rtype = "FIRST"
	CASE "each"
		rtype = "EACH"
	CASE "nth"
		rtype = "NTH"
	CASE ELSE
		PRINT ("You haven't selected any valid choice")
		GOTO getrewardtype
END SELECT

'get the reward number (seconds for 
IF experiment.reward = "NTH" THEN
	PRINT ""
	INPUT "You selected each nth lever press would bring reward. Please enter how often should that be (2,3,5 etc.): ", inp_rnum% 			'THIS IS NOT VALIDATED! TODO
	experiment.rewardnumber = inp_rnum%
	rnum = inp_rnum%
END IF
PRINT ""

'getrewardduration
INPUT "How long should the reward cycle last?: ", imp_rdur!	'THIS IS NOT VALIDATED! TODO
experiment.rewardduration = imp_rdur!
rdur = imp_rdur!

writeinterval = 2
'----------------------------------------------------------------------------
'       PORT ACTIVATION
'----------------------------------------------------------------------------

IF Feeder.address = &H302 THEN OUT &H303, &H92
Feeder.status = 0

'----------------------------------------------------------------------------
'       LEVER FEEDER INICIALIZATIONS
'----------------------------------------------------------------------------
lever.sensitivity = 0.01
'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------

timesincestart = GetTime								'START OF THE EXPERIMENT

FOR icycle = 1 TO numcycles STEP 1					
	startmaincycle:									'goto point
	'---
	'In the designated loop time
	'---

	'---
	'	SIGNAL
	'---
	
	'---
	'	TEST PHASE
	'---
	loopstarttime! = GetTime 			'SINGLE, should be enough
	lasttimewrite! = loopstarttime!	'gets the last time a log has been made
	Print "cycle started"
	WHILE loopstarttime! + cdur >= GetTime
	timesincestart = GetTime
		'plays the experimental scenario based on the input values
		SELECT CASE etype
			'---
			'checks for lever press during the cycle if the experiment is evil
			'---
			CASE "DRL"
				leverstatus% = CheckLever
				'Write that the mouse pressed the lever
				IF leverstatus% = 1 THEN GOTO startmaincycle 	'the evil step
			CASE "BASIC"
				lasttimewrite! = TryWrite(lasttimewrite!)
		END SELECT
	lasttimewrite! = TryWrite(lasttimewrite!)
	WEND
	'---
	'	REWARD PHASE
	'---
	Print "reward phase started"
	SELECT CASE rtype
		CASE "EACH"
			RewardEachLever
		CASE "NTH"
			RewardEachNthLever(rnum)
		CASE "TIME"
			print "TIME"
		CASE ELSE
			PRINT "ELSE"
	END SELECT
	Print "inter trial started"
	WaitForTime(intertrialtime)	'problem - mouse doesn't know it stopped being rewarded - how to distinguis inter trial and reward phase?
	endmaincycle:					'goto point
NEXT icycle

'needs to turn off the feeder

CLOSE #fid

PRINT "EXPERIMENT FINISHED, PLEASE PRESS A KEY"

'----------------------------------------------------------------------------
'       END
'----------------------------------------------------------------------------

'----------------------------------------------------------------------------
'       EXPERIMENTAL SUBROUTINES
'----------------------------------------------------------------------------
SUB WaitForTime (t!) 'basically does nothing, just waits
    starttime! = GetTime
    WHILE starttime! + t! >= GetTime
        
    WEND
    CLOSE
END SUB

'----------------------------------------------------------------------------
'       REWARD SUBROUTINES
'----------------------------------------------------------------------------

SUB RewardEachLever()
	RewardEachNthLever(1)
END SUB

SUB RewardFirst()
	SHARED rdur as SINGLE
	SHARED lever as TLever
	SHARED experiment as TExperiment
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	loopstarttime! = GetTime
	feederactivated% = 0
	WHILE loopstarttime! + rdur >= GetTime AND feederactivated = 0	'the mouse has only specified time to press the lever
		leverstatus% = CheckLever
		'need to log it in the script
		IF leverstatus% = 1 THEN 
			ActivateFeeder
			feederactivated = 1
		END IF
	WEND
END SUB

SUB RewardEachNthLever(nth%)
	SHARED lever AS TLever
	SHARED experiment	AS TExperiment
	SHARED rdur AS SINGLE
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	numberofpresses% = 0
	loopstarttime! = GetTime
	WHILE loopstarttime! + rdur >= GetTime
		leverstatus% = CheckLever
		'need to log it in the script
		IF leverstatus% = 1 THEN 
			numberofpresses% = numberofpresses% + 1
		END IF
		if numberofpresses% MOD nth% THEN ActivateFeeder
	WEND
END SUB

'----------------------------------------------------------------------------
'       HELPER SUBROUTINES
'----------------------------------------------------------------------------

'----------------------------------------------------------------------------
'       FUNCTIONS
'----------------------------------------------------------------------------
FUNCTION GetTime
	GetTime = TIMER
END FUNCTION

FUNCTION MidnightCorrection (time!)
IF time! > TIMER THEN
    MidnightCorrection! = time! - 86400 'takes care of experimenting over midnight - needs to be done in fucntion if necessary
ELSE
    MidnightCorrection! = time!
END IF
END FUNCTION

FUNCTION TryWrite(time!)
	IF time! - GetTime > writeinterval THEN 		'if the time from the last log is larger than the logging frequency
		Write2File									'we write the log
		TryWrite = GetTime							'and send the the time of the log to the SUBROUTINE, so that it knows when it was made								
	ELSE TryWrite = time!							'otherwise we send the time back
	END IF
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
    CheckFeeder = 0
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


SUB Write2File

  SHARED lever AS TLever, feeder AS TFeeder
  SHARED timesincestart AS SINGLE
	Print "Info Written"
	'WHAT do we want to write down?
    'PRINT #fid, USING fstr$; msg; t; tc; c + 1; h + 1; ct + 1;
    'PRINT #fid, USING fstr$; Cs(ct).sch(Cs(ct).k);
    'FOR j = LBOUND(Rs) TO UBOUND(Rs)
      'PRINT #fid, USING fstr$; Rs(j).x; Rs(j).y;
    'NEXT j
    'PRINT #fid,
END SUB