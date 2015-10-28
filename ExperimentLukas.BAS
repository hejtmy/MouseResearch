DECLARE FUNCTION GetTime! ()
DECLARE FUNCTION CheckFeeder! ()
DECLARE SUB ActivateFeeder ()
DECLARE SUB Write2File ()
DECLARE FUNCTION CheckLever ()
DECLARE FUNCTION MidnightCorrection (time!)

DECLARE SUB WaitForTime (waittime AS SINGLE)    'Runs for designated time - basically pauses the scrip

TYPE TCycle
	duration AS SINGLE      'cycle duration in seconds
END TYPE

DECLARE FUNCTION DoDRLExperiment
DECLARE SUB DoBasicExperiment

DECLARE SUB RewardEachLever
DECLARE SUB RewardEachNthLever (nth%)

DECLARE FUNCTION TryWrite (lasttime AS SINGLE)
DECLARE SUB FillCycles (ncycles%, cdur)

OPTION BASE 1
'----------------------------------------------------------------------------
'       Define user types
'----------------------------------------------------------------------------
TYPE TExperiment
	exptype AS INTEGER 'sets the type of the experiment to DRL, BASIC ...
	reward AS INTEGER 'sets the reward scenario to NTH, EACH ...
	rewardduration AS SINGLE '
	rewardnumber AS INTEGER 'number to define either nth reward or time during which
	intertrialtime AS SINGLE
END TYPE

TYPE TLever
  status AS INTEGER                             'lever status
  laststatus AS INTEGER         'last known status
  lasttimechanged AS SINGLE     'last time the lever changed status
  sensitivity AS SINGLE                 '(10msec)
  address AS LONG                               'parallel port address
  bit AS LONG                                   'which bit on the port is used?
END TYPE

TYPE TFeeder
  duration AS SINGLE                            'duration (10msec) of feeder activation
  delay AS SINGLE                               'activation delay (10msec)
  lasttimeactivated AS SINGLE           'time (10msec) of the last activation
  status AS INTEGER                                     '0..no activated, -1 or 1..activated
  address AS LONG                                       'parallel port address
  bit AS LONG                                           'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
DIM timesincestart AS SINGLE
DIM lever AS TLever
DIM feeder AS TFeeder
DIM experiment AS TExperiment
DIM currentcycle AS TCycle
DIM writeinterval AS SINGLE     'how often do we want to log stuff
DIM numcycles AS INTEGER                'number of cycles in the experimental session
DIM fstr$                                       'output file format string
DIM etype AS STRING
DIM cdur AS SINGLE
DIM rtype AS STRING
DIM rdur AS SINGLE
DIM rnum AS INTEGER
DIM intertrialtime AS SINGLE

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
rewritefile:                 'gotopoint
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
		PRINT ("You havent selected any valid choice")
		GOTO selectcomputer
END SELECT
'PUTS the option to skip all this to either load variables from a different source or to let the defaults take over
PRINT ""
'get the experiment type
getexperimenttype:
INPUT ; "Please enter experiment type (basic, drl): ", inpetype$
SELECT CASE inpetype$
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
INPUT "How many cycles should there be in an experiment?: ", inpnumcycles%                      'THIS IS NOT VALIDATED! TODO
numcycles = inpnumcycles%
PRINT ""
'getexperimentduration
INPUT "How long should the experiment cycle cycle last in seconds?: ", inpcdur!                         'THIS IS NOT VALIDATED! TODO
cdur = inpcdur!

'INPUT the reward type
getrewardtype:
PRINT ""
INPUT ; "Please enter reward type (each, nth, first): ", inprtype$
SELECT CASE inprtype$
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
IF rtype = "NTH" THEN
	PRINT ""
	INPUT "You selected each nth lever press would bring reward. Please enter how often should that be (2,3,5 etc.): ", inprnum%                    'THIS IS NOT VALIDATED! TODO
	experiment.rewardnumber = inprnum%
	rnum = inprnum%
END IF
PRINT ""

'getrewardduration
INPUT "How long should the reward cycle last?: ", imprdur!      'THIS IS NOT VALIDATED! TODO
experiment.rewardduration = imprdur!
rdur = imprdur!


'----------------------------------------------------------------------------
'       INICIALIZATIONS
'----------------------------------------------------------------------------

