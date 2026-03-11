local QBCore = exports['qb-core']:GetCoreObject()

local MAX_PAGES = 20
local MAX_CHARS = 800
local isWriting = false

-- ── Open the book writer NUI ──
RegisterNetEvent("uv-books:client:startWriting", function()
    print("[uv-books] startWriting. isWriting=" .. tostring(isWriting))
    if isWriting then return end
    isWriting = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "openBookWriter" })

    -- Re-assert focus a few times on open to beat other resources,
    -- stops as soon as isWriting goes false
    Citizen.CreateThread(function()
        local ticks = 0
        while isWriting and ticks < 10 do
            Citizen.Wait(500)
            if isWriting then SetNuiFocus(true, true) end
            ticks = ticks + 1
        end
    end)
end)

-- ── Open the book reader NUI ──
RegisterNetEvent("uv-books:client:readBook", function(info, page)
    if not info then
        QBCore.Functions.Notify("This book seems corrupted.", "error")
        return
    end
    if isWriting then return end
    isWriting = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openBookReader",
        info   = info,
        page   = page or 1
    })

    Citizen.CreateThread(function()
        local ticks = 0
        while isWriting and ticks < 10 do
            Citizen.Wait(500)
            if isWriting then SetNuiFocus(true, true) end
            ticks = ticks + 1
        end
    end)
end)


-- ── ESC detection ──
local lastEsc = 0
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isWriting then
            local now = GetGameTimer()
            if (now - lastEsc) > 600 then
                if IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then
                    lastEsc = now
                    print("[uv-books] ESC detected")
                    SendNUIMessage({ action = "escPressed" })
                end
            end
        end
    end
end)


-- ── NUI Callbacks ──

RegisterNUICallback("draftSaved", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("bookPublished", function(data, cb)
    print("[uv-books] bookPublished received")
    cb("ok")

    if not data then return end

    local pages = {}
    for i = 1, MAX_PAGES do
        local raw = data.pages[i] or data.pages[tostring(i)] or data.pages[i - 1] or ""
        if type(raw) ~= "string" then raw = "" end
        if string.len(raw) > MAX_CHARS then raw = string.sub(raw, 1, MAX_CHARS) end
        pages[i] = raw
    end

    local bookDraft = {
        title     = type(data.title) == "string" and data.title or "Untitled Book",
        pages     = pages,
        signed    = data.signed == true,
        signature = type(data.signature) == "string" and data.signature or ""
    }

    print("[uv-books] Creating book: " .. bookDraft.title)
    TriggerServerEvent("uv-books:server:createBook", bookDraft)

    isWriting = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback("bookClosed", function(data, cb)
    print("[uv-books] bookClosed received")
    isWriting = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    cb("ok")
end)


-- ── Useable item (server handles routing, but keep client events for compat) ──
RegisterNetEvent("uv-books:client:nextPage", function(data)
    -- no-op: reader is now handled in NUI
end)

RegisterNetEvent("uv-books:client:prevPage", function(data)
    -- no-op: reader is now handled in NUI
end)
