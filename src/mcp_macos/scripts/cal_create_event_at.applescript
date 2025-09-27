on run argv
    if (count of argv) < 8 then return "ERROR: need title, year, month, day, hour, minute, second, duration_minutes [calendar_name]"
    set t to item 1 of argv
    set y to (item 2 of argv) as integer
    set mo to (item 3 of argv) as integer
    set d to (item 4 of argv) as integer
    set hr to (item 5 of argv) as integer
    set mi to (item 6 of argv) as integer
    set sc to (item 7 of argv) as integer
    set durationMins to (item 8 of argv) as integer
    set calName to ""
    if (count of argv) >= 9 then set calName to item 9 of argv

    set monthsList to {January, February, March, April, May, June, July, August, September, October, November, December}

    set sd to (current date)
    set year of sd to y
    set month of sd to (item mo of monthsList)
    set day of sd to d
    set time of sd to (hr * hours) + (mi * minutes) + sc

    set ed to sd + (durationMins * minutes)

    tell application "Calendar"
        set theCal to first calendar
        if calName is not "" then set theCal to first calendar whose name is calName
        make new event at end of events of theCal with properties {summary:t, start date:sd, end date:ed}
    end tell
    return "OK"
end run
