DIM wait_t AS LONG
DIM start_t AS LONG
DECLARE SUB Wait (wait_time as LONG)
CLS

wait_t = 2
start_t = GetTime
WHILE start_t + wait_t >= GetTime
    PRINT (GetTime)
WEND
CLOSE

FUNCTION GetTime
GetTime = TIMER(.1)
END FUNCTION

