on run argv
    set daysAhead to 7
    set maxCount to 20
    if (count of argv) >= 1 then
        try
            set daysAhead to (item 1 of argv) as integer
        end try
    end if
    if (count of argv) >= 2 then
        try
            set maxCount to (item 2 of argv) as integer
        end try
    end if
    set t0 to (current date)
    set t1 to t0 + (daysAhead * days)
    set AppleScript's text item delimiters to linefeed
    set outLines to {}
    set n to 0
    tell application "Calendar"
        repeat with cal in calendars
            set evs to (every event of cal whose start date >= t0 and start date <= t1)
            repeat with e in evs
                set startText to (start date of e as text)
                set endText to (end date of e as text)
                set sumText to (summary of e as text)
                set calName to (name of cal as text)
                set end of outLines to startText & tab & endText & tab & sumText & tab & calName
                set n to n + 1
                if n >= maxCount then exit repeat
            end repeat
            if n >= maxCount then exit repeat
        end repeat
    end tell
    return outLines as text
end run
