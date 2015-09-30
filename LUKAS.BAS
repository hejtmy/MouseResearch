DECLARE SUB string2words (s$, words$())
DECLARE SUB ActivateFeeder ()
DECLARE FUNCTION CheckCycle& ()
DECLARE FUNCTION CheckFeeder& ()
DECLARE FUNCTION CheckLever& ()
DECLARE FUNCTION CheckUserAction& ()
DECLARE SUB DrawRectangle (R AS ANY)
DECLARE SUB DrawRectangles (forwards&)
DECLARE SUB InitCycle ()
DECLARE SUB InitLever ()
DECLARE FUNCTION InitRectangles& ()
DECLARE SUB MoveRectangle (R AS ANY)
DECLARE SUB MoveRectangles (forwards&)
DECLARE SUB ReadParamFile ()
DECLARE SUB RedrawRectangle (R AS ANY, x&, y&)
DECLARE SUB Write2File ()
DECLARE SUB Write2Screen ()

DEFLNG A-Z
'----------------------------------------------------------------------------
'       Define user types
'----------------------------------------------------------------------------
TYPE TCycle
  d AS LONG             'cycle duration (10msec)
  sch(1) AS LONG        'reinforcement schedule:
                        '  0..no reward, 1..FR or VR, 2..FI or VI
  x(1) AS LONG
  y(1) AS LONG          'VR[x(k),y(k)] or VI[x(k),y(k)]
                        '  x,y..min resp. max #responses/interval duration to get reward
                        '  Define FR[x(k)] and FI[(x(k))] by setting x(k)=y(k)
  k AS LONG             'k=0..reinforcement schedule until the 1st reward in the cycle
                        'k=1..reinforcement schedule for the rest of the cycle
END TYPE

TYPE TLever
  n AS LONG             'number of the last response
  t AS LONG             'time of the last response
  nRew AS LONG          'number of the next rewarded response
  tRew AS LONG          'min time of the next rewarded response
  tPom AS LONG          '
  status AS LONG
  status0 AS LONG
  sensitivity AS LONG   '(10msec)
  address AS LONG
  bit AS LONG
END TYPE

TYPE TFeeder
  d AS LONG             'duration (10msec) of feeder activation
  delay AS LONG         'activation delay (10msec)
  t0 AS LONG            'time (10msec) of the last activation
  status AS LONG        '0..no activated, -1 or 1..activated
  address AS LONG
  bit AS LONG
END TYPE

TYPE TRectangle
  x AS LONG
  y AS LONG
  w AS LONG
  h AS LONG
  color AS LONG
  visible AS LONG
  x0 AS LONG
  y0 AS LONG
  coefX AS SINGLE
  coefY AS SINGLE
END TYPE

TYPE TTrajectory
  x0 AS LONG
  y0 AS LONG
  x1 AS LONG
  y1 AS LONG
  visible AS LONG
END TYPE

'----------------------------------------------------------------------------
'       Declare variables
'----------------------------------------------------------------------------
DIM t           'time ellapsed since the beginning of the session (10msec)
DIM t0          'beginning of the session (10msec)
DIM tc          'time ellapsed since the beginning of the current cycle
DIM tc0         'beginning of the current cycle (10msec)

DIM j           'counter
DIM c           'current cycle
DIM nc          'number of cycles-1
DIM h           'current hypercycle
DIM nh          'number of hypercycles-1
DIM ct          'current cycle type
DIM nct         'number of cycle types

DIM fid         'output file identifier
DIM fstr$       'output file format string
DIM nr          'number of rectangles
DIM msg         '0<..write to file, 0..don't write

DIM Lever AS TLever
DIM Feeder AS TFeeder
DIM HC(nc)
DIM Cs(nct) AS TCycle
DIM Rs(nr) AS TRectangle
DIM Ts(nr, nct) AS TTrajectory

DIM Nps(nct)
DIM Cmd$(j)     'command line

'----------------------------------------------------------------------------
'       Process command line and init some variables
'----------------------------------------------------------------------------
IF LEN(COMMAND$) = 0 THEN
  PRINT
  PRINT "   monie3.exe paramFile"
  PRINT "     to use keyboard for input and beep for output"
  PRINT
  PRINT "   monie3.exe paramFile leverAddress leverBit feederAddress feederBit"
  PRINT "     to read a lever and to control a feeder"
  PRINT
  PRINT "     Right/Left computer: leverAddress: &H300 / &H379"
  PRINT "                              leverBit:     1 / 5 "
  PRINT "                         feederAddress: &H302 / &H378"
  PRINT "                             feederBit:     1 / 2"
  PRINT
  END
