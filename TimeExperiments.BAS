DECLARE FUNCTION GetTime ()
DECLARE FUNCTION CheckFeeder ()
DECLARE FUNCTION CheckLever ()
DECLARE SUB ActivateFeeder ()

DECLARE FUNCTION MidnightCorrection (time!)

DECLARE SUB WaitForTime (waittime AS SINGLE)    'Runs for designated time - basically pauses the scrip

TYPE TCycle
    duration AS SINGLE 'cycle duration in seconds
END TYPE

DECLARE FUNCTION DoDRLExperiment ()
DECLARE SUB DoBasicExperiment ()
DECLARE SUB InterTrialTimeSub ()

DECLARE SUB RewardEachLever ()
DECLARE SUB RewardEachNthLever (nth%)
DECLARE SUB RewardFirst ()

DECLARE SUB TryWrite ()
DECLARE SUB Write2File ()
DECLARE SUB WriteHeader ()
DECLARE SUB WriteEvent(event$)

DECLARE SUB Signal2 ()      'signal for the rat

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
    activatetime AS SINGLE 'time (10msec) of the last activation
    status AS INTEGER '0..no activated, -1 or 1..activated
    address AS LONG 'parallel port address
    bit AS LONG 'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
DIM timesincestart AS SINGLE
DIM lever AS TLever
DIM feeder AS TFeeder
DIM experiment AS TExperiment
DIM currentcycle AS TCycle
DIM writeinterval AS SINGLE 'how often do we want to log stuff
DIM numcycles AS INTEGER 'number of cycles in the experimental session
DIM fstr$ 'output file format string
DIM etype AS STRING
DIM cdur AS SINGLE
DIM rtype AS STRING
DIM rdur AS SINGLE
DIM rnum AS INTEGER
DIM intertrialtime AS SINGLE
DIM phase AS STRING
DIM icycle AS INTEGER

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

getexperimentcycles:
INPUT "How many cycles should there be in an experiment?: ", inpnumcycles% 'THIS IS NOT VALIDATED! TODO
IF inpnumcycles% > 0 THEN
    numcycles = inpnumcycles%
ELSE
    PRINT ("You haven't selected any valid choice")
    GOTO getexperimentcycles
END IF

getexperimentduration:
INPUT "How long should the experiment cycle cycle last in seconds?: ", inpcdur! 'THIS IS NOT VALIDATED! TODO
IF inpcdur! > 0 THEN
    cdur = inpcdur!
ELSE
    PRINT ("You haven't selected any valid choice")
    GOTO getexperimentduration
END IF

'INPUT the reward type
getrewardtype:
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
PRINT ""

'get the reward number (seconds for
IF rtype = "NTH" THEN
    PRINT ""
    getrewardnumber:
    INPUT "You selected each nth lever press would bring reward. Please enter how often should that be (2,3,5 etc.): ", inprnum% 'THIS IS NOT VALIDATED! TODO
    IF inprnum% > 0 THEN
        rnum = inprnum%
    ELSE
        PRINT ("You haven't selected any valid choice")
        GOTO getrewardnumber
    END IF
END IF

getrewardduration:
INPUT "How long should the reward cycle last?: ", inprdur! 'THIS IS NOT VALIDATED! TODO
IF inprdur! > 0 THEN
    rdur = inprdur!
ELSE
    PRINT ("You haven't selected any valid choice")
    GOTO getrewardduration
END IF

getintertrialtime:
INPUT "How long should the intertrial time be?: ", inpinter! 'THIS IS NOT VALIDATED! TODO
IF inpinter! > 0 THEN
    intertrialtime = inpinter!
ELSE
    PRINT ("You haven't selected any valid choice")
    GOTO getintertrialtime
END IF
'----------------------------------------------------------------------------
'       INICIALIZATIONS
'----------------------------------------------------------------------------

'intertrialtime = 1
writeinterval = 0.01
fstr$ = "########"
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