intertrialtime = 5
writeinterval = 2
'----------------------------------------------------------------------------
'       PORT ACTIVATION
'----------------------------------------------------------------------------

IF feeder.address = &H302 THEN OUT &H303, &H92
feeder.status = 0

'----------------------------------------------------------------------------
'       LEVER FEEDER INICIALIZATIONS
'----------------------------------------------------------------------------
lever.sensitivity = .01
feeder.delay = .01
feeder.duration = 1
'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------

timesincestart = GetTime                                                                'START OF THE EXPERIMENT

FOR icycle = 1 TO numcycles STEP 1
startmaincycle:                                                                                 'goto point
	'---
	'In the designated loop time
	'---
	
	'---
	'       WriteLoopStarted
	'---			
	
	'---
	'       SIGNAL
	'---
	
	'---
	'       TEST PHASE
	'---
	'gets the last time a log has been made
	PRINT "cycle started"
	'plays the experimental scenario based on the input values
	SELECT CASE etype
	loopstarttime! = GetTime
	lasttimewrite! = loopstarttime! 
		'---
		'checks for lever press during the cycle if the experiment is evil
		'---
		CASE "DRL"
			drl% = DoDRLExperiment
			lasttimewrite! = TryWrite(lasttimewrite!)
			'Write loop ended
			if drl% = 0 THEN GOTO startmaincycle
		CASE "BASIC"
			DoBasicExperimentExperiment
			'Write loop ended
			lasttimewrite! = TryWrite(lasttimewrite!)
		CASE ELSE
	END SELECT
	'---
	'       REWARD PHASE
	'---
	PRINT "reward phase started"
	SELECT CASE rtype
		CASE "EACH"
			RewardEachLever
		CASE "NTH"
			RewardEachNthLever (rnum)
		CASE "FIRST"
			RewardFirst
		CASE "TIME"
			PRINT "TIME"
		CASE ELSE
			PRINT "ELSE"
	END SELECT
	PRINT "inter trial started"
	WaitForTime (intertrialtime)    'problem - mouse doesn't know it stopped being rewarded - how to distinguis inter trial and reward phase?
	endmaincycle:                   'goto point
NEXT icycle

'needs to turn off the feeder

CLOSE #fid
'turns off the feeder
if feeder.address >0 THEN OUT feeder.address, 0


PRINT "EXPERIMENT FINISHED, PLEASE PRESS A KEY"

'----------------------------------------------------------------------------
'       END
'----------------------------------------------------------------------------

'----------------------------------------------------------------------------
'       EXPERIMENT SUBROUTINES
'----------------------------------------------------------------------------
FUNCTION DoDRLExperiment()
	SHARED cdur AS SINGLE
	SHARED lever as TLever
	SHARED timesincestart as SINGLE
	loopstarttime! = GetTime
	DoDRLExperiment = 1		'we set the default return to 1
	WHILE loopstarttime! + cdur >= GetTime AND exit% = 0 
		timesincestart = GetTime
		leverstatus% = CheckLever
		'Write that the mouse pressed the lever
		IF leverstatus% = 1 THEN 
			DoDRLExperiment = 0 'the evil step, we return 0, meaning the step ended prematurely
			exit% = 1
		END IF
	WEND
END FUNCTION

SUB DoBasicExperiment()
	SHARED cdur AS SINGLE
	SHARED lever as TLever
	SHARED timesincestart as SINGLE
	loopstarttime! = GetTime
	'we set the default return to 1
	WHILE loopstarttime! + cdur >= GetTime
		timesincestart = GetTime
		leverstatus% = CheckLever
		'Write that the mouse pressed the lever
		IF leverstatus% = 1 THEN 
			'Write it down
		END IF
	WEND
END SUB

'----------------------------------------------------------------------------
'       REWARD SUBROUTINES
'----------------------------------------------------------------------------
SUB RewardEachLever
	RewardEachNthLever (1)
END SUB