END IF
string2words COMMAND$, Cmd$()
IF UBOUND(Cmd$) >= 4 THEN
  Lever.address = VAL(Cmd$(1))
  Lever.bit = VAL(Cmd$(2))
  Feeder.address = VAL(Cmd$(3))
  Feeder.bit = VAL(Cmd$(4))
ELSE
  Lever.address = -1
  Feeder.address = -1
END IF

'----------------------------------------------------------------------------
'       INPUTING STARTUP VARIABLES
'----------------------------------------------------------------------------
CLS
INPUT "What is your name: ", urname$
PRINT urname$; " is your name."

PRINT "Is this information correct?"
INPUT "Y/N", bool$ 
IF UCASE$(bool$) = "N" THEN END 'if N we exit the file

'----------------------------------------------------------------------------
'       Open output file
'----------------------------------------------------------------------------
DO
  INPUT ; "Type output file name and then press Enter: ", outfile$
  IF LEN(outfile$) = 0 THEN outfile$ = "cv3.txt": EXIT DO
  pomfile$ = DIR$(outfile$)
  IF LEN(pomfile$) > 0 THEN
    PRINT outfile$; " exists. Overwrite? (A..yes, N..no): ";
    IF UCASE$(INPUT$(1)) = "A" THEN EXIT DO
  ELSE
    EXIT DO
  END IF
LOOP

fid = FREEFILE
OPEN outfile$ FOR OUTPUT AS #fid

'----------------------------------------------------------------------------
'       Init variables
'----------------------------------------------------------------------------
SCREEN 12

'------------
' Change this to better seed

RANDOMIZE (TIMER) 'only sets the seed - not a best thing for reproducibility!!!!

IF Feeder.address = &H302 THEN OUT &H303, &H92

fstr$ = "########"

'------------
' Change this
ReadParamFile

Lever.n = 0
Lever.t = 0

Feeder.t0 = -Feeder.d - 1
Feeder.status = 0

REDIM Nps(nct + 1)

j = -1
t = 0
tc = Cs(0).d + 1
tc0 = 0

'----------------------------------------------------------------------------
'       Main loop
'----------------------------------------------------------------------------

msg = CheckCycle * 100
Write2File

t0 = TIMER * 100 'sets the beginning timer 

'---loops while current hypercycle < number of hypercycles and the key is not Escape
DO
  t = TIMER * 100 - t0  'decrementing the TIMER by the beginning of the session time t0
  tc = t - tc0

  'this not only sets msg, but checks if the cycle is finished, 
  'increments "j" and initiates a new cycle (not a best practice to do in a middle of a loop)
  msg = CheckCycle * 100 
  MoveRectangles 0
  
  msg = CheckUserAction * 1000 + msg 
  msg = CheckLever + msg
  msg = CheckFeeder * 10 + msg
  IF msg MOD 10 = 3 THEN Nps(ct) = Nps(ct) + 1
  IF INT((msg MOD 100) / 10) = 1 THEN Nps(nct + 1) = Nps(nct + 1) + 1

  Write2Screen
  Write2File

  msg = 0
LOOP WHILE h <= nh AND key$ <> CHR$(27)

'----------------------------------------------------------------------------
'       End
'----------------------------------------------------------------------------
DO
  key$ = INKEY$
'Waits for escape
LOOP UNTIL key$ = CHR$(27)

CLOSE #fid
OUT Feeder.address, 0
'-------------
'WHAT THIS DOES
'
'
SUB ActivateFeeder
  SHARED Feeder AS TFeeder
  SHARED t

  IF Feeder.status = 0 THEN
    Feeder.t0 = t + Feeder.delay
    Feeder.status = -1
  END IF

END SUB

'-------------
'WHAT THIS DOES
'if the time from the beginning of the current cycle is larger than the duration of current cycle
'we set the counter to j+1 and InitCycle, then set return to 1
FUNCTION CheckCycle
  SHARED Cs() AS TCycle
  SHARED t, tc, j, ct

  CheckCycle = 0
  IF tc > Cs(ct).d THEN
    j = j + 1: InitCycle
    CheckCycle = 1
  END IF
END FUNCTION


'-------------
'WHAT THIS DOES
'
'
FUNCTION CheckFeeder
  SHARED Feeder AS TFeeder, Cs() AS TCycle
  SHARED t

  CheckFeeder = Feeder.status * 2
  IF Feeder.status <= 0 THEN
    IF t >= Feeder.t0 AND t - Feeder.t0 <= Feeder.d THEN
      Feeder.status = 1
      IF Feeder.address >= 0 THEN OUT Feeder.address, 2 ^ Feeder.bit - 1 ELSE SOUND 1000, 2
      CheckFeeder = 1
    END IF
  ELSEIF Feeder.status = 1 AND t - Feeder.t0 > Feeder.d THEN
      Feeder.status = 0
      Cs(ct).k = 1
      InitLever
      IF Feeder.address >= 0 THEN OUT Feeder.address, 0 ELSE SOUND 500, 2
      CheckFeeder = 3
  END IF

