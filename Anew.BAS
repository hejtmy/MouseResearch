DECLARE FUNCTION CheckLever& ()
DECLARE FUNCTION MidnightCorrection()

DECLARE SUB WaitForTime(wait_time as SINGLE)	'Runs for designated time - basically pauses the scrip

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
	duration AS SINGLE	'cycle duration in seconds
END TYPE

TYPE TLever
  status AS INTEGER				'lever status
  last_status AS INTEGER		'last known status
  last_time_changed AS SINGLE	'last time the lever changed status
  sensitivity AS SINGLE			'(10msec)
  address AS LONG				'parallel port address
  bit AS LONG					'which bit on the port is used?
END TYPE

TYPE TFeeder
  duration AS SINGLE				'duration (10msec) of feeder activation
  delay AS SINGLE         			'activation delay (10msec)
  last_time_activated AS SINGLE		'time (10msec) of the last activation
  status AS INTEGER					'0..no activated, -1 or 1..activated
  address AS LONG					'parallel port address
  bit AS LONG						'which bit on the port is used:
END TYPE
'----------------------------------------------------------------------------
'       DECLARE VARIABLES
'----------------------------------------------------------------------------
time_since_start AS SINGLE
DIM lever AS TLever
DIM feeder AS TFeeder
DIM experiment AS TExperiment
DIM current_cycle as TCycle		
DIM write_interval as SINGLE	'how often do we want to log stuff
DIM num_cycles as INTEGER		'number of cycles in the experimental session
DIM fstr$       				'output file format string

'----------------------------------------------------------------------------
'       Open output file
'----------------------------------------------------------------------------

fid = FREEFILE
name_file:
INPUT ; "Type output file name and then press Enter: ", outfile$
IF LEN(outfile$) = 0 THEN
    PRINT "Choose a name, please"
    GOTO name_file
END IF
OPEN outfile$ FOR BINARY AS #fid
IF LOF(fid) <> 0 THEN 'if the file is NOT empty
    CLOSE #fid
    rewrite_file: 'gotopoint
    PRINT "File already exists. Overwrite? (Y..yes, N..no):"
    DO
        LET k$ = INKEY$
    LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE "y"
            OPEN outfile$ FOR OUTPUT AS #fid
        CASE "n"
            GOTO name_file
        CASE ELSE
            PRINT ("You haven't selected any valid choice")
            GOTO rewrite_file
    END SELECT
ELSE
    CLOSE #fid
    OPEN outfile$ FOR OUTPUT AS #fid
END IF

'-----------------------------------
'       BASIC INICIALIZATIONS
'-----------------------------------
select_computer:
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
		GOTO select_computer
END SELECT


'PUTS the option to skip all this to either load variables from a different source or to let the defaults take over

'get the experiment type
get_experiment_type:
INPUT ; "Please enter experiment type (basic, drl): ", e_type$
SELECT CASE e_type$
	CASE "drl"
		experiment.type = "DRL"
	CASE "basic"
		 experiment.type = "BASIC"
	CASE ELSE
		PRINT ("You haven't selected any valid choice")
		GOTO get_experiment_type
END SELECT

'get_experiment_cycles
INPUT "How many cycles should there be in an experiment?: ", num_cycles 			'THIS IS NOT VALIDATED! TODO

'get_experiment_duration
INPUT "How long should the experiment cycle cycle last in seconds?: ", c_dur! 			'THIS IS NOT VALIDATED! TODO

DIM SHARED cycles(num_cycles) AS TCycle
FillCycles(num_cycles,c_dur!)		'basically fills each cycle with predefined information - could be done easier, I was aiming for TYpes before I realized thay are ddifficult to work with in BASIC

'INPUT the reward type
get_reward_type:

INPUT ; "Please enter reward type (each, nth, first): ", r_type$
SELECT CASE e_type$
	CASE "first"
		experiment.reward = "FIRST"
	CASE "each"
		experiment.reward = "EACH"
	CASE "nth"
		experiment.reward = "NTH"
	CASE ELSE
		PRINT ("You haven't selected any valid choice")
		GOTO get_reward_type
END SELECT

'get the reward number (seconds for 
IF experiment.reward = "NTH" THEN
	INPUT "You selected each nth lever press would bring reward. Please enter how often should that be (2,3,5 etc.): ", r_num% 			'THIS IS NOT VALIDATED! TODO
	experiment.reward_number = r_num%
END IF

