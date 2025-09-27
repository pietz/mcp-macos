on run argv
    if (count of argv) < 2 then return "ERROR: need id and action"
    set targetId to item 1 of argv
    set actionName to item 2 of argv
    set normalizedAction to my normalize_action(actionName)
    if normalizedAction is "" then return "ERROR: unsupported action"

    tell application "Mail"
        set targetMessage to my find_message_by_id(targetId)
        if targetMessage is missing value then return "ERROR: message not found"

        if normalizedAction is "mark_read" then
            set read status of targetMessage to true
        else if normalizedAction is "mark_unread" then
            set read status of targetMessage to false
        else if normalizedAction is "archive" then
            if my archive_message(targetMessage) is false then return "ERROR: archive mailbox not available"
        else
            return "ERROR: unsupported action"
        end if
    end tell

    return "OK"
end run

on normalize_action(actionName)
    if actionName is missing value then return ""
    set actionText to actionName as text
    ignoring case
        if actionText is "mark_read" or actionText is "read" then return "mark_read"
        if actionText is "mark_unread" or actionText is "unread" then return "mark_unread"
        if actionText is "archive" then return "archive"
    end ignoring
    return ""
end normalize_action

on archive_message(targetMessage)
    tell application "Mail"
        try
            set msgMailbox to mailbox of targetMessage
            set msgAccount to account of msgMailbox
            set archiveBox to missing value
            try
                set archiveBox to mailbox "Archive" of msgAccount
            end try
            if archiveBox is missing value then
                try
                    set archiveBox to mailbox "Archive"
                end try
            end if
            if archiveBox is missing value then return false
            if mailbox of targetMessage is archiveBox then return true
            move targetMessage to archiveBox
            return true
        on error
            return false
        end try
    end tell
end archive_message

on find_message_by_id(targetId)
    if targetId is missing value then return missing value
    set targetText to targetId as text
    if targetText is "" then return missing value
    tell application "Mail"
        try
            repeat with acc in accounts
                repeat with mb in mailboxes of acc
                    try
                        set msgs to (every message of mb whose id is (targetText as integer))
                        if (count of msgs) > 0 then return item 1 of msgs
                    end try
                end repeat
            end repeat
        end try
    end tell
    return missing value
end find_message_by_id
