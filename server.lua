-- ══════════════════════════════════════════════════════════════
--  uv-books  ·  server.lua
--  Supports: QBCore, QBox (qbx_core), ox_inventory, jaksam_inventory, qb-inventory, qs-inventory
-- ══════════════════════════════════════════════════════════════

local MAX_PAGES = 20
local MAX_CHARS = 800

-- ── Framework & inventory detection ──────────────────────────

local Framework = nil   -- "qbx" | "qb"
local Inventory = nil   -- "ox"  | "qb" | "jaksam" | "qs"
local QBCore    = nil   -- only populated when running plain QBCore

CreateThread(function()

    -- Framework
    if GetResourceState("qbx_core") == "started" then
        Framework = "qbx"
        print("[uv-books] Framework detected: QBox (qbx_core)")
    elseif GetResourceState("qb-core") == "started" then
        Framework = "qb"
        QBCore = exports["qb-core"]:GetCoreObject()
        print("[uv-books] Framework detected: QBCore")
    else
        print("[uv-books] ^1WARNING: No supported framework found!^0")
    end

    -- Inventory
    if GetResourceState("jaksam_inventory") == "started" then
        Inventory = "jaksam"
        print("[uv-books] Inventory detected: jaksam_inventory (ox-compatible)")
    elseif GetResourceState("ox_inventory") == "started" then
        Inventory = "ox"
        print("[uv-books] Inventory detected: ox_inventory")
    elseif GetResourceState("qb-inventory") == "started" or
           GetResourceState("qs-inventory") == "started" or
           GetResourceState("ps-inventory") == "started" or
           GetResourceState("lj-inventory") == "started" then
        Inventory = "qb"
        print("[uv-books] Inventory detected: qb-style inventory")
    else
        Inventory = (Framework == "qbx") and "ox" or "qb"
        print("[uv-books] Inventory fallback: " .. Inventory)
    end

end)


-- ── Helper: get player object ────────────────────────────────

local function GetPlayer(src)
    if Framework == "qbx" then
        return exports.qbx_core:GetPlayer(src)
    elseif Framework == "qb" and QBCore then
        return QBCore.Functions.GetPlayer(src)
    end
    return nil
end


-- ── Helper: send notification ────────────────────────────────

local function Notify(src, msg, nType)
    if GetResourceState("ox_lib") == "started" then
        TriggerClientEvent("ox_lib:notify", src, {
            description = msg,
            type        = nType or "info",
        })
    elseif Framework == "qb" then
        TriggerClientEvent("QBCore:Notify", src, msg, nType)
    elseif Framework == "qbx" then
        exports.qbx_core:Notify(src, msg, nType)
    end
end


-- ── Helper: add item to player ───────────────────────────────

local function AddItem(src, item, count, metadata)
    if Inventory == "ox" then
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    elseif Inventory == "jaksam" then
        return exports.jaksam_inventory:AddItem(src, item, count, metadata)
    else
        local Player = GetPlayer(src)
        if Player then
            return Player.Functions.AddItem(item, count, false, metadata)
        end
    end
    return false
end


-- ══════════════════════════════════════════════════════════════
--  Create book event
-- ══════════════════════════════════════════════════════════════

RegisterNetEvent("uv-books:server:createBook", function(bookData)

    local src    = source
    local Player = GetPlayer(src)

    if not Player   then return end
    if not bookData then return end
    if not bookData.pages then return end

    if type(bookData.pages) ~= "table" then
        print("[uv-books] Exploit attempt (pages not table) from " .. src)
        return
    end

    if #bookData.pages > MAX_PAGES then
        print("[uv-books] Exploit attempt (too many pages) from " .. src)
        return
    end

    local hasContent = false

    for i = 0, MAX_PAGES - 1 do
        local page = bookData.pages[i] or bookData.pages[tostring(i)] or ""

        if type(page) ~= "string" then
            print("[uv-books] Invalid page type from " .. src)
            return
        end

        if string.len(page) > MAX_CHARS then
            print("[uv-books] Exploit attempt (page too long) from " .. src)
            return
        end

        if page ~= "" then hasContent = true end
    end

    if not hasContent then
        Notify(src, "You can't publish an empty book.", "error")
        return
    end

    local pageCount = 0
    for _, page in pairs(bookData.pages) do
        if type(page) == "string" and page ~= "" then
            pageCount = pageCount + 1
        end
    end

    local author = (bookData.signed and bookData.signature ~= "") and bookData.signature or "Unknown"

    local info = {
        title     = bookData.title or "Untitled Book",
        author    = author,
        pages     = pageCount,
        content   = bookData.pages,
        signed    = bookData.signed or false,
        signature = bookData.signature or "",
    }

    local success = AddItem(src, "book", 1, info)
    Notify(src, success and "Book published!" or "Failed to create book!", success and "success" or "error")

end)


-- ══════════════════════════════════════════════════════════════
--  Register "book" as a useable item
-- ══════════════════════════════════════════════════════════════

local function OnBookUsed(src, item)

    -- qb-inventory uses item.info, ox/jaksam use item.metadata
    -- check both as a fallback chain
    local info = (item and item.info) or (item and item.metadata) or {}

    if info.content and type(info.content) == "table" and next(info.content) ~= nil then
        TriggerClientEvent("uv-books:client:readBook", src, info)
    else
        TriggerClientEvent("uv-books:client:startWriting", src)
    end

end

-- ══════════════════════════════════════════════════════════════
--  📚 Useable item — registration varies by inventory
-- ══════════════════════════════════════════════════════════════

-- ox_inventory: uses a named export matching the item name.
-- The item in ox_inventory/data/items.lua needs:
--   consume = 0,
--   server = { export = 'uv-books.book' }
exports("book", function(event, item, inventory, slot, data)
    if event == "usingItem" then
        local src = inventory.id

        -- ox_inventory passes the item DEFINITION, not the slot instance.
        -- We need to fetch the actual slot to get the metadata.
        local slotData = exports.ox_inventory:GetSlot(src, slot)
        local info = (slotData and slotData.metadata) or {}

        if info.content and type(info.content) == "table" and next(info.content) ~= nil then
            TriggerClientEvent("uv-books:client:readBook", src, info)
        else
            TriggerClientEvent("uv-books:client:startWriting", src)
        end
    end
end)

-- For non-ox inventories, register inside a thread after detection
CreateThread(function()
    while Framework == nil do Wait(100) end

    if Inventory == "jaksam" then
        exports["jaksam_inventory"]:registerUsableItem("book", function(playerId, item)
            OnBookUsed(playerId, item)
        end)
        print("[uv-books] Registered useable item via jaksam_inventory")

    elseif Inventory == "qb" then
        if Framework == "qb" and QBCore then
            QBCore.Functions.CreateUseableItem("book", function(source, item)
                OnBookUsed(source, item)
            end)
            print("[uv-books] Registered useable item via QBCore")

        elseif Framework == "qbx" then
            local core = exports["qb-core"]:GetCoreObject()
            if core then
                core.Functions.CreateUseableItem("book", function(source, item)
                    OnBookUsed(source, item)
                end)
                print("[uv-books] Registered useable item via QBox bridge")
            end
        end

    else
        print("[uv-books] Using ox_inventory export for item registration")
    end
end)