timesincestart = GetTime 'START OF THE EXPERIMENT
WriteHeader
WriteEvent ("ExperimentStarted")
PRINT "experiments started" 'DEBUG
FOR icycle = 1 TO numcycles STEP 1
    startmaincycle: 'goto point
    '----------------------------
    '       WriteLoopStarted
    '----------------------------

    PRINT "cycle started"
    '-----------------------
    '       SIGNAL
    '-----------------------
    Signal2
    '-----------------------
    '       TEST PHASE
    '-----------------------
    phase = "TEST"
    'plays the experimental scenario based on the input values
    PRINT "test phase started" 'DEBUG
    WriteEvent ("TestPhaseStarted")
    phase = "TEST"
    SELECT CASE etype
        CASE "DRL"
			startdrl! = GetTime
            DoDRLExperiment
            'Write loop ended
			IF GetTime - startdrl! < cdur THEN GOTO startmaincycle
        CASE "BASIC"
            DoBasicExperiment
            'Write loop ended
        CASE ELSE
    END SELECT
    PRINT "test ended" 'DEBUG
    WriteEvent ("TestPhaseEnded")
    '-------------------------
    '       REWARD PHASE
    '--------------------------
    WriteEvent ("RewardPhaseStarted")
    PRINT "reward started" 'DEBUG
    phase = "REWARD"
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
    PRINT "reward ended" 'DEBUG
    WriteEvent ("RewardPhaseEnded")
    WriteEvent ("InterTrialStarted")
    PRINT "intertrial started" 'DEBUG
    phase = "INTERTRIAL"
    InterTrialTimeSub 'problem - mouse doesn't know it stopped being rewarded - how to distinguis inter trial and reward phase?
    WriteEvent ("InterTrialEnded")
    endmaincycle: 'goto point
    PRINT "new cycle should start" 'DEBUG
NEXT
WriteEvent ("ExperimentEnded")
CLOSE #fid
IF feeder.address > 0 THEN OUT feeder.address, 0 'turns off the feeder
PRINT "EXPERIMENT FINISHED, PLEASE PRESS A KEY"

'----------------------------------------------------------------------------
'       END
'----------------------------------------------------------------------------

'----------------------------------------------------------------------------
'       EXPERIMENT SUBROUTINES
'----------------------------------------------------------------------------
SUB DoDRLExperiment ()
SHARED cdur AS SINGLE
SHARED lever AS TLever
SHARED timesincestart AS SINGLE
exiting% = 0
loopstarttime! = GetTime
running = 1 		'we set the default return to 1
WHILE loopstarttime! + cdur >= GetTime AND running = 1
    timesincestart = GetTime
    leverstatus% = CheckLever
    IF leverstatus% = 1 THEN
        'Write that the mouse pressed the lever - should be in the TryWriteFunction
        runing = 0 'the evil step, we return 0, meaning the step ended prematurely
    END IF
    TryWrite
WEND
END SUB

SUB DoBasicExperiment ()
SHARED cdur AS SINGLE
SHARED lever AS TLever
SHARED timesincestart AS SINGLE
loopstarttime! = GetTime
'we set the default return to 1
WHILE loopstarttime! + cdur >= GetTime
    timesincestart = GetTime
    TryWrite
WEND
END SUB

'----------------------------------------------------------------------------
'       REWARD SUBROUTINES
'----------------------------------------------------------------------------
SUB RewardEachLever
RewardEachNthLever (1)
END SUB

SUB RewardEachNthLever (nth%)
SHARED rdur AS SINGLE
SHARED timesincestart AS SINGLE
numberofpresses% = 0
activated% = 0
previouslever% = 0
loopstarttime! = GetTime
WHILE loopstarttime! + rdur >= GetTime
    timesincestart = GetTime
    leverstatus% = CheckLever 'checks the lever
    f% = CheckFeeder 'checks the feeder - if it's running
    IF leverstatus% = 1 AND previouslever% = 0 AND f% = 0 THEN 'if the new lever follows no lever pressed and the feeder is not going, we increment the number of presses
        numberofpresses% = numberofpresses% + 1
        previouslever% = 1
		activated% = 0
    END IF
    IF leverstatus% = 0 THEN 'if the lever was released we can start counting again
        previouslever% = 0
    END IF
	'if we should activate the feeder and it's not running
    IF numberofpresses% > 0 AND (numberofpresses% MOD nth%) = 0 AND f% = 0 AND Activated% = 0 THEN
        ActivateFeeder
		activated% = 1
        WriteEvent ("RewardAdministered")
    END IF
    TryWrite
WEND
END SUB

SUB RewardFirst
SHARED rdur AS SINGLE
SHARED timesincestart AS SINGLE
loopstarttime! = GetTime
feederactivated% = 0 'if the feeder has alrady been activated once
rewarddone% = 0
WHILE loopstarttime! + rdur >= GetTime AND rewarddone% = 0 'the mouse has only specified time to press the lever
    timesincestart = GetTime
    leverstatus% = CheckLever
    feederstatus% = CheckFeeder
    IF leverstatus% = 1 AND feederactivated% = 0 THEN
        ActivateFeeder
        feederactivated% = 1
        WriteEvent ("RewardAdministered")
    END IF
    IF feederstatus% = 0 AND feederactivated% = 1 THEN rewarddone% = 1 'if the reward was given, we finish the subroutine
    TryWrite
