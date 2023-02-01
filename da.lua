-- Import completion and quill
package.path = "/DavinCC/?.lua;" .. package.path
local completion = require("lib/completion")
local quill = require("lib/quill")
local sketch = require("lib/sketch")

-- User input for risk and personality
local personality, risk, cutoff, img, magnitude = ...
local isImg
local tempImg
personality = personality or "standard"
personality = string.lower(personality)

-- Input conversion
if risk then
    risk = tonumber(risk)
end
if img then
    img = string.lower(img)
else
    img = "false"
end
if magnitude then
    magnitude = string.lower(magnitude)
else
    magnitude = "sm"
end

-- Magnitude conversion, defaults to small
local size
if magnitude == "sm" then
    size = "256x256"
elseif magnitude == "md" then
    size = "512x512"
elseif magnitude == "lg" then
    size = "1024x1024"
end

-- Input testing for non-number
if type(risk) ~= "number" then
    risk = 0
end
if type(cutoff) ~= "number" then
    cutoff = 5
end

-- Input testing for out of range
if risk < 0 then
    risk = 0
elseif risk > 1 then
    risk = 1
end
if cutoff < 0 then
    cutoff = 0
elseif cutoff > 42 then
    cutoff = 42
end

-- Translating string to boolean
if img == "true" or img == "t" or img == 1 then
    img = "true"
    isImg = true
elseif img == "false" or img == "f" or img == 0 then
    img = "false"
    isImg = false
end

-- Conversation variables
local prompt
local cont
local reply
local number = 1


-- Quick and flavourless request
if personality == "none" then
    -- Print arguments
    print("Personality: \"" .. personality .. "\" Risk: " .. risk .. " Img: " .. img .. "\n")

    -- Read input as red
    term.setTextColour(colours.red)
    prompt = read()
    print("\n")

    -- Complete prompt (user input), risk (0-1), token limit
    cont = completion.request(prompt, risk, 1000)

    -- Store truncated reply
    reply = cont["choices"][1]["text"]
    reply = quill.truncate(reply)
    quill.scribe("/DavinCC/out.txt", "w", reply)

    -- Print output as orange
    term.setTextColour(colours.orange)
    print(reply .. "\n")

    -- Generating image if true
    if isImg then
        sleep(1)
        sketch.generate(reply, number, size)
        print("I made an image...\n")
    end


-- Otherwise, conduct conversation with chosen personality
else
    -- Printing chosen arguments
    print("Personality: \"" .. personality .. "\" Risk: " .. risk .. " Cutoff: " .. cutoff .. " Img: " .. img)

    -- Select greeting file based on personality
    personality = quill.firstUpper(personality)
    local greetFile = "/DavinCC/greetings/greet" .. personality .. ".txt"

    -- Initiate a conversation
    completion.greet(greetFile)
    quill.scribe(greetFile, "r")

    -- Start with reply to "hello" prompt
    term.setTextColour(colours.orange)
    cont = completion.continue("hello", risk, 200, cutoff)
    print(cont["choices"][1]["text"])

    -- Continue the conversation indefinately
    while true do
        -- Read input as red
        print("\n")
        term.setTextColour(colours.red)
        prompt = read()
        print("\n")

        -- Continue with prompt (user input), risk (0-1), token limit (max per reply), cutoff (how many replies to remember)
        cont = completion.continue(prompt, risk, 200, cutoff)

        -- Store truncated reply
        reply = cont["choices"][1]["text"]
        reply = quill.truncate(reply)
        quill.scribe("/DavinCC/data/out.txt", "w", reply)

        -- Print output as orange
        term.setTextColour(colours.orange)
        print(reply)

        -- Allowing mid-convo images
        tempImg = false
        if string.sub(prompt, #prompt - 2) == "IMG" then
            tempImg = true
        end

        -- Generating image if true
        if isImg or tempImg then
            sleep(1)
            sketch.generate(reply, number, size)
            print("I made an image...\n")
        end
    end
end