'get_reward_duration
INPUT "How long should the reward cycle last?: ", r_dur! 			'THIS IS NOT VALIDATED! TODO
experiment.reward_duration = r_dur!

'----------------------------------------------------------------------------
'       PORT ACTIVATION
'----------------------------------------------------------------------------

IF Feeder.address = &H302 THEN OUT &H303, &H92
Feeder.status = 0
'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------

time_since_start = GetTime								'START OF THE EXPERIMENT

FOR i_cycle = 1 TO num_cycles STEP 1
	current_cycle = cycles(i_cycle)						'initialises the cycle
	start_main_cycle:									'goto point

	'---
	'In the designated loop time
	'---

	'---
	'	SIGNAL
	'---
	
	'---
	'	TRAINING PHASE
	'---
	'plays the experimental scenario based on the input values
	SELECT CASE experiment.type
		CASE "DRL"
			DoDRLExperiment()
		CASE "BASIC"
			DoBasicExperiment()
	END SELECT
	
	'---
	'	REWARD PHASE
	'---
	
	SELECT CASE experiment.reward
		CASE "EACH"
			RewardEachLever()
		CASE "NTH"
			RewardEachNthLever(experiment.reward_number)
		CASE "TIME"
	END SELECT
		
	WaitForTime(inter_trial_time)	'problem - mouse doesn't know it stopped being rewarded - how to distinguis inter trial and reward phase?
	end_main_cycle:					'goto point
NEXT i_cycle

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
    start_time! = GetTime
    WHILE start_time! + t! >= GetTime
        
    WEND
    CLOSE
END SUB

SUB DoDRLExperiment()
	SHARED lever as TLever
	SHARED current_cycle
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	loop_start_time! = GetTime 			'SINGLE, should be enough
	last_time_write! = start_time!		'gets the last time a log has been made
	WHILE loop_start_time! + current_cycle.duration >= GetTime
		time_since_start = GetTime
		last_time_write! = TryWrite(last_time_write!)
		lever_status% = CheckLever
		if lever_status% == X THEN GOTO start_main_cycle 	'the evil step
	WEND
END SUB

SUB DoBasicExperiment()
	start_time! = GetTime
	last_time_write! = start_time!	'gets the last time a log has been made
    WHILE start_time! + t! >= GetTime
		time_since_start = GetTime
        last_time_write! = TryWrite(last_time_write!)
    WEND
END SUB

'----------------------------------------------------------------------------
'       REWARD SUBROUTINES
'----------------------------------------------------------------------------

SUB RewardEachLever()
	RewardEachNthLever(1)
END SUB

SUB RewardFirst()
	SHARED lever
	SHARED experiment
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	loop_start_time! = GetTime
	feeder_activated% = 0
	WHILE loop_start_time! + experiment.reward_duration >= GetTime AND feeder_activated = 0	'the mouse has only specified time to press the lever
		lever_status% = CheckLever
		'need to log it in the script
		IF lever_status% == X THEN 
			ActivateFeeder
			feeder_activated = 1
		ENDIF
		
	WEND
END SUB

SUB RewardEachNthLever(nth%)
	SHARED lever
	SHARED experiment
	
	'---
	'checks for lever press during the cycle if the experiment is evil
	'---
	number_of_presses% = 0
	loop_start_time! = GetTime
	WHILE loop_start_time! + experiment.reward_duration >= GetTime
		lever_status% = CheckLever
		'need to log it in the script
		IF lever_status% = X THEN number_of_presses% = number_of_presses% + 1
		if number_of_presses% MOD nth% THEN ActivateFeeder
	WEND
END SUB

'----------------------------------------------------------------------------
'       HELPER SUBROUTINES
'----------------------------------------------------------------------------
'Fills Cycles with the same values that are provided
SUB FillCycles(n_cycles%,c_dur!)
	SHARED cycles
	FOR i = 1 TO n_cycles% STEP 1
		cycles(i).duration=c_dur!
	NEXT i
END SUB

'----------------------------------------------------------------------------
'       FUNCTIONS
'----------------------------------------------------------------------------
FUNCTION GetTime
	GetTime = TIMER(.01)
END FUNCTION

FUNCTION MidnightCorrection(time!)
	IF time! > TIMER THEN MidnightCorrection! = time! - 86400 'takes care of experimenting over midnight - needs to be done in fucntion if necessary
	ELSE MidnightCorrection! = time!
	END IF
END FUNCTION

