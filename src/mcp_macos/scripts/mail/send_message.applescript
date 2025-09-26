on run argv
    if (count of argv) < 3 then
        return "ERROR:Missing required parameters"
    end if

    set toValue to item 1 of argv
    set subjectValue to item 2 of argv
    set bodyValue to item 3 of argv

    set ccValue to ""
    set bccValue to ""
    set senderValue to ""

    if (count of argv) > 3 then
        set ccValue to item 4 of argv
    end if

    if (count of argv) > 4 then
        set bccValue to item 5 of argv
    end if

    if (count of argv) > 5 then
        set senderValue to item 6 of argv
    end if

    tell application "Mail"
        set newMessage to make new outgoing message with properties {visible:false, subject:subjectValue, content:bodyValue}

        my add_addresses(toValue, "to", newMessage)
        if ccValue is not "" then my add_addresses(ccValue, "cc", newMessage)
        if bccValue is not "" then my add_addresses(bccValue, "bcc", newMessage)

        if senderValue is not "" then
            try
                set sender of newMessage to senderValue
            end try
        end if

        send newMessage
    end tell

    return "OK"
end run

on add_addresses(addressText, addressType, msg)
    set addresses to my split_addresses(addressText)
    if (count of addresses) is 0 then return

    tell application "Mail"
        repeat with addr in addresses
            set cleanAddress to addr as text
            if addressType is "to" then
                make new to recipient at end of to recipients of msg with properties {address:cleanAddress}
            else if addressType is "cc" then
                make new cc recipient at end of cc recipients of msg with properties {address:cleanAddress}
            else if addressType is "bcc" then
                make new bcc recipient at end of bcc recipients of msg with properties {address:cleanAddress}
            end if
        end repeat
    end tell
end add_addresses

on split_addresses(addressText)
    set normalizedText to my replace_text(addressText, ";", ",")
    set normalizedText to my replace_text(normalizedText, return, ",")
    set normalizedText to my replace_text(normalizedText, linefeed, ",")

    set prevDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to ","
    set rawItems to every text item of normalizedText
    set AppleScript's text item delimiters to prevDelims

    set results to {}
    repeat with itemText in rawItems
        set trimmed to my trim_text(itemText)
        if trimmed is not "" then
            set end of results to trimmed
        end if
    end repeat

    return results
end split_addresses

on trim_text(theText)
    set textValue to theText as text
    set spaceChars to {space, tab, return, linefeed}

    repeat while (textValue is not "") and my begins_with_any(textValue, spaceChars)
        if (length of textValue) > 1 then
            set textValue to text 2 thru -1 of textValue
        else
            set textValue to ""
        end if
    end repeat

    repeat while (textValue is not "") and my ends_with_any(textValue, spaceChars)
        if (length of textValue) > 1 then
            set textValue to text 1 thru -2 of textValue
        else
            set textValue to ""
        end if
    end repeat

    return textValue
end trim_text

on begins_with_any(theText, charsList)
    if (length of theText) = 0 then return false
    set firstChar to character 1 of theText
    repeat with ch in charsList
        if firstChar is ch then return true
    end repeat
    return false
end begins_with_any

on ends_with_any(theText, charsList)
    if (length of theText) = 0 then return false
    set lastChar to character -1 of theText
    repeat with ch in charsList
        if lastChar is ch then return true
    end repeat
    return false
end ends_with_any

on replace_text(theText, searchString, replacementString)
    if searchString is "" then return theText

    set prevDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to searchString
    set theItems to every text item of theText
    set AppleScript's text item delimiters to replacementString
    set theText to theItems as text
    set AppleScript's text item delimiters to prevDelims
    return theText
end replace_text