END FUNCTION


'-------------
'WHAT THIS DOES
'
'
FUNCTION CheckLever
  SHARED Lever AS TLever, Feeder AS TFeeder
  SHARED t
  
  IF Lever.address >= 0 THEN
    u = INP(Lever.address)
    Lever.status = INT((u MOD 2 ^ Lever.bit) / 2 ^ (Lever.bit - 1))
  END IF

  IF Lever.status0 <> Lever.status THEN
    'lever was released or pressed including bouncing
    Lever.tPom = t
  END IF

  CheckLever = Lever.status * 2

  IF Lever.tPom > 0 AND t - Lever.tPom >= Lever.sensitivity THEN
    IF Lever.status = 1 THEN 'lever released
      Lever.n = Lever.n + 1: Lever.t = t: Lever.tPom = -1
      CheckLever = 3
    ELSE
      Lever.tPom = -1
      CheckLever = 1
    END IF
  END IF

  Lever.status0 = Lever.status

  IF Lever.nRew >= 0 AND Lever.n >= Lever.nRew THEN
    Lever.nRew = -1: Lever.tRew = -1
    ActivateFeeder
  ELSEIF Lever.tRew >= 0 AND Lever.t >= Lever.tRew THEN
    Lever.nRew = -1: Lever.tRew = -1
    ActivateFeeder
  END IF

END FUNCTION


'-------------
'WHAT THIS DOES
'
'
FUNCTION CheckUserAction
  SHARED Lever AS TLever
  SHARED j, key$

  key$ = INKEY$
  SELECT CASE UCASE$(key$)
    CASE "1": Lever.status = 1
    CASE "2": Lever.status = 0
    CASE "N": j = j + 1: InitCycle
              CheckUserAction = ASC(UCASE$(key$))
    CASE "P": j = j - 1:
              IF j < 0 THEN j = 0
              InitCycle
              CheckUserAction = ASC(UCASE$(key$))
    CASE CHR$(13): ActivateFeeder
                   CheckUserAction = ASC(UCASE$(key$))
    CASE CHR$(27): CheckUserAction = ASC(UCASE$(key$))
    CASE ELSE: CheckUserAction = 0
  END SELECT


END FUNCTION

'-------------
'WHAT THIS DOES
'
'
SUB DrawRectangle (R AS TRectangle)
  FOR j = 1 TO R.w
    LINE (R.x + j - 1, R.y)-(R.x + j - 1, R.y + R.h - 1), R.color * R.visible
  NEXT j
END SUB

'-------------
'WHAT THIS DOES
'
'
SUB DrawRectangles (forwards)
  SHARED Rs() AS TRectangle

  IF forwards = 1 THEN
    FOR j = LBOUND(Rs) TO UBOUND(Rs)
      DrawRectangle Rs(j)
    NEXT j
  ELSE
    FOR j = UBOUND(Rs) TO LBOUND(Rs) STEP -1
      DrawRectangle Rs(j)
    NEXT j
  END IF

END SUB

'-------------
'WHAT THIS DOES
'
'
SUB InitCycle

  SHARED HC(), Cs() AS TCycle, Rs() AS TRectangle, Ts() AS TTrajectory
  SHARED Lever AS TLever
  SHARED t, tc, tc0, j, c, ct, h, nc

  c = j MOD (nc + 1)
  h = FIX(j / (nc + 1))
  ct = HC(c)
  tc0 = t
  tc = 0
  Cs(ct).k = 0

  InitLever

  pom = InitRectangles
  IF pom THEN DrawRectangles 0

END SUB

'-------------
'WHAT THIS DOES
'
'
SUB InitLever
  SHARED Lever AS TLever
  SHARED Cs() AS TCycle
  SHARED ct

  Lever.nRew = -1: Lever.tRew = -1 'no reward

  k = Cs(ct).k
  SELECT CASE Cs(ct).sch(k)
    CASE 1: pom = Cs(ct).y(k) - Cs(ct).x(k)       'FR or VR
            pom = INT(RND * (pom + 1)) + Cs(ct).x(k)
            Lever.nRew = Lever.n + pom
    CASE 2: pom = Cs(ct).y(k) - Cs(ct).x(k)       'FI or VI
            pom = INT(RND * (pom + 1)) + Cs(ct).x(k)
            Lever.tRew = Lever.t + pom
  END SELECT

