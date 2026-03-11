local QBCore = exports['qb-core']:GetCoreObject()

local MAX_PAGES = 20
local MAX_CHARS = 800


RegisterNetEvent("uv-books:server:createBook", function(bookData)

    local src    = source
    local Player = QBCore.Functions.GetPlayer(src)

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
        TriggerClientEvent('QBCore:Notify', src, "You can't publish an empty book.", "error")
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

    Player.Functions.AddItem("book", 1, false, info)
    TriggerClientEvent('QBCore:Notify', src, "Book published!", "success")

end)


-- 📚 Useable item
QBCore.Functions.CreateUseableItem("book", function(source, item)

    local info = item.info or {}

    if info.content and next(info.content) ~= nil then
        TriggerClientEvent("uv-books:client:readBook", source, info)
    else
        TriggerClientEvent("uv-books:client:startWriting", source)
    end

end)
