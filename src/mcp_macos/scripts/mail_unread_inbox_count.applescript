on run argv
    tell application "Mail"
        try
            set c to (count of (every message of inbox whose read status is false))
            return c as text
        on error errMsg
            return "0"
        end try
    end tell
end run

