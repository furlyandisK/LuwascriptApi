# LuwascriptApi
--[[
    NOTIFYAPI - FULL GUIDE
    ----------------------
    STEP 1: Load it at the top of your LocalScript (once):
            local Notify = loadstring(game:HttpGet("YOUR_RAW_URL"))()

    STEP 2: Call it anywhere:

        -- Message only
        Notify("Hello world!")

        -- Title + message
        Notify("Welcome", "Thanks for using the script!")

        -- With type
        Notify("Done", "Trade completed!", { Type = "success" })
        Notify("Careful", "Your health is low!", { Type = "warn" })
        Notify("Oops", "Something went wrong.", { Type = "error" })
        Notify("Info", "Server restarts in 5 min.", { Type = "info" })

        -- With custom duration (seconds)
        Notify("Quick", "This disappears fast.", { Duration = 2 })

        -- Both options together
        Notify("Update", "New version is out!", { Type = "success", Duration = 8 })

    TYPES:
        "info"    - Blue  - bell icon  (default)
        "success" - Green - check icon
        "warn"    - Orange - warning icon
        "error"   - Red   - X icon

    FEATURES:
        - Hover over a notification to pause its timer
        - Click x to close it immediately
        - Up to 6 notifications stacked at once
        - Long messages auto-wrap, card grows to fit
]]