FUNCTION TryWrite(time!)
	IF time! - GetTime > write_interval THEN 		'if the time from the last log is larger than the logging frequency
		Write2File									'we write the log
		TryWrite = GetTime							'and send the the time of the log to the SUBROUTINE, so that it knows when it was made								
	ELSE TryWrite = time!							'otherwise we send the time back
	END IF
END FUNCTION

FUNCTION CheckLever	'returns 1, 3 or lever.status * 2
	SHARED lever AS TLever, feeder AS TFeeder
	SHARED time_since_start
  
	IF lever.address >= 0 THEN 'only if we actually have a lever
		parallel_input = INP(lever.address) 											'INPUT from parallel port on designated address
		lever.status = INT((paralel_input MOD 2 ^ lever.bit) / 2 ^ (lever.bit - 1))		'we turn paralel_input into I guess either 0 or 1
	END IF

	IF lever.last_status <> lever.status THEN		'if the new status is different from the old one
		'lever was released or pressed including bouncing
		lever.last_time_changed = time_since_start
	END IF
	
	CheckLever = lever.status * 2	'if it was 1, it turns to 2
	'if the time since last change is bigger than sensitivity of the lever, we take a look on what the value is
	
	IF time_since_start - lever.last_time_changed >= lever.sensitivity THEN 	'if there was a lever press, and it was before the time we set for sensitivity
		IF lever.status = 1 THEN 									'lever pressed?
			lever.last_time_changed = -1
			CheckLever = 3
		ELSE
			lever.last_time_changed = -1
			CheckLever = 1
		END IF
	END IF
	
	lever.last_status = lever.status 'resets the status
	
END FUNCTION

FUNCTION CheckFeeder
	SHARED feeder AS TFeeder, Cs() AS TCycle
	SHARED time_since_start

	CheckFeeder = feeder.status * 2		'What is this?
	IF feeder.status < 0 THEN			'this happens in the activate feeder
		'if we want to activate the feeder and the time of activation was set in the ActivateFeeder function
		IF time_since_start >= feeder.last_time_activated THEN
			Feeder.status = 1		'sets the status to activated
			'actually turns on the feeder or BEEPS in case the parallel port does not exist
			IF feeder.address >= 0 THEN OUT feeder.address, 2 ^ feeder.bit - 1 ELSE SOUND 1000, 2
			CheckFeeder = 1
		END IF
	'if we wanted to have the feeder activated, but it's already running for its duration, we turn it off
	ELSEIF feeder.status = 1 AND time_since_start - feeder.last_time_activated > feeder.duration THEN
		'this allows the feeder to be turned on
		feeder.status = 0
		'InitLever			'do I need it? don't think so
		IF feeder.address >= 0 THEN OUT feeder.address, 0 ELSE SOUND 500, 2		'turns the feeder off
		CheckFeeder = 3
	END IF
END FUNCTION

SUB ActivateFeeder				'only changes the status, CheckFeeder actually turns it on
	SHARED feeder AS TFeeder
	SHARED time_since_start
	'if the feeder is not running, we can turn it on
	IF feeder.status = 0 THEN
		feeder.last_time_activated = time_since_start + feeder.delay
		feeder.status = -1
	END IF
END SUB

SUB Write2File

  SHARED lever AS TLever, feeder AS TFeeder
  SHARED t
	
	'WHAT do we want to write down?
    PRINT #fid, USING fstr$; msg; t; tc; c + 1; h + 1; ct + 1;
    PRINT #fid, USING fstr$; Cs(ct).sch(Cs(ct).k);
    FOR j = LBOUND(Rs) TO UBOUND(Rs)
      PRINT #fid, USING fstr$; Rs(j).x; Rs(j).y;
    NEXT j
    PRINT #fid,
END SUB

SUB Write2Screen
  SHARED Lever AS TLever, Feeder AS TFeeder
  SHARED Cs() AS TCycle, Rs() AS TRectangle, Nps()
  SHARED t, tc, c, ct, h, fid, msg, fstr$, key$


  LOCATE 1, 1
  PRINT "t:"; INT(t / 100); INT(Lever.tRew / 100);
  PRINT ", #p:"; Lever.n; Lever.nRew; "#pct:";
  FOR k = LBOUND(Nps) TO UBOUND(Nps) - 1: PRINT Nps(k); : NEXT k
  PRINT ", #rew:"; Nps(UBOUND(Nps));
  'PRINT ", tc:"; FIX(tc / 100);
  PRINT ", c:"; c + 1; ", h:"; h + 1; "msg:"; USING "######"; msg


END SUB