WEND
END SUB
'----------------------------------------------------------------------------
'       HELPER SUBROUTINES
'----------------------------------------------------------------------------
SUB WaitForTime (t!) 'basically does nothing, just waits
starttime! = GetTime
WHILE starttime! + t! >= GetTime
    TryWrite
WEND
END SUB

SUB Signal2
	SOUND 500, 2
END SUB
'----------------------------------------------------------------------------
'       CONNECTION SUBROUTINES
'----------------------------------------------------------------------------
SUB ActivateFeeder 'only changes the status, CheckFeeder actually turns it on
SHARED feeder AS TFeeder
SHARED timesincestart AS SINGLE
'if the feeder is not running, we can turn it on
IF feeder.status = 0 THEN
    feeder.activatetime = timesincestart + feeder.delay
    feeder.status = -1
END IF
END SUB

FUNCTION CheckFeeder
SHARED feeder AS TFeeder
SHARED timesincestart AS SINGLE

CheckFeeder = feeder.status
IF feeder.status < 0 THEN 'this happens in the activate feeder
    'if we want to activate the feeder and the time of activation was set in the ActivateFeeder function
    IF timesincestart >= feeder.activatetime THEN
        feeder.status = 1 'sets the status to activated
        'actually turns on the feeder or BEEPS in case the parallel port does not exist
        IF feeder.address >= 0 THEN OUT feeder.address, 2 ^ feeder.bit - 1 ELSE SOUND 1000, 2
        CheckFeeder = 1
    END IF
    'if we wanted to have the feeder activated, but it's already running for its duration, we turn it off
ELSEIF feeder.status = 1 AND timesincestart - feeder.activatetime > feeder.duration THEN
    'this allows the feeder to be turned on
    feeder.status = 0
    'InitLever          'do I need it? don't think so
    IF feeder.address >= 0 THEN OUT feeder.address, 0 ELSE SOUND 500, 2 'turns the feeder off
    CheckFeeder = 0
END IF
END FUNCTION

FUNCTION CheckLever 'returns 1, 3 or lever.status * 2
SHARED lever AS TLever, feeder AS TFeeder
SHARED timesincestart AS SINGLE

IF lever.address >= 0 THEN 'only if we actually have a lever
    lever.status = INP(lever.address) 'INPUT from parallel port on designated address - right computer gets 3 on pressed and 2 on left alone
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


SUB InterTrialTimeSub 'basically does nothing, just waits
SHARED intertrialtime AS SINGLE
SHARED timesincestart AS SINGLE
starttime! = GetTime
WHILE starttime! + intertrialtime >= GetTime
    timesincestart = GetTime
    TryWrite
WEND
END SUB

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

'----------------------------------------------------------------------------
'       WRITE FUNCTIONS
'----------------------------------------------------------------------------
SUB TryWrite
STATIC lasttimewrite!
SHARED writeinterval AS SINGLE
IF GetTime - lasttimewrite! > writeinterval THEN 'if the time from the last log is larger than the logging frequency
    Write2File 'we write the log
    lasttimewrite! = GetTime 'and send the the time of the log to the SUBROUTINE, so that it knows when it was made
END IF
END FUNCTION

SUB WriteHeader
SHARED fid
PRINT #fid, "HEADER"
PRINT #fid, "Name of the experiment"
PRINT #fid, "Computer"
PRINT #fid, "Experiment type: ", etype 'Type of experiment
PRINT #fid, "Number of cycles: ", icycle 'number of iterations
PRINT #fid, "Duration of each test cycle: ", cdur 'length of each
PRINT #fid, "Reward type: ", rtype
PRINT #fid, "Duration of reward cycle: ", rdur
PRINT #fid, "Inter trial time: ", intertrialtime
PRINT #fid, "*********"
END SUB

SUB WriteEvent (event$)
SHARED fid
PRINT #fid, "---"
PRINT #fid, event$, ";", GetTime
PRINT #fid, "---"
END SUB

SUB Write2File
SHARED fstr$
SHARED lever AS TLever, feeder AS TFeeder
SHARED timesincestart AS SINGLE
SHARED icycle AS INTEGER
SHARED phase AS STRING
SHARED fid
'WHAT do we want to write down?
'TIME, CYCLE NUMBER, PHASE, LEVER STATUS, FEEDER STATUS
PRINT #fid, timesincestart; icycle; phase; CheckLever; CheckFeeder
END SUB

SUB Write2Screen
SHARED lever AS TLever, feeder AS TFeeder
SHARED timesincestart AS SINGLE
SHARED icycle AS INTEGER
timesincestart = GetTime
'WHAT do we want to write down?
'TIME, CYCLE NUMBER, PHASE, LEVER STATUS, FEEDER STATUS
PRINT USING fstr$; timesincestart; icycle, phase; CheckLever; CheckFeeder
END SUB