SUB RewardEachNthLever (nth%)
	SHARED lever AS TLever
	SHARED rdur AS SINGLE
	SHARED timesincestart AS SINGLE
	activated% = 1
	numberofpresses% = 0
	previouslever% = 0
	loopstarttime! = GetTime
	WHILE loopstarttime! + rdur >= GetTime
		timesincestart = GetTime
		leverstatus% = CheckLever
		f% = CheckFeeder	'checks the 
		'need to log it in the script
		IF leverstatus% = 1 AND previouslever% = 0 AND f% = 0 THEN 	'if the new lever follows no lever pressed and the feeder is not going, we increment the number of presses
			numberofpresses% = numberofpresses% + 1
			previouslever% = 1
		END IF
		IF leverstatus% = 0 THEN 	'if the lever was released we can start counting again
			activated% = 0
			previouslever% = 0
		END IF
		IF numberofpresses% > 0 AND(numberofpresses% MOD nth%) = 0 AND activated% = 0 THEN 
			ActivateFeeder
			activated% = 1
		END IF
	WEND
END SUB

SUB RewardFirst
	SHARED rdur AS SINGLE
	SHARED lever AS TLever
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	loopstarttime! = GetTime
	feederactivated% = 0
	WHILE loopstarttime! + rdur >= GetTime  'the mouse has only specified time to press the lever
		leverstatus% = CheckLever
		'need to log it in the script
		IF leverstatus% = 1 AND feederactivated% = 0 THEN
			ActivateFeeder
			feederactivated% = 1
		END IF
	WEND
END SUB
'----------------------------------------------------------------------------
'       HELPER SUBROUTINES
'----------------------------------------------------------------------------


'----------------------------------------------------------------------------
'       CONNECTION SUBROUTINES
'----------------------------------------------------------------------------
SUB ActivateFeeder 'only changes the status, CheckFeeder actually turns it on
SHARED feeder AS TFeeder
SHARED timesincestart AS SINGLE
'if the feeder is not running, we can turn it on
IF feeder.status = 0 THEN
	feeder.lasttimeactivated = timesincestart + feeder.delay
	feeder.status = -1
END IF
END SUB

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

FUNCTION CheckLever                     'returns 1, 3 or lever.status * 2
	SHARED lever AS TLever, feeder AS TFeeder
	SHARED timesincestart AS SINGLE

	IF lever.address >= 0 THEN 'only if we actually have a lever
		lever.status = INP(lever.address)                               'INPUT from parallel port on designated address - right computer gets 3 on pressed and 2 on left alone
	END IF

	IF lever.laststatus <> lever.status THEN 'if the new status is different from the old one
		'lever was released or pressed including bouncing
		lever.lasttimechanged = timesincestart
	END IF

	CheckLever = 3 'if it was 1, it turns to 2
	'if the time since last change is bigger than sensitivity of the lever, we take a look on what the value is

	IF timesincestart - lever.lasttimechanged >= lever.sensitivity THEN 'if there was a lever press, and it was before the time we set for sensitivity
		IF lever.status = 2 THEN 'lever pressed?
			lever.lasttimechanged = -1
			CheckLever = 1
		ELSE
			lever.lasttimechanged = -1
			CheckLever = 0
		END IF
	END IF

	lever.laststatus = lever.status 'resets the status

END FUNCTION

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

FUNCTION TryWrite (time!)
	IF time! - GetTime > writeinterval THEN                 'if the time from the last log is larger than the logging frequency
		Write2File                                                                      'we write the log
		TryWrite = GetTime                                                      'and send the the time of the log to the SUBROUTINE, so that it knows when it was made                                                        
	ELSE TryWrite = time!                                                   'otherwise we send the time back
	END IF
END FUNCTION

'----------------------------------------------------------------------------
'       EXPERIMENTAL SUBROUTINES
'----------------------------------------------------------------------------
SUB WaitForTime (t!) 'basically does nothing, just waits
	starttime! = GetTime
	WHILE starttime! + t! >= GetTime
		
	WEND
	CLOSE
END SUB

SUB Write2File

  SHARED lever AS TLever, feeder AS TFeeder
  SHARED timesincestart AS SINGLE
	PRINT "Info Written"
	'WHAT do we want to write down?
	'PRINT #fid, USING fstr$; msg; t; tc; c + 1; h + 1; ct + 1;
	'PRINT #fid, USING fstr$; Cs(ct).sch(Cs(ct).k);
	'FOR j = LBOUND(Rs) TO UBOUND(Rs)
	  'PRINT #fid, USING fstr$; Rs(j).x; Rs(j).y;
	'NEXT j
	'PRINT #fid,
END SUB