END SUB

'-------------
'WHAT THIS DOES
'
'
FUNCTION InitRectangles
  SHARED Cs() AS TCycle, Rs() AS TRectangle, Ts() AS TTrajectory
  SHARED ct

  FOR j = LBOUND(Rs) TO UBOUND(Rs)
    RedrawRectangle Rs(j), Ts(j, ct).x0, Ts(j, ct).y0
  NEXT j

  pom = 0
  FOR j = LBOUND(Rs) TO UBOUND(Rs)
    pom = pom OR ABS(Rs(j).visible <> Ts(j, ct).visible)
    Rs(j).x0 = Ts(j, ct).x0
    Rs(j).y0 = Ts(j, ct).y0
    Rs(j).visible = Ts(j, ct).visible
    Rs(j).coefX = (Ts(j, ct).x1 - Ts(j, ct).x0) / Cs(ct).d
    Rs(j).coefY = (Ts(j, ct).y1 - Ts(j, ct).y0) / Cs(ct).d
  NEXT j

  InitRectangles = pom

END FUNCTION

'-------------
'WHAT THIS DOES
'
'
SUB MoveRectangle (R AS TRectangle)

  SHARED tc

  x = R.x0 + R.coefX * tc
  y = R.y0 + R.coefY * tc

  RedrawRectangle R, x, y

END SUB

'-------------
'WHAT THIS DOES
'
'
SUB MoveRectangles (forwards)
  SHARED Rs() AS TRectangle

  IF forwards = 1 THEN
    FOR j = LBOUND(Rs) TO UBOUND(Rs)
      MoveRectangle Rs(j)
    NEXT j
  ELSE
    FOR j = UBOUND(Rs) TO LBOUND(Rs) STEP -1
      MoveRectangle Rs(j)
    NEXT j
  END IF

END SUB

'-------------
'WHAT THIS DOES
'
'

SUB RedrawRectangle (R AS TRectangle, x, y)

  FOR j = R.x TO x - 1
    LINE (j, R.y)-(j, R.y + R.h - 1), 0
    LINE (j + R.w - 1, R.y)-(j + R.w - 1, R.y + R.h - 1), R.color * R.visible
  NEXT j

  FOR j = R.x TO x + 1 STEP -1
    LINE (j + R.w - 1, R.y)-(j + R.w - 1, R.y + R.h - 1), 0
    LINE (j, R.y)-(j, R.y + R.h - 1), R.color * R.visible
  NEXT j

  R.x = x

  FOR j = R.y TO y - 1
    LINE (R.x, j)-(R.x + R.w - 1, j), 0
    LINE (R.x, j + R.h - 1)-(R.x + R.w - 1, j + R.h - 1), R.color * R.visible
  NEXT j

  FOR j = R.y TO y + 1 STEP -1
    LINE (R.x, j + R.h - 1)-(R.x + R.w - 1, j + R.h - 1), 0
    LINE (R.x, j)-(R.x + R.w - 1, j), R.color * R.visible
  NEXT j

  R.y = y


END SUB

'-------------
'WHAT THIS DOES
'
'
SUB string2words (s$, words$())

  s$ = s$ + " "
  s$ = LTRIM$(s$)
  k = 0
  WHILE LEN(s$) > 0
    n = INSTR(s$, " ")
    REDIM PRESERVE words$(k)
    words$(k) = LEFT$(s$, n - 1)
    s$ = MID$(s$, n, LEN(s$))
    s$ = LTRIM$(s$)
    k = k + 1
  WEND

END SUB

'-------------
'WHAT THIS DOES
'
'
SUB Write2File

  SHARED Lever AS TLever, Feeder AS TFeeder
  SHARED Cs() AS TCycle, Rs() AS TRectangle
  SHARED t, tc, c, ct, h, fid, msg, fstr$, key$

  pom = msg >= 1000 'if user pressed a key
  FOR k = 1 TO 3
    pom2 = INT((msg MOD (10 ^ k)) / (10 ^ (k - 1)))
    pom = pom OR (ABS(pom2 <> 2) AND ABS(pom2 <> 0))
  NEXT k

  IF pom THEN
    PRINT #fid, USING fstr$; msg; t; tc; c + 1; h + 1; ct + 1;
    PRINT #fid, USING fstr$; Cs(ct).sch(Cs(ct).k);
    FOR j = LBOUND(Rs) TO UBOUND(Rs)
      PRINT #fid, USING fstr$; Rs(j).x; Rs(j).y;
    NEXT j
    PRINT #fid,
  END IF
END SUB

'-------------
'WHAT THIS DOES
'
'
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

