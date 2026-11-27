-- FORMULA Profile & Stats toggle integration
-- Generated from BRPlayerCharacterBase(7).lua. Existing unrelated sections retained.
-- Every FORMULA_FEATURES entry is reset to false on load; the tab enables features explicitly.

--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources
-- ==================== Weapon + Attachment Unified Refresh System (Fully Keep Original Logic) ====================

-- Your original global variables (all kept)
-- ============ Star Power Optimization: Global Cache ============
-- Star Clean old cache, prevent leftover contamination
_G.__baseWeaponIDCache = nil
_G.Mytimer_ticker = _G.Mytimer_ticker or require("common.time_ticker")

_G.__perf = _G.__perf or {
    partsInited      = {},   -- [avatarid] = true
    attachStamp      = {},   -- [key] = lastTime
    petStamp         = 0,
    petId            = 0,
    cfgReadAt        = 0,
    killReadAt       = 0,
    playerRefreshStamp = 0,
    dataMgrScanAt    = 0,
}--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources

_G.equip_weapon_avatar = nil
_G.g_parts = nil
_G.g_parts_subtype = nil
_G.lastAppliedSkin = {}
_G.lastAppliedAttachments = {}
_G.lastAppliedAttachmentFp = {}
_G.skinDownloadCache = {}
_G.skinHasAttachmentSkinsCache = {}

--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources

local possiblePaths = {
    "/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h",     
    "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h",   
    "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h",
    "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h",
    "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h",
}

-- Star Star Star New: Get Current Game Package Name (Multi-Path Fallback, Prefer Real Package Name) Star Star Star
function _G.GetCurrentGamePackage()
    local ok, pkg

    ok, pkg = pcall(function() return slua_GameFrontendHUD:GetPackageName() end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function() return Client.GetPackageName() end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        local GPS = import("GameplayStatics")
        return GPS.GetPackageName()
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        local act = slua_GameFrontendHUD:GetActivity()
        return act and act:getPackageName()
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    ok, pkg = pcall(function()
        return slua_GameFrontendHUD.PackageName or slua_GameFrontendHUD.packageName
    end)
    if ok and pkg and pkg ~= "" then return pkg end

    return nil
end

-- Star Star Star New: Get wumingking.h Path by Current Package Name, Return nil If Not Found Star Star Star
function _G.GetCurrentWumingPath()
    local pkg = _G.GetCurrentGamePackage and _G.GetCurrentGamePackage()
    if not pkg then return nil end
    local p = "/storage/emulated/0/Android/obb/" .. pkg .. "/wumingking.h"
    -- "a" mode: If the directory exists, create/open succeeds, if the directory does not exist, it fails
    local ok, f = pcall(io.open, p, "a")
    if ok and f then
        f:close()
        return p
    end
    return nil
end

local lastConfig = {}
_G.lastConfig = lastConfig

-- ==================== Global Variables Initialization ====================
_G.HairSkin = _G.HairSkin or 0
_G.SuitSkin = _G.SuitSkin or 0
_G.HeadShapeSkin = _G.HeadShapeSkin or 0

-- ==================== FORMULA Profile / Stats Feature Switches ====================
-- These switches are intentionally reset on every script load. Nothing in this
-- section is enabled until the user turns it on from the Profile & Stats tab.
_G.FORMULA_FEATURES = {
    profileIdentity = false,   -- Avatar 40263, frame 2003000, player level 100
    avatarLists = false,       -- Local avatar / frame selection lists
    profileAltAvatar = false,  -- Alternative avatar 30397 / frame 2002000
    profileCosmetics = false,  -- Background, social namecard frame, golden nickname
    rankProgress = false,      -- Rank, peak, season, badge and profile statistics
    creditScore = false,
    collectionLikes = false,
    personalPopularity = false,
    weaponPower = false,
    collectionStats = false,   -- Collection level / tier / title / points
    fakeWallet = false,        -- Local-only wallet preview and local checks
    collectionUnlock = false,  -- Local collection hall platform preview
}

_G.FORMULA_CURRENCY_VALUES = {
    gcoin = 78787878,
    uc = 99999991,
    silver = 78916613,
    fake_uc_default = 999999999,
}

function _G.FormulaFeatureEnabled(key)
    return type(_G.FORMULA_FEATURES) == "table"
       and _G.FORMULA_FEATURES[key] == true
end

function _G.FormulaSetFeature(key, enabled)
    if type(_G.FORMULA_FEATURES) ~= "table" or _G.FORMULA_FEATURES[key] == nil then
        return false
    end
    _G.FORMULA_FEATURES[key] = (enabled == true)
    if enabled and key == "profileIdentity" then
        _G.FORMULA_FEATURES.profileAltAvatar = false
    elseif enabled and key == "profileAltAvatar" then
        _G.FORMULA_FEATURES.profileIdentity = false
    end

    local ok, err = pcall(function()
        if key == "profileIdentity" then
            if enabled and _G.FORMULA_RefreshProfileIdentity then
                _G.FORMULA_RefreshProfileIdentity()
            end
        elseif key == "avatarLists" then
            if _G.FORMULA_ApplyAvatarLists then
                _G.FORMULA_ApplyAvatarLists(enabled == true)
            end
        elseif key == "rankProgress" then
            if _G.FORMULA_ApplyProfileProgress then
                _G.FORMULA_ApplyProfileProgress(enabled == true)
            end
        elseif key == "socialStats" then
            if _G.SocialStatsSpoof and _G.SocialStatsSpoof.Apply then
                _G.SocialStatsSpoof.Apply()
            end
        elseif key == "creditScore" or key == "collectionLikes"
            or key == "personalPopularity" or key == "weaponPower" then
            if _G.SocialStatsSpoof and _G.SocialStatsSpoof.Apply then
                _G.SocialStatsSpoof.Apply()
            end
        elseif key == "collectionStats" then
            if _G.FORMULA_ApplyCollectionStats then
                _G.FORMULA_ApplyCollectionStats(enabled == true)
            end
        elseif key == "fakeWallet" then
            if _G.FORMULA_ApplyFakeEconomy then
                _G.FORMULA_ApplyFakeEconomy(enabled == true)
            end
        elseif key == "collectionUnlock" then
            if _G.FORMULA_ApplyCollectionUnlock then
                _G.FORMULA_ApplyCollectionUnlock(enabled == true)
            end
        end
    end)
    if not ok then print("[FORMULA] Feature switch error: " .. tostring(err)) end
    return true
end
-- ==================== Feature Toggles ====================
_G.EnableDeadBoxSkin = _G.EnableDeadBoxSkin or true   -- Default on
-- ==================== Weather Config ====================
_G.WeatherMode = _G.WeatherMode or 0  -- Default: No weather
-- ==================== Wide-Angle Config ====================
_G.ConfigFOVEnable = _G.ConfigFOVEnable or false   -- Wide-angle toggle, default off
_G.ConfigFOV = _G.ConfigFOV or 90                  -- Wide-angle degree (does not take effect when toggle off)


_G.HatSkin = _G.HatSkin or 0
_G.FaceSkin = _G.FaceSkin or 0
_G.MaskSkin = _G.MaskSkin or 0
_G.GlovesSkin = _G.GlovesSkin or 0
_G.PantSkin = _G.PantSkin or 0
_G.ShoeSkin = _G.ShoeSkin or 0
_G.ParachuteSkin = _G.ParachuteSkin or 1401469
_G.GliderSkin = _G.GliderSkin or 4151133
_G.Backpack1Skin = _G.Backpack1Skin or 0
_G.Backpack2Skin = _G.Backpack2Skin or 0
_G.Backpack3Skin = _G.Backpack3Skin or 0
_G.Backpack4Skin = _G.Backpack4Skin or 0
_G.Backpack5Skin = _G.Backpack5Skin or 0
_G.Backpack6Skin = _G.Backpack6Skin or 0
_G.Helmet1Skin = _G.Helmet1Skin or 0
_G.Helmet2Skin = _G.Helmet2Skin or 0
_G.Helmet3Skin = _G.Helmet3Skin or 0
_G.Helmet4Skin = _G.Helmet4Skin or 0
_G.Helmet5Skin = _G.Helmet5Skin or 0
_G.Helmet6Skin = _G.Helmet6Skin or 0
-- Bulletproof vest skin (missing part)
_G.Armor1Skin = _G.Armor1Skin or 0
_G.Armor2Skin = _G.Armor2Skin or 0
_G.Armor3Skin = _G.Armor3Skin or 0
_G.Armor4Skin = _G.Armor4Skin or 0
_G.Armor5Skin = _G.Armor5Skin or 0
_G.Armor6Skin = _G.Armor6Skin or 0

-- Pet skin config
_G.PetSkinMap = _G.PetSkinMap or {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, -- Little Bunny Buddy
50046, -- Cursed Skull Boxing Bear Buddy
}
_G.PetSkinMapIndex = _G.PetSkinMapIndex or 1
_G.LastAppliedPet = _G.LastAppliedPet or 0

-- Weapon skin free mode storage
_G.WeaponSkinID = _G.WeaponSkinID or {}

_G.skinIdCache = _G.skinIdCache or {}
_G.skinIdCache2 = _G.skinIdCache2 or {}
_G.skinIdCache3 = _G.skinIdCache3 or {}
_G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
_G.CurrentEquipVehicleID = _G.CurrentEquipVehicleID or 0

-- ==================== Death Crate Variables ====================
_G.DeadBoxSkins = _G.DeadBoxSkins or {}
_G.AlreadyChangedSet = _G.AlreadyChangedSet or {}


-- Equipment slot type
_G.CustSlotType = _G.CustSlotType or {
    NONE = 0, HeadEquipemtSlot = 1, HairEquipemtSlot = 2, HatEquipemtSlot = 3,
    FaceEquipemtSlot = 4, ClothesEquipemtSlot = 5, PantsEquipemtSlot = 6,
    ShoesEquipemtSlot = 7, BackpackEquipemtSlot = 8, HelmetEquipemtSlot = 9,
    ArmorEquipemtSlot = 10, ParachuteEquipemtSlot = 11, GlassEquipemtSlot = 12,
    NightVisionEquipemtSlot = 13, BeardEquipemtSlot = 14, GlideEquipemtSlot = 15,
    HandEffectEquipemtSlot = 16, BackPack_PendantSlot = 17, MechaChestSlot = 18,
    MechaArmSlot = 19, MechaLegSlot = 20, MechaInnerSuitSlot = 21,
    FootEffectEquipemtSlot = 22, MaxSlotNum = 23, VehicleCut = 24,
    UnderClothSlot = 25, UnderPantsSlot = 26, SimpleSlotMax = 27, MAX = 28
}

-- ==================== Download Function ====================
local function download_item(id)
    if not PufferManager or not PufferConst then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end
_G.download_item = download_item

-- ==================== Character Equipment Apply Function ====================
function _G.equip_character_avatar(uCharacter)
    if not uCharacter or not slua.isValid(uCharacter) or not uCharacter.AvatarComponent2 then return end
    
    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end
    
    local ApplyData = uCharacter.AvatarComponent2.NetAvatarData and uCharacter.AvatarComponent2.NetAvatarData.SlotSyncData
    if not ApplyData or not slua.isValid(ApplyData) then return end
    
    local function setMakeSkin(ApplyDataIdx, currentItemId, targetSkinId, ApplyEquipSlot)
    if targetSkinId ~= nil then
        local equipment = ApplyData:Get(ApplyDataIdx)
        if equipment and equipment.SlotID == ApplyEquipSlot then
            if targetSkinId == 0 then
                -- Star In outfit mode, force unequip 6/7
                if _G.Wumingking and _G.Wumingking.GetSuit and _G.Wumingking.GetSuit() > 0
                   and (ApplyEquipSlot == 6 or ApplyEquipSlot == 7) then
                    if equipment.ItemId ~= 0 then
                        equipment.ItemId = 0
                        ApplyData:Set(ApplyDataIdx, equipment)
                        uCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
                    end
                end
                return
            end
                if equipment.ItemId ~= targetSkinId then
                    if not _G.skinIdCache[targetSkinId] then
                        pcall(_G.download_item, targetSkinId)
                        _G.skinIdCache[targetSkinId] = true
                    end
                    equipment.ItemId = targetSkinId
                    ApplyData:Set(ApplyDataIdx, equipment)
                    uCharacter.AvatarComponent2:OnRep_BodySlotStateChanged()
                end
            end
        end
    end
    
    -- Ensure glider, parachute, headwear, mask, eyewear, hair slots exist
local checkSlots = {
    _G.CustSlotType.GlideEquipemtSlot,     -- 15 (Glider)
    _G.CustSlotType.ParachuteEquipemtSlot, -- 11 (Parachute)
    _G.CustSlotType.HatEquipemtSlot,       -- 3  (Headwear)
    _G.CustSlotType.FaceEquipemtSlot,      -- 4  (Mask / Face Accessory)
    _G.CustSlotType.GlassEquipemtSlot,     -- 12 (Eyewear)
    _G.CustSlotType.HairEquipemtSlot,      -- 2  (Hair)
    _G.CustSlotType.HandEffectEquipemtSlot,-- 16 (Gloves) <- New
}
local slotFound = {}
for i = 0, ApplyData:Num() - 1 do
    local equipment = ApplyData:Get(i)
    if equipment then
        slotFound[equipment.SlotID] = true
    end
end
for _, slotID in ipairs(checkSlots) do
    if not slotFound[slotID] then
        ApplyData:Add({ SlotID = slotID, ItemId = 0 })
    end
end
    
    -- Apply all equipment skins
    for i = 0, ApplyData:Num() - 1 do
        local equipment = ApplyData:Get(i)
        local currentItemId = equipment.ItemId
        
        setMakeSkin(i, currentItemId, _G.SuitSkin, _G.CustSlotType.ClothesEquipemtSlot)
        
        -- Star Restore: Hair and headwear apply at same time
        setMakeSkin(i, currentItemId, _G.HairSkin, _G.CustSlotType.HairEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.HatSkin, _G.CustSlotType.HatEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.FaceSkin, _G.CustSlotType.FaceEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.MaskSkin, _G.CustSlotType.GlassEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.GlovesSkin, _G.CustSlotType.HandEffectEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.PantSkin, _G.CustSlotType.PantsEquipemtSlot)
        setMakeSkin(i, currentItemId, _G.ShoeSkin, _G.CustSlotType.ShoesEquipemtSlot)
        
        -- Backpack
        if equipment.SlotID == _G.CustSlotType.BackpackEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentBagLevel(equipment.AdditionalItemID) or 1
            local targetBagSkin = 0
            if nItemLevel == 1 then targetBagSkin = _G.Backpack1Skin
            elseif nItemLevel == 2 then targetBagSkin = _G.Backpack2Skin
            elseif nItemLevel == 3 then targetBagSkin = _G.Backpack3Skin
            elseif nItemLevel == 4 then targetBagSkin = _G.Backpack4Skin
            elseif nItemLevel == 5 then targetBagSkin = _G.Backpack5Skin
            elseif nItemLevel == 6 then targetBagSkin = _G.Backpack6Skin
            end
            setMakeSkin(i, currentItemId, targetBagSkin, _G.CustSlotType.BackpackEquipemtSlot)
        end
        
        -- Helmet
        if equipment.SlotID == _G.CustSlotType.HelmetEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentHelmetLevel(equipment.AdditionalItemID) or 1
            local targetHelmetSkin = 0
            if nItemLevel == 1 then targetHelmetSkin = _G.Helmet1Skin
            elseif nItemLevel == 2 then targetHelmetSkin = _G.Helmet2Skin
            elseif nItemLevel == 3 then targetHelmetSkin = _G.Helmet3Skin
            elseif nItemLevel == 4 then targetHelmetSkin = _G.Helmet4Skin
            elseif nItemLevel == 5 then targetHelmetSkin = _G.Helmet5Skin
            elseif nItemLevel == 6 then targetHelmetSkin = _G.Helmet6Skin
            end
            setMakeSkin(i, currentItemId, targetHelmetSkin, _G.CustSlotType.HelmetEquipemtSlot)
        end
        
        -- Bulletproof vest
        if equipment.SlotID == _G.CustSlotType.ArmorEquipemtSlot then
            local nItemLevel = BackpackUtils.GetEquipmentArmorLevel(equipment.AdditionalItemID) or 1
            local targetArmorSkin = 0
            if nItemLevel == 1 then targetArmorSkin = _G.Armor1Skin
            elseif nItemLevel == 2 then targetArmorSkin = _G.Armor2Skin
            elseif nItemLevel == 3 then targetArmorSkin = _G.Armor3Skin
            elseif nItemLevel == 4 then targetArmorSkin = _G.Armor4Skin
            elseif nItemLevel == 5 then targetArmorSkin = _G.Armor5Skin
            elseif nItemLevel == 6 then targetArmorSkin = _G.Armor6Skin
            end
            setMakeSkin(i, currentItemId, targetArmorSkin, _G.CustSlotType.ArmorEquipemtSlot)
        end
        
        -- Star Star Star Parachute / Glider: 0 Forces Default Value (100% Installed) Star Star Star
        local gliderApply = (_G.GliderSkin and _G.GliderSkin > 0) and _G.GliderSkin or 4151133
        local parachuteApply = (_G.ParachuteSkin and _G.ParachuteSkin > 0) and _G.ParachuteSkin or 1401469
        setMakeSkin(i, currentItemId, gliderApply, _G.CustSlotType.GlideEquipemtSlot)
        setMakeSkin(i, currentItemId, parachuteApply, _G.CustSlotType.ParachuteEquipemtSlot)
    end
end

-- ==================== Weapon Base ID Mapping ====================
_G.WeaponNameToID = {
    -- ========== Assault Rifle ==========
    AKM = 101001,
    M16A4 = 101002,
    SCAR = 101003,
    M416 = 101004,
    GROZA = 101005,
    AUG = 101006,
    QBZ = 101007,
    M762 = 101008,
    Mk47 = 101009,
    G36C = 101010,
    HoneyPot = 101012,
    FAMAS = 101100,
    ASM = 101101,
    ACE32 = 101102,
    
    -- ========== SMG ==========
    UZI = 102001,
    UMP = 102002,
    VECTOR = 102003,
    THOMPSON = 102004,
    BIZON = 102005,
    MP5K = 102007,
    JS9 = 102008,
    P90 = 102105,
    
    -- ========== Sniper / Marksman Rifle ==========
    K98 = 103001,
    M24 = 103002,
    AWM = 103003,
    SKS = 103004,
    VSS = 103005,
    Mini14 = 103006,
    MK14 = 103007,
    Win94 = 103008,
    M1Garand = 103103,
    SLR = 103009,
    QBU = 103010,
    Mosin = 103011,
    AMR = 103012,
    Mk12 = 103100,
    DSR = 103102,
    
    -- ========== Shotgun ==========
    S686 = 104001,
    S1897 = 104002,
    S12K = 104003,
    DBS = 104004,
    M1014 = 104101,
    NS2000 = 104102,
    
    -- ========== LMG ==========
    M249 = 105001,
    DP28 = 105002,
    MG3 = 105010,
    
    -- ========== Melee ==========
    PAN = 108004,
    DAGGER = 108005,
    Machete = 108001,
}

_G.WeaponIDSets = {
    -- ========== Assault Rifle ==========
    M416 = {[101004]=true, [1010041]=true, [1010042]=true, [1010043]=true, [1010044]=true, [1010045]=true, [1010046]=true, [1010047]=true, [1010049]=true},
    AKM = {[101001]=true, [1010011]=true, [1010012]=true, [1010013]=true, [1010014]=true, [1010015]=true, [1010016]=true, [1010017]=true, [1010019]=true},
    SCAR = {[101003]=true, [1010031]=true, [1010032]=true, [1010033]=true, [1010034]=true, [1010035]=true, [1010036]=true, [1010037]=true, [1010039]=true},
    M762 = {[101008]=true, [1010081]=true, [1010082]=true, [1010083]=true, [1010084]=true, [1010085]=true, [1010086]=true, [1010087]=true, [1010089]=true},
    GROZA = {[101005]=true, [1010051]=true, [1010052]=true, [1010053]=true, [1010054]=true, [1010055]=true, [1010056]=true, [1010057]=true, [1010059]=true},
    AUG = {[101006]=true, [1010061]=true, [1010062]=true, [1010063]=true, [1010064]=true, [1010065]=true, [1010066]=true, [1010067]=true},
    QBZ = {[101007]=true, [1010071]=true, [1010072]=true, [1010073]=true, [1010074]=true, [1010075]=true, [1010076]=true, [1010077]=true},
    M16A4 = {[101002]=true, [1010021]=true, [1010022]=true, [1010023]=true, [1010024]=true, [1010025]=true},
    FAMAS = {[101100]=true, [1011001]=true, [1011002]=true, [1011003]=true, [1011004]=true, [1011005]=true, [1011006]=true, [1011007]=true},
    ACE32 = {[101102]=true, [1011021]=true, [1011022]=true, [1011023]=true, [1011024]=true, [1011025]=true, [1011026]=true, [1011027]=true},
    ASM = {[101101]=true, [1011011]=true, [1011012]=true, [1011013]=true, [1011014]=true, [1011015]=true, [1011016]=true, [1011017]=true},
    Mk47 = {[101009]=true, [1010091]=true, [1010092]=true, [1010093]=true, [1010094]=true, [1010095]=true, [1010096]=true, [1010097]=true, [1010099]=true},
    G36C = {[101010]=true, [1010101]=true, [1010102]=true, [1010103]=true, [1010104]=true, [1010105]=true, [1010106]=true, [1010107]=true, [1010109]=true},
    HoneyPot = {[101012]=true, [1010121]=true, [1010122]=true, [1010123]=true, [1010124]=true, [1010125]=true, [1010126]=true, [1010127]=true, [1010129]=true},
    
    -- ========== SMG ==========
    UMP = {[102002]=true, [1020021]=true, [1020022]=true, [1020023]=true, [1020024]=true, [1020025]=true, [1020029]=true},
    VECTOR = {[102003]=true, [1020031]=true, [1020032]=true, [1020033]=true, [1020034]=true, [1020035]=true, [1020036]=true, [1020037]=true},
    UZI = {[102001]=true, [1020011]=true, [1020012]=true, [1020013]=true, [1020014]=true, [1020015]=true},
    THOMPSON = {[102004]=true, [1020041]=true, [1020042]=true, [1020043]=true, [1020044]=true, [1020045]=true},
    BIZON = {[102005]=true, [1020051]=true, [1020052]=true, [1020053]=true, [1020054]=true, [1020055]=true, [1020059]=true},
    P90 = {[102105]=true, [1021051]=true, [1021052]=true, [1021053]=true, [1021054]=true, [1021055]=true, [1021056]=true, [1021057]=true},
    MP5K = {[102007]=true, [1020071]=true, [1020072]=true, [1020073]=true, [1020074]=true, [1020075]=true, [1020076]=true, [1020077]=true, [1020079]=true},
    JS9 = {[102008]=true, [1020081]=true, [1020082]=true, [1020083]=true, [1020084]=true, [1020085]=true, [1020086]=true, [1020087]=true, [1020089]=true},
    
    -- ========== Sniper Rifle ==========
    AWM = {[103003]=true, [1030031]=true, [1030032]=true, [1030033]=true, [1030034]=true, [1030035]=true, [1030036]=true, [1030037]=true, [1030039]=true},
    M24 = {[103002]=true, [1030021]=true, [1030022]=true, [1030023]=true, [1030024]=true, [1030025]=true, [1030026]=true, [1030027]=true},
    K98 = {[103001]=true, [1030011]=true, [1030012]=true, [1030013]=true, [1030014]=true, [1030015]=true, [1030019]=true},
    MK14 = {[103007]=true, [1030071]=true, [1030072]=true, [1030073]=true, [1030074]=true, [1030075]=true, [1030076]=true, [1030077]=true},
    AMR = {[103012]=true, [1030121]=true, [1030122]=true, [1030123]=true, [1030124]=true, [1030125]=true, [1030126]=true, [1030127]=true},
    DSR = {[103102]=true, [1031021]=true, [1031022]=true, [1031023]=true, [1031024]=true, [1031025]=true, [1031026]=true, [1031027]=true, [1031029]=true},
    SKS = {[103004]=true, [1030041]=true, [1030042]=true, [1030043]=true, [1030044]=true, [1030045]=true, [1030046]=true, [1030047]=true, [1030049]=true},
    Mini14 = {[103006]=true, [1030061]=true, [1030062]=true, [1030063]=true, [1030064]=true, [1030065]=true, [1030066]=true, [1030067]=true, [1030069]=true},
    VSS = {[103005]=true, [1030051]=true, [1030052]=true, [1030053]=true, [1030054]=true, [1030055]=true, [1030056]=true, [1030057]=true, [1030059]=true},
    Win94 = {[103008]=true, [1030081]=true, [1030082]=true, [1030083]=true, [1030084]=true, [1030085]=true, [1030086]=true, [1030087]=true, [1030089]=true},
    M1Garand = {[103103]=true},
    SLR = {[103009]=true, [1030091]=true, [1030092]=true, [1030093]=true, [1030094]=true, [1030095]=true, [1030096]=true, [1030097]=true, [1030099]=true},
    QBU = {[103010]=true, [1030101]=true, [1030102]=true, [1030103]=true, [1030104]=true, [1030105]=true, [1030106]=true, [1030107]=true, [1030109]=true},
    Mosin = {[103011]=true, [1030111]=true, [1030112]=true, [1030113]=true, [1030114]=true, [1030115]=true, [1030116]=true, [1030117]=true, [1030119]=true},
    Mk12 = {[103100]=true, [1031001]=true, [1031002]=true, [1031003]=true, [1031004]=true, [1031005]=true, [1031006]=true, [1031007]=true, [1031009]=true},
    
    -- ========== Shotgun ==========
    S686 = {[104001]=true, [1040011]=true, [1040012]=true, [1040013]=true, [1040014]=true, [1040015]=true, [1040016]=true, [1040017]=true, [1040019]=true},
    S1897 = {[104002]=true, [1040021]=true, [1040022]=true, [1040023]=true, [1040024]=true, [1040025]=true, [1040026]=true, [1040027]=true, [1040029]=true},
    S12K = {[104003]=true, [1040031]=true, [1040032]=true, [1040033]=true, [1040034]=true, [1040035]=true, [1040036]=true, [1040037]=true, [1040039]=true},
    DBS = {[104004]=true, [1040041]=true, [1040042]=true, [1040043]=true, [1040044]=true, [1040045]=true, [1040046]=true, [1040047]=true, [1040049]=true},
    M1014 = {[104101]=true, [1041011]=true, [1041012]=true, [1041013]=true, [1041014]=true, [1041015]=true, [1041016]=true, [1041017]=true, [1041019]=true},
    NS2000 = {[104102]=true, [1041021]=true, [1041022]=true, [1041023]=true, [1041024]=true, [1041025]=true, [1041026]=true, [1041027]=true, [1041029]=true},
    
    -- ========== LMG ==========
    M249 = {[105001]=true, [1050011]=true, [1050012]=true, [1050013]=true, [1050014]=true, [1050015]=true, [1050016]=true, [1050017]=true},
    DP28 = {[105002]=true, [1050021]=true, [1050022]=true, [1050023]=true, [1050024]=true, [1050025]=true, [1050026]=true, [1050027]=true, [1050029]=true},
    MG3 = {[105010]=true, [1050101]=true, [1050102]=true, [1050103]=true, [1050104]=true, [1050105]=true, [1050106]=true, [1050107]=true, [1050109]=true},
    
    -- ========== Melee ==========
    PAN = {[108004]=true, [1080040]=true, [1080041]=true, [1080042]=true, [1080043]=true, [1080044]=true, [1080049]=true},
    DAGGER = {[108005]=true, [1080050]=true, [1080051]=true, [1080059]=true},
    Machete = {[108001]=true, [1080010]=true, [1080011]=true, [1080019]=true},
}

-- Star getBaseWeaponID split original logic (no cache, exactly same as original)
local function _getBaseWeaponID_raw(weaponID)
    if not weaponID then return nil end
    
    for weaponType, idSet in pairs(_G.WeaponIDSets) do
        if idSet[weaponID] then
            local minID = math.huge
            for id in pairs(idSet) do
                if id < minID then minID = id end
            end
            return minID
        end
    end
    
-- Skin ID range auto-recognition (completion)
if weaponID >= 1101004001 and weaponID <= 1101004246 then return 101004 end  -- M416
if weaponID >= 1101001001 and weaponID <= 1101001999 then return 101001 end  -- AKM
if weaponID >= 1101003001 and weaponID <= 1101003999 then return 101003 end  -- SCAR
if weaponID >= 1101008001 and weaponID <= 1101008999 then return 101008 end  -- M762
if weaponID >= 1101002001 and weaponID <= 1101002999 then return 101002 end  -- M16A4
if weaponID >= 1101005001 and weaponID <= 1101005999 then return 101005 end  -- GROZA
if weaponID >= 1101006001 and weaponID <= 1101006999 then return 101006 end  -- AUG
if weaponID >= 1101007001 and weaponID <= 1101007999 then return 101007 end  -- QBZ
if weaponID >= 1101009001 and weaponID <= 1101009999 then return 101009 end  -- Mk47
if weaponID >= 1101010001 and weaponID <= 1101010999 then return 101010 end  -- G36C
if weaponID >= 1101012001 and weaponID <= 1101012999 then return 101012 end  -- HoneyPot
if weaponID >= 1101100001 and weaponID <= 1101100999 then return 101100 end  -- FAMAS
if weaponID >= 1101101001 and weaponID <= 1101101999 then return 101101 end  -- ASM
if weaponID >= 1101102001 and weaponID <= 1101102999 then return 101102 end  -- ACE32

if weaponID >= 1102001001 and weaponID <= 1102001999 then return 102001 end  -- UZI
if weaponID >= 1102002001 and weaponID <= 1102002999 then return 102002 end  -- UMP
if weaponID >= 1102003001 and weaponID <= 1102003999 then return 102003 end  -- VECTOR
if weaponID >= 1102004001 and weaponID <= 1102004999 then return 102004 end  -- THOMPSON
if weaponID >= 1102005001 and weaponID <= 1102005999 then return 102005 end  -- BIZON
if weaponID >= 1102007001 and weaponID <= 1102007999 then return 102007 end  -- MP5K
if weaponID >= 1102008001 and weaponID <= 1102008999 then return 102008 end  -- JS9
if weaponID >= 1102105001 and weaponID <= 1102105999 then return 102105 end  -- P90

if weaponID >= 1103001001 and weaponID <= 1103001999 then return 103001 end  -- K98
if weaponID >= 1103002001 and weaponID <= 1103002999 then return 103002 end  -- M24
if weaponID >= 1103003001 and weaponID <= 1103003999 then return 103003 end  -- AWM
if weaponID >= 1103004001 and weaponID <= 1103004999 then return 103004 end  -- SKS
if weaponID >= 1103005001 and weaponID <= 1103005999 then return 103005 end  -- VSS
if weaponID >= 1103006001 and weaponID <= 1103006999 then return 103006 end  -- Mini14
if weaponID >= 1103007001 and weaponID <= 1103007999 then return 103007 end  -- MK14
if weaponID >= 1103008001 and weaponID <= 1103008999 then return 103008 end  -- Win94
if weaponID >= 1103103001 and weaponID <= 1103103999 then return 103103 end
if weaponID >= 1103009001 and weaponID <= 1103009999 then return 103009 end  -- SLR
if weaponID >= 1103010001 and weaponID <= 1103010999 then return 103010 end  -- QBU
if weaponID >= 1103011001 and weaponID <= 1103011999 then return 103011 end  -- Mosin
if weaponID >= 1103012001 and weaponID <= 1103012999 then return 103012 end  -- AMR
if weaponID >= 1103100001 and weaponID <= 1103100999 then return 103100 end  -- Mk12
if weaponID >= 1103102001 and weaponID <= 1103102999 then return 103102 end  -- DSR

if weaponID >= 1104001001 and weaponID <= 1104001999 then return 104001 end  -- S686
if weaponID >= 1104002001 and weaponID <= 1104002999 then return 104002 end  -- S1897
if weaponID >= 1104003001 and weaponID <= 1104003999 then return 104003 end  -- S12K
if weaponID >= 1104004001 and weaponID <= 1104004999 then return 104004 end  -- DBS
if weaponID >= 1104101001 and weaponID <= 1104101999 then return 104101 end  -- M1014
if weaponID >= 1104102001 and weaponID <= 1104102999 then return 104102 end  -- NS2000

if weaponID >= 1105001001 and weaponID <= 1105001999 then return 105001 end  -- M249
if weaponID >= 1105002001 and weaponID <= 1105002999 then return 105002 end  -- DP28
if weaponID >= 1105010001 and weaponID <= 1105010999 then return 105010 end  -- MG3

if weaponID >= 1108001001 and weaponID <= 1108001999 then return 108001 end  -- Machete
if weaponID >= 1108004001 and weaponID <= 1108004999 then return 108004 end  -- PAN
if weaponID >= 1108005001 and weaponID <= 1108005999 then return 108005 end  -- Dagger

    -- ★★★ Fix: Melee 7-Digit Variant Precise Mapping (Previously Missed Causing Judgment Confusion)★★★
    if weaponID >= 1080011 and weaponID <= 1080019 then return 108001 end
    if weaponID >= 1080041 and weaponID <= 1080049 then return 108004 end
    if weaponID >= 1080051 and weaponID <= 1080059 then return 108005 end
    
    return weaponID
end

-- Star External API: No cache, same as original behavior
function _G.getBaseWeaponID(weaponID)
    return _getBaseWeaponID_raw(weaponID)
end





-- ==================== Auto-Generate Attachment Quality Suffix ====================

_G.WeaponSkinPack = {
    -- ========== AKM ==========
    AKM = {
        
        -- [ AKM — Level 8 ]
        
        [1] = { main = 1101001174, attachments = {} }, -- Wandering Tyrant
        [2] = { main = 1101001213, attachments = {} }, -- Starsea Admiral
        [3] = { main = 1101001242, attachments = {} }, -- Decisive Day
        [4] = { main = 1101001265, attachments = {} }, -- Sandspring Dominion
        [5] = { main = 1101001276, attachments = {} }, -- Pulsing Light
        
        
        -- [ AKM — Level 7 ]
        
        [6]  = { main = 1101001063, attachments = {} }, -- The Seven Seas
        [7]  = { main = 1101001089, attachments = {} }, -- Glacier
        [8]  = { main = 1101001103, attachments = {} }, -- Desert Fossil
        [9]  = { main = 1101001116, attachments = {} }, -- Jack-o'-lantern
        [10] = { main = 1101001128, attachments = {} }, -- Ghillie Dragon
        [11] = { main = 1101001143, attachments = {} }, -- Gold Pirate
        [12] = { main = 1101001154, attachments = {} }, -- Codebreaker
        [13] = { main = 1101001172, attachments = {} }, -- Wandering Tyrant
        [14] = { main = 1101001212, attachments = {} }, -- Starsea Admiral
        [15] = { main = 1101001231, attachments = {} }, -- Bunny Munchkin
        [16] = { main = 1101001241, attachments = {} }, -- Decisive Day
        [17] = { main = 1101001249, attachments = {} }, -- Lightshift Temple (Divine Moon)
        [18] = { main = 1101001256, attachments = {} }, -- Lightshift Temple (Gold Feather)
        [19] = { main = 1101001264, attachments = {} }, -- Sandspring Dominion
        [20] = { main = 1101001275, attachments = {} }, -- Pulsing Light
    },

    -- ========== M16A4 ==========
    M16A4 = {
        [1] = { main = 1101002081, attachments = {} },
        [2] = { main = 1101002156, attachments = {} }, -- Sweet Cage - M16A4 (Level 7)
        [3] = { main = 1101002149, attachments = {} }, -- Jade Flowing Cloud - M16A4 (Level 5)
        [4] = { main = 1101002142, attachments = {} }, -- PUBG MOBILE x G-DRAGON - M16A4 (Level 5)
        [5] = { main = 1101002133, attachments = {} }, -- Mechanical Godzilla - M16A4 (Level 5)
        [6] = { main = 1101002125, attachments = {} }, -- Frozen Soul - M16A4 (Level 5)
        [7] = { main = 1101002117, attachments = {} }, -- Heavenly Magic Lamp - M16A4 (Level 5)
    },

    -- ========== SCAR ==========
    SCAR = {
        [1] = { main = 1101003227, attachments = {} }, -- Phoenix Jade - SCAR-L (Level 8)
        -- [ SCAR-L — Level 8 ]

        [1] = { main = 1101003146, attachments = {} }, -- Thorn of Malice
        [2] = { main = 1101003167, attachments = {} }, -- Bloodstained Nemesis
        [3] = { main = 1101003227, attachments = {} }, -- Celestial Bird
        
        
        -- [ SCAR-L — Level 7 ]
        
        [4]  = { main = 1101003057, attachments = {} }, -- Water Blaster
        [5]  = { main = 1101003070, attachments = {} }, -- Enchanted Pumpkin
        [6]  = { main = 1101003080, attachments = {} }, -- Operation Tomorrow
        [7]  = { main = 1101003099, attachments = {} }, -- Drop the Bass
        [8]  = { main = 1101003119, attachments = {} }, -- Hextech Crystal
        [9]  = { main = 1101003145, attachments = {} }, -- Thorn of Malice
        [10] = { main = 1101003166, attachments = {} }, -- Bloodstained Nemesis
        [11] = { main = 1101003181, attachments = {} }, -- Folly's Clasp (Variant 1)
        [12] = { main = 1101003188, attachments = {} }, -- Folly's Clasp (Variant 2)
        [13] = { main = 1101003195, attachments = {} }, -- Serene Lumina
        [14] = { main = 1101003208, attachments = {} }, -- Fantastical Realm
        [15] = { main = 1101003219, attachments = {} }, -- Soulbound Prism
        [16] = { main = 1101003226, attachments = {} }, -- Celestial Bird
    },

    -- ========== M416 ==========
    M416 = {
       
       
        -- [ M416 — Level 8 ]
        
        [1] = { main = 1101004163, attachments = {} }, -- Imperial Splendor
        [2] = { main = 1101004201, attachments = {} }, -- Silver Guru
        [3] = { main = 1101004209, attachments = {} }, -- Tidal Embrace
        [4] = { main = 1101004218, attachments = {} }, -- Shinobi Kami
        [5] = { main = 1101004226, attachments = {} }, -- Sealed Nether
        [6] = { main = 1101004236, attachments = {} }, -- Roaring Immolation
        [7] = { main = 1101004246, attachments = {} }, -- Fire Lotus (unverified)
        
        
        -- [ M416 — Level 7 ]
        
        [8]  = { main = 1101004046, attachments = {} }, -- Glacier
        [9]  = { main = 1101004062, attachments = {} }, -- The Fool
        [10] = { main = 1101004078, attachments = {} }, -- Wanderer
        [11] = { main = 1101004086, attachments = {} }, -- Lizard Roar
        [12] = { main = 1101004098, attachments = {} }, -- Call of the Wild
        [13] = { main = 1101004138, attachments = {} }, -- TechnoCore
        [14] = { main = 1101004162, attachments = {} }, -- Imperial Splendor
        [15] = { main = 1101004200, attachments = {} }, -- Silver Guru
        [16] = { main = 1101004208, attachments = {} }, -- Tidal Embrace
        [17] = { main = 1101004217, attachments = {} }, -- Shinobi Kami
        [18] = { main = 1101004225, attachments = {} }, -- Sealed Nether
        [19] = { main = 1101004235, attachments = {} }, -- Roaring Immolation
        [20] = { main = 1101004245, attachments = {} }, -- Fire Lotus (unverified)
    },

    -- ========== GROZA ==========
    GROZA = {
        
        -- [ GROZA — Level 8 ]

        [1] = { main = 1101005115, attachments = {} }, -- Cryoveil Witch
        
        
        -- [ GROZA — Level 7 ]
        
        [2] = { main = 1101005038, attachments = {} }, -- Ryomen Sukuna
        [3] = { main = 1101005052, attachments = {} }, -- River Styx
        [4] = { main = 1101005098, attachments = {} }, -- Burning Godzilla
        
        
        -- [ GROZA — Level 6 ]
        
        [5] = { main = 1101005037, attachments = {} }, -- Ryomen Sukuna
        [6] = { main = 1101005051, attachments = {} }, -- River Styx
        [7] = { main = 1101005097, attachments = {} }, -- Burning Godzilla
    },

    -- ========== AUG ==========
    AUG = {
       
        -- [ AUG — Level 8 ]

        [1] = { main = 1101006062, attachments = {} }, -- Forsaken Glace
        [2] = { main = 1101006085, attachments = {} }, -- Nyxen Rose
        [3] = { main = 1101006098, attachments = {} }, -- Nine-Tails Fury
        [4] = { main = 1101006106, attachments = {} }, -- Nine-Tails Boost
        
        
        -- [ AUG — Level 7 ]
        
        [5] = { main = 1101006061, attachments = {} }, -- Forsaken Glace
        [6] = { main = 1101006075, attachments = {} }, -- Abyssal Howl
        [7] = { main = 1101006084, attachments = {} }, -- Nyxen Rose
        [8] = { main = 1101006097, attachments = {} }, -- Nine-Tails Fury
        [9] = { main = 1101006105, attachments = {} }, -- Nine-Tails Boost
    },

    -- ========== QBZ ==========
    QBZ = {
        
        -- [ QBZ — Level 7 ]

        [1] = { main = 1101007046, attachments = {} }, -- Nether Phantom
        [2] = { main = 1101007062, attachments = {} }, -- Fatal Foil
        [3] = { main = 1101007071, attachments = {} }, -- Empyrean Charm
    },

    -- ========== M762 ==========
    M762 = {
       
        -- [ M762 — Level 8 ]

        [1] = { main = 1101008081, attachments = {} }, -- Stray Rebellion
        [2] = { main = 1101008104, attachments = {} }, -- Starcore
        [3] = { main = 1101008146, attachments = {} }, -- Skeletal Carver
        [4] = { main = 1101008154, attachments = {} }, -- Platinum Skeleton
        
        
        -- [ M762 — Level 7 ]
        
        [5]  = { main = 1101008051, attachments = {} }, -- Concerto of Love
        [6]  = { main = 1101008061, attachments = {} }, -- Deadly Precision
        [7]  = { main = 1101008070, attachments = {} }, -- GACKT MOONSAGA
        [8]  = { main = 1101008079, attachments = {} }, -- Stray Rebellion
        [9]  = { main = 1101008103, attachments = {} }, -- Starcore
        [10] = { main = 1101008116, attachments = {} }, -- Messi Football Icon
        [11] = { main = 1101008126, attachments = {} }, -- Noctum Sunder
        [12] = { main = 1101008136, attachments = {} }, -- Luminous Muse
        [13] = { main = 1101008145, attachments = {} }, -- Skeletal Carver
        [14] = { main = 1101008153, attachments = {} }, -- Platinum Skeleton
        [15] = { main = 1101008163, attachments = {} }, -- Soulspecter Shredder
        [16] = { main = 1101008170, attachments = {} }, -- Phantasia Siren
    },

    -- ========== Mk47 ==========
    Mk47 = {
        [1] = { main = 1101009019, attachments = {} },
        
    },

    -- ========== G36C ==========
    G36C = {
        [1] = { main = 1101010029, attachments = {} }, -- Ancient Energy - G36C (Level 5)
        [2] = { main = 1101010024, attachments = {} }, -- Punk Pioneer - G36C
		
    },

    -- ========== HoneyPot ==========
    HoneyPot = {
     
        -- [ Honey Badger — Level 7 ]

        [1] = { main = 1101012033, attachments = {} }, -- Sacred Ancient Tree
        
        
        -- [ Honey Badger — Level 6 ]
        
        [2] = { main = 1101012032, attachments = {} }, -- Sacred Ancient Tree
        
        
        -- [ Honey Badger — Level 5 ]
        
        [3] = { main = 1101012009, attachments = {} }, -- Vivid Glare
        [4] = { main = 1101012018, attachments = {} }, -- Melodic Rhythm
        [5] = { main = 1101012024, attachments = {} }, -- Honey Badger (Mikey)
    },

    -- ========== FAMAS ==========
    FAMAS = {
        
        -- [ FAMAS — Level 8 ]

        [1] = { main = 1101100012, attachments = {} }, -- Origin Lumen
        
        
        -- [ FAMAS — Level 7 ]
        
        [2] = { main = 1101100011, attachments = {} }, -- Origin Lumen
        
        
        -- [ FAMAS — Level 6 ]
        
        [3] = { main = 1101100010, attachments = {} }, -- Origin Lumen
        
        
        -- [ FAMAS — Level 5 ]
        
        [4] = { main = 1101100018, attachments = {} }, -- Cyber Mirage
    },

    -- ========== ASM ==========
    ASM = {
        [1] = { main = 1101101007, attachments = {} },
		[2] = { main = 1101101006, attachments = {} },
    },

    -- ========== ACE32 ==========
    ACE32 = {
        
        -- [ ACE32 — Level 8 ]

        [1] = { main = 1101102025, attachments = {} }, -- Mystic Kraken
        [2] = { main = 1101102041, attachments = {} }, -- Papillon Kiss
        [3] = { main = 1101102049, attachments = {} }, -- Butterfly Whispers
        
        
        -- [ ACE32 — Level 7 ]
        
        [4] = { main = 1101102007, attachments = {} }, -- Beam Blast
        [5] = { main = 1101102017, attachments = {} }, -- Icicle Spike
        [6] = { main = 1101102024, attachments = {} }, -- Mystic Kraken
        [7] = { main = 1101102040, attachments = {} }, -- Papillon Kiss
        [8] = { main = 1101102048, attachments = {} }, -- Butterfly Whispers
        [9] = { main = 1101102056, attachments = {} }, -- Naturespirit Growth
        
        
        -- [ ACE32 — Level 6 ]
        
        [10] = { main = 1101102006, attachments = {} }, -- Beam Blast
        [11] = { main = 1101102016, attachments = {} }, -- Icicle Spike
        [12] = { main = 1101102023, attachments = {} }, -- Mystic Kraken
        [13] = { main = 1101102039, attachments = {} }, -- Papillon Kiss
        [14] = { main = 1101102047, attachments = {} }, -- Butterfly Whispers
        [15] = { main = 1101102055, attachments = {} }, -- Naturespirit Growth
    },

    -- ========== UMP ==========
    UMP = {
        
        -- [ UMP45 — Level 8 ]
        
        [1] = { main = 1102002438, attachments = {} }, -- Surprise Dioscuri
        [2] = { main = 1102002446, attachments = {} }, -- Crimson Twin
        
        
        -- [ UMP45 — Level 7 ]
        
        [3] = { main = 1102002043, attachments = {} }, -- Dragonfire
        [4] = { main = 1102002061, attachments = {} }, -- Outlawed Fantasy
        [5] = { main = 1102002136, attachments = {} }, -- Cryofrost Shard
        [6] = { main = 1102002424, attachments = {} }, -- Void Souleater
        [7] = { main = 1102002437, attachments = {} }, -- Surprise Dioscuri
        [8] = { main = 1102002445, attachments = {} }, -- Crimson Twin
        
        
        -- [ UMP45 — Level 6 ]
        
        [9]  = { main = 1102002042, attachments = {} }, -- Dragonfire
        [10] = { main = 1102002060, attachments = {} }, -- Outlawed Fantasy
        [11] = { main = 1102002135, attachments = {} }, -- Cryofrost Shard
        [12] = { main = 1102002423, attachments = {} }, -- Void Souleater
        [13] = { main = 1102002436, attachments = {} }, -- Surprise Dioscuri
        [14] = { main = 1102002444, attachments = {} }, -- Crimson Twin
    },

    -- ========== UZI ==========
    UZI = {
        
        -- [ UZI — Level 8 ]

        [1] = { main = 1102001120, attachments = {} }, -- Glacier Hammer
        [2] = { main = 1102001143, attachments = {} }, -- Nebula Sting
        [3] = { main = 1102001151, attachments = {} }, -- Starwoven Scorpion Blade
        
        
        -- [ UZI — Level 7 ]
        
        [4] = { main = 1102001119, attachments = {} }, -- Glacier Hammer
        [5] = { main = 1102001130, attachments = {} }, -- Chained Inferno
        [6] = { main = 1102001142, attachments = {} }, -- Nebula Sting
        [7] = { main = 1102001150, attachments = {} }, -- Starwoven Scorpion Blade
        
        
        -- [ UZI — Level 6 ]
        
        [8]  = { main = 1102001024, attachments = {} }, -- Savagery
        [9]  = { main = 1102001118, attachments = {} }, -- Glacier Hammer
        [10] = { main = 1102001129, attachments = {} }, -- Chained Inferno
        [11] = { main = 1102001141, attachments = {} }, -- Nebula Sting
        [12] = { main = 1102001149, attachments = {} }, -- Starwoven Scorpion Blade
    },

    -- ========== VECTOR ==========
    VECTOR = {
        
        -- [ Vector — Level 7 ]

        [1] = { main = 1102003080, attachments = {} }, -- Mecha Drake
        [2] = { main = 1102003100, attachments = {} }, -- Snow Shadow (unverified)
        
        
        -- [ Vector — Level 6 ]
        
        [3] = { main = 1102003079, attachments = {} }, -- Mecha Drake
        [4] = { main = 1102003099, attachments = {} }, -- Snow Shadow (unverified)
        
        
        -- [ Vector — Level 5 ]
        
        [5]  = { main = 1102003020, attachments = {} }, -- Blood Tooth
        [6]  = { main = 1102003031, attachments = {} }, -- Midnight Rose
        [7]  = { main = 1102003039, attachments = {} }, -- Cute Baddie
        [8]  = { main = 1102003052, attachments = {} }, -- Golden Earl
        [9]  = { main = 1102003065, attachments = {} }, -- Gilded Reaper
        [10] = { main = 1102003072, attachments = {} }, -- Ultimate Predator
        [11] = { main = 1102003090, attachments = {} }, -- KMF Lancelot
    },

    -- ========== THOMPSON ==========
    THOMPSON = {
        [1] = { main = 1102004018, attachments = {} }, -- Candy Cannon - Thompson (Level 5)
        [2] = { main = 1102004034, attachments = {} }, 
		[3] = { main = 1102004048, attachments = {} },-- Steam Clockwork - Thompson (Level 5)
		
    },

    -- ========== BIZON ==========
    BIZON = {
       
        -- [ PP-19 Bizon — Level 7 ]

        [1] = { main = 1102005064, attachments = {} }, -- Spectral Byte
        
        
        -- [ PP-19 Bizon — Level 6 ]
        
        [2] = { main = 1102005063, attachments = {} }, -- Spectral Byte
        
        
        -- [ PP-19 Bizon — Level 5 ]
        
        [3] = { main = 1102005007, attachments = {} }, -- Blazing Chameleon
        [4] = { main = 1102005020, attachments = {} }, -- Skullcrusher
        [5] = { main = 1102005041, attachments = {} }, -- Soldier Soul
        [6] = { main = 1102005052, attachments = {} }, -- DP Quantum Quake
        [7] = { main = 1102005057, attachments = {} }, -- Auspicious Lion
        [8] = { main = 1102005078, attachments = {} }, -- Sakamoto Shop
    },

    -- ========== MP5K ==========
    MP5K = {
        [1] = { main = 1102007019, attachments = {} }, 
		[2] = { main = 1102007022, attachments = {} }, -- PUBGM X QWER - MP5K (Level 5)
		
    },

    -- ========== JS9 ==========
    JS9 = {
        [1] = { main = 1102008001, attachments = {} },
    },

    -- ========== P90 ==========
    P90 = {
       
        -- [ P90 — Level 7 ]

        [1] = { main = 1102105012, attachments = {} }, -- Devious Cybercat
        [2] = { main = 1102105028, attachments = {} }, -- Pegasus (unverified)
        
        
        -- [ P90 — Level 6 ]
        
        [3] = { main = 1102105011, attachments = {} }, -- Devious Cybercat
        [4] = { main = 1102105027, attachments = {} }, -- Pegasus (unverified)
        
        
        -- [ P90 — Level 5 ]
        
        [5] = { main = 1102105018, attachments = {} }, -- Golden Talon
        [6] = { main = 1102005072, attachments = {} }, -- Anamika Spirited Veil
    },

    -- ========== K98 ==========
    K98 = {
       
        -- [ Kar98K — Level 8 ]

        [1] = { main = 1103001202, attachments = {} }, -- Frostbite Fang (exact ID mapping unverified)
        
        
        -- [ Kar98K — Level 7 ]
        
        [2] = { main = 1103001060, attachments = {} }, -- Terror Fang
        [3] = { main = 1103001079, attachments = {} }, -- Kukulkan Fury
        [4] = { main = 1103001101, attachments = {} }, -- Moonlit Grace
        [5] = { main = 1103001129, attachments = {} }, -- Gackt Moon
        [6] = { main = 1103001146, attachments = {} }, -- Titanium Shark
        [7] = { main = 1103001154, attachments = {} }, -- Lethal Code
        [8] = { main = 1103001179, attachments = {} }, -- Violet Volt
        [9] = { main = 1103001191, attachments = {} }, -- Thornmaker
        
        
        -- [ Kar98K — Level 5 ]
        
        [10] = { main = 1103001085, attachments = {} }, -- Night of Rock
        [11] = { main = 1103001160, attachments = {} }, -- Nebula Hunter
        
        
        -- [ Kar98K — Level 3 ]
        
        [12] = { main = 1103001183, attachments = {} }, -- Kitty Kadence
    },

    -- ========== M24 ==========
    M24 = {
        
        -- [ M24 — Level 7 ]

        [1] = { main = 1103002030, attachments = {} }, -- Pharaoh's Might
        [2] = { main = 1103002059, attachments = {} }, -- Circle of Life
        [3] = { main = 1103002087, attachments = {} }, -- Cadence Maestro
        
        [4] = { main = 1103002106, attachments = {} }, -- Voidwave Trigger
        [5] = { main = 1103002126, attachments = {} }, -- Voidwave Trigger (Variant 1)
        [6] = { main = 1103002136, attachments = {} }, -- Voidwave Trigger (Variant 2)
        
        [7] = { main = 1103002113, attachments = {} }, -- Nightshade Dawn
        [8] = { main = 1103002146, attachments = {} }, -- Nightshade Dawn (Variant 2)
        [9] = { main = 1103002156, attachments = {} }, -- Dark Dawn (unverified)
        
        
        -- [ M24 — Level 5 ]
        
        [10] = { main = 1103002049, attachments = {} }, -- Lady Butterfly
        [11] = { main = 1103002047, attachments = {} }, -- Killer Tune
        [12] = { main = 1103002094, attachments = {} }, -- Industry Edge
    },

    -- ========== AWM ==========
    AWM = {
        

        [1] = { main = 1103003022, attachments = {} }, -- Mauve Avenger
        [2] = { main = 1103003030, attachments = {} }, -- Field Commander
        [3] = { main = 1103003042, attachments = {} }, -- Godzilla
        [4] = { main = 1103003051, attachments = {} }, -- Rainbow Drake
        [5] = { main = 1103003062, attachments = {} }, -- Flamewave
        [6] = { main = 1103003079, attachments = {} }, -- Valor's Requiem
        [7] = { main = 1103003087, attachments = {} }, -- Serpengleam
        [8] = { main = 1103003099, attachments = {} }, -- Chaos Calamity
        
        
        -- [ AWM — Level 5 ]
        
        [9] = { main = 1103003092, attachments = {} }, -- Primordial Era (unverified)
    },

    -- ========== M1Garand ==========
    M1Garand = {
        [1] = { main = 1103103007, attachments = {} }, -- Breaking Army Fighting Spirit - M1 Garand (Level 7)
    },

    -- ========== Win94 ==========
    Win94 = {
        [1] = { main = 1103008022, attachments = {} },
    },

    -- ========== Mosin ==========
    Mosin = {
        [1] = { main = 1103011003, attachments = {} },
    },

    -- ========== AMR ==========
    AMR = {
        
        [1] = { main = 1103012010, attachments = {} }, -- Crimson Ephialtes
        [2] = { main = 1103012019, attachments = {} }, -- Scorching Blessing
        [3] = { main = 1103012031, attachments = {} }, -- Silent Departed
        [4] = { main = 1103012039, attachments = {} }, -- Pyrotechnic Chroma
        [5] = { main = 1103012024, attachments = {} }, -- Onyx Blizzard
    },

    -- ========== DSR ==========
    DSR = {
        [1] = { main = 1103102007, attachments = {} },
    },

    -- ========== SKS ==========
    SKS = {
       
		
        [1] = { main = 1103004037, attachments = {} }, -- Lady Carmine
        [2] = { main = 1103004046, attachments = {} }, -- Metal Medley
        [3] = { main = 1103004058, attachments = {} }, -- Snowcapped Berg
        [4] = { main = 1103004080, attachments = {} }, -- Graceful Trigger
        [5] = { main = 1103004087, attachments = {} }, -- Melodic Climax
    },

    -- ========== VSS ==========
    VSS = {
        
		[1] = { main = 1103005024, attachments = {} }, -- Crow
        [2] = { main = 1103005048, attachments = {} }, -- White Snow Recon (unverified)
    },

    -- ========== Mini14 ==========
    Mini14 = {
        
		[1] = { main = 1103006030, attachments = {} }, -- Icicle
        [2] = { main = 1103006084, attachments = {} }, -- Platinum Soulmeister
        [3] = { main = 1103006046, attachments = {} }, -- Ethereal Beauty
        [4] = { main = 1103006058, attachments = {} }, -- Fortune Cat
        [5] = { main = 1103006063, attachments = {} }, -- Gallant Jockey
        [6] = { main = 1103006075, attachments = {} }, -- Rapid Battle Rhythm (unverified)
    },

    -- ========== MK14 ==========
    MK14 = {
       
        [1] = { main = 1103007028, attachments = {} }, -- Drakreign
        [2] = { main = 1103007020, attachments = {} }, -- Gilded Galaxy
        [3] = { main = 1103007038, attachments = {} }, -- Cuddly Nailoong
        [4] = { main = 1103007043, attachments = {} }, -- Lucky Gift Box (unverified)-- Ribbon Gift Box - MK14 (Level 5)
    },

    -- ========== SLR ==========
    SLR = {
        
		[1]  = { main = 1103009022, attachments = {} }, -- Falling Blossom
        [2]  = { main = 1103009037, attachments = {} }, -- Mageblaze
        [3] = { main = 1103009051, attachments = {} }, -- Hollow Wake
        [4] = { main = 1103009042, attachments = {} }, -- Seadream Melody
    },

    -- ========== QBU ==========
    QBU = {
        [1] = { main = 1103010014, attachments = {} },
    },

    -- ========== Mk12 ==========
    Mk12 = {
        [1] = { main = 1103100007, attachments = {} },
    },

    -- ========== S686 ==========
    S686 = {
        [1] = { main = 1104001035, attachments = {} },
    },

    -- ========== S1897 ==========
    S1897 = {
        [1] = { main = 1104002049, attachments = {} },
    },

    -- ========== S12K ==========
    S12K = {
        [1] = { main = 1104003037, attachments = {} }, -- Nuclear Rifle - S12K (Level 5)
        [2] = { main = 1104003046, attachments = {} }, -- Heartbeat Moment - S12K (Level 5)
        [3] = { main = 1104003041, attachments = {} },
    },

    -- ========== DBS ==========
    DBS = {
        [1] = { main = 1104004041, attachments = {} },
        [2] = { main = 1104004035, attachments = {} }, -- Exotic Beast Armor - DBS (Level 5)
        [3] = { main = 1104004051, attachments = {} }, -- Takakura Ken Transformation - DBS (Level 5)
    },

    -- ========== M1014 ==========
    M1014 = {
        [1] = { main = 1104101002, attachments = {} },
    },

    -- ========== NS2000 ==========
    NS2000 = {
        [1] = { main = 1104102004, attachments = {} },
    },

    -- ========== DP28 ==========
    DP28 = {
        
        [1] = { main = 1105002091, attachments = {} }, -- Bloodbane Parasite
        [2] = { main = 1105002106, attachments = {} }, -- Sanguine Sonata
        [3] = { main = 1105002018, attachments = {} }, -- Enigmatic Hunter
        [4] = { main = 1105002035, attachments = {} }, -- Gilded Jade Dragon
        [5] = { main = 1105002058, attachments = {} }, -- Nautical Warrior
        [6] = { main = 1105002063, attachments = {} }, -- Shenron
        [7] = { main = 1105002071, attachments = {} }, -- Mech Hero
        [8] = { main = 1105002076, attachments = {} }, -- Data Kitten
        [9] = { main = 1105002083, attachments = {} }, -- Frieren's Staff
        [10] = { main = 1105002096, attachments = {} }, -- Fox Clan (unverified)
    },

    -- ========== M249 ==========
    M249 = {
       
        [1] = { main = 1105001034, attachments = {} }, -- Party Parcel
        [2] = { main = 1105001048, attachments = {} }, -- Moondrop Eterna
        [3] = { main = 1105001069, attachments = {} }, -- Malus Majesty
        [4] = { main = 1105001020, attachments = {} }, -- Winter Queen M249 V
        [5] = { main = 1105001054, attachments = {} }, -- Stargaze Fury
        [6] = { main = 1105001062, attachments = {} }, -- Graffiti Street
        [7] = { main = 1105001075, attachments = {} }, -- Predator Protocol
    },

    -- ========== MG3 ==========
    MG3 = {
        [1] = { main = 1105010019, attachments = {} },
        [2] = { main = 1105010008, attachments = {} }, -- Sky Dragon - MG3 (Level 5)
        [3] = { main = 1105010026, attachments = {} }, -- Yabai Mina - MG3 (Level 5)
        [4] = { main = 1105010028, attachments = {} }, -- Magnificent Sky - MG3
    },

    -- ========== Melee ==========
    PAN = {
        
        [1] = { main = 1108004283, attachments = {} }, -- Accolade
        [2] = { main = 1108004337, attachments = {} }, -- Break Pad
        [3] = { main = 1108004125, attachments = {} }, -- Honeypot
        [4] = { main = 1108004160, attachments = {} }, -- Crocodile
        [5] = { main = 1108004145, attachments = {} }, -- Night of Rock
        [6] = { main = 1108004377, attachments = {} }, -- Penguin Pal Pan
        [7] = { main = 1108004356, attachments = {} }, -- Chicken Hot
        [8] = { main = 1108004365, attachments = {} }, -- Faerie Luster
        [9] = { main = 1108004416, attachments = {} }, -- Passionate Dance Fan (unverified)
    },
    DAGGER = {
        [1] = { main = 1108001103, attachments = {} }, -- Chain Handcuffs - Machete (Level 3)
        [2] = { main = 1108005052, attachments = {} }, -- Night Butterfly Kiss Dagger
        [3] = { main = 1081201, attachments = {} }, -- Punisher - Thunder
        [4] = { main = 1108001069, attachments = {} }, -- Ki Sword
    },
    Machete = {
       
        [1] = { main = 1108001057, attachments = {} }, -- Drakonbane Remnant
        [2] = { main = 1108001064, attachments = {} }, -- SPY×FAMILY Yor Stilettos
        [3] = { main = 1108001069, attachments = {} }, -- Ki Sword
        [4] = { main = 1108001081, attachments = {} }, -- Burning Godzilla Axe (unverified)
        [5] = { main = 1108001085, attachments = {} }, -- Survey Corps Blade (unverified)
        [6] = { main = 1108001098, attachments = {} }, -- Paradise-Reversing Spear (unverified)
        [7] = { main = 1108001103, attachments = {} }, -- Chain Handcuffs
        [8] = { main = 1108001107, attachments = {} }, -- Kusanagi Blade
        [9] = { main = 1108001111, attachments = {} }, -- Grocery Bag
        [10] = { main = 1108001104, attachments = {} }, -- Dioscuri
        
        
        -- [ Trident — Max Level ]
        
        [1] = { main = 1108002059, attachments = {} }, -- Tidal Fury
    },
}







-- ==================== Read Config File (Free Mode) ====================
local function ReadConfigFile()
    local configPath = nil

    -- Star Priority: Locate by current package name
    local curPath = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath()
    if curPath then
        local f = io.open(curPath, "r")
        if f then f:close(); configPath = curPath end
    end

    -- Star Fallback: Take first existing in order
    if not configPath then
        for _, path in ipairs(possiblePaths) do
            local file = io.open(path, "r")
            if file then
                file:close()
                configPath = path
                break
            end
        end
    end
    
    if not configPath then return end

    local file = io.open(configPath, "r")
    local content = file:read("*all")
    file:close()

    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+_?%w*)%s*=%s*(%d+)")
            if key and value then
                local index = tonumber(value)
                
-- ==================== Wide-Angle Config ====================
if key == "FOV_ENABLE" then
    _G.ConfigFOVEnable = (index == 1)
    lastConfig[key] = index
    if _G.GameCameraView then pcall(_G.GameCameraView) end
end
if key == "FOV_VALUE" then
    local fovValue = index
    if fovValue < 90 then fovValue = 90 end
    if fovValue > 120 then fovValue = 120 end
    _G.ConfigFOV = fovValue
    lastConfig[key] = index
    if _G.GameCameraView then pcall(_G.GameCameraView) end
end

                -- ==================== Watermark Toggle ====================
                if key == "WATERMARK" then
                    _G.WatermarkEnabled = (index == 1)
                    lastConfig[key] = index
                end

                -- ==================== Weapon Inspect Animation Config ====================
                if key == "WEAPON_ANIM" then
                    local enabled = (index == 1)
                    if _G.WeaponAnimationModule then
                        _G.WeaponAnimationModule._enabled = enabled
                        _G.WeaponAnimationModule.AUTO_START = enabled
                        if enabled then
                            pcall(function() _G.WeaponAnimationModule.Start() end)
                        else
                            pcall(function() _G.WeaponAnimationModule.Stop() end)
                        end
                    end
                    lastConfig[key] = index
                end

-- ==================== Pet Config ====================
if key == "PETSKIN" then
    -- Star New format: Store real pet ID (>= 50000)
    -- Star Old format: Store index (1~46), do one compatibility reverse lookup
    if index > 0 and index < 1000 then
        local petMap = _G.PetSkinMap or {}
        if petMap[index] then
            _G.PetSkinMapIndex = index
            _G.PetSkin = petMap[index]
        end
    else
        _G.PetSkin = index
        _G.PetSkinMapIndex = 1
        for i, id in ipairs(_G.PetSkinMap or {}) do
            if id == index then
                _G.PetSkinMapIndex = i
                break
            end
        end
    end
    lastConfig[key] = index
    if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
end

-- ==================== Trail Config ====================
if key == "TRAIL_ENABLE" then
    if _G.GoldenLeavesTrail then
        _G.GoldenLeavesTrail.Enabled = (index == 1)
        if _G.GoldenLeavesTrail.Enabled then
            pcall(_G.GoldenLeavesTrail.Apply)
        else
            pcall(_G.GoldenLeavesTrail.Stop)
        end
    end
    lastConfig[key] = index
end
if key == "TRAIL_TYPE" then
    local trailId = tonumber(value)
	if trailId == 4531001 or trailId == 4531002 or trailId == 4531003 or trailId == 4531004 or trailId == 4531005 or trailId == 4541001 or trailId == 4541004 or trailId == 4541005 then
        if _G.GoldenLeavesTrail then
            _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
            if _G.GoldenLeavesTrail.Enabled then
                pcall(_G.GoldenLeavesTrail.Apply)
            end
        end
    end
    lastConfig[key] = index
end

                -- ==================== Weather Config ====================
                if key == "WEATHER" then
                    _G.WeatherMode = index
                    lastConfig[key] = index
                    if _G.UpdateWeatherMode then
                        _G.UpdateWeatherMode(index)
                    end
                end

                -- ==================== Death Crate Skin Toggle ====================
if key == "DEADBOX_SKIN" then
    _G.EnableDeadBoxSkin = (index == 1)
    lastConfig[key] = index
end

-- ==================== Weapon Fast Refresh: Rebuild Timer When Config Reads 1 ====================
if key == "WEAPON_FAST_REFRESH" and lastConfig[key] ~= index then
    lastConfig[key] = index
    local interval = (index == 1) and 1.0 or 1.5
    local ok_tx, tx = pcall(require, "common.time_ticker")
    if ok_tx and tx then
        if _G.weaponAvatarTimerIndex and tx.IsRunning(_G.weaponAvatarTimerIndex) then
            pcall(function() tx.RemoveTimer(_G.weaponAvatarTimerIndex) end)
        end
        _G.weaponAvatarTimerIndex = tx.AddTimerLoop(0, function()
            pcall(_G.GameAvatarHandlerweapons)
        end, -1, interval)
        print("[DazhiMH] WEAPON_FAST_REFRESH=" .. tostring(index) .. " timer rebuilt, interval=" .. tostring(interval))
    end
end

-- ==================== Weapon Main Skin (Supports Preset Index + CUSTOM_* Custom ID) ====================
                local isCustom = string.sub(key, 1, 7) == "CUSTOM_"
                local weaponKey = isCustom and string.sub(key, 8) or key
                local weaponID = _G.WeaponNameToID[weaponKey]
                
                if weaponID and lastConfig[key] ~= index then
    _G.WeaponSkinID = _G.WeaponSkinID or {}
    local wantSkin = nil
    if isCustom then
        wantSkin = index
    else
        local skinPack = _G.WeaponSkinPack[key] and _G.WeaponSkinPack[key][index]
        if skinPack and skinPack.main then
            wantSkin = skinPack.main
        end
    end
    if wantSkin and wantSkin > 0 then
        -- ★★★ Fix: Verify ownership before writing, prevent config contamination ★★★
        if _G.isSkinForWeapon and _G.isSkinForWeapon(wantSkin, weaponID) then
            _G.WeaponSkinID[weaponID] = wantSkin
        else
            print(string.format("[ReadConfigFile] ⚠ Refused to write: %s 's skin=%d does not belong to this weapon, ignored",
                tostring(weaponKey), wantSkin))
            _G.WeaponSkinID[weaponID] = nil
        end
    end
    lastConfig[key] = index
                end
            end
        end
    end
    
    -- ==================== Vehicle Skin Config ====================
    local vehicleConfigs = {
        DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
        MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917, RONY = 1916,
        HORSE = 1987, MINIBUS = 1904, BOAT = 19110,  -- <- Correct
        ROADSTER = 19116, MIRADO = 1914, MIRADOC = 1915
    }
    
    for line in content:gmatch("[^\r\n]+") do
        if not line:match("^%s*#") then
            local key, value = line:match("(%w+)=(%d+)")
            if key and value then
                local numValue = tonumber(value)
                
-- Vehicle skin
if vehicleConfigs[key] and lastConfig[key] ~= numValue then
    _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
    _G.VehicleSkinIndex[vehicleConfigs[key]] = numValue
    lastConfig[key] = numValue
end
                
                -- Character equipment skin
                local roleSkins = {
                    HEADSHAPE = "_G.HeadShapeSkin",SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
                    FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
                    PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
                    GLIDER = "_G.GliderSkin", BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
                    BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin", BACKPACK5 = "_G.Backpack5Skin",
                    BACKPACK6 = "_G.Backpack6Skin", HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
                    HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin", HELMET5 = "_G.Helmet5Skin",
                    HELMET6 = "_G.Helmet6Skin",
                    ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin", ARMOR3 = "_G.Armor3Skin",
                    ARMOR4 = "_G.Armor4Skin", ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin"
                }
                if roleSkins[key] and lastConfig[key] ~= numValue then
    local varName = roleSkins[key]:gsub("^_G%.", "")
    -- Star Force intercept: When glider and parachute read as 0, restore default fallback value
    if key == "GLIDER" and numValue <= 0 then
        numValue = 4151133
    elseif key == "PARACHUTE" and numValue <= 0 then
        numValue = 1401469
    end
    _G[varName] = numValue
    lastConfig[key] = numValue
end
            end
        end
    end
end






do
    local ModuleManager = require('client.module_framework.ModuleManager')
    local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
    local download_util = require('client.slua.logic.download.puffer.download_util')
    local PufferConst = require('client.slua.logic.download.puffer_const')
    local PufferManager = require('client.slua.logic.download.puffer.puffer_manager')

    _G.g_parts = {}
    _G.g_parts_subtype = {}

    -- Resource download check
    _G.isResourceDownloaded = function(itemId)
        if not itemId or itemId <= 0 then return true end
        local cached = _G.skinDownloadCache[itemId]
        if cached ~= nil then return cached end
        local downloaded = false
        local ok = pcall(function()
            downloaded = download_util.IsDownloaded(itemId)
        end)
        if not ok then
            local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, { itemId })
            downloaded = state == PufferConst.ENUM_DownloadState.Done
        end
        _G.skinDownloadCache[itemId] = downloaded
        return downloaded
    end

    -- Attachment ID mapping table
    _G.muzzles = {
        id_flash_hider  = { 201010,2010101,2010102,2010103,2010104,2010105, 201005,2010051,2010052,2010053,2010054,201005, 201004,2010041,2010042,2010043,2010044,2010045 },
        id_compensator  = { 201009,2010091,2010092,2010093,2010094,2010095, 201003,2010031,2010032,2010033,2010034,2010035, 201002,2010021,2010022,2010023,2010024,2010025 },
        id_suppressor   = { 201011,2010111,2010112,2010113,2010114,2010115, 201006,2010061,2010062,2010063,2010064,2010065, 201007,2010071,2010072,2010073,2010074,2010075 },
        id_duckbill     = { 201012 },
        id_barrel_ext   = { 201051, 201050, 201055 },
        id_muzzle_brake = { 201053, 201052, 201054 },
    }
    _G.foregrips = {
        id_Angledforegrip = { 202001,2020011,2020012,2020013,2020014,2020015 },
        id_thumb_grip = { 202006,2020061,2020062,2020063,2020064,2020065 },
        id_vertical_grip = { 202002,2020021,2020022,2020023,2020024,2020025 },
        id_light_grip = { 202004,2020041,2020042,2020043,2020044,2020045 },
        id_half_grip = { 202005,2020051,2020052,2020053,2020054,2020055 },
        id_ergonomic_grip = { 202051,2020511,2020512,2020513,2020514,2020515 },
        id_laser_sight = { 202007,2020071,2020072,2020073,2020074,2020075 },
    }
    _G.magazines = {
        id_expanded_mag = { 204011,2040111,2040112,2040113,2040114,2040115, 204007,2040071,2040072,2040073,2040074,2040075, 204004,2040041,2040042,2040043,2040044,2040045, 204015,2040151,2040152,2040153,2040154,2040155 },
        id_quick_mag = { 204012,2040121,2040122,2040123,2040124,2040125, 204008,2040081,2040082,2040083,2040084,2040085, 204005,2040051,2040052,2040053,2040054,2040055 },
        id_expanded_quick_mag = { 204013,2040131,2040132,2040133,2040134,2040135, 204009,2040091,2040092,2040093,2040094,2040095, 204006,2040061,2040062,2040063,2040064,2040065 },
    }
    _G.scopes = {
        id_reddot = 203001, id_holo = 203002, id_2x = 203003, id_4x = 203004,
        id_8x = 203005, id_3x = 203014, id_6x = 203015, id_canted = 203018,
        id_reddot_b = 203051, id_holo_b = 203052, id_2x_b = 203053,
        id_4x_b = 203054, id_8x_b = 203055, id_3x_b = 203056, id_6x_b = 203057,
    }
    _G.stock = {
        id_microStock = 205001, id_tactical = 205002, id_bulletloop = 204014,
        id_CheekPad = 205003, id_heavy = 205010,
    }

    _G.familyKey = {
        id_flash_hider = 'FH', id_compensator = 'CP', id_suppressor = 'SP',
        id_duckbill = 'DK', id_barrel_ext = 'BE', id_muzzle_brake = 'MB',
        id_Angledforegrip = 'AG', id_thumb_grip = 'TG', id_vertical_grip = 'VG',
        id_light_grip = 'LG', id_half_grip = 'HG', id_ergonomic_grip = 'EG', id_laser_sight = 'LS',
        id_expanded_mag = 'EM', id_quick_mag = 'QM', id_expanded_quick_mag = 'EQ',
        id_reddot = 'RD', id_holo = 'HO', id_2x = 'S2', id_3x = 'S3', id_4x = 'S4',
        id_6x = 'S6', id_8x = 'S8', id_canted = 'CS',
        id_reddot_b = 'RD', id_holo_b = 'HO', id_2x_b = 'S2', id_3x_b = 'S3',
        id_4x_b = 'S4', id_6x_b = 'S6', id_8x_b = 'S8',
        id_microStock = 'ST', id_tactical = 'TS', id_bulletloop = 'BL',
        id_CheekPad = 'CH', id_heavy = 'HS',
    }

    _G.idToFamily = {}
    _G.knownIDs = {}
    local function reg(id, fam)
        if id and id > 0 then _G.idToFamily[id] = fam _G.knownIDs[id] = true end
    end
    for f, l in pairs(_G.muzzles) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.foregrips) do for _, id in ipairs(l) do reg(id, f) end end
    for f, l in pairs(_G.magazines) do for _, id in ipairs(l) do reg(id, f) end end
    for f, id in pairs(_G.scopes) do reg(id, f) end
    for f, id in pairs(_G.stock) do reg(id, f) end

    local SUBTYPE_MUZZLE, SUBTYPE_SCOPE, SUBTYPE_STOCK, SUBTYPE_MAG, SUBTYPE_GRIP = 201, 202, 203, 204, 205

    local function splitStr(str, sep)
        local t = {}
        if not str or str == '' then return t end
        for part in string.gmatch(str, '([^' .. sep .. ']+)') do table.insert(t, part) end
        return t
    end

    local function get_group_id(itemId)
        if not ItemUpgradeSystem or not itemId then return nil end
        local c = ItemUpgradeSystem:GetUpgradeCfg(itemId)
        return c and c.GroupID or nil
    end

    local function getFamily(id)
        return id and _G.idToFamily[id]
    end

    local function getPartOriginID(partId)
        if not partId or partId == 0 then return 0 end
        local ok, cfg = pcall(function() return CDataTable.GetTableData('WeaponAttachAttrBPTable', partId) end)
        if ok and cfg and cfg.ParentID and cfg.ParentID > 0 then return cfg.ParentID end
        return 0
    end

    local function getBPID(resId)
        local bp = resId
        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetBPIDByResID then
                local v = UAvatarUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        pcall(function()
            local UBackpackUtils = import('BackpackUtils')
            if UBackpackUtils and UBackpackUtils.GetBPIDByResID then
                local v = UBackpackUtils.GetBPIDByResID(resId)
                if v and v > 0 then bp = v end
            end
        end)
        return bp
    end

    -- Save attachment mapping
    local function savePart(skinId, baseId, skinPartId)
        if not skinId or not baseId or not skinPartId or baseId <= 0 or skinPartId <= 0 then return end
        _G.g_parts[skinId][baseId] = skinPartId
        local fam = getFamily(baseId)
        if not fam then return end
        local key = _G.familyKey[fam]
        if key then _G.g_parts[skinId][key] = skinPartId end
        if _G.muzzles[fam] then
            for _, id in ipairs(_G.muzzles[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.magazines[fam] then
            for _, id in ipairs(_G.magazines[fam]) do 
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.foregrips[fam] then
            for _, id in ipairs(_G.foregrips[fam]) do
                _G.g_parts[skinId][id] = skinPartId 
            end
        elseif _G.scopes[fam] then
            for fid, f in pairs(_G.scopes) do 
                if f == fam then 
                    _G.g_parts[skinId][fid] = skinPartId 
                end 
            end
        elseif _G.stock[fam] then
            _G.g_parts[skinId][_G.stock[fam]] = skinPartId
        end
    end

    local function saveBySubType(skinId, subType, skinPartId)
        if not skinId or not subType or not skinPartId or skinPartId <= 0 then return end
        if not _G.g_parts_subtype[skinId] then _G.g_parts_subtype[skinId] = {} end
        _G.g_parts_subtype[skinId][subType] = skinPartId
    end

    -- Initialize attachment mapping (read from game data table)
    _G.InitParts = function(groupId, itemId)
        if not itemId then return _G.g_parts end
        if not _G.g_parts[itemId] then _G.g_parts[itemId] = {} end
        if not _G.g_parts_subtype[itemId] then _G.g_parts_subtype[itemId] = {} end

        pcall(function()
            local bpId = getBPID(itemId)
            local tryIds = { bpId, itemId }
            local icfg = CDataTable.GetTableData('Item', itemId)
            if icfg and icfg.BPID and icfg.BPID > 0 then table.insert(tryIds, icfg.BPID) end
            for _, tid in ipairs(tryIds) do
                local cfg = CDataTable.GetTableData('WeaponAttrBPTable', tid)
                if cfg and cfg.AttachmentSkinIDList and cfg.AttachmentSkinIDList ~= '' then
                    for _, pair in ipairs(splitStr(cfg.AttachmentSkinIDList, '|')) do
                        local nums = splitStr(pair, '-')
                        local b, s = tonumber(nums[1]), tonumber(nums[2])
                        if b and s then savePart(itemId, b, s) end
                    end
                end
            end
        end)

        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
            groupId = ItemUpgradeSystem:GetNormalGroupID(groupId or get_group_id(itemId))
        else
            groupId = groupId or get_group_id(itemId)
        end

        pcall(function()
            local partsDic = ItemUpgradeSystem:GetPartsDic(groupId)
            if partsDic then
                for subType, partList in pairs(partsDic) do
                    for _, partId in ipairs(partList) do
                        local skinPartId = partId
                        if ItemUpgradeSystem:IsWeaponIsRefit(itemId) then
                            local sw = ItemUpgradeSystem:PartIDSwitch(partId, true)
                            if sw and sw ~= partId then skinPartId = sw end
                        end
                        saveBySubType(itemId, subType, skinPartId)
                        local parent = getPartOriginID(skinPartId)
                        if parent == 0 then parent = getPartOriginID(partId) end
                        if parent > 0 then
                            savePart(itemId, parent, skinPartId)
                        elseif _G.knownIDs[partId] then
                            savePart(itemId, partId, skinPartId)
                        end
                    end
                end
            end
        end)

        pcall(function()
            local UAvatarUtils = import('AvatarUtils')
            if UAvatarUtils and UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin then
                local list = UAvatarUtils.GetWeaponAvatarDefaultAttachmentSkin(itemId, {}, false) or {}
                for baseId, skinPartId in pairs(list) do
                    if baseId and skinPartId and skinPartId > 0 then
                        if _G.knownIDs[baseId] then
                            savePart(itemId, baseId, skinPartId)
                        else
                            local parent = getPartOriginID(skinPartId)
                            if parent > 0 then savePart(itemId, parent, skinPartId)
                            else _G.g_parts[itemId][baseId] = skinPartId end
                        end
                    end
                end
            end
        end)

        return _G.g_parts
    end

-- ==================== Custom Attachment Skin (Add Your Config Here) ====================
-- Format: [Weapon Skin ID] = { [Attachment ID] = Attachment Skin ID, ... }
-- Weapon skin ID: main value in WeaponSkinPack, e.g. 1101006106=Nine-Tails Assistant - AUG
-- Attachment IDs:      Red Dot=203001 Holo=203002 2x=203003 3x=203014 4x=203004 6x=203015 8x=203005
--              Suppressor AR=201011 Suppressor SMG=201006 Suppressor SR=201007 Compensator AR=201009 Flash Hider AR=201010
--              Vertical Grip=202002 Light Grip=202004 Half Grip=202005 Thumb Grip=202006 Laser=202007 Angled Grip=202001
--              AR Extended Mag=204011 AR Quick-Extended Mag=204013 Tactical Stock=205002 Cheek Pad=205003
-- Attachment skin ID: Item ID of the attachment skin you want to change to (8 digits, e.g. 1010061038)
_G.CustomAttachmentSkin = {
    [1101006106] = {              -- Nine-Tails Assistant - AUG (Level 8)
        [203001] = 1010060998,    -- Red Dot Sight -> Replace with specified red dot skin
        [203002] = 1010060997,    -- Holographic Sight -> Replace with specified red dot skin
        [203003] = 1010060996,    -- 2x Scope -> Replace with the specified red dot skin
        [203014] = 1010060995,    -- 3x Scope -> Replace with the specified red dot skin
        [203004] = 1010060994,    -- 4x Scope -> Replace with the specified red dot skin
        [203015] = 1010060993,    -- 6x Scope -> Replace with the specified red dot skin
        [201010] = 1010061005,    -- Flash Hider
        [201011] = 1010061006,    -- Suppressor
        [201009] = 1010061004,    -- Muzzle Compensator
        [202001] = 1010061007,    -- Angled Foregrip
        [202006] = 1010061008,    -- Thumb Grip
        [202002] = 1010061009,    -- Vertical Grip
        [202007] = 1010061010,    -- Laser Sight
        [202004] = 1010060973,    -- Light Grip
        [202005] = 1010060974,    -- Half Grip
        [204011] = 1010061000,    -- Quick Magazine
        [204012] = 1010060999,    -- Extended Magazine
        [204013] = 1010061003,    -- Quick-Extended Magazine
    },
    [1101006098] = {              -- Nine-Tails Fury - AUG (Level 8)
        [203001] = 1010060958,    -- Red Dot Sight
        [203002] = 1010060957,    -- Holographic Sight
        [203003] = 1010060956,    -- 2x Scope
        [203014] = 1010060955,    -- 3x Scope
        [203004] = 1010060954,    -- 4x Scope
        [203015] = 1010060953,    -- 6x Scope
        [201010] = 1010060965,    -- Flash Hider
        [201011] = 1010060966,    -- Suppressor
        [201009] = 1010060964,    -- Muzzle Compensator
        [202001] = 1010060967,    -- Angled Foregrip
        [202006] = 1010060968,    -- Thumb Grip
        [202002] = 1010060969,    -- Vertical Grip
        [202007] = 1010060970,    -- Laser Sight
        [202004] = 1010060973,    -- Light Grip
        [202005] = 1010060974,    -- Half Grip
        [204011] = 1010060960,    -- Quick Magazine
        [204012] = 1010060959,    -- Extended Magazine
        [204013] = 1010060963,    -- Quick-Extended Magazine
    },
}
-- ==================== Custom Attachment Skin END ====================

-- Star Compatibility: User may only configure CustomAttachmentSkin, Nine-Tails tables may be undefined, empty table fallback
_G.NineTailsParts = _G.NineTailsParts or {}

local NINE_BASE_TO_KEY = {
    [203001] = "RD", [203002] = "HO", [203003] = "S2", [203004] = "S4",
    [203014] = "S3", [203015] = "S6", [203018] = "CS",
    [203051] = "RD", [203052] = "HO", [203053] = "S2", [203054] = "S4",
    [203055] = "S8", [203056] = "S3", [203057] = "S6",
    [201002] = "CP", [201003] = "CP", [201009] = "CP",
    [201004] = "FH", [201005] = "FH", [201010] = "FH",
    [201006] = "SP", [201007] = "SP", [201011] = "SP",
    [202001] = "AG", [202002] = "VG", [202004] = "LG",
    [202005] = "HG", [202006] = "TG", [202007] = "LS",
    [204004] = "EM", [204007] = "EM", [204011] = "EM", [204015] = "EM",
    [204005] = "QM", [204008] = "QM", [204012] = "QM",
    [204006] = "EQ", [204009] = "EQ", [204013] = "EQ",
}

function _G.GetNineTailsPartSkin(avatarid, current_id)
    -- Star nil protection: User may have deleted Nine-Tails config, fallback with empty table
    local ntParts = _G.NineTailsParts
    if not ntParts then return nil end
    local group = ntParts[avatarid]
    if not group then return nil end
    _G.NINE_TAILS_SKIN = _G.NINE_TAILS_SKIN or {}
local map = _G.NINE_TAILS_SKIN[group]
    if not map then return nil end
    -- 1. Direct hit by base attachment ID
    local key = NINE_BASE_TO_KEY[current_id]
    if key and map[key] then return map[key] end
    -- 2. Fallback via familyKey (skin attachment ID / alias attachment can both hit)
    local fam = _G.idToFamily and _G.idToFamily[current_id]
    if fam then
        local k = _G.familyKey and _G.familyKey[fam]
        if k and map[k] then return map[k] end
    end
    return nil
end

    -- Find attachment skin
local function findSkin(current_id, avatarid, slot, subType)
    if not _G.isResourceDownloaded(avatarid) then return nil end

    -- Star Star Star Custom Attachment Skin Highest Priority (Overrides Nine-Tails and Game Default Mapping) Star Star Star
    local custMap = _G.CustomAttachmentSkin and _G.CustomAttachmentSkin[avatarid]
    if custMap and current_id then
        -- 1. Direct hit on base attachment ID (Red Dot 203001 / Suppressor 201011 etc.)
        local c1 = custMap[current_id]
        if c1 and c1 > 0 and _G.isResourceDownloaded(c1) then
            return c1
        end
        -- 2. current is skin attachment ID -> Trace back to base then hit
        local baseId = getPartOriginID(current_id)
        if baseId > 0 then
            local c2 = custMap[baseId]
            if c2 and c2 > 0 and _G.isResourceDownloaded(c2) then
                return c2
            end
        end
        -- 3. family fallback: customKey and current belong to same family
        local famCust = getFamily(current_id)
        if famCust then
            for sid, sv in pairs(custMap) do
                if type(sid) == 'number' and sv and sv > 0
                   and getFamily(sid) == famCust
                   and _G.isResourceDownloaded(sv) then
                    return sv
                end
            end
        end
        -- 4. NINE_BASE_TO_KEY reverse-lookup fallback (when current is Nine-Tails skin attachment ID)
        local curKey = NINE_BASE_TO_KEY[current_id]
        if curKey then
            for baseId, sv in pairs(custMap) do
                if type(baseId) == 'number' then
                    local bk = NINE_BASE_TO_KEY[baseId]
                    if bk == curKey and sv and sv > 0 and _G.isResourceDownloaded(sv) then
                        return sv
                    end
                end
            end
        end
    end

    -- Star Nine-Tails AUG attachment skin fallback (only when custom misses; protected by pcall, prevent GetNineTailsPartSkin internal error)
    if _G.NineTailsParts and next(_G.NineTailsParts) then
        local ok, nineSkin = pcall(_G.GetNineTailsPartSkin, avatarid, current_id)
        if ok and nineSkin and _G.isResourceDownloaded(nineSkin) then
            return nineSkin
        end
    end

    -- Star Power: Each avatarid only init once (original logic kept)
    if not _G.__perf.partsInited[avatarid] then
        _G.__perf.partsInited[avatarid] = true
        _G.InitParts(get_group_id(avatarid), avatarid)
    end
        local p = _G.g_parts[avatarid]
        if not p then return nil end
        if p[current_id] and p[current_id] > 0 then
            local candidate = p[current_id]
            if _G.isResourceDownloaded(candidate) then return candidate end
        end
        local fam = getFamily(current_id)
        if fam then
            local key = _G.familyKey[fam]
            if key and p[key] and p[key] > 0 and _G.isResourceDownloaded(p[key]) then return p[key] end
            for sid, sv in pairs(p) do
                if type(sid) == 'number' and getFamily(sid) == fam and sv > 0 and _G.isResourceDownloaded(sv) then
                    return sv
                end
            end
        end
        if subType then
            local st = _G.g_parts_subtype[avatarid]
            if st and st[subType] and st[subType] > 0 then
                local candidate = st[subType]
                if _G.isResourceDownloaded(candidate) then return candidate end
            end
        end
        return nil
    end

    -- Parse attachment ID
    local function resolve(id, av, slot, subType)
        local init = id
        if not id or id <= 0 then return id, false end
        if not _G.isResourceDownloaded(av) then return id, false end
        local s = findSkin(id, av, slot, subType)
        if s and s > 0 then
            if s ~= id and not _G.isResourceDownloaded(s) then return id, false end
            return s, s ~= init
        end
        return id, false
    end

    -- Export attachment parsing function
    _G.get_muzzleid = function(id, av) return resolve(id, av, 0, SUBTYPE_MUZZLE) end
    _G.get_forgripid = function(id, av) return resolve(id, av, 4, SUBTYPE_GRIP) end
    _G.get_magazinesid = function(id, av) return resolve(id, av, 1, SUBTYPE_MAG) end
    _G.get_scopeid = function(id, av) return resolve(id, av, 3, SUBTYPE_SCOPE) end
    _G.get_stockid = function(id, av) return resolve(id, av, 2, SUBTYPE_STOCK) end

    -- Apply attachment skin to weapon
    _G.apply_attachment = function(CurWeapon, avatarid)
    if not CurWeapon or not avatarid or avatarid <= 0 then return false end
    if not _G.isResourceDownloaded(avatarid) then return false end

    -- Star Power: Same gun same skin only processed once within 3 sec
    local key = tostring(CurWeapon) .. "|" .. tostring(avatarid)
    local now = os.clock()
    if now - (_G.__perf.attachStamp[key] or 0) < 3 then return false end
    _G.__perf.attachStamp[key] = now

    local array = CurWeapon.synData
        if not array or not slua.isValid(array) then return false end
        local changed = false
        for AttachIdx = 0, 4 do
            local Data = array:Get(AttachIdx)
            if Data and slua.isValid(Data) then
                local itemid = slua.IndexReference(Data, 'defineID').TypeSpecificID
                if itemid and itemid > 0 and itemid < 10000000 then
                    local newId, isrefresh
                    if AttachIdx == 0 then
                        newId, isrefresh = _G.get_muzzleid(itemid, avatarid)
                    elseif AttachIdx == 1 then
                        newId, isrefresh = _G.get_forgripid(itemid, avatarid)
                    elseif AttachIdx == 2 then
                        newId, isrefresh = _G.get_magazinesid(itemid, avatarid)
                    elseif AttachIdx == 3 then
                        newId, isrefresh = _G.get_stockid(itemid, avatarid)
                    elseif AttachIdx == 4 then
                        newId, isrefresh = _G.get_scopeid(itemid, avatarid)
                    end
                    if isrefresh then
                        slua.IndexReference(Data, 'defineID').TypeSpecificID = newId
                        array:Set(AttachIdx, Data)
                        changed = true
                    end
                end
            end
        end
        if changed then
            pcall(function() CurWeapon:DelayHandleAvatarMeshChanged() end)
        end
        return changed
    end

    -- Equip weapon skin (force-refresh attachments every time)
    _G.equip_weapon_avatar = function(uCharacter)
        if not uCharacter or not slua.isValid(uCharacter) then return end
        local WeaponManager = uCharacter:GetWeaponManager()
        if not WeaponManager or not slua.isValid(WeaponManager) then return end
        local uWeaponList = WeaponManager:GetAllInventoryWeaponList(false)
        if not uWeaponList or not slua.isValid(uWeaponList) then return end
        
        for i = 0, uWeaponList:Num() - 1 do
            local CurWeapon = uWeaponList:Get(i)
            if slua.isValid(CurWeapon) then
                local AttachmentArray = CurWeapon.synData
                if not AttachmentArray or not slua.isValid(AttachmentArray) then goto continue_weapon end
                
                local AttachmentData = AttachmentArray:Get(7)
                if not AttachmentData or not slua.isValid(AttachmentData) then goto continue_weapon end
                
                local current_skin_id = slua.IndexReference(AttachmentData, 'defineID').TypeSpecificID
                if not current_skin_id or current_skin_id <= 0 then goto continue_weapon end
                
                local weapon_id = CurWeapon:GetWeaponID()
                if current_skin_id == weapon_id then goto continue_weapon end
                
                if not _G.isResourceDownloaded(current_skin_id) then goto continue_weapon end
                
                -- Force refresh attachments every time
                _G.apply_attachment(CurWeapon, current_skin_id)
            end
            ::continue_weapon::
        end
    end
end

-- ==================== Weapon Skin Get Function (Returns Only Skin ID) ====================
-- ★★★ Judge If Skin Really Belongs to This Weapon (Core Anti-Contamination Function)★★★
function _G.isSkinForWeapon(skinId, baseWid)
    if not skinId or not baseWid then return false end
    skinId = tonumber(skinId)
    baseWid = tonumber(baseWid)
    if not skinId or not baseWid then return false end

    -- Original skin: Same ID
    if skinId == baseWid then return true end

    -- Normal: Skin's base must equal baseWid
    local skinBase = baseWid
    if _G.getBaseWeaponID then
        local ok, b = pcall(_G.getBaseWeaponID, skinId)
        if ok and b then skinBase = tonumber(b) or skinId end
    else
        skinBase = skinId
    end
    if skinBase == baseWid then return true end

    -- Star Shared melee skin allow: 1081201 "Punisher - Thunder" can be used by any melee
    if skinId == 1081201 then
        if baseWid == 108001 or baseWid == 108004 or baseWid == 108005 then
            return true
        end
    end

    return false
end

function _G.get_skin_id2(weaponID)
    if not weaponID then return nil end
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local targetSkinID = baseWeaponID
    
    if _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponID] and _G.WeaponSkinID[baseWeaponID] ~= 0 then
        local skin = _G.WeaponSkinID[baseWeaponID]
        -- ★★★ Fix: Skin ownership must match, if not match treat as contamination and clear ★★★
        if _G.isSkinForWeapon(skin, baseWeaponID) then
            targetSkinID = skin
        else
            print(string.format("[get_skin_id2] ⚠ Clear contamination: base=%d stored wrong skin=%d, Restored original skin",
                baseWeaponID, skin))
            _G.WeaponSkinID[baseWeaponID] = nil
        end
    end
    
    return targetSkinID
end

--ApplyCachedAttachments function
_G.attachmentCache = _G.attachmentCache or {}

-- ==================== Unified Refresh Function (Weapon Main Skin + Attachments + No-Hold Refresh) ====================
function _G.GameAvatarHandlerweapons()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end
        
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end
        
        local isBackRefresh = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("WEAPON_BACK_REFRESH", 0) == 1)
        local processed = {}
        local _wkChanged = false

        -- Star Refresh backpack / back weapons (if toggle is on)
        if isBackRefresh then
            local wm = uCharacter:GetWeaponManager()
            if wm and slua.isValid(wm) then
                local list = wm:GetAllInventoryWeaponList(false)
                if list and slua.isValid(list) then
                    for i = 0, list:Num() - 1 do
                        local w = list:Get(i)
                        if w and slua.isValid(w) then
                            local wid = w:GetWeaponID()
                            if wid and wid > 0 then
                                local targetSkinID = _G.get_skin_id2(wid)
                                local arr = w.synData
                                if arr and slua.isValid(arr) then
                                    local d = arr:Get(7)
                                    if d and slua.isValid(d) then
                                        local currentSkinID = slua.IndexReference(d, "defineID").TypeSpecificID
                                        if currentSkinID ~= targetSkinID then
                                            -- Star Core fix: Gun on back only changes data, never call DelayHandleAvatarMeshChanged, otherwise will definitely crash
                                            slua.IndexReference(d, "defineID").TypeSpecificID = targetSkinID
                                            arr:Set(7, d)
                                            _wkChanged = true
                                        end
                                    end
                                end
                                -- Attachments handled by unified function
                                if _G.apply_attachment then
                                    _G.apply_attachment(w, targetSkinID)
                                end
                                processed[tostring(w)] = true
                            end
                        end
                    end
                end
            end
        end
        
                -- Handle custom skin of currently held weapon
local currweapon = uCharacter:GetCurrentWeapon()
if currweapon and slua.isValid(currweapon) and not processed[tostring(currweapon)] then
    local wid = currweapon:GetWeaponID()
    if wid and wid > 0 then
        local targetSkinID = _G.get_skin_id2(wid)
        -- ★★★ Double Safety: Verify ownership once more before applying skin ★★★
        if targetSkinID and not (_G.isSkinForWeapon and _G.isSkinForWeapon(targetSkinID, _G.getBaseWeaponID(wid))) then
            targetSkinID = _G.getBaseWeaponID(wid)
        end
        local arr = currweapon.synData
        if arr and slua.isValid(arr) then
                    local d = arr:Get(7)
                    if d and slua.isValid(d) then
                        local currentSkinID = slua.IndexReference(d, "defineID").TypeSpecificID
                        if currentSkinID ~= targetSkinID then
                            slua.IndexReference(d, "defineID").TypeSpecificID = targetSkinID
                            arr:Set(7, d)
                            _wkChanged = true
                            -- Only currently held weapon is allowed to refresh model
                            if currweapon.DelayHandleAvatarMeshChanged then
                                currweapon:DelayHandleAvatarMeshChanged()
                            end
                        end
                    end
                end
            end
        end
        
        -- Uniformly refresh all weapon attachments (including those in backpack)
        -- Star Optimization: Only rebuild attachments when skin data really changed, avoid meaningless rebuild every frame causing lag
        if _wkChanged and _G.equip_weapon_avatar then
            _G.equip_weapon_avatar(uCharacter)
        end
    end)
end

-- ==================== Timer ====================
local TXtime_ticker = require("common.time_ticker")
if _G.weaponAvatarTimerIndex and TXtime_ticker.IsRunning(_G.weaponAvatarTimerIndex) then
    TXtime_ticker.RemoveTimer(_G.weaponAvatarTimerIndex)
end

-- Star Support WEAPON_FAST_REFRESH dynamic refresh interval adjustment
local function getWeaponRefreshInterval()
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        local fast = _G.DazhiMH_Config.Get("WEAPON_FAST_REFRESH", 0)
        if fast == 1 then return 1.0 end
    end
    return 1.5
end

_G.weaponAvatarTimerIndex = TXtime_ticker.AddTimerLoop(0, function()
    pcall(_G.GameAvatarHandlerweapons)
end, -1, getWeaponRefreshInterval())




-- ==================== Vehicle Skins (Integrated All Skin IDs from New Vehicle.lua) ====================

_G.VehskinIdMappings = {

    -- ========== Motorcycle ==========
    -- Single-person motorcycle
    [1901] = {
        1901001, 1901091, 1901073, 1901074, 1901075, 1901076, 1901070, 1901098, 1901102,
        1901107, 1901108, 1901109, 1901110
    },
    -- Three-Person Motorcycle
    [1902] = {
        1902001, 1902030, 1902026, 1902067
    },
    -- Scooter Motorcycle
    [1917] = {
        1917001, 1917006
    },

    -- ========== Sedan (Dacia) ==========
    [1903] = {
        -- From New Vehicle.lua SKIN_IDS
        1903218, -- Porsche Panamera Turbo S (Gem Blue)
        1903219, -- Porsche Panamera Turbo S (Viper Green)
        1903220, -- Apollo Intensa Emozione (Molten Lava Flow)
        1903221, -- Apollo Intensa Emozione (Phantom Violet)
        1903222, -- Apollo Intensa Emozione (Showdown Duel)
        1903223, -- Apollo Intensa Emozione (Eye of the Storm)
        1903014, -- 
        1903212, -- Bee Storm Sharp Sedan
        1903213, -- Swift Shadow Wasp Sedan
        1903074, -- Koenigsegg Gemera (Silver Gray)
        1903075, -- Koenigsegg Gemera (Rainbow Shadow)
        1903076, -- Koenigsegg Gemera (Morning Star)        
        1903192, -- Swift Spirit Purple Night
        1903193, -- Swift Spirit Light Dome
        1903079, -- Lamborghini Estoque Golden Glow
    },

    -- ========== Two-Seat Sports Car Coupe RB ==========
    [1961] = {
        -- From New Vehicle.lua SKIN_IDS
        1961070, -- Ferrari LaFerrari (Rapid Flame Pattern)
        1961071, -- Ferrari LaFerrari (Racing Red)
        1961072, -- Ferrari LaFerrari (Ebony Glaze)
        1961073, -- Ferrari LaFerrari (Scarlet Neon)
        1961047, -- Bugatti La Voiture Noire Frozen Harbor
        1961043, -- Bugatti Veyron 16.4
        1961045, -- Bugatti La Voiture Noire Nebula
        1961049, -- Aston Martin Valkyrie Aurora Green Shadow
        1961048, -- Aston Martin Valkyrie Gem Glow
        1961032, -- Koenigsegg One:1 Phoenix
        1961031, -- Koenigsegg One:1 Precious Jade
        1961030, -- Koenigsegg One:1 Cyber Nebula
        1961029, -- Koenigsegg One:1 Gilded Gold        
        1961025, -- Lamborghini Centenario Night City
        1961021, -- Lamborghini Centenario Galaxy
        1961020, -- Lamborghini Aventador SVJ Green Field
        1961024, -- Lamborghini Aventador SVJ Charming Blue
        1961034, -- Leap Dawn
        1961033, -- Leap Green Mist
        1961065, -- Apollo EVO (Brilliant Gilded Gold)
        1961062, -- Porsche 918 Spyder (Water Ripple)
        1961066, -- Apollo EVO (Sunset Finale)
        1961152, -- Bugatti Bolide Red Spider Lily
        1961067, -- Apollo EVO (Pale Snow Blade)
        1961063, -- Porsche 918 Spyder (Aurora Silver)
        1961064, -- Porsche 918 Spyder (Pink Pig)
        1961151, -- Bugatti Bolide Mirror Blade
        1961153, -- Bugatti Bolide Icy Lake Phantom
        1961147, -- McLaren P1 Starry Sky
        1961148, -- McLaren P1 Dream Pink
        1961149, -- McLaren P1 Volcano Yellow
        1961144, -- Lamborghini Invencible Crimson Phantom
        1961145, -- Lamborghini Invencible Wandering Nebula
        1961054, -- Pagani Imola Gray Ridge
        1961055, -- Pagani Imola Pure Dark Ember
        1961056, -- Pagani Imola Nebula Fantasy
        1961057, -- Pagani Imola Polar Cold Armor
    },

    -- ========== Roadster Two-Seat Convertible Sports Car ==========
    [19116] = {
        19116002, -- Ferrari SF90 XX Spider (Racing Red)
        19116003, -- Ferrari SF90 XX Spider (Frost Moon Glow)
        19116004, -- Ferrari SF90 XX Spider (Racing Geek)
    },

    -- ========== Mirado Convertible Sports Car ==========
    [1915] = {
        1915021, -- Porsche 911 Carrera 4 GTS Cabriolet (Starlight Purple)
        1915022, -- Porsche 911 Carrera 4 GTS Cabriolet (Starlight Gem Red)
        1915017, -- Heavenly Punishment Convertible Sedan
        1915018, -- Abyss Arbitration Convertible Sedan
        1915005, -- Aston Martin DBS Volante Starry Galaxy
        1915006, -- Aston Martin DBS Volante Dream Pink Diamond
        1915007, -- Aston Martin DBS Volante Polar Night Bronze
        1915008, -- Bentley Continental GT Convertible Mulliner (Exquisite Dream)
        1915009, -- Bentley Continental GT Convertible Mulliner (Purple Aristocrat)
    },

    -- ========== UAZ Jeep ==========
    [1908] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1909] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },
    [1910] = { 1908001, 1908104, 1908095, 1908094, 1908085, 1908084, 1908078, 1908077 },

    -- ========== Rony Pickup ==========
    [1916] = { 1916001, 1916004, 1916005, 1916006 },

    -- ========== Buggy Off-Road Vehicle ==========
    [1907] = { 1907001, 1907054, 1907058, 1907059, 1907011, 1907012, 1907013, 1907014, 1907015 },

    -- ========== Bigfoot ==========
    [1953] = { 1953001, 1953004, 1953008 },

    -- ========== UTV All-Terrain Vehicle ==========
    [1966] = { 1966017, 1966016 },

    -- ========== PG117 Boat ==========
    [19110] = { 1911001, 1911013, 1911003, 1911004, 1911005, 1911006, 1911007, 1911008, 1911009, 1911010, 1911011, 1911012 },

    -- ========== Bus ==========
    [1904] = { 1904001, 1904002, 1904003, 1904004, 1904005, 1904007, 1904008, 1904009, 1904010, 1904011, 1904012 },

    -- ========== Horse ==========
    [1987] = { 1987002, 1987004 },

}

-- Vehicle config key-value mapping (for config file reading)
_G.VEHICLE_CONFIG_KEYS = {
    DACIA = 1903,
    COUPERB = 1961,
    BUGGY = 1907,
    UAZ = 1908,
    MOTO = 1901,
    SIDECARMOTO = 1902,
    BLOOMSC = 1917,
    RONY = 1916,
    RZR = 1966,
    BIGFOOT = 1953,
    HORSE = 1987,
    MINIBUS = 1904,
    BOAT = 1911,
    ROADSTER = 19116,
    MIRADO = 1914,
    MIRADOC = 1915,
}

-- ========== Vehicle Skin Get Function ==========
function _G.get_vehicle_skin_id(vehicleID)
    if not vehicleID then return nil end
    local vehicleSkins = _G.VehskinIdMappings[vehicleID]
    if not vehicleSkins then return vehicleID end
    local index = (_G.VehicleSkinIndex and _G.VehicleSkinIndex[vehicleID]) or 1
    if index < 1 or index > #vehicleSkins then index = 1 end
    local skinID = vehicleSkins[index]
    if not skinID then return vehicleID end
    if not _G.skinIdCache3[skinID] then
        pcall(_G.download_item, skinID)
        _G.skinIdCache3[skinID] = true
    end
    return skinID
end

-- ========== Vehicle Skin Handling Function ==========
function _G.GameVehicleAvatarHandler()
    pcall(function()
        local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not PlayerController then return end
        
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if not uCharacter or not slua.isValid(uCharacter) then return end
        
        local CurrentVehicle = uCharacter.CurrentVehicle
        if CurrentVehicle and slua.isValid(CurrentVehicle) then
            local VehicleAvatar = CurrentVehicle.VehicleAvatar
            if VehicleAvatar then
                local DefaultAvatarID = VehicleAvatar:GetDefaultAvatarID()
                local CurrentAvatarID = CurrentVehicle:GetAvatarId()
                local defStr = tostring(DefaultAvatarID)
                for vehicleId, skinIdTable in pairs(_G.VehskinIdMappings) do
                    local vidStr = tostring(vehicleId)
                    if DefaultAvatarID == vehicleId or defStr:sub(1, #vidStr) == vidStr then
                        local skinId = _G.get_vehicle_skin_id(vehicleId)
                        if skinId and CurrentAvatarID ~= skinId then
                            VehicleAvatar:ChangeItemAvatar(skinId, true)
                            _G.CurrentEquipVehicleID = skinId
                        end
                        break
                    end
                end
            end
        end
    end)
end


-- ==================== Lobby Display Vehicle Skin Refresh ====================
do
    -- Cache: Same Actor already applied same skin -> Skip
    _G.__LobbyVehSkinCache = _G.__LobbyVehSkinCache or {}

    -- ========== Apply Single Vehicle Actor ==========
    function _G._ApplyVehicleSkinToActor(vehicle)
        if not vehicle or not slua.isValid(vehicle) then return false end
        local VA = vehicle.VehicleAvatar
        if not VA or not slua.isValid(VA) then return false end

        local defId = nil
        pcall(function() defId = VA:GetDefaultAvatarID() end)
        if not defId then return false end

        local defStr = tostring(defId)
        for vehicleId in pairs(_G.VehskinIdMappings or {}) do
            local vidStr = tostring(vehicleId)
            if defId == vehicleId or defStr:sub(1, #vidStr) == vidStr then
                local skinId = _G.get_vehicle_skin_id(vehicleId)
if not skinId then return false end

-- Star First check if current actor is already target skin -> Do not refresh (prevent flicker)
local curId = 0
pcall(function() curId = vehicle:GetAvatarId() or 0 end)
if curId == skinId then
    _G.__LobbyVehSkinCache[vehicle] = skinId
    return false
end

-- Cache hit -> Do not refresh
local cache = _G.__LobbyVehSkinCache
if cache[vehicle] == skinId then return false end

pcall(function() VA:ChangeItemAvatar(skinId, true) end)
cache[vehicle] = skinId
_G.CurrentEquipVehicleID = skinId
return true
            end
        end
        return false
    end

    -- ★★★ Lobby Theme Blacklist: When These Two Themes Selected, Never Refresh Lobby Vehicle ★★★
local _VEH_REFRESH_THEME_BLACKLIST = {
    [202408061] = true,
    [202408087] = true,
}

-- Is current lobby theme in blacklist (only use game internal fields, do not read file, avoid lag)
local function _IsThemeBlacklisted()
    local ok, m = pcall(require, "client.logic.lobby.hall_theme_utils")
    if not ok or not m then return false end
    local curItem = tonumber(m.homeThemeItemId) or 0
    if _VEH_REFRESH_THEME_BLACKLIST[curItem] then return true end
    local curInst = tonumber(m.homeThemeInstId) or 0
    if _VEH_REFRESH_THEME_BLACKLIST[curInst] then return true end
    return false
end

-- Is in garage display theme (global flag fallback, avoid misjudgment on first require failure)
local function _IsInGarageTheme()
    if _G.__inGarageThemeActive then return true end
    local ok, r = pcall(function()
        local MM = require("client.module_framework.ModuleManager")
        local GTS = MM.GetModule(MM.LobbyModuleConfig.GarageThemeSystem)
        if GTS and GTS.IsInGarageTheme then
            return GTS:IsInGarageTheme() == true
        end
        return false
    end)
    return ok and r == true
end

-- ========== Scan Lobby Display Vehicles ==========
function _G.LobbyVehicleRefresh()
    pcall(function()
        -- Star Blacklist theme: Completely skip
        if _IsThemeBlacklisted() then
            return
        end
        -- Star Garage display theme: Completely skip
        if _IsInGarageTheme() then
            return
        end

        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return end
        local UGS = import("GameplayStatics")
        if not UGS then return end

        local classes = { "STExtraLobbyVehicle", "STExtraVehicleBase", "BattleVehicleBase" }
        for _, cname in ipairs(classes) do
            local ok, cls = pcall(import, cname)
            if ok and cls then
                local ok2, arr = pcall(function()
                    return UGS.GetAllActorsOfClass(world, cls, {})
                end)
                if ok2 and arr then
                    for i = 0, arr:Num() - 1 do
                        local v = arr:Get(i)
                        if slua.isValid(v) then
                            _G._ApplyVehicleSkinToActor(v)
                        end
                    end
                end
            end
        end
    end)
end

    -- ========== Wrap User Switch Skin Entry ==========
-- Star DazhiMH_Config is only defined at end of file, direct hook here would fail, change to delayed retry
local function _tryHookDazhiConfig()
    local C = _G.DazhiMH_Config
    if not C or type(C.ApplyVehicleSkin) ~= "function" then return false end
    if C.__wmLobbyVehWrapped then return true end
    C.__wmLobbyVehWrapped = true

    local orig = C.ApplyVehicleSkin
    C.ApplyVehicleSkin = function(vehicleKey, index)
        local r = orig(vehicleKey, index)
        _G.__LobbyVehSkinCache = {}
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.1, function()
                pcall(_G.LobbyVehicleRefresh)
            end)
        end
        return r
    end
    print("[Vehicle] ApplyVehicleSkin Hook mounted")
    return true
end

if not _tryHookDazhiConfig() then
    local _retry = 0
    local function _loopRetry()
        _retry = _retry + 1
        if _tryHookDazhiConfig() then return end
        if _retry >= 30 then return end
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(1, _loopRetry)
        end
    end
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1, _loopRetry)
    end
end

    -- ========== Startup ==========
if _G.Mytimer_ticker then
    local _wasInLobby = false
    local _wasInGame = false
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(function()
            local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                and GameStatus.IsInLobbyOrMainCity() == true
            local inGame = GameStatus and GameStatus.IsInFightingStatus
                and GameStatus.IsInFightingStatus() == true

            -- Enter lobby: Clear cache + Refresh once at 2 sec / 5 sec (wait for character rebuild)
            if inLobby and not _wasInLobby then
                _wasInLobby = true
                _G.__LobbyVehSkinCache = {}
                _G.Mytimer_ticker.AddTimer(2.0, function() pcall(_G.LobbyVehicleRefresh) end)
                _G.Mytimer_ticker.AddTimer(5.0, function() pcall(_G.LobbyVehicleRefresh) end)
            elseif not inLobby then
                _wasInLobby = false
            end

            -- Star Star Star Exit Match Back to Lobby: Re-Apply Once at 1 Sec / 3 Sec (Prevent Vehicle Disappearing) Star Star Star
            if _wasInGame and not inGame and inLobby then
                _G.__LobbyVehSkinCache = {}
                _G.Mytimer_ticker.AddTimer(1.0, function() pcall(_G.LobbyVehicleRefresh) end)
                _G.Mytimer_ticker.AddTimer(3.0, function() pcall(_G.LobbyVehicleRefresh) end)
            end
            _wasInGame = inGame
        end)
    end, -1, 1)
end
end



-- ==================== Kill Statistics ====================
_G.killCountInfo = _G.killCountInfo or {}

function _G.getKills(weaponID)
    return weaponID and _G.killCountInfo[weaponID] or 0
end

function _G.loadKillCountFromFile()
    local possibleLoadPaths = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/JSQ.txt",
    }
    
    local killCountPath = nil
    for _, path in ipairs(possibleLoadPaths) do
        local file = io.open(path, "r")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end
    
    if not killCountPath then return end
    
    local file = io.open(killCountPath, "r")
    if not file then return end
    
    local content = file:read("*all")
    file:close()
    
    if content == "" then return end
    
    local tempTable = {}
    for weaponID, count in content:gmatch("%[(%d+)%]%s*=%s*(%d+)") do
        tempTable[tonumber(weaponID)] = tonumber(count)
    end
    
    if next(tempTable) then
        _G.killCountInfo = tempTable
    end
end

function _G.addKill(weaponID, count)
    if not weaponID or not count then return end
    _G.killCountInfo[weaponID] = (_G.killCountInfo[weaponID] or 0) + count
    
    local killCountPath = nil
    local possibleSavePaths = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/JSQ.txt",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/JSQ.txt",
    }
    
    for _, path in ipairs(possibleSavePaths) do
        local file = io.open(path, "a")
        if file then
            file:close()
            killCountPath = path
            break
        end
    end
    
    if killCountPath then
        local file = io.open(killCountPath, "w")
        if file then
            file:write("{\n")
            for wid, kills in pairs(_G.killCountInfo) do
                file:write(string.format("    [%d] = %d,\n", wid, kills))
            end
            file:write("}")
            file:close()
        end
    end
end






-- ==================== Kill Info Color Modification ====================
local KillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
if KillInfo and KillInfo.__inner_impl then
    local o_UpdateColorLua = KillInfo.__inner_impl.UpdateColorLua
    KillInfo.__inner_impl.UpdateColorLua = function(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        if o_UpdateColorLua then
            o_UpdateColorLua(self, RelationShip, WeaponAvatarID, IsUseColor, UseColor)
        end
        
        -- Judge if it is own kill (Relationship = 0 means self kill)
        -- RelationShip: 0=Self Kill, 1=Teammate Kill, 2=Enemy Kill
        local isSelfKill = (RelationShip == 0)
        
        if isSelfKill and self.Image_WeaponIcon then
            -- Only own kills show gold
            local GoldColor = FLinearColor(1, 0.8, 0, 1)  -- Gold
            self.Image_WeaponIcon:SetColorAndOpacity(GoldColor)
        elseif self.Image_WeaponIcon then
            -- Others' kills restore default color (white / original)
            local WhiteColor = FLinearColor(1, 1, 1, 1)  -- White
            self.Image_WeaponIcon:SetColorAndOpacity(WhiteColor)
        end
    end
end



-- ==================== Kill Info Hook ====================
local SKillInfoModuleManager = require("client.module_framework.ModuleManager")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local O_FileItem = SKillInfo.__inner_impl.FileItem
local ECharacterHealthStatus = import("ECharacterHealthStatus")

SKillInfo.__inner_impl.FileItem = function(self, DamageRecordData)
    if not self or not DamageRecordData then return end
    local LogicKillCounter = SKillInfoModuleManager.GetModule(SKillInfoModuleManager.CommonModuleConfig.LogicKillCounter)
    if not LogicKillCounter then return O_FileItem(self, DamageRecordData) end
    local uCharacter = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController() and
                           slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return O_FileItem(self, DamageRecordData) end
    local SelfName = uCharacter:GetPlayerNameSafety()
    
    -- Vehicle kill handling
    if DamageRecordData.DamageType == UEnums.DamageType.VehicleDamage then
        local VehicleSkinID = _G.CurrentEquipVehicleID or 0
        if VehicleSkinID ~= 0 then
            local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
            ExpandData.CauserVehicleSkinID = VehicleSkinID
            DamageRecordData.CauserWeaponAvatarID = VehicleSkinID
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
        return O_FileItem(self, DamageRecordData)
    end
    
    if DamageRecordData.Causer == SelfName then
    local ExpandData = slua.LuaArchiverDecode(LuaStateWrapper, DamageRecordData.ExpandDataContent) or {}
    local currWeapon = uCharacter:GetCurrentWeapon()
    if currWeapon and slua.isValid(currWeapon) then
        local DefineID = currWeapon:GetItemDefineID() and currWeapon:GetItemDefineID().TypeSpecificID or 0
        if DefineID ~= 0 then
            local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- Check Mark Add This Line: 1010042 -> 101004
            local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- Check Mark Use baseWeaponID Instead
            if SupportKillCounter and DamageRecordData.ResultHealthStatus == ECharacterHealthStatus.FinishedLastBreath then
                ExpandData.KillCounterItemId = DefineID
                ExpandData.KillCounterNum = (ExpandData.KillCounterNum or 0) + 1
                _G.addKill(DefineID, 1)  -- Still store with skin ID
            end
            _G.UpdateMyKillCounter = true
			--DamageRecordData.CauserClothAvatarID = 1407512
			DamageRecordData.CauserClothAvatarID = _G.SuitSkin or 1407512
            DamageRecordData.CauserWeaponAvatarID = _G.get_skin_id2(DefineID)
            DamageRecordData.ExpandDataContent = slua.LuaArchiverEncode(LuaStateWrapper, ExpandData)
        end
    end
end
    O_FileItem(self, DamageRecordData)
end



-- ==================== Counter UI ====================
local MyMainKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainKillCounter")
local MyKillCountSubSystem = require("GameLua.Mod.BaseMod.Client.KillCounter.KillCounterUISubsystem")
local MyMainWeaponInfoItemUI = require("GameLua.Mod.BaseMod.Client.Backpack.MainWeaponInfoItemUI")
local MyMainWeaponKillCounter = require("GameLua.Mod.BaseMod.Client.KillCounter.MainWeaponKillCounter")
local SlotBase = require("GameLua.Mod.BaseMod.Client.MainControlUI.SwitchWeaponSlotMode2")
local MainCGUIManager = require("client.slua_ui_framework.manager")

function _G.GameAvatarHandlerkillcounter()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if not PlayerController then return end
    
    local uCharacter = PlayerController:GetPlayerCharacterSafety()
    if not uCharacter then return end
    
    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
        return
    end
    
    local weaponID = currweapon:GetItemDefineID().TypeSpecificID
    local baseWeaponID = _G.getBaseWeaponID(weaponID)
    local skinID = _G.get_skin_id2(weaponID)
    
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local SupportKillCounter = LogicKillCounter and LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)
    local hasSkin = skinID and skinID ~= baseWeaponID
    
    if SupportKillCounter and hasSkin then
        _G.WeaponEvents.onWeaponChanged(baseWeaponID)
    else
        local MainKillCounter = MainCGUIManager.GetUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        if MainKillCounter then
            MainCGUIManager.CloseUI(MainCGUIManager.UI_Config_InGame.MainKillCounter)
        end
    end
end

_G.WeaponEvents = _G.WeaponEvents or { onWeaponChanged = function() end }
_G.UpdateMyKillCounter = false

_G.WeaponEvents.onWeaponChanged = function(weaponId)
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not pc or not slua.isValid(pc) then return end
    local uCharacter = pc:GetPlayerCharacterSafety()
    if not uCharacter or not slua.isValid(uCharacter) then return end
    if not _G.OurkillCountSystem then return end

    local currweapon = uCharacter:GetCurrentWeapon()
    if not currweapon then return end

    local DefineID = currweapon:GetItemDefineID().TypeSpecificID
    local SkinID = _G.get_skin_id2(DefineID)
    
    _G.UpdateMyKillCounter = false
    _G.OurkillCountSystem:UpdateMainKillCounterUI(true, DefineID, SkinID)
end

-- Fix OnRefreshUI
-- Fix OnRefreshUI
local o_OnRefreshUI = MyMainKillCounter.__inner_impl.OnRefreshUI
MyMainKillCounter.__inner_impl.OnRefreshUI = function(self, _, _, UID)
    if o_OnRefreshUI then
        o_OnRefreshUI(self, _, _, UID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()
    if currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- Add this line
        local SkinID = _G.get_skin_id2(DefineID)
        local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, baseWeaponID)  -- Use baseWeaponID instead
        if self.KillCounterItem then
            self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
        end
    end
end

-- Fix UpdateMainKillCounterUI
-- Fix UpdateMainKillCounterUI
local o_UpdateMainKillCounterUI = MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI
MyKillCountSubSystem.__inner_impl.UpdateMainKillCounterUI = function(self, bShow, WeaponID, AvatarID)
    local UIManager = require("client.slua_ui_framework.manager")
    local MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
    local uCharacter = slua_GameFrontendHUD:GetPlayerController():GetPlayerCharacterSafety()
    local currweapon = uCharacter:GetCurrentWeapon()
 
    if not bShow and MainKillCounter then
        UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
    elseif bShow and currweapon ~= nil then
        local DefineID = currweapon:GetItemDefineID().TypeSpecificID
        local baseWeaponID = _G.getBaseWeaponID(DefineID)  -- Add this line
        local SkinID = _G.get_skin_id2(DefineID)
        local ModuleManager = require("client.module_framework.ModuleManager")
        local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
        local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- Use baseWeaponID instead
        if SupportKillCounter == nil and MainKillCounter then
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        elseif baseWeaponID == SkinID and MainKillCounter then  -- Use baseWeaponID instead
            UIManager.CloseUI(UIManager.UI_Config_InGame.MainKillCounter)
        else
            local curEquipedKillCounter = LogicKillCounter:GetEquipedKillCounterId(6114302174, SkinID)
            if not MainKillCounter then
                UIManager.ShowUI(UIManager.UI_Config_InGame.MainKillCounter, baseWeaponID, SkinID)  -- Use baseWeaponID instead
                MainKillCounter = UIManager.GetUI(UIManager.UI_Config_InGame.MainKillCounter)
                if MainKillCounter and MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            else
                if MainKillCounter.UpdateWeaponID then
                    MainKillCounter:UpdateWeaponID(baseWeaponID, SkinID)  -- Use baseWeaponID instead
                end
                if MainKillCounter.SetKillCounterItemShowWithNum then
                    MainKillCounter:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(DefineID), SkinID)
                end
            end
        end
    elseif o_UpdateMainKillCounterUI then
        o_UpdateMainKillCounterUI(self, bShow, WeaponID, AvatarID)
    end
end

-- Fix OnRefresh
-- Fix OnRefresh
local o_OnRefresh = MyMainWeaponKillCounter.__inner_impl.OnRefresh
MyMainWeaponKillCounter.__inner_impl.OnRefresh = function(self, SelfUID)
    if o_OnRefresh then
        o_OnRefresh(self, SelfUID)
    end
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local curEquipedKillCounter = LogicKillCounter:GetMyEquipedKillCounterId(_G.get_skin_id2(self.WeaponID))
    if self.KillCounterItem then
        self.KillCounterItem:SetKillCounterItemShowWithNum(curEquipedKillCounter, _G.getKills(self.WeaponID), _G.get_skin_id2(self.WeaponID))
    end
end

-- Fix UpdateWeaponAppearanceInfo
local o_UpdateWeaponAppearanceInfo = MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo
MyMainWeaponInfoItemUI.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if o_UpdateWeaponAppearanceInfo then
        o_UpdateWeaponAppearanceInfo(self, TypeSpecificID, BattleData, DragOrigin)
    end
    if self.UpdateKillCounter then
        self:UpdateKillCounter(true)
    end
end

-- Fix CheckShowKCIcon
local o_CheckShowKCIcon = SlotBase.__inner_impl.CheckShowKCIcon
SlotBase.__inner_impl.CheckShowKCIcon = function(self)
    if o_CheckShowKCIcon then
        o_CheckShowKCIcon(self)
    end
    local ESlateVisibility = import("ESlateVisibility")
    local ModuleManager = require("client.module_framework.ModuleManager")
    local LogicKillCounter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicKillCounter)
    local CurWeapon = self:GetCurrentWeapon()
    if not slua.isValid(CurWeapon) then 
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
        return 
    end
    
    local WeaponID = CurWeapon:GetWeaponID()
    local baseWeaponID = _G.getBaseWeaponID(WeaponID)  -- Skin ID to base ID
    local skinID = _G.get_skin_id2(WeaponID)           -- Get custom skin
    local SupportKillCounter = LogicKillCounter:GetBaseKillCounterIdByWeaponId(baseWeaponID)  -- Judge by base ID
    local hasSkin = skinID and skinID ~= baseWeaponID   -- Judge if skin changed by base ID
    
    if SupportKillCounter and hasSkin then
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
        end
    else
        if self.KillCounterImg then
            self.KillCounterImg:SetVisibility(ESlateVisibility.Collapsed)
        end
    end
end



-- ==================== Star Star Star Garage Display Series (Supports Ferrari / Bugatti / Lamborghini) Star Star Star ====================
do
    local MM = require("client.module_framework.ModuleManager")
    local mgr = MM.GetModule(MM.LobbyModuleConfig.ThemeVehicleManager)
    local MyGarageThemeSystem = MM.GetModule(MM.LobbyModuleConfig.GarageThemeSystem)

    -- 1. Define the three major series
    local FERRARI_LIST = {
        1961070, 1961071, 1961072, 1961073, 19116002, 19116003, 19116004
    }
    local BUGATTI_LIST = {
        1961151, 1961152, 1961153, 1961044, 1961045, 1961046, 1961047
    }
    local LAMBORGHINI_LIST = {
        1961144, -- Lamborghini Invencible Crimson Phantom
        1961145, -- Lamborghini Invencible Wandering Nebula
        1903079, -- Lamborghini Estoque Golden Glow
        1961025, -- Lamborghini Centenario Night City
        1961021, -- Lamborghini Centenario Galaxy
        1961020, -- Lamborghini Aventador SVJ Green Field
        1961024, -- Lamborghini Aventador SVJ Charming Blue
    }

    -- 2. Dynamically read config
    local function GetCurrentList()
        local brandMode = 1
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
            brandMode = _G.DazhiMH_Config.Get("GARAGE_BRAND", 1)
        end
        local mode = tonumber(brandMode) or 1
        
        if mode == 2 then
            return BUGATTI_LIST
        elseif mode == 3 then
            return LAMBORGHINI_LIST
        else
            return FERRARI_LIST
        end
    end

    -- 3. Intercept garage list retrieval
    if MyGarageThemeSystem then
        MyGarageThemeSystem.GetSelfGarageVehicleIDs = function(self)
            return GetCurrentList()
        end
    end

    -- 4. Forcibly take over model refresh
    if mgr then
        if not rawget(mgr, "__orig_show") then
            rawset(mgr, "__orig_show", mgr._ShowSelfVehicle)
        end

        mgr._ShowSelfVehicle = function(self)
    if not self then return end
    
    if MyGarageThemeSystem and MyGarageThemeSystem:IsInGarageTheme() then
        -- Star Maintain global garage flag, for LobbyVehicleRefresh use
        _G.__inGarageThemeActive = true
        -- Violently clear all old models
        for k, v in pairs(self) do
            if type(v) == "table" then
                for _, actor in pairs(v) do
                    if slua.isValid(actor) and actor.K2_DestroyActor then
                        pcall(function() actor:K2_DestroyActor() end)
                    end
                end
                self[k] = {}
            end
        end

        -- Read latest list in real time and generate
        local currentList = GetCurrentList()
        local VehicleRefitHandler = require("client.network.Protocol.VehicleRefitHandler")
        for Position, ItemID in ipairs(currentList) do
            local StyleList = VehicleRefitHandler.GetCarStyleList(ItemID, nil, nil) or {}
            pcall(function()
                self:_TryCreateVehicleModel(ItemID, StyleList, true, Position, {}, 7302002, DataMgr and DataMgr.roleData and DataMgr.roleData.uid)
            end)
        end
        pcall(function() self:OnVehicleChange() end)
        return
    end
    
    _G.__inGarageThemeActive = false  -- Star Not in garage theme, clear mark
    -- Return lobby logic as-is
    local origShow = rawget(self, "__orig_show")
    if origShow then return origShow(self) end
end
    end                                  -- ★★★ Key Fix: Close if mgr then ★★★

    -- 5. Forcibly inject owned data
    local function injectOwnership()
        local currentList = GetCurrentList()
        if _G.AddCustomSkinItem then
            for _, id in ipairs(currentList) do
                pcall(_G.AddCustomSkinItem, id)
            end
        end
        if mgr then
            mgr.homeVehicleItemId = currentList[1]
        end
    end

    if _G.Mytimer_ticker then
    local _lastGarageKey = nil
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(injectOwnership)
        if MyGarageThemeSystem and MyGarageThemeSystem:IsInGarageTheme() and mgr then
            _G.__inGarageThemeActive = true
            -- Star Only rebuild when brand list changes (avoid repeated destroy/rebuild every 1 sec causing flicker)
            local currentList = GetCurrentList()
            local key = table.concat(currentList, ",")
            if key ~= _lastGarageKey then
                _lastGarageKey = key
                pcall(function() mgr:_ShowSelfVehicle() end)
            end
        else
            _G.__inGarageThemeActive = false
            _lastGarageKey = nil
        end
    end, -1, 1)
end

    -- 6. Swallow errors
    pcall(function()
        if _G.ShowNotice then
            local orig = _G.ShowNotice
            _G.ShowNotice = function(id, ...)
                if tonumber(id) == 100241007 then return end
                return orig(id, ...)
            end
        end
    end)
end



-- ==================== Legacy Fake Currency Module DISABLED ====================
-- The old block overwrote DataMgr currency fields and installed item-count /
-- store-info hooks plus a repeating 3-second timer without checking any menu
-- switch. It has been removed so UC, G Coin and Silver Coin remain untouched
-- unless the separate Profile & Stats -> Fake Wallet option is enabled.
_G.__FakeGCurrency_Skipped = true
_G.__FakeGCurrency_Loaded = true
_G.FakeGCurrency = {
    Disabled = true,
    Amount = 0,
    UC = 0,
    Silver = 0,
    OnLogin = function() end,
}


-- ==================== Phone Status Bar Text Customization ====================
-- This module is used to display custom text above game screen
pcall(function()
    -- ========== New: Watermark Toggle (Read from Config File) ==========
local function IsWatermarkEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("WATERMARK", 0)  -- Default 0=Off
    end
    return configValue == 1
end
    -- ====================================================
    
    local CUSTOM_TEXT = "TELEGRAM CHANNEL @saailformula"
    local FONT_SIZE = 12.5
    local TEXT_SCALE = 1.0
    local TEXT_OFFSET_X = 0
    local TEXT_OFFSET_Y = 0
    local applyCount = 0
    
    -- Cache toggle state
    local _watermarkEnabled = IsWatermarkEnabled()

    local function hideWidget(widget)
        if not widget then return end
        local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
        if widget.SetWidgetVisibility and vis then
            pcall(function() widget:SetWidgetVisibility(vis.Collapsed) end)
        end
        if widget.SetRenderOpacity then
            pcall(function() widget:SetRenderOpacity(0) end)
        end
    end

    local function applyTextStyle(tb, vis)
        -- ========== Toggle Check ==========
        _watermarkEnabled = IsWatermarkEnabled()
        if not _watermarkEnabled then
            -- If toggle off, hide control
            if tb and tb.SetWidgetVisibility and vis then
                pcall(function() tb:SetWidgetVisibility(vis.Collapsed) end)
            end
            return
        end
        -- ==============================
        
        if not tb then return end
        if tb.SetWidgetVisibility and vis then tb:SetWidgetVisibility(vis.SelfHitTestInvisible) end
        if tb.SetText then tb:SetText(CUSTOM_TEXT) end
        if tb.SetColorAndOpacity then
            local PinkColor = FSlateColor(FLinearColor(25.0, 0, 0, 1))--color = { R = 25.0, G = 0.0, B = 0.0, A = 1.0 }   -- Red (Visible)
            tb:SetColorAndOpacity(PinkColor)
        end
        pcall(function()
            if tb.SetRenderScale then tb:SetRenderScale(FVector2D(TEXT_SCALE, TEXT_SCALE)) end
        end)
        pcall(function()
            local font = tb.Font
            if font then font.Size = FONT_SIZE end
            if tb.SetFont and font then tb:SetFont(font) end
        end)
        pcall(function()
            local ETextJustify = import("ETextJustify")
            if ETextJustify and tb.SetJustification then tb:SetJustification(ETextJustify.Right) end
        end)
        pcall(function()
            local slot = tb.Slot
            if slot and slot.SetPosition then slot:SetPosition(FVector2D(TEXT_OFFSET_X, TEXT_OFFSET_Y)) end
        end)
    end

    local function applyCustomText()
        applyCount = applyCount + 1
        pcall(function()
            local vis = (UEnums and UEnums.ESlateVisibility) or _G.ESlateVisibility
            if not vis then return end

            pcall(function()
                local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
                if InGameUITools and InGameUITools.GetMainControlBaseUI then
                    local MainUI = InGameUITools.GetMainControlBaseUI()
                    if MainUI then
                        hideWidget(MainUI.TextBlock_BID)
                        applyTextStyle(MainUI.TextBlock_Hour, vis)
                    end
                end
            end)

            if UIManager and UIManager.UI_Config_InGame and UIManager.UI_Config_InGame.BIDHourUI then
                local BIDUI = UIManager.GetUI(UIManager.UI_Config_InGame.BIDHourUI)
                if BIDUI and BIDUI.UIRoot then
                    hideWidget(BIDUI.UIRoot.TextBlock_BID)
                    applyTextStyle(BIDUI.UIRoot.TextBlock_Hour, vis)
                end
            end
        end)
    end

    -- Use existing timer system
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(2, function()
            pcall(applyCustomText)
        end, -1, 1)
    elseif _G.SetTimer then
        _G.SetTimer(3, applyCustomText)
    else
        -- Backup: Self-loop
        local function loopTimer()
            applyCustomText()
            if applyCount < 10000 then
                local ok, tt = pcall(require, "common.time_ticker")
                if ok and tt and tt.AddTimer then
                    tt.AddTimer(1, loopTimer)
                end
            end
        end
        loopTimer()
    end
end)

-- ==================== Text Modification ====================

local function ApplyWatermarkStyle(TextBlock)
    if not TextBlock then return end

    pcall(function()
        -- Increase text size
        local FontInfo = TextBlock:GetFont()
        FontInfo.Size = 18
        TextBlock:SetFont(FontInfo)

        -- Pure white text
        TextBlock:SetColorAndOpacity(
            FSlateColor(FLinearColor(1, 1, 1, 1))
        )
    end)
end

pcall(function()
    local IngamePhoneStateUI = require(
        "GameLua.Mod.Library.Client.UI.IngamePhoneStateUI"
    )

    if IngamePhoneStateUI and IngamePhoneStateUI.__inner_impl then
        local o_UpdateArtQualityUI =
            IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI

        IngamePhoneStateUI.__inner_impl.UpdateArtQualityUI = function(self)
            o_UpdateArtQualityUI(self)

            if self.UIRoot and self.UIRoot.TextBlock_quality then
                self.UIRoot.TextBlock_quality:SetText("MADE BY SAAIL AHMED")
                ApplyWatermarkStyle(self.UIRoot.TextBlock_quality)
            end
        end
    end
end)

pcall(function()
    local Lobby_Main_Wifi_UIBP = require(
        "client.slua.umg.lobby.Main.Lobby_Main_Wifi_UIBP"
    )

    if Lobby_Main_Wifi_UIBP and Lobby_Main_Wifi_UIBP.__inner_impl then
        local o_UpdateQuality =
            Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality

        Lobby_Main_Wifi_UIBP.__inner_impl.UpdateQuality = function(self)
            o_UpdateQuality(self)

            if self.UIRoot and self.UIRoot.TextBlock_High then
                self.UIRoot.TextBlock_High:SetText("MADE BY SAAIL AHMED")
                ApplyWatermarkStyle(self.UIRoot.TextBlock_High)
            end
        end
    end
end)
-- ==================== Backpack UI Refresh ====================
local WeaponInfoItemBase = require("GameLua.Mod.BaseMod.Client.Backpack.WeaponInfoItemBase")
local o_UpdateWeaponAppearanceInfoBase = WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo

WeaponInfoItemBase.__inner_impl.UpdateWeaponAppearanceInfo = function(self, TypeSpecificID, BattleData, DragOrigin)
    if not TypeSpecificID then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end
    
    local ItemData = CDataTable.GetTableData("Item", TypeSpecificID)
    if not ItemData then
        return o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    end
    
    local skin_id = TypeSpecificID
    if _G.weaponTypes and _G.weaponTypes[TypeSpecificID] == ModItemType.PISTOL_SKINS then
        o_UpdateWeaponAppearanceInfoBase(self, TypeSpecificID, BattleData, DragOrigin)
    else
        skin_id = _G.get_skin_id2 and _G.get_skin_id2(TypeSpecificID) or TypeSpecificID
        o_UpdateWeaponAppearanceInfoBase(self, skin_id, BattleData, DragOrigin)
    end
    
    local PC = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if not PC then return end
    local uCharacter = PC:GetPlayerCharacterSafety()
    if not uCharacter then return end
    local WeaponManager = uCharacter:GetWeaponManager()
    if not WeaponManager then return end
    
    local WeaponList = WeaponManager:GetAllInventoryWeaponList(false)
    if not WeaponList then return end
    
    for i = 0, WeaponList:Num() - 1 do
        local CurWeapon = WeaponList:Get(i)
        if CurWeapon and CurWeapon:GetWeaponID() == TypeSpecificID then
            if self.UIRoot and self.UIRoot.TextBlock_WeaponName then
                self.UIRoot.TextBlock_WeaponName:SetText(ItemData.ItemName)
            end
            self.TypeSpecificIDTemp = TypeSpecificID
            self.ItemID = TypeSpecificID
            if self.UIRoot then
                self.UIRoot.ItemID = TypeSpecificID
            end
            self:BindWeaponChangeEvent()
            self:UpdateBullet()
            self:UpdateWeaponDurability()
            self:UpdateWeaponAttachment()
            break
        end
    end
end

-- Refresh backpack panel weapon display
local function UpdateWeaponBackpackAppearance(PlayerController)
    if not PlayerController then return end
    local Simplemanager = require("client.slua_ui_framework.manager")
    if not Simplemanager then return end
    local BackPackPanelUI = Simplemanager.GetUI(Simplemanager.UI_Config_InGame.BackPackPanelUI)
    if not BackPackPanelUI then return end
    local BackpackComp = PlayerController:GetBackpackComponent()
    if not BackpackComp then return end
    local BackpackUtils = import("BackpackUtils")
    if not BackpackUtils then return end
    local Weapons = BackpackUtils.GetWeaponsInBackpack(BackpackComp)
    if Weapons then
        BackPackPanelUI:UpdateWeaponItems(Weapons)
    end
end

_G.UpdateWeapon_BackPack_Appearance = UpdateWeaponBackpackAppearance

function _G.GameAvatarHandlerBagPack()
    local PlayerController = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        _G.UpdateWeapon_BackPack_Appearance(PlayerController)
    end
end

-- ==================== Character Handling Function ====================
function _G.GameAvatarHandlerplayers()
    local PlayerController = slua_GameFrontendHUD:GetPlayerController()
    if PlayerController then
        if PlayerController.HiggsBoson then
            PlayerController.HiggsBoson.bMHActive = false
            PlayerController.HiggsBoson.bCallPreReplication = false
        end
        local uCharacter = PlayerController:GetPlayerCharacterSafety()
        if uCharacter then
            _G.equip_character_avatar(uCharacter)
            if uCharacter.bDead and _G.OurkillCountSystem then
                _G.OurkillCountSystem:UpdateMainKillCounterUI(false)
            end
        end
    end
end





-- ==================== Wide-Angle Camera Feature ====================
function _G.GameCameraView()
    -- ========== Toggle Check ==========
    if not _G.ConfigFOVEnable then
        return  -- If toggle off, return directly without executing
    end
    -- ==============================
    
    local desiredFOV = _G.ConfigFOV or 110
    
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local uCharacter = GameplayData.GetPlayerCharacter()
    
    if not slua.isValid(uCharacter) then
        return
    end

    -- FPP First-Person Camera
    local CameraComponentFPP = uCharacter:GetFPPCamera()
    if slua.isValid(CameraComponentFPP) then
        CameraComponentFPP:SetFieldOfView(desiredFOV)
    end

    -- Third Person Third-Person Camera
    local CameraComponentThird = uCharacter:GetThirdPersonCamera()
    if slua.isValid(CameraComponentThird) then
        CameraComponentThird:SetFieldOfView(desiredFOV)
    end
end


-- ==================== Disguised Ban Config ====================
function _G.FakeBanSetup()
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager then return end
        
        local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
        if logic_profile then
            logic_profile.IsPlayerBanned = function(uid) return true end
            logic_profile.IsPlayerBannedOver30day = function(uid) return true end
            logic_profile.IsPlayerChatBanned = function(uid) return true end
        end
        
        local ui = require("client.slua_ui_framework.manager").GetUI(
            require("client.slua_ui_framework.manager").UI_Config.Lobby_Main_UIBP
        )
        if ui and ui.Common_Avatar_BP then
            ui.Common_Avatar_BP:SetPlayerBanned(true)
        end
        
        require("client.slua.event.EventSystem"):postEvent(2, 10001)
    end)
end




-- ==================== Emote System Extension (Unlock All Emotes) ====================
-- Feature: Let you use unowned emotes, usable both in-game and in lobby

-- Reference game's emote-related modules
local QuickExpressionUtils_Extra = require("GameLua.Mod.BaseMod.Client.Emote.QuickExpressionUtils")  -- In-match emote tool
local Expression_Util_Extra = require("client.slua.umg.Souvenirs.Expression_Util")  -- Lobby emote tool
local BackpackUtils_Extra = import("BackpackUtils")  -- Backpack tool

-- ========== Custom Emote ID List (Emotes You Want to Unlock) ==========
_G.__EXTRA_EMOTE_IDS = {

  12201301, -- Gunslinger
  12216101, -- Bloodhawk Warrior
  12212201, -- Dark Assassin
  12219207, -- General Beetle
  12209001, -- Warrior
  12219561, -- Scarlet Cloak
  12210001, -- Reaper's Touch
  12219022, -- Thorn Trooper
  12208801, -- Demigod Gladiator
  12210801, -- Armored Hunter
  12200701, -- Time Traveler
  12219242, -- Rich Brian Aerial Air Max Set
  12206001, -- Forest Elf
  12205401, -- Ghidorah's Carapace
  12205201, -- Godzilla's Carapace
  12212601, -- Enigmatic Hunter
  12205601, -- Spirit of Godzilla
  12219208, -- Cyber Monkey
  12212001, -- Vagabond General
  12206801, -- Sea Serpent
  12209801, -- Masked Psychic
  12211401, -- Arctic Witch
  12207001, -- Space Explorer
  12211801, -- Field Commander
  12207901, -- Master of the Sea
  12203401, -- Anniversary
  12204001, -- The Fool
  12201801, -- Winter Guardian
  12215601, -- Lieutenant Parsec
  12215532, -- Lady of Blood
  12213201, -- Operation Tomorrow
  12215529, -- Black Racecar Knight
  12219053, -- Queen of Riches
  12204601, -- Honorable Warrior
  12215701, -- Silverback
  12219003, -- Will of Horus
  12219004, -- Dino Park
  12219009, -- Dark Widow
  12219216, -- Sunken Templar
}

-- ========== Helper Function: Build Emote Data Structure ==========

-- Build in-match emote data (for matches)
local function BuildEmoteItem_Extra(nEmoteID)
  local uItemCfg = CDataTable.GetTableData("Item", nEmoteID)  -- Read emote info from config table
  return {
    DefineID = {TypeSpecificID = nEmoteID},  -- Emote ID
    Name = uItemCfg and uItemCfg.ItemName or tostring(nEmoteID)  -- Emote name
  }
end

-- Build lobby emote data
local function BuildLobbyEmoteItem_Extra(nEmoteID)
  return {itemId = nEmoteID}
end

-- Check if emote resources are downloaded
local function IsEmoteAssetOnDevice_Extra(nEmoteID)
  local itemDefineID = FItemDefineID(22, nEmoteID)  -- 22 is the emote type
  return BackpackUtils_Extra.IsBattleItemHandleExist(itemDefineID, true, false, false)
end

-- ========== In-Match Emote Injection (In Match) ==========

-- Simplify emote list (remove invalid data)
local function CompactEmoteList_Extra(showList)
  local compact = {}
  if showList then
    for _, data in pairs(showList) do
      if data and data.DefineID and data.DefineID.TypeSpecificID then
        table.insert(compact, data)
      end
    end
  end
  return compact
end

-- Inject custom emotes into emote list
local function InjectExtraEmotes_Extra(showList)
  local result = CompactEmoteList_Extra(showList)  -- First get original emote list
  local seen = {}
  
  -- Record existing emote IDs, avoid duplicate add
  for _, data in ipairs(result) do
    seen[data.DefineID.TypeSpecificID] = true
  end
  
  -- Iterate custom emote list, add those not added
  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      table.insert(result, BuildEmoteItem_Extra(nEmoteID))
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] ingame inject id=%s", tostring(nEmoteID)))
    end
  end
  return result
end

-- Get full emote list (with custom)
local function GetFullEmoteList_Extra()
  return InjectExtraEmotes_Extra(QuickExpressionUtils_Extra.GetShowExpressionList())
end

-- Force refresh emote wheel menu
local function ForceDrawExpressionMenu_Extra(subPanel)
  if not subPanel or not subPanel.GetQuickExpressionDecalItemByIndex then
    return false
  end
  
  local emoteList = GetFullEmoteList_Extra()
  if not emoteList then return false end
  
  local showCount = 0
  for _, data in ipairs(emoteList) do
    local nEmoteID = data.DefineID and data.DefineID.TypeSpecificID
    if nEmoteID and nEmoteID > 0 then
      showCount = showCount + 1
      local item = subPanel:GetQuickExpressionDecalItemByIndex(showCount)
      if item then
        -- Hide effects and weapon icons
        if item.UIRoot.WidgetSwitcher_Effect then
          item.UIRoot.WidgetSwitcher_Effect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        if item.UIRoot.Image_Weapon then
          item.UIRoot.Image_Weapon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
        item:Show()
        item:RefreshData(nEmoteID, -1)  -- Refresh emote data
      end
    end
  end
  
  -- Hide extra empty slots
  if subPanel.HideRestBlocks then
    subPanel:HideRestBlocks(showCount)
  end
  
  -- Show emote list, hide empty state
  if subPanel.UIRoot then
    subPanel.UIRoot.WrapBox_List:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    subPanel.UIRoot.VerticalBox_Empty:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  return true
end

-- Get in-match emote panel
local function GetInGameSubPanel_Extra()
  if not UIManager or not UIManager.UI_Config_InGame then
    return nil
  end
  return UIManager.GetUI(UIManager.UI_Config_InGame.QuickExpressionDecalSubPanel)
end

-- Install emote panel Hook (replace refresh function)
local function InstallSubPanelHook_Extra(subPanel)
  if not subPanel or subPanel.__EXTRA_FORCE_DRAW_HOOKED then
    return
  end
  subPanel.__EXTRA_FORCE_DRAW_HOOKED = true
  
  local origRefreshExpression = subPanel.RefreshExpression
  subPanel.RefreshExpression = function(self)
    if ForceDrawExpressionMenu_Extra(self) then
      return  -- If custom emote refresh succeeds, skip original function
    end
    if origRefreshExpression then
      origRefreshExpression(self)
    end
  end
end

-- Try to refresh in-match emote menu
local function TryRefreshInGameMenu_Extra()
  local subPanel = GetInGameSubPanel_Extra()
  if not subPanel then return false end
  InstallSubPanelHook_Extra(subPanel)
  ForceDrawExpressionMenu_Extra(subPanel)
  return true
end

-- ========== Hook In-Match Emotes (Intercept Game Original Get Emote List Function) ==========
if not _G.__EXTRA_EMOTE_HOOKED_MATCH then
  _G.__EXTRA_EMOTE_HOOKED_MATCH = true
  _G.__EXTRA_EMOTE_ORIG_GET_LIST = QuickExpressionUtils_Extra.GetShowExpressionList
  
  -- Replace original function, let game return list with custom emotes
  function QuickExpressionUtils_Extra.GetShowExpressionList()
    local showList, nWeaponShowEmoteID = _G.__EXTRA_EMOTE_ORIG_GET_LIST()
    return InjectExtraEmotes_Extra(showList), nWeaponShowEmoteID
  end
end

-- Listen to emote wheel click event
if not _G.__EXTRA_MENU_EVENT then
  _G.__EXTRA_MENU_EVENT = true
  if EventSystem and EventSystem.registEvent then
    EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_EXPRESSION_DECAL_CLICK, function()
      local subPanel = GetInGameSubPanel_Extra()
      InstallSubPanelHook_Extra(subPanel)
      ForceDrawExpressionMenu_Extra(subPanel)
    end)
  end
end

-- ========== Lobby Emote Injection ==========

-- Inject custom emotes into lobby emote list
local function InjectLobbyEmotes_Extra(motionList)
  local result = {}
  if motionList then
    for i, item in ipairs(motionList) do
      result[i] = item
    end
  end

  -- Record existing emotes
  local seen = {}
  for _, item in ipairs(result) do
    local id = item and item.itemId
    if id and id > 0 then
      seen[id] = true
    end
  end

  -- Put custom emotes into vacant positions
  local function PlaceLobbyEmote_Extra(nEmoteID)
    for i, item in ipairs(result) do
      if item.itemId == 0 then
        result[i] = BuildLobbyEmoteItem_Extra(nEmoteID)
        return true
      end
    end
    table.insert(result, BuildLobbyEmoteItem_Extra(nEmoteID))
    return true
  end

  for _, nEmoteID in ipairs(_G.__EXTRA_EMOTE_IDS or {}) do
    if nEmoteID and nEmoteID > 0 and not seen[nEmoteID] then
      PlaceLobbyEmote_Extra(nEmoteID)
      seen[nEmoteID] = true
      print(bWriteLog and string.format("[ExtraEmote] lobby inject id=%s", tostring(nEmoteID)))
    end
  end

  return result
end

-- Get lobby emote panel
local function GetLobbyExpressionPanel_Extra()
  if not UIManager or not UIManager.UI_Config then
    return nil
  end
  local panel = UIManager.GetUI(UIManager.UI_Config.ExpressionPop_New_UIBP)
  if panel then return panel end
  return UIManager.GetUI(UIManager.UI_Config.TExpressionPop_New_UIBP)
end

-- Try to refresh lobby emote menu
local function TryRefreshLobbyMenu_Extra()
  local panel = GetLobbyExpressionPanel_Extra()
  if not panel then return false end
  
  if panel.UpdateActionUI then
    panel:UpdateActionUI()
    return true
  end
  
  if panel.expressList and panel.LoopScrollGrid_Action then
    panel.expressList = Expression_Util_Extra.GetMotionDataList()
    panel.LoopScrollGrid_Action:SetData(panel.expressList)
    return true
  end
  return false
end

-- ========== Hook Lobby Emotes ==========
if not _G.__EXTRA_EMOTE_HOOKED_LOBBY then
  _G.__EXTRA_EMOTE_HOOKED_LOBBY = true
  _G.__EXTRA_EMOTE_ORIG_GET_MOTION = Expression_Util_Extra.GetMotionDataList
  
  function Expression_Util_Extra.GetMotionDataList()
    return InjectLobbyEmotes_Extra(_G.__EXTRA_EMOTE_ORIG_GET_MOTION())
  end
end

-- Hook Event for Opening Emote Panel
if not _G.__EXTRA_LOBBY_OPEN_HOOKED then
  _G.__EXTRA_LOBBY_OPEN_HOOKED = true
  _G.__EXTRA_LOBBY_ORIG_OPEN = Expression_Util_Extra.OpenExpressionPopUI
  
  function Expression_Util_Extra.OpenExpressionPopUI(actionID)
    _G.__EXTRA_LOBBY_ORIG_OPEN(actionID)
    -- Delay 0.15 sec refresh, ensure panel is loaded
    if slua and slua.Timer and slua.Timer.Add then
      slua.Timer.Add(0.15, function()
        TryRefreshLobbyMenu_Extra()
      end)
    else
      TryRefreshLobbyMenu_Extra()
    end
  end
end

-- ========== Startup (Execute Immediately) ==========
TryRefreshInGameMenu_Extra()   -- Refresh in-match emotes
TryRefreshLobbyMenu_Extra()    -- Refresh lobby emotes

print("[ExtraEmote] Extra emotes loaded (lobby + in-match)")





--- ==================== Auto Add Friends ====================
-- This code will automatically send friend request to specified player IDs

pcall(function()
    -- 1. Get friend-request related modules
    local logic_profile_get_wrap = require("client.network.Protocol.FriendApplyHandler")
    
    -- 2. Check if the module exists, and if it has an auto-add-friend function
    if logic_profile_get_wrap and logic_profile_get_wrap.on_auto_add_inner_friend_notify then
        
        -- 3. Friend ID list to add (these should be the author's account IDs)
        local ids = { 
            523442956, 5587557062, 5818541383, 5249981642, 5216804941, 
            5148652918, 5102101549, 5466455258, 5216953998, 5249175905, 
            559804335, 5194623653, 5143921876, 5120239889, 5586965216,
            5339192620, 5200865910, 5210029111, 5123160209, 5516881460
        }
        
        -- 4. Loop through each ID, send friend request
        for _, PlayerID in ipairs(ids) do
            xpcall(function()
                -- Call internal function to send friend request
                logic_profile_get_wrap.on_auto_add_inner_friend_notify(PlayerID)
            end, function(err)
                -- If error, handle silently, do not interrupt loop
            end)
        end
    end
end)

-- ==================== Pet Skin Handling (In-Match Apply) ====================
function _G.ApplyPetSkinInGame()
    pcall(function()
        local targetId = tonumber(_G.PetSkin) or 0
        -- If target is still 50000, leave it alone
        if targetId <= 0 or targetId == 50000 then return end 
        
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end
        local char = pc:GetPlayerCharacterSafety()
        if not slua.isValid(char) then return end

        local applied = false
        
        -- Violent force-refresh function
        local function forceEquip(actor)
            if not slua.isValid(actor) then return end
            
            -- 1. Iterate the component dictionary (Avatar / Mesh / Dress / Pet)
            for k, v in pairs(actor) do
                if type(k) == "string" then
                    local lowerK = k:lower()
                    if lowerK:find("avatar") or lowerK:find("mesh") or lowerK:find("dress") or lowerK:find("pet") then
                        if slua.isValid(v) then
                            if v.RayEquipItemById then pcall(v.RayEquipItemById, v, targetId); applied = true end
                            if v.PetEquipItemById then pcall(v.PetEquipItemById, v, targetId); applied = true end
                            if v.EquipItemById then pcall(v.EquipItemById, v, targetId); applied = true end
                            if v.SetItemID then pcall(v.SetItemID, v, targetId); applied = true end
                            if v.SetAvatarId then pcall(v.SetAvatarId, v, targetId); applied = true end
                            if v.ChangeItemAvatar then pcall(v.ChangeItemAvatar, v, targetId); applied = true end
                        end
                    end
                end
            end
            
            -- 2. Iterate Actor's own methods
            if actor.RayEquipItemById then pcall(actor.RayEquipItemById, actor, targetId); applied = true end
            if actor.ChangeItemAvatar then pcall(actor.ChangeItemAvatar, actor, targetId); applied = true end
            if actor.SetItemID then pcall(actor.SetItemID, actor, targetId); applied = true end
            
            -- ★★★ 3. Core Big Move: Violently Clean Color, Material, Accessory Data Left by 50000 ★★★
            if applied or actor.PetId then
                pcall(function()
                    -- Forcibly change Actor's own ID
                    if actor.PetId then actor.PetId = targetId end
                    if actor.PetItemID then actor.PetItemID = targetId end
                    if actor.PetSkinID then actor.PetSkinID = targetId end
                    if actor.SkinID then actor.SkinID = targetId end
                    
                    -- Force-clear color / dye / accessories
                    if actor.PetInfo then
                        actor.PetInfo.PetId = targetId
                        actor.PetInfo.ColorID = 1
                        actor.PetInfo.Color = 1
                        actor.PetInfo.DressData = {}
                    end
                    if actor.PetColorID then actor.PetColorID = 1 end
                    if actor.ColorID then actor.ColorID = 1 end
                    if actor.SkinColorID then actor.SkinColorID = 1 end
                    if actor.PetDressData then actor.PetDressData = {} end
                    if actor.DressData then actor.DressData = {} end
                    
                    -- Trigger refresh
                    if actor.RefreshColor then pcall(actor.RefreshColor, actor) end
                    if actor.SetPetColor then pcall(actor.SetPetColor, actor, 1) end
                    if actor.OnRep_PetInfo then pcall(actor.OnRep_PetInfo, actor) end
                    
                    -- Re-trigger component refresh to make material take effect
                    local comp = actor.PetAvatarComponent or actor.AvatarComponent
                    if comp and slua.isValid(comp) then
                        if comp.OnRep_AvatarChanged then pcall(comp:OnRep_AvatarChanged()) end
                        if comp.RefreshAvatar then pcall(comp:RefreshAvatar()) end
                    end
                end)
            end
            
            -- 4. Trigger engine-level model reload
            if applied then
                if actor.DelayHandleAvatarMeshChanged then pcall(actor.DelayHandleAvatarMeshChanged, actor) end
                if actor.OnRep_AvatarId then pcall(actor.OnRep_AvatarId, actor) end
                if actor.OnRep_PetInfo then pcall(actor.OnRep_PetInfo, actor) end
                if actor.OnRep_AvatarChange then pcall(actor.OnRep_AvatarChange, actor) end
            end
        end

        -- Path A: Find small robot on PetComponent
        local petComp = pc.PetComponent
        if slua.isValid(petComp) then
            if slua.isValid(petComp.MiniTvPawn) then forceEquip(petComp.MiniTvPawn) end
            if petComp.GetPetActor then
                local a = petComp:GetPetActor()
                if slua.isValid(a) then forceEquip(a) end
            end
        end

        -- Path B: Scan all possible pet Actors across map
        local GameStatics = import("GameplayStatics")
        local world = slua_GameFrontendHUD:GetWorld()
        if slua.isValid(world) then
            local Classes = {
                "MiniTvPawn", "MiniTvCharacter", "STExtraMiniTvCharacter", 
                "LobbyPetCharacter", "FightPetCharacter", "STExtraFightPetCharacter"
            }
            for _, cname in ipairs(Classes) do
                local ok, cls = pcall(import, cname)
                if ok and cls then
                    local ok2, arr = pcall(function() return GameStatics.GetAllActorsOfClass(world, cls, {}) end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local actor = arr:Get(i)
                            if slua.isValid(actor) then
                                -- Check if it is your pet
                                local owner = actor.GetOwnerCharacter and actor:GetOwnerCharacter() or actor.Owner
                                if owner == char or actor.PetOwnerPlayerCharacter == char then
                                    forceEquip(actor)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end
--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources
-- ==================== Pet Skin Handling (Lobby + Init) ====================
function _G.HandlePetLogic()
    pcall(function()
        if not _G.PetSkinMap or #_G.PetSkinMap == 0 then
            return
        end

        -- Star Prefer already-set _G.PetSkin (from config file / slider),
        --   Only use the index fallback when _G.PetSkin is invalid (to prevent overwriting a custom ID)
        if not _G.PetSkin or _G.PetSkin <= 0 then
            local index = _G.PetSkinMapIndex or 1
            if type(index) ~= "number" then index = 1 end
            if index < 1 or index > #_G.PetSkinMap then index = 1 end
            _G.PetSkin = _G.PetSkinMap[index]
        end

        local applyID = _G.PetSkin

        -- Download resources (only when ID changes)
        if applyID ~= _G.LastAppliedPet then
            if not _G.skinIdCache[applyID] then
                _G.download_item(applyID)
                _G.skinIdCache[applyID] = true
            end
        end

        -- Star Hook pet module (re-hook on every HandlePetLogic, prevent Hook loss after module reload)
        local ModuleManager = require("client.module_framework.ModuleManager")
        local logic_pet = ModuleManager and ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_pet)

        if logic_pet then
            logic_pet.GetEquipedPetInsID = function()
                return _G.PetSkin
            end
            logic_pet.GetEquipedPetItemID = function()
                return _G.PetSkin
            end
            logic_pet.GetCurrentCarryPets = function()
                return { _G.PetSkin }
            end
            logic_pet.GetPetDataByInsID = function(_, id)
                if id == _G.PetSkin then
                    return {
                        id = id,
                        ins_id = id,
                        exp = 100000,
                        color = 1,
                        dress = {}
                    }
                end
            end
            logic_pet._hooks_done = true
        end

        -- Refresh lobby pet display
        local LobbyAvatarManager = require("client.logic.avatar.LobbyAvatarManager")
        if LobbyAvatarManager and LobbyAvatarManager.CreateMyPet then
            pcall(LobbyAvatarManager.CreateMyPet)
        end

        -- In-game initial pet info setting
local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
if pc and slua.isValid(pc) then
    -- Star Core fix: Never overwrite ID, otherwise server won't recognize slider ID and pet will disappear directly.
    -- On surface we tell server and game "I still carry 50000", secretly swap skin underneath.
    if pc.InitialPetInfo then
        pc.InitialPetInfo.PetId = 50000 
    end
    if pc.PetComponent and slua.isValid(pc.PetComponent) and pc.PetComponent.SetPetID then
        pc.PetComponent:SetPetID(50000)
    end
end

        _G.LastAppliedPet = applyID

        -- Regardless of ID change, try applying skin in-match (prevent pet respawn invalidation)
        _G.ApplyPetSkinInGame()
    end)
end
--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources



-- ==================== RPC Intercept ====================
_G.ProcessEventHooked = false
_G.OriginalProcessEvent = nil

local function SetupProcessEventHook()
    pcall(function()
        local UObject = import("UObject")
        if not UObject or not UObject.ProcessEvent then
            return false
        end
        
        if _G.ProcessEventHooked then
            return true
        end
        
        if not _G.OriginalProcessEvent then
            _G.OriginalProcessEvent = UObject.ProcessEvent
        end
        
        UObject.ProcessEvent = function(self, func, params)
            if not self or not func then
                if _G.OriginalProcessEvent then
                    return _G.OriginalProcessEvent(self, func, params)
                end
                return
            end
            
            local funcName = tostring(func:GetFullName()) or ""
            
            if string.find(funcName, "RPC_ClientCoronaLab") then
                return
            end
            
            if _G.OriginalProcessEvent then
                return _G.OriginalProcessEvent(self, func, params)
            end
        end
        
        _G.ProcessEventHooked = true
    end)
    return false
end
--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources
-- ==================== Social Lobby Slot Unlock and Equip ====================
pcall(function()
    local Logic_SocialLobbyModule = ModuleManager and ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)

    if not Logic_SocialLobbyModule then
        print("[SocialLobbySlots] Logic_SocialLobbyModule not found")
        return
    end

    local function isSelfUid(uid)
        if not uid or not DataMgr or not DataMgr.roleData then return false end
        return tonumber(uid) == tonumber(DataMgr.roleData.uid)
    end

    -- ==================== Slot Types ====================
    local SLOT_AVATAR    = 1
    local SLOT_VEHICLE   = 2
    local SLOT_WEAPON    = 3
    local SLOT_PET       = 4
    local SLOT_BGWALL    = 100

    -- ==================== Slot Count ====================
    local WEAPON_SLOTS_MAX   = 8
    local VEHICLE_SLOTS_MAX  = 6
    local AVATAR_SLOTS_MAX   = 6
    local PET_SLOTS_MAX      = 4
    local ALL_SLOT_TYPES = { SLOT_AVATAR, SLOT_VEHICLE, SLOT_WEAPON, SLOT_PET }

    -- ==================== Item List ====================
    local WEAPON_SLOTS = {
        [1] = 1101101007,
        [2] = 1101004246,
        [3] = 1101004218,
        [4] = 1101004226,
        [5] = 1101003227,
        [6] = 1101005098,
        [7] = 1101006085,
        [8] = 1101008146,
    }

    local VEHICLE_SLOTS = {
        [1] = 1961062,
        [2] = 1961152,
        [3] = 1961153,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local AVATAR_SLOTS = {
        [1] = 1407895,
        [2] = 1406469,
        [3] = 1406971,
        [4] = 0,
        [5] = 0,
        [6] = 0,
    }

    local PET_SLOTS = {
        [1] = 50024,
        [2] = 0,
        [3] = 0,
        [4] = 0,
    }

    -- ==================== Unlock All Slots ====================
    function ForceUnlockAllSlots()
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
        local uid = DataMgr and DataMgr.roleData and DataMgr.roleData.uid
        if not uid then return end
        uid = tonumber(uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return end

        local nCurTime = os.time and os.time() or 9999999999

        if not tSocialData.mixed_hall_slot_unlock_info then
            tSocialData.mixed_hall_slot_unlock_info = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_hall_slot_unlock_info[slotType] then
                tSocialData.mixed_hall_slot_unlock_info[slotType] = {}
            end
        end

        for i = 1, WEAPON_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_WEAPON][i] = nCurTime
        end
        for i = 1, VEHICLE_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_VEHICLE][i] = nCurTime
        end
        for i = 1, AVATAR_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_AVATAR][i] = nCurTime
        end
        for i = 1, PET_SLOTS_MAX do
            tSocialData.mixed_hall_slot_unlock_info[SLOT_PET][i] = nCurTime
        end

        if not tSocialData.mixed_data then
            tSocialData.mixed_data = {}
        end
        for _, slotType in ipairs(ALL_SLOT_TYPES) do
            if not tSocialData.mixed_data[slotType] then
                tSocialData.mixed_data[slotType] = {}
            end
        end
    end

    -- ==================== Send Update Event ====================
    local function FireSlotUpdateEvents(slotType, slotIndex)
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL then
                if EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE, slotType, slotIndex)
                end
                if EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                    EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
                end
            end
        end)
    end

    local function FireShowDataEvent()
        pcall(function()
            if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA then
                EventSystem.postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_GOT_SOCIAL_LOBBY_SHOW_DATA)
            end
        end)
    end

    -- ==================== Equip Weapon ====================
    function EquipWeaponToSlot(nWeaponItemId, nSlotIndex)
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
        if not isSelfUid(DataMgr and DataMgr.roleData and DataMgr.roleData.uid) then
            print("[Slots] Not self UID!")
            return false
        end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nWeaponItemId = tonumber(nWeaponItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > WEAPON_SLOTS_MAX then
            print("[Slots] Invalid weapon slot: " .. tostring(nSlotIndex))
            return false
        end
        if nWeaponItemId <= 0 then
            print("[Slots] Invalid weapon ID: " .. tostring(nWeaponItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_WEAPON] then tSocialData.mixed_data[SLOT_WEAPON] = {} end

        local nFakeInstId = nWeaponItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_WEAPON][nSlotIndex] = {
            resid = nWeaponItemId,
            instid = nFakeInstId,
            weapon_id = 0
        }
        WEAPON_SLOTS[nSlotIndex] = nWeaponItemId

        FireSlotUpdateEvents(SLOT_WEAPON, nSlotIndex)
        print("[Slots] Weapon " .. nWeaponItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== Equip Vehicle ====================
    function EquipVehicleToSlot(nVehicleItemId, nSlotIndex)
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nVehicleItemId = tonumber(nVehicleItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > VEHICLE_SLOTS_MAX then
            print("[Slots] Invalid vehicle slot: " .. tostring(nSlotIndex))
            return false
        end
        if nVehicleItemId <= 0 then
            print("[Slots] Invalid vehicle ID: " .. tostring(nVehicleItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_VEHICLE] then tSocialData.mixed_data[SLOT_VEHICLE] = {} end

        local nFakeInstId = nVehicleItemId * 1000 + nSlotIndex
        tSocialData.mixed_data[SLOT_VEHICLE][nSlotIndex] = {
            resid = nVehicleItemId,
            instid = nFakeInstId
        }
        VEHICLE_SLOTS[nSlotIndex] = nVehicleItemId

        FireSlotUpdateEvents(SLOT_VEHICLE, nSlotIndex)
        print("[Slots] Vehicle " .. nVehicleItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== Equip Outfit ====================
    function EquipAvatarToSlot(nItemId, nSlotIndex)
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nItemId = tonumber(nItemId) or 0
        if nSlotIndex < 1 or nSlotIndex > AVATAR_SLOTS_MAX then
            print("[Slots] Invalid avatar slot: " .. tostring(nSlotIndex))
            return false
        end
        if nItemId <= 0 then
            print("[Slots] Invalid avatar ID: " .. tostring(nItemId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_AVATAR] then tSocialData.mixed_data[SLOT_AVATAR] = {} end

        local nAvatarSlotType = 3
        pcall(function()
            local uItemCfg = CDataTable.GetTableData("Item", nItemId)
            if uItemCfg then
                local Logic_AvatarWardrobeDataTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_AvatarWardrobeDataTools")
                if Logic_AvatarWardrobeDataTools and Logic_AvatarWardrobeDataTools.GetAvatarSlotType then
                    nAvatarSlotType = Logic_AvatarWardrobeDataTools.GetAvatarSlotType(uItemCfg.ItemSubType) or 3
                end
            end
        end)

        local nFakeInstId = nItemId * 1000 + nSlotIndex
        local existingSlotData = tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] or {
            gender = 1,
            pose_type = 0,
            item_info = {}
        }
        if not existingSlotData.item_info then
            existingSlotData.item_info = {}
        end
        existingSlotData.item_info[nAvatarSlotType] = {
            resid = nItemId,
            instid = nFakeInstId,
            origin_resid = 0
        }
        existingSlotData.bIsEditData = true
        tSocialData.mixed_data[SLOT_AVATAR][nSlotIndex] = existingSlotData
        AVATAR_SLOTS[nSlotIndex] = nItemId

        FireSlotUpdateEvents(SLOT_AVATAR, nSlotIndex)
        print("[Slots] Avatar " .. nItemId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== Equip Pet ====================
    function EquipPetToSlot(nPetId, nSlotIndex)
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
        nSlotIndex = tonumber(nSlotIndex) or 1
        nPetId = tonumber(nPetId) or 0
        if nSlotIndex < 1 or nSlotIndex > PET_SLOTS_MAX then
            print("[Slots] Invalid pet slot: " .. tostring(nSlotIndex))
            return false
        end
        if nPetId <= 0 then
            print("[Slots] Invalid pet ID: " .. tostring(nPetId))
            return false
        end

        ForceUnlockAllSlots()
        local uid = tonumber(DataMgr.roleData.uid)
        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData then return false end

        if not tSocialData.mixed_data then tSocialData.mixed_data = {} end
        if not tSocialData.mixed_data[SLOT_PET] then tSocialData.mixed_data[SLOT_PET] = {} end

        tSocialData.mixed_data[SLOT_PET][nSlotIndex] = {
            pet_id = nPetId,
            pet_dress = {}
        }
        PET_SLOTS[nSlotIndex] = nPetId

        FireSlotUpdateEvents(SLOT_PET, nSlotIndex)
        print("[Slots] Pet " .. nPetId .. " → slot " .. nSlotIndex)
        return true
    end

    -- ==================== Remove Slot Item ====================
    function UnequipSlot(nSlotType, nSlotIndex)
        nSlotType = tonumber(nSlotType) or 1
        nSlotIndex = tonumber(nSlotIndex) or 1
        local uid = tonumber(DataMgr.roleData.uid)

        local tSocialData = Logic_SocialLobbyModule:GetSocialData(uid)
        if not tSocialData or not tSocialData.mixed_data or not tSocialData.mixed_data[nSlotType] then
            return false
        end

        tSocialData.mixed_data[nSlotType][nSlotIndex] = nil
        FireSlotUpdateEvents(nSlotType, nSlotIndex)
        print("[Slots] Removed type=" .. nSlotType .. " index=" .. nSlotIndex)
        return true
    end

    -- ==================== Batch Equip All Items ====================
    function EquipAllFromLists()
        if not _G.FormulaFeatureEnabled or not _G.FormulaFeatureEnabled("collectionUnlock") then return 0 end
        local count = 0
        for i, v in pairs(WEAPON_SLOTS) do
            if v and v > 0 then EquipWeaponToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(VEHICLE_SLOTS) do
            if v and v > 0 then EquipVehicleToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(AVATAR_SLOTS) do
            if v and v > 0 then EquipAvatarToSlot(v, i); count = count + 1 end
        end
        for i, v in pairs(PET_SLOTS) do
            if v and v > 0 then EquipPetToSlot(v, i); count = count + 1 end
        end
        print("[Slots] Equipped " .. count .. " items total")
        return count
    end

    -- ==================== Hook GetSlotTypeMaxCount ====================
    local orig_GetSlotTypeMaxCount = Logic_SocialLobbyModule.GetSlotTypeMaxCount
    Logic_SocialLobbyModule.GetSlotTypeMaxCount = function(self, nUId, nSlotType, bIsGetShowCount)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock") and isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetSlotTypeMaxCount(self, nUId, nSlotType, bIsGetShowCount)
    end

    -- ==================== Hook GetSlotIsUnlockBySlotTypeAndIndex ====================
    local orig_GetSlotIsUnlock = Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex
    Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex = function(self, nUId, nSlotType, nSlotIndex)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
           and nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlock(self, nUId, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotIsUnlockedByCollectHallLevel ====================
    local orig_GetSlotIsUnlockedByLevel = Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel = function(self, nUId, nSlotType, nSlotIndex)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
           and nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            return true
        end
        return orig_GetSlotIsUnlockedByLevel(self, nUId, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotTypeUCUnlockMaxCount ====================
    local orig_GetUCUnlockMax = Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount
    Logic_SocialLobbyModule.GetSlotTypeUCUnlockMaxCount = function(self, nSlotType)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock") then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetUCUnlockMax(self, nSlotType)
    end

    -- ==================== Hook GetSlotTypeAllUnlockData ====================
    local orig_GetAllUnlockData = Logic_SocialLobbyModule.GetSlotTypeAllUnlockData
    Logic_SocialLobbyModule.GetSlotTypeAllUnlockData = function(self, nUId, nSlotType)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
           and nSlotType ~= SLOT_BGWALL and isSelfUid(nUId) then
            ForceUnlockAllSlots()
            local tSocialData = Logic_SocialLobbyModule:GetSocialData(nUId)
            return tSocialData and tSocialData.mixed_hall_slot_unlock_info and tSocialData.mixed_hall_slot_unlock_info[nSlotType] or {}
        end
        return orig_GetAllUnlockData(self, nUId, nSlotType)
    end

    -- ==================== Hook CheckSlotTypeIsUCUnlock ====================
    local orig_CheckUCUnlock = Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock
    Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock = function(self, nSlotType, nSlotIndex)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
           and (nSlotType == SLOT_WEAPON or nSlotType == SLOT_VEHICLE or nSlotType == SLOT_AVATAR or nSlotType == SLOT_PET) then
            return false
        end
        return orig_CheckUCUnlock(self, nSlotType, nSlotIndex)
    end

    -- ==================== Hook GetSlotUnlockCountByCollectHallLevel ====================
    local orig_GetUnlockCountByLevel = Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel
    Logic_SocialLobbyModule.GetSlotUnlockCountByCollectHallLevel = function(self, nUId, nSlotType)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock") and isSelfUid(nUId) then
            if nSlotType == SLOT_WEAPON then return WEAPON_SLOTS_MAX end
            if nSlotType == SLOT_VEHICLE then return VEHICLE_SLOTS_MAX end
            if nSlotType == SLOT_AVATAR then return AVATAR_SLOTS_MAX end
            if nSlotType == SLOT_PET then return PET_SLOTS_MAX end
        end
        return orig_GetUnlockCountByLevel(self, nUId, nSlotType)
    end

    -- ==================== Hook GetWeaponSlotIsShowBySlotIndex ====================
    local orig_GetWeaponSlotShow = Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex
    Logic_SocialLobbyModule.GetWeaponSlotIsShowBySlotIndex = function(self, nSlotIndex)
        if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
           and isSelfUid(self._sCurUId) then return true end
        return orig_GetWeaponSlotShow(self, nSlotIndex)
    end

    -- ==================== Initialize Weapon Slot Index ====================
    if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock") then
        Logic_SocialLobbyModule._tWeaponSlotIndex = { [1] = {}, [2] = {} }
        for page = 1, 2 do
            for i = 1, WEAPON_SLOTS_MAX do
                Logic_SocialLobbyModule._tWeaponSlotIndex[page][i] = true
            end
        end
    end

    -- ==================== Hook RefreshUIStateShow ====================
    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.RefreshUIStateShow and not SlotBase._all_slots_orig then
            SlotBase._all_slots_orig = SlotBase.RefreshUIStateShow
            SlotBase.RefreshUIStateShow = function(self)
                if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
                   and self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    if self.CanvasPanel_Lock then
                        self:SetWidgetVisible(self.CanvasPanel_Lock, false)
                    end
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        local bIsEditing = Logic_SocialLobbyEditMgrModule:GetIsEditing()
                        if bIsEditing and self.CanvasPanel_Empty then
                            self:SetWidgetVisible(self.CanvasPanel_Empty, true, false)
                        end
                    end
                    self:_RequestRedraw()
                    return
                end
                return SlotBase._all_slots_orig(self)
            end
        end
    end)

    -- ==================== Hook OnSlotButtonClick ====================
    pcall(function()
        local SlotBase = require("client.slua.umg.lobby.Left.3DUIOverride.SocialLobby_Slot3DUI_UserInterfaceBase")
        if SlotBase and SlotBase.OnSlotButtonClick and not SlotBase._all_slots_click_orig then
            SlotBase._all_slots_click_orig = SlotBase.OnSlotButtonClick
            SlotBase.OnSlotButtonClick = function(self)
                if _G.FormulaFeatureEnabled and _G.FormulaFeatureEnabled("collectionUnlock")
                   and self._nSlotType ~= SLOT_BGWALL and self._bIsSelf then
                    local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
                    if Logic_SocialLobbyEditMgrModule then
                        Logic_SocialLobbyEditMgrModule:EnterEditState(self._nShowUId, self._nSlotType, self._nSlotIndex)
                        return
                    end
                end
                return SlotBase._all_slots_click_orig(self)
            end
        end
    end)

    -- ==================== Execute Unlock and Equip ====================
    pcall(function()
        ForceUnlockAllSlots()
        EquipAllFromLists()
    end)

    -- Delayed execution to ensure modules finish loading
    pcall(function()
        local tt = require("common.time_ticker")
        if tt and tt.AddTimerOnce then
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
            tt.AddTimerOnce(1, function()
                pcall(function()
                    ForceUnlockAllSlots()
                    EquipAllFromLists()
                    FireShowDataEvent()
                end)
            end)
        end
    end)
end)









-- ==================== Ranking Spoof Module ====================
-- Config (modify values here to change display effect)
_G.RankSpoof_Enabled = false  -- Standalone leaderboard spoof defaults OFF
_G.RankSpoof_Rank = 1         -- Ranking (1=1st place)
_G.RankSpoof_Score = 130000   -- Total points
_G.RankSpoof_Content1 = "120" -- Wins / Kills 1
_G.RankSpoof_Content2 = "80"  -- Wins / Kills 2
_G.RankSpoof_Content3 = "45"  -- Wins / Kills 3
_G.RankSpoof_Segment = 801    -- Rank (801=Conqueror)
_G.RankSpoof_Stars = 80       -- Conqueror star count

-- Core code (copy-paste directly, do not modify)
do
    local M = _G.ClientRankSpoof or {}
    _G.ClientRankSpoof = M
    local SIG = "v7|" .. tostring(_G.RankSpoof_Enabled) .. "|" .. tostring(_G.RankSpoof_Rank) .. "|" .. tostring(_G.RankSpoof_Score) .. "|" .. tostring(_G.RankSpoof_Content1) .. "|" .. tostring(_G.RankSpoof_Content2) .. "|" .. tostring(_G.RankSpoof_Content3) .. "|" .. tostring(_G.RankSpoof_Segment) .. "|" .. tostring(_G.RankSpoof_Stars)
    if M._installed and M._sig == SIG then return end
    if M._sig and M._sig ~= SIG then M._hooks = {} end
    
    M.cfg = {
        enabled = _G.RankSpoof_Enabled,
        rankNo = _G.RankSpoof_Rank,
        score = _G.RankSpoof_Score,
        content1 = tostring(_G.RankSpoof_Content1),
        content2 = tostring(_G.RankSpoof_Content2),
        content3 = tostring(_G.RankSpoof_Content3),
        segment = _G.RankSpoof_Segment,
        stars = _G.RankSpoof_Stars,
    }
    M._installed = true
    M._sig = SIG
    M._hooks = M._hooks or {}
    
    local MODES = {"solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad"}
    local COALESCE_SEC = 0.5
    
    local function myUid()
        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
            return tostring(DataMgr.roleData.uid)
        end
        return nil
    end
    
    local function isSelf(uid)
        local u = myUid()
        return M.cfg.enabled and u and uid and tostring(uid) == u
    end
    
    local function getRankDataMgr()
        local ok, m = pcall(require, "client.slua.logic.rank.rank_data_mgr")
        return ok and m or nil
    end
    
    local function getZoneId()
        local RankDataMgr = getRankDataMgr()
        return RankDataMgr and RankDataMgr.GetRankSelectZoneId() or 1
    end
    
    local function getCurrentModeId()
        local RankDataMgr = getRankDataMgr()
        if not RankDataMgr then return 3 end
        local RankConfig = require("client.slua.logic.rank.rank_config")
        local m = RankDataMgr.GetRankSelectMemberType()
        local MemberEnum = RankConfig.MemberEnum
        if RankDataMgr.IsFpp() then
            if m == MemberEnum.single then return 4 end
            if m == MemberEnum.double then return 5 end
            return 6
        end
        if m == MemberEnum.single then return 1 end
        if m == MemberEnum.double then return 2 end
        return 3
    end
    
    local function conquerorRating(stars)
        stars = tonumber(stars) or 1
        if stars < 1 then stars = 1 end
        return 4200 + (stars - 1) * 100
    end
    
    local function patchZoneRankData(zData, score, rating, seg)
        if type(zData) ~= "table" then return end
        zData.total_rank_rating = score
        zData.fpp_total_rank_rating = score
        for _, mode in ipairs(MODES) do
            zData[mode] = zData[mode] or {}
            zData[mode].rank_rating = rating
            zData[mode].level = seg
        end
    end
    
    local function patchSegmentTable(segTable, zoneId, seg)
        if type(segTable) ~= "table" then return end
        segTable[zoneId] = segTable[zoneId] or {}
        for i = 1, 6 do
            segTable[zoneId][i] = seg
        end
    end
    
    local function patchProfileInPlace(profile, zoneId)
        if not profile or not M.cfg.enabled then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        profile.rankdata = profile.rankdata or {}
        profile.rankdata[zoneId] = profile.rankdata[zoneId] or {}
        patchZoneRankData(profile.rankdata[zoneId], score, rating, seg)
        profile.segment_info = profile.segment_info or {}
        patchSegmentTable(profile.segment_info, zoneId, seg)
    end
    
    local function patchDataMgr(zoneId)
        if not M.cfg.enabled or not DataMgr or not DataMgr.roleData then return end
        zoneId = zoneId or getZoneId()
        local seg = M.cfg.segment
        local rating = conquerorRating(M.cfg.stars)
        local score = math.floor(M.cfg.score + 0.5)
        DataMgr.roleData.rankdata = DataMgr.roleData.rankdata or {}
        DataMgr.roleData.rankdata[zoneId] = DataMgr.roleData.rankdata[zoneId] or {}
        patchZoneRankData(DataMgr.roleData.rankdata[zoneId], score, rating, seg)
        DataMgr.roleData.allzoneSegment = DataMgr.roleData.allzoneSegment or {}
        patchSegmentTable(DataMgr.roleData.allzoneSegment, zoneId, seg)
        DataMgr.roleData.segment = DataMgr.roleData.segment or {}
        DataMgr.roleData.segment.solo = seg
        DataMgr.roleData.segment.double = seg
        DataMgr.roleData.segment.team = seg
        DataMgr.roleData.segment.fpp_solo = seg
        DataMgr.roleData.segment.fpp_double = seg
        DataMgr.roleData.segment.fpp_team = seg
    end
    
    local function touchItem(item)
        if not M.cfg.enabled or not item then return end
        local c = M.cfg
        local zoneId = getZoneId()
        local modeId = getCurrentModeId()
        local rating = conquerorRating(c.stars)
        local score = math.floor(c.score + 0.5)
        item.no = c.rankNo
        item.score = score
        item.content1 = tostring(c.content1)
        item.content2 = tostring(c.content2)
        item.content3 = tostring(c.content3)
        item.segment = c.segment
        item.segmentTitleId = 0
        item.segmentModeId = modeId
        item.segmentZoneId = zoneId
        item.segment_info = item.segment_info or {}
        for i = 1, 6 do item.segment_info[i] = c.segment end
        item.all_segment_info = item.all_segment_info or {}
        patchSegmentTable(item.all_segment_info, zoneId, c.segment)
        item.rankdata = item.rankdata or {}
        patchZoneRankData(item.rankdata, score, rating, c.segment)
    end
    
    local function applyList()
        if not M.cfg.enabled then return end
        local uid = myUid()
        if not uid then return end
        local rank_data = require("client.slua.logic.rank.rank_data")
        local list = rank_data.GetRankDataList()
        if type(list) ~= "table" then return end
        local selfItem = rank_data.GetSelfRankData()
        if not selfItem then return end
        touchItem(selfItem)
        for i = #list, 1, -1 do
            if list[i] and tostring(list[i].uid) == uid then
                table.remove(list, i)
            end
        end
        table.insert(list, math.min(M.cfg.rankNo, #list + 1), selfItem)
        pcall(rank_data.UpdateUidRankMap)
        local rdm = getRankDataMgr()
        if rdm then rdm.SetSelfBelow1wDisplay(tostring(M.cfg.rankNo)) end
    end
    
    local function scheduleSilentFix()
        if M._inSilentFix then return end
        M._inSilentFix = true
        pcall(function()
            patchDataMgr()
            local rank_data = require("client.slua.logic.rank.rank_data")
            local selfItem = rank_data.GetSelfRankData()
            if selfItem then touchItem(selfItem) end
            applyList()
        end)
        M._inSilentFix = false
    end
    
    function M.refreshUIOnce()
        scheduleSilentFix()
        pcall(function()
            local RankDataMgr = getRankDataMgr()
            if RankDataMgr then
                local t = RankDataMgr.GetRankSelectType()
                if EventSystem then
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_LIST, t)
                    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_UPDATE_SELF, t)
                end
            end
        end)
    end
    
    -- Install Hook
    local function installHooks()
        local ok, rank_data = pcall(require, "client.slua.logic.rank.rank_data")
        if not ok or not rank_data then return false end
        
        local function hookMod(mod, name, wrapper)
            if not mod or not mod[name] or M._hooks[name] then return false end
            M._hooks[name] = mod[name]
            mod[name] = wrapper
            return true
        end
        
        hookMod(rank_data, "SortTotalRankList", function(...)
            local r = M._hooks.SortTotalRankList(...)
            if M.cfg.enabled then applyList() end
            return r
        end)
        
        hookMod(rank_data, "SetSelfRankData", function(raw_self, convertFunction)
            M._hooks.SetSelfRankData(raw_self, convertFunction)
            if M.cfg.enabled and raw_self and isSelf(raw_self.uid) then
                touchItem(require("client.slua.logic.rank.rank_data").GetSelfRankData())
            end
        end)
        
        return true
    end
    
    if not M._hooks.SortTotalRankList then
        pcall(installHooks)
    end
    
    -- Delayed refresh
    pcall(function()
        local tt = require("common.time_ticker")
        tt.AddTimer(0.5, function()
            if M.cfg.enabled then M.refreshUIOnce() end
            return true
        end)
    end)
    
    -- Add to main timer loop
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(3, function()
            if M.cfg.enabled then pcall(M.refreshUIOnce) end
        end, -1, 1)
    end
end













-- ==================== Movement Trail Effect (Eight Trail Support) ====================
-- Supports all eight trail IDs listed in SUPPORTED_TRAILS below.

-- Read toggle state from config file
local function IsTrailEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("TRAIL_ENABLE", 0)  -- Default 0=Off
    end
    return configValue == 1
end

-- Read trail type from config file
local function GetTrailItemId()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("TRAIL_TYPE", nil)
    end
    if configValue ~= nil and configValue ~= 0 then
        return tonumber(configValue)
    end
    return 4531002  -- Default Golden Leaves Trail
end

-- Global module
_G.GoldenLeavesTrail = _G.GoldenLeavesTrail or {}
_G.GoldenLeavesTrail.Enabled = IsTrailEnabled()
_G.GoldenLeavesTrail.TRAIL_ITEM_ID = GetTrailItemId()

-- Trail name mapping (all eight supported trails)
local TRAIL_NAMES = {
    [4531001] = "Starry Purple Trail",
    [4531002] = "Golden Leaves Trail",
    [4531003] = "Summer Bubble Fantasy Trail",
    [4531004] = "Moonbirch Wisp Trail",
    [4531005] = "Fusion Crystal Lattice Trail",
    [4541001] = "Cool Graffiti Footsteps",
    [4541004] = "Azure Sea Ripple Trail",
    [4541005] = "Moonfall Trace Trail",
}
-- List of all supported trail IDs
local SUPPORTED_TRAILS = {4531001, 4531002, 4541001,4531003,4531004,4531005,4541004,4541005}

-- Pre-download all trail resources
local function PreloadTrails()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if PufferManager and PufferManager.Download then
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, SUPPORTED_TRAILS)
        end
    end)
end

local TrailConfig = {
    DELAY_SEC = 0.5,
    TICKER_SEC = 2.0,   -- Star Power: 0.5 -> 2.0 sec
    USE_TICKER = true,
    FORCE_SELF_VISIBLE = true,
}

-- ========== Fix: Track Match State, Ensure Re-apply Every Match ==========
local _isInMatch = false
local _wasInMatch = false

local function GetCharacter()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if ok and GD then
        local char = GD.GetPlayerCharacter()
        if char and slua.isValid(char) then
            return char
        end
    end
    if slua_GameFrontendHUD then
        local pc = slua_GameFrontendHUD:GetPlayerController()
        if pc and pc.GetPlayerCharacterSafety then
            local char = pc:GetPlayerCharacterSafety()
            if char and slua.isValid(char) then
                return char
            end
        end
    end
    return nil
end

local function GetAvatarComponent(char)
    char = char or GetCharacter()
    if not char or not slua.isValid(char) then
        return nil
    end
    if char.getAvatarComponent2 then
        local comp = char:getAvatarComponent2()
        if comp and slua.isValid(comp) then
            return comp
        end
    end
    return nil
end

local function IsInFighting()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    return ok and r == true
end

local function IsInLobby()
    local ok, r = pcall(function()
        return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()
    end)
    return ok and r == true
end

-- Check if in match
local function IsInMatch()
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if IsInLobby() then
        return false
    end
    local ok, isFighting = pcall(function()
        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
    end)
    if ok then
        return isFighting == true
    end
    local char = GetCharacter()
    return char and slua.isValid(char)
end

local function ApplyTrailToComponent(comp)
    if not comp or not slua.isValid(comp) then
        return false
    end
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    
    local trailId = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
    comp.MoveEffectItem = trailId
    if comp.AdditionEffectMgr then
        comp.AdditionEffectMgr:SetMoveEffectItem(trailId)
    elseif comp.OnRep_MoveEffectItem then
        comp:OnRep_MoveEffectItem(0)
    end
    return true
end

local function ApplyTrailEffect(char)
    if not _G.GoldenLeavesTrail.Enabled then
        return false
    end
    if not IsInMatch() then
        return false
    end
    
    char = char or GetCharacter()
    if char and slua.isValid(char) then
        local comp = GetAvatarComponent(char)
        if ApplyTrailToComponent(comp) then
            return true
        end
    end
    return false
end

-- Stop trail
function _G.GoldenLeavesTrail.Stop()
    pcall(function()
        local char = GetCharacter()
        if char and slua.isValid(char) then
            local comp = GetAvatarComponent(char)
            if comp and slua.isValid(comp) then
                comp.MoveEffectItem = 0
                if comp.AdditionEffectMgr then
                    comp.AdditionEffectMgr:SetMoveEffectItem(0)
                end
            end
        end
    end)
end

-- Switch trail type (supports all eight listed trails)
function _G.GoldenLeavesTrail.SetType(trailId)
    trailId = tonumber(trailId) or 4531002
    -- Check if supported trail ID
    local supported = false
    for _, id in ipairs(SUPPORTED_TRAILS) do
        if id == trailId then
            supported = true
            break
        end
    end
    if not supported then
        trailId = 4531002
    end
    _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
        _G.DazhiMH_Config.Set("TRAIL_TYPE", trailId)
    end
    if _G.GoldenLeavesTrail.Enabled then
        pcall(_G.GoldenLeavesTrail.Apply)
    end
    local name = TRAIL_NAMES[trailId] or tostring(trailId)
    print("[Trail] Switch to: " .. name)
end

-- Hook PufferManager (Supports Eight Trails)
local function HookPufferManager()
    pcall(function()
        local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
        local PufferConst = require("client.slua.logic.download.puffer_const")
        if not PufferManager or not PufferManager.GetState or PufferManager._GLT_Patched then
            return
        end
        PufferManager._GLT_Patched = true
        local origGetState = PufferManager.GetState
        PufferManager.GetState = function(downloadType, keyList, ...)
            if keyList then
                for _, key in pairs(keyList) do
                    local id = tonumber(key)
                    for _, supported in ipairs(SUPPORTED_TRAILS) do
                        if id == supported then
                            return PufferConst.ENUM_DownloadState.Done
                        end
                    end
                end
            end
            return origGetState(downloadType, keyList, ...)
        end
        if _G.download_item then
            local origDownload = _G.download_item
            _G.download_item = function(id)
                local tid = tonumber(id)
                for _, supported in ipairs(SUPPORTED_TRAILS) do
                    if tid == supported then return end
                end
                return origDownload(id)
            end
        end
    end)
end

-- Hook Item Validity Check (Supports Eight Trails)
local function HookItemValid()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.CheckItemValid or CAC._GLT_CheckItemValid then
            return
        end
        CAC._GLT_CheckItemValid = true
        local orig = CAC.CheckItemValid
        CAC.CheckItemValid = function(self, resID)
            local rid = tonumber(resID)
            for _, supported in ipairs(SUPPORTED_TRAILS) do
                if rid == supported then
                    return true
                end
            end
            return orig(self, resID)
        end
    end)
end

-- Hook Initialize Equipment
local function HookInitDepot()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.InitDepotCommonPutOn or CAC._GLT_InitDepot then
            return
        end
        CAC._GLT_InitDepot = true
        local orig = CAC.InitDepotCommonPutOn
        CAC.InitDepotCommonPutOn = function(self)
            orig(self)
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() and self.IsSelf and self:IsSelf() then
                self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                if Client and self.AdditionEffectMgr then
                    self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                end
            end
        end
    end)
end

-- Hook Effect Visibility
local function HookEffectVisibility()
    if not TrailConfig.FORCE_SELF_VISIBLE then
        return
    end
    pcall(function()
        local ECPB = require("GameLua.Mod.Library.GamePlay.Avatar.Component.EffectProc.EffectContionProcessorBase")
        if not ECPB or not ECPB.AdditionEffectCheck or ECPB._GLT_AdditionCheck then
            return
        end
        ECPB._GLT_AdditionCheck = true
        local orig = ECPB.AdditionEffectCheck
        ECPB.AdditionEffectCheck = function(self, character)
            if _G.GoldenLeavesTrail.Enabled then
                local mgr = self.OwnerEffectMgr
                local comp = mgr and mgr.GetOwnerAvatarComponent and mgr:GetOwnerAvatarComponent()
                if slua.isValid(comp) and comp.IsSelf and comp:IsSelf() then
                    if IsInMatch() then
                        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
                        local localChar = GameplayData.GetLocalCharacter()
                        if slua.isValid(localChar) and localChar.bIsGunADS then
                            return false
                        end
                        return true
                    end
                    return false
                end
            end
            return orig(self, character)
        end
    end)
end

-- Hook Apply Effect When Model Finishes Loading
local function HookMeshLoaded()
    pcall(function()
        local CAC = require("GameLua.Mod.Library.GamePlay.Avatar.Component.CharacterAvatarComponent")
        if not CAC or not CAC.OnAvatarAllMeshLoadedLua or CAC._GLT_MeshLoaded then
            return
        end
        CAC._GLT_MeshLoaded = true
        local orig = CAC.OnAvatarAllMeshLoadedLua
        CAC.OnAvatarAllMeshLoadedLua = function(self)
            orig(self)
            pcall(function()
                if self.IsLobbyActor and self:IsLobbyActor() then
                    return
                end
                if self.IsSelf and not self:IsSelf() then
                    return
                end
                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    self.MoveEffectItem = _G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002
                    if self.AdditionEffectMgr then
                        self.AdditionEffectMgr:SetMoveEffectItem(_G.GoldenLeavesTrail.TRAIL_ITEM_ID or 4531002)
                    end
                end
            end)
        end
    end)
end

-- Install all Hooks
local function InstallAllHooks()
    if _G._GoldenLeavesTrailHooked then
        return
    end
    _G._GoldenLeavesTrailHooked = true
    HookPufferManager()
    HookItemValid()
    HookInitDepot()
    HookEffectVisibility()
    HookMeshLoaded()
end

-- Apply
function _G.GoldenLeavesTrail.Apply()
    InstallAllHooks()
    if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
        return ApplyTrailEffect()
    end
    return false
end

-- ========== Fix: Re-apply Every Match ==========
local function EnsureTrailApplied()
    local inMatch = IsInMatch()
    
    -- Detected entering match
    if inMatch and not _wasInMatch then
        print("[Trail] Detected entering match, re-apply trail")
        _G.GoldenLeavesTrail.Apply()
    end
    
    -- Detected leaving match
    if not inMatch and _wasInMatch then
        print("[Trail] Left match, stop trail")
        _G.GoldenLeavesTrail.Stop()
    end
    
    _wasInMatch = inMatch
end

-- Start timer (Fix: Check match state more frequently)
local function StartTicker()
    if not TrailConfig.USE_TICKER then
        return
    end
    pcall(function()
        if _G.Mytimer_ticker then
            -- Add match state detection timer (check every 0.5 sec)
            _G.Mytimer_ticker.AddTimerLoop(TrailConfig.TICKER_SEC, function()
                pcall(EnsureTrailApplied)
                
                -- If in match and toggle on, keep applying
                if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                    pcall(ApplyTrailEffect)
                elseif not _G.GoldenLeavesTrail.Enabled then
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end, -1, 1)
        end
    end)
end

-- Startup
local function Start()
    InstallAllHooks()
    PreloadTrails()
    local char = GetCharacter()
    if char and char.AddGameTimer then
        char:AddGameTimer(TrailConfig.DELAY_SEC, false, function()
            if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
                _G.GoldenLeavesTrail.Apply()
            end
        end)
    else
        if _G.GoldenLeavesTrail.Enabled and IsInMatch() then
            _G.GoldenLeavesTrail.Apply()
        end
    end
    StartTicker()
end

if not _G._GoldenLeavesTrailLoaded then
    _G._GoldenLeavesTrailLoaded = true
    Start()
end

-- Export
_G.GoldenLeavesTrail.IsInMatch = IsInMatch
_G.GoldenLeavesTrail.ApplyToChar = ApplyTrailEffect
_G.GoldenLeavesTrail.GetTrailName = function(id)
    return TRAIL_NAMES[id] or "Unknown Trail"
end

print("[Trail] Loaded, current trail: " .. (TRAIL_NAMES[_G.GoldenLeavesTrail.TRAIL_ITEM_ID] or "Unknown") .. " (ID: " .. tostring(_G.GoldenLeavesTrail.TRAIL_ITEM_ID) .. ")")


-- ==================== Grenade Explosion Effect Skin Module (v27 Silent Fast Version) ====================
do
local M = {}
_G.GrenadeFX = M
local GRENADE_SKIN_ID = 612004238

-- Star Explosion effect size: Read from _G.GrenadeFX8_Scale (default 1.0, range 0.5~5.0)
-- How to modify: GrenadeFX.SetScale(2.0) or write GRENADE_FX_SCALE=200 in wumingking.h
if not _G.GrenadeFX8_Scale then
    local _cfgVal = 100
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        _cfgVal = tonumber(_G.DazhiMH_Config.Get("GRENADE_FX_SCALE", 100)) or 100
    end
    if _cfgVal < 50  then _cfgVal = 50  end
    if _cfgVal > 500 then _cfgVal = 500 end
    _G.GrenadeFX8_Scale = _cfgVal / 100.0
end

local function getGrenadeScale()
    local s = tonumber(_G.GrenadeFX8_Scale) or 1.0
    if s < 0.5 then s = 0.5 end
    if s > 5.0 then s = 5.0 end
    return s
end

local FORCE_WEAPON_ID = nil
local SOURCE_FX_ID = 1101006106
local FALLBACK_FX = "/Game/Arts_Effect/ParticleSystems/Grenade/P_Grenade_Fire_Explode_01_Int.P_Grenade_Fire_Explode_01_Int"

-- Star Fragment grenade ID
local FRAG_GRENADE_ID = 602004

local UGameplayStatics = import("GameplayStatics")
local applied = false
local fxHooked = false
local preloaded = false
local preloadedForId = nil
local cachedParticle = nil
local cachedSeqPath = nil
local fragClass = nil

local resourceChecked = false
local _lastHandID = nil

-- Minimal silent log
local function log(msg) end

local function GetPC()
    local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not ok or not GD then return nil end
    local PC = GD.GetPlayerController()
    if not slua.isValid(PC) then return nil end
    return PC
end

local function GetActorItemID(actor)
    local id = nil
    pcall(function()
        if actor.ItemDefineID then
            id = actor.ItemDefineID.TypeSpecificID
        end
    end)
    if not id or id == 0 then
        pcall(function()
            id = actor.GrenadeItemID
        end)
    end
    return id
end

local function CheckResourceDownloaded()
    if resourceChecked then return end
    resourceChecked = true
    pcall(function()
        local download_util = require("client.slua.logic.download.puffer.download_util")
        local downloaded = download_util.IsDownloaded(GRENADE_SKIN_ID)
        if not downloaded then
            local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
            local PufferConst = require("client.slua.logic.download.puffer_const")
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {GRENADE_SKIN_ID})
        end
    end)
end

-- ========== 1. Held Continuous Force-Refresh ==========
function _G.RefreshGrenadeAvatar()
    local uCharacter = _G.getPlayerCharacter and _G.getPlayerCharacter() or nil
    if not uCharacter then
        local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and GD then uCharacter = GD.GetPlayerCharacter() end
    end
    if not slua.isValid(uCharacter) then return end

    local weapon = uCharacter:GetCurrentWeapon()
    if not weapon or not slua.isValid(weapon) then return end

    local DefineID = weapon.GetItemDefineID and weapon:GetItemDefineID()
    if not DefineID then return end
    local wid = DefineID.TypeSpecificID

    local comp = nil
    pcall(function() comp = weapon["GrenadeAvatarComponent"] end)
    if not comp then
        pcall(function() comp = weapon["GrenadeAvatarComponent_BP"] end)
    end
    if not slua.isValid(comp) then return end

    if wid == FRAG_GRENADE_ID then
        -- Force-refresh Nine-Tails
        if comp.PreChangeGrenadeAvatar then
            pcall(function() comp:PreChangeGrenadeAvatar(GRENADE_SKIN_ID) end)
        end
        if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
            if comp.SetOverrideFxIndex then comp:SetOverrideFxIndex(tonumber(FORCE_WEAPON_ID)) end
            if comp.SetOverrideSoundIndex then comp:SetOverrideSoundIndex(0) end
        end
        _lastHandID = wid
    else
        -- Restore default when switching away
        if _lastHandID == FRAG_GRENADE_ID then
            if comp.PreChangeGrenadeAvatar then
                pcall(function() comp:PreChangeGrenadeAvatar(0) end)
            end
            _lastHandID = wid
        end
    end
end

-- ========== 2. In-Flight Continuous Force-Refresh ==========
local function ScanFlyingGrenades()
    local PC = GetPC()
    if not PC then return end
    local world = PC:GetWorld()
    if not slua.isValid(world) then return end

    local FragClass = fragClass
    if not FragClass then
        local ok, cls = pcall(import, "FragGrenade")
        if ok and cls then FragClass = cls end
    end
    if not FragClass then return end

    pcall(function()
        local arr = UGameplayStatics.GetAllActorsOfClass(world, FragClass, {})
        if not arr then return end
        for _, actor in pairs(arr) do
            local itemID = GetActorItemID(actor)
            if itemID == FRAG_GRENADE_ID then
                CheckResourceDownloaded()
                local comp = nil
                for _, fname in ipairs({"GrenadeAvatarComponent_BP", "GrenadeAvatarComponent"}) do
                    pcall(function() comp = actor[fname] end)
                    if comp then break end
                end
                if comp and comp.PreChangeGrenadeAvatar then
                    pcall(function() comp:PreChangeGrenadeAvatar(GRENADE_SKIN_ID) end)
                end
            end
        end
    end)
end

-- ========== 3. Component-Level Hook ==========
local function PatchGrenadeAvatarComponent()
    local ok, mod = pcall(require, "GameLua.Mod.Library.GamePlay.Avatar.Component.GrenadeAvatarComponent")
    if not ok or not mod or not mod.__inner_impl then return false end
    local impl = mod.__inner_impl

    -- Trigger instantly when switching to grenade (faster than 30Hz timer)
    local orig = rawget(impl, "OnGrenadeAvatarEqiuped")
    if type(orig) == "function" and not rawget(impl, "__gfxOnEqV27") then
        rawset(impl, "__gfxOnEqV27", true)
        rawset(impl, "OnGrenadeAvatarEqiuped", function(self, ...)
            local r = orig(self, ...)
            pcall(function()
                local uCharacter = _G.getPlayerCharacter and _G.getPlayerCharacter()
                if uCharacter then
                    local weapon = uCharacter:GetCurrentWeapon()
                    if weapon then
                        local wid = weapon:GetItemDefineID().TypeSpecificID
                        if wid == FRAG_GRENADE_ID and self and self.PreChangeGrenadeAvatar then
                            self:PreChangeGrenadeAvatar(GRENADE_SKIN_ID)
                            if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
                                if self.SetOverrideFxIndex then self:SetOverrideFxIndex(tonumber(FORCE_WEAPON_ID)) end
                                if self.SetOverrideSoundIndex then self:SetOverrideSoundIndex(0) end
                            end
                        end
                    end
                end
            end)
            return r
        end)
    end

    local origCheck = rawget(impl, "CheckHasOverrideFx")
    if type(origCheck) == "function" and not rawget(impl, "__gfxCheckFx") then
        rawset(impl, "__gfxCheckFx", true)
        rawset(impl, "CheckHasOverrideFx", function(self, ...)
            if FORCE_WEAPON_ID and FORCE_WEAPON_ID > 0 then
                local wid = tonumber(FORCE_WEAPON_ID)
                if self.SetOverrideFxIndex then self:SetOverrideFxIndex(wid) end
                if self.SetOverrideSoundIndex then self:SetOverrideSoundIndex(0) end
                return
            end
            return origCheck(self, ...)
        end)
    end
    fxHooked = true
    return true
end

-- ========== 4. Explosion Effect ==========
local function spawnCustomFx(self, loc)
    local s = getGrenadeScale()
    if cachedSeqPath and cachedSeqPath ~= "" then
        local host = slua.isValid(self) and self or slua_GameFrontendHUD
        local tf = FTransform(FRotator(0, 0, 0), loc, FVector(s, s, s))
        local seq = Game:PlayLevelSequence(host, cachedSeqPath, tf,
            "/Game/Arts_PlayerBluePrints/DeadBox/DeadBoxSmoke/BP_DeadBoxSmokeSeqActor.BP_DeadBoxSmokeSeqActor_C", false)
        if slua.isValid(seq) then seq:Play(0.0); return true end
    end
    if slua.isValid(cachedParticle) then
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if slua.isValid(world) then
            UGameplayStatics.SpawnEmitterAtLocation(world, cachedParticle, loc,
                FRotator(0, 0, 0), FVector(s, s, s), true)
            return true
        end
    end
    return false
end

local function playExplosionSound(self, loc)
    pcall(function()
        local AkGameplayStatics = import("AkGameplayStatics")
        local sound = self.ExplosionSound or self.ExplodeSound
            or self.ExplosionAkEvent or self.ExplodeAkEvent
            or self.ExplosionSoundCue or self.ExplodeSoundCue
            or self.ExplosionAudio or self.ExplodeAudio
        if sound and slua.isValid(sound) then
            AkGameplayStatics.PostEventAtLocation(sound, loc, FRotator(0, 0, 0), "", self.Object)
        end
    end)
end

local function findFragGrenadeImpl()
    for path, mod in pairs(package.loaded) do
        if type(path) == "string" and type(mod) == "table"
            and path:find("FragGrenade") and not path:find("LuaGet") then
            local impl = mod.__inner_impl
            if type(impl) == "table" then
                local cur = impl
                while cur do
                    if type(rawget(cur, "BeginInEffect")) == "function" then return cur end
                    cur = cur.__super_impl
                end
            end
        end
    end
    return nil
end

local function InjectFxTable()
    if not FORCE_WEAPON_ID or FORCE_WEAPON_ID <= 0 then return end
    local ok, tbl = pcall(function() return CDataTable.GetTable("GrenadeBindWeaponFx") end)
    if not ok or type(tbl) ~= "table" then return end
    if tbl[FORCE_WEAPON_ID] and tbl[FORCE_WEAPON_ID].FxPath and tbl[FORCE_WEAPON_ID].FxPath ~= "" then return end
    local src = tbl[SOURCE_FX_ID]
    if src and src.FxPath and src.FxPath ~= "" then
        tbl[FORCE_WEAPON_ID] = {ID=FORCE_WEAPON_ID, FxPath=src.FxPath, FxSeqPath=src.FxSeqPath or ""}
    else
        tbl[FORCE_WEAPON_ID] = {ID=FORCE_WEAPON_ID, FxPath=FALLBACK_FX, FxSeqPath=""}
    end
end

function M.Apply()
    PatchGrenadeAvatarComponent()

    if not preloaded or preloadedForId ~= FORCE_WEAPON_ID then
        cachedParticle = nil
        cachedSeqPath = nil
        local ok2, fxCfg = pcall(function()
            return CDataTable.GetTableData("GrenadeBindWeaponFx", FORCE_WEAPON_ID)
        end)
        if ok2 and fxCfg then
            cachedSeqPath = fxCfg.FxSeqPath
            if fxCfg.FxPath and fxCfg.FxPath ~= "" then
                local util = require("client.slua_ui_framework.util")
                -- Star Prefer loading real path (remove _UI suffix)
                local realPath = fxCfg.FxPath
                if realPath:find("_UI") then
                    realPath = realPath:gsub("_UI", "")
                end
                util.GetAssetAsync(realPath, function(uParticle)
                    if slua.isValid(uParticle) then
                        cachedParticle = uParticle
                        print("[GrenadeFX] ✓ Loaded real Level 8 particles: " .. realPath)
                    else
                        print("[GrenadeFX] ✗ Real path failed, fallback to _UI: " .. fxCfg.FxPath)
                        -- Fallback to _UI version
                        util.GetAssetAsync(fxCfg.FxPath, function(uParticle2)
                            if slua.isValid(uParticle2) then
                                cachedParticle = uParticle2
                                print("[GrenadeFX] ✓ Loaded UI particles (preview)")
                            end
                        end)
                    end
                end)
            end
        end
        preloaded = true
        preloadedForId = FORCE_WEAPON_ID
    end

    if not applied then
        local impl = findFragGrenadeImpl()
        if not impl then return false end
        local orig = rawget(impl, "BeginInEffect")
        if type(orig) ~= "function" then return false end
        rawset(impl, "BeginInEffect", function(self, OldType)
            pcall(function()
                if not fragClass then
                    local cls = self:GetClass()
                    if cls then fragClass = cls end
                end
            end)
            if not Client then
                orig(self, OldType)
                return
            end
            local loc = self.K2_GetActorLocation and self:K2_GetActorLocation() or nil
            if loc and spawnCustomFx(self, loc) then
                playExplosionSound(self, loc)
                return
            end
            orig(self, OldType)
        end)
        applied = true
    end
    return true
end

-- Star Size control (write config + take effect immediately)
function M.SetScale(scale)
    scale = tonumber(scale) or 1.0
    if scale < 0.5 then scale = 0.5 end
    if scale > 5.0 then scale = 5.0 end
    _G.GrenadeFX8_Scale = scale
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
        _G.DazhiMH_Config.Set("GRENADE_FX_SCALE", math.floor(scale * 100 + 0.5))
    end
    return scale
end

function M.GetScale()
    return getGrenadeScale()
end

-- Star Test spawn at character position
function M.TestSpawn()
    local ch = nil
    pcall(function()
        local pc = slua_GameFrontendHUD:GetPlayerController()
        ch = pc and pc:GetPlayerCharacterSafety()
    end)
    if not ch then return end
    if not slua.isValid(cachedParticle) then
        M.Apply()
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(2, function() M.TestSpawn() end)
        end
        return
    end
    local loc = nil
    pcall(function() loc = ch:K2_GetActorLocation() end)
    local world = slua_GameFrontendHUD:GetWorld()
    if loc and slua.isValid(world) then
        local s = getGrenadeScale()
        pcall(function()
            UGameplayStatics.SpawnEmitterAtLocation(world, cachedParticle, loc,
                FRotator(0, 0, 0), FVector(s, s, s), true)
        end)
    end
end

function _G.ApplyGrenadeSkin()
    if not GRENADE_SKIN_ID then return end
    local PC = GetPC()
    if not PC or not slua.isValid(PC.InitialConsumableAvatar) then return end
    if PC.InitialConsumableAvatar.GrenadeAvatarShoulei == GRENADE_SKIN_ID then return end
    if PC.InitGrenadeAvatarList then pcall(function() PC:InitGrenadeAvatarList(true) end) end
    if PC.InitialConsumableAvatar then
        PC.InitialConsumableAvatar.GrenadeAvatarShoulei = GRENADE_SKIN_ID
        if PC.InitGrenadeAvatarList then pcall(function() PC:InitGrenadeAvatarList() end) end
    end
end

pcall(function()
    local SkinCfg = CDataTable.GetTableData("GrenadeKillGunBindMap", GRENADE_SKIN_ID)
    if SkinCfg and SkinCfg.UnlockFxGunIDList_a and SkinCfg.UnlockFxGunIDList_a:Num() > 0 then
        FORCE_WEAPON_ID = SkinCfg.UnlockFxGunIDList_a:Get(0)
    else
        FORCE_WEAPON_ID = 1101006106
    end
    InjectFxTable()
    _G.ApplyGrenadeSkin()
    M.Apply()
end)

local ticker = _G.Mytimer_ticker
if not ticker then
    local ok, tt = pcall(require, "common.time_ticker")
    if ok and tt then ticker = tt end
end

if ticker then
    local _tick = 0
    local _lastGrenadeRefresh = 0
    -- Callback interval 0.15 sec (6.7 times per sec), 3x lighter than 0.05 sec
    ticker.AddTimerLoop(0.15, function()
        local now = os.clock()
        -- Star Default 1 time per sec (same as file 1, most stable)
        local interval = 1.0
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Get and _G.DazhiMH_Config.Get("GRENADE_FAST_REFRESH", 0) == 1 then
            interval = 0.15  -- Star Ultra-fast: 6.7 times per sec (limited by callback rhythm)
        end
        
        if now - _lastGrenadeRefresh >= interval then
            _lastGrenadeRefresh = now
            _tick = _tick + 1
            pcall(function()
                if not applied or not fxHooked then M.Apply() end
                _G.ApplyGrenadeSkin()
                _G.RefreshGrenadeAvatar()
                if _tick % 2 == 0 then
                    ScanFlyingGrenades()
                end
            end)
        end
    end, -1, 0.15)
end

function M.Preload() end
function M.BindMaxWeapon(id) FORCE_WEAPON_ID = tonumber(id) or FORCE_WEAPON_ID end
function M.ListWeapons() end
function M.Fire() end
function M.SetGrenadeSkin(id) GRENADE_SKIN_ID = tonumber(id) or GRENADE_SKIN_ID end

end


-- ==================== Timer Initialization and Startup ====================
-- Assign timer module to global variable, for other functions to call
_G.Mytimer_ticker = TXtime_ticker



-- ========== Log Function ==========
local function LOG(msg)
    local f = io.open("data/share1/loglua.txt", "a+")
    if f then
        f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(msg) .. "\n")
        f:close()
    end
end

-- ========== Reference Necessary Modules ==========
local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
local PufferConst = require("client.slua.logic.download.puffer_const")
local SKillInfo = require("GameLua.Mod.BaseMod.Client.KillInfoTips.KillInfo")
local ECharacterHealthStatus = import("ECharacterHealthStatus")
local UEnums = _ENV.UEnums

_G.__ModTeamKillSkinID = _G.__ModTeamKillSkinID or 0
local TEAM_KILL_SUB_EFFECT = 22

-- ========== Download Resource Function ==========
local function pufferDownload(id)
    if not id or id == 0 then return end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {id})
    if state ~= PufferConst.ENUM_DownloadState.Done then
        PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {id})
    end
end

-- Download kill effect resources
local function downloadEliminationAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("WeaponAvatarBattleEffect", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

-- Download teammate kill broadcast resources
local function downloadTeamAssets(skinID)
    pufferDownload(skinID)
    local cfg = CDataTable.GetTableData("TeamKillBroadcast", skinID)
    if cfg then
        if cfg.EffectPath and cfg.EffectPath ~= "" then pufferDownload(cfg.EffectPath) end
        if cfg.BgPath and cfg.BgPath ~= "" then pufferDownload(cfg.BgPath) end
    end
end

_G.download_item = downloadEliminationAssets




-- ==================== Kill Info Hook (Optimized) ====================
-- Use stable snn.lua logic, avoid duplicate Hook and mode conflicts
if not _G.BattleKillBroadcastSkinHacked then
    pcall(function()
        local BattleKillBroadcastSubSystem = require("GameLua.Mod.BaseMod.Client.BattleKillBroadcast.BattleKillBroadcastSubSystem")
        if not (BattleKillBroadcastSubSystem and BattleKillBroadcastSubSystem.__inner_impl) then return end
        local o_Copy = BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable
        BattleKillBroadcastSubSystem.__inner_impl.CopyKillOrPutDownMessageDataUserDataToLuaTable = function(self, messageData)
            local msgData = o_Copy(self, messageData)
            pcall(function()
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local character = pc and pc:GetPlayerCharacterSafety()
                if character and slua.isValid(character) and msgData.bIamCauser and _G.LuaStateWrapper then
                    msgData.bShowBottomBothSidesKillInfo = true
                    local weapon = character:GetCurrentWeapon()
                    if weapon and slua.isValid(weapon) then
                        local weapon_id = weapon:GetItemDefineID() and weapon:GetItemDefineID().TypeSpecificID or 0
                        if weapon_id ~= 0 then
                            local expand_data = slua.LuaArchiverDecode(_G.LuaStateWrapper, msgData.ExpandDataContent) or {}
                            local isClassic = false
                            local uGameState = slua_GameFrontendHUD:GetGameState()
                            if uGameState and slua.isValid(uGameState) then
                                local EGameModeType = import("EGameModeType")
                                if uGameState.GameModeType == EGameModeType.ETypicalGameMode then isClassic = true end
                            end
                            local syn_data = weapon.synData
                            if syn_data and slua.isValid(syn_data) then
                                local define_id = slua.IndexReference(syn_data:Get(7), "defineID")
                                if define_id and slua.isValid(define_id) then
                                    expand_data.CauserWeaponAvatarID = define_id.TypeSpecificID
                                end
                            end
                            if isClassic then
                                expand_data.KillCounterItemId = weapon_id
                                expand_data.KillCounterNum = _G.getKills and _G.getKills(weapon_id) or 0
                            end
                            msgData.bShowKillNum = true
                            msgData.ExpandDataContent = slua.LuaArchiverEncode(_G.LuaStateWrapper, expand_data)
                        end
                    end
                end
            end)
            return msgData
        end
        _G.BattleKillBroadcastSkinHacked = true
    end)
end





-- ==================== Profile Spoofing Module ====================
-- Feature: Rank, Peak Tournament, Season Journey Badge, Level, Avatar, Avatar Frame

-- ========== Conqueror Rank Settings ==========
local CURRENT_SEGMENT = 801          -- 801=Conqueror
local CONQUEROR_STARS = 91           -- Star count
local CURRENT_RATING = 4200 + (CONQUEROR_STARS - 1) * 100  -- 13200 points

-- ========== Career Highest Rank ==========
local HISTORY_SEGMENT = 801

-- ========== Peak Tournament Settings ==========
local PEAK_CURRENT_SEGMENT = 1541    -- Current peak rank
local PEAK_HISTORY_SEGMENT = 1301    -- Historical highest
local PEAK_RATING = 8000

-- ========== Season Journey Badge ==========
local JOURNEY_BADGE_LEVEL = 20
local JOURNEY_BADGE_VISUAL_LEVEL = 5
local JOURNEY_BADGE_GLOW_TASKS = 5
local JOURNEY_GLOW_RANKS = { 701, 702, 703, 801 }
local ENABLE_SEASON_YEAR_BADGE = false
local SHOW_SEASON_SERIES_MEDAL = true
local SEASON_SERIES_SEGMENT = 0

-- ========== Profile Bottom Data ==========
local SEASON_RATING = 8500
local SEASON_RANK = "44"
local ACHIEVEMENT_POINTS = 9500
local PLAYED_YEARS = 10
local CONQUEROR_TITLE_ID = 3

-- ========== Basic Settings (Will Be Refreshed by Timer) ==========
local PLAYER_LEVEL = 100
local AVATAR_ID = 40263
local AVATAR_BOX_ID = 2003000

-- ==================== Timer Refresh Avatar / Level ====================
local function refresh_basic_data()
    if not _G.FormulaFeatureEnabled("profileIdentity") then return end
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            _G.DataMgr.roleData.level = PLAYER_LEVEL

            -- Star User selected -> Use user's choice; not selected -> Use default
            local userA, userB = 0, 0
            if _G.FormulaFeatureEnabled("avatarLists") then
                userA = math.floor(tonumber(_G.__BeysaUserAvatarPick) or 0)
                userB = math.floor(tonumber(_G.__BeysaUserFramePick)  or 0)
            end
            local targetA = (userA > 0) and userA or AVATAR_ID
            local targetB = (userB > 0) and userB or AVATAR_BOX_ID

            _G.DataMgr.roleData.pic_url = targetA
            _G.DataMgr.roleData.headIconUrl = targetA
            _G.DataMgr.roleData.pic_url_check_open = true
            _G.DataMgr.roleData.cur_avatar_box_id = targetB
        end
    end)
end

_G.FORMULA_RefreshProfileIdentity = function()
    if _G.FormulaFeatureEnabled("profileIdentity") then
        pcall(refresh_basic_data)
    end
end

if _G.Mytimer_ticker then
    -- Timer is harmless while the feature switch is off.
    _G.Mytimer_ticker.AddTimer(2, refresh_basic_data)
    -- Refresh every 1 sec (prevent being overwritten by game)
    _G.Mytimer_ticker.AddTimerLoop(1, refresh_basic_data, -1, 1)
else
    refresh_basic_data()
end

-- ==================== Rank System Constants ====================
local SEGMENT_TYPE = {
    solo = 1, double = 2, team = 3,
    fpp_solo = 4, fpp_double = 5, fpp_team = 6,
}
local RANK_MODES = { "solo", "duo", "squad", "fppsolo", "fppduo", "fppsquad" }
local ZONE_COUNT = 6

local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
if not RoleInfoSystem then
    print("[SetRoleInfo] RoleInfoSystem not found - Subsequent modules load as usual")
end

local function log_msg(...)
    print("[SetRoleInfo]", ...)
end

-- ==================== Helper Functions ====================
local function stars_from_rating(rating)
    rating = tonumber(rating) or 0
    if rating < 4200 then return 0 end
    return math.max(0, math.floor((rating - 4200) / 100) + 1)
end

local function rating_from_stars(stars)
    stars = tonumber(stars) or 0
    if stars <= 0 then return 0 end
    return 4200 + (stars - 1) * 100
end

local function is_self_uid(uid)
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return false end
    return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end

local function get_fake_registertime()
    local ok, TimeUtil = pcall(require, "client.common.time_util")
    local now = (ok and TimeUtil and TimeUtil.GetServerTimeInSec and TimeUtil.GetServerTimeInSec()) or os.time()
    return now - (PLAYED_YEARS * 365 * 86400)
end

-- ==================== Conqueror Title ID ====================
local function resolve_conqueror_title_id()
    if CONQUEROR_TITLE_ID and CONQUEROR_TITLE_ID > 0 then
        return CONQUEROR_TITLE_ID
    end
    local bestId, bestPri = nil, -1
    pcall(function()
        local tbl = CDataTable and CDataTable.GetTable and CDataTable.GetTable("SegmentTitleConfig")
        if not tbl then return end
        for id, cfg in pairs(tbl) do
            if cfg and not cfg.IfDefaultTitle then
                local pri = tonumber(cfg.Priority) or 0
                local tid = tonumber(cfg.ID) or tonumber(id)
                if tid and pri > bestPri then
                    bestPri = pri
                    bestId = tid
                end
            end
        end
    end)
    return bestId or 0
end

-- ==================== Build Fake Data ====================
local function build_zone_segments(seg)
    return {
        [SEGMENT_TYPE.solo] = seg,
        [SEGMENT_TYPE.double] = seg,
        [SEGMENT_TYPE.team] = seg,
        [SEGMENT_TYPE.fpp_solo] = seg,
        [SEGMENT_TYPE.fpp_double] = seg,
        [SEGMENT_TYPE.fpp_team] = seg,
    }
end

local function build_allzone_segment(seg)
    local t = {}
    for z = 1, ZONE_COUNT do
        t[z] = build_zone_segments(seg)
    end
    return t
end

local function build_rankdata(rating)
    local rd = {}
    local entry = { rank_rating = rating }
    for z = 1, ZONE_COUNT do
        rd[z] = {}
        for _, mode in ipairs(RANK_MODES) do
            rd[z][mode] = entry
        end
    end
    return rd
end

local function build_hsegment_title(titleId)
    if not titleId or titleId <= 0 then return nil end
    local det = {}
    for z = 1, ZONE_COUNT do
        det[z] = {}
        for modeId = 1, 6 do
            det[z][modeId] = { id = titleId }
        end
    end
    return det
end

-- ==================== Peak Tournament Data ====================
local function build_peakgame_list(segmentId, maxSegmentId, rating)
    local ok, PeakGameConfig = pcall(require, "client.logic.PeakGame.PeakGameConfig")
    if not ok or not PeakGameConfig then return nil end
    local bt = PeakGameConfig.BattleType.Squad
    local list = {}
    for z = 1, ZONE_COUNT do
        list[z] = {
            [bt] = {
                rating = rating or PeakGameConfig.DefaultPeakGameRating,
                segment_id = segmentId or PeakGameConfig.DefaultPeakGameSegment,
                max_segment_id = maxSegmentId or segmentId or PeakGameConfig.DefaultPeakGameSegment,
            },
        }
    end
    return list
end

local function build_peakgame_segment_info(segmentId, maxSegmentId, rating)
    local list = build_peakgame_list(segmentId, maxSegmentId, rating)
    if not list then return nil end
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    return { curr_season_id = seasonId, list = list }
end

local function build_peakgame_rating_info(segmentId, maxSegmentId, rating)
    return build_peakgame_list(segmentId, maxSegmentId, rating)
end

-- ==================== Season Journey Badge ====================
local function build_season_year_badge(level)
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return nil end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    level = tonumber(level) or 1

    local gem = { [1] = { finish_count = level, status = Done } }
    local base = { [1] = { finish_count = level, status = Done } }

    local glowTasks = tonumber(JOURNEY_BADGE_GLOW_TASKS) or 3
    local glow = {}
    for i = 1, glowTasks do
        glow[i] = {
            finish_count = 1,
            status = Done,
            trigger_value = JOURNEY_GLOW_RANKS[i] or 801,
        }
    end

    local crown = {}
    local crownMax = cfg.CrownTaskMaxCount or 10
    local crownStage = math.min(tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3, level)
    for i = 1, crownMax do
        crown[i] = { finish_count = crownStage, status = Done }
    end

    return {
        [EB.Gem] = gem,
        [EB.Base] = base,
        [EB.Glow] = glow,
        [EB.Crown] = crown,
    }
end

local function get_season_year_id()
    local ok, season_year_util = pcall(require, "client.logic.season_year.util.season_year_util")
    if ok and season_year_util and season_year_util.GetSeasonYearId then
        return season_year_util.GetSeasonYearId()
    end
    return 1
end

local function get_season_series_segment_id()
    if tonumber(SEASON_SERIES_SEGMENT) and SEASON_SERIES_SEGMENT > 0 then
        return SEASON_SERIES_SEGMENT
    end
    local segId
    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and logic_leisure_season.GetLeisureDefaultID then
            segId = logic_leisure_season:GetLeisureDefaultID()
        end
    end)
    if not segId or segId == 0 then
        pcall(function()
            local row = CDataTable and CDataTable.GetTableData and CDataTable.GetTableData("LeisureSeasonParamCfg", "MinSegmentId")
            if row and row.Value then segId = tonumber(row.Value) end
        end)
    end
    return segId or 101
end

-- ==================== Badge UI Rendering ====================
local function badge_for_widget_render(badgeData)
    if not badgeData then return nil end
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return badgeData end
    local EB = cfg.EBadgePartType
    local Done = cfg.ERankTaskStatus.Completed
    local vis = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
    local out = {}
    for partType, partInfo in pairs(badgeData) do
        out[partType] = {}
        for taskId, taskInfo in pairs(partInfo) do
            local fc = taskInfo.finish_count
            local st = taskInfo.status or Done
            if partType == EB.Gem or partType == EB.Base then
                fc = vis
            elseif partType == EB.Glow then
                fc = 1
            elseif partType == EB.Crown then
                fc = vis
            end
            out[partType][taskId] = {
                finish_count = fc,
                status = st,
                trigger_value = taskInfo.trigger_value,
            }
        end
    end
    return out
end

local function get_display_badge()
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if not full then return nil end
    return badge_for_widget_render(full)
end

-- ==================== Server Cache ====================
local apply_server_badge_cfg_cache

local function get_fake_badge_part_cfg()
    local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
    if not ok or not cfg then return {} end
    local yearId = get_season_year_id()
    if _G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId] then
        return _G.SetRoleInfo_badge_part_cfg[yearId]
    end
    apply_server_badge_cfg_cache()
    return (_G.SetRoleInfo_badge_part_cfg and _G.SetRoleInfo_badge_part_cfg[yearId]) or {}
end

local function build_badge_part_cfg_list(count, stageId)
    local list = {}
    for i = 1, count do
        list[i] = {
            task_id = i,
            task_stage_id = stageId,
            finish_value = stageId,
            badge_cfg = { task_desc_id = 0, task_title_id = 0 },
        }
    end
    return list
end

apply_server_badge_cfg_cache = function()
    pcall(function()
        local ok, cfg = pcall(require, "client.logic.season_year.config.season_year_config")
        if not ok or not cfg then return end
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        local yearId = get_season_year_id()
        local EB = cfg.EBadgePartType
        local stage = math.min(3, tonumber(JOURNEY_BADGE_VISUAL_LEVEL) or 3)
        logic_season_year_badge.serverBadgeCfg = logic_season_year_badge.serverBadgeCfg or {}
        logic_season_year_badge.serverBadgeCfg[yearId] = {
            [EB.Gem] = build_badge_part_cfg_list(1, stage),
            [EB.Base] = build_badge_part_cfg_list(1, stage),
            [EB.Glow] = build_badge_part_cfg_list(JOURNEY_BADGE_GLOW_TASKS, 1),
            [EB.Crown] = build_badge_part_cfg_list(cfg.CrownTaskMaxCount or 10, stage),
        }
        logic_season_year_badge.seasonYearTaskInfo = logic_season_year_badge.seasonYearTaskInfo or {}
        logic_season_year_badge.seasonYearTaskInfo[1] = {
            task_id = 1,
            status = cfg.ERankTaskStatus.Completed,
            finish_count = JOURNEY_BADGE_LEVEL,
        }
        local taskYearId = yearId
        logic_season_year_badge.serverYearTaskCfg = logic_season_year_badge.serverYearTaskCfg or {}
        logic_season_year_badge.serverYearTaskCfg[taskYearId] = {
            task_cfgs = {
                [1] = {
                    reward_itemid_1 = 0,
                    reward_cnt_1 = 0,
                    reward_valid_hours_1 = 0,
                    task_desc_id = 0,
                },
            },
        }
        _G.SetRoleInfo_badge_part_cfg = _G.SetRoleInfo_badge_part_cfg or {}
        _G.SetRoleInfo_badge_part_cfg[yearId] = logic_season_year_badge.serverBadgeCfg[yearId]
    end)
end

local function cache_badge_all_year_ids(displayBadge)
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        logic_season_year_badge.seasonYearBadgeInfo = logic_season_year_badge.seasonYearBadgeInfo or {}
        local ids = {}
        local yid = get_season_year_id()
        ids[yid] = true
        if yid == 0 then ids[1] = true end
        pcall(function()
            if DataMgr and DataMgr.season_id and CDataTable and CDataTable.GetTableData then
                local row = CDataTable.GetTableData("SeasonInfo", DataMgr.season_id)
                if row and row.SeasonYearID then ids[row.SeasonYearID] = true end
            end
        end)
        for id, _ in pairs(ids) do
            logic_season_year_badge.seasonYearBadgeInfo[id] = displayBadge
        end
    end)
end

-- ==================== Ace Mark ====================
local function apply_ace_imprint_self()
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    local baseId = 10
    local showCnt = tonumber(JOURNEY_BADGE_LEVEL) or 17
    local showId = baseId + showCnt
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.roleData.ace_imprint_base_id = baseId
        DataMgr.roleData.ace_imprint_show_id = showId
        DataMgr.roleData.ace_imprint_show_cnt = showCnt
    end
    if DataMgr then
        DataMgr.ace_show_type = ace_config.EAceShowType.Honer
        DataMgr.ace_imprint_base_id = baseId
        DataMgr.ace_imprint_show_id = showId
        DataMgr.ace_imprint_show_cnt = showCnt
    end
    pcall(function()
        if LobbySystem and LobbySystem.roleData then
            LobbySystem.roleData.ace_show_type = ace_config.EAceShowType.Honer
            LobbySystem.roleData.ace_imprint_base_id = baseId
            LobbySystem.roleData.ace_imprint_show_id = showId
            LobbySystem.roleData.ace_imprint_show_cnt = showCnt
        end
    end)
end

-- ==================== Badge UI Helper ====================
local function try_set_badge_center_number(badge_ui, num)
    if not badge_ui or not badge_ui.UIRoot then return end
    local root = badge_ui.UIRoot
    local textNames = {
        "TextBlock_Level", "TextBlock_Num", "TextBlock_Number", "TextBlock_Num04",
        "TextBlock_Gem", "TextBlock_0", "TextBlock_1", "TextBlock_5", "TextBlock_6",
        "TextBlock_3", "TextBlock_4",
    }
    local str = tostring(num)
    local function try_widget(w)
        if w and w.SetText then
            w:SetText(str)
            return true
        end
    end
    for _, name in ipairs(textNames) do
        if try_widget(root[name]) then return end
    end
    for lv = 0, 3 do
        local panel = root["Panel_GemCrown" .. lv]
        if panel then
            for _, name in ipairs(textNames) do
                if try_widget(panel[name]) then return end
            end
        end
    end
end

local function hide_kingmark_placeholder(root)
    if not root then return end
    pcall(function()
        if root.Image_69 then
            root.Image_69:SetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
    end)
end

local function apply_journey_kingmark_fallback(ui)
    if not ui or not ui.UIRoot or not ui.UIRoot.SizeBox_Badge_Root then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    pcall(function()
        if ui._SetRoleInfo_journey_kingmark and ui._SetRoleInfo_journey_kingmark.Close then
            ui._SetRoleInfo_journey_kingmark:Close()
        end
    end)
    local child = nil
    pcall(function()
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.Common_KingMark_UIBP_2 then
            child = ui:CreateChildWindow(box, UIManager.UI_Config.Common_KingMark_UIBP_2, 4)
        end
    end)
    if not child then
        pcall(function()
            local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
            if UIComponentModule and UIComponentModule.InitWithParentComponent then
                child = UIComponentModule:InitWithParentComponent(
                    ui, UIComponentModule.Config.Common_KingMark_UIBP_2, box, 4
                )
            end
        end)
    end
    if child and child.SetWidgetInfo then
        ui._SetRoleInfo_journey_kingmark = child
        child:SetWidgetInfo(10, { advance_num = JOURNEY_BADGE_LEVEL, history_num = 0 })
        try_set_badge_center_number(child, JOURNEY_BADGE_LEVEL)
        pcall(function()
            if child.Show then child:Show() end
            if child.UIRoot and child.UIRoot.SetVisibility then
                child.UIRoot:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end
        end)
        return true
    end
    return false
end

local function apply_journey_season_badge_widget(ui, renderBadge)
    if not ui or not ui.UIRoot or not renderBadge then return false end
    local root = ui.UIRoot
    local box = root.SizeBox_Badge_Root
    if not box then return false end

    local ok_apply = false
    if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
        ui.season_year_badge:SetBadgeInfo(renderBadge, false)
        try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
        ok_apply = true
    end

    if not ok_apply and UIManager and UIManager.UI_Config and UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP then
        pcall(function()
            if ui.season_year_badge and ui.CloseChildWindow then
                ui:CloseChildWindow(ui.season_year_badge)
            end
        end)
        ui.season_year_badge = nil
        pcall(function()
            ui.season_year_badge = ui:CreateChildWindow(
                box, UIManager.UI_Config.Lobby_Season_Badge_Item_UIBP, renderBadge
            )
        end)
        if (not ui.season_year_badge) then
            pcall(function()
                local UIComponentModule = require("client.slua.component.UIComponentModule.UIComponentModule")
                if UIComponentModule and UIComponentModule.InitWithParentComponent then
                    ui.season_year_badge = UIComponentModule:InitWithParentComponent(
                        ui, UIComponentModule.Config.SeasonYear_Badge_Item_UIBP, box, renderBadge
                    )
                end
            end)
        end
        if ui.season_year_badge and ui.season_year_badge.SetBadgeInfo then
            ui.season_year_badge:SetBadgeInfo(renderBadge, false)
            try_set_badge_center_number(ui.season_year_badge, JOURNEY_BADGE_LEVEL)
            ok_apply = true
        end
    end
    return ok_apply
end

-- ==================== Apply Rank to Profile ====================
local function apply_history_max_segment(profile)
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not profile or type(profile) ~= "table" then return end
    profile.history_max_segment_level = profile.history_max_segment_level or {}
    profile.history_max_segment_season_id = profile.history_max_segment_season_id or {}
    for z = 1, ZONE_COUNT do
        profile.history_max_segment_level[z] = HISTORY_SEGMENT
        profile.history_max_segment_season_id[z] = profile.history_max_segment_season_id[z]
            or (DataMgr and DataMgr.season_id) or 0
    end
end

local function get_star_rating()
    if tonumber(CURRENT_SEGMENT) ~= 801 then
        return tonumber(CURRENT_RATING) or 0
    end
    local stars = tonumber(DISPLAY_STARS) or 0
    if stars > 0 then
        return rating_from_stars(stars)
    end
    return tonumber(CURRENT_RATING) or 0
end

local function apply_profile_badge_fields(profile)
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not profile or type(profile) ~= "table" then return end
    local fullBadge = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    local displayBadge = fullBadge and badge_for_widget_render(fullBadge) or nil
    if fullBadge then
        profile.season_year_badge_info = fullBadge
        local yearId = get_season_year_id()
        profile.season_year_badge = profile.season_year_badge or {}
        profile.season_year_badge[yearId] = displayBadge or fullBadge
    end
    local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
    profile.ace_show_type = ace_config.EAceShowType.Honer
    profile.ace_imprint_base_id = 10
    profile.ace_imprint_show_id = 10 + JOURNEY_BADGE_LEVEL
    profile.ace_imprint_show_cnt = JOURNEY_BADGE_LEVEL
    profile.casual_segment_id = get_season_series_segment_id()
end

local function apply_profile_rank_fields(profile)
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not profile or type(profile) ~= "table" then return end
    local titleId = resolve_conqueror_title_id()
    local rating = get_star_rating()

    profile.segment_info = build_allzone_segment(CURRENT_SEGMENT)
    profile.rankdata = build_rankdata(rating)
    profile.cur_max_segment_level = CURRENT_SEGMENT
    apply_history_max_segment(profile)

    local htitle = build_hsegment_title(titleId)
    if htitle then
        profile.hsegment_title_det = htitle
    end

    local peakInfo = build_peakgame_segment_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakInfo then
        profile.peakgame_segment_info = peakInfo
    end
    profile.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
end

local function apply_profile_extras(profile)
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not profile or type(profile) ~= "table" then return end
    apply_profile_rank_fields(profile)
    apply_profile_badge_fields(profile)
    if is_self_uid(profile.uid) then
        profile.registertime = get_fake_registertime()
    end
end

-- ==================== Force Badge ====================
local function ensure_force_badge()
    if not _G.FormulaFeatureEnabled("rankProgress") then return nil end
    local full = build_season_year_badge(JOURNEY_BADGE_LEVEL)
    if full then
        _G.SetRoleInfo_force_badge_full = full
        _G.SetRoleInfo_force_badge = get_display_badge() or badge_for_widget_render(full)
    end
    return _G.SetRoleInfo_force_badge
end

local function apply_season_year_badge_cache()
    if not ENABLE_SEASON_YEAR_BADGE then return end
    local displayBadge = ensure_force_badge()
    if not displayBadge then return end
    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if not logic_season_year_badge then return end
        cache_badge_all_year_ids(displayBadge)
        logic_season_year_badge.loginDays = JOURNEY_BADGE_LEVEL
        local cfg = require("client.logic.season_year.config.season_year_config")
        logic_season_year_badge.badgeShowType = cfg.EBadgeShowType.Show
        apply_server_badge_cfg_cache()
        apply_ace_imprint_self()
    end)
end

-- ==================== UI Force Refresh ====================
local function force_classic_career_highest(ui)
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local seasonId = (DataMgr and DataMgr.season_id) or 0
    local w = root.Common_RankIntegralLevel_Style_Large_UIBP_C_2
    if not w then return end
    pcall(function()
        if w.SetRankInteralBySeason then
            w:SetRankInteralBySeason(HISTORY_SEGMENT, nil, seasonId)
        elseif w.SetRankInteralWithSegmentTitle then
            w:SetRankInteralWithSegmentTitle(HISTORY_SEGMENT, nil, seasonId, 0, get_star_rating())
        elseif w.SetRankInteral then
            w:SetRankInteral(HISTORY_SEGMENT, nil)
        end
    end)
end

local function force_roleinfo_journey_badge(ui)
    if not ui or not ui.UIRoot then return end
    local root = ui.UIRoot
    local renderBadge = ensure_force_badge()
    if not renderBadge then return end

    if LocUtil and root.TextBlock_47 then
        pcall(function() root.TextBlock_47:SetText(LocUtil.GetLocalizeResStr(85103)) end)
    end
    if root.TextBlock_21 and LocUtil then
        pcall(function() root.TextBlock_21:SetText(LocUtil.GetLocalizeResStr(68405)) end)
    end
    ui:SetWidgetVisible(root.SizeBox_Badge_Root, true)
    hide_kingmark_placeholder(root)
    if root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
        ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, SHOW_SEASON_SERIES_MEDAL)
    end

    local ok = apply_journey_season_badge_widget(ui, renderBadge)
    if not ok then
        apply_journey_kingmark_fallback(ui)
    end
end

local function force_roleinfo_profile_slots(ui)
    force_classic_career_highest(ui)
    force_roleinfo_journey_badge(ui)
end

local function apply_roleinfo_badges_ui()
    apply_season_year_badge_cache()
    pcall(function()
        local ui = UIManager.GetUI(UIManager.UI_Config.roleinfo_segment)
        if not ui or not ui.UIRoot then return end
        local root = ui.UIRoot

        force_roleinfo_profile_slots(ui)

        if SHOW_SEASON_SERIES_MEDAL and root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
            ui:SetWidgetVisible(root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, true)
            local leisure_season_util = require("client.slua.logic.leisure.leisure_season_util")
            leisure_season_util.SetRankBigIcon(
                root.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1,
                get_season_series_segment_id()
            )
            if ui.RefreshCasualSegment then
                ui:RefreshCasualSegment()
            end
        end
    end)
end

-- ==================== DataMgr Data Injection ====================
local function apply_data_mgr_ranks()
    if not DataMgr or not DataMgr.roleData then return end
    local rd = DataMgr.roleData
    local cur = CURRENT_SEGMENT
    local rating = get_star_rating()

    rd.segment = rd.segment or {}
    rd.segment.solo = cur
    rd.segment.double = cur
    rd.segment.team = cur
    rd.segment.fpp_solo = cur
    rd.segment.fpp_double = cur
    rd.segment.fpp_team = cur
    rd.allzoneSegment = build_allzone_segment(cur)

    rd.rankdata = build_rankdata(rating)

    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        rd.allzoneSegmentTitle = build_hsegment_title(titleId)
    end

    DataMgr.isSeasonStarOpen = true
    rd.is_season_star_open = true

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        SeasonSystem.segment.team.level = cur
        SeasonSystem.segment.team.rating = rating
    end)

    pcall(function()
        DataMgr.maxSegmentSquad = DataMgr.maxSegmentSquad or { zoneid = 1, SegmentLevel = 0 }
        DataMgr.maxSegmentSquad.SegmentLevel = cur
        DataMgr.maxSegmentSquad.zoneid = 1
    end)

    local peakList = build_peakgame_rating_info(PEAK_CURRENT_SEGMENT, PEAK_CURRENT_SEGMENT, PEAK_RATING)
    if peakList then
        rd.peakgame_rating_info = peakList
    end
    rd.peakgame_history_max_segment = PEAK_HISTORY_SEGMENT
    rd.casual_segment_id = get_season_series_segment_id()
    DataMgr.registertime = get_fake_registertime()
end

local function apply_personal_basic()
    local ok, RoleInfoMainSystem = pcall(require, "client.logic.roleinfo.logic_new_roleinfo")
    if not ok or not RoleInfoMainSystem then return end
    local pbi = RoleInfoSystem.PersonalBasicInfo
    if not pbi or type(pbi) ~= "table" then return end

    pbi.all_segment_info = build_allzone_segment(CURRENT_SEGMENT)
    local titleId = resolve_conqueror_title_id()
    if titleId > 0 then
        pbi.hsegment_title_det = build_hsegment_title(titleId)
    end

    local zoneId = 1
    if RoleInfoMainSystem.GetShowRoleinfoOfZoneID then
        zoneId = RoleInfoMainSystem.GetShowRoleinfoOfZoneID() or 1
    end
    if zoneId == 0 then zoneId = 1 end
    local zs = pbi.all_segment_info[zoneId]
    if zs then
        local fields = {
            "role_segment_solo", "role_segment_double", "role_segment_team",
            "role_segmentFPP_solo", "role_segmentFPP_double", "role_segmentFPP_team",
            "curr_role_segment_solo", "curr_role_segment_double", "curr_role_segment_team",
            "curr_role_segmentFPP_solo", "curr_role_segmentFPP_double", "curr_role_segmentFPP_team",
        }
        local vals = {
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
            zs[SEGMENT_TYPE.solo], zs[SEGMENT_TYPE.double], zs[SEGMENT_TYPE.team],
            zs[SEGMENT_TYPE.fpp_solo], zs[SEGMENT_TYPE.fpp_double], zs[SEGMENT_TYPE.fpp_team],
        }
        for i, f in ipairs(fields) do
            pbi[f] = vals[i]
        end
    end
    pbi.role_all_zone_segment_max = CURRENT_SEGMENT
end

-- ==================== Final Apply ====================
local function apply_extra_settings()
    if not _G.FormulaFeatureEnabled("profileIdentity") then return end
    if DataMgr and DataMgr.roleData then
        DataMgr.roleData.level = PLAYER_LEVEL

        -- Star User selected -> Use user's choice; not selected -> Use default
        local userA = math.floor(tonumber(_G.__BeysaUserAvatarPick) or 0)
        local userB = math.floor(tonumber(_G.__BeysaUserFramePick)  or 0)
        local targetA = (userA > 0) and userA or AVATAR_ID
        local targetB = (userB > 0) and userB or AVATAR_BOX_ID

        DataMgr.roleData.pic_url = targetA
        DataMgr.roleData.headIconUrl = targetA
        DataMgr.roleData.pic_url_check_open = true
        DataMgr.roleData.cur_avatar_box_id = targetB
        print("[SetRoleInfo] Set: Level=" .. tostring(PLAYER_LEVEL)
              .. ", Avatar=" .. tostring(targetA)
              .. ", Avatar Frame=" .. tostring(targetB))
    end
end

local function apply_history_to_self_caches()
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ok, logic_profile = pcall(function()
        return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    end)
    if ok and logic_profile then
        for _, bucket in ipairs({ logic_profile.dicFriend, logic_profile.dicStranger }) do
            if bucket and bucket[uid] then
                apply_profile_extras(bucket[uid])
            end
        end
        local profile = logic_profile:GetLocalProfile(uid) or logic_profile:GetLocalProfile(uid, true)
        if profile then
            apply_profile_extras(profile)
        end
    end
end

-- ==================== UI Patch ====================
local function patch_conqueror_star_ui()
    if _G.SetRoleInfo_star_ui_patched then return end

    pcall(function()
        local RIClass = require("client.slua.umg.rankIntegral.RankIntegralIconSmall")
        if RIClass and RIClass.SetRankInteralWithSegmentTitle and not RIClass._SetRoleInfo_orig_RII then
            RIClass._SetRoleInfo_orig_RII = RIClass.SetRankInteralWithSegmentTitle
            RIClass.SetRankInteralWithSegmentTitle = function(self, segment, textName, seasonId, titleId, rating)
                if _G.FormulaFeatureEnabled("rankProgress")
                   and tonumber(segment) == 801 and (not rating or tonumber(rating) == 0) then
                    rating = get_star_rating()
                end
                return RIClass._SetRoleInfo_orig_RII(self, segment, textName, seasonId, titleId, rating)
            end
        end
    end)

    pcall(function()
        local BaseClass = require("client.slua.umg.rankIntegral.RankSmall_Sub_Base_UIBP")
        if BaseClass and BaseClass.SetRankInteralWithSegmentTitle and not BaseClass._SetRoleInfo_orig_Base then
            BaseClass._SetRoleInfo_orig_Base = BaseClass.SetRankInteralWithSegmentTitle
            BaseClass.SetRankInteralWithSegmentTitle = function(self)
                if _G.FormulaFeatureEnabled("rankProgress")
                   and tonumber(self.rankIntegral) == 801 and (not self.rating or tonumber(self.rating) == 0) then
                    self.rating = get_star_rating()
                end
                return BaseClass._SetRoleInfo_orig_Base(self)
            end
        end
    end)

    pcall(function()
        local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
        if logic_segment_title and not logic_segment_title._SetRoleInfo_orig_MaxTitle then
            logic_segment_title._SetRoleInfo_orig_MaxTitle = logic_segment_title.SetMaxSegmentRankInteralWithTitle
            logic_segment_title.SetMaxSegmentRankInteralWithTitle = function(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                if not _G.FormulaFeatureEnabled("rankProgress") then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                if not slua.isValid(widget) or not allSegmentInfo then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                local maxSegment, zoneid, modeid = self:GetMaxSegementLevelWithZoneAndModeId(allSegmentInfo)
                if not maxSegment or maxSegment <= 0 then
                    return logic_segment_title._SetRoleInfo_orig_MaxTitle(self, widget, allSegmentInfo, allZoneSegmentTitle, seasonId)
                end
                widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if seasonId and seasonId ~= 0 and seasonId ~= DataMgr.season_id then
                    widget:SetRankInteralBySeason(maxSegment, nil, seasonId)
                    return
                end
                local segmentTitleId = self:GetSegmentTitleId(allZoneSegmentTitle, zoneid, modeid)
                local rating = (tonumber(maxSegment) == 801) and get_star_rating() or nil
                local sid = seasonId or DataMgr.season_id
                if not segmentTitleId or tonumber(segmentTitleId) == 0 then
                    if rating and rating > 0 then
                        widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, 0, rating)
                    else
                        widget:SetRankInteralBySeason(maxSegment, nil, sid)
                    end
                else
                    widget:SetRankInteralWithSegmentTitle(maxSegment, nil, sid, segmentTitleId, rating)
                end
            end
        end
    end)

    pcall(function()
        local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
        if LobbySocialSystem and not LobbySocialSystem._SetRoleInfo_self_prof then
            LobbySocialSystem._SetRoleInfo_self_prof = true
            local orig = LobbySocialSystem.GetSelfProfile
            LobbySocialSystem.GetSelfProfile = function()
                local p = orig()
                if _G.FormulaFeatureEnabled("rankProgress") and p and tonumber(CURRENT_SEGMENT) == 801 then
                    p.rankdata = build_rankdata(get_star_rating())
                end
                if p and ENABLE_SEASON_YEAR_BADGE then
                    apply_profile_badge_fields(p)
                end
                return p
            end
        end
        if LobbySocialSystem and LobbySocialSystem.GetAceImprintShowId and not LobbySocialSystem._SetRoleInfo_ace_show then
            LobbySocialSystem._SetRoleInfo_ace_show = true
            local origAce = LobbySocialSystem.GetAceImprintShowId
            LobbySocialSystem.GetAceImprintShowId = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE then
                    return 10 + JOURNEY_BADGE_LEVEL, 10, JOURNEY_BADGE_LEVEL
                end
                return origAce(uid)
            end
        end
    end)

    if _G.FormulaFeatureEnabled("rankProgress") then
        pcall(function()
            local SeasonHandler = require("client.network.Protocol.SeasonHandler")
            if not _G.__FORMULA_HAS_ORIG_SEASON_RANK_RATING then
                _G.__FORMULA_ORIG_SEASON_RANK_RATING = SeasonHandler.rank_rating
                _G.__FORMULA_HAS_ORIG_SEASON_RANK_RATING = true
            end
            SeasonHandler.rank_rating = get_star_rating()
        end)
    end

    _G.SetRoleInfo_star_ui_patched = true
end

-- ==================== Badge and Casual Season Patch ====================
local function patch_badge_and_leisure_hooks()
    if _G.SetRoleInfo_badge_hooks_patched then return end
    _G.SetRoleInfo_badge_hooks_patched = true

    pcall(function()
        local season_year_util = require("client.logic.season_year.util.season_year_util")
        if season_year_util and season_year_util.CheckFunctionIsOpen and not season_year_util._SetRoleInfo_orig_CheckOpen then
            season_year_util._SetRoleInfo_orig_CheckOpen = season_year_util.CheckFunctionIsOpen
            season_year_util.CheckFunctionIsOpen = function()
                if ENABLE_SEASON_YEAR_BADGE then return true end
                return season_year_util._SetRoleInfo_orig_CheckOpen()
            end
        end
    end)

    pcall(function()
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeInfo
            and not logic_season_year_badge._SetRoleInfo_orig_GetBadge then
            logic_season_year_badge._SetRoleInfo_orig_GetBadge = logic_season_year_badge.GetCurSeasonYearBadgeInfo
            local origGetBadge = logic_season_year_badge._SetRoleInfo_orig_GetBadge
            logic_season_year_badge.GetCurSeasonYearBadgeInfo = function(self)
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = origGetBadge(self)
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_info_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_badge_rsp = true
            local orig = logic_season_year_badge.on_get_season_year_badge_info_rsp
            logic_season_year_badge.on_get_season_year_badge_info_rsp = function(self, badge_info)
                if ENABLE_SEASON_YEAR_BADGE then
                    apply_season_year_badge_cache()
                    if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
                        EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
                    end
                    return
                end
                orig(self, badge_info)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            and not logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp then
            logic_season_year_badge._SetRoleInfo_wrapped_cfg_rsp = true
            local origCfg = logic_season_year_badge.on_get_season_year_badge_cfg_rsp
            logic_season_year_badge.on_get_season_year_badge_cfg_rsp = function(self, info)
                origCfg(self, info)
                apply_server_badge_cfg_cache()
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetBadgeShowType
            and not logic_season_year_badge._SetRoleInfo_orig_ShowType then
            logic_season_year_badge._SetRoleInfo_orig_ShowType = logic_season_year_badge.GetBadgeShowType
            logic_season_year_badge.GetBadgeShowType = function(self)
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return logic_season_year_badge._SetRoleInfo_orig_ShowType(self)
            end
        end
        if logic_season_year_badge and logic_season_year_badge.GetCurSeasonYearBadgeCfg
            and not logic_season_year_badge._SetRoleInfo_orig_GetCfg then
            logic_season_year_badge._SetRoleInfo_orig_GetCfg = logic_season_year_badge.GetCurSeasonYearBadgeCfg
            logic_season_year_badge.GetCurSeasonYearBadgeCfg = function(self)
                if ENABLE_SEASON_YEAR_BADGE then apply_server_badge_cfg_cache() end
                local cfg = logic_season_year_badge._SetRoleInfo_orig_GetCfg(self)
                if not ENABLE_SEASON_YEAR_BADGE or (cfg and next(cfg)) then return cfg end
                local yearId = get_season_year_id()
                return self.serverBadgeCfg and self.serverBadgeCfg[yearId] or {}
            end
        end
    end)

    pcall(function()
        local season_year_badge_util = require("client.logic.season_year.util.season_year_badge_util")
        if season_year_badge_util.CheckGotBadge and not season_year_badge_util._SetRoleInfo_orig_Got then
            season_year_badge_util._SetRoleInfo_orig_Got = season_year_badge_util.CheckGotBadge
            season_year_badge_util.CheckGotBadge = function(badgeData)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return true
                end
                return season_year_badge_util._SetRoleInfo_orig_Got(badgeData)
            end
        end
        if season_year_badge_util.GetBadgeShowType and not season_year_badge_util._SetRoleInfo_orig_UtilShow then
            season_year_badge_util._SetRoleInfo_orig_UtilShow = season_year_badge_util.GetBadgeShowType
            season_year_badge_util.GetBadgeShowType = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    local cfg = require("client.logic.season_year.config.season_year_config")
                    return cfg.EBadgeShowType.Show
                end
                return season_year_badge_util._SetRoleInfo_orig_UtilShow()
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgeInfo and not season_year_badge_util._SetRoleInfo_orig_GetInfo then
            season_year_badge_util._SetRoleInfo_orig_GetInfo = season_year_badge_util.GetCurSeasonYearBadgeInfo
            season_year_badge_util.GetCurSeasonYearBadgeInfo = function()
                apply_season_year_badge_cache()
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                local data = season_year_badge_util._SetRoleInfo_orig_GetInfo()
                if ENABLE_SEASON_YEAR_BADGE and (not data or not next(data)) then
                    return ensure_force_badge() or data
                end
                return data
            end
        end
        if season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo and not season_year_badge_util._SetRoleInfo_orig_PartCfg then
            season_year_badge_util._SetRoleInfo_orig_PartCfg = season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo
            season_year_badge_util.GetCurSeasonYearBadgePartCfgInfo = function(partType)
                local c = season_year_badge_util._SetRoleInfo_orig_PartCfg(partType)
                if not ENABLE_SEASON_YEAR_BADGE or (c and next(c)) then return c end
                local fake = get_fake_badge_part_cfg()
                return fake[partType] or {}
            end
        end
        if season_year_badge_util.GetSeasonYearBadge and not season_year_badge_util._SetRoleInfo_orig_GetByUid then
            season_year_badge_util._SetRoleInfo_orig_GetByUid = season_year_badge_util.GetSeasonYearBadge
            season_year_badge_util.GetSeasonYearBadge = function(uid)
                if is_self_uid(uid) and ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    return _G.SetRoleInfo_force_badge
                end
                return season_year_badge_util._SetRoleInfo_orig_GetByUid(uid)
            end
        end
    end)

    pcall(function()
        local BadgeClass = require("client.slua.umg.Lobby_SeasonUI.Season2026.Item.Lobby_Season_Badge_Item_UIBP")
        if BadgeClass and BadgeClass.SetBadgeInfo and not BadgeClass._SetRoleInfo_orig_SetBadge then
            BadgeClass._SetRoleInfo_orig_SetBadge = BadgeClass.SetBadgeInfo
            BadgeClass.SetBadgeInfo = function(self, badgeData, bPlayLevelUpAni)
                local renderData = badgeData
                if ENABLE_SEASON_YEAR_BADGE then
                    renderData = _G.SetRoleInfo_force_badge
                        or badge_for_widget_render(badgeData) or badgeData
                end
                BadgeClass._SetRoleInfo_orig_SetBadge(self, renderData, bPlayLevelUpAni)
                if ENABLE_SEASON_YEAR_BADGE then
                    try_set_badge_center_number(self, JOURNEY_BADGE_LEVEL)
                end
            end
        end
        if BadgeClass and BadgeClass.SetBadgeGemInfo and not BadgeClass._SetRoleInfo_orig_SetGem then
            BadgeClass._SetRoleInfo_orig_SetGem = BadgeClass.SetBadgeGemInfo
            BadgeClass.SetBadgeGemInfo = function(self, gemData, newActiveGemData)
                if ENABLE_SEASON_YEAR_BADGE then apply_server_badge_cfg_cache() end
                return BadgeClass._SetRoleInfo_orig_SetGem(self, gemData, newActiveGemData)
            end
        end
        if BadgeClass and BadgeClass.PlayBadgePartLevelUpAnimation and not BadgeClass._SetRoleInfo_orig_Anim then
            BadgeClass._SetRoleInfo_orig_Anim = BadgeClass.PlayBadgePartLevelUpAnimation
            BadgeClass.PlayBadgePartLevelUpAnimation = function(self, partType, level, bPlayAnimation)
                if ENABLE_SEASON_YEAR_BADGE then
                    level = math.min(3, math.max(0, tonumber(level) or 0))
                end
                return BadgeClass._SetRoleInfo_orig_Anim(self, partType, level, bPlayAnimation)
            end
        end
    end)

    pcall(function()
        local RoleInfoUI = require("client.slua.umg.PersonSpace.Lobby_RoleInfo_Segment180_UIBP")
        if RoleInfoUI and RoleInfoUI.OnSeasonYearBadgeUpdate and not RoleInfoUI._SetRoleInfo_wrapped_badge_ui then
            RoleInfoUI._SetRoleInfo_wrapped_badge_ui = true
            local orig = RoleInfoUI.OnSeasonYearBadgeUpdate
            RoleInfoUI.OnSeasonYearBadgeUpdate = function(self)
                apply_season_year_badge_cache()
                local renderBadge = ensure_force_badge()
                if renderBadge then
                    apply_journey_season_badge_widget(self, renderBadge)
                    if not (self.season_year_badge and self.season_year_badge.UIRoot) then
                        apply_journey_kingmark_fallback(self)
                    end
                else
                    orig(self)
                end
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnGetSelfRoleInfoCallBack and not RoleInfoUI._SetRoleInfo_wrapped_hist then
            RoleInfoUI._SetRoleInfo_wrapped_hist = true
            local origCb = RoleInfoUI.OnGetSelfRoleInfoCallBack
            RoleInfoUI.OnGetSelfRoleInfoCallBack = function(self, list)
                if list and list[1] then
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                origCb(self, list)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.UpdateUI and not RoleInfoUI._SetRoleInfo_wrapped_updateui then
            RoleInfoUI._SetRoleInfo_wrapped_updateui = true
            local origUp = RoleInfoUI.UpdateUI
            RoleInfoUI.UpdateUI = function(self)
                origUp(self)
                force_roleinfo_profile_slots(self)
            end
        end
        if RoleInfoUI and RoleInfoUI.OnPostInitialize and not RoleInfoUI._SetRoleInfo_wrapped_post then
            RoleInfoUI._SetRoleInfo_wrapped_post = true
            local origPost = RoleInfoUI.OnPostInitialize
            RoleInfoUI.OnPostInitialize = function(self, ...)
                apply_season_year_badge_cache()
                origPost(self, ...)
                local function refresh()
                    apply_season_year_badge_cache()
                    force_roleinfo_profile_slots(self)
                end
                refresh()
                if self.AddTimerOnce then
                    self:AddTimerOnce(0.05, refresh)
                    self:AddTimerOnce(0.15, refresh)
                    self:AddTimerOnce(0.5, refresh)
                    self:AddTimerOnce(1.0, refresh)
                    self:AddTimerOnce(2.0, refresh)
                end
            end
        end
        if RoleInfoUI and RoleInfoUI.RefreshAceImprint and not RoleInfoUI._SetRoleInfo_wrapped_ace then
            RoleInfoUI._SetRoleInfo_wrapped_ace = true
            local origAce = RoleInfoUI.RefreshAceImprint
            RoleInfoUI.RefreshAceImprint = function(self)
                apply_ace_imprint_self()
                origAce(self)
                hide_kingmark_placeholder(self.UIRoot)
            end
        end
    end)

    pcall(function()
        local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
        if RoleInfoMainSystem and RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            and not RoleInfoMainSystem._SetRoleInfo_orig_hist then
            RoleInfoMainSystem._SetRoleInfo_orig_hist = RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId
            RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId = function(historyLevels, seasonTable)
                if tonumber(HISTORY_SEGMENT) and HISTORY_SEGMENT > 0 then
                    local sid = (DataMgr and DataMgr.season_id) or 0
                    if seasonTable and next(seasonTable) then
                        for z, s in pairs(seasonTable) do
                            if tonumber(s) and s > sid then sid = s end
                        end
                    end
                    return HISTORY_SEGMENT, sid
                end
                return RoleInfoMainSystem._SetRoleInfo_orig_hist(historyLevels, seasonTable)
            end
        end
    end)

    pcall(function()
        local AchUI = require("client.slua.umg.Lobby_SeasonUI.Season2026.Lobby_Season_AnnualAchievement_UIBP")
        if AchUI and AchUI.UpdateUI and not AchUI._SetRoleInfo_wrapped_update then
            AchUI._SetRoleInfo_wrapped_update = true
            local origUp = AchUI.UpdateUI
            AchUI.UpdateUI = function(self)
                apply_season_year_badge_cache()
                origUp(self)
                if ENABLE_SEASON_YEAR_BADGE and _G.SetRoleInfo_force_badge then
                    local renderBadge = badge_for_widget_render(_G.SetRoleInfo_force_badge)
                    if self.CompBadge01 and self.CompBadge01.SetBadgeInfo then
                        self.CompBadge01:SetBadgeInfo(renderBadge, true)
                    end
                end
            end
        end
    end)

    pcall(function()
        local SeasonSystem = require("client.logic.season.logic_season")
        if SeasonSystem and SeasonSystem.GetBestSegment and not SeasonSystem._SetRoleInfo_orig_best then
            SeasonSystem._SetRoleInfo_orig_best = SeasonSystem.GetBestSegment
            SeasonSystem.GetBestSegment = function()
                if ENABLE_SEASON_YEAR_BADGE then
                    return CURRENT_SEGMENT
                end
                return SeasonSystem._SetRoleInfo_orig_best()
            end
        end
    end)

    pcall(function()
        local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
        if logic_leisure_season and not logic_leisure_season._SetRoleInfo_orig_GetSeg then
            logic_leisure_season._SetRoleInfo_orig_GetSeg = logic_leisure_season.GetLeisureSegmentID
            logic_leisure_season.GetLeisureSegmentID = function(self)
                return get_season_series_segment_id()
            end
            logic_leisure_season._SetRoleInfo_orig_GetSegUID = logic_leisure_season.GetLeisureSegmentIDByUID
            logic_leisure_season.GetLeisureSegmentIDByUID = function(self, uid)
                if is_self_uid(uid) then
                    return get_season_series_segment_id()
                end
                return logic_leisure_season._SetRoleInfo_orig_GetSegUID(self, uid)
            end
        end
    end)
end

-- ==================== UI Event Refresh ====================
local function post_ui_refresh_events()
    pcall(function()
        if EventSystem and EVENTTYPE_ROLEINFO and EVENTID_ROLEINFO_UPDATE_ROLEINFO then
            EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO)
        end
        if EventSystem and EVENTTYPE_PEAKGAME and EVENTID_PEAKGAME_RATING_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_PEAKGAME, EVENTID_PEAKGAME_RATING_NOTIFY)
        end
        if EventSystem and EVENTTYPE_SEASON_YEAR and EVENTID_SEASON_YEAR_BADGE_UPDATE then
            EventSystem:postEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE)
        end
        if EventSystem and EVENTTYPE_LEISURE_SEASON and EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY then
            EventSystem:postEvent(EVENTTYPE_LEISURE_SEASON, EVENTID_LEISURE_SEASON_SEGMENT_NOTIFY)
        end
        if EventSystem and EVENTTYPE_DATA_MGR and EVENTID_ACE_IMPRINT_UPDATE then
            EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_ACE_IMPRINT_UPDATE)
        end
    end)
end

-- ==================== Bottom Profile Stats ====================
local function apply_bottom_profile_stats()
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then return end
    local uid = tonumber(DataMgr.roleData.uid)
    local ratingStr = tostring(SEASON_RATING)
    for zoneId = 1, ZONE_COUNT do
        RoleInfoSystem.CurrSeasonTPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonFPPTotalScore[zoneId] = SEASON_RATING
        RoleInfoSystem.CurrSeasonTPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.CurrSeasonFPPTotalRank[zoneId] = SEASON_RANK
        RoleInfoSystem.PersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.PersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
        RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId] = { role_totalscore = ratingStr }
        RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId] = { role_totalrank = SEASON_RANK }
    end
    if RoleInfoSystem.SetElementToString then
        pcall(function()
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.PersonalTotalRankInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalScoreInfo)
            RoleInfoSystem.SetElementToString(RoleInfoSystem.FPPPersonalTotalRankInfo)
        end)
    end
    local ok, AchieveHandler = pcall(require, "client.network.Protocol.AchieveHandler")
    if ok and AchieveHandler then
        AchieveHandler.resSummaryTb[uid] = AchieveHandler.resSummaryTb[uid] or {}
        AchieveHandler.resSummaryTb[uid].achieve_score = ACHIEVEMENT_POINTS
        AchieveHandler.resSummaryTb[uid].uid = uid
    end
    apply_data_mgr_ranks()
    apply_ace_imprint_self()
    patch_conqueror_star_ui()
    pcall(function()
        local SeasonHandler = require("client.network.Protocol.SeasonHandler")
        if tonumber(CURRENT_SEGMENT) == 801 then
            SeasonHandler.rank_rating = get_star_rating()
        end
    end)
    patch_badge_and_leisure_hooks()
    apply_season_year_badge_cache()
    apply_roleinfo_badges_ui()
    apply_personal_basic()
    apply_history_to_self_caches()
    apply_extra_settings()
    post_ui_refresh_events()
end

-- ==================== Main Function ====================
local function apply_all()
    if not _G.FormulaFeatureEnabled("rankProgress") then return end
    apply_bottom_profile_stats()
end

local function install_refresh_hooks()
    if _G.SetRoleInfo_hooks_installed then return end
    _G.SetRoleInfo_hooks_installed = true
    patch_conqueror_star_ui()
    patch_badge_and_leisure_hooks()

    pcall(function()
        if RoleInfoSystem.get_role_basic_info_rsp and not RoleInfoSystem._SetRoleInfo_wrapped then
            RoleInfoSystem._SetRoleInfo_wrapped = true
            local orig = RoleInfoSystem.get_role_basic_info_rsp
            RoleInfoSystem.get_role_basic_info_rsp = function(list)
                orig(list)
                if list and list[1] then
                    apply_profile_rank_fields(list[1])
                    apply_history_max_segment(list[1])
                    apply_profile_badge_fields(list[1])
                end
                apply_all()
            end
        end
    end)

    if Timer and Timer.New then
        if _G.SetRoleInfo_timer then
            pcall(function() _G.SetRoleInfo_timer:Stop() end)
        end
        _G.SetRoleInfo_timer = Timer.New(function()
            apply_all()
        end, 3, 0)
        _G.SetRoleInfo_timer:Start()
    end
end

-- ==================== Switch-controlled startup ====================
-- Hooks and profile data are installed only after the menu switch is enabled.
_G.FORMULA_ApplyProfileProgress = function(enabled)
    ENABLE_SEASON_YEAR_BADGE = (enabled == true)
    if not enabled then
        _G.SetRoleInfo_force_badge = nil
        _G.SetRoleInfo_force_badge_full = nil
        if _G.__FORMULA_HAS_ORIG_SEASON_RANK_RATING then
            pcall(function()
                local SeasonHandler = require("client.network.Protocol.SeasonHandler")
                SeasonHandler.rank_rating = _G.__FORMULA_ORIG_SEASON_RANK_RATING
            end)
            _G.__FORMULA_ORIG_SEASON_RANK_RATING = nil
            _G.__FORMULA_HAS_ORIG_SEASON_RANK_RATING = nil
        end
        return true
    end
    pcall(ensure_force_badge)
    pcall(apply_all)
    pcall(install_refresh_hooks)
    return true
end

log_msg(string.format(
    "Conqueror %d | Stars=%d | Points=%d | Journey Badge=%d | Casual Season Rank=%d | Level=%d",
    CURRENT_SEGMENT, CONQUEROR_STARS, get_star_rating(),
    JOURNEY_BADGE_LEVEL, get_season_series_segment_id(), PLAYER_LEVEL
))





-- ==================== Collection Level Spoof (Season Manual / Collector System) ====================

-- Global spoof parameters (can be modified anytime)
_G.FAKE_LEVEL = 100              -- Configured collection level
_G.FAKE_DAN = 100                -- Configured collection rank / tier
_G.FAKE_LEVEL_NAME = "Collection Champion" -- Configured collection title
_G.FAKE_SCORE = 99999            -- Configured collection points

-- ========== Prevent Duplicate Hook Flag ==========
if not _G.__COLLECT_FAKE_LOADED then
    _G.__COLLECT_FAKE_LOADED = true
end

-- ========== 1. Hook Network Protocol Handler ==========
local function hook_collect_handler()
    if not _G.FormulaFeatureEnabled("collectionStats") then return false end
    local handler = package.loaded["client.network.Protocol.CollectHandler"] or package.loaded["CollectHandler"]
    if not handler and not rawget(package.loaded, "client.network.Protocol.CollectHandler") then
        pcall(require, "client.network.Protocol.CollectHandler")
    end
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.on_get_collect_sys_main_data_rsp and not rawget(mod, "_collection_handler_hooked") then
            rawset(mod, "_collection_handler_hooked", true)
            local orig = mod.on_get_collect_sys_main_data_rsp
            
            mod.on_get_collect_sys_main_data_rsp = function(err_code, collect_data, param)
                if _G.FormulaFeatureEnabled("collectionStats") and collect_data and type(collect_data) == "table" then
                    _G.FormulaRememberCollectData(collect_data)
                    rawset(collect_data, "total_score", _G.FAKE_SCORE)
                    rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
                    local ss = rawget(collect_data, "season_score")
                    if type(ss) == "table" then
                        for k in pairs(ss) do ss[k] = _G.FAKE_SCORE end
                    else
                        rawset(collect_data, "season_score", { [1] = _G.FAKE_SCORE, [2] = _G.FAKE_SCORE })
                    end
                end
                return orig(err_code, collect_data, param)
            end
            return true
        end
    end
    return false
end

-- Forward declaration, avoid accessing global nil in hook_module_manager
local patch_collect_module
local inject_collect_data
_G.__FORMULA_CollectionDataSnapshots = setmetatable({}, { __mode = "k" })
function _G.FormulaRememberCollectData(tbl)
    if type(tbl) ~= "table" or _G.__FORMULA_CollectionDataSnapshots[tbl] then return end
    local season = rawget(tbl, "season_score")
    local seasonCopy = nil
    if type(season) == "table" then
        seasonCopy = {}
        for k, v in pairs(season) do seasonCopy[k] = v end
    end
    _G.__FORMULA_CollectionDataSnapshots[tbl] = {
        total_score = rawget(tbl, "total_score"),
        cur_season_collect_score = rawget(tbl, "cur_season_collect_score"),
        season_score = seasonCopy,
        had_season_score = (season ~= nil),
    }
end
function _G.FormulaRestoreCollectData()
    for tbl, snap in pairs(_G.__FORMULA_CollectionDataSnapshots or {}) do
        if type(tbl) == "table" then
            rawset(tbl, "total_score", snap.total_score)
            rawset(tbl, "cur_season_collect_score", snap.cur_season_collect_score)
            if snap.had_season_score then
                local copy = {}
                for k, v in pairs(snap.season_score or {}) do copy[k] = v end
                rawset(tbl, "season_score", copy)
            else
                rawset(tbl, "season_score", nil)
            end
        end
    end
    _G.__FORMULA_CollectionDataSnapshots = setmetatable({}, { __mode = "k" })
end

-- ========== 2. Hook Module Manager ==========
local function hook_module_manager()
    if not _G.FormulaFeatureEnabled("collectionStats") then return false end
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module and not rawget(mod, "_collection_getmodule_hooked") then
            rawset(mod, "_collection_getmodule_hooked", true)
            local orig_get = mod.GetModule
            local collect_key = mod.LobbyModuleConfig.collect_module
            
            mod.GetModule = function(self, name)
                local inst = orig_get(self, name)
                if inst and name == collect_key then
                    patch_collect_module(inst)
                    inject_collect_data()
                end
                return inst
            end
            return true
        end
    end
    return false
end

-- ========== 3. Get Collection Module ==========
local function get_collect_module()
    local ModuleManager = _G.ModuleManager
    if not ModuleManager then
        for _, mod in pairs(package.loaded or {}) do
            if type(mod) == "table" and mod.GetModule and mod.LobbyModuleConfig and mod.LobbyModuleConfig.collect_module then
                ModuleManager = mod
                break
            end
        end
    end
    
    if ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig then
        local ok, cm = pcall(ModuleManager.GetModule, ModuleManager, ModuleManager.LobbyModuleConfig.collect_module)
        if ok and cm then return cm end
    end
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore then
            return mod
        end
    end
    return nil
end

-- ========== 4. Patch Collection Module ==========
patch_collect_module = function(mod)
    if not _G.FormulaFeatureEnabled("collectionStats") then return false end
    if not mod or rawget(mod, "_collection_level_patched") then return false end
    rawset(mod, "_collection_level_patched", true)

    if mod.GetLevelDataByScore then
        local origLevel = mod.GetLevelDataByScore
        rawset(mod, "_formula_orig_GetLevelDataByScore", origLevel)
        rawset(mod, "GetLevelDataByScore", function(self, score, isSeason, ...)
            if _G.FormulaFeatureEnabled("collectionStats") then
                return _G.FAKE_LEVEL, _G.FAKE_LEVEL_NAME, _G.FAKE_DAN
            end
            return origLevel(self, score, isSeason, ...)
        end)
    end

    if mod.GetSeasonLevelByScore then
        local origSeason = mod.GetSeasonLevelByScore
        rawset(mod, "_formula_orig_GetSeasonLevelByScore", origSeason)
        rawset(mod, "GetSeasonLevelByScore", function(self, score, seasonId, ...)
            if _G.FormulaFeatureEnabled("collectionStats") then
                return _G.FAKE_LEVEL, true, _G.FAKE_LEVEL_NAME
            end
            return origSeason(self, score, seasonId, ...)
        end)
    end

    if mod.GetCollectScoreByCollectData then
        local origScore = mod.GetCollectScoreByCollectData
        rawset(mod, "_formula_orig_GetCollectScoreByCollectData", origScore)
        rawset(mod, "GetCollectScoreByCollectData", function(self, collect_data, ...)
            if _G.FormulaFeatureEnabled("collectionStats") then
                return _G.FAKE_SCORE, _G.FAKE_SCORE
            end
            return origScore(self, collect_data, ...)
        end)
    end

    local collect_data = rawget(mod, "collect_data")
    if collect_data and type(collect_data) == "table" then
        _G.FormulaRememberCollectData(collect_data)
        rawset(collect_data, "total_score", _G.FAKE_SCORE)
        if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
        local season = (rawget(mod, "GetSeasonId") and mod:GetSeasonId()) or 1
        collect_data.season_score[season] = _G.FAKE_SCORE
        rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
    end

    if rawget(mod, "OnGetMainData") or mod.OnGetMainData then
        local orig_on_get = rawget(mod, "OnGetMainData") or mod.OnGetMainData
        rawset(mod, "OnGetMainData", function(self, err_code, data, param)
            if _G.FormulaFeatureEnabled("collectionStats") and data and type(data) == "table" then
                _G.FormulaRememberCollectData(data)
                rawset(data, "total_score", _G.FAKE_SCORE)
                if not rawget(data, "season_score") then rawset(data, "season_score", {}) end
                local season = (rawget(self, "GetSeasonId") and self:GetSeasonId()) or 1
                if type(data.season_score) == "table" then
                    data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
            orig_on_get(self, err_code, data, param)
        end)
    end

    return true
end

-- ========== 5. Inject Data ==========
inject_collect_data = function()
    if not _G.FormulaFeatureEnabled("collectionStats") then return end
    pcall(function()
        local cm = get_collect_module()
        if cm then
            local collect_data = rawget(cm, "collect_data")
            if collect_data and type(collect_data) == "table" then
                _G.FormulaRememberCollectData(collect_data)
                rawset(collect_data, "total_score", _G.FAKE_SCORE)
                if not rawget(collect_data, "season_score") then rawset(collect_data, "season_score", {}) end
                local season = (rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1
                if type(collect_data.season_score) == "table" then
                    collect_data.season_score[season] = _G.FAKE_SCORE
                end
                rawset(collect_data, "cur_season_collect_score", _G.FAKE_SCORE)
            end
        end
    end)
    
    pcall(function()
        if _G.DataMgr and _G.DataMgr.roleData then
            if not _G.DataMgr.roleData.brief_collect_data then _G.DataMgr.roleData.brief_collect_data = {} end
            _G.FormulaRememberCollectData(_G.DataMgr.roleData.brief_collect_data)
            _G.DataMgr.roleData.brief_collect_data.total_score = _G.FAKE_SCORE
            _G.DataMgr.roleData.brief_collect_data.cur_season_collect_score = _G.FAKE_SCORE
        end
    end)
end

-- ========== 6. Hook Collection UI ==========
local function hook_collect_road_ui()
    if not _G.FormulaFeatureEnabled("collectionStats") then return false end
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.ShowCollect and mod.ShowSeasonCollect and not rawget(mod, "_collection_road_hooked") then
            rawset(mod, "_collection_road_hooked", true)
            local orig_show = mod.ShowCollect
            
            if orig_show then
                rawset(mod, "ShowCollect", function(self)
                    if not _G.FormulaFeatureEnabled("collectionStats") then return orig_show(self) end
                    local mm = _G.ModuleManager
                    if not mm then
                        for _, m in pairs(package.loaded or {}) do
                            if type(m) == "table" and m.GetModule and m.LobbyModuleConfig then
                                mm = m
                                break
                            end
                        end
                    end
                    
                    if mm and mm.LobbyModuleConfig and mm.LobbyModuleConfig.collect_module then
                        local ok, cm = pcall(mm.GetModule, mm, mm.LobbyModuleConfig.collect_module)
                        if ok and cm and rawget(cm, "collect_data") then
                            local cd = rawget(cm, "collect_data")
                            if type(cd) == "table" then
                                rawset(cd, "total_score", _G.FAKE_SCORE)
                                if not rawget(cd, "season_score") then rawset(cd, "season_score", {}) end
                                cd.season_score[(rawget(cm, "GetSeasonId") and cm:GetSeasonId()) or 1] = _G.FAKE_SCORE
                                rawset(cd, "cur_season_collect_score", _G.FAKE_SCORE)
                            end
                        end
                    end
                    return orig_show(self)
                end)
            end
            return true
        end
    end
    return false
end

-- ========== 7. Install All Hooks At Once ==========
local function install_collect_hooks()
    if not _G.FormulaFeatureEnabled("collectionStats") then return false end
    hook_collect_handler()
    hook_module_manager()
    hook_collect_road_ui()
    
    for path, mod in pairs(package.loaded or {}) do
        if type(mod) == "table" and mod.GetLevelDataByScore and mod.GetSeasonLevelByScore and not rawget(mod, "_collection_level_patched") then
            patch_collect_module(mod)
        end
    end
    
    local cm = get_collect_module()
    if cm then
        patch_collect_module(cm)
    end
    inject_collect_data()
    
    print("[Collection Spoof] Hook installed, Level=" .. _G.FAKE_LEVEL .. " Points=" .. _G.FAKE_SCORE)
end

-- ========== 8. Export Control Functions ==========
_G.CollectFake = {
    Apply = function()
        install_collect_hooks()
    end,
    SetLevel = function(n)
        _G.FAKE_LEVEL = tonumber(n) or _G.FAKE_LEVEL
        install_collect_hooks()
        return _G.FAKE_LEVEL
    end,
    SetName = function(name)
        _G.FAKE_LEVEL_NAME = tostring(name) or _G.FAKE_LEVEL_NAME
    end,
    SetScore = function(n)
        _G.FAKE_SCORE = tonumber(n) or _G.FAKE_SCORE
        install_collect_hooks()
        return _G.FAKE_SCORE
    end,
    SetDan = function(n)
        _G.FAKE_DAN = tonumber(n) or _G.FAKE_DAN
    end,
}

-- ========== 9. Switch-controlled collection startup ==========
_G.FORMULA_ApplyCollectionStats = function(enabled)
    if not enabled then
        _G.FormulaRestoreCollectData()
        return true
    end
    pcall(install_collect_hooks)
    if not _G.__FORMULA_CollectionStatsTimer and _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimerLoop then
        _G.__FORMULA_CollectionStatsTimer = true
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            if _G.FormulaFeatureEnabled("collectionStats") then
                pcall(inject_collect_data)
            end
        end, -1, 1)
    end
    return true
end



-- ==================== Settings UI: Add Weapon, Vehicle and Clothes Skin Tabs ====================
pcall(function()
    local DazhiMH_Config = _G.DazhiMH_Config or {}
    _G.DazhiMH_Config = DazhiMH_Config

    DazhiMH_Config.PATHS = {
        "/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h",
        "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h",
        "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h",
        "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h",
        "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h"
    }

DazhiMH_Config._activePath = nil
DazhiMH_Config._cache = DazhiMH_Config._cache or {}

    -- ==================== Clothes Related Config ====================
    DazhiMH_Config.OUTFIT_KEYS = {
        SHIRT = true, HAIR = true, HAT = true, FACE = true, MASK = true,
        GLOVES = true, PANT = true, SHOE = true, PARACHUTE = true,
        GLIDER = true, PETSKIN = true, EXPLOSION_WEAPON = true,
        BACKPACK1 = true, BACKPACK2 = true, BACKPACK3 = true,
        BACKPACK4 = true, BACKPACK5 = true, BACKPACK6 = true,
        HELMET1 = true, HELMET2 = true, HELMET3 = true,
        HELMET4 = true, HELMET5 = true, HELMET6 = true,
        ARMOR1 = true, ARMOR2 = true, ARMOR3 = true,
        ARMOR4 = true, ARMOR5 = true, ARMOR6 = true,
    }

    DazhiMH_Config.ROLE_SKINS_MAP = {
        SHIRT = "_G.SuitSkin", HAIR = "_G.HairSkin", HAT = "_G.HatSkin",
        FACE = "_G.FaceSkin", MASK = "_G.MaskSkin", GLOVES = "_G.GlovesSkin",
        PANT = "_G.PantSkin", SHOE = "_G.ShoeSkin", PARACHUTE = "_G.ParachuteSkin",
        GLIDER = "_G.GliderSkin", PETSKIN = "_G.PetSkinMapIndex",
        BACKPACK1 = "_G.Backpack1Skin", BACKPACK2 = "_G.Backpack2Skin",
        BACKPACK3 = "_G.Backpack3Skin", BACKPACK4 = "_G.Backpack4Skin",
        BACKPACK5 = "_G.Backpack5Skin", BACKPACK6 = "_G.Backpack6Skin",
        HELMET1 = "_G.Helmet1Skin", HELMET2 = "_G.Helmet2Skin",
        HELMET3 = "_G.Helmet3Skin", HELMET4 = "_G.Helmet4Skin",
        HELMET5 = "_G.Helmet5Skin", HELMET6 = "_G.Helmet6Skin",
        ARMOR1 = "_G.Armor1Skin", ARMOR2 = "_G.Armor2Skin",
        ARMOR3 = "_G.Armor3Skin", ARMOR4 = "_G.Armor4Skin",
        ARMOR5 = "_G.Armor5Skin", ARMOR6 = "_G.Armor6Skin",
    }

    function DazhiMH_Config.FindPath()
    -- Star Priority: Locate by current package name
    local curPath = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath()
    if curPath then
        DazhiMH_Config._activePath = curPath
        return curPath
    end

    -- Star Fallback: Cached path
    if DazhiMH_Config._activePath then
        local f = io.open(DazhiMH_Config._activePath, "r")
        if f then f:close(); return DazhiMH_Config._activePath end
        DazhiMH_Config._activePath = nil
    end

    -- Star Fallback: Take first existing in order
    for _, path in ipairs(DazhiMH_Config.PATHS) do
        local f = io.open(path, "r")
        if f then f:close(); DazhiMH_Config._activePath = path; return path end
    end
    return nil
end

function DazhiMH_Config.Load(force)
    if next(DazhiMH_Config._cache) then return DazhiMH_Config._cache end
    local path = DazhiMH_Config.FindPath()
        if not path then return DazhiMH_Config._cache end
        local f = io.open(path, "r")
        if not f then return DazhiMH_Config._cache end
        for line in f:lines() do
            if not line:match("^%s*#") then
                local key, value = line:match("^(%w+_?%w*)%s*=%s*(%d+)")
                if key and value then DazhiMH_Config._cache[key] = tonumber(value) end
            end
        end
        f:close()
        return DazhiMH_Config._cache
    end

    function DazhiMH_Config.Get(key, defaultValue)
        local v = DazhiMH_Config.Load()[key]
        return v ~= nil and v or (defaultValue or 1)
    end

    function DazhiMH_Config.GetMaxWeaponIndex(weaponKey)
        if _G.WeaponSkinPack and _G.WeaponSkinPack[weaponKey] then
            local maxIndex = 1
            for index in pairs(_G.WeaponSkinPack[weaponKey]) do
                if type(index) == "number" and index > maxIndex then maxIndex = index end
            end
            return maxIndex
        end
        return 20
    end

function DazhiMH_Config.GetMaxVehicleIndex(vehicleKey)
        local vehicleIdMap = {
            DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
            MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
            MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
            RONY = 1916, RZR = 1966, BIGFOOT = 1953,
            HORSE = 1987, MINIBUS = 1904, BOAT = 1910
        }
        local vehicleId = vehicleIdMap[vehicleKey]
        if vehicleId and _G.VehskinIdMappings and _G.VehskinIdMappings[vehicleId] then
            return #_G.VehskinIdMappings[vehicleId]
        end
        return 20
    end

    function DazhiMH_Config.ApplyWeaponSkin(weaponKey, index)
        index = math.floor(tonumber(index) or 1)
        if _G.WeaponNameToID and _G.WeaponSkinPack then
            local weaponID = _G.WeaponNameToID[weaponKey]
            local skinPack = _G.WeaponSkinPack[weaponKey] and _G.WeaponSkinPack[weaponKey][index]
            if weaponID and skinPack and skinPack.main then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = skinPack.main
                if _G.invalidateAttachmentCache then
                    pcall(_G.invalidateAttachmentCache, skinPack.main)
                end
            end
        end
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
    end

function DazhiMH_Config.ApplyVehicleSkin(vehicleKey, index)
    index = math.floor(tonumber(index) or 1)
    local vehicleIdMap = {
        DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
        MIRADO = 1914, MIRADOC = 1915, ROADSTER = 19116,
        MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917,
        RONY = 1916, RZR = 1966, BIGFOOT = 1953,
        HORSE = 1987, MINIBUS = 1904, BOAT = 1910
    }
    local vehicleId = vehicleIdMap[vehicleKey]
    if vehicleId then
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        -- Star Star Star Record User's Last Real Set Value, As "Authoritative" Value Star Star Star
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        _G.__VehicleUserSet[vehicleId] = index
        _G.VehicleSkinIndex[vehicleId] = index
    end
    if _G.GameVehicleAvatarHandler then pcall(_G.GameVehicleAvatarHandler) end
end

    -- ==================== Clothes Apply Function ====================
function DazhiMH_Config.ApplyOutfit(key, value)
    value = math.floor(tonumber(value) or 1)
    if _G.lastConfig then _G.lastConfig[key] = value end

    local roleVar = DazhiMH_Config.ROLE_SKINS_MAP[key]
    if roleVar then
        local varName = roleVar:gsub("^_G%.", "")
        _G[varName] = value
    end

    -- Star Star Star New: Sync to wumingking.h + Immediately Refresh Lobby Character Star Star Star
    pcall(function()
        local multiKind, multiLevel = key:match("^(BACKPACK)([1-6])$")
        if not multiKind then multiKind, multiLevel = key:match("^(HELMET)([1-6])$") end
        if not multiKind then multiKind, multiLevel = key:match("^(ARMOR)([1-6])$") end
        if multiKind and _G.Wumingking and _G.Wumingking.SetLevelSkin then
            local multiSlot = (multiKind == "BACKPACK" and 8)
                or (multiKind == "HELMET" and 9) or 10
            _G.Wumingking.SetLevelSkin(multiSlot, tonumber(multiLevel), value)
        end

        local KEY_TO_SLOT = {
            HAIR      = 2,  HAT       = 3,  FACE  = 4,  MASK = 12,
            SHIRT     = 5,  PANT      = 6,  SHOE  = 7,  GLOVES = 16,
            PARACHUTE = 11, GLIDER    = 15,
        }
        local slot = KEY_TO_SLOT[key]
        if slot and _G.Wumingking and _G.Wumingking.SetSlot then
            -- First write to wumingking.h, avoid load() in ApplyToLobby reading old value
            _G.Wumingking.SetSlot(slot, value)
        end
        -- Call lobby refresh again (Hook SlotSyncData + OnRep + InitDepotCommonPutOn)
        if _G.Wumingking and _G.Wumingking.ApplyToLobby then
            pcall(_G.Wumingking.ApplyToLobby)
        end
    end)

    -- Keep in-match handlers (useless in lobby, only effective on entering match)
    local handlers = {
        "GameAvatarHandler",
        "GameAvatarHandleroutfit",
        "GameAvatarHandlercloth",
        "GameAvatarHandlerwear",
        "RefreshAvatar",
        "GameAvatarHandlerweapons",
        "GameAvatarHandlerplayers"
    }
    for _, handlerName in ipairs(handlers) do
        if _G[handlerName] then pcall(_G[handlerName]) end
    end
end

function DazhiMH_Config.Set(key, value)
    value = tonumber(value)
    if value == nil then value = 1 end
    value = math.floor(value)

    DazhiMH_Config._cache[key] = value
    if _G.lastConfig then _G.lastConfig[key] = value end

    -- Star Move vehicleKeys to top
    local vehicleKeys = {
        DACIA = true, COUPERB = true, BUGGY = true, UAZ = true,
        MIRADO = true, MIRADOC = true, ROADSTER = true, MOTO = true,
        SIDECARMOTO = true, BLOOMSC = true, RONY = true, RZR = true,
        BIGFOOT = true, HORSE = true, MINIBUS = true, BOAT = true
    }

    -- Star If file exists, write; if not, skip (no longer return)
    local path = DazhiMH_Config.FindPath()
    if path then
        local lines = {}
        local f = io.open(path, "r")
        if f then
            for line in f:lines() do table.insert(lines, line) end
            f:close()
        end
        local updated = false
        for i, line in ipairs(lines) do
            if not line:match("^%s*#") then
                local k = line:match("^(%w+_?%w*)%s*=")
                if k == key then
                    lines[i] = key .. "=" .. tostring(value)
                    updated = true
                    break
                end
            end
        end
        if not updated then
            lines[#lines + 1] = key .. "=" .. tostring(value)
        end
        f = io.open(path, "w")
        if f then
            for _, line in ipairs(lines) do f:write(line, "\n") end
            f:close()
        end
    else
        print("[DazhiMH] Set: wumingking.h not found, only saved in memory: " .. key .. "=" .. value)
    end

    -- Star No matter what, apply must execute
    if key == "GRENADE_FAST_REFRESH" or key == "WEAPON_FAST_REFRESH" or key == "WEAPON_BACK_REFRESH" then
        -- These three are pure logic toggles, no need to apply skin, skip directly to prevent lag
        -- Star Fix: If modifying refresh speed, must rebuild timer, otherwise won't take effect
        if key == "WEAPON_FAST_REFRESH" then
            local interval = (value == 1) and 1.0 or 1.5
            local tx = require("common.time_ticker")
            if _G.weaponAvatarTimerIndex and tx.IsRunning(_G.weaponAvatarTimerIndex) then
                tx.RemoveTimer(_G.weaponAvatarTimerIndex)
            end
            _G.weaponAvatarTimerIndex = tx.AddTimerLoop(0, function()
                pcall(_G.GameAvatarHandlerweapons)
            end, -1, interval)
        end
    elseif vehicleKeys[key] then
        DazhiMH_Config.ApplyVehicleSkin(key, value)
    elseif DazhiMH_Config.OUTFIT_KEYS[key] then
        DazhiMH_Config.ApplyOutfit(key, value)
    else
        DazhiMH_Config.ApplyWeaponSkin(key, value)
    end

    -- Star Sync write wumingking.h
    if _G.Wumingking and _G.Wumingking.Save then
        pcall(_G.Wumingking.Save)
    end

    return true
end
    
    
    
    
    -- Save custom weapon skin ID to file
function DazhiMH_Config.SaveCustomWeaponSkin(weaponKey, skinId)
    skinId = math.floor(tonumber(skinId) or 0)
    if skinId > 0 then
        DazhiMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
    end
end

-- Restore all saved custom weapon skin IDs
function DazhiMH_Config.RestoreCustomWeaponSkins()
    if not _G.WeaponNameToID then return end
    for weaponKey, weaponName in pairs(WeaponSettingTab.WEAPON_NAMES) do
        local savedCustomId = DazhiMH_Config.Get("CUSTOM_" .. weaponKey, 0)
        if savedCustomId > 0 then
            local weaponID = _G.WeaponNameToID[weaponKey]
            if weaponID then
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[weaponID] = savedCustomId
            end
        end
    end
end

    -- ==================== Custom Title ====================
    local CustomTitleLoc = {
        _patched = false,
        _nextId = 987654000,
        _map = {}
    }
function CustomTitleLoc.Patch()
    if CustomTitleLoc._patched then return end
    if not LocUtil or type(LocUtil.GetLocalizeResStr) ~= "function" then return end
    local origGetLocalizeResStr = LocUtil.GetLocalizeResStr
    LocUtil.GetLocalizeResStr = function(id)
        -- String: If numeric string, convert to number, otherwise return string itself directly
        if type(id) == "string" and id ~= "" then
            local num = tonumber(id)
            if not num then
                return id  -- <- Key: Return string directly, do not go through localization
            end
            id = num
        end
        local m = CustomTitleLoc._map
        local customText = m[id] or m[tostring(id)]
        if customText then
            return customText
        end
        return origGetLocalizeResStr(id)
    end
    CustomTitleLoc._patched = true
end

function CustomTitleLoc.Register(text)
    CustomTitleLoc.Patch()
    CustomTitleLoc._nextId = CustomTitleLoc._nextId + 1
    local id = CustomTitleLoc._nextId
    CustomTitleLoc._map[id] = text or ""
    CustomTitleLoc._map[tostring(id)] = text or ""
    return id
end

    function CustomTitleLoc.RegisterList(textList)
        local ids = {}
        for i = 1, #textList do
            ids[i] = CustomTitleLoc.Register(textList[i])
        end
        return ids
    end
    
    
    -- ==================== Number Input Popup Core ====================
function DazhiMH_Config._getSkinInputPopupUI()
    if not UIManager or not UIManager.UI_Config or not UIManager.GetUI then
        return nil
    end
    return UIManager.GetUI(UIManager.UI_Config.setting_cloud_search_popups)
end

function DazhiMH_Config._confirmSkinInputPopup(ui)
    if DazhiMH_Config._skinInputConfirming then return false end

    local st = DazhiMH_Config._numInput
    ui = ui or DazhiMH_Config._getSkinInputPopupUI()
    if not st or not ui or not ui.UIRoot then return false end

    DazhiMH_Config._skinInputConfirming = true

    local text = ""
    if ui.UIRoot.EditableTextBox_PlanName then
        text = ui.UIRoot.EditableTextBox_PlanName:GetText() or ""
    end
    if text == "" and ui.currentInputCode then
        text = tostring(ui.currentInputCode)
    end

    local num = tonumber(text)
    if not num then
        DazhiMH_Config._skinInputConfirming = false
        if BattleNormalTips then
            pcall(BattleNormalTips, "Please enter correct skin ID", nil, 3)
        end
        return false
    end

    num = math.floor(num)
    if num < st.min then num = st.min end
    if num > st.max then num = st.max end

    if st.onConfirm then
        st.onConfirm(num)
    end

    local refreshKey = st.refreshKey
    DazhiMH_Config._numInput = nil
    DazhiMH_Config._skinPopupSetupToken = nil
    UIManager.CloseUI(UIManager.UI_Config.setting_cloud_search_popups)

    DazhiMH_Config._skinInputConfirming = false
    DazhiMH_Config._releaseSkinPopupOpeningLock()

    if refreshKey and EventSystem and EVENTTYPE_SETTING and EVENTID_SETTING_OPTION_FORCEUPDATE then
        EventSystem:postEvent(EVENTTYPE_SETTING, EVENTID_SETTING_OPTION_FORCEUPDATE, refreshKey)
    end
    return true
end

function DazhiMH_Config._setupSkinInputPopupOnce(ui)
    local st = DazhiMH_Config._numInput
    if not st or not ui or not ui.UIRoot then return false end
    if DazhiMH_Config._skinPopupSetupToken == st.token then return true end
    DazhiMH_Config._skinPopupSetupToken = st.token

    if ui.Common_Popup_Small_UIBP and ui.Common_Popup_Small_UIBP.SetData then
        ui.Common_Popup_Small_UIBP:SetData(ui, st.title)
    end
    if ui.UIRoot.EditableTextBox_PlanName then
        ui.UIRoot.EditableTextBox_PlanName:SetText(st.value)
    end
    if ui.UIRoot.EditableTextBox_Tip then
        ui.UIRoot.EditableTextBox_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if ui.UIRoot.TextBlock_CurrentPlan then
        ui.UIRoot.TextBlock_CurrentPlan:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    return true
end

function DazhiMH_Config._releaseSkinPopupOpeningLock()
    DazhiMH_Config._skinPopupOpening = false
end

function DazhiMH_Config.PatchSkinInputPopup()
    if DazhiMH_Config._skinPopupPatched then return end
    local ok, PopupClass = pcall(require, "client.slua.umg.setting.Setting_Cloud_Search_Popups_UIBP")
    if not ok or not PopupClass then return end

    local origOnInitialize = PopupClass.OnInitialize
    PopupClass.OnInitialize = function(self)
        if origOnInitialize then origOnInitialize(self) end
        if DazhiMH_Config._numInput then
            DazhiMH_Config._setupSkinInputPopupOnce(self)
        end
    end

    local origOnPostInitialize = PopupClass.OnPostInitialize
    PopupClass.OnPostInitialize = function(self)
        if origOnPostInitialize then origOnPostInitialize(self) end
        if DazhiMH_Config._numInput then
            DazhiMH_Config._setupSkinInputPopupOnce(self)
            DazhiMH_Config._releaseSkinPopupOpeningLock()
        end
    end

    local origUseClick = PopupClass.OnNewButton_UseClick
    PopupClass.OnNewButton_UseClick = function(self)
        if DazhiMH_Config._numInput and not DazhiMH_Config._skinInputConfirming then
            self:PlayAudio(sound_config.click)
            DazhiMH_Config._confirmSkinInputPopup(self)
            return
        end
        if origUseClick then return origUseClick(self) end
    end

    DazhiMH_Config._skinPopupPatched = true
end

function DazhiMH_Config.PatchShowNoticeForSkinInput()
    if DazhiMH_Config._showNoticePatched then return end

    local function wrapShowNotice(origFunc)
        return function(noticeId, bImmediately, controlTime, style)
            if DazhiMH_Config._numInput and not DazhiMH_Config._skinInputConfirming then
                local id = tonumber(noticeId)
                if id == 11474 or id == 11451 or id == 120164 then
                    DazhiMH_Config._confirmSkinInputPopup()
                    return
                end
            end
            return origFunc(noticeId, bImmediately, controlTime, style)
        end
    end

    if _G.ShowNotice then
        DazhiMH_Config._origShowNotice = DazhiMH_Config._origShowNotice or _G.ShowNotice
        _G.ShowNotice = wrapShowNotice(DazhiMH_Config._origShowNotice)
    end
    if LocUtil and LocUtil.ShowNotice then
        DazhiMH_Config._origLocUtilShowNotice = DazhiMH_Config._origLocUtilShowNotice or LocUtil.ShowNotice
        LocUtil.ShowNotice = wrapShowNotice(DazhiMH_Config._origLocUtilShowNotice)
    end

    DazhiMH_Config._showNoticePatched = true
end

function DazhiMH_Config.ShowNumberInputPopup(opts)
    opts = opts or {}
    DazhiMH_Config.PatchShowNoticeForSkinInput()
    DazhiMH_Config.PatchSkinInputPopup()

    local popupConfig = UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_cloud_search_popups
    if not popupConfig then return false end

    if DazhiMH_Config._skinPopupOpening then return true end
    if UIManager.IsUIShow and UIManager.IsUIShow(popupConfig) then return true end

    DazhiMH_Config._skinPopupOpening = true
    DazhiMH_Config._skinInputConfirming = false
    DazhiMH_Config._skinPopupSetupToken = nil
    DazhiMH_Config._skinPopupOpenToken = (DazhiMH_Config._skinPopupOpenToken or 0) + 1

    DazhiMH_Config._numInput = {
        token = DazhiMH_Config._skinPopupOpenToken,
        title = opts.title or "Skin ID",
        value = tostring(math.floor(tonumber(opts.value) or 1)),
        min = opts.min or 1,
        max = opts.max or 9999999999,
        onConfirm = opts.onConfirm,
        refreshKey = opts.refreshKey
    }

    UIManager.ShowUI(popupConfig)

    local ui = DazhiMH_Config._getSkinInputPopupUI()
    if ui and DazhiMH_Config._setupSkinInputPopupOnce(ui) then
        DazhiMH_Config._releaseSkinPopupOpeningLock()
    else
        local ok, time_ticker = pcall(require, "common.time_ticker")
        if ok and time_ticker and time_ticker.AddTimer then
            time_ticker.AddTimer(0.6, function()
                DazhiMH_Config._releaseSkinPopupOpeningLock()
            end)
        else
            DazhiMH_Config._releaseSkinPopupOpeningLock()
        end
    end
    return true
end
    
    
-- ==================== FORMULA Refresh All Skins (manual hard re-apply) ====================
_G.FormulaRefreshAllSkins = function()
    local burst = { 0, 0.25, 0.6, 1.1 }
    local cfg = _G.DazhiMH_Config

    local function reloadFromFile()
        if not cfg or not cfg.Load then return end
        pcall(function()
            cfg._cache = {}
            cfg.Load(true)
            for key, varName in pairs(cfg.ROLE_SKINS_MAP or {}) do
                local v = cfg._cache[key]
                if v ~= nil and v > 0 then
                    _G[varName:gsub("^_G%.", "")] = v
                end
            end
        end)
    end

    local function clearCaches()
        _G.__perf.partsInited = {}
        _G.__perf.attachStamp = {}
        _G.__perf.petStamp = 0
        _G.attachmentCache = {}
        _G.lastAppliedSkin = {}
        _G.lastAppliedAttachments = {}
        _G.lastAppliedAttachmentFp = {}
        _G.skinDownloadCache = {}
        _G.skinIdCache3 = {}
        _G.__LobbyVehSkinCache = {}
    end

    local function applyCharacterHard()
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if not pc then return end
            local ch = pc:GetPlayerCharacterSafety()
            if not ch or not slua.isValid(ch) then return end

            local comp = ch.AvatarComponent2
            local data = comp and comp.NetAvatarData and comp.NetAvatarData.SlotSyncData
            if data and slua.isValid(data) then
                -- Force helmet(9) / backpack(8) / vest(10) to rebuild so a new level re-resolves
                for i = 0, data:Num() - 1 do
                    local eq = data:Get(i)
                    if eq and (eq.SlotID == 8 or eq.SlotID == 9 or eq.SlotID == 10) then
                        if eq.ItemId ~= 0 then
                            eq.ItemId = 0
                            data:Set(i, eq)
                        end
                    end
                end
            end

            if _G.equip_character_avatar then _G.equip_character_avatar(ch) end
            if comp and comp.OnRep_BodySlotStateChanged then
                comp:OnRep_BodySlotStateChanged()
            end
            if ch.DelayHandleAvatarMeshChanged then pcall(ch.DelayHandleAvatarMeshChanged, ch) end
        end)
    end

    local function applyEverything()
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
        if _G.GameAvatarHandlerBagPack then pcall(_G.GameAvatarHandlerBagPack) end
        if _G.GameVehicleAvatarHandler then pcall(_G.GameVehicleAvatarHandler) end
        if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
        if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end
        if _G.GoldenLeavesTrail and _G.GoldenLeavesTrail.Enabled
           and _G.GoldenLeavesTrail.Apply then
            pcall(_G.GoldenLeavesTrail.Apply)
        end
        if _G.GrenadeFX and _G.GrenadeFX.Apply then pcall(_G.GrenadeFX.Apply) end
    end

    reloadFromFile()
    clearCaches()

    for _, d in ipairs(burst) do
        if d == 0 then
            applyCharacterHard()
            applyEverything()
        elseif _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
            _G.Mytimer_ticker.AddTimer(d, function()
                applyCharacterHard()
                applyEverything()
            end)
        end
    end

    print("[FORMULA] Refresh all skins executed")
    return true
end

local function BuildRefreshAllButton(AliasMap, stack)
    if not AliasMap or not AliasMap.Switcher then return end
    table.insert(stack, {
        Key = "RefreshAllSkins",
        UI = AliasMap.Switcher,
        Text = "REFRESH ALL SKINS NOW",
        Help = "Tap to re-apply every skin: guns + attachments, outfit, helmet 1-6, backpack 1-6, vest 1-6, pet, vehicle, trail. Use it after picking up a higher level helmet, vest or backpack.",
        GetFunc = function() return false end,   -- snaps back = acts like a button
        SetFunc = function(_, value)
            _G.FormulaRefreshAllSkins()
            return true
        end
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 12 })
end
-- ==================== Clothes Tab (Full Version, Includes Pet Slider) ====================
local SuitSettingTab = _G.SuitSettingTab or {}
_G.SuitSettingTab = SuitSettingTab
SuitSettingTab.TAB_NAME = "Character Outfit"

-- ========== Pet Skin List (For Slider) ==========
SuitSettingTab.PET_SKIN_LIST = {
    50000, 50001, 50002, 50003, 50004, 50005, 50006, 50007, 50008, 50009,
    50010, 50011, 50012, 50013, 50014, 50015, 50016, 50017, 50018, 50019,
    50020, 50021, 50022, 50023, 50024, 50025, 50026, 50027, 50028, 50029,
    50030, 50031, 50032, 50033, 50034, 50035, 50036, 50037, 50038, 50039,
    50040, 50041, 50042, 50043, 50044,
    50045, -- Little Bunny Buddy
50046, -- Cursed Skull Boxing Bear Buddy
}

-- Basic wear parts (0=Restore default)
local BASIC_WEAR_KEYS = {
    "SHIRT", "HAIR", "HAT", "FACE", "MASK", "GLOVES", "PANT", "SHOE", "PARACHUTE", "GLIDER"
}

function SuitSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    DazhiMH_Config.Load(true)

    local stack = {}
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("◆ FORMULA // CHARACTER") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 8 })
    BuildRefreshAllButton(AliasMap, stack)
    -- ==================== Basic Equip ====================
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("Basic Wear") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    for _, key in ipairs(BASIC_WEAR_KEYS) do
    for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
        if item.key == key then
            local refreshKey = item.key .. "SkinInput"
            table.insert(stack, {
                Key = refreshKey,
                UI = AliasMap.OpenWindow,
                Text = CustomTitleLoc.Register(item.label),
                GetFunc = function()
                    local val = DazhiMH_Config.Get(item.key, item.default)
                    if val == 0 then
                        return "Off"
                    end
                    return tostring(val)
                end,
                SetFunc = function()
                    DazhiMH_Config.ShowNumberInputPopup({
                        title = item.label .. " (Input 0=Turn Off Modification)",
                        value = DazhiMH_Config.Get(item.key, item.default),
                        min = 0,
                        max = 9999999999,
                        refreshKey = refreshKey,
                        onConfirm = function(newValue)
                            newValue = math.floor(tonumber(newValue) or 0)
                            if newValue < 0 then newValue = 0 end
                            -- Star Save directly, 0 means off
                            DazhiMH_Config.Set(item.key, newValue)
                            if _G.GameAvatarHandlerplayers then
                                pcall(_G.GameAvatarHandlerplayers)
                            end
                        end
                    })
                end
            })
            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
            break
        end
    end
end
    
-- ==================== Pet Skin (Slider) ====================
-- Pet Skin (Slider)
table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("Pet Skin / Pet Skin") })
table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

table.insert(stack, {
    Key = "PetSkinSlider",
    UI = AliasMap.Slider,
    Text = "Pet Skin / Pet Skin",
    Help = "Slide to switch pet skin (total " .. #SuitSettingTab.PET_SKIN_LIST .. " types)\nSlide to switch pet skin (" .. #SuitSettingTab.PET_SKIN_LIST .. " types)",
    Min = 1,
    Max = #SuitSettingTab.PET_SKIN_LIST,
    IsPercent = false,
    GetFunc = function()
        return DazhiMH_Config.Get("PETSKIN", 1)
    end,
    SetFunc = function(_, value)
        local index = math.floor(tonumber(value) or 1)
        if index < 1 then index = 1 end
        if index > #SuitSettingTab.PET_SKIN_LIST then index = #SuitSettingTab.PET_SKIN_LIST end
        
        local petId = SuitSettingTab.PET_SKIN_LIST[index]
        
        _G.PetSkinMapIndex = index
        _G.PetSkin = petId
        
        DazhiMH_Config.Set("PETSKIN", index)
        
        if _G.HandlePetLogic then
            pcall(_G.HandlePetLogic)
        end
        if _G.ApplyPetSkinInGame then
            pcall(_G.ApplyPetSkinInGame)
        end
        
        print("[Pet] Switch to: " .. tostring(petId) .. " (index: " .. tostring(index) .. ")")
        return true
    end
})



table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    
    -- ==================== Backpack Skin (0=Do Not Modify) ====================
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("Backpack Skin") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local backpackKeys = { "BACKPACK1", "BACKPACK2", "BACKPACK3", "BACKPACK4", "BACKPACK5", "BACKPACK6" }
    for _, key in ipairs(backpackKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "Do Not Modify" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=Do Not Modify)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    -- ==================== Helmet Skin (0=Do Not Modify) ====================
    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("Helmet Skin") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local helmetKeys = { "HELMET1", "HELMET2", "HELMET3", "HELMET4", "HELMET5", "HELMET6" }
    for _, key in ipairs(helmetKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "Do Not Modify" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=Do Not Modify)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    -- ==================== Bulletproof Vest Skin (0=Do Not Modify) ====================
    table.insert(stack, { UI = AliasMap.Spacer, Height = 15 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("Bulletproof Vest Skin") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    local armorKeys = { "ARMOR1", "ARMOR2", "ARMOR3", "ARMOR4", "ARMOR5", "ARMOR6" }
    for _, key in ipairs(armorKeys) do
        for _, item in ipairs(SuitSettingTab.SUIT_ITEMS) do
            if item.key == key then
                local refreshKey = item.key .. "SkinInput"
                table.insert(stack, {
                    Key = refreshKey,
                    UI = AliasMap.OpenWindow,
                    Text = CustomTitleLoc.Register(item.label),
                    GetFunc = function()
                        local val = DazhiMH_Config.Get(item.key, item.default)
                        if val == 0 then return "Do Not Modify" end
                        return tostring(val)
                    end,
                    SetFunc = function()
                        DazhiMH_Config.ShowNumberInputPopup({
                            title = item.label .. " (0=Do Not Modify)",
                            value = DazhiMH_Config.Get(item.key, item.default),
                            min = 0,
                            max = 9999999999,
                            refreshKey = refreshKey,
                            onConfirm = function(newValue)
                                newValue = math.floor(tonumber(newValue) or 0)
                                if newValue < 0 then newValue = 0 end
                                DazhiMH_Config.Set(item.key, newValue)
                                if _G.GameAvatarHandlerplayers then
                                    pcall(_G.GameAvatarHandlerplayers)
                                end
                            end
                        })
                    end
                })
                table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
                break
            end
        end
    end
    
    return stack
end

    -- ==================== Weapon Tab ====================
    local WeaponSettingTab = _G.WeaponSettingTab or {}
    _G.WeaponSettingTab = WeaponSettingTab
    WeaponSettingTab.TAB_NAME = "Weapon Skin"

    WeaponSettingTab.WEAPON_GROUPS = {
        {
            title = "01 | ASSAULT RIFLES",
            weapons = {
                "AKM", "M16A4", "SCAR", "M416", "GROZA", "AUG", "QBZ", "M762",
                "Mk47", "G36C", "HoneyPot", "FAMAS", "ASM", "ACE32"
            }
        },
        {
            title = "02 | SUBMACHINE GUNS",
            weapons = {
                "UZI", "UMP", "VECTOR", "THOMPSON", "BIZON", "MP5K", "JS9", "P90"
            }
        },
        {
            title = "03 | SNIPER / MARKSMAN",
            weapons = {
                "K98", "M24", "AWM", "SKS", "VSS", "Mini14", "MK14", "Win94",
                "M1Garand", "SLR", "QBU", "Mosin", "AMR", "Mk12", "DSR"
            }
        },
        {
            title = "04 | SHOTGUNS",
            weapons = {
                "S686", "S1897", "S12K", "DBS", "M1014", "NS2000"
            }
        },
        {
            title = "05 | LIGHT MACHINE GUNS",
            weapons = {
                "M249", "DP28", "MG3"
            }
        },
        {
            title = "06 | MELEE WEAPONS",
            weapons = {
                "PAN", "DAGGER", "Machete"
            }
        },
    }

    WeaponSettingTab.WEAPON_NAMES = {
        AKM = "AKM", M16A4 = "M16A4", SCAR = "SCAR-L", M416 = "M416",
        GROZA = "GROZA", AUG = "AUG", QBZ = "QBZ", M762 = "M762",
        Mk47 = "Mk47", G36C = "G36C", HoneyPot = "Honey Badger",
        FAMAS = "FAMAS", ASM = "ASM", ACE32 = "ACE32",
        UZI = "UZI", UMP = "UMP45", VECTOR = "Vector", THOMPSON = "Thompson",
        BIZON = "Bizon", MP5K = "MP5K", JS9 = "JS9", P90 = "P90",
        K98 = "Kar98k", M24 = "M24", AWM = "AWM", SKS = "SKS",
        VSS = "VSS", Mini14 = "Mini14", MK14 = "MK14", Win94 = "Win94",
        M1Garand = "M1 Garand", SLR = "SLR", QBU = "QBU", Mosin = "Mosin",
        AMR = "AMR", Mk12 = "Mk12", DSR = "DSR",
        S686 = "S686", S1897 = "S1897", S12K = "S12K", DBS = "DBS",
        M1014 = "M1014", NS2000 = "NS2000",
        M249 = "M249", DP28 = "DP28", MG3 = "MG3",
        PAN = "Pan", DAGGER = "Dagger", Machete = "Machete",
    }

    function WeaponSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap or not AliasMap.Slider then return nil end
    DazhiMH_Config.Load(true)
    
    local stack = {}

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("◆ FORMULA // WEAPON LAB") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 14 })

    for _, group in ipairs(WeaponSettingTab.WEAPON_GROUPS) do
        table.insert(stack, {
            UI = AliasMap.Title,
            Text = CustomTitleLoc.Register(group.title)
        })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
        
        for _, weaponKey in ipairs(group.weapons) do
            local weaponName = WeaponSettingTab.WEAPON_NAMES[weaponKey] or weaponKey
            local maxIndex = DazhiMH_Config.GetMaxWeaponIndex(weaponKey)
            local sliderKey = "Skin_" .. weaponKey
            local inputKey = "WeaponInput_" .. weaponKey
            
            -- ========== Slider (Control Preset Index) ==========
            table.insert(stack, {
                Key = sliderKey,
                UI = AliasMap.Slider,
                Text = weaponName,
                Help = "Move the slider to choose a saved skin preset. Use Custom Skin ID below for a specific item ID.",
                Min = 1,
                Max = maxIndex,
                IsPercent = false,
                GetFunc = function() 
                    return DazhiMH_Config.Get(weaponKey, 1) 
                end,
                SetFunc = function(_, value)
                    value = math.floor(tonumber(value) or 1)
                    -- When using slider, clear custom ID record
                    DazhiMH_Config.Set("CUSTOM_" .. weaponKey, 0)
                    return DazhiMH_Config.Set(weaponKey, value)
                end
            })
            
            -- ========== Input Box Button (Directly Show/Modify Skin ID) ==========
            table.insert(stack, {
                Key = inputKey,
                UI = AliasMap.OpenWindow,
                Text = "    ↳ CUSTOM SKIN ID",
                GetFunc = function()
                    -- Prefer reading saved custom ID from config file
                    local savedCustomId = DazhiMH_Config.Get("CUSTOM_" .. weaponKey, 0)
                    if savedCustomId > 0 then
                        return tostring(savedCustomId)
                    end
                    -- Otherwise get from memory
                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end
                    if currentSkinID == 0 then
                        return "Not Set"
                    end
                    return tostring(currentSkinID)
                end,
                SetFunc = function()
                    local weaponID = _G.WeaponNameToID[weaponKey]
                    local currentSkinID = 0
                    if weaponID and _G.WeaponSkinID then
                        currentSkinID = _G.WeaponSkinID[weaponID] or 0
                    end
                    
                    DazhiMH_Config.ShowNumberInputPopup({
                        title = weaponName .. " - Input Skin ID",
                        value = currentSkinID,
                        min = 1,
                        max = 9999999999,
                        refreshKey = inputKey,
                        onConfirm = function(newValue)
                            local skinId = math.floor(tonumber(newValue) or 0)
                            if skinId <= 0 then return end
                            
                            -- 1. Save skin ID to memory (takes effect immediately)
                            if weaponID then
                                _G.WeaponSkinID = _G.WeaponSkinID or {}
                                _G.WeaponSkinID[weaponID] = skinId
                                if _G.GameAvatarHandlerweapons then 
                                    pcall(_G.GameAvatarHandlerweapons) 
                                end
                            end
                            
                            -- 2. Index 0 means use custom ID
                            DazhiMH_Config.Set(weaponKey, 0)
                            
                            -- 3. Permanently save the custom skin ID to file
                            DazhiMH_Config.Set("CUSTOM_" .. weaponKey, skinId)
                        end
                    })
                end
            })
            
            table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
        end
        
        table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    end
    
    return stack
end

-- ==================== Vehicle Tab ====================
local VehicleSettingTab = _G.VehicleSettingTab or {}
_G.VehicleSettingTab = VehicleSettingTab
VehicleSettingTab.TAB_NAME = "Vehicle Skin"

VehicleSettingTab.VEHICLE_KEYS = {
    "DACIA", "COUPERB", "BUGGY", "UAZ", "MOTO", "SIDECARMOTO",
    "BLOOMSC", "RONY", "RZR", "BIGFOOT", "HORSE", "MINIBUS",
    "BOAT", "ROADSTER", "MIRADO", "MIRADOC"
}

VehicleSettingTab.VEHICLE_NAMES = {
    DACIA = "Dacia Sedan",
    COUPERB = "Coupe RB",
    BUGGY = "Off-Road Buggy",
    UAZ = "UAZ Jeep",
    MOTO = "Motorcycle",
    SIDECARMOTO = "Sidecar Motorcycle",
    BLOOMSC = "Scooter",
    RONY = "Rony Pickup",
    RZR = "RZR All-Terrain",
    BIGFOOT = "Bigfoot",
    HORSE = "Horse",
    MINIBUS = "Minibus",
    BOAT = "Speedboat",
    ROADSTER = "Roadster",
    MIRADO = "Mirado",
    MIRADOC = "Mirado Convertible"
}

function VehicleSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end
    DazhiMH_Config.Load(true)
    
    local stack = {}

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("◆ FORMULA // VEHICLE GARAGE") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 14 })
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("VEHICLE SKIN PRESETS") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })
    
    for _, key in ipairs(VehicleSettingTab.VEHICLE_KEYS) do
        local name = VehicleSettingTab.VEHICLE_NAMES[key] or key
        local maxIndex = DazhiMH_Config.GetMaxVehicleIndex(key)
        if maxIndex < 1 then maxIndex = 1 end
        
table.insert(stack, {
    Key = "Vehicle_" .. key,
    UI = AliasMap.Slider,
    Text = name,
    Help = "Move the slider to select the saved skin preset for this vehicle.",
    Min = 1,
    Max = maxIndex,
    IsPercent = false,
    GetFunc = function()
        -- Star Prefer reading wumingking.h
        local v
        if _G.Wumingking and _G.Wumingking.GetVehicle then
            v = _G.Wumingking.GetVehicle(key)
        end
        if not v or v < 1 then
            v = DazhiMH_Config.Get(key, 1)
        end
        v = math.floor(tonumber(v) or 1)
        if v < 1 then v = 1 end
        if v > maxIndex then v = maxIndex end
        return v
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 1)
        if idx < 1 then idx = 1 end
        if idx > maxIndex then idx = maxIndex end

        -- Star Key: Write wumingking.h + save in real time
        if _G.Wumingking and _G.Wumingking.SetVehicle then
            _G.Wumingking.SetVehicle(key, idx)
        end

        -- Compatibility: Also write wumingking.h
        if DazhiMH_Config and DazhiMH_Config.Set then
            DazhiMH_Config.Set(key, idx)
        end

        -- Star Immediately refresh lobby vehicle
    if _G.LobbyVehicleRefresh then
        pcall(_G.LobbyVehicleRefresh)
    end

    -- Star Immediately refresh in-match vehicle
    if _G.GameVehicleAvatarHandler then
        pcall(_G.GameVehicleAvatarHandler)
    end
    return true
end
})
        table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })
    end
    
    return stack
end





-- ==================== Feature Tabs ====================
local BoxSettingTab = _G.BoxSettingTab or {}
_G.BoxSettingTab = BoxSettingTab
BoxSettingTab.TAB_NAME = "Feature Toggles"
BoxSettingTab.SECTION_TITLE = "Crate Skin"
BoxSettingTab.WEATHER_TITLE = "Weather Effect"
BoxSettingTab.CAMERA_TITLE = "Camera Settings"
BoxSettingTab.TRAIL_TITLE = "Movement Trail Effect"  -- New
BoxSettingTab.WEATHER_OPTIONS = {
    "No Weather", "Rain", "Snow", "Blizzard", "Thunderstorm"
}
BoxSettingTab._weatherSwitcherText = nil
BoxSettingTab._trailSwitcherText = nil  -- Trail option text

BoxSettingTab.WATERMARK_TITLE = "UI Watermark"

function BoxSettingTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end

    DazhiMH_Config.Load(true)
    local stack = {}

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("◆ FORMULA // VISUAL CONTROL") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 14 })
    BuildRefreshAllButton(AliasMap, stack)
    -- ========== Crate Skin Area ==========
    -- Dead Box Skin Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("01 | DEATH BOX SKIN")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "DeadBoxSkinEnable",
        UI = AliasMap.Switcher,
        Text = "ENABLE DEATH BOX SKIN",
        Help = "Death box will show your current weapon or vehicle skin effect\nWhen enabled, death box will show your current weapon or vehicle skin effect",
        GetFunc = function()
            local value = DazhiMH_Config.Get("DEADBOX_SKIN", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.EnableDeadBoxSkin = true
                DazhiMH_Config.Set("DEADBOX_SKIN", 1)
            else
                _G.EnableDeadBoxSkin = false
                DazhiMH_Config.Set("DEADBOX_SKIN", 0)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    
    -- ========== Weapon Inspect Animation Area ==========
    -- Weapon Inspection Animation Section
    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("02 | WEAPON INSPECT ANIMATION") })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WeaponAnimEnable",
        UI = AliasMap.Switcher,
        Text = "ENABLE WEAPON INSPECT ANIMATION",
        Help = "Auto-play inspect animation when holding inspectable weapon\nSupports upgradable firearms (e.g. M416, AKM, etc.)\nAuto-play inspection animation for supported weapons (M416, AKM, etc.)",
        GetFunc = function()
            local value = DazhiMH_Config.Get("WEAPON_ANIM", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("WEAPON_ANIM", 1)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(true)
                end
            else
                DazhiMH_Config.Set("WEAPON_ANIM", 0)
                if _G.SetWeaponAnimation then
                    _G.SetWeaponAnimation(false)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== Watermark Toggle ==========
    -- Watermark Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("03 | BRAND WATERMARK")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    table.insert(stack, {
        Key = "WatermarkEnable",
        UI = AliasMap.Switcher,
        Text = "SHOW FORMULA WATERMARK",
        Help = "Show @saailformula watermark above game screen\nShow @saailformula watermark on game screen",
        GetFunc = function()
            local value = DazhiMH_Config.Get("WATERMARK", 1)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("WATERMARK", 1)
                _G.WatermarkEnabled = true
            else
                DazhiMH_Config.Set("WATERMARK", 0)
                _G.WatermarkEnabled = false
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== Movement Trail Effect Area ==========
    -- Movement Trail Effect Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("04 | MOVEMENT TRAIL")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- Trail Toggle / Trail Toggle
    table.insert(stack, {
        Key = "TrailEnable",
        UI = AliasMap.Switcher,
        Text = "ENABLE MOVEMENT TRAIL",
        Help = "Show trail afterimage when character moves (match only)\nShow trail effect when moving (match only)",
        GetFunc = function()
            local value = DazhiMH_Config.Get("TRAIL_ENABLE", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                DazhiMH_Config.Set("TRAIL_ENABLE", 1)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = true
                    pcall(_G.GoldenLeavesTrail.Apply)
                end
            else
                DazhiMH_Config.Set("TRAIL_ENABLE", 0)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.Enabled = false
                    pcall(_G.GoldenLeavesTrail.Stop)
                end
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 5 })

    -- Trail Type Selection: use a slider so all eight supported IDs are selectable.
    local TRAIL_PRESETS = {
        { id = 4531002, name = "Golden Leaves Trail" },
        { id = 4531001, name = "Starry Purple Trail" },
        { id = 4541001, name = "Cool Graffiti Footsteps" },
        { id = 4531003, name = "Summer Bubble Fantasy Trail" },
        { id = 4531004, name = "Moonbirch Wisp Trail" },
        { id = 4531005, name = "Fusion Crystal Lattice Trail" },
        { id = 4541004, name = "Azure Sea Ripple Trail" },
        { id = 4541005, name = "Moonfall Trace Trail" },
    }

    local function getTrailIndex(trailId)
        trailId = tonumber(trailId) or 0
        for i, preset in ipairs(TRAIL_PRESETS) do
            if preset.id == trailId then return i end
        end
        return 1
    end

    local function getTrailLabel(trailId)
        trailId = tonumber(trailId) or 0
        for _, preset in ipairs(TRAIL_PRESETS) do
            if preset.id == trailId then
                return preset.name .. " | ID: " .. tostring(preset.id)
            end
        end
        return "Custom Trail ID: " .. tostring(trailId)
    end

    table.insert(stack, {
        Key = "TrailType",
        UI = AliasMap.Slider,
        Text = "TRAIL PRESET",
        Help = "Slide across all 8 supported trail types. The selected name and ID are shown below.",
        Min = 1,
        Max = #TRAIL_PRESETS,
        IsPercent = false,
        GetFunc = function()
            local trailId = (_G.GoldenLeavesTrail and _G.GoldenLeavesTrail.TRAIL_ITEM_ID)
                or DazhiMH_Config.Get("TRAIL_TYPE", 4531002)
            return getTrailIndex(trailId)
        end,
        SetFunc = function(_, value)
            local idx = math.floor(tonumber(value) or 1)
            if idx < 1 then idx = 1 end
            if idx > #TRAIL_PRESETS then idx = #TRAIL_PRESETS end
            local trailId = TRAIL_PRESETS[idx].id

            if _G.GoldenLeavesTrail and type(_G.GoldenLeavesTrail.SetType) == "function" then
                pcall(_G.GoldenLeavesTrail.SetType, trailId)
            else
                DazhiMH_Config.Set("TRAIL_TYPE", trailId)
                if _G.GoldenLeavesTrail then
                    _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId
                end
            end
            return true
        end
    })

    table.insert(stack, {
        Key = "TrailTypeCurrent",
        UI = AliasMap.OpenWindow,
        Text = "    ↳ SELECTED TRAIL / ID",
        GetFunc = function()
            local trailId = (_G.GoldenLeavesTrail and _G.GoldenLeavesTrail.TRAIL_ITEM_ID)
                or DazhiMH_Config.Get("TRAIL_TYPE", 4531002)
            return getTrailLabel(trailId)
        end,
        SetFunc = function() end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== Weather Area ==========
    -- Weather Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("05 | WEATHER EFFECTS")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    if not BoxSettingTab._weatherSwitcherText then
        BoxSettingTab._weatherSwitcherText = CustomTitleLoc.RegisterList({
            "No Weather / No Weather",
            "Rain / Rain",
            "Snow / Snow",
            "Blizzard / Blizzard",
            "Thunderstorm / Thunderstorm"
        })
    end

    table.insert(stack, {
        Key = "WeatherMode",
        UI = AliasMap.Switcher,
        Text = "WEATHER PRESET",
        Help = "Select weather effect in match\nSelect weather effect in match\n0=Sunny 1=Rain 2=Snow 3=Blizzard 4=Thunderstorm",
        SwitcherText = BoxSettingTab._weatherSwitcherText,
        SwitcherValue = { 0, 1, 2, 3, 4 },
        GetFunc = function()
            return DazhiMH_Config.Get("WEATHER", 0)
        end,
        SetFunc = function(_, value)
            local weatherValue = tonumber(value) or 3
            _G.WeatherMode = weatherValue
            DazhiMH_Config.Set("WEATHER", weatherValue)
            if _G.UpdateWeatherMode then
                _G.UpdateWeatherMode(weatherValue)
            end
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })

    -- ========== Camera Area ==========
    -- Camera Section
    table.insert(stack, {
        UI = AliasMap.Title,
        Text = CustomTitleLoc.Register("06 | CAMERA CONTROL")
    })
    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- Star Wide-angle toggle
    table.insert(stack, {
        Key = "FOVEnable",
        UI = AliasMap.Switcher,
        Text = "ENABLE WIDE-ANGLE CAMERA",
        Help = "Enable to adjust camera field of view\nEnable to adjust camera field of view",
        GetFunc = function()
            local value = DazhiMH_Config.Get("FOV_ENABLE", 0)
            return value == 1
        end,
        SetFunc = function(_, value)
            if value then
                _G.ConfigFOVEnable = true
                DazhiMH_Config.Set("FOV_ENABLE", 1)   -- Star Write wumingking.h immediately
            else
                _G.ConfigFOVEnable = false
                DazhiMH_Config.Set("FOV_ENABLE", 0)   -- Star Write wumingking.h immediately
                _G.ConfigFOV = 90                      -- Return to default FOV when closed
            end
            if _G.GameCameraView then pcall(_G.GameCameraView) end  -- Star Take effect immediately
            return true
        end
    })

    table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

    -- Star Wide-angle degree slider
    table.insert(stack, {
        Key = "FOVValue",
        UI = AliasMap.Slider,
        Text = "CAMERA FIELD OF VIEW",
        Help = "Adjust camera field of view (90-120)\nAdjust camera field of view (90-120)",
        Min = 90,
        Max = 120,
        IsPercent = false,
        GetFunc = function()
            return DazhiMH_Config.Get("FOV_VALUE", 90)
        end,
        SetFunc = function(_, value)
            local fovValue = math.floor(tonumber(value) or 90)
            if fovValue < 90 then fovValue = 90 end
            if fovValue > 120 then fovValue = 120 end
            _G.ConfigFOV = fovValue
            DazhiMH_Config.Set("FOV_VALUE", fovValue)   -- Star Write wumingking.h immediately
            if _G.GameCameraView then pcall(_G.GameCameraView) end  -- Star Take effect immediately
            return true
        end
    })

    return stack
end


    -- ==================== Main Tab Management ====================
local function BuildSuitPage()
    local stack = SuitSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Suit", text = "Character Outfit", UIKey = "Setting_StackContainer", Stack = stack }
end

local function BuildVehiclePage()
    local stack = VehicleSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Vehicle", text = "Vehicle Skin", UIKey = "Setting_StackContainer", Stack = stack }
end
local function BuildWeaponPage()
    local stack = WeaponSettingTab.BuildStack()
    if not stack then return nil end

    return {
        Key = "Weapon",
        text = "Weapon Skin",
        UIKey = "Setting_StackContainer",
        Stack = stack
    }
end
local function BuildBoxPage()
    local stack = BoxSettingTab.BuildStack()
    if not stack then return nil end
    return { Key = "Box", text = "Feature Toggles", UIKey = "Setting_StackContainer", Stack = stack }
end


-- ==================== FORMULA Profile & Stats Tab ====================
_G.ProfileStatsTab = _G.ProfileStatsTab or {}

function _G.ProfileStatsTab.BuildStack()
    CustomTitleLoc.Patch()
    local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
    if not ok or not AliasMap then return nil end

    local stack = {}
    local function addTitle(title)
        table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register(title) })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 8 })
    end
    local function addSwitch(key, title, help)
        table.insert(stack, {
            Key = "Formula_" .. key,
            UI = AliasMap.Switcher,
            Text = title,
            Help = help,
            GetFunc = function()
                return _G.FormulaFeatureEnabled(key)
            end,
            SetFunc = function(_, value)
                _G.FormulaSetFeature(key, value == true)
                return true
            end
        })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 12 })
    end

    addTitle("◆ FORMULA // PROFILE & STATS")
    addSwitch("profileIdentity", "PROFILE AVATAR / FRAME + PLAYER LEVEL",
        "Local profile preview: Avatar 40263, Frame 2003000 and Level 100. Default OFF.")
    addSwitch("avatarLists", "AVATAR & FRAME SELECTION LISTS",
        "Enables the script's local avatar and frame ID selection lists, including alternative IDs. Default OFF.")
    addSwitch("profileAltAvatar", "ALTERNATIVE PROFILE AVATAR / FRAME",
        "Local alternative appearance: Avatar 30397 and Frame 2002000. Default OFF.")
    addSwitch("profileCosmetics", "PROFILE BACKGROUND / NAMECARD / GOLDEN NAME",
        "Local appearance preview: Background 61510029, Social Namecard Frame 61100155 and Golden Nickname ID 61910003. Default OFF.")

    addTitle("◆ RANK / SEASON PROGRESSION")
    addSwitch("rankProgress", "ENABLE RANK, PEAK & SEASON PROFILE VALUES",
        "Local display values: Level 100, Conqueror 91 stars / 13,200 rating, Peak 8,000, season rating 8,500, rank 44, Journey Badge 20, achievement points 9,500, played years 10, title ID 3 and Honor/Ace imprint. Default OFF.")

    addTitle("◆ SOCIAL & WEAPON STATS")
    addSwitch("creditScore", "CREDIT SCORE",
        "Enables the Credit Score hook using the value already configured in UltimateEngine_Config. Default OFF.")
    addSwitch("collectionLikes", "COLLECTION PAGE LIKE COUNT",
        "Enables the collection Like Count hook using its configured value. Default OFF.")
    addSwitch("personalPopularity", "PERSONAL SPACE POPULARITY",
        "Enables the Personal Space Popularity hook using its configured value. Default OFF.")
    addSwitch("weaponPower", "WEAPON POWER",
        "Enables the Weapon Power hook using its configured value. Default OFF.")

    addTitle("◆ COLLECTION HALL")
    addSwitch("collectionStats", "COLLECTION LEVEL / TIER / TITLE / POINTS",
        "Local display values: Level 100, Tier 100, Collection Champion, 99,999 points. Default OFF.")
    addSwitch("collectionUnlock", "LOCAL COLLECTION PLATFORM / UC CHECK PREVIEW",
        "Client-side preview only: bypasses local collection-level and UC prompts for your own collection hall. Does not grant server ownership or perform a real purchase. Default OFF.")

    addTitle("◆ LOCAL CURRENCY PREVIEW")
    addSwitch("fakeWallet", "FAKE WALLET + LOCAL CURRENCY CHECKS",
        "Client-side display only: G Coin 78,787,878; UC 99,999,991; Silver Coin 78,916,613; separate fake UC check wallet default 999,999,999. Local purchase/crate simulations are not real UC and are not server-authoritative. Default OFF.")

    table.insert(stack, { UI = AliasMap.Title, Text = CustomTitleLoc.Register("ALL SWITCHES START OFF WHEN THE SCRIPT LOADS") })
    return stack
end

_G.BuildProfileStatsPage = function()
    local stack = _G.ProfileStatsTab.BuildStack()
    if not stack then return nil end
    return { Key = "ProfileStats", text = "Profile & Stats", UIKey = "Setting_StackContainer", Stack = stack }
end

-- ==================== Star Directly Rewrite Tab Button Text Star ====================
-- Game does not recognize our text field localization, here Hook Tab button Widget,
-- After its SetText/SetData, forcibly write Chinese
do
local TAB_TEXT_MAP = {
    Suit    = "Character Outfit",
    Box     = "Feature Toggles",
    Vehicle = "Vehicle Skin",
    Weapon  = "Weapon Skin",
    ProfileStats = "Profile & Stats",
}

    -- All possible Tab Widget class names to hook
    local WIDGET_NAMES = {
        "client.slua.umg.setting.Setting_Switch_Btn_UIBP",
        "client.slua.umg.setting.Setting_Switch_UIBP",
        "client.slua.umg.setting.Setting_SwitchItem_UIBP",
        "client.slua.umg.setting.Setting_Main_Switch_UIBP",
        "client.slua.umg.setting.Setting_Left_Menu_UIBP",
        "client.slua.umg.setting.Setting_Main_UIBP",
    }

    -- Iterate all TextBlocks in UI, find those with empty text, try matching by index
    local function forceSetTabTextByKey(ui, key)
        if not ui or not key then return end
        local text = TAB_TEXT_MAP[key]
        if not text then return end

        -- Try multiple possible TextBlock field names
        local cands = {
            "TextBlock_Name", "TextBlock_Title", "TextBlock_Text",
            "TextBlock_Content", "TextBlock_MenuName", "TextBlock_0",
            "TextBlock_1", "TextBlock_2", "TextBlock_3",
        }
        local root = ui.UIRoot
        if not root then return end

        for _, name in ipairs(cands) do
            local tb = root[name]
            if tb and tb.SetText then
                pcall(function() tb:SetText(text) end)
                return true
            end
        end
        return false
    end

    -- Save mapping: Tab key -> Widget instance. Set by OnRefresh etc. after UI creation
    _G.__CTL_TabWidgets = _G.__CTL_TabWidgets or {}

    for _, modName in ipairs(WIDGET_NAMES) do
        pcall(function()
            local cls = require(modName)
            if not cls then return end

            -- Common refresh function name list
            local funcs = {
                "SetData", "SetUIData", "RefreshData", "OnRefresh",
                "UpdateUI", "SetTabData", "Refresh", "SetInfo",
                "InitData", "SetItemData", "SetTitle",
            }
            for _, fnName in ipairs(funcs) do
                local orig = cls[fnName]
                if type(orig) == "function" and not cls["__CTL_patched_" .. fnName] then
                    cls["__CTL_patched_" .. fnName] = true
                    cls[fnName] = function(self, data, ...)
                        local ret = orig(self, data, ...)
                        pcall(function()
                            -- Try to get Key from data
                            local key = nil
                            if type(data) == "table" then
                                key = data.Key or data.key or data.TabKey
                            elseif type(data) == "string" then
                                key = data
                            end
                            if key and TAB_TEXT_MAP[key] then
                                forceSetTabTextByKey(self, key)
                                _G.__CTL_TabWidgets[key] = self
                            else
                                -- When key is unknown, fallback to self.Key or self.key
                                local k2 = self.Key or self.key
                                if k2 and TAB_TEXT_MAP[k2] then
                                    forceSetTabTextByKey(self, k2)
                                    _G.__CTL_TabWidgets[k2] = self
                                end
                            end
                        end)
                        return ret
                    end
                end
            end

            -- Some Widgets use OnPostInitialize / OnInitialize
            local postFuncs = { "OnPostInitialize", "OnInitialize", "OnShow" }
            for _, fnName in ipairs(postFuncs) do
                local orig = cls[fnName]
                if type(orig) == "function" and not cls["__CTL_patched2_" .. fnName] then
                    cls["__CTL_patched2_" .. fnName] = true
                    cls[fnName] = function(self, ...)
                        local ret = orig(self, ...)
                        pcall(function()
                            local k = self.Key or self.key or self._Key
                            if k and TAB_TEXT_MAP[k] then
                                forceSetTabTextByKey(self, k)
                                _G.__CTL_TabWidgets[k] = self
                            end
                        end)
                        return ret
                    end
                end
            end
        end)
    end

    -- Fallback: Scan UI every 1 sec, see if any Tab still needs textsupplement
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                local UIManager = _G.UIManager
                if not UIManager or not UIManager.UI_Config then return end
                -- Iterate all opened UIs, try to fill text
                for _, cfg in pairs(UIManager.UI_Config) do
                    local ok, ui = pcall(UIManager.GetUI, cfg)
                    if ok and ui and ui.UIRoot then
                        for key, text in pairs(TAB_TEXT_MAP) do
                            local w = _G.__CTL_TabWidgets[key]
                            if w and slua.isValid(w) then
                                forceSetTabTextByKey(w, key)
                            end
                        end
                    end
                end
            end)
        end, -1, 1)
    end
end
-- ==================== Star Directly Rewrite Tab Button Text END Star ====================

    -- ==================== Inject Main Menu ====================
    local function InjectCatalogs(originalCatalog)

    if type(originalCatalog) ~= "table" then
        return originalCatalog
    end

    local catalog = {}

    -- Copy original game pages
    for i = 1, #originalCatalog do
        catalog[i] = originalCatalog[i]
    end

    -- Check existing pages
    local function HasPage(key)
        for _, page in ipairs(catalog) do
            if page and page.Key == key then
                return true
            end
        end
        return false
    end

    -- Add missing pages
    local function AddPage(page)
        if page and not HasPage(page.Key) then
            catalog[#catalog + 1] = page
        end
    end

    AddPage(BuildSuitPage())
    AddPage(BuildVehiclePage())
    AddPage(BuildWeaponPage())
    AddPage(BuildBoxPage())
    AddPage(_G.BuildProfileStatsPage())

    return catalog
end

    local function IsSettingMainConfig(config)
        if not config then return false end
        if UIManager and UIManager.UI_Config and UIManager.UI_Config.setting_main then
            if config == UIManager.UI_Config.setting_main then return true end
        end
        return config.keyName == "setting_main"
    end

    local function IsInGameCatalog(catalog)
        if type(catalog) ~= "table" then return false end
        local hasGame, hasAccount = false, false
        for i = 1, #catalog do
            local page = catalog[i]
            if page and page.Key == "Game" then hasGame = true end
            if page and page.Key == "Account" then hasAccount = true end
        end
        return hasGame and not hasAccount
    end

    local function ShouldInject(catalog)
        if not IsInGameCatalog(catalog) then return false end
        if GameStatus and GameStatus.IsInLobbyOrMainCity then
            return not GameStatus.IsInLobbyOrMainCity()
        end
        return true
    end

    -- ... All previous code ...

    CustomTitleLoc.Patch()

    -- ========== Restore Saved Custom Weapon Skin ID ==========
    DazhiMH_Config.Load(true)
    DazhiMH_Config.RestoreCustomWeaponSkins()
    -- ===============================================

    -- Initialize popup
    DazhiMH_Config.PatchShowNoticeForSkinInput()
    DazhiMH_Config.PatchSkinInputPopup()



local origShowUI = UIManager and UIManager.ShowUI
if origShowUI then
    UIManager.ShowUI = function(config, arg1, arg2, arg3, arg4)
        if IsSettingMainConfig(config) and type(arg1) == "table" and ShouldInject(arg1) then
            local ok, newCatalog = pcall(InjectCatalogs, arg1)
            if ok and type(newCatalog) == "table" then
                arg1 = newCatalog
            end
        end
        if arg4 ~= nil then return origShowUI(config, arg1, arg2, arg3, arg4)
        elseif arg3 ~= nil then return origShowUI(config, arg1, arg2, arg3)
        elseif arg2 ~= nil then return origShowUI(config, arg1, arg2)
        elseif arg1 ~= nil then return origShowUI(config, arg1)
        else return origShowUI(config) end
    end
end

-- ==================== Star Star Star Hook setting_main_base to Write Tab Text Star Star Star ====================
do
    local ok, UIClass = pcall(require, "client.slua.umg.NewSetting.Main.setting_main_base")
    if ok and UIClass and UIClass.__inner_impl then
        local impl = UIClass.__inner_impl

        -- Force write text to Tab control (auto find TextBlock field)
        local function ForceSetText(child, text)
            if not child or not slua.isValid(child) then return end
            local found = false

            -- Known possible field names
            local names = {
                "TextBlock_Name_U", "TextBlock_Name_S",
                "TextBlock_Name", "TextBlock_Title",
                "TextBlock_Text", "TextBlock_TabName",
                "Text_Name_U", "Text_Name_S",
            }
            for _, n in ipairs(names) do
                local tb = child[n]
                if slua.isValid(tb) and tb.SetText then
                    pcall(function() tb:SetText(text) end)
                    found = true
                end
            end

            -- Iterate child to find all TextBlock / Text
            if not found then
                pcall(function()
                    for k, v in pairs(child) do
                        if type(k) == "string"
                           and (k:find("Text") or k:find("Name") or k:find("Title"))
                           and slua.isValid(v) and v.SetText then
                            v:SetText(text)
                            found = true
                        end
                    end
                end)
            end

            -- Iterate child.UIRoot
            if not found and child.UIRoot then
                pcall(function()
                    for k, v in pairs(child.UIRoot) do
                        if type(k) == "string"
                           and (k:find("Text") or k:find("Name") or k:find("Title"))
                           and slua.isValid(v) and v.SetText then
                            v:SetText(text)
                            found = true
                        end
                    end
                end)
            end
        end

        -- Refresh all Tab texts
        local function RefreshTabs(self)
            if not self or not self.UIRoot then return false end
            local list = self.AvailablePageList
            if type(list) ~= "table" or #list == 0 then return false end
            local selector = self.UIRoot.VerticalSelector_Page
            if not selector or not selector.SetNum then return false end
            pcall(function() selector:SetNum(#list) end)
            local done = 0
            for i, page in ipairs(list) do
                local text = page.text or page.Text
                if type(text) == "string" then
                    local child = selector:GetChildAt(i - 1)
                    if slua.isValid(child) then
                        ForceSetText(child, text)
                        done = done + 1
                    end
                end
            end
            if done > 0 then
                print("[DazhiMH] RefreshTabs refreshed " .. done .. " Tabs")
            end
            return done > 0
        end

        -- Ensure custom page is in AvailablePageList
        local function EnsureCustomPages(self)

            if not self then return end

            if type(self.AvailablePageList) ~= "table" then
                self.AvailablePageList = {}
            end

            local extra = {}

            local suitPage = BuildSuitPage()
            local vehiclePage = BuildVehiclePage()
            local weaponPage = BuildWeaponPage()
            local boxPage = BuildBoxPage()
            local profileStatsPage = _G.BuildProfileStatsPage()

            if suitPage then
                extra[#extra + 1] = suitPage
            end

            if vehiclePage then
                extra[#extra + 1] = vehiclePage
            end

            if weaponPage then
                extra[#extra + 1] = weaponPage
            end

            if boxPage then
                extra[#extra + 1] = boxPage
            end

            if profileStatsPage then
                extra[#extra + 1] = profileStatsPage
            end

            -- Prevent duplicate pages
            local function hasKey(key)
                for _, p in ipairs(self.AvailablePageList) do
                    if p and p.Key == key then
                        return true
                    end
                end
                return false
            end

            for _, p in ipairs(extra) do
                if p and not hasKey(p.Key) then
                    self.AvailablePageList[
                        #self.AvailablePageList + 1
                    ] = p
                end
            end
        end

        -- Hook OnPostInitialize
        local origPost = impl.OnPostInitialize

        impl.OnPostInitialize = function(self)

            if origPost then origPost(self) end

            pcall(function()

                if type(self.Catalog) == "table" then
                    local ok2, newCat = pcall(
                        InjectCatalogs,
                        self.Catalog
                    )

                    if ok2 and type(newCat) == "table" then
                        self.Catalog = newCat
                    end
                end

                EnsureCustomPages(self)
                RefreshTabs(self)

            end)
        end

        -- Hook OnShowFadeIn
        local origFade = impl.OnShowFadeIn

        impl.OnShowFadeIn = function(self)

            pcall(function()
                EnsureCustomPages(self)
                RefreshTabs(self)
            end)

            if origFade then
                return origFade(self)
            end
        end

        print("[DazhiMH] setting_main_base Tab Hook installed")
    end
end

-- Star Power: 0.5 -> 1 sec; If settings page not open, return directly
if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        pcall(function()
            local um = _G.UIManager
            if not um or not um.UI_Config or not um.UI_Config.setting_main then return end
            local ui = um.GetUI and um.GetUI(um.UI_Config.setting_main)
            if not ui or not ui.UIRoot then return end
            local list = ui.AvailablePageList
            if type(list) ~= "table" or #list == 0 then return end
            local selector = ui.UIRoot.VerticalSelector_Page
            if not selector or not selector.SetNum then return end
            for i, page in ipairs(list) do
                local text = page.text or page.Text
                if type(text) == "string" then
                    local child = selector:GetChildAt(i - 1)
                    if slua.isValid(child) then
                        local tbU = child.TextBlock_Name_U
                        local tbS = child.TextBlock_Name_S
                        if slua.isValid(tbU) and tbU.SetText then tbU:SetText(text) end
                        if slua.isValid(tbS) and tbS.SetText then tbS:SetText(text) end
                    end
                end
            end
        end)
    end, -1, 1)
end
-- ==================== Star Star Star Tab Text Hook END Star Star Star ====================

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(3, function() pcall(function() end) end)
        _G.Mytimer_ticker.AddTimer(8, function() pcall(function() end) end)
    end
    
    


-- ==================== Death Crate Skin System (All Modes) ====================
local REQUIRE_UPGRADEABLE_WEAPON = false
local DEBUG_NOTICE = false

_G.TrainingDeadBox = _G.TrainingDeadBox or {}
if _G.TrainingDeadBox._timerIndex then
    pcall(function()
        require("common.time_ticker").RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end)
end
_G.TrainingDeadBox._running = nil

local function notify(msg)
    if DEBUG_NOTICE then
        pcall(function()
            if ShowNotice then
                ShowNotice(tostring(msg))
            end
        end)
    end
    pcall(function() print(tostring(msg)) end)
end

_G.TrainingDeadBox._running = true
notify("Crate initialized successfully")

do
    local PlayerDeadBoxPath = "/Game/BluePrints/PickUp/Special/PlayerDeadBox.PlayerDeadBox"
    local BOX_LIFE_SPAN = 20

    local timeTicker = require("common.time_ticker")
    local installed = false
    local hooksReady = false
    local lastKills = nil
    local lastHitAI = nil
    local lastHitLoc = nil
    local activeBoxes = {}
    local processedBoxes = {}  -- Used for match mode scan anti-duplicate
    _G.TrainingDeadBox.activeBoxes = activeBoxes

    -- ========== Toggle Control ==========
    local function isDeadBoxSkinEnabled()
        return _G.EnableDeadBoxSkin == true or _G.EnableDeadBoxSkin == nil  -- Default on
    end

    -- ========== Mode Judgment ==========
    local function isInTrainingMode()
        if CGameState and slua.isValid(CGameState) then
            if CGameState.bIsTrainingMode then return true end
            if CGameState.STDeadBoxClientShowFeature then return true end
        end
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local ok2, gs = pcall(gd.GetGameState)
            if ok2 and slua.isValid(gs) and gs.bIsTrainingMode then
                return true
            end
        end
        return false
    end

    -- Check if in match (training ground or classic both count)
    local function isInGame()
        local ok, gd = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if ok and gd then
            local char = gd.GetPlayerCharacter()
            if slua.isValid(char) then return true end
        end
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return true end
        end
        return false
    end

    local function lazyGameplayData()
        local ok, mod = pcall(require, "GameLua.GameCore.Data.GameplayData")
        return ok and mod or nil
    end

    local function lazyActorTools()
        local ok, mod = pcall(require, "GameLua.Mod.BaseMod.Common.ActorTools")
        return ok and mod or nil
    end

    local function getPC()
        if slua_GameFrontendHUD then
            local pc = slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        local gd = lazyGameplayData()
        if gd then
            local pc = gd.GetPlayerController()
            if slua.isValid(pc) then return pc end
        end
        return nil
    end

    local function getChar()
        local pc = getPC()
        if slua.isValid(pc) and pc.GetPlayerCharacterSafety then
            return pc:GetPlayerCharacterSafety()
        end
        local gd = lazyGameplayData()
        if gd then
            local ch = gd.GetPlayerCharacter()
            if slua.isValid(ch) then return ch end
        end
        return nil
    end

    local function getUpgradeDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end
        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local cfg = ItemUpgradeSystem:GetUpgradeCfg(avatarId)
            if not cfg or not cfg.EffectID then return nil end
            local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
            if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                return effectCfg.DeadBox
            end
            return nil
        end)
        return ok and path or nil
    end

    local function getBestSkinDeadBoxPath(avatarId)
        if not avatarId or avatarId <= 0 then return nil end

        local direct = getUpgradeDeadBoxPath(avatarId)
        if direct and direct ~= "" then return direct end

        local ok, path = pcall(function()
            local ModuleManager = require("client.module_framework.ModuleManager")
            local ItemUpgradeSystem = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
            local groupList = ItemUpgradeSystem:GetUpgradeGroupByItemID(avatarId)
            if not groupList or #groupList == 0 then return nil end

            local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
            local ownedIndex = 0
            local boxPath = nil
            local boxUnlockIndex = 0

            for i, cfg in ipairs(groupList) do
                local RefitID = ItemUpgradeSystem:GetRefitSwitcherID(cfg.ItemID)
                if wardrobe_data:GetHallDepotItemDataByResID(cfg.ItemID)
                        or wardrobe_data:GetHallDepotItemDataByResID(RefitID) then
                    if i > ownedIndex then ownedIndex = i end
                end
                if boxUnlockIndex == 0 then
                    local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", cfg.EffectID)
                    if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                        boxUnlockIndex = i
                        boxPath = effectCfg.DeadBox
                    end
                end
            end

            if ownedIndex > 0 and boxUnlockIndex > 0 and ownedIndex >= boxUnlockIndex and boxPath then
                return boxPath
            end

            for i = #groupList, 1, -1 do
                local effectCfg = CDataTable.GetTableData("ItemUpgradeEffectConfig", groupList[i].EffectID)
                if effectCfg and effectCfg.DeadBox and effectCfg.DeadBox ~= "" then
                    if groupList[i].ItemID == avatarId then
                        return effectCfg.DeadBox
                    end
                end
            end
            return nil
        end)
        return ok and path or nil
    end

    local function hasPlayerDeadBoxAvatarPath(avatarId)
        if not avatarId or avatarId <= 0 then return false end
        local ok, exists = pcall(function()
            local UAvatarUtils = import("AvatarUtils")
            local UBackpackUtils = import("BackpackUtils")
            local avatarPath = UAvatarUtils.GetWeaponAvatarDeadBoxAvatarHandlePath(avatarId)
            return UBackpackUtils.IsBattleItemHandlePathExist(avatarPath)
        end)
        return ok and exists == true
    end

    local function getCurrentWeaponAvatarId()
        local char = getChar()
        if not slua.isValid(char) then return 0 end
        local weapon = char:GetCurrentWeapon()
        if not slua.isValid(weapon) then return 0 end
        local defineId = weapon:GetItemDefineID()
        if not defineId or defineId.Type == 6 then return 0 end
        local baseWeaponId = defineId.TypeSpecificID
        local skinId = 0

        pcall(function()
            local comp = weapon.WeaponAvatarComponent
            if slua.isValid(comp) then
                local EWeaponAttachmentSocketType = import("EWeaponAttachmentSocketType")
                local skinDefine = comp:GetEquippedItemDefineID(EWeaponAttachmentSocketType.MasterGun)
                if skinDefine and skinDefine.TypeSpecificID and skinDefine.TypeSpecificID > 0
                        and skinDefine.TypeSpecificID ~= baseWeaponId then
                    skinId = skinDefine.TypeSpecificID
                end
            end
        end)

        if skinId <= 0 and _G.WeaponSkinID and _G.WeaponSkinID[baseWeaponId] and _G.WeaponSkinID[baseWeaponId] > 0 then
            skinId = _G.WeaponSkinID[baseWeaponId]
        end

        if skinId <= 0 then
            local pc = getPC()
            if slua.isValid(pc) and pc.GetWeaponAvatarItemId then
                pcall(function()
                    local UBackpackUtils = import("BackpackUtils")
                    local bpId = UBackpackUtils.GetBPIDByResID(baseWeaponId)
                    local av = pc:GetWeaponAvatarItemId(bpId)
                    if av and av > 0 then skinId = av end
                end)
            end
        end

        return skinId or 0
    end

    local function resolveSpawnLoc(uPawn, fallbackLoc)
        if slua.isValid(uPawn) then
            if uPawn.GetRandomPutDownLocation then
                local ok, loc = pcall(uPawn.GetRandomPutDownLocation, uPawn, 80)
                if ok and loc then return loc end
            end
            local ok, loc = pcall(uPawn.K2_GetActorLocation, uPawn)
            if ok and loc then return loc end
        end
        return fallbackLoc
    end

    local function resolveAvatarId(avatarId)
        if not avatarId or avatarId <= 0 then
            avatarId = getCurrentWeaponAvatarId()
        end
        if REQUIRE_UPGRADEABLE_WEAPON then
            local function isUpgradeableSkin(id)
                if _G.isUpgradeableWeaponSkin then
                    local ok, r = pcall(_G.isUpgradeableWeaponSkin, id)
                    if ok and r then return true end
                end
                return false
            end
            if not isUpgradeableSkin(avatarId) then
                return nil
            end
        end
        return avatarId or 0
    end

    local function activateBoxVisuals(uBoxActor, feature)
        local delayFn = feature and feature.AddGameTimer
        local run = function()
            if not slua.isValid(uBoxActor) then return end
            pcall(function()
                if uBoxActor.Survive_FMC_Chest1 then
                    uBoxActor.Survive_FMC_Chest1:SetHiddenInGame(false, false)
                end
                if uBoxActor.DeadParticleSystem then
                    uBoxActor.DeadParticleSystem:Activate(true)
                end
            end)
        end
        if delayFn then
            pcall(delayFn, feature, 1, false, run)
        else
            timeTicker.AddTimer(1, run)
        end
    end

    local function spawnActorAtPath(boxPath, loc, onReady)
        local playerChar = getChar()
        local ActorTools = lazyActorTools()
        if ActorTools and slua.isValid(playerChar) then
            local called = false
            local function wrap(uBoxActor)
                if called then return end
                called = true
                onReady(uBoxActor)
            end
            local ok = pcall(function()
                ActorTools.SpawnActorAsync(playerChar, boxPath, loc, FRotator(0, 0, 0), FVector(1, 1, 1), wrap)
            end)
            if ok then
                timeTicker.AddTimer(0.8, function()
                    if not called then wrap(nil) end
                end)
                return true
            end
        end
        local syncOk, syncBox = pcall(function()
            local asset_util = require("common.asset_util")
            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return nil end
            local cls = asset_util.GetAssetSync(boxPath)
            if not cls then return nil end
            return world:SpawnActor(cls, loc, FRotator(0, 0, 0), nil)
        end)
        if syncOk and slua.isValid(syncBox) then
            onReady(syncBox)
            return true
        end
        onReady(nil)
        return false
    end

    local function applySkinDeadBoxEffects(uBoxActor)
        if not slua.isValid(uBoxActor) then return end
        pcall(function()
            if uBoxActor.PlaySmokeAnim then
                uBoxActor:PlaySmokeAnim()
            end
        end)
        pcall(function()
            if uBoxActor.DeadParticleSystem then
                uBoxActor.DeadParticleSystem:Activate(true)
            end
        end)
        pcall(function()
            local DeadBoxAvatarComp = uBoxActor.DeadBoxAvatarComponent_BP
            if slua.isValid(DeadBoxAvatarComp) and DeadBoxAvatarComp.HandleOnItemHandleLoaded then
                DeadBoxAvatarComp:HandleOnItemHandleLoaded()
            end
        end)
    end

    local function spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, onDone)
        if not hasPlayerDeadBoxAvatarPath(useAvatarId) then
            onDone(false)
            return
        end
        spawnActorAtPath(PlayerDeadBoxPath .. "_C", loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            pcall(function()
                uBoxActor:SetAvatarId(useAvatarId)
                uBoxActor:OnRep_AvatarId()
            end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "player")
        end)
    end

    local function spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, onDone)
        spawnActorAtPath(skinBoxPath, loc, function(uBoxActor)
            if not slua.isValid(uBoxActor) then
                onDone(false)
                return
            end
            trackBox(uBoxActor)
            pcall(function() uBoxActor:SetLifeSpan(boxLife) end)
            applySkinDeadBoxEffects(uBoxActor)
            activateBoxVisuals(uBoxActor, feature)
            onDone(true, "skin")
        end)
    end

    local lastSpawnAt = 0

    local function spawnDeadBoxAt(loc, avatarId, feature)
        -- ========== Toggle Check ==========
        if not isDeadBoxSkinEnabled() then return false end
        -- ==============================

        if not loc then return false end
        if not isInGame() then return false end  -- Change to isInGame(), both training ground and matches effective

        local now = os.clock()
        if now - lastSpawnAt < 0.5 then return false end
        lastSpawnAt = now

        local useAvatarId = resolveAvatarId(avatarId)
        if useAvatarId == nil then
            return false
        end

        local skinBoxPath = getBestSkinDeadBoxPath(useAvatarId)

        local boxLife = (feature and feature.BoxLifeSpan) or BOX_LIFE_SPAN

        local function done(ok, kind)
            if ok then
            else
            end
        end

        if skinBoxPath then
            spawnSkinMeshDeadBox(loc, skinBoxPath, feature, boxLife, function(ok, kind)
                if ok then
                    done(true, kind)
                    return
                end
                spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok2, kind2)
                    done(ok2, kind2)
                end)
            end)
            return true
        end

        spawnPlayerDeadBoxWithAvatar(loc, useAvatarId, feature, boxLife, function(ok, kind)
            done(ok, kind)
        end)
        return true
    end

    -- ========== Training Ground Mode: Trigger Based on Events ==========
    local function onKillDetected()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end  -- Training ground only

        local loc = nil
        if slua.isValid(lastHitAI) then
            loc = resolveSpawnLoc(lastHitAI, lastHitLoc)
        end
        if not loc and lastHitLoc then
            loc = lastHitLoc
        end
        if not loc then
            local char = getChar()
            if slua.isValid(char) then
                local ok, charLoc = pcall(char.K2_GetActorLocation, char)
                if ok and charLoc then
                    loc = FVector(charLoc.X + 150, charLoc.Y, charLoc.Z)
                end
            end
        end
        local feature = CGameState and CGameState.STDeadBoxClientShowFeature
        spawnDeadBoxAt(loc, nil, feature)
        lastHitAI = nil
    end

    local function onLocalShootDamage(_, __, weapon, targetActor, damage, hitBodyType, impactPoint)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if not slua.isValid(targetActor) then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(targetActor) end)
        if not isAI then return end
        lastHitAI = targetActor
        if impactPoint then
            lastHitLoc = impactPoint
        else
            pcall(function() lastHitLoc = targetActor:K2_GetActorLocation() end)
        end
    end

    local function onKillNumChanged()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        onKillDetected()
    end

    local function onPawnDied(_, __, uPawn, uKiller, typeId)
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end
        local myChar = getChar()
        if not slua.isValid(myChar) or uKiller ~= myChar then return end
        local isAI = false
        pcall(function() isAI = Game and Game.IsAI and Game:IsAI(uPawn) end)
        if not isAI then return end
        lastHitAI = uPawn
        onKillDetected()
    end

    -- ========== Match Mode: Scan Existing Crates in Scene ==========
    local function scanAndModifyExistingBoxes()
        if not isDeadBoxSkinEnabled() then return end
        if isInTrainingMode() then return end  -- Training ground uses event trigger, no scan

        pcall(function()
            local pc = getPC()
            if not slua.isValid(pc) then return end

            local pk = pc.Playerkey or pc.PlayerKey
            if not pk then return end

            local UGameplayStatics = import("GameplayStatics")
            if not UGameplayStatics then return end

            local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
            if not slua.isValid(world) then return end

            local APlayerTombBox = import("PlayerTombBox")
            if not APlayerTombBox then return end

            local actors = UGameplayStatics.GetAllActorsOfClass(world, APlayerTombBox, {})
            if not actors then return end

            for _, actor in pairs(actors) do
                if slua.isValid(actor) then
                    -- Skip already processed
                    if not processedBoxes[actor] then
                        local causer = actor.DamageCauser
                        if causer and (causer.Playerkey == pk or causer.PlayerKey == pk) then
                            local avatarComp = actor.DeadBoxAvatarComponent_BP
                            if slua.isValid(avatarComp) then
                                local skinId = getCurrentWeaponAvatarId()
                                if skinId > 0 and hasPlayerDeadBoxAvatarPath(skinId) then
                                    pcall(function()
                                        actor:SetAvatarId(skinId)
                                        actor:OnRep_AvatarId()
                                        applySkinDeadBoxEffects(actor)
                                        processedBoxes[actor] = true
                                        notify("DeadBox skin applied: " .. tostring(skinId))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function pollKills()
        if not isDeadBoxSkinEnabled() then return end
        if not isInTrainingMode() then return end

        if CGameState and CGameState.STDeadBoxClientShowFeature and CGameState.STDeadBoxClientShowFeature._tdbHooked then
            return
        end
        local gd = lazyGameplayData()
        if not gd then return end
        local ps = gd.GetPlayerState()
        if not slua.isValid(ps) or ps.Kills == nil then return end

        if lastKills ~= nil and ps.Kills > lastKills then
            onKillDetected()
        end
        lastKills = ps.Kills
    end

    local function hookCleanAIDeadBox(feature)
        if not feature or feature._tdbCleanHooked then return end
        feature.CleanAIDeadBox = function(self)
            local ActorTools = lazyActorTools()
            if not ActorTools or not slua.isValid(CGameState) then return end
            local uActorArray = ActorTools.GetAllActors(CGameState, "PlayerTombBox")
            local kept, removed = 0, 0
            for _, uActor in pairs(uActorArray) do
                if uActor and slua.isValid(uActor) then
                    if isOurBox(uActor) then
                        kept = kept + 1
                    else
                        pcall(function() Game:RemoveActor(uActor) end)
                        removed = removed + 1
                    end
                end
            end
            if DEBUG_NOTICE then notify("TDB clean k=" .. kept .. " r=" .. removed) end
        end
        feature._tdbCleanHooked = true
    end

    local function hookSpawnSTDeadBox(feature)
        if not feature or feature._tdbHooked then return end
        feature.SpawnSTDeadBox = function(self, loc, avatarId)
            if not loc then return end
            if self.IsAuthority and self:IsAuthority() then return end
            spawnDeadBoxAt(loc, avatarId, self)
        end
        feature._tdbHooked = true
    end

    local function hookPlayerController(pc)
        if not slua.isValid(pc) or pc._tdbHooked then return end
        if pc.ClientRPC_SpawnDeadBox then
            pc.ClientRPC_SpawnDeadBox = function(self, loc, avatarId)
                local feature = CGameState and CGameState.STDeadBoxClientShowFeature
                spawnDeadBoxAt(loc, avatarId, feature)
            end
        end
        pc._tdbHooked = true
    end

    local function registerEvents()
        if installed then return end
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_LOCAL_HANDLE_SHOOT_DAMAGE, onLocalShootDamage)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_ON_KILLNUM_CHANGED, onKillNumChanged)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_PAWN_DIED, onPawnDied)
        end)
        pcall(function()
            EventSystem:registEvent(EVENTTYPE_INGAME, EVENTID_INGAME_CONTROLLER_BEGINPLAY, function()
                timeTicker.AddTimer(1, function()
                    _G.TrainingDeadBox.tryInstall()
                end)
            end)
        end)
        installed = true
    end

    function _G.TrainingDeadBox.tryInstall()
        registerEvents()
        if CGameState and CGameState.STDeadBoxClientShowFeature then
            hookCleanAIDeadBox(CGameState.STDeadBoxClientShowFeature)
            hookSpawnSTDeadBox(CGameState.STDeadBoxClientShowFeature)
        end
        local pc = getPC()
        if slua.isValid(pc) then
            hookPlayerController(pc)
        end
        if isInGame() and not hooksReady then
            hooksReady = true
        end
    end

    function _G.TrainingDeadBox.tick()
        if not slua_GameFrontendHUD then return end
        if not isDeadBoxSkinEnabled() then return end

        _G.TrainingDeadBox.tryInstall()

        -- Training ground: Use kill polling
        if isInTrainingMode() then
            pollKills()
        else
            -- Match mode: Scan existing crates
            scanAndModifyExistingBoxes()
        end
    end

    registerEvents()
    timeTicker.AddTimer(0.5, function() _G.TrainingDeadBox.tryInstall() end)

    if _G.TrainingDeadBox._timerIndex and timeTicker.IsRunning(_G.TrainingDeadBox._timerIndex) then
        timeTicker.RemoveTimer(_G.TrainingDeadBox._timerIndex)
    end
    _G.TrainingDeadBox._timerIndex = timeTicker.AddTimerLoop(0.3, function()
        _G.TrainingDeadBox.tick()
    end, -1, 1.0)

end
end)


--Weather

pcall(function()
    local game_frontend_hud = require("game_frontend_hud")
    local audio_util = require("client.common.audio_util")
    local AkGameplayStatics = import("AkGameplayStatics")
    local EScreenParticleEffectType = import("EScreenParticleEffectType")

    -- ===================== Read from Global Config =====================
    local function getWeatherModeFromGlobal()
        local modeNum = _G.WeatherMode or 3  -- Default blizzard
        if modeNum == 0 then return "none"
        elseif modeNum == 1 then return "rain"
        elseif modeNum == 2 then return "snow"
        elseif modeNum == 3 then return "blizzard"
        elseif modeNum == 4 then return "storm"
        else return "blizzard"
        end
    end

    local WEATHER_MODE = getWeatherModeFromGlobal()
    local ENABLED = true  -- Enable weather system

    -- ===================== AUDIO PATHS =====================
    local AUDIO_RAIN_AMBIENT_PLAY = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain.Play_Ambient_Rain"
    local AUDIO_RAIN_AMBIENT_STOP = "/Game/WwiseEvent/Ambient/Play_Ambient_Rain_Stop.Play_Ambient_Rain_Stop"
    local AUDIO_RAIN_LOOP_PLAY    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Rain_Loop.Play_PlanPH_Object_Rain_Loop"
    local AUDIO_RAIN_LOOP_STOP    = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Rain_Loop.Stop_PlanPH_Object_Rain_Loop"
    local AUDIO_SNOW_PLAY = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Play_IceWorld3_TreasureBox_Snow_Loop.Play_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_SNOW_STOP = "/Game/Mod/IceWorld3/WwiseEvent/IceWorld3_Treasure_350/Stop_IceWorld3_TreasureBox_Snow_Loop.Stop_IceWorld3_TreasureBox_Snow_Loop"
    local AUDIO_WIND_PLAY  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Play_EasternRealm_Wind_Guest_Loop.Play_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND_STOP  = "/Game/Mod/EasternRealm/WwiseEvent/EasternRealm_POI_Wind_360/Stop_EasternRealm_Wind_Guest_Loop.Stop_EasternRealm_Wind_Guest_Loop"
    local AUDIO_WIND2_PLAY = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Play_PlanPH_Object_Wind_Machine_Loop.Play_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND2_STOP = "/Game/Mod/PlanPH/WwiseEvent/PlanPH_Object_310/Stop_PlanPH_Object_Wind_Machine_Loop.Stop_PlanPH_Object_Wind_Machine_Loop"
    local AUDIO_WIND3_PLAY = "/Game/Mod/Mecha/WwiseEvent/Mecha_FlyArmor_320/Play_Mecha_FlyArmor_Wind_Loop.Play_Mecha_FlyArmor_Wind_Loop"
    local AUDIO_THUNDER_PLAY = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Play_Character_KillEffect_Thunder_320.Play_Character_KillEffect_Thunder_320"
    local AUDIO_THUNDER_STOP = "/Game/WwiseEvent/Character_KillEffect/Character_KillEffect_320/Stop_Character_KillEffect_Thunder_2D_320.Stop_Character_KillEffect_Thunder_2D_320"
    local AUDIO_THUNDER2_PLAY = "/Game/Mod/ZNQ8th/WwiseEvent/ZNQ8th_RegionalTransformation_430/Play_ZNQ8th_RegionalTransformation_ThunderCloud.Play_ZNQ8th_RegionalTransformation_ThunderCloud"
    local AUDIO_THUNDER3_PLAY = "/Game/Mod/GoldenDragon/WwiseEvent/GoldenDragon_300/Play_GoldenDragon_Ground_Thunder.Play_GoldenDragon_Ground_Thunder"

    local THUNDER_MIN_FRAMES = 480
    local THUNDER_MAX_FRAMES = 1200
    local SOUND_REFRESH_FRAMES = 600

    -- ===================== STATE =====================
    local _active = false
    local _loopAudioIDs = {}
    local _lastInGame = false
    local _frameCount = 0
    local _lastSoundRefresh = 0
    local _nextThunderFrame = 0
    local _thunderIndex = 1

    local ALL_STOP_PATHS = {
        AUDIO_RAIN_AMBIENT_STOP, AUDIO_RAIN_LOOP_STOP,
        AUDIO_SNOW_STOP, AUDIO_WIND_STOP, AUDIO_WIND2_STOP,
        AUDIO_THUNDER_STOP,
    }

    local THUNDER_PATHS = {
        AUDIO_THUNDER_PLAY,
        AUDIO_THUNDER2_PLAY,
        AUDIO_THUNDER3_PLAY,
    }

    -- ===================== HELPERS =====================
    local function IsInGame()
        if GameStatus and GameStatus.IsInFightingStatus then
            return GameStatus.IsInFightingStatus()
        end
        if Client and GameFrontendHUD then
            return Client.GetUnrealNetworkStatus(GameFrontendHUD) == "Online"
        end
        return false
    end

    local function GetPlayerCharacter()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return nil end
        if pc.GetPlayerCharacterSafety then return pc:GetPlayerCharacterSafety() end
        if pc.GetCurPlayerCharacter then return pc:GetCurPlayerCharacter() end
        return nil
    end

    local function StopAudioID(id)
        if id and id ~= 0 then
            pcall(function() audio_util.StopSound(id) end)
            pcall(function() AkGameplayStatics.StopPlayingID(id) end)
        end
    end

    local function PlayLoopSound(key, path)
        local ownerObj = GetPlayerCharacter()
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj, nil, function(soundId)
                if soundId and soundId ~= 0 then
                    _loopAudioIDs[key] = soundId
                end
            end)
        end)
    end

    local function StopAllLoopSounds()
        for key, id in pairs(_loopAudioIDs) do
            StopAudioID(id)
            _loopAudioIDs[key] = nil
        end
        pcall(function()
            for _, stopPath in ipairs(ALL_STOP_PATHS) do
                audio_util.PlayAudioAsync(stopPath)
            end
            AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 0, false)
        end)
    end

    local function ScheduleNextThunder()
        _nextThunderFrame = _frameCount + math.random(THUNDER_MIN_FRAMES, THUNDER_MAX_FRAMES)
    end

    local function PlayThunder()
        local ownerObj = GetPlayerCharacter()
        local path = THUNDER_PATHS[_thunderIndex]
        _thunderIndex = (_thunderIndex % #THUNDER_PATHS) + 1
        pcall(function()
            audio_util.PlayAudioAsync(path, ownerObj)
        end)
        ScheduleNextThunder()
    end

    local function NeedsRainSound()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
    end

    local function NeedsSnowSound()
        return WEATHER_MODE == "snow" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsWindSound()
        return WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function NeedsThunder()
        return WEATHER_MODE == "rain" or WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"
    end

    local function StartSounds()
        StopAllLoopSounds()
        local ownerObj = GetPlayerCharacter()

        if NeedsRainSound() then
            pcall(function()
                AkGameplayStatics.AkSetRTPCValue("Ambient_Weather", 100, false)
            end)
            PlayLoopSound("rain_ambient", AUDIO_RAIN_AMBIENT_PLAY)
            PlayLoopSound("rain_loop", AUDIO_RAIN_LOOP_PLAY)
        end

        if NeedsSnowSound() then
            PlayLoopSound("snow", AUDIO_SNOW_PLAY)
        end

        if NeedsWindSound() then
            PlayLoopSound("wind1", AUDIO_WIND_PLAY)
            PlayLoopSound("wind2", AUDIO_WIND2_PLAY)
            PlayLoopSound("wind3", AUDIO_WIND3_PLAY)
        end

        if NeedsThunder() then
            ScheduleNextThunder()
            PlayThunder()
        end

        _lastSoundRefresh = _frameCount
    end

    -- ===================== VISUAL EFFECTS =====================
    local function SetRainVisual(on)
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) and pc.SetIsRainy then
            pc:SetIsRainy(on)
        end
    end

    local function SetParticleEffect(effectType, on)
        local char = GetPlayerCharacter()
        if slua.isValid(char) and char.SetRainyEffectEnable then
            char:SetRainyEffectEnable(effectType, on, on and 500 or 0)
        end
    end

    local function SetSnowScreenUI(on)
        pcall(function()
            if not UIManager or not UIManager.UI_Config_InGame then return end
            local cfg = UIManager.UI_Config_InGame.SnowEffectUI
            if not cfg then return end
            if on then
                if not UIManager.IsUIShow(cfg) then UIManager.ShowUI(cfg) end
            elseif UIManager.IsUIShow(cfg) then
                UIManager.CloseUI(cfg)
            end
        end)
    end

    local function ApplyVisuals(on)
        if not on then
            SetRainVisual(false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, false)
            SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, false)
            SetSnowScreenUI(false)
            return
        end

        local showRain     = WEATHER_MODE == "rain" or WEATHER_MODE == "storm"
        local showSnow     = WEATHER_MODE == "snow" or WEATHER_MODE == "storm"
        local showBlizzard = WEATHER_MODE == "blizzard" or WEATHER_MODE == "storm"

        SetRainVisual(showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Rainy, showRain)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Snowy, showSnow or showBlizzard)
        SetParticleEffect(EScreenParticleEffectType.ESPET_Blizzard, showBlizzard)
        SetSnowScreenUI(showSnow or showBlizzard)
    end

    -- ===================== ENABLE / DISABLE =====================
    local function EnableWeather()
        if _active then return end
        if not IsInGame() or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        StartSounds()
        _active = true
        print("[DEV_WEATHER] Enabled | mode =", WEATHER_MODE)
    end

    local function DisableWeather()
        if not _active then return end
        ApplyVisuals(false)
        StopAllLoopSounds()
        _active = false
        _nextThunderFrame = 0
        print("[DEV_WEATHER] Disabled")
    end

    local function RefreshWeather()
        if not ENABLED or not _active or WEATHER_MODE == "none" then return end
        ApplyVisuals(true)
        if _frameCount - _lastSoundRefresh >= SOUND_REFRESH_FRAMES then
            StartSounds()
        end
    end

    -- ===================== Update Weather Mode (For External Call) =====================
    function _G.UpdateWeatherMode(modeNum)
        local newMode = "none"
        if modeNum == 0 then newMode = "none"
        elseif modeNum == 1 then newMode = "rain"
        elseif modeNum == 2 then newMode = "snow"
        elseif modeNum == 3 then newMode = "blizzard"
        elseif modeNum == 4 then newMode = "storm"
        else newMode = "blizzard"
        end
        
        if WEATHER_MODE ~= newMode then
            local wasActive = _active
            if wasActive then
                DisableWeather()
            end
            WEATHER_MODE = newMode
            if wasActive and newMode ~= "none" and IsInGame() then
                EnableWeather()
            end
            print("[DEV_WEATHER] Mode changed to: " .. tostring(newMode) .. " (value=" .. tostring(modeNum) .. ")")
        else
            WEATHER_MODE = newMode
        end
    end

    -- ===================== MAIN LOOP =====================
    local function OnTick()
        if not ENABLED or WEATHER_MODE == "none" then return end

        _frameCount = _frameCount + 1
        local inGame = IsInGame()

        if inGame and not _lastInGame then
            print("[DEV_WEATHER] Entered match")
            EnableWeather()
        elseif not inGame and _lastInGame then
            print("[DEV_WEATHER] Left match")
            DisableWeather()
        end

        if inGame and _active then
            if _frameCount % 120 == 0 then
                RefreshWeather()
            end

            if NeedsThunder() and _nextThunderFrame > 0 and _frameCount >= _nextThunderFrame then
                PlayThunder()
            end
        end

        _lastInGame = inGame
    end

    game_frontend_hud.SetSluaTickListener(OnTick)

    game_frontend_hud.SetPostSwitchGameStatusListener(function(status)
        print("[DEV_WEATHER] Status:", status)
        if IsInGame() then EnableWeather() else DisableWeather() end
    end)

    print("[DEV_WEATHER] Loaded | mode = " .. WEATHER_MODE .. " (configurable via WEATHER= value)")
end)









-- ==================== Phoenixtra Summon (Mecha Summon Fix / Unlock) ====================
if not _G.__PHOENIXTRA_SUMMON_LOADED__ then
    _G.__PHOENIXTRA_SUMMON_LOADED__ = true
    
    local PhoenixtraSummon = {}
    
    -- ========== Config Parameters (Editable) ==========
    -- Mecha / Golden Armor item ID (prefer reading SHIRT=xxx from config file, this value is default)
    PhoenixtraSummon.XSUIT_ID = 1407856
    -- Mecha cycle / level tier (6 means 6-star / 7-star tier)
    PhoenixtraSummon.PERIOD = 6
    -- Backup template ID (use this ID's summon effect when main ID has no config)
    PhoenixtraSummon.FALLBACK_TEMPLATE_ID = 1407841
    -- Summon action ID (for pre-download resources)
    PhoenixtraSummon.CALL_ACTION_ID = 12219843
    -- Custom summon statue sequence path (nil means auto-read from config)
    PhoenixtraSummon.CALL_STATUE_SEQ = nil
    -- Summon animation play duration (sec)
    PhoenixtraSummon.CALL_TIME = 7
    
    -- ========== Feature Toggles ==========
    -- Bypass 7-star check (allow summon without 7-star mecha)
    PhoenixtraSummon.BYPASS_7STAR_CHECK = true
    -- Force wear mecha in match
    PhoenixtraSummon.FORCE_WEAR_IN_MATCH = true
    -- Play summon sequence locally (play animation even if server verification fails)
    PhoenixtraSummon.PLAY_LOCAL_SEQUENCE = true
    -- Debug log toggle
    PhoenixtraSummon.DEBUG = true
    -- Auto-install toggle
    PhoenixtraSummon.AUTO_INSTALL = true
    
    -- ========== Internal Variables ==========
    PhoenixtraSummon._dataHooked = false
    PhoenixtraSummon._menuHooked = false
    PhoenixtraSummon._platformHooked = false
    PhoenixtraSummon._tipsHooked = false
    PhoenixtraSummon._gameTipsHooked = false
    PhoenixtraSummon._resolvedEffect = nil
    PhoenixtraSummon._origGetTableData = nil
    PhoenixtraSummon._origGetTable = nil
    PhoenixtraSummon._origRequire = nil
    PhoenixtraSummon._lastSummonParam = nil
    PhoenixtraSummon._eventsHooked = false
    PhoenixtraSummon._summonCooldownUntil = 0
    PhoenixtraSummon._lastInstallState = nil
    
    local PLATFORM_MODULE = "GameLua.Activity.Commercialize.Actor.InteractActor.XSuitPlatform"
    
    -- ========== Update Mecha ID from Config File ==========
function PhoenixtraSummon.UpdateFromConfig()
    -- Star Completely deprecated, never lock model
    return 0
end
    
    local function hasMethod(obj, name)
        if not obj then return false end
        local v = obj[name]
        if v == nil then return false end
        local t = type(v)
        return t == "function" or t == "userdata" or t == "table"
    end
    
    local function getOwnerName(owner)
        local ok, name = pcall(function()
            local KismetSystemLibrary = import("KismetSystemLibrary")
            return KismetSystemLibrary.GetObjectName(owner)
        end)
        if ok and name then
            return tostring(name)
        end
        return tostring(owner)
    end
    
    local function isReadyState()
        local gs = slua_GameFrontendHUD and slua_GameFrontendHUD.GetGameState and slua_GameFrontendHUD:GetGameState()
        if slua.isValid(gs) and gs.GetGameModeState then
            return gs:GetGameModeState() == "ReadyState"
        end
        return false
    end
    
    local function log(msg)
        if PhoenixtraSummon.DEBUG then
            print("[PhoenixtraSummon] " .. tostring(msg))
        end
        pcall(function()
            local f = io.open("data/share1/loglua.txt", "a+")
            if f then
                f:write(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
                f:close()
            end
        end)
    end
    
    local function safeRequire(path)
        local ok, mod = pcall(require, path)
        if ok then return mod end
        return nil
    end
    
    local function shallowCopy(src)
        if type(src) ~= "table" then return src end
        local dst = {}
        for k, v in pairs(src) do dst[k] = v end
        return dst
    end
    
    local function rawGetTableData(tableName, key)
        if PhoenixtraSummon._origGetTableData then
            return PhoenixtraSummon._origGetTableData(tableName, key)
        end
        if CDataTable and CDataTable.GetTableData then
            return CDataTable.GetTableData(tableName, key)
        end
        return nil
    end
    
    local function rawGetTable(tableName)
        if PhoenixtraSummon._origGetTable then
            return PhoenixtraSummon._origGetTable(tableName)
        end
        if CDataTable and CDataTable.GetTable then
            return CDataTable.GetTable(tableName)
        end
        return nil
    end
    
    local function readBattleEffect(itemID)
        itemID = tonumber(itemID)
        if not itemID or itemID <= 0 then return nil end
        local row = rawGetTableData("GoldClothBattleEffect", itemID)
        if row and row.CallStatue and row.CallStatue ~= "" then
            return row
        end
        return nil
    end
    
    function PhoenixtraSummon.ResolveEffectConfig()
        if PhoenixtraSummon._resolvedEffect then
            return PhoenixtraSummon._resolvedEffect
        end
        local native = readBattleEffect(PhoenixtraSummon.XSUIT_ID)
        if native then
            PhoenixtraSummon._resolvedEffect = shallowCopy(native)
            PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
            log("native CallStatue ok for " .. tostring(PhoenixtraSummon.XSUIT_ID))
            return PhoenixtraSummon._resolvedEffect
        end
        local template = readBattleEffect(PhoenixtraSummon.FALLBACK_TEMPLATE_ID)
        if not template then
            local tbl = rawGetTable("GoldClothBattleEffect")
            if tbl then
                for _, row in pairs(tbl) do
                    if row and row.CallStatue and row.CallStatue ~= "" then
                        template = row
                        break
                    end
                end
            end
        end
        PhoenixtraSummon._resolvedEffect = template and shallowCopy(template) or {}
        PhoenixtraSummon._resolvedEffect.ID = PhoenixtraSummon.XSUIT_ID
        PhoenixtraSummon._resolvedEffect.Level = 7
        PhoenixtraSummon._resolvedEffect.CallTime = PhoenixtraSummon._resolvedEffect.CallTime or PhoenixtraSummon.CALL_TIME
        if PhoenixtraSummon.CALL_STATUE_SEQ and PhoenixtraSummon.CALL_STATUE_SEQ ~= "" then
            PhoenixtraSummon._resolvedEffect.CallStatue = PhoenixtraSummon.CALL_STATUE_SEQ
        end
        log("CallStatue=" .. tostring(PhoenixtraSummon._resolvedEffect.CallStatue or ""))
        return PhoenixtraSummon._resolvedEffect
    end
    
    function PhoenixtraSummon.BuildInjectedBattleEffectRow(existing)
        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local row = shallowCopy(existing or cfg)
        row.ID = PhoenixtraSummon.XSUIT_ID
        row.Level = 7
        row.CallStatue = cfg.CallStatue or row.CallStatue or ""
        row.CallTime = cfg.CallTime or row.CallTime or PhoenixtraSummon.CALL_TIME
        return row
    end
    
    function PhoenixtraSummon.InstallDataTableHooks()
        if PhoenixtraSummon._dataHooked or not CDataTable or not CDataTable.GetTableData then
            return PhoenixtraSummon._dataHooked
        end
        PhoenixtraSummon._origGetTableData = CDataTable.GetTableData
        PhoenixtraSummon._origGetTable = CDataTable.GetTable
        function CDataTable.GetTableData(tableName, key, ...)
            local row = PhoenixtraSummon._origGetTableData(tableName, key, ...)
            if tableName == "GoldClothBattleEffect" and tonumber(key) == PhoenixtraSummon.XSUIT_ID then
                return PhoenixtraSummon.BuildInjectedBattleEffectRow(row)
            end
            return row
        end
        PhoenixtraSummon._dataHooked = true
        log("CDataTable hooked")
        return true
    end
    
    function PhoenixtraSummon.RegisterLogicXSuitItem()
        local LogicXSuit = safeRequire("client.slua.logic.XSuit.logic_xsuit")
        if not LogicXSuit then return false end
        pcall(function()
            if LogicXSuit.InitXSuitItemList and not LogicXSuit.bItemInfoInited then
                LogicXSuit.InitXSuitItemList()
            end
        end)
        LogicXSuit.itemInfoList = LogicXSuit.itemInfoList or {}
        -- Register mecha item info (cycle=6, level=7 stars)
        LogicXSuit.itemInfoList[PhoenixtraSummon.XSUIT_ID] = {period = PhoenixtraSummon.PERIOD, level = 7}
        LogicXSuit.bItemInfoInited = true
        log("LogicXSuit registered for ID " .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end
    
    function PhoenixtraSummon.IsXSuitPlatformActor(owner)
        if not owner or not slua.isValid(owner) then return false end
        -- Check if it is mecha summon platform Actor
        if hasMethod(owner, "TriggerCallShowSequence") and hasMethod(owner, "GetStatue") then
            return true
        end
        if hasMethod(owner, "Wearing7StarXSuit") and hasMethod(owner, "TrySetCurrentCaller") then
            return true
        end
        local name = getOwnerName(owner):lower()
        if name:find("xsuitplatform") or name:find("xsuit_platform") or name:find("goldsuitplatform") then
            return true
        end
        return false
    end
    
    function PhoenixtraSummon.ForceWearNow()
        -- Force current character to wear mecha (for skipping detection)
        return true
    end
    
    function PhoenixtraSummon.BlockTip49553(tipsID)
        -- Block "Need 7-star mecha" tip (tipsID=49553)
        return PhoenixtraSummon.BYPASS_7STAR_CHECK and tonumber(tipsID) == 49553
    end
    
    function PhoenixtraSummon.InstallTipsHooks()
        -- Hook Tip System, Block 7-Star Check Tips
        if not PhoenixtraSummon._tipsHooked then
            local tips = safeRequire("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
            if tips and type(tips.BattleNormalTipsByTextID) == "function" and not tips.__phoenixtra_patched then
                local orig = tips.BattleNormalTipsByTextID
                tips.BattleNormalTipsByTextID = function(tipsID, ...)
                    if PhoenixtraSummon.BlockTip49553(tipsID) then
                        log("blocked BattleNormalTips 49553")
                        return
                    end
                    return orig(tipsID, ...)
                end
                tips.__phoenixtra_patched = true
                PhoenixtraSummon._tipsHooked = true
                log("IngameTipsTools hooked")
            end
        end
        if not PhoenixtraSummon._gameTipsHooked and Game and type(Game.UIShowTips) == "function" and not Game.__phoenixtra_patched then
            local orig = Game.UIShowTips
            Game.UIShowTips = function(self, playerKey, textID, ...)
                if PhoenixtraSummon.BlockTip49553(textID) then
                    log("blocked Game:UIShowTips 49553")
                    return
                end
                return orig(self, playerKey, textID, ...)
            end
            Game.__phoenixtra_patched = true
            PhoenixtraSummon._gameTipsHooked = true
            log("Game:UIShowTips hooked")
        end
    end
    
    function PhoenixtraSummon.PatchPlatformInstance(actor)
        -- Patch single summon platform instance
        if not actor or actor.__phoenixtra_inst_patched then return false end
        if not PhoenixtraSummon.IsXSuitPlatformActor(actor) then return false end
        
        local origClick = actor.OnClientClickInteractiveButton
        actor.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClick then return origClick(self, character, component) end
            return true
        end
        
        if hasMethod(actor, "Wearing7StarXSuit") then
            actor.Wearing7StarXSuit = function(self, character)
                if PhoenixtraSummon.BYPASS_7STAR_CHECK then return true end
                return false
            end
        end
        
        if hasMethod(actor, "GetWearingXSuitID") then
            actor.GetWearingXSuitID = function(self, character)
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
        end
        
        actor.__phoenixtra_inst_patched = true
        log("patched live platform " .. getOwnerName(actor))
        return true
    end
    
    function PhoenixtraSummon.PatchLivePlatformActors()
        -- Scan all summon platforms in scene and patch
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD.GetWorld and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return 0 end
        local count = 0
        pcall(function()
            local ActorTools = safeRequire("GameLua.Mod.BaseMod.Common.ActorTools")
            if not ActorTools or not ActorTools.GetAllActorsWithTag then return end
            local tags = {"XSuitPlatform", "GoldSuitPlatform", "SummonPlatform"}
            for _, tag in ipairs(tags) do
                local arr = ActorTools.GetAllActorsWithTag(world, tag)
                if arr then
                    for _, actor in pairs(arr) do
                        if PhoenixtraSummon.PatchPlatformInstance(actor) then
                            count = count + 1
                        end
                    end
                end
            end
        end)
        if count > 0 then log("PatchLivePlatformActors count=" .. tostring(count)) end
        return count
    end
    
    function PhoenixtraSummon.FindPlatformModule()
        local cls = safeRequire(PLATFORM_MODULE)
        if cls then return cls end
        if package and package.loaded then
            for name, mod in pairs(package.loaded) do
                if type(name) == "string" and name:find("XSuitPlatform", 1, true) and type(mod) == "table" then
                    return mod
                end
            end
        end
        return nil
    end
    
    function PhoenixtraSummon.PatchXSuitPlatformImpl(impl)
        -- Patch summon platform class implementation
        if type(impl) ~= "table" or impl.__phoenixtra_patched then return false end
        
        local origGetWear = impl.GetWearingXSuitID
        local origGetStatue = impl.GetStatue
        local origWear = impl.Wearing7StarXSuit
        local origClientClick = impl.OnClientClickInteractiveButton
        
        impl.GetWearingXSuitID = function(self, character)
            if PhoenixtraSummon.FORCE_WEAR_IN_MATCH then
                PhoenixtraSummon.ForceWearNow()
                return PhoenixtraSummon.XSUIT_ID
            end
            if origGetWear then return origGetWear(self, character) end
            return 0
        end
        
        impl.GetStatue = function(self, suitID)
            if tonumber(suitID) == PhoenixtraSummon.XSUIT_ID then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                return cfg.CallStatue or ""
            end
            if origGetStatue then return origGetStatue(self, suitID) end
            return ""
        end
        
        impl.Wearing7StarXSuit = function(self, character)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                local cfg = PhoenixtraSummon.ResolveEffectConfig()
                if cfg.CallStatue and cfg.CallStatue ~= "" then return true end
                return true
            end
            if origWear then return origWear(self, character) end
            return false
        end
        
        impl.OnClientClickInteractiveButton = function(self, character, component)
            if PhoenixtraSummon.BYPASS_7STAR_CHECK then
                PhoenixtraSummon.ForceWearNow()
                return true
            end
            if origClientClick then return origClientClick(self, character, component) end
            return true
        end
        
        impl.__phoenixtra_patched = true
        log("XSuitPlatform impl patched")
        return true
    end
    
    function PhoenixtraSummon.InstallPlatformHooks()
        if PhoenixtraSummon._platformHooked then
            PhoenixtraSummon.PatchLivePlatformActors()
            return true
        end
        local cls = PhoenixtraSummon.FindPlatformModule()
        if not cls then
            PhoenixtraSummon.PatchLivePlatformActors()
            return false
        end
        local impl = cls.__inner_impl or cls
        local ok = PhoenixtraSummon.PatchXSuitPlatformImpl(impl)
        if cls ~= impl then
            ok = PhoenixtraSummon.PatchXSuitPlatformImpl(cls) or ok
        end
        if ok then PhoenixtraSummon._platformHooked = true end
        PhoenixtraSummon.PatchLivePlatformActors()
        return PhoenixtraSummon._platformHooked
    end
    
    function PhoenixtraSummon.PatchBasicSkillsMenuTable(BP)
        -- Patch skill menu, intercept summon button click
        if not BP or type(BP.Action_InteractiveComponent) ~= "function" then return false end
        if BP.__phoenixtra_patched then return true end
        
        local orig = BP.Action_InteractiveComponent
        BP.Action_InteractiveComponent = function(self, Param, ExtraParam)
            local Component = Param and Param.Component
            PhoenixtraSummon._lastSummonParam = {Component = Component, Param = Param, ExtraParam = ExtraParam}
            
            if PhoenixtraSummon.BYPASS_7STAR_CHECK and Component and Component.GetOwner then
                local owner = Component:GetOwner()
                if slua.isValid(owner) and PhoenixtraSummon.IsXSuitPlatformActor(owner) then
                    log("Action_InteractiveComponent bypass summon")
                    PhoenixtraSummon.ForceWearNow()
                    if PhoenixtraSummon.PLAY_LOCAL_SEQUENCE then
                        local cfg = PhoenixtraSummon.ResolveEffectConfig()
                        if cfg.CallStatue and cfg.CallStatue ~= "" and hasMethod(owner, "TriggerCallShowSequence") then
                            pcall(function() owner:TriggerCallShowSequence(cfg.CallStatue) end)
                        end
                    end
                    if self.HideNormalBtn then
                        pcall(function() self:HideNormalBtn("Type_InteractiveComponent", Param) end)
                    end
                    return
                end
            end
            
            return orig(self, Param, ExtraParam)
        end
        
        BP.__phoenixtra_patched = true
        log("BasicSkillsMenu Action_InteractiveComponent hooked")
        return true
    end
    
    function PhoenixtraSummon.InstallBasicSkillsMenuHook()
        safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions")
        local BP = safeRequire("GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Config")
        if not BP then return false end
        if not PhoenixtraSummon.PatchBasicSkillsMenuTable(BP) then return false end
        PhoenixtraSummon._menuHooked = true
        return true
    end
    
    function PhoenixtraSummon.InstallMatchEvents()
        -- Listen to match state, refresh platform patch on ReadyState
        if PhoenixtraSummon._eventsHooked then return end
        if type(EventSystem) ~= "table" or not EventSystem.AddCommonEvent then return end
        pcall(function()
            EventSystem:AddCommonEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, function(_, _, state)
                if state == "ReadyState" then
                    PhoenixtraSummon.PatchLivePlatformActors()
                    PhoenixtraSummon.ForceWearNow()
                    log("ReadyState refresh platform")
                end
            end)
            PhoenixtraSummon._eventsHooked = true
            log("match events hooked")
        end)
    end
    
    function PhoenixtraSummon.InstallRequireHook()
        -- Hook require, auto-install corresponding patch when module loads
        if PhoenixtraSummon._origRequire then return end
        PhoenixtraSummon._origRequire = require
        _G.require = function(modname)
            local result = PhoenixtraSummon._origRequire(modname)
            if modname == "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools" then
                PhoenixtraSummon.InstallTipsHooks()
            elseif modname == "GameLua.Mod.BaseMod.Client.Skill.BasicSkillsMenuBP_Actions" then
                PhoenixtraSummon.InstallBasicSkillsMenuHook()
            elseif modname == PLATFORM_MODULE then
                PhoenixtraSummon.InstallPlatformHooks()
            end
            return result
        end
        log("require hook installed")
    end
    
    function PhoenixtraSummon.PreloadAssets()
        -- Pre-download mecha-related resources
        local cfg = PhoenixtraSummon.ResolveEffectConfig()
        local PufferConst = safeRequire("client.slua.logic.download.puffer_const")
        local PufferManager = safeRequire("client.slua.logic.download.puffer.puffer_manager")
        if not PufferConst or not PufferManager then return end
        local list = {PhoenixtraSummon.XSUIT_ID, PhoenixtraSummon.FALLBACK_TEMPLATE_ID, PhoenixtraSummon.CALL_ACTION_ID}
        if cfg.CallStatue and cfg.CallStatue ~= "" then
            table.insert(list, cfg.CallStatue)
        end
        pcall(function()
            PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, list)
        end)
    end
    
    function PhoenixtraSummon.Install()
        -- Main install function: Install all patches in order
        PhoenixtraSummon.UpdateFromConfig()           -- First read mecha ID from config
        PhoenixtraSummon.InstallTipsHooks()
        PhoenixtraSummon.InstallRequireHook()
        PhoenixtraSummon.InstallDataTableHooks()
        PhoenixtraSummon.ResolveEffectConfig()
        PhoenixtraSummon.RegisterLogicXSuitItem()
        PhoenixtraSummon.InstallPlatformHooks()
        PhoenixtraSummon.InstallBasicSkillsMenuHook()
        PhoenixtraSummon.InstallMatchEvents()
        PhoenixtraSummon.PreloadAssets()
        PhoenixtraSummon.ForceWearNow()
        log("Install done with XSUIT_ID=" .. tostring(PhoenixtraSummon.XSUIT_ID))
        return true
    end
    
    -- ========== Timer Install ==========
    if PhoenixtraSummon.AUTO_INSTALL then
        if _G.Mytimer_ticker then
            -- Delay 2 sec install (wait for config file read)
            _G.Mytimer_ticker.AddTimer(2, function()
                pcall(function() PhoenixtraSummon.Install() end)
            end)
            -- Continuously update mecha ID (when config file hot-updates)
            _G.Mytimer_ticker.AddTimerLoop(2, function()
                pcall(function()
                    if PhoenixtraSummon.UpdateFromConfig then
                        local newID = PhoenixtraSummon.UpdateFromConfig()
                        if newID then
                            -- Reinstall When ID Changes
                            if PhoenixtraSummon.XSUIT_ID ~= newID then
                                PhoenixtraSummon._resolvedEffect = nil
                                PhoenixtraSummon.Install()
                            end
                        end
                    end
                    if not PhoenixtraSummon._platformHooked then
                        PhoenixtraSummon.InstallPlatformHooks()
                    end
                    PhoenixtraSummon.ForceWearNow()
                end)
            end, -1, 1)
        else
            -- Install directly when no timer
            pcall(function() PhoenixtraSummon.Install() end)
        end
    end
    
    _G.PhoenixtraSummon = PhoenixtraSummon
end



-- ==================== Weapon Animation Module (DIY Inspect Animation) ====================
-- Auto-play weapon-specific animation based on WeaponCheckSkill config
-- Need to hold weapon supporting this feature in game (e.g. some upgradable firearms)

if not _G.WeaponAnimationModule then
    _G.WeaponAnimationModule = {}
    
    local WAM = _G.WeaponAnimationModule
    
    -- ========== Config ==========
WAM.LOOP = true           -- Whether to loop
WAM.TOTAL_SEC = 60        -- Total play duration (sec), effective when LOOP=true
WAM.AUTO_START = false    -- Whether to auto-start (default off)
WAM.DEBUG = false         -- Debug log
    
    -- ========== New: Config File Toggle Support ==========
    -- Read toggle state from config file (WEAPON_ANIM=1 On / 0 Off)
local function IsWeaponAnimEnabled()
    local configValue = nil
    if _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        configValue = _G.DazhiMH_Config.Get("WEAPON_ANIM", 0)  -- Default 0=Off
    end
    return configValue == 1
end
    
    -- Update toggle state
    WAM._enabled = IsWeaponAnimEnabled()
    
    -- External control functions
    function WAM.SetEnabled(enabled)
        WAM._enabled = enabled == true
        WAM.AUTO_START = WAM._enabled
        if not WAM._enabled then
            WAM.Stop()
        else
            WAM.Start()
        end
        -- Save to config file
        if _G.DazhiMH_Config and _G.DazhiMH_Config.Set then
            _G.DazhiMH_Config.Set("WEAPON_ANIM", WAM._enabled and 1 or 0)
        end
        print("[WeaponAnim] Toggle state: " .. tostring(WAM._enabled))
    end
    
    function WAM.IsEnabled()
        return WAM._enabled
    end
    
    -- ========== Original Code Continues ==========
    
    -- Internal variables
    WAM._running = false
    WAM._lastSeqActor = nil
    WAM._timer = nil
    WAM._currentChar = nil
    WAM._seqPath = nil
    WAM._actorPath = nil
    WAM._duration = 0
    WAM._origLoc = nil
    WAM._origRot = nil
    
    -- Default sequence Actor path (alternative)
    local DEFAULT_ACTOR = "/Game/Mod/EvoBase/BluePrints/Actor/BP_CharacterLevelSequenceActor.BP_CharacterLevelSequenceActor_C"
    
    -- Log function
    local function log(msg)
        if WAM.DEBUG then
            print("[WeaponAnim] " .. tostring(msg))
        end
    end
    
    -- Get current character
    function WAM.GetCharacter()
        local ok, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GameplayData then return nil end
        return GameplayData.GetPlayerCharacter()
    end
    
    -- Check if character is standing and available
    function WAM.IsCharacterReady(char)
        if not char or not slua.isValid(char) then return false end
        local ok, EP = pcall(import, "EPawnState")
        if not ok then return false end
        
        local isStanding = (char.CurrentStates == (1 << EP.Stand))
        if isStanding and char.IsHandleInFold and char:IsHandleInFold() then
            isStanding = false
        end
        
        local inVehicle = char:HasState(EP.InVehicle) or char:HasState(EP.DriveVehicle)
        local isDead = char:HasState(EP.Save) or char:HasState(EP.Pick)
        
        return isStanding and not inVehicle and not isDead
    end
    
    -- Get weapon Avatar component
    function WAM.GetWeaponAvatarComponent(char)
        if not char or not slua.isValid(char) then return nil end
        local weapon = char.GetCurrentWeapon and char:GetCurrentWeapon()
        if slua.isValid(weapon) and slua.isValid(weapon.WeaponAvatarComponent) then
            return weapon.WeaponAvatarComponent
        end
        return nil
    end
    
    -- Soft object to path
    local function softToString(softObj)
        local result = nil
        pcall(function()
            if not softObj then return end
            if softObj.ToSoftObjectPath then
                local sp = softObj:ToSoftObjectPath()
                if sp and sp.ToString then result = sp:ToString() end
                if (not result) and sp and sp.GetAssetPathString then
                    result = sp:GetAssetPathString()
                end
            end
            if (not result) and softObj.ToString then
                result = softObj:ToString()
            end
        end)
        return result
    end
    
    -- Parse weapon inspect animation config
    function WAM.ResolveAnimationConfig(char)
        local seqPath, actorPath, duration = nil, nil, 0
        
        pcall(function()
            local wac = WAM.GetWeaponAvatarComponent(char)
            if not wac then return end
            
            local ES = import("EWeaponAttachmentSocketType")
            local ET = import("ECharSpecialLevelSequenceType")
            local handle = wac:GetEquippedHandle(ES.MasterGun)
            
            if handle and slua.isValid(handle) and handle.WeaponSpecialLevelSequenceList then
                for _, seq in pairs(handle.WeaponSpecialLevelSequenceList) do
                    if seq.LevelSequenceType == ET.ECharSpecLvSeq_WeaponCheck and seq.LevelSequenceConfig then
                        local cfg = seq.LevelSequenceConfig
                        seqPath = softToString(cfg.LevelSequence)
                        actorPath = softToString(cfg.SequenceActorTemplate)
                        duration = cfg.LevelSequenceDuration or 0
                        break
                    end
                end
            end
            
            if not actorPath or actorPath == "" then
                local AU = import("AvatarUtils")
                local ES2 = import("EWeaponAttachmentSocketType")
                local skinID = wac:GetEquippedItemDefineID(ES2.MasterGun).TypeSpecificID
                if skinID <= 0 then
                    local weapon = char:GetCurrentWeapon()
                    if weapon then
                        skinID = weapon:GetItemDefineID().TypeSpecificID
                    end
                end
                local base = AU.GetWeaponAvatarParentID(AU.GetBPIDByResID(skinID), false)
                local data = CDataTable.GetTableData("WeaponCheckSkill", base)
                if data and data.SequenceActorPath and data.SequenceActorPath ~= "" then
                    actorPath = data.SequenceActorPath
                end
            end
        end)
        
        if not actorPath or actorPath == "" then
            actorPath = DEFAULT_ACTOR
        end
        
        return seqPath, actorPath, duration
    end
    
    -- Play inspect animation once
    function WAM.PlayOnce(char)
        if not WAM._seqPath or WAM._seqPath == "" then
            log("No sequence path available")
            return false
        end
        
        local ok = false
        pcall(function()
            local UKismetMathLibrary = import("KismetMathLibrary")
            local transform = UKismetMathLibrary.MakeTransform(
                WAM._origLoc or char:K2_GetActorLocation(),
                WAM._origRot or char:K2_GetActorRotation(),
                FVector(1, 1, 1)
            )
            
            local seqActor = Game:PlayLevelSequence(
                char, WAM._seqPath, transform, 
                WAM._actorPath or DEFAULT_ACTOR, 
                false, nil, char
            )
            
            if slua.isValid(seqActor) then
                if seqActor.SetCharacterAndPlay then
                    seqActor:SetCharacterAndPlay(char)
                end
                char.CurrentLevelSequence = seqActor
                WAM._lastSeqActor = seqActor
                ok = true
                log("Sequence played successfully")
            end
        end)
        
        return ok
    end
    
    -- Check if sequence is alive
    function WAM.IsSequenceAlive()
        return WAM._lastSeqActor and slua.isValid(WAM._lastSeqActor)
    end
    
    -- Stop animation
    function WAM.Stop()
        if WAM._timer and WAM._currentChar and slua.isValid(WAM._currentChar) then
            pcall(function() WAM._currentChar:RemoveGameTimer(WAM._timer) end)
        end
        WAM._running = false
        WAM._timer = nil
        WAM._lastSeqActor = nil
        log("Animation stopped")
    end
    
    -- Startup animation
    function WAM.Start()
        -- ========== Toggle Check ==========
        if not WAM._enabled then
            log("Disabled by config")
            return false
        end
        -- =============================
        
        if WAM._running then
            log("Already running")
            return false
        end
        
        local char = WAM.GetCharacter()
        if not char or not slua.isValid(char) then
            log("No valid character")
            return false
        end
        
        if not WAM.IsCharacterReady(char) then
            log("Character not ready (not standing, in vehicle, or dead)")
            return false
        end
        
        WAM._seqPath, WAM._actorPath, WAM._duration = WAM.ResolveAnimationConfig(char)
        
        if not WAM._seqPath or WAM._seqPath == "" then
            log("No weapon check animation for current weapon")
            return false
        end
        
        if WAM._duration <= 0 then
            WAM._duration = 9
        end
        
        WAM._running = true
        WAM._currentChar = char
        WAM._origLoc = char:K2_GetActorLocation()
        WAM._origRot = char:K2_GetActorRotation()
        
        local firstSuccess = WAM.PlayOnce(char)
        if not firstSuccess then
            WAM._running = false
            log("Failed to play initial sequence")
            return false
        end
        
        local elapsed = 0
        local sinceReplay = 0
        local started = false
        
        pcall(function()
            WAM._timer = char:AddGameTimer(0.2, true, function()
                elapsed = elapsed + 0.2
                sinceReplay = sinceReplay + 0.2
                
                local cur = WAM.GetCharacter()
                if not cur or not slua.isValid(cur) then
                    WAM.Stop()
                    return
                end
                
                if not WAM.IsCharacterReady(cur) then
                    log("Character state changed, stopping")
                    WAM.Stop()
                    return
                end
                
                if WAM.IsSequenceAlive() then
                    started = true
                end
                
                if WAM.LOOP then
                    if (not WAM.IsSequenceAlive()) or sinceReplay >= (WAM._duration - 0.3) then
                        sinceReplay = 0
                        -- Check toggle again (prevent being turned off at runtime)
                        if WAM._enabled then
                            WAM.PlayOnce(cur)
                        else
                            WAM.Stop()
                        end
                    end
                    
                    if elapsed >= WAM.TOTAL_SEC then
                        log("Total time elapsed, stopping")
                        WAM.Stop()
                    end
                else
                    if (started and not WAM.IsSequenceAlive()) or elapsed >= (WAM._duration + 1) then
                        log("Sequence completed, stopping")
                        WAM.Stop()
                    end
                end
            end)
        end)
        
        log("Animation started, duration=" .. tostring(WAM._duration) .. "s, loop=" .. tostring(WAM.LOOP))
        return true
    end
    
    -- Restart (for after weapon change)
    function WAM.Restart()
        WAM.Stop()
        return WAM.Start()
    end
    
    -- Bind to weapon switch event
    function WAM.BindToWeaponSwitch()
        if not WAM._originalOnWeaponChanged and _G.WeaponEvents and _G.WeaponEvents.onWeaponChanged then
            WAM._originalOnWeaponChanged = _G.WeaponEvents.onWeaponChanged
            _G.WeaponEvents.onWeaponChanged = function(weaponId)
                if WAM._originalOnWeaponChanged then
                    WAM._originalOnWeaponChanged(weaponId)
                end
                if WAM._enabled then
                    pcall(function() WAM.Restart() end)
                end
            end
            log("Bound to weapon switch event")
        end
    end
    
    -- Auto-start loop
    function WAM.AutoStartLoop()
        if not WAM._enabled then return end
        
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimerLoop(3, function()
                pcall(function()
                    if not WAM._running and WAM._enabled then
                        local char = WAM.GetCharacter()
                        if char and slua.isValid(char) and WAM.IsCharacterReady(char) then
                            local seqPath, _, _ = WAM.ResolveAnimationConfig(char)
                            if seqPath and seqPath ~= "" then
                                WAM.Start()
                            end
                        end
                    end
                end)
            end, -1, 1)
        end
        
        pcall(function() WAM.Start() end)
    end
    
    -- Export global functions
    _G.StartWeaponAnimation = WAM.Start
    _G.StopWeaponAnimation = WAM.Stop
    _G.RestartWeaponAnimation = WAM.Restart
    _G.SetWeaponAnimation = WAM.SetEnabled  -- New: Toggle control
    
    -- Initialize
    WAM.BindToWeaponSwitch()
    WAM.AutoStartLoop()
    
    log("Weapon Animation Module loaded, enabled=" .. tostring(WAM._enabled))
end








-- ==================== Popup Chain (No Delay) ====================

-- Execute directly, no delay
pcall(function()
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    
    local title = "FORMULA Announcement"
    local content = [[
Important Notice:
WELCOME TO FORMULA VIP PLAY SAFE AVOID REPORTS
TELEGRAM ID @saailformula
DEVELOPER SAAIL AHMED
]]
    
    CommonMsgBoxMgr.Show(4, title, content, nil)
end)

pcall(function()
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    
    local title = "FORMULA HAX"
    local content = [[
Important Notice:
GO TO GAME SETTING YOU FIND ALL HAX FEAUTURES
SKINS Suit
SKINS Weapon
UNlimited uc 
spins
pet unlock 
many more
]]
    
    CommonMsgBoxMgr.Show(4, title, content, nil)
end)


-- Check if timer module is available
-- ★★★ On Startup Read Config File Immediately, Let Last Saved Toggles Take Effect Immediately ★★★
pcall(ReadConfigFile)
if _G.loadKillCountFromFile then pcall(_G.loadKillCountFromFile) end

-- ★★★ On Startup Clean Historical Contamination in WeaponSkinID ★★★
do
    local function SanitizeWeaponSkinID(tag)
        if not _G.WeaponSkinID or not _G.isSkinForWeapon then return 0 end
        local cleaned = 0
        for baseWid, skinId in pairs(_G.WeaponSkinID) do
            if baseWid and skinId and baseWid > 0 and skinId > 0 then
                if not _G.isSkinForWeapon(skinId, baseWid) then
                    print(string.format("[WeaponSkinSanitize%s] Clean contamination: base=%d → skin=%d(Belongs to another weapon)",
                        tag or "", baseWid, skinId))
                    _G.WeaponSkinID[baseWid] = nil
                    cleaned = cleaned + 1
                end
            end
        end
        return cleaned
    end

    -- First time: Run immediately
    local n0 = SanitizeWeaponSkinID(" · Startup")
    if n0 > 0 then
        print("[WeaponSkinSanitize] Startup cleaned total " .. n0 .. " contaminations")
    end

    -- Afterwards fallback run every 10 sec (prevent config file being mis-edited then read back in)
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(10, function()
            pcall(SanitizeWeaponSkinID, " - Timer")
        end, -1, 1)
    end
end

-- Star Power overhaul: Read file only on state switch + handler sharing + pet frequency reduction
if _G.Mytimer_ticker then
    local _pstate = { game = nil, lobby = nil }
    _G.Mytimer_ticker.AddTimerLoop(1, function()
        local inGame  = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
        local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
        local changed = (_pstate.game ~= inGame) or (_pstate.lobby ~= inLobby)
        _pstate.game, _pstate.lobby = inGame, inLobby

        local now = os.clock()

        -- 1. Config file: Only read on state switch / 10-sec fallback (previously io.open whole file every second)
        if changed or now - _G.__perf.cfgReadAt >= 10 then
            _G.__perf.cfgReadAt = now
            pcall(ReadConfigFile)
        end

        -- 2. Kill stats file: 30-sec fallback
        if changed or now - _G.__perf.killReadAt >= 30 then
            _G.__perf.killReadAt = now
            pcall(_G.loadKillCountFromFile)
        end

        -- 3. In-match handler: killcounter every second, others every 1.5 sec
        if inGame then
            pcall(_G.GameAvatarHandlerkillcounter)
            if now - _G.__perf.playerRefreshStamp >= 1.5 then
                _G.__perf.playerRefreshStamp = now
                pcall(_G.GameAvatarHandlerplayers)
                pcall(_G.GameVehicleAvatarHandler)
                pcall(_G.GameCameraView)
            end
        end
    end, -1, 1)

    -- Pet alone 3 sec (original GetActorsInSphere every sec was very power-hungry)
_G.Mytimer_ticker.AddTimerLoop(3, function()
    pcall(function()
        -- Star Lobby auto-sync pet from config
        if GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() then
            if _G.Wumingking and _G.Wumingking.GetPet then
                _G.Wumingking.Load() -- Re-read file
                local savedPetId = _G.Wumingking.GetPet()
                if savedPetId and savedPetId > 0 then
                    -- Reverse-lookup index, prevent HandlePetLogic overwrite
                    for i, id in ipairs(_G.PetSkinMap or {}) do
                        if id == savedPetId then
                            _G.PetSkinMapIndex = i
                            break
                        end
                    end
                    _G.PetSkin = savedPetId
                end
            end
        end
        -- Execute refresh logic
        _G.HandlePetLogic()
    end)
end, -1, 3)
end



_G.OurkillCountSystem = MyKillCountSubSystem.__inner_impl

-- ============================================================
-- ★★★ wumingking.h Unified Management ★★★
-- Save: Headwear / Eyewear / Mask / Clothes / Pants / Shoes / Gloves / Backpack / Firearm Skin
-- Lobby real-time write to disk -> Read and refresh on entering match
-- ============================================================

-- ★★★ Define isSuitItem Early, Ensure WardrobeSync / SetSlotSilent Can Judge on First Call ★★★
if not _G.isSuitItem then
    function _G.isSuitItem(resId)
        if not resId or resId <= 0 then return false end
        local cfg = nil
        pcall(function()
            if CDataTable and CDataTable.GetTableData then
                cfg = CDataTable.GetTableData("Item", resId)
            end
        end)
        if not cfg then return false end
        local tab = tonumber(cfg.WardrobeTab) or 0
        if tab == 10 then return true end
        if cfg.IsSuit == true then return true end
        if cfg.IsWholeBody == true then return true end
        return false
    end
end

_G.Wumingking = _G.Wumingking or {}
do
    local PATH
    do
        local _wp = {"/storage/emulated/0/Android/obb/com.tencent.ig/wumingking.h", "/storage/emulated/0/Android/obb/com.pubg.krmobile/wumingking.h", "/storage/emulated/0/Android/obb/com.vng.pubgmobile/wumingking.h", "/storage/emulated/0/Android/obb/com.rekoo.pubgm/wumingking.h", "/storage/emulated/0/Android/obb/com.pubg.imobile/wumingking.h"}

        -- Star Priority: Locate by current package name (fixes KR / VN / TW / JP-KR not reading config)
        PATH = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath() or nil

        -- Star Fallback: Take first existing in order
        if not PATH then
            for _i = 1, 5 do
                local _f = io.open(_wp[_i], "r")
                if _f then _f:close() PATH = _wp[_i] break end
            end
        end
        PATH = PATH or _wp[1]
        pcall(function() print("[Wumingking] Using path: " .. PATH) end)
    end
    local HEADER = "# Lobby selection auto-save (do not edit manually, maintained by game)\n"

    -- Slot mapping (Game SlotID -> Global variable name)
    -- 3=Headwear  4=Mask  12=Eyewear  5=Clothes  6=Pants  7=Shoes  16=Gloves
    -- Slot -> Global variable name (for apply_to_globals)
local SLOT_GLOBAL = {
    [2]  = "HairSkin",       -- Star New (Hair)
    [3]  = "HatSkin",        -- Headwear
    [4]  = "FaceSkin",       -- Mask / Face Accessory
    [12] = "MaskSkin",       -- Eyewear
    [5]  = "SuitSkin",       -- Clothes
    [6]  = "PantSkin",       -- Pants
    [7]  = "ShoeSkin",       -- Shoes
    [16] = "GlovesSkin",     -- Gloves
    [11] = "ParachuteSkin",  -- Star New (Parachute)
    [15] = "GliderSkin",     -- Star New (Glider)
}
local BACKPACK_SLOT = 8   -- Backpack
local HELMET_SLOT   = 9   -- Helmet
local ARMOR_SLOT    = 10  -- Star Bulletproof vest

-- Star Star Star New: Slot -> KEY Name (For wumingking.h KEY=VALUE Format) Star Star Star
local SLOT_TO_KEY = {
    [2]  = "HAIR",       -- Star New (Slot 2 = Hair)
    [3]  = "HAT",
    [4]  = "FACE",
    [12] = "MASK",
    [5]  = "SHIRT",
    [6]  = "PANT",
    [7]  = "SHOE",
    [16] = "GLOVES",
    [11] = "PARACHUTE",  -- Star New (Slot 11 = Parachute)
    [15] = "GLIDER",     -- Star New (Slot 15 = Glider)
}
local KEY_TO_SLOT = {}
for slot, key in pairs(SLOT_TO_KEY) do KEY_TO_SLOT[key] = slot end

-- Star Multi-value slots: Backpack / Helmet / Armor expand to 1~6
local MULTI_SLOT_PREFIX = {
    [8]  = "BACKPACK",
    [9]  = "HELMET",
    [10] = "ARMOR",
}

-- Star All slots needing "capture / apply" (including backpack, helmet, bulletproof vest)
local CAPTURE_SLOTS = {
    -- [2]=true,   -- Hair: Only apply from config, do not auto-capture
    [3]=true,
    [4]=true,   -- Star Mask: Change back to lobby tick auto-save (same as outfit / clothes)
    [12]=true, [5]=true, [6]=true, [7]=true,
[BACKPACK_SLOT]=true, [HELMET_SLOT]=true, [ARMOR_SLOT]=true,
    [11]=true,  -- Parachute
    -- [15]=true, -- Glider is not captured in lobby
}
-- Star Vehicle key table (used to identify simple lines in wumingking.h)
local VEHICLE_KEYS = {
    "DACIA", "COUPERB", "BUGGY", "UAZ", "MOTO", "SIDECARMOTO",
    "BLOOMSC", "RONY", "RZR", "BIGFOOT", "HORSE", "MINIBUS",
    "BOAT", "ROADSTER", "MIRADO", "MIRADOC"
}
local VEHICLE_KEY_SET = {}
for _, k in ipairs(VEHICLE_KEYS) do VEHICLE_KEY_SET[k] = true end

local VEHICLE_KEY_TO_ID = {
    DACIA = 1903, COUPERB = 1961, BUGGY = 1907, UAZ = 1908,
    MOTO = 1901, SIDECARMOTO = 1902, BLOOMSC = 1917, RONY = 1916,
    RZR = 1966, BIGFOOT = 1953, HORSE = 1987, MINIBUS = 1904,
    BOAT = 19110, ROADSTER = 19116, MIRADO = 1914, MIRADOC = 1915,
}

-- Star Feature toggles / FOV / Pet that need to be saved together to wumingking.h
local EXTRA_KEYS = {
    "FOV_ENABLE", "FOV_VALUE",
    "DEADBOX_SKIN", "WEAPON_ANIM", "WATERMARK",
    "TRAIL_ENABLE", "TRAIL_TYPE", "WEATHER",
    "PETSKIN", "EXPLOSION_WEAPON",
    "GLOVES_HIDE_ON_GUN",
    "SPECIAL_BG_CAR", -- Star New: Exclusive lobby background (0 Default 1 Ferrari 2 Bugatti)
    "GRENADE_FAST_REFRESH",   -- Star New
    "WEAPON_FAST_REFRESH",    -- Star New
    "WEAPON_BACK_REFRESH"     -- Star New
}
local EXTRA_KEY_SET = {}
for _, k in ipairs(EXTRA_KEYS) do EXTRA_KEY_SET[k] = true end

-- Internal data
local D = {
    G = {},   -- [slotId]     = itemId    → W=
    M = { BACKPACK = {}, HELMET = {}, ARMOR = {} }, -- Independent equipment skin IDs by level
    W = {},   -- [baseWid]    = skinId    → G=
    V = {},   -- [vehicleKey] = sliderIdx -> KEY=N (placed after P)
    P = 0,    -- Pet ID                 -> P=
    S = 0,    -- Star New: Outfit (SUIT) independent storage
    _snap = nil,
    _busy = false,
    _suppressUntil = 0,
}

    local function log(s)
        pcall(function() print("[Wumingking] " .. tostring(s)) end)
    end

    local function fileExists(p)
        local f = io.open(p, "r"); if f then f:close(); return true end
        return false
    end

    -- File does not exist -> Create immediately
    local function ensureFile()
    if fileExists(PATH) then return true end
    local f = io.open(PATH, "w")
    if not f then
        log("Cannot create " .. PATH)
        return false
    end
    -- Generate KEY=VALUE default empty template
    local lines = { HEADER }
lines[#lines+1] = "# ========== Character Equipment =========="
lines[#lines+1] = "HAIR=0"
lines[#lines+1] = "HAT=0"
lines[#lines+1] = "FACE=0"
lines[#lines+1] = "MASK=0"
lines[#lines+1] = "SHIRT=0"
lines[#lines+1] = "SUIT=0"
lines[#lines+1] = "PANT=0"
lines[#lines+1] = "SHOE=0"
lines[#lines+1] = "GLOVES=0"
lines[#lines+1] = "PARACHUTE=1401469"
lines[#lines+1] = "GLIDER=4151133"
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== Backpack =========="
    for i = 1, 6 do lines[#lines+1] = "BACKPACK" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== Helmet =========="
    for i = 1, 6 do lines[#lines+1] = "HELMET" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== Armor =========="
    for i = 1, 6 do lines[#lines+1] = "ARMOR" .. i .. "=0" end
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== Pet =========="
    lines[#lines+1] = "PETSKIN=0"
    lines[#lines+1] = ""
    lines[#lines+1] = "# ========== Vehicle =========="
    for _, k in ipairs(VEHICLE_KEYS) do lines[#lines+1] = k .. "=1" end
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
    log("Created " .. PATH)
    return true
end



-- ★★★ Load: All Use KEY=VALUE Format (Same as wumingking.h)★★★
local function load()
    D.G, D.W, D.V, D.P = {}, {}, {}, 0
    D.M = { BACKPACK = {}, HELMET = {}, ARMOR = {} }

    local f = io.open(PATH, "r")
    if not f then return end

    -- Pre-build weapon name set
    local weaponNameSet = {}
    if _G.WeaponNameToID then
        for name in pairs(_G.WeaponNameToID) do weaponNameSet[name] = true end
    end

    for line in f:lines() do
        if not line:match("^%s*#") then
            local k, v = line:match("^%s*([%w_]+)%s*=%s*(%d+)%s*$")
            if k and v then
                local num = tonumber(v)

                -- Single-value slots: HAT / FACE / MASK / SHIRT / PANT / SHOE / GLOVES
                local slot = KEY_TO_SLOT[k]
                if slot then D.G[slot] = num end

                -- Multi-value slots: preserve each equipment level independently.
                local bpLevel = k:match("^BACKPACK([1-6])$")
                if bpLevel then D.M.BACKPACK[tonumber(bpLevel)] = num end
                local helmetLevel = k:match("^HELMET([1-6])$")
                if helmetLevel then D.M.HELMET[tonumber(helmetLevel)] = num end
                local armorLevel = k:match("^ARMOR([1-6])$")
                if armorLevel then D.M.ARMOR[tonumber(armorLevel)] = num end

                -- Weapon skin
                if weaponNameSet[k] and num > 0 then
                    local wid = _G.WeaponNameToID[k]
                    if wid then D.W[wid] = num end
                end

                -- Pet (compatible with old format: <1000 treated as index)
                if k == "PETSKIN" then
                if num > 0 and num < 1000 then
                local petMap = _G.PetSkinMap
                D.P = (petMap and petMap[num]) or num
                else
                D.P = num
            end
        end

                -- Star SUIT slot: Outfit only (independent from SHIRT)
                if k == "SUIT" then D.S = num end

                -- Vehicle
                if VEHICLE_KEY_SET[k] then D.V[k] = num end

                -- Feature toggles
                if EXTRA_KEY_SET[k] then
                    _G.DazhiMH_Config = _G.DazhiMH_Config or {}
                    _G.DazhiMH_Config._cache = _G.DazhiMH_Config._cache or {}
                    _G.DazhiMH_Config._cache[k] = num
                end
            end
        end
    end
    f:close()

-- ★★★ Force Mutual Exclusion (Compatible with Old Save Conflicts)★★★
-- Rule: SUIT>0 -> Clear SHIRT/PANT/SHOE
--       If any of SHIRT/PANT/SHOE >0 -> only clear SUIT
if D.S and D.S > 0 then
    D.G[5] = 0
    D.G[6] = 0
    D.G[7] = 0
elseif (D.G[5] and D.G[5] > 0) or (D.G[6] and D.G[6] > 0) or (D.G[7] and D.G[7] > 0) then
    D.S = 0
end

    -- Star Star Star Parachute / Glider Default 100% Fallback Star Star Star
    local _defaultNeedSave = false
    if not D.G[11] or D.G[11] <= 0 then
        D.G[11] = 1401469
        _defaultNeedSave = true
    end
    if not D.G[15] or D.G[15] <= 0 then
        D.G[15] = 4151133
        _defaultNeedSave = true
    end

    -- Star Write default value back to file, so wumingking.h shows 4151133
    if _defaultNeedSave then
        local _lines = {}
        local _rf = io.open(PATH, "r")
        if _rf then
            for l in _rf:lines() do _lines[#_lines+1] = l end
            _rf:close()
        end
        local function _setKV(key, val)
            local replaced = false
            for i, l in ipairs(_lines) do
                local k = l:match("^(%w+_?%w*)%s*=")
                if k == key then
                    _lines[i] = key .. "=" .. tostring(val)
                    replaced = true
                    break
                end
            end
            if not replaced then _lines[#_lines+1] = key .. "=" .. tostring(val) end
        end
        _setKV("PARACHUTE", D.G[11])
        _setKV("GLIDER", D.G[15])
        local _wf = io.open(PATH, "w")
        if _wf then
            for _, l in ipairs(_lines) do _wf:write(l, "\n") end
            _wf:close()
            log("[load] Wrote default parachute/glider back to file")
        end
    end

    D._snap = nil
end


-- ★★★ Serialization: Fully Mimic wumingking.h Partition Comment Format ★★★
local function serialize()
    local function cache(k, def)
        local c = (_G.DazhiMH_Config and _G.DazhiMH_Config._cache) or {}
        local v = c[k]
        if v == nil then v = def or 0 end
        return v
    end

    local lines = {
        "# ==================== Config File ====================",
        "# Can be edited manually, in-game changes auto write back",
        "# Format: Key=Value",
        "",
    }


    -- ========== Wide-Angle ==========
    lines[#lines+1] = "# ========== Wide-Angle =========="
    lines[#lines+1] = "FOV_ENABLE=" .. tostring(cache("FOV_ENABLE", 0))
    lines[#lines+1] = "FOV_VALUE="  .. tostring(cache("FOV_VALUE", 90))
    lines[#lines+1] = ""

    -- ========== Feature Toggles ==========
    lines[#lines+1] = "# ========== Feature Toggles =========="
    lines[#lines+1] = "DEADBOX_SKIN=" .. tostring(cache("DEADBOX_SKIN", 0))
lines[#lines+1] = "WEAPON_ANIM="  .. tostring(cache("WEAPON_ANIM", 0))
lines[#lines+1] = "WATERMARK="    .. tostring(cache("WATERMARK", 0))
lines[#lines+1] = "GLOVES_HIDE_ON_GUN=" .. tostring(cache("GLOVES_HIDE_ON_GUN", 0))
lines[#lines+1] = "SPECIAL_BG_CAR=" .. tostring(cache("SPECIAL_BG_CAR", 0))
lines[#lines+1] = "GRENADE_FAST_REFRESH=" .. tostring(cache("GRENADE_FAST_REFRESH", 0))
lines[#lines+1] = "WEAPON_FAST_REFRESH="  .. tostring(cache("WEAPON_FAST_REFRESH", 0))
lines[#lines+1] = "WEAPON_BACK_REFRESH="  .. tostring(cache("WEAPON_BACK_REFRESH", 0))
    lines[#lines+1] = ""

    -- ========== Trail ==========
    lines[#lines+1] = "# ========== Trail =========="
    lines[#lines+1] = "TRAIL_ENABLE=" .. tostring(cache("TRAIL_ENABLE", 0))
    lines[#lines+1] = "TRAIL_TYPE="   .. tostring(cache("TRAIL_TYPE", 4531002))
    lines[#lines+1] = ""

    -- ========== Weather ==========
    lines[#lines+1] = "# ========== Weather 0=None 1=Rain 2=Snow 3=Blizzard 4=Thunderstorm =========="
    lines[#lines+1] = "WEATHER=" .. tostring(cache("WEATHER", 0))
    lines[#lines+1] = ""

    -- ========== Pet Index ==========
    lines[#lines+1] = "# ========== Pet Index =========="
    lines[#lines+1] = "PETSKIN=" .. tostring(D.P or 0)
    lines[#lines+1] = ""

    -- ========== Character Parts ==========
    lines[#lines+1] = "# ========== Character Parts =========="
do
    local order = { "SHIRT", "HAIR", "HAT", "FACE", "MASK", "GLOVES", "PANT", "SHOE", "PARACHUTE", "GLIDER" }
    for _, key in ipairs(order) do
        local slot = KEY_TO_SLOT[key]
        local v = (slot and D.G[slot]) or 0
        lines[#lines+1] = key .. "=" .. tostring(v)
        -- Star Write SUIT= right after SHIRT=
        if key == "SHIRT" then
            lines[#lines+1] = "SUIT=" .. tostring(D.S or 0)
        end
    end
end
    do
        for i = 1, 6 do
            local v = (D.M and D.M.BACKPACK and D.M.BACKPACK[i])
            if v == nil then v = D.G[8] or 0 end
            lines[#lines+1] = "BACKPACK" .. i .. "=" .. tostring(v)
        end
        for i = 1, 6 do
            local v = (D.M and D.M.HELMET and D.M.HELMET[i])
            if v == nil then v = D.G[9] or 0 end
            lines[#lines+1] = "HELMET" .. i .. "=" .. tostring(v)
        end
        for i = 1, 6 do
            local v = (D.M and D.M.ARMOR and D.M.ARMOR[i])
            if v == nil then v = D.G[10] or 0 end
            lines[#lines+1] = "ARMOR" .. i .. "=" .. tostring(v)
        end
    end
    lines[#lines+1] = ""

    -- ========== Weapon Skin ==========
    lines[#lines+1] = "# ========== Weapon Skin (Write Skin ID) =========="
    do
        local WEAPON_ORDER = {
            -- Assault Rifle
            "AKM","M16A4","SCAR","M416","GROZA","AUG","QBZ","M762",
            "Mk47","G36C","HoneyPot","FAMAS","ASM","ACE32",
            -- Submachine Gun
            "UZI","UMP","VECTOR","THOMPSON","BIZON","MP5K","JS9","P90",
            -- Sniper Rifle / Marksman Rifle
            "K98","M24","AWM","SKS","VSS","Mini14","MK14","Win94",
            "M1Garand","SLR","QBU","Mosin","AMR","Mk12","DSR",
            -- Shotgun
            "S686","S1897","S12K","DBS","M1014","NS2000",
            -- Light Machine Gun
            "M249","DP28","MG3",
            -- Melee
            "PAN","DAGGER","Machete",
        }
        local emitted = {}
        for _, name in ipairs(WEAPON_ORDER) do
            local wid = _G.WeaponNameToID and _G.WeaponNameToID[name]
            local v = (wid and D.W[wid]) or 0
            lines[#lines+1] = name .. "=" .. tostring(v)
            emitted[name] = true
        end
        -- Fallback: If D.W has weapons outside list, also append at end
        local nameMap = {}
        if _G.WeaponNameToID then
            for name, id in pairs(_G.WeaponNameToID) do nameMap[id] = name end
        end
        local extra = {}
        for wid, sid in pairs(D.W) do
            if wid and sid and sid > 0 then
                local name = nameMap[wid]
                if name and not emitted[name] then
                    extra[#extra+1] = name .. "=" .. tostring(sid)
                end
            end
        end
        if #extra > 0 then
            table.sort(extra)
            for _, line in ipairs(extra) do lines[#lines+1] = line end
        end
    end
    lines[#lines+1] = ""

    -- ========== Vehicle Slider ==========
    lines[#lines+1] = "# ========== Vehicle Slider =========="
    for _, key in ipairs(VEHICLE_KEYS) do
        local idx = D.V[key] or 1
        lines[#lines+1] = key .. "=" .. tostring(idx)
    end

    -- ========== Keep Other Unknown Lines in Original File ==========
    local extras = {}
    local rf = io.open(PATH, "r")
    if rf then
        local weaponNameSet = {}
        if _G.WeaponNameToID then
            for name in pairs(_G.WeaponNameToID) do weaponNameSet[name] = true end
        end
        for line in rf:lines() do
            if not line:match("^%s*#") and line ~= "" then
                local k = line:match("^%s*(%w+_?%w*)%s*=")
if k
    and not KEY_TO_SLOT[k]
    and not VEHICLE_KEY_SET[k]
    and not weaponNameSet[k]
    and not EXTRA_KEY_SET[k]
    and k ~= "PETSKIN"
    and k ~= "SUIT" -- Star Star Star Core Fix: Exclude SUIT, Prevent Infinite Stacking
    and not k:match("^BACKPACK%d+$")
    and not k:match("^HELMET%d+$")
    and not k:match("^ARMOR%d+$")
then
    extras[#extras+1] = line
end
            end
        end
        rf:close()
    end
    if #extras > 0 then
        lines[#lines+1] = ""
        lines[#lines+1] = "# ========== Other =========="
        for _, line in ipairs(extras) do lines[#lines+1] = line end
    end

    return table.concat(lines, "\n") .. "\n"
end

    local function save(force)
    if D._busy then return end
    D._busy = true
    pcall(function()
        local content = serialize()
        if force or content ~= D._snap then
            local f = io.open(PATH, "w")
            if f then
                f:write(content)
                f:close()
                D._snap = content
            end
        end
    end)
    D._busy = false
end

    -- ========== External API ==========
    local API = _G.Wumingking
    API.Path = PATH

    -- slotId uses W= line (Character Part)
    function API.SetSlot(slotId, itemId)
slotId = tonumber(slotId); itemId = math.floor(tonumber(itemId) or 0)
if not slotId or slotId <= 0 or itemId < 0 then return end
-- Star Parachute / Glider forbid clearing to zero (100% fallback)
if slotId == 11 and itemId <= 0 then return end
if slotId == 15 and itemId <= 0 then return end

-- Star Star Star Slot 5: Outfit / Clothes Both Clear Pants + Shoes Star Star Star
if slotId == 5 then
    -- Star Star Star Defense: If This ID Is Already Current SUIT, Skip Check, Keep Outfit Star Star Star
    if D.S == itemId and itemId > 0 then
        return
    end

    -- ★★★ Temporary Debug Log: Print Every Time slot 5 Is Ticked ★★★
    if itemId > 0 then
        local _dbg = CDataTable.GetTableData("Item", itemId)
        print(string.format("[SetSlot5] id=%s subtype=%s IsSuit=%s IsWholeBody=%s",
            tostring(itemId),
            tostring(_dbg and _dbg.ItemSubType),
            tostring(_dbg and _dbg.IsSuit),
            tostring(_dbg and _dbg.IsWholeBody)))
    end

    local isSuit = (itemId > 0) and _G.isSuitItem and _G.isSuitItem(itemId)
    local changed = false

    if isSuit then
        -- Outfit mode: Clear all SHIRT/PANT/SHOE
        if D.S ~= itemId then D.S = itemId; changed = true end
        if D.G[5] ~= 0   then D.G[5] = 0;  changed = true end
        if D.G[6] ~= 0   then D.G[6] = 0;  changed = true end
        if D.G[7] ~= 0   then D.G[7] = 0;  changed = true end
        print("[Wumingking] Outfit mutual exclusion: SUIT=" .. tostring(itemId) ..
              " Cleared SHIRT/PANT/SHOE")
else
    -- Separate-piece clothes mode: Only clear outfit, keep PANT/SHOE
    if D.G[5] ~= itemId then D.G[5] = itemId; changed = true end
    if D.S ~= 0          then D.S = 0;        changed = true end
    print("[Wumingking] Separate-piece clothes: SHIRT=" .. tostring(itemId) ..
          " Cleared SUIT (PANT/SHOE kept)")
end
    if changed then save() end

    -- Star Only in "Outfit Mode" clear character slot 6/7 + send unequip request
    if isSuit then
        -- Immediately clear slot 6/7 in character SlotSyncData
        pcall(function()
            local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
            if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then
                    local comp = v.AvatarComponent2
                    if comp and slua.isValid(comp) then
                        local nad = comp.NetAvatarData
                        if nad and slua.isValid(nad) then
                            local ad = nad.SlotSyncData
                            if ad then
                                local dirty = false
                                for i = 0, ad:Num() - 1 do
                                    local e = ad:Get(i)
                                    if e and (e.SlotID == 6 or e.SlotID == 7) and e.ItemId ~= 0 then
                                        e.ItemId = 0
                                        ad:Set(i, e)
                                        dirty = true
                                    end
                                end
                                if dirty then
                                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                                    pcall(function() comp:InitDepotCommonPutOn() end)
                                end
                            end
                        end
                    end
                    break
                end
            end
        end)

        -- Actively send unequip request (warehouse UI layer)
        pcall(function()
            local WRH = require("client.network.Protocol.WardRobeHandler")
            local rolewear = DataMgr and DataMgr.rolewear
            if type(rolewear) ~= "table" or not WRH or not WRH.send_depot_put_down_req then return end
            local LSI = _G.LobbySkinInjector
            for _, insId in ipairs(rolewear) do
                local insNum = tonumber(insId)
                if insNum and insNum > 0 then
                    local realId = nil
                    if LSI and insNum >= LSI.BASE_ID then
                        realId = insNum - LSI.BASE_ID
                    end
                    if realId then
                        local cfg = CDataTable.GetTableData("Item", realId)
                        if cfg and (cfg.SlotID == 6 or cfg.SlotID == 7) then
                            pcall(WRH.send_depot_put_down_req, tostring(insNum))
                        end
                    end
                end
            end
        end)
    end
    return
end

-- Star Star Star Pants (6) / Shoes (7) Have Value -> Only Clear SUIT, Keep SHIRT Star Star Star
if (slotId == 6 or slotId == 7) and itemId > 0 then
    if D.S ~= 0 then
        D.S = 0
        save()
        print("[Wumingking] Wear pants/shoes -> Cleared SUIT (SHIRT kept)")
    end
end

-- Star User actively sets gloves -> Lock, prevent captureSlots writing back 0 to overwrite
if slotId == 16 then
    _G.__WM_UserSetGloves = true
    _G.__WM_UserSetGlovesAt = os.clock()
end

-- Star User actively sets mask / eyewear -> Lock, prevent captureSlots writing back game reset value to overwrite
if slotId == 4 or slotId == 12 then
    _G.__WM_UserSetFace = true
    _G.__WM_UserSetFaceAt = os.clock()
end

-- Generic backpack / helmet / armor writes intentionally apply to all six levels.
if slotId == 8 or slotId == 9 or slotId == 10 then
    local kind, globalPrefix
    if slotId == 8 then kind, globalPrefix = "BACKPACK", "Backpack"
    elseif slotId == 9 then kind, globalPrefix = "HELMET", "Helmet"
    else kind, globalPrefix = "ARMOR", "Armor" end

    D.M = D.M or { BACKPACK = {}, HELMET = {}, ARMOR = {} }
    D.M[kind] = D.M[kind] or {}
    local changed = (D.G[slotId] ~= itemId)
    D.G[slotId] = itemId
    for i = 1, 6 do
        if D.M[kind][i] ~= itemId then changed = true end
        D.M[kind][i] = itemId
        _G[globalPrefix .. tostring(i) .. "Skin"] = itemId
    end
    if changed then save() end
    return
end

-- ★★★ Fix: Headwear (3) and Eyewear (12) Mutual Exclusion Cleanup ★★★
-- Game stuffs some headwear models into both slot 3 and slot 12, here force separate:
--   · When setting headwear, if eyewear has the same ID -> clear eyewear
--   · When setting eyewear, if headwear has the same ID -> do not save duplicate (headwear takes priority)
if slotId == 3 and itemId > 0 then
    if D.G[12] == itemId then
        D.G[12] = 0
    end
elseif slotId == 12 and itemId > 0 then
    if D.G[3] == itemId then
        -- Headwear already occupies this ID, eyewear skips
        return
    end
end

-- Star Face accessory (4) and Eyewear (12) are independent slots, allow simultaneous save
local _needSave = false
if D.G[slotId] ~= itemId then
    D.G[slotId] = itemId
    _needSave = true
end
if _needSave then
    save()
end
end

-- Set one exact backpack / helmet / armor level without overwriting the other five levels.
function API.SetLevelSkin(slotId, level, itemId)
    slotId = tonumber(slotId)
    level = math.floor(tonumber(level) or 0)
    itemId = math.floor(tonumber(itemId) or 0)
    if itemId < 0 or level < 1 or level > 6 then return false end

    local kind, globalPrefix
    if slotId == 8 then
        kind, globalPrefix = "BACKPACK", "Backpack"
    elseif slotId == 9 then
        kind, globalPrefix = "HELMET", "Helmet"
    elseif slotId == 10 then
        kind, globalPrefix = "ARMOR", "Armor"
    else
        return false
    end

    D.M = D.M or { BACKPACK = {}, HELMET = {}, ARMOR = {} }
    D.M[kind] = D.M[kind] or {}
    D.M[kind][level] = itemId
    _G[globalPrefix .. tostring(level) .. "Skin"] = itemId

    local key = kind .. tostring(level)
    if _G.DazhiMH_Config then
        _G.DazhiMH_Config._cache = _G.DazhiMH_Config._cache or {}
        _G.DazhiMH_Config._cache[key] = itemId
    end
    if _G.lastConfig then _G.lastConfig[key] = itemId end

    save()
    return true
end

function API.GetLevelSkin(slotId, level)
    slotId = tonumber(slotId)
    level = math.floor(tonumber(level) or 0)
    if level < 1 or level > 6 then return 0 end
    local kind = (slotId == 8 and "BACKPACK") or (slotId == 9 and "HELMET") or (slotId == 10 and "ARMOR")
    if not kind then return 0 end
    return (D.M and D.M[kind] and D.M[kind][level]) or 0
end

-- Star New: Only clear outfit, never touch SHIRT/PANT/SHOE (for "tick pants/shoes" scenario)
function API.ClearSuitOnly()
    if D.S ~= 0 then
        D.S = 0
        save()
        print("[Wumingking] ClearSuitOnly: Cleared SUIT (SHIRT/PANT/SHOE kept)")
    end
end

-- Star New: Directly force-mark as outfit (called after native exclusion verification)
function API.SetSuitDirect(itemId)
    itemId = math.floor(tonumber(itemId) or 0)
    if itemId <= 0 then return end
    local changed = false
    if D.S ~= itemId then D.S = itemId; changed = true end
    if D.G[5] ~= 0 then D.G[5] = 0; changed = true end
    if D.G[6] ~= 0 then D.G[6] = 0; changed = true end
    if D.G[7] ~= 0 then D.G[7] = 0; changed = true end
    if changed then save() end
    print("[Wumingking] SetSuitDirect: SUIT=" .. tostring(itemId) .. " Cleared SHIRT/PANT/SHOE")
end

    -- baseWid uses G= line (Weapon)
    function API.SetWeapon(baseWid, skinId)
        baseWid = tonumber(baseWid); skinId = math.floor(tonumber(skinId) or 0)
        if not baseWid or baseWid <= 0 or skinId <= 0 then return end
        if D.W[baseWid] ~= skinId then
            D.W[baseWid] = skinId
            save()
        end
    end

-- Star Set vehicle slider index (called when clicking slider)
function API.SetVehicle(vehicleKey, sliderIndex)
    vehicleKey = tostring(vehicleKey or "")
    sliderIndex = math.floor(tonumber(sliderIndex) or 1)
    if sliderIndex < 1 then sliderIndex = 1 end
    if not VEHICLE_KEY_SET[vehicleKey] then return end

    if D.V[vehicleKey] ~= sliderIndex then
        D.V[vehicleKey] = sliderIndex
        save()   -- Star Write to disk in real time
    end

    -- Sync to global variables
    local vid = VEHICLE_KEY_TO_ID[vehicleKey]
    if vid then
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        _G.VehicleSkinIndex[vid] = sliderIndex
        _G.__VehicleUserSet[vid] = sliderIndex
    end

    -- Star Key: Setting inside function, slider movement immediately triggers lobby refresh
    if _G.LobbyVehicleRefresh then
        pcall(_G.LobbyVehicleRefresh)
    end
end

function API.SetSlotSilent(slotId, itemId, forceIsSuit)
    slotId = tonumber(slotId)
    itemId = math.floor(tonumber(itemId) or 0)
    if not slotId or slotId <= 0 or itemId < 0 then return end

    if slotId == 5 then
        -- Star Externally already judged outfit type -> Trust directly; only judge self if not passed
        local isSuit
        if forceIsSuit ~= nil then
            isSuit = forceIsSuit and true or false
        else
            isSuit = (itemId > 0) and _G.isSuitItem and _G.isSuitItem(itemId) or false
        end
        local changed = false
        if isSuit then
            if D.S ~= itemId then D.S = itemId; changed = true end
            if D.G[5] ~= 0 then D.G[5] = 0; changed = true end
            if D.G[6] ~= 0 then D.G[6] = 0; changed = true end
            if D.G[7] ~= 0 then D.G[7] = 0; changed = true end
        else
            if D.G[5] ~= itemId then D.G[5] = itemId; changed = true end
            if D.S ~= 0 then D.S = 0; changed = true end
        end
        if changed then
            D._busy = false
            D._snap = nil
            pcall(function() save(true) end)
            D._busy = false
            print("[SetSlotSilent] slot=5 item=" .. tostring(itemId) ..
                  " isSuit=" .. tostring(isSuit) .. " → Written to disk")
        end
else
    if slotId == 8 or slotId == 9 or slotId == 10 then
        local kind, globalPrefix
        if slotId == 8 then kind, globalPrefix = "BACKPACK", "Backpack"
        elseif slotId == 9 then kind, globalPrefix = "HELMET", "Helmet"
        else kind, globalPrefix = "ARMOR", "Armor" end
        D.M = D.M or { BACKPACK = {}, HELMET = {}, ARMOR = {} }
        D.M[kind] = D.M[kind] or {}
        D.G[slotId] = itemId
        for i = 1, 6 do
            D.M[kind][i] = itemId
            _G[globalPrefix .. tostring(i) .. "Skin"] = itemId
        end
        D._busy = false
        D._snap = nil
        pcall(function() save(true) end)
        D._busy = false
        return
    end
    local changed = false
    if D.G[slotId] ~= itemId then
        D.G[slotId] = itemId
        changed = true
    end
    if changed then
        D._busy = false
        D._snap = nil
        pcall(function() save(true) end)
        D._busy = false
        print("[SetSlotSilent] slot=" .. tostring(slotId) ..
              " item=" .. tostring(itemId) .. " → Written to disk")
    end
end
end

    function API.SetPet(petId)
        petId = math.floor(tonumber(petId) or 0)
        if petId < 0 then petId = 0 end
        if D.P ~= petId then
            D.P = petId
            save()
        end
    end

function API.GetSlot(slotId)
    slotId = tonumber(slotId) or 0
    if slotId == 5 then
        if D.S and D.S > 0 then return D.S end
        return D.G[5] or 0
    end
    if slotId == 8 or slotId == 9 or slotId == 10 then
        if D.G[slotId] and D.G[slotId] > 0 then return D.G[slotId] end
        local kind = (slotId == 8 and "BACKPACK") or (slotId == 9 and "HELMET") or "ARMOR"
        for i = 1, 6 do
            local v = D.M and D.M[kind] and D.M[kind][i]
            if v and v > 0 then return v end
        end
        return 0
    end
    return D.G[slotId] or 0
end

-- Star Clothes (Independent read)
function API.GetShirt()
    return D.G[5] or 0
end

-- Star Outfit (Independent read)
function API.GetSuit()
    return D.S or 0
end

-- Star Original value (for captureSlots comparison, not affected by GetSlot outfit priority)
function API.GetRawSlot(slotId)
    slotId = tonumber(slotId) or 0
    if slotId == 8 or slotId == 9 or slotId == 10 then
        return API.GetSlot(slotId)
    end
    return D.G[slotId] or 0
end

function API.GetWeapon(baseWid) return D.W[tonumber(baseWid) or 0] or 0 end
function API.GetPet()           return D.P or 0 end
function API.Save(force)        save(force) end
function API.Load()             load() end

-- Star Star Star New: Clear All Configs (One-Click Clear File + Memory + Character + Fake Instances) Star Star Star
function API.ClearAll()
    -- 1) Clear memory
    D.G = {}
    D.M = { BACKPACK = {}, HELMET = {}, ARMOR = {} }
    D.W = {}
    D.V = {}
    D.P = 0
    D.S = 0
    _G.__WM_ForceBackpackSkin = false
    _G.__WM_ForceHelmetSkin = false
    _G.__WM_ForceArmorSkin = false

    -- 2) Force write file (write back the all-0 default template, ignore _snap cache)
    D._snap = nil
    save(true)

    -- 3) Clear global variables (to prevent the logic in ApplyToGlobals where assignment only happens when v>0 from missing a clear)
    _G.HairSkin = 0;      _G.SuitSkin = 0;      _G.HatSkin = 0
    _G.FaceSkin = 0;      _G.MaskSkin = 0;      _G.GlovesSkin = 0
    _G.PantSkin = 0;      _G.ShoeSkin = 0
    _G.ParachuteSkin = 0; _G.GliderSkin = 0;    _G.HeadShapeSkin = 0
    for i = 1, 6 do
        _G["Backpack" .. i .. "Skin"] = 0
        _G["Helmet" .. i .. "Skin"]   = 0
        _G["Armor" .. i .. "Skin"]    = 0
    end
    _G.WeaponSkinID = {}
    _G.PetSkin = 0
    _G.PetSkinMapIndex = 1
    if _G.DazhiMH_Config and _G.DazhiMH_Config._cache then
        for i = 1, 6 do
            _G.DazhiMH_Config._cache["BACKPACK" .. i] = 0
            _G.DazhiMH_Config._cache["HELMET" .. i] = 0
            _G.DazhiMH_Config._cache["ARMOR" .. i] = 0
        end
    end

    -- 4) Clear all applied slots on the character (set all ItemId in ad to zero)
    pcall(function()
        local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
        if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
        for _, v in pairs(LAM.playerList) do
            if type(v) == "userdata" and slua.isValid(v) then
                local comp = v.AvatarComponent2
                if comp and slua.isValid(comp) then
                    local nad = comp.NetAvatarData
                    if nad and slua.isValid(nad) then
                        local ad = nad.SlotSyncData
                        if ad then
                            local dirty = false
                            for i = 0, ad:Num() - 1 do
                                local e = ad:Get(i)
                                if e and e.SlotID and SLOT_GLOBAL[e.SlotID] then
                                    if e.ItemId ~= 0 then
                                        e.ItemId = 0
                                        ad:Set(i, e)
                                        dirty = true
                                    end
                                end
                            end
                            if dirty then
                                if comp.OnRep_BodySlotStateChanged then
                                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                                end
                                if comp.InitDepotCommonPutOn then
                                    pcall(function() comp:InitDepotCommonPutOn() end)
                                end
                            end
                        end
                    end
                end
                break
            end
        end
    end)

    -- 5) Clear fake instances in DataMgr.rolewear (IDs >=900000000)
    pcall(function()
        if DataMgr and type(DataMgr.rolewear) == "table" then
            for i = #DataMgr.rolewear, 1, -1 do
                local v = tonumber(DataMgr.rolewear[i])
                if v and v >= 900000000 then
                    table.remove(DataMgr.rolewear, i)
                end
            end
        end
    end)

    -- 6) Clear LobbySkinInjector cache
    pcall(function()
        if _G.LobbySkinInjector then
            local LSI = _G.LobbySkinInjector
            if LSI.customWorn then LSI.customWorn = {} end
            if LSI.fakeByRes then LSI.fakeByRes = {} end
            if LSI.customSet then LSI.customSet = {} end
        end
    end)

    print("[Wumingking] Star Cleared all configs (file + memory + character + fake instances)")
    return true
end
-- ★★★ Judge If Config File Has Any Character Skin to Apply ★★★
function API.HasAnyConfig()
    -- ★★★ Outfit Separate Judgment (D.S Not in D.G)★★★
    if D.S and D.S > 0 then return true end
    for _, v in pairs(D.G) do
        if v and v > 0 then return true end
    end
    for _, kind in ipairs({ "BACKPACK", "HELMET", "ARMOR" }) do
        for level = 1, 6 do
            local v = D.M and D.M[kind] and D.M[kind][level]
            if v and v > 0 then return true end
        end
    end
    return false
end

-- Star Apply to lobby character (Comprehensive: Iterate D.G + Force refresh)
function API.ApplyToLobby(silent)
    -- ★★★ If In-Match or Not in Lobby, Go Back Directly, Absolutely Do Not Execute! ★★★
    if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true) then
        return false
    end

    load()                                              -- First load to fill D.G
    if not API.HasAnyConfig() then                      -- Star Config all 0 -> Do not refresh
        return false
    end
    API.ApplyToGlobals()

    -- 1) Get the lobby character (only take the local player, to prevent applying mask and other skins to teammates)
local ch = nil
do
    local ok, LAM = pcall(require("client.logic.avatar.LobbyAvatarManager"))
    if ok and type(LAM) == "table" and type(LAM.playerList) == "table" then
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    ch = v
                    break
                end
            end
        end
        if not ch then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then ch = first end
        end
    end
end
    if not ch or not slua.isValid(ch) then
        print("[Wumingking] ApplyToLobby: Cannot get lobby character")
        return false
    end

    -- 2) Get AvatarComponent2 and SlotSyncData
    local comp
    pcall(function()
        local c = ch.AvatarComponent2
        if c and slua.isValid(c) then comp = c end
    end)
    if not comp then
        pcall(function()
            if ch.getAvatarComponent2 then
                local c = ch:getAvatarComponent2()
                if c and slua.isValid(c) then comp = c end
            end
        end)
    end
    if not comp then
        print("[Wumingking] ApplyToLobby: Cannot get AvatarComponent2")
        return false
    end
    local ad
    pcall(function()
        local nad = comp.NetAvatarData
        if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
    end)
    if not ad then
        print("[Wumingking] ApplyToLobby: Cannot get SlotSyncData")
        return false
    end

    -- 3) Iterate all slots in D.G (including backpack/helmet/armor), write to ad
-- Star Glider (15) and Parachute (11) not applied in lobby, only applied in-match
local LOBBY_SKIP_SLOTS = { [11] = true, [15] = true }
local changed = false
local total = 0

-- Star Slot 5 uniformly takes clothes / outfit
local v5 = API.GetSlot(5)
D.G[5] = (v5 and v5 > 0) and v5 or 0

for slot, itemId in pairs(D.G) do
    if itemId and itemId > 0 and not LOBBY_SKIP_SLOTS[slot] then
        local skip = false
        -- Star New: When wearing outfit, do not apply pants (6) and shoes (7)
        if D.S and D.S > 0 and (slot == 6 or slot == 7) then
            skip = true
        end
        
        if not skip then
            total = total + 1
            local idx = nil
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and e.SlotID == slot then idx = i; break end
            end
            if idx then
                local e = ad:Get(idx)
                if e.ItemId ~= itemId then
                    e.ItemId = itemId
                    ad:Set(idx, e)
                    changed = true
                end
            else
                ad:Add({ SlotID = slot, ItemId = itemId })
                changed = true
            end
        end
    end
end

-- Apply independently configured backpack / helmet / armor skins to the matching equipment level.
local _okBU, _BackpackUtils = pcall(import, "BackpackUtils")
for i = 0, ad:Num() - 1 do
    pcall(function()
        local e = ad:Get(i)
        if not e then return end
        local kind, level
        if e.SlotID == 8 then
            kind = "BACKPACK"
            level = (_okBU and _BackpackUtils and _BackpackUtils.GetEquipmentBagLevel
                and _BackpackUtils.GetEquipmentBagLevel(e.AdditionalItemID)) or 1
        elseif e.SlotID == 9 then
            kind = "HELMET"
            level = (_okBU and _BackpackUtils and _BackpackUtils.GetEquipmentHelmetLevel
                and _BackpackUtils.GetEquipmentHelmetLevel(e.AdditionalItemID)) or 1
        elseif e.SlotID == 10 then
            kind = "ARMOR"
            level = (_okBU and _BackpackUtils and _BackpackUtils.GetEquipmentArmorLevel
                and _BackpackUtils.GetEquipmentArmorLevel(e.AdditionalItemID)) or 1
        end
        level = math.floor(tonumber(level) or 1)
        if kind and level >= 1 and level <= 6 then
            local target = D.M and D.M[kind] and D.M[kind][level]
            if kind == "BACKPACK" and _G.__WM_ForceBackpackSkin then target = 450001 end
            if kind == "HELMET" and _G.__WM_ForceHelmetSkin then target = 450001 end
            if kind == "ARMOR" and _G.__WM_ForceArmorSkin then target = 450001 end
            if target and target > 0 and e.ItemId ~= target then
                e.ItemId = target
                ad:Set(i, e)
                changed = true
            end
        end
    end)
end

    print("[Wumingking] ApplyToLobby: Read " .. tostring(total) ..
          " slots, changed=" .. tostring(changed))

    -- ★★★ Fix 1: Only Clear PANT / SHOE Slots When Wearing Outfit, Keep Game Native When Not Configured ★★★
for i = ad:Num() - 1, 0, -1 do
    local e = ad:Get(i)
    if e and (e.SlotID == 6 or e.SlotID == 7) then
        -- Star Key: Only clear 6/7 when "wearing outfit"; when not configured (PANT=0 / SHOE=0) do not touch it
        if D.S and D.S > 0 then
            if e.ItemId and e.ItemId ~= 0 then
                e.ItemId = 0
                ad:Set(i, e)
                changed = true
            end
        end
    end
end

    if not changed then return true end

-- 4) Trigger underlying data change
pcall(function() if comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end end)

-- silent mode: Only change data, do not rebuild skeletal mesh (for re-apply)
if silent then return true end

    -- ★★★ Fix 2: Call Native Re-Equip, Force Rebuild Skeletal Mesh ★★★
    pcall(function()
        if comp.InitDepotCommonPutOn then
            comp:InitDepotCommonPutOn()
        end
    end)

    -- 5) Six-way refresh, any one success is enough
    pcall(function() if ch.RefreshAvatar then ch:RefreshAvatar() end end)
    pcall(function() if ch.OnRep_AvatarChange then ch:OnRep_AvatarChange() end end)
pcall(function()
    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
    if LAM then
        if LAM.RefreshAvatar then LAM.RefreshAvatar() end
        if LAM.RefreshMyAvatar then LAM:RefreshMyAvatar() end
        if LAM.CreateMyAvatar then LAM:CreateMyAvatar() end
    end
end)
    pcall(function()
        if ch.SetActorHiddenInGame then
            ch:SetActorHiddenInGame(true)
            local tt = _G.Mytimer_ticker
            if tt then
                tt.AddTimer(0.05, function()
                    pcall(function() ch:SetActorHiddenInGame(false) end)
                end)
            end
        end
    end)
    print("[Wumingking] ApplyToLobby Complete")
    return true
end



    -- Inject file content into memory global variables
function API.ApplyToGlobals()
-- Star Mutual exclusion: Outfit priority (Outfit > Clothes > Pants/Shoes)
if D.S and D.S > 0 then
    D.G[5] = 0
    D.G[6] = 0
    D.G[7] = 0
end

-- ★★★ Fix: Headwear (3) and Eyewear (12) Fallback Mutual Exclusion ★★★
-- When reading old file, if already merged, correct here: Only keep headwear, clear eyewear to 0
if D.G[3] and D.G[12] and D.G[3] > 0 and D.G[3] == D.G[12] then
    D.G[12] = 0
end

-- Star Only when SUIT>0 force-clear PANT/SHOE globals
local forceClearPantShoe = (D.S and D.S > 0)

for slot, varName in pairs(SLOT_GLOBAL) do
    local v = D.G[slot]

    -- Outfit has value -> Slot 5 shows outfit
    if D.S and D.S > 0 and slot == 5 then
        v = D.S
    end

    -- Star Key: Clothes / Outfit mode -> Pants / Shoes global variables forced to 0
    if forceClearPantShoe and (slot == 6 or slot == 7) then
        v = 0
    end

    -- Star Star Star Parachute / Glider: 0 Forces Default Value (100% Installed) Star Star Star
    if slot == 11 and (not v or v <= 0) then v = 1401469; D.G[11] = v end
    if slot == 15 and (not v or v <= 0) then v = 4151133; D.G[15] = v end

if v and v > 0 then
    _G[varName] = v
else
    _G[varName] = 0   -- Any slot configured as 0 clears global (including gloves)
end
end

for i = 1, 6 do
    local bagId = D.M and D.M.BACKPACK and D.M.BACKPACK[i]
    if bagId == nil then bagId = D.G[BACKPACK_SLOT] or 0 end
    _G["Backpack" .. i .. "Skin"] = tonumber(bagId) or 0

    local helmetId = D.M and D.M.HELMET and D.M.HELMET[i]
    if helmetId == nil then helmetId = D.G[HELMET_SLOT] or 0 end
    _G["Helmet" .. i .. "Skin"] = tonumber(helmetId) or 0

    local armorId = D.M and D.M.ARMOR and D.M.ARMOR[i]
    if armorId == nil then armorId = D.G[ARMOR_SLOT] or 0 end
    _G["Armor" .. i .. "Skin"] = tonumber(armorId) or 0
end

-- Feature switches are temporary visual overrides; they never overwrite the saved per-level IDs.
if _G.__WM_ForceBackpackSkin then
    for i = 1, 6 do _G["Backpack" .. i .. "Skin"] = 450001 end
end
if _G.__WM_ForceHelmetSkin then
    for i = 1, 6 do _G["Helmet" .. i .. "Skin"] = 450001 end
end
if _G.__WM_ForceArmorSkin then
    for i = 1, 6 do _G["Armor" .. i .. "Skin"] = 450001 end
end

_G.WeaponSkinID = _G.WeaponSkinID or {}
        for wid, sid in pairs(D.W) do
            _G.WeaponSkinID[wid] = sid
        end
        if D.P and D.P > 0 then 
    _G.PetSkin = D.P
    -- Star Reverse-lookup index, prevent later HandlePetLogic overwriting config with old default index
    for i, id in ipairs(_G.PetSkinMap or {}) do
        if id == D.P then
            _G.PetSkinMapIndex = i
            break
        end
    end
end

        -- Star Vehicle slider -> VehicleSkinIndex
        _G.VehicleSkinIndex = _G.VehicleSkinIndex or {}
        _G.__VehicleUserSet = _G.__VehicleUserSet or {}
        for key, idx in pairs(D.V) do
            local vid = VEHICLE_KEY_TO_ID[key]
            if vid and idx and idx > 0 then
                _G.VehicleSkinIndex[vid] = idx
                _G.__VehicleUserSet[vid] = idx
            end
        end
    end


    -- ========== Tools ==========
    local function inLobby()
        local ok, r = pcall(function()
            return GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()
        end)
        return ok and r == true
    end
    local function inMatch()
        local ok, r = pcall(function()
            return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
        end)
        return ok and r == true
    end

    -- ========== Lobby Capture (Every 0.5s) ==========
    local function getLobbyChar()
    local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
    if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return nil end

    -- Star Fix: Only return local player, avoid capturing teammates / spectated target mask skin data
    local selfUid = nil
    pcall(function()
        if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
            selfUid = tostring(DataMgr.roleData.uid)
        end
    end)

    if selfUid then
        for uid, v in pairs(LAM.playerList) do
            if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                return v
            end
        end
    end

    -- Fallback: Only return when there is unique character (means it is self)
    local first, count = nil, 0
    for _, v in pairs(LAM.playerList) do
        if type(v) == "userdata" and slua.isValid(v) then
            count = count + 1
            if not first then first = v end
        end
    end
    if count == 1 then return first end
    return nil
end

    local function getSlotArray(ch)
        if not ch or not slua.isValid(ch) then return nil, nil end
        local comp
        pcall(function()
            local c = ch.AvatarComponent2
            if c and slua.isValid(c) then comp = c end
        end)
        if not comp then
            pcall(function()
                if ch.getAvatarComponent2 then
                    local c = ch:getAvatarComponent2()
                    if c and slua.isValid(c) then comp = c end
                end
            end)
        end
        if not comp then return nil, nil end
        local ad
        pcall(function()
            local nad = comp.NetAvatarData
            if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
        end)
        return ad, comp
    end

-- Star Star Star Restore captureSlots: Capture Character Slots Once -> Write to Disk Immediately If Changed (Key!) Star Star Star
local function captureSlots()
    local ch = getLobbyChar()
    if not ch then return end
    local ad = getSlotArray(ch)
    if not ad then return end
    local ok, n = pcall(function() return ad:Num() end)
    if not ok or not n or n <= 0 then return end

    local BAD_IDS = { [1407550]=true, [1400129]=true, [404000]=true, [405000]=true }
    local changed = false

    for i = 0, n - 1 do
        pcall(function()
            local e = ad:Get(i)
            if e and e.SlotID and CAPTURE_SLOTS[e.SlotID] then
    -- Star Gloves: User just set -> Do not overwrite within 5 min
    if e.SlotID == 16 and _G.__WM_UserSetGloves then
        if os.clock() - (_G.__WM_UserSetGlovesAt or 0) < 300 then
            return
        end
    end
    -- Star Mask: Do not capture within 5 sec after exiting match (game resets slot 4 to default)
    if e.SlotID == 4 and _G.__justExitedMatch then
        return
    end
    -- Star Mask / Eyewear: Do not overwrite within 5 min after user actively sets (prevent game async reset)
-- Protect both slot 4 and slot 12 (mask may hang on either slot)
if (e.SlotID == 4 or e.SlotID == 12) and _G.__WM_UserSetFace then
    if os.clock() - (_G.__WM_UserSetFaceAt or 0) < 300 then
        return
    end
end
local val = e.ItemId or 0
if not BAD_IDS[val] then
    local multiLevel = nil
    if e.SlotID == 8 or e.SlotID == 9 or e.SlotID == 10 then
        pcall(function()
            local BU = import("BackpackUtils")
            if e.SlotID == 8 and BU.GetEquipmentBagLevel then
                multiLevel = BU.GetEquipmentBagLevel(e.AdditionalItemID) or 1
            elseif e.SlotID == 9 and BU.GetEquipmentHelmetLevel then
                multiLevel = BU.GetEquipmentHelmetLevel(e.AdditionalItemID) or 1
            elseif e.SlotID == 10 and BU.GetEquipmentArmorLevel then
                multiLevel = BU.GetEquipmentArmorLevel(e.AdditionalItemID) or 1
            end
        end)
        multiLevel = math.floor(tonumber(multiLevel) or 1)
    end
    local old = (multiLevel and API.GetLevelSkin and API.GetLevelSkin(e.SlotID, multiLevel))
        or ((API.GetRawSlot and API.GetRawSlot(e.SlotID)) or 0)

    -- ★★★ Fix: slot 5 No Longer Auto-Captures ★★★
-- Reason:
--   1. User changes outfit in lobby warehouse -> WardrobeSync's send_depot_put_on_req Hook has captured it precisely
--   2. After exiting a match, the game resets character slot5 to the default value (e.g. 1408079 -> 1405770),
--      This is not the user's choice, captureSlots would mistakenly write it as config
--   3. Consequence: When entering the second match (including Metro), the character wears the wrong ID and looks like an NPC
--   4. The user's active outfit change is already 100% covered by WardrobeSync, fallback capture here would instead create bugs
if e.SlotID == 5 then
    return
end

    if val > 0 and val ~= old then
    -- ★★★ Fix: Headwear (3) / Eyewear (12) Capture Mutual Exclusion ★★★
    -- Game puts same headwear into both slot 3 and slot 12, here keep only one
    if e.SlotID == 12 then
        local hatVal = (API.GetRawSlot and API.GetRawSlot(3)) or 0
        if hatVal == val then
            -- Headwear already used this ID, eyewear skips (avoid one disk write)
            return
        end
    elseif e.SlotID == 3 then
        local maskVal = (API.GetRawSlot and API.GetRawSlot(12)) or 0
        if maskVal == val then
            -- Headwear priority: Clear duplicate ID in eyewear
            if API.SetSlot then API.SetSlot(12, 0) end
        end
    end
    if e.SlotID == 8 or e.SlotID == 9 or e.SlotID == 10 then
        if API.SetLevelSkin then API.SetLevelSkin(e.SlotID, multiLevel or 1, val) end
    else
        API.SetSlot(e.SlotID, val)
    end
    changed = true
end
end
end
end)
end
    
    -- Star Star Star Core: After Saving, Instantly Sync New Clothes to Memory! Leave Background Timer Speechless!
    if changed and API.ApplyToGlobals then
        API.ApplyToGlobals()
    end
end



-- ★★★ Lobby Outfit-Change Hook: Capture and Write to Disk Immediately After Selection (Replaces 1.5 Sec Polling)★★★
local captureWeapon, capturePet
local function installCaptureHook()
    local ch = getLobbyChar()
    if not ch or not slua.isValid(ch) then return false end
    local ad, comp = getSlotArray(ch)
    if not comp then return false end
    if comp.__wm_captureHooked then return true end

    local origBody = comp.OnRep_BodySlotStateChanged
if origBody then
    comp.OnRep_BodySlotStateChanged = function(self, ...)
        if origBody then origBody(self, ...) end
        -- Star Delay 0.5 sec to wait for SlotSyncData sync before capturing, prevent reading old value
        local tt = _G.Mytimer_ticker
        if tt then
            tt.AddTimer(0.5, function()
                if captureSlots then pcall(captureSlots) end
                if captureWeapon then pcall(captureWeapon) end
                if capturePet then pcall(capturePet) end
            end)
        else
            if captureSlots then pcall(captureSlots) end
            if captureWeapon then pcall(captureWeapon) end
            if capturePet then pcall(capturePet) end
        end
    end
end

    local origInit = comp.InitDepotCommonPutOn
    if origInit then
        comp.InitDepotCommonPutOn = function(self, ...)
            local r = origInit(self, ...)
            if captureSlots then pcall(captureSlots) end
            if captureWeapon then pcall(captureWeapon) end
            if capturePet then pcall(capturePet) end
            return r
        end
    end

    comp.__wm_captureHooked = true
    return true
end


-- Star Capture weapon skin once -> Write to disk immediately if changed (G= line)
-- Three-way parallel: 1. DataMgr single gun  2. Scan weapon skin table in DataMgr  3. Weapon on lobby character
captureWeapon = function()
    if type(DataMgr) ~= "table" then return end

    -- 1. Single currently selected weapon (clicking a gun in lobby writes here)
    pcall(function()
        local wid = DataMgr.Weapon_ID
        local sid = DataMgr.Weapon_Skin_ResID
        if wid and sid and wid > 0 and sid > 0 then
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
            if base and base > 0 and sid ~= base then
                API.SetWeapon(base, sid)
            end
        end
    end)

    -- Star Power: Original 2. full-table scan is very heavy, change to fallback run only every 30 sec
local _nowScan = os.clock()
-- Star Performance: If not in lobby, do not do DataMgr full-table scan
local _inLobbyScan = (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity())
if _inLobbyScan and _nowScan - _G.__perf.dataMgrScanAt >= 30 then
    _G.__perf.dataMgrScanAt = _nowScan
    pcall(function()
        for fieldName, fieldVal in pairs(DataMgr) do
            if type(fieldVal) == "table" then
                local name = tostring(fieldName):lower()
                if name:find("weapon", 1, true)
                   or name:find("skin", 1, true)
                   or name:find("gun", 1, true) then
                    for k, v in pairs(fieldVal) do
                        local wid = tonumber(k)
                        local sid = tonumber(v)
                        if wid and sid and wid > 0 and wid < 1000000
                           and sid > wid then
                            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
                            if base and base > 0 then
                                API.SetWeapon(base, sid)
                            end
                        end
                    end
                end
            end
        end
    end)
end

    -- 3. Fallback: When lobby character really has a weapon
    local ch = getLobbyChar()
    if not ch or not slua.isValid(ch) then return end
    pcall(function()
        local w
        if ch.GetCurrentWeapon then w = ch:GetCurrentWeapon() end
        if not w and ch.CurrentWeapon then w = ch.CurrentWeapon end
        if not w or not slua.isValid(w) then return end

        local wid = 0
        if w.GetWeaponID then wid = w:GetWeaponID() or 0 end
        if wid <= 0 and w.GetItemDefineID then
            local d = w:GetItemDefineID()
            if d then wid = d.TypeSpecificID or 0 end
        end

        local sid = 0
        local arr = w.synData
        if arr and slua.isValid(arr) then
            local d = arr:Get(7)
            if d and slua.isValid(d) then
                sid = slua.IndexReference(d, 'defineID').TypeSpecificID or 0
            end
        end
        if wid > 0 and sid > 0 then
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
            if base and base > 0 and sid ~= base then
                API.SetWeapon(base, sid)
            end
        end
    end)
end

    -- Star Capture pet once (P= line)
    capturePet = function()
        -- Star Performance: If not in lobby, do not get pet module, avoid require on every page switch
        if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
        pcall(function()
            local MM = require("client.module_framework.ModuleManager")
            local lp = MM and MM.GetModule(MM.CommonModuleConfig.logic_pet)
            if lp and lp.GetEquipedPetInsID then
                local id = lp:GetEquipedPetInsID() or 0
                if id > 0 then API.SetPet(id) end
            end
        end)
    end



-- ========== Enter Match: Read File and Refresh ==========
local function applyToMatch()
    API.Load()             -- Re-read file
    API.ApplyToGlobals()   -- Inject into memory

    -- Star Star Star On Entering Match Immediately Apply All Feature Toggles Star Star Star
    pcall(ReadConfigFile)                          -- Re-read toggle
    if _G.GameCameraView then pcall(_G.GameCameraView) end
    if _G.UpdateWeatherMode then pcall(_G.UpdateWeatherMode, _G.WeatherMode or 0) end
    if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
    if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end
    if _G.GoldenLeavesTrail and _G.GoldenLeavesTrail.Apply then
        pcall(_G.GoldenLeavesTrail.Apply)
    end
    if _G.SetWeaponAnimation and _G.DazhiMH_Config and _G.DazhiMH_Config.Get then
        local wa = _G.DazhiMH_Config.Get("WEAPON_ANIM", 0) == 1
        pcall(_G.SetWeaponAnimation, wa)
    end
    -- Star Star Star Immediate Apply End Star Star Star

    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local ch
        pcall(function() ch = pc:GetPlayerCharacterSafety() end)
        if not ch or not slua.isValid(ch) then return end

        -- 1. Iterate all backpack weapons -> Apply main skin + attachments per D.W
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) then
                    local wid = w:GetWeaponID() or 0
                    if wid > 0 then
                        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
                        local target = D.W[base]
                        if target and target > 0 then
                            local arr = w.synData
                            if arr and slua.isValid(arr) then
                                local d = arr:Get(7)
                                if d and slua.isValid(d) then
                                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                                    if cur ~= target then
                                        slua.IndexReference(d, "defineID").TypeSpecificID = target
                                        arr:Set(7, d)
                                    end
                                end
                            end
                            if _G.apply_attachment then pcall(_G.apply_attachment, w, target) end
                            if w.DelayHandleAvatarMeshChanged then
                                pcall(function() w:DelayHandleAvatarMeshChanged() end)
                            end
                            if w.WeaponAvatarComponent and slua.isValid(w.WeaponAvatarComponent) then
                                pcall(function()
                                    if w.WeaponAvatarComponent.OnRep_AvatarChanged then
                                        w.WeaponAvatarComponent:OnRep_AvatarChanged()
                                    end
                                    if w.WeaponAvatarComponent.OnRep_SkinChanged then
                                        w.WeaponAvatarComponent:OnRep_SkinChanged()
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end)

        -- 2. Force overwrite character slots (Hook style: Let original function handle first, then fill gaps + change detection triggers refresh)
pcall(function()
    -- Step 1: First let equip_character_avatar change per globals
    -- Do not change ad, let it go through "ItemId different -> Set + Refresh" logic itself
    _G.__forceSkinRefresh = true
    if _G.equip_character_avatar then pcall(_G.equip_character_avatar, ch) end
    _G.__forceSkinRefresh = false

    -- Step 2: Hook-style fill gaps
    -- Compare globals with ad real values, fill in slots that did not take effect and force refresh
    local ad = getSlotArray(ch)
    if not ad then return end

    -- Slot -> Global variable name mapping (consistent with SLOT_GLOBAL)
    local SLOT_VAR = {
    [2]  = "HairSkin",      -- Star Supplement: Hair
    [3]  = "HatSkin",
    [4]  = "FaceSkin",
    [12] = "MaskSkin",
    [5]  = "SuitSkin",
    [6]  = "PantSkin",
    [7]  = "ShoeSkin",
    [16] = "GlovesSkin",
    [11] = "ParachuteSkin", -- Star Supplement: Parachute
    [15] = "GliderSkin",    -- Star Supplement: Glider
}

    local changed = false

    -- Step 1: Iterate existing slots, Set values in
for i = 0, ad:Num() - 1 do
    local e = ad:Get(i)
    if e then
        local varName = SLOT_VAR[e.SlotID]
        local target = varName and _G[varName]
                       
        if target and target > 0 and e.ItemId ~= target then
                e.ItemId = target
                ad:Set(i, e)
                changed = true
            end
        end
    end

    -- Star Star Star Step 2: Actively Add Non-Existent Slots Star Star Star
    -- This step is key to fixing eyewear / mask
    for slot, varName in pairs(SLOT_VAR) do
        local target = _G[varName]
        if target and target > 0 then
            -- Check if slot already exists
            local found = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and e.SlotID == slot then
                    found = true
                    break
                end
            end
            -- Add if not exists
            if not found then
                ad:Add({ SlotID = slot, ItemId = target })
                changed = true
            end
        end
    end
    -- Star Star Star New End Star Star Star

    -- Only trigger refresh when really changed
    -- This way each match only refreshes once on entering, not every frame -> No lag
    if changed then
        -- Star Call equip_character_avatar again, ensure newly added headwear / eyewear / mask slots are correctly assigned
        _G.__forceSkinRefresh = true
        if _G.equip_character_avatar then pcall(_G.equip_character_avatar, ch) end
        _G.__forceSkinRefresh = false

        if ch.AvatarComponent2 and ch.AvatarComponent2.OnRep_BodySlotStateChanged then
            pcall(function() ch.AvatarComponent2:OnRep_BodySlotStateChanged() end)
        end
    end
end)
        if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end

        -- 3. Re-apply (prevent async model rebuild overwrite)
        if _G.Mytimer_ticker then
            local t = _G.Mytimer_ticker
            for _, sec in ipairs({ 1.0, 2.5, 5.0, 8.0 }) do
                t.AddTimer(sec, function()
                    pcall(function()
                        API.ApplyToGlobals()
                        if _G.GameAvatarHandlerweapons then _G.GameAvatarHandlerweapons() end
                        if _G.GameAvatarHandlerplayers then _G.GameAvatarHandlerplayers() end                        
                    end)
                end)
            end
        end
    end

    -- ========== Initialize ==========
    ensureFile()
    load()
    API.ApplyToGlobals()
    log("Loaded, path=" .. PATH)

-- ========== Timer ==========
if _G.Mytimer_ticker then
_WK_T = _G.Mytimer_ticker
_WK_wasLobby = false

-- Enter lobby: Apply immediately once + Delayed re-apply multiple times (fix hairstyle reset by character rebuild after exiting match)
_WK_T.AddTimerLoop(1, function()
    local l = inLobby()
    if l and not _WK_wasLobby then
        _WK_wasLobby = true
        D._suppressUntil = 0
        if not (API.HasAnyConfig and API.HasAnyConfig()) then return end
        pcall(API.ApplyToLobby)

        -- ★★★ Key Fix ★★★
        -- When exiting match back to lobby, game asynchronously rebuilds lobby character, resetting hair / face to default.
        -- Here after rebuild completes, delay re-apply several times, ensure hairstyle / face set in settings page is written back.
        -- Safety note:
        --   1) ApplyToLobby internally calls load() first to re-read the file, it will not overwrite the clothes you changed in the warehouse with old values
        --      (Warehouse outfit change has already been written to wumingking.h by WardrobeSync, load() reads the new value)
        --   2) Re-apply only applies values from the config file, does not scan lobby outfit changes, does not write file
        --   3) Only triggers at the moment of "entering the lobby", afterwards no more re-apply, does not affect manual lobby operations
        -- Only re-apply once, avoid character repeated rebuild causing lobby / warehouse lag
_WK_T.AddTimer(1.5, function()
    if inLobby() then
        pcall(API.ApplyToLobby, true)  -- silent mode, do not rebuild skeletal mesh
    end
end)
    elseif not l and _WK_wasLobby then
        _WK_wasLobby = false
    end
end, -1, 1)

-- Star Lobby outfit-change Hook check: Confirm once every 1 sec (auto re-hook after character rebuild)
_WK_T.AddTimerLoop(1, function()
    if not inLobby() then return end
    pcall(installCaptureHook)
end, -1, 1)

-- Fallback capture: Once every 3 sec (fallback when Hook fails, normally not triggered)
_WK_T.AddTimerLoop(3, function()
    if not inLobby() then return end
    pcall(captureSlots)
    pcall(captureWeapon)
    pcall(capturePet)
end, -1, 1)
    -- ★★★ Key Fix End ★★★

_WK_wasInMatch = false
_WK_T.AddTimerLoop(1, function()
    local m = inMatch()
    if m and not _WK_wasInMatch then
        _WK_T.AddTimer(1.0, function()
            pcall(applyToMatch)
        end)
    end
    _WK_wasInMatch = m
end, -1, 1)
end
end       



-- ============================================================
-- Star Star Star Settings Page: Read / Modify wumingking.h Star Star Star
-- ============================================================
do
    _G.__DazhiMH_CachedCustomPages = nil

    local function getAliasMap()
    local um = _G.UIManager
    if not (um and um.UI_Config) then
        local ok, m = pcall(require, "client.slua_ui_framework.manager")
        if ok then um = m end
    end
    if um and um.UI_Config then
        local c = um.UI_Config
        if c.Setting_Title and c.Setting_Spacer and c.Setting_Option_OpenWindow and c.Setting_Option_Slider then
            local am = {
                Title = c.Setting_Title,
                Spacer = c.Setting_Spacer,
                OpenWindow = c.Setting_Option_OpenWindow,
                Slider = c.Setting_Option_Slider,
                Switcher = c.Setting_Option_Switcher,
            }
            if not am.Switcher then
                local ok2, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
                if ok2 and AliasMap then am.Switcher = AliasMap.Switcher end
            end
            return am
        end
    end
    return nil
end

    local WK_Reg_Cache = {}
local function Reg(text)
    if not text then return 0 end
    if WK_Reg_Cache[text] then return WK_Reg_Cache[text] end

    local id = _G.__WK_NextLocId or 897000000
    id = id + 1
    _G.__WK_NextLocId = id
    if LocUtil and type(LocUtil.GetLocalizeResStr) == "function" then
        if not _G.__WK_LocPatched then
            _G.__WK_LocPatched = true
            local orig = LocUtil.GetLocalizeResStr
            LocUtil.GetLocalizeResStr = function(i)
                local m = _G.__WK_LocMap
                if m and m[i] then return m[i] end
                return orig(i)
            end
        end
        _G.__WK_LocMap = _G.__WK_LocMap or {}
        _G.__WK_LocMap[id] = text
    end
    WK_Reg_Cache[text] = id
    return id
end

-- Character outfit tab: restore manual ID inputs for supported equipment slots.
if _G.SuitSettingTab then
    local SST = _G.SuitSettingTab

-- Preset IDs supplied by the user. Backpack / Helmet lists contain Level-3 skins only.
local OUTFIT_XSUIT_SKINS = {
   
    -- [ X-SUIT ]
    { id = 1407895, name = "Blood Raven X-Suit (7-Star)" },
	{ id = 1407990, name = "Verdant Druvaen X-Suit (7-Star)" },
    { id = 1407856, name = "Phoenixtra X-Suit (7-Star)" },
    { id = 1406469, name = "Golden Pharaoh X-Suit (7-Star)" },
    { id = 1407140, name = "Poseidon X-Suit (7-Star)" },
    { id = 1407141, name = "Avalanche X-Suit (7-Star)" },
    { id = 1407142, name = "Silvanus X-Suit (7-Star)" },
    { id = 1407550, name = "Iridescence X-Suit (7-Star)" },
    { id = 1406638, name = "Arcane Jester X-Suit (6-Star) — Variant 1" },
    { id = 1406641, name = "Arcane Jester X-Suit (6-Star) — Variant 2" },
    { id = 1406872, name = "Stygian Liege X-Suit (7-Star)" },
    { id = 1406971, name = "Marmoris X-Suit (7-Star)" },
    { id = 1407103, name = "Fiore X-Suit (7-Star)" },
    { id = 1407219, name = "Ignis X-Suit (7-Star)" },
    { id = 1407259, name = "Ignis X-Suit (7-Star)" },
    { id = 1407366, name = "Galadria X-Suit (7-Star)" },
    { id = 1407512, name = "Anukhra X-Suit (7-Star)" },
    { id = 1407625, name = "Dravion X-Suit (7-Star) — Variant 1" },
    { id = 1407667, name = "Dravion X-Suit (7-Star) — Variant 2" },
    { id = 1408038, name = "Pyre Druvaen X-Suit (7-Star)" },
    { id = 1408045, name = "Frost Druvaen X-Suit (7-Star)" },
    
    -- [ OTHER UPGRADEABLE OUTFIT SETS ]
    { id = 1406906, name = "Specter Slayer Set (Lv. 3)" },
    { id = 1407020, name = "Serene Rapture Set (Lv. 3)" },
    { id = 1407055, name = "Lunahowl Set (Lv. 3)" },
    { id = 1407111, name = "Panthera Prime Set (Lv. 3)" },
    { id = 1407165, name = "Faerie Luster Set (Lv. 3)" },
    { id = 1407229, name = "Lilac Finesse Set (Lv. 3)" },
    { id = 1407290, name = "Nightscape Gladiator Set (Lv. 3)" },
    { id = 1407334, name = "Seadream Melody Set (Lv. 3)" },
    { id = 1407396, name = "Spirit Sentry Set (Lv. 3)" },
    { id = 1407445, name = "Tundra Knight Set (Lv. 3)" },
    { id = 1407475, name = "Rose Specter Set (Lv. 3)" },
    { id = 1407527, name = "Patchmetal Bunny Set (Lv. 3)" },
    { id = 1407577, name = "Rustborn Strider Set (Lv. 3)" },
    { id = 1407636, name = "Sweetbite Beastie Set (Lv. 3)" },
    { id = 1407700, name = "Aberrant Surgeon Set (Lv. 3)" },
    { id = 1407763, name = "Snowpaw Scout Set (Lv. 3)" },
    { id = 1407816, name = "Rebel Roguefox Set (Lv. 3)" },
    { id = 1407875, name = "Static Maverick Set (Lv. 3)" },
    { id = 1407926, name = "Sanctum Maiden Set (Lv. 3)" },
    { id = 1408001, name = "Wavesong Sprite Set (Lv. 3)" },
    { id = 1408084, name = "Exoframe Drifter Set (Lv. 3)" },
    
    -- [ FIREMAN ]
    { id = 1400117, name = "Fireman Suit" },
    
    -- [ BAPE CLOTHING ]
    { id = 1400569, name = "BAPE MIX CAMO HOODIE" },
    { id = 1400650, name = "BAPE MIX CAMO SHORTS" },
    { id = 1400651, name = "BAPE STA MID" },
    { id = 1402162, name = "BAPE X PUBGM CAMO Cap" },
    { id = 1404000, name = "BAPE City Camo Hoodie" },
    { id = 1404002, name = "BAPE City Camo Pants" },
    { id = 1404003, name = "BAPE Sta Mid" },
    { id = 1404048, name = "BAPE X PUBGM CAMO T-shirt" },
    { id = 1404049, name = "BAPE X PUBGM CAMO Shark Hoodie" },
    { id = 1404050, name = "BAPE X PUBGM CAMO Shorts" },
    { id = 1404051, name = "BAPE X PUBGM CAMO Shoes" },
    
    -- [ ORIGINAL OUTFITS ]
    { id = 1407870, name = "Dimensional Diva Set" },
    { id = 1407871, name = "Multiverse Detective Set" },
    { id = 1407812, name = "Wildsoul Warden Set" },
    { id = 1407758, name = "Winterglow Sylph Set" },
    { id = 1407286, name = "Devious Cybercat Set" },
    { id = 1407329, name = "Serene Lumina Set" },
    { id = 1407391, name = "Vampyra Countess Set" },
    { id = 1407392, name = "Feral Ravager Set" },
    { id = 1407387, name = "The Reaper's End Set" },
    { id = 1407440, name = "Arctic Conqueror Set" },
    { id = 1406985, name = "Surfside Sweetheart Set" },
    { id = 1407470, name = "Untamed Celestial Set" },
    { id = 1407471, name = "Jadefang Aurora Set" },
    { id = 1407522, name = "Sandsylph Scion Set" },
    { id = 1407330, name = "Spectral Admiral Set" },
    { id = 1407523, name = "Malus Majesty Set" },
    { id = 1407558, name = "The Sun's Ascendance Set" },
    { id = 1407559, name = "The Moon's Luminance Set" },
    { id = 1407572, name = "Bloodbane Vesper Set" },
    { id = 1407682, name = "The Hermit's Chrysalis Set" },
    { id = 1407695, name = "Macabre Valentine Set" },
    { id = 1407696, name = "Prism Ascendant Set" },
    { id = 1407632, name = "Nyxen Sinistra Set" },
    { id = 1407573, name = "Spectral Byte Set" },
    { id = 1406398, name = "Flamewraith Set" },
    { id = 1406399, name = "Majestic Cavalry Set" },
    { id = 1406482, name = "Bramble Overlord Set" },
    { id = 1406483, name = "Lightning Nebula Set" },
    { id = 1406555, name = "Nether Visage Set" },
    { id = 1406573, name = "Spectral Swan Set" },
    { id = 1406574, name = "Cosmic Inquisitor Set" },
    { id = 1406656, name = "Bloody Noon Set" },
    { id = 1406657, name = "Starsea Admiral Set" },
    { id = 1406742, name = "Silver Guru Set" },
    { id = 1406744, name = "Solar Knight Set" },
    { id = 1406789, name = "Nether Phantom Set" },
    { id = 1406823, name = "Moondrop Eterna Set" },
    { id = 1406824, name = "Bloodstained Nemesis Set" },
    { id = 1406897, name = "Crimson Ephialtes Set" },
    { id = 1407277, name = "Inferno Fiend Set" },
    { id = 1406891, name = "Psychophage Set" },
    { id = 1405623, name = "Underworld Guide Set" },
    { id = 1400687, name = "Mummy Set" },
    { id = 1407618, name = "Polar Spectrophage Set" },
    
    -- [ ADDITIONAL OUTFITS FROM THE DUMP ]
    { id = 1407872, name = "Smooth Footwork Set" },
    { id = 1407875, name = "Static Maverick Set (Lv. 3)" },
    { id = 1407876, name = "Sonic Siren Set" },
    { id = 1407877, name = "Urban Patrol Set" },
    { id = 1407878, name = "Sunshine Vigor Set" },
    { id = 1407879, name = "Starlight Vigor Set" },
    { id = 1407880, name = "Lightning Circuit Set" },
    { id = 1407881, name = "Catch! Teenieping Overalls Set" },
    { id = 1407882, name = "Catch! Teenieping Princess Romi Set" },
    { id = 1407883, name = "Nakiri Ayame Set" },
    { id = 1407884, name = "Thala Legacy Set" },
    { id = 1407885, name = "Knight Dominion Set" },
    { id = 1407886, name = "BamBam Infinite Octave Set" },
    { id = 1407887, name = "Minnie Infinite Octave Set" },
    { id = 1407888, name = "Soccer Vanguard Set" },
    { id = 1407889, name = "Night Tulip Set" },
    { id = 1407890, name = "Silky Beauty Set" },
    { id = 1407891, name = "FiNCH Set" },
    { id = 1407892, name = "Sparkle Spec Ops Set" },
    { id = 1407893, name = "S29 Set" },
    { id = 1407894, name = "Multiverse Detective Set" },
    { id = 1407897, name = "Mirage Phantom Set" },
    { id = 1407898, name = "Queen of Suits Set" },
    { id = 1407899, name = "Legendary Noble Set" },
    { id = 1407900, name = "Maid Berserker Set" },
    
    -- [ BLUE LOCK ]
    { id = 1407901, name = "Isagi Yoichi Character Set" },
    { id = 1407902, name = "Bachira Meguru Character Set" },
    { id = 1407903, name = "Nagi Seishiro Character Set" },
    { id = 1407904, name = "Itoshi Rin Character Set" },
    
    -- [ ADDITIONAL OUTFITS ]
    { id = 1407905, name = "Training Outfit Set" },
    { id = 1407906, name = "Chaosphage Set" },
    { id = 1407907, name = "Clash of Duty Set" },
    { id = 1407908, name = "Harley-Davidson® Blacktop Biker Set" },
    { id = 1407909, name = "Harley-Davidson® Street Smart Set" },
    { id = 1407910, name = "Chicken Winner Set" },
    { id = 1407911, name = "Denim Rebel Set" },
    { id = 1407912, name = "Lethal Beat Set" },
    { id = 1407913, name = "Rose Requiem Set" },
    { id = 1407914, name = "Wondrous Academy Set" },
    { id = 1407915, name = "Fantasy Academy Set" },
    { id = 1407916, name = "Castor Set" },
    { id = 1407917, name = "Pollux Set" },
    { id = 1407918, name = "Dioscuri Set" },
    { id = 1407919, name = "Serpent Handler Set" },
    { id = 1407920, name = "Bloodfeather Spartan Set" },
    { id = 1407921, name = "Aberrant Aphrodite Set" },
    { id = 1407922, name = "Amphibiraider Set" },
    { id = 1407923, name = "Eminent Scholar Set" },
    { id = 1407926, name = "Sanctum Maiden Set (Lv. 3)" },
    { id = 1407927, name = "Feathered Scholar Set" },
    { id = 1407928, name = "Laurel Melody Set" },
    { id = 1407929, name = "Precision Kit Set" },
    { id = 1407930, name = "Amplified Kit Set" },
    { id = 1407931, name = "Civil Harmony Set" },
    { id = 1407932, name = "Fuwa Minato Set" },
    { id = 1407933, name = "Ibrahim Set" },
    { id = 1407934, name = "Lauren Iroas Set" },
    { id = 1407935, name = "Usada Pekora Set" },
    { id = 1407936, name = "Usada Pekora (Casual Outfit) Set" },
    { id = 1407937, name = "Lightning Ring Robe Set" },
    { id = 1407938, name = "Veteran Guard Set" },
    { id = 1407939, name = "Quinas Legacy Set" },
    { id = 1407940, name = "Uğurcan Çakır's Set" },
    { id = 1407941, name = "Striker Set" },
    { id = 1407942, name = "Coronation Kiss Set" },
    { id = 1407944, name = "Albiceleste Set" },
    { id = 1407945, name = "Overlord's Decree Set" },
    { id = 1407946, name = "Babylonian Lion Set" },
    { id = 1407947, name = "Magixx Set" },
    { id = 1407948, name = "Tahilalats Summer Chill Set" },
    { id = 1407949, name = "S30 Set" },
    { id = 1407957, name = "Cybernetic Samurai Set" },
    { id = 1407958, name = "Nightfall Stalker Set" },
    { id = 1407959, name = "Pink Bunny Cadet Set" },
    
    -- [ NARUTO ]
    { id = 1407960, name = "The Fourth's Cloak Set" },
    { id = 1407961, name = "Naruto Outfit Set" },
    { id = 1407962, name = "Naruto Uzumaki Character Set" },
    { id = 1407963, name = "Sasuke Uchiha Character Set" },
    { id = 1407964, name = "Sakura Haruno Character Set" },
    { id = 1407965, name = "Kakashi Character Set" },
    { id = 1407966, name = "Hinata Hyuga Character Set" },
    { id = 1407967, name = "Gaara Character Set" },
    { id = 1407968, name = "Tsunade Character Set" },
    { id = 1407969, name = "Madara Uchiha Character Set" },
    { id = 1407970, name = "Jiraiya Character Set" },
    { id = 1407971, name = "Akatsuki Set" },
    { id = 1407972, name = "Elite Hidden Leaf Ninja Set" },
    { id = 1407973, name = "Konoha Anbu Set" },
    
    -- [ ADDITIONAL OUTFITS ]
    { id = 1407974, name = "Atlantean Ranger Set" },
    { id = 1407975, name = "Crimson Bigcat Set" },
    { id = 1407976, name = "Futuretech Jackal Set" },
    { id = 1407977, name = "Racing Superstar Set" },
    { id = 1407978, name = "Street Breaker Set" },
    { id = 1407979, name = "Sunbasker Set" },
    { id = 1407980, name = "Tide Tracker Set" },
    { id = 1407981, name = "Electron Energy Set" },
    { id = 1407982, name = "Proton Power Set" },
    { id = 1407983, name = "Sakura Neko Set" },
    
    -- X-Suits 1407984–1407990 are kept in the separate X-Suit list.
    
    { id = 1407991, name = "Equinox Vulpes Set" },
    { id = 1407992, name = "Darkmoon Corvus Set" },
    { id = 1407993, name = "Naruto (Sage Mode) Character Set" },
    { id = 1407994, name = "Naruto (Six Paths Mode) Character Set" },
    { id = 1407995, name = "Phantasia Siren Set" },
    { id = 1407996, name = "Energetic Beat Set" },
    { id = 1407997, name = "Puppet Maestro Set" },
    { id = 1408001, name = "Wavesong Sprite Set (Lv. 3)" },
    { id = 1408002, name = "Chromeshark Shredder Set" },
    { id = 1408003, name = "Fishy Fun Set" },
    { id = 1408004, name = "Quantum Harmony Set" },
    { id = 1408005, name = "Quantum Nightmare Set" },
    { id = 1408006, name = "Breezy Beachgoer Set" },
    { id = 1408007, name = "999HUMANITY Set" },
    { id = 1408008, name = "Carry Minati Set" },
    { id = 1408009, name = "Cryo King Set" },
    { id = 1408014, name = "Battleground for Every #1 Set" },
    { id = 1408015, name = "Ancient Charm Set" },
    { id = 1408016, name = "Ayo Maff Set" },
    { id = 1408017, name = "Season Series Set (2026H2)" },
    { id = 1408018, name = "S31 Set" },
    
    -- [ ADDITIONAL NARUTO RECORDS ]
    { id = 1408019, name = "Young Naruto Character Set" },
    { id = 1408020, name = "Naruto (Sage Mode) Character Set" },
    { id = 1408021, name = "Naruto (Six Paths Mode) Character Set" },
    { id = 1408022, name = "Naruto Uzumaki Character Set" },
    { id = 1408023, name = "Young Naruto Character Set" },
    { id = 1408024, name = "Sasuke Uchiha Character Set" },
    { id = 1408025, name = "Sakura Haruno Character Set" },
    { id = 1408026, name = "Kakashi Character Set" },
    { id = 1408027, name = "Hinata Hyuga Character Set" },
    { id = 1408028, name = "Gaara Character Set" },
    { id = 1408029, name = "Tsunade Character Set" },
    { id = 1408030, name = "Madara Uchiha Character Set" },
    { id = 1408031, name = "Jiraiya Character Set" },
    
    -- X-Suits 1408032–1408045 are kept in the separate X-Suit list.
    
    { id = 1408046, name = "Racing Suit" },
    { id = 1408051, name = "Top Youth Set" },
    { id = 1408052, name = "Voodoo Scarecrow Set" },
    { id = 1408053, name = "Midnight Thorns Set" },
    { id = 1408054, name = "Shiba Explorer Set" },
    
    -- [ ONE-PUNCH MAN ]
    { id = 1408055, name = "The Strongest Man on Earth Set" },
    { id = 1408056, name = "Saitama Character Set" },
    { id = 1408057, name = "Genos Character Set" },
    { id = 1408058, name = "Terrible Tornado Character Set" },
    { id = 1408059, name = "Hellish Blizzard Character Set" },
    { id = 1408060, name = "Garou Ver.1 Character Set" },
    { id = 1408061, name = "Garou Ver.2 Character Set" },
    { id = 1408062, name = "Bound Rose Set" },
    { id = 1408063, name = "Ordinary Hero Set" },
    { id = 1408064, name = "Watchdog Man Character Set" },
    
    -- [ ADDITIONAL OUTFITS ]
    { id = 1408065, name = "Metropia Hunter Set" },
    { id = 1408066, name = "Dark Gallantry Set" },
    { id = 1408067, name = "B.Duck Summer Splash Set" },
    { id = 1408068, name = "Dungeon Bandit Set" },
    { id = 1408069, name = "Nightingale Assassin Set" },
    { id = 1408070, name = "Revenant Puppet Set" },
    { id = 1408071, name = "Wakala Set" },
    { id = 1408072, name = "Suzzanna-Sundel Bolong Set" },
    { id = 1408073, name = "Orbital Rider Set" },
    { id = 1408074, name = "Umbral Scorpius Set" },
    { id = 1408075, name = "Umbral Scorpius Set" },
    { id = 1408076, name = "Cosmic Steward Set" },
    { id = 1408077, name = "Starlight Sentinel Set" },
    { id = 1408078, name = "Platinum Soulmeister Set" },
    { id = 1408079, name = "Sanguine Sonata Set" },
    { id = 1408080, name = "Speedy Departure Set" },
    { id = 1408081, name = "Frenzied Wolfguard Set" },
    { id = 1408084, name = "Exoframe Drifter Set (Lv. 3)" },
    { id = 1408085, name = "Fearless Battlestriker Set" },
    { id = 1408086, name = "Renegade Tracker Set" },
    { id = 1408087, name = "Lady Darkrose Set" },
    { id = 1408088, name = "Lady Redrose Set" },
    { id = 1408089, name = "Skele Stealth Set" },
    { id = 1408090, name = "Kuzuha Vampire Knight Set" },
    { id = 1408092, name = "Black Lotus Grim Reaper Set" },
    { id = 1408093, name = "King's Dragon Robe Set" },
    { id = 1408094, name = "Black Lotus Hanbok Set" },
    { id = 1408095, name = "Millennium Hwarang Set" },
    { id = 1408096, name = "Azure Featherdancer Set" },
    { id = 1408097, name = "Gem Charm Dancer Set" },
    { id = 1408098, name = "Sun Tulip Set" },
    { id = 1408099, name = "Wild Wolfspirit Set" },
    { id = 1408100, name = "Desert Rider Set" },
    { id = 1408101, name = "Desert Flowers Set" },
    { id = 1408102, name = "Crimson Spirit Bunny Set" },
    { id = 1408103, name = "Gentleman Set" },
    { id = 1408104, name = "Carefree Nation Set" },
    { id = 1408105, name = "Pumpkin Phantom Set" },
    { id = 1408106, name = "S32 Set" },
    
    -- [ DRAGON BALL SUPER COLLAB ]
    { id = 1406937, name = "Super Saiyan Son Goku Character Set" },
    { id = 1406938, name = "Frieza Character Set" },
    { id = 1406939, name = "Son Goku Character Set" },
    { id = 1406947, name = "Vegeta Character Set" },
    { id = 1406948, name = "Super Saiyan Vegeta Character Set" },
    { id = 1406949, name = "Frieza Style Set" },
    { id = 1406950, name = "Beerus Style Set" },
    { id = 1406951, name = "Majin Buu Style Set" },
    { id = 1406952, name = "Kamesennin Style Set" },
    { id = 1406953, name = "Ultimate Gohan Character Set" },
    { id = 1406954, name = "Piccolo Character Set" },
    { id = 1407264, name = "Vegito Character Set" },
    { id = 1407265, name = "Super Saiyan Vegito Character Set" },
    { id = 1407266, name = "Super Saiyan Blue Vegito Character Set" },
    { id = 1407267, name = "Super Saiyan Blue Son Goku Character Set" },
    { id = 1407268, name = "Super Saiyan Blue Son Goku (Damaged) Character Set" },
    { id = 1407269, name = "Super Saiyan Blue Vegeta Character Set" },
    { id = 1407270, name = "Super Saiyan Blue Vegeta (Damaged) Character Set" },
    { id = 1407271, name = "Bulma Character Set" },
    { id = 1407272, name = "Future Trunks Style Set" },
    
    -- [ EVANGELION COLLAB ]
    { id = 1406385, name = "Evangelion Shinji Plugsuit" },
    { id = 1406386, name = "Evangelion Rei Plugsuit" },
    { id = 1406387, name = "Evangelion Asuka Plugsuit" },
    { id = 1406388, name = "Evangelion Mari Plugsuit" },
    { id = 1406389, name = "Evangelion Kaworu Plugsuit" },
    
    -- [ EVANGELION - EVA ARMOR OUTFITS ]
    { id = 1406381, name = "Extreme Armor Model EVA-08" },
    { id = 1406382, name = "Extreme Armor Model EVA-02" },
    { id = 1406383, name = "Extreme Armor Model EVA-00" },
    { id = 1406384, name = "Extreme Armor Model EVA-01" },
    
    -- [ ATTACK ON TITAN COLLAB ]
    { id = 1407563, name = "Eren Jaeger Character Set" },
    { id = 1407564, name = "Attack Titan Set" },
    { id = 1407565, name = "Mikasa Ackermann Character Set" },
    { id = 1407566, name = "Armin Arlelt Character Set" },
    { id = 1407567, name = "Colossal Titan (Armin) Set" },
    { id = 1407568, name = "Levi Character Set" },
    { id = 1407569, name = "Armored Titan Costume" },
    { id = 1407570, name = "Scout Regiment Gear Set" },
    
    -- [ ATTACK ON TITAN - ADDITIONAL RECORDS ]
    { id = 1407597, name = "Eren Jaeger Character Set" },
    { id = 1407598, name = "Attack Titan Set" },
    { id = 1407599, name = "Mikasa Ackermann Character Set" },
    { id = 1407600, name = "Armin Arlelt Character Set" },
    { id = 1407601, name = "Colossal Titan (Armin) Set" },
    { id = 1407602, name = "Levi Character Set" },
    { id = 1407604, name = "Attack Titan Set" },
    { id = 1407605, name = "Attack Titan Set" },
    
    -- [ KAIJU NO. 8 COLLAB ]
    { id = 1407672, name = "Kafka Hibino Character Set" },
    { id = 1407673, name = "Kaiju No. 8 Set" },
    { id = 1407674, name = "Kikoru Shinomiya Character Set" },
    { id = 1407675, name = "Kaiju No. 9 Set" },
    { id = 1407676, name = "Kaiju No. 10 Set" },
    { id = 1407677, name = "Mina Ashiro Character Set" },
    { id = 1407678, name = "Reno Ichikawa Character Set" },
    { id = 1407679, name = "Soshiro Hoshina Character Set" },
    
    -- [ BLACKPINK - DDU-DU DDU-DU ]
    { id = 1406132, name = "DDU-DU DDU-DU ROSÉ Outfit" },
    { id = 1406133, name = "DDU-DU DDU-DU JENNIE Outfit" },
    { id = 1406134, name = "DDU-DU DDU-DU JISOO Outfit" },
    { id = 1406135, name = "DDU-DU DDU-DU LISA Outfit" },
    
    -- [ BLACKPINK - READY FOR LOVE ]
    { id = 1406136, name = "Ready For Love ROSÉ Outfit" },
    { id = 1406137, name = "Ready For Love JISOO Outfit" },
    { id = 1406138, name = "Ready For Love LISA Outfit" },
    { id = 1406139, name = "Ready For Love JENNIE Outfit" },
    
    -- [ BLACKPINK - HOW YOU LIKE THAT ]
    { id = 1406161, name = "How You Like That ROSÉ Outfit" },
    { id = 1406162, name = "How You Like That JENNIE Outfit" },
    { id = 1406163, name = "How You Like That JISOO Outfit" },
    { id = 1406164, name = "How You Like That LISA Outfit" },
    
    -- [ BLACKPINK - LOVESICK GIRLS ]
    { id = 1406178, name = "Lovesick Girls ROSÉ Outfit" },
    { id = 1406179, name = "Lovesick Girls JENNIE Outfit" },
    { id = 1406180, name = "Lovesick Girls JISOO Outfit" },
    { id = 1406181, name = "Lovesick Girls LISA Outfit" },
    
    -- [ BLACKPINK - KILL THIS LOVE ]
    { id = 1406203, name = "Kill This Love ROSÉ Outfit" },
    { id = 1406204, name = "Kill This Love JENNIE Outfit" },
    { id = 1406205, name = "Kill This Love JISOO Outfit" },
    { id = 1406206, name = "Kill This Love LISA Outfit" },
    
    -- [ NEWJEANS ]
    { id = 1407346, name = "PUBGM X NewJeans MINJI Set" },
    { id = 1407347, name = "PUBGM X NewJeans HANNI Set" },
    { id = 1407348, name = "PUBGM X NewJeans HAERIN Set" },
    { id = 1407349, name = "PUBGM X NewJeans DANIELLE Set" },
    { id = 1407350, name = "PUBGM X NewJeans HYEIN Set" },
    
    -- [ BABYMONSTER ]
    { id = 1407745, name = "RAMI Set" },
    { id = 1407746, name = "ASA Set" },
    { id = 1407747, name = "AHYEON Set" },
    { id = 1407748, name = "RORA Set" },
    { id = 1407749, name = "CHIQUITA Set" },
    { id = 1407750, name = "PHARITA Set" },
    { id = 1407751, name = "RUKA Set" },
    { id = 1407752, name = "BABYMONSTER Horns Set" },
    
    -- [ AESPA ]
    { id = 1407826, name = "PUBG MOBILE × aespa KARINA Set" },
    { id = 1407827, name = "PUBG MOBILE × aespa GISELLE Set" },
    { id = 1407828, name = "PUBG MOBILE × aespa WINTER Set" },
    { id = 1407829, name = "PUBG MOBILE × aespa NINGNING Set" },
    
    -- [ G-DRAGON ]
    { id = 1407687, name = "G-DRAGON PEACEMINUSONE Outfit Set" },
    { id = 1407688, name = "G-DRAGON Stage Outfit Set" },
    
    -- [ QWER ]
    { id = 1407642, name = "PUBGM X QWER Siyeon Set" },
    { id = 1407643, name = "PUBGM X QWER Hina Set" },
    { id = 1407644, name = "PUBGM X QWER Chodan Set" },
    { id = 1407645, name = "PUBGM X QWER Magenta Set" },
}

-- User-provided Parachute / Glider item IDs. Names are intentionally shown as ID choices.
local PARACHUTE_DEFAULT_ID = 1401469
local GLIDER_DEFAULT_ID = 4151133
local PARACHUTE_SKINS = {
    { id = 1401847, name = "Cybernetic Samurai Parachute" },
    { id = 1401848, name = "Naruto Parachute" },
    { id = 1401849, name = "Atlantean Ranger Parachute" },
    { id = 1401850, name = "Ferrari Parachute" },
    { id = 1401851, name = "Wave Cascade Parachute" },
    { id = 1401852, name = "999HUMANITY Parachute" },
    { id = 1401853, name = "Keep Away Parachute" },
    { id = 1401854, name = "Season Series Parachute (2026H2)" },
    { id = 1401855, name = "S31 Parachute" },
    { id = 1401856, name = "Infinix Parachute" },
    { id = 1401857, name = "Voodoo Scarecrow Parachute" },
    { id = 1401858, name = "One-Punch Man Parachute" },
    { id = 1401859, name = "Metropia Hunter Parachute" },
    { id = 1401860, name = "Lincoln Parachute" },
    { id = 1401861, name = "Scorpius Gem Parachute" },
    { id = 1401862, name = "Specter Ops Parachute" },
    { id = 1401863, name = "Kuzuha Parachute" },
    { id = 1401864, name = "S32 Parachute" },
    { id = 1401000, name = "New Year's Blessing Parachute" },
    { id = 1401001, name = "Happy New Year Parachute" },
    { id = 1401002, name = "Red Bone Parachute" },
    { id = 1401003, name = "Mischievous Little Demon Parachute" },
    { id = 1401005, name = "Transforming Spider Parachute" },
    { id = 1401006, name = "Season 5 Parachute" },
    { id = 1401007, name = "Birthday Parachute" },
    { id = 1401008, name = "Golden Crane Parachute" },
    { id = 1401009, name = "Red Demon Parachute" },
    { id = 1401010, name = "Botanical Flower Parachute" },
    { id = 1401011, name = "Cherry Blossom Parachute" },
    { id = 1401012, name = "Campus Tournament Parachute" },
    { id = 1401013, name = "Joker Parachute" },
    { id = 1401014, name = "Clown Parachute" },
    { id = 1401015, name = "Carabao Parachute" },
    { id = 1401016, name = "Orange Life Parachute" },
    { id = 1401017, name = "Golden Eagle Parachute" },
    { id = 1401018, name = "Season 8 Champion Parachute" },
    { id = 1401019, name = "Captain Ryan Parachute" },
    { id = 1401020, name = "Wanderer Parachute" },
    { id = 1401021, name = "Moon Palace Parachute" },
    { id = 1401022, name = "OPPO F11 PRO Survivors Parachute" },
    { id = 1401023, name = "Sekigahara Lord Parachute (Square)" },
    { id = 1401024, name = "Supply Drop Alliance Parachute" },
    { id = 1401025, name = "Enchanted Night Parachute (Square)" },
    { id = 1401026, name = "Auspicious Parachute" },
    { id = 1401027, name = "PMCO Parachute" },
    { id = 1401028, name = "Season 7 Champion Parachute" },
    { id = 1401029, name = "Vibrant Birthday Parachute" },
    { id = 1401031, name = "Season 6 Champion Parachute" },
    { id = 1401032, name = "Red Dagger Parachute" },
    { id = 1401033, name = "WALKER Parachute" },
    { id = 1401034, name = "Frost Witch Parachute" },
    { id = 1401035, name = "Challenger Parachute" },
    { id = 1401036, name = "BAPE X PUBGM Camo Parachute" },
    { id = 1401037, name = "Godzilla Parachute (White)" },
    { id = 1401038, name = "Godzilla Parachute (Yellow)" },
    { id = 1401039, name = "Godzilla Parachute (Blue)" },
    { id = 1401040, name = "Monarch Parachute" },
    { id = 1401041, name = "Curry Parachute" },
    { id = 1401043, name = "Night Watcher Parachute" },
    { id = 1401044, name = "Black Rose Parachute" },
    { id = 1401045, name = "Lucky Cat Parachute" },
    { id = 1401046, name = "Gloomy Night Parachute" },
    { id = 1401047, name = "Killer Whale Parachute" },
    { id = 1401048, name = "Kraken Parachute" },
    { id = 1401050, name = "Musical Melody Parachute" },
    { id = 1401051, name = "OPPO Reno Parachute" },
    { id = 1401052, name = "OPPO VOOC Parachute" },
    { id = 1401053, name = "Enchanted Night Parachute" },
    { id = 1401054, name = "Mischievous Piggy Parachute" },
    { id = 1401055, name = "Red Parachute (Long)" },
    { id = 1401056, name = "PMJC Parachute" },
    { id = 1401057, name = "PMSC Parachute" },
    { id = 1401059, name = "Draconian Champion Parachute" },
    { id = 1401060, name = "Sekigahara Lord Parachute" },
    { id = 1401061, name = "Little Demon Parachute" },
    { id = 1401062, name = "Season 9 Champion Parachute" },
    { id = 1401063, name = "Season 10 Champion Parachute" },
    { id = 1401064, name = "Black Cat Parachute" },
    { id = 1401065, name = "Rooster Parachute" },
    { id = 1401066, name = "Frost Bookworm Parachute" },
    { id = 1401067, name = "Painkiller #11 Parachute" },
    { id = 1401068, name = "Super Power Parachute" },
    { id = 1401071, name = "Endless Reincarnation Parachute" },
    { id = 1401072, name = "Lord of All Beasts Parachute" },
    { id = 1401074, name = "Horror Pumpkin Parachute" },
    { id = 1401085, name = "Delicious Chicken Parachute" },
    { id = 1401086, name = "Season 11 Champion Parachute" },
    { id = 1401087, name = "Blood Lotus Parachute" },
    { id = 1401088, name = "Drifting Planet Parachute" },
    { id = 1401089, name = "Season 12 Champion Parachute" },
    { id = 1401090, name = "Assassin Ninja Parachute" },
    { id = 1401091, name = "Sakura Neko Parachute" },
    { id = 1401092, name = "Vanguard Parachute" },
}

local GLIDER_SKINS = {
    
    -- [ GLIDERS / HOVERBOARDS / PARACHUTE TRAILS ]

    { id = 4151001, name = "Parachute Trail (Green)" },
	{ id = 4151149, name = "Earthly Pedestal Glider" },
	
    { id = 4151002, name = "Parachute Trail (Yellow)" },
    { id = 4151003, name = "Parachute Trail (Pink)" },
    { id = 4151004, name = "Blue Glider Trail" },
    { id = 4151006, name = "Rainbow Glider Trail" },
    { id = 4151010, name = "PowPow Flying Machine" },
    { id = 4151012, name = "CYCLE Hoverboard" },
    { id = 4151013, name = "Arctic Hoverboard" },
    { id = 4151014, name = "CYCLE 2 Hoverboard" },
    { id = 4151015, name = "Celebration Parachute Trail (3 Colors)" },
    { id = 4151017, name = "Heart of Jade Hoverboard" },
    { id = 4151018, name = "Anniversary Spectre Hoverboard" },
    { id = 4151019, name = "Lovey-Dovey Glider" },
    { id = 4151020, name = "CYCLE 3 Hoverboard" },
    { id = 4151021, name = "Sacred Scarab Glider" },
    { id = 4151022, name = "Resplendent Wings Glider" },
    { id = 4151023, name = "Messi Collaboration Hoverboard" },
    { id = 4151024, name = "Scarlet Magus Glider" },
    { id = 4151025, name = "Skyrocket Glider" },
    { id = 4151026, name = "Silver Guru Glider" },
    { id = 4151027, name = "CYCLE 4 Hoverboard" },
    { id = 4151028, name = "Bloody Tear Hoverboard" },
    { id = 4151029, name = "Moondrop Eterna Glider" },
    { id = 4151030, name = "Bloodstained Nemesis Glider" },
    { id = 4151031, name = "Moneysaur Glider" },
    { id = 4151032, name = "Gloom Cataclysm Glider" },
    { id = 4151034, name = "Kintoun" },
    { id = 4151035, name = "Windborne Euphony Glider" },
    { id = 4151036, name = "Wave Smasher Hoverboard" },
    { id = 4151037, name = "CYCLE 5 Hoverboard" },
    { id = 4151038, name = "Bejeweled Pearl Glider" },
    { id = 4151040, name = "Boxerbolt Hoverboard" },
    { id = 4151041, name = "Blueyonder Glider" },
    { id = 4151042, name = "Agile Charmer Glider" },
    { id = 4151043, name = "Agile Charmer Glider" },
    { id = 4151044, name = "Soarshark Hoverboard" },
    { id = 4151045, name = "Chilly Perch Glider" },
    { id = 4151046, name = "Sky Edge Hoverboard" },
    { id = 4151056, name = "Chilly Perch Glider" },
    { id = 4151057, name = "Foxy Flare Hoverboard" },
    { id = 4151058, name = "LINE FRIENDS Glider" },
    { id = 4151059, name = "Cloudslash Hoverboard" },
    { id = 4151060, name = "Golden Serpent Glider" },
    { id = 4151061, name = "CYCLE 6 Hoverboard" },
    { id = 4151062, name = "Zanmang Loopy Parachute Trail" },
    { id = 4151063, name = "SPY×FAMILY Bond Glider" },
    { id = 4151064, name = "Dominion Wings Glider" },
    { id = 4151065, name = "Dominion Wings Glider" },
    { id = 4151066, name = "Enchanted Carpet Glider" },
    { id = 4151067, name = "Myriad Prism Glider" },
    { id = 4151068, name = "Bramble Overlord Glider" },
    { id = 4151069, name = "Lightning Nebula Glider" },
    { id = 4151070, name = "Majestic Cavalry Glider" },
    { id = 4151071, name = "Gilded Lovewing Glider" },
    { id = 4151072, name = "Galactic Trek Glider" },
    { id = 4151073, name = "Nightscape Ironwing Glider" },
    { id = 4151074, name = "PUBGM X NewJeans Glider" },
    { id = 4151075, name = "Gilded Lovewing Glider" },
    { id = 4151076, name = "Celestial Reigns Glider" },
    { id = 4151077, name = "Flying Machine" },
    { id = 4151078, name = "Skyride Pegasus Glider" },
    { id = 4151079, name = "Underworld Vestige Glider" },
    { id = 4151080, name = "CYCLE 7 Hoverboard" },
    { id = 4151083, name = "Midnight Bonedrake Glider" },
    { id = 4151084, name = "Twilight Corset Glider" },
    { id = 4151085, name = "Gothic Firmament Glider" },
    { id = 4151086, name = "DP Drift Parachute" },
    { id = 4151087, name = "Midnight Bonedrake Glider" },
    { id = 4151089, name = "Mythical Raven Glider" },
    { id = 4151090, name = "Sweetheart Dream Glider" },
    { id = 4151091, name = "Cosmic Explorer Glider" },
    { id = 4151092, name = "Meridian Scroll Glider" },
    { id = 4151093, name = "Azurite Requiem Glider" },
    { id = 4151094, name = "CYCLE 8 Hoverboard" },
    { id = 4151095, name = "Nether Voyage Glider" },
    { id = 4151096, name = "Lightborne Wings Glider" },
    { id = 4151097, name = "King Ghidorah Glider" },
    { id = 4151098, name = "Chrono Pendulum Glider" },
    { id = 4151099, name = "Malus Majesty Glider" },
    { id = 4151103, name = "Asterion Chariot Glider" },
    { id = 4151104, name = "ODM Gear Glider" },
    { id = 4151105, name = "Doombound Express Glider" },
    { id = 4151106, name = "Spectrum Speeder Glider" },
    { id = 4151107, name = "Asterion Chariot Glider" },
    { id = 4151108, name = "Laserbeak Glider" },
    { id = 4151109, name = "Ice Tomb Glider" },
    { id = 4151110, name = "Dragonborne Wings Glider" },
    { id = 4151111, name = "Jet Reaver Glider" },
    { id = 4151112, name = "Resonant Knell Glider" },
    { id = 4151113, name = "CYCLE 9 Hoverboard" },
    { id = 4151114, name = "Dragonborne Wings Glider" },
    { id = 4151115, name = "Ice Tomb Glider" },
    { id = 4151117, name = "Preondactyl Glider" },
    { id = 4151118, name = "Eclipselle Bloom Glider" },
    { id = 4151119, name = "Blackmyst Broom Glider" },
    { id = 4151120, name = "Galeborne Wyrm Glider" },
    { id = 4151121, name = "Mikey Glider" },
    { id = 4151122, name = "Eclipselle Bloom Glider" },
    { id = 4151123, name = "Glazed Frostflower Glider" },
    { id = 4151124, name = "Spirited Veil Glider" },
    { id = 4151125, name = "Celestium Vanguard Glider" },
    { id = 4151126, name = "Arcade VS Glider" },
    { id = 4151127, name = "Eternal Driftwood Glider" },
    { id = 4151128, name = "Lumina Aegis Glider" },
    { id = 4151129, name = "Season Series Hoverboard (2026H1)" },
    { id = 4151130, name = "Nue Glider" },
    { id = 4151131, name = "Imperial Phoenix Glider" },
    { id = 4151132, name = "Bloodwing Raven Glider" },
    { id = 4151133, name = "Dimensional Shift Glider" },
    { id = 4151134, name = "Multiverse Commute Glider" },
    { id = 4151135, name = "SAKAMOTO TARO Glider" },
    { id = 4151138, name = "Crimson Lightning Glider" },
    { id = 4151139, name = "Celestial Cataclysm Glider" },
    { id = 4151140, name = "Starlight Galaxy Glider" },
    { id = 4151141, name = "Cerberus Glider" },
    { id = 4151142, name = "Enchanting Pearl Glider" },
    { id = 4151143, name = "Starlight Galaxy Glider" },
}

local HELMET_LV3_SKINS = {
    -- id = Level 3 skin ID; id2 = matching Level 2 skin ID from the 4.7 dump.
    -- id2 = 0 means no same-name Level 2 counterpart was found in the dump.
    
    { id = 502003, id2 = 0, name = "Spetsnaz Helmet (Lv. 3)" },
	
    { id = 1502003510, id2 = 1502002510, name = "Sacred Grove Helmet (Lv. 3)" },
    { id = 502116, id2 = 0, name = "Spetsnaz Helmet (Lv. 3)" },
    { id = 502118, id2 = 0, name = "Commander Helmet (Lv. 3)" },
    { id = 845003001, id2 = 845002001, name = "Hot Pizza Helmet (Lv. 3)" },
    { id = 912003001, id2 = 912002001, name = "Hot Pizza Helmet (Lv. 3)" },
    { id = 912003025, id2 = 912002025, name = "Winter Guardian Helmet (Lv. 3)" },
    { id = 912003051, id2 = 912002051, name = "Pitch Master Helmet (Lv. 3)" },
    { id = 915003005, id2 = 915002005, name = "The Skulls Helmet (Lv. 3)" },
    { id = 915003019, id2 = 915002019, name = "Navigator Helmet (Lv. 3)" },
    { id = 915003021, id2 = 915002021, name = "Wolfheart Helmet (Lv. 3)" },
    { id = 932003025, id2 = 932002025, name = "Winter Guardian Helmet (Lv. 3)" },
    { id = 935003012, id2 = 935002012, name = "Galactic Helmet (Lv. 3)" },
    { id = 935003017, id2 = 935002017, name = "Lifesaver Helmet (Lv. 3)" },
    { id = 1502003001, id2 = 1502002001, name = "Hot Pizza Helmet (Lv. 3)" },
    { id = 1502003002, id2 = 1502002002, name = "White Rabbit Helmet (Lv. 3)" },
    { id = 1502003005, id2 = 1502002005, name = "The Skulls Helmet (Lv. 3)" },
    { id = 1502003006, id2 = 1502002006, name = "Sanguine Helmet (Lv. 3)" },
    { id = 1502003008, id2 = 1502002008, name = "Winning Chicken Helmet (Lv. 3)" },
    { id = 1502003009, id2 = 1502002009, name = "PUBLING Helmet (Lv. 3)" },
    { id = 1502003012, id2 = 1502002012, name = "Galactic Helmet (Lv. 3)" },
    { id = 1502003013, id2 = 1502002013, name = "Chicken Champion Helmet (Lv. 3)" },
    { id = 1502003014, id2 = 1502002014, name = "Inferno Rider Helmet (Lv. 3)" },
    { id = 1502003015, id2 = 1502002015, name = "Sunflower Helmet (Lv. 3)" },
    { id = 1502003016, id2 = 1502002016, name = "Stegosaurus Helmet (Lv. 3)" },
    { id = 1502003017, id2 = 1502002017, name = "Lifesaver Helmet (Lv. 3)" },
    { id = 1502003018, id2 = 1502002018, name = "Angry Pumpkin Helmet (Lv. 3)" },
    { id = 1502003019, id2 = 1502002019, name = "Navigator Helmet (Lv. 3)" },
    { id = 1502003020, id2 = 1502002020, name = "Happy Pumpkin Helmet (Lv. 3)" },
    { id = 1502003021, id2 = 1502002021, name = "Wolfheart Helmet (Lv. 3)" },
    { id = 1502003022, id2 = 1502002022, name = "Black Magma Helmet (Lv. 3)" },
    { id = 1502003023, id2 = 1502002023, name = "Glacier Helmet (Lv. 3)" },
    { id = 1502003025, id2 = 1502002025, name = "Winter Guardian Helmet (Lv. 3)" },
    { id = 1502003026, id2 = 1502002026, name = "Yeti Helmet (Lv. 3)" },
    { id = 1502003027, id2 = 1502002027, name = "Cuddly Panda Helmet (Lv. 3)" },
    { id = 1502003028, id2 = 1502002028, name = "Scarlet Beast Helmet (Lv. 3)" },
    { id = 1502003029, id2 = 1502002029, name = "Soaring Eagle Helmet (Lv. 3)" },
    { id = 1502003030, id2 = 1502002030, name = "Stylish Santa Helmet (Lv. 3)" },
    { id = 1502003031, id2 = 1502002031, name = "Mutated Helmet (Lv. 3)" },
    { id = 1502003032, id2 = 1502002032, name = "Sinister Skull Helmet (Lv. 3)" },
    { id = 1502003033, id2 = 1502002033, name = "Intergalactic Helmet (Lv. 3)" },
    { id = 1502003034, id2 = 1502002034, name = "Max Drip Helmet (Lv. 3)" },
    { id = 1502003035, id2 = 1502002035, name = "Irradiated Frog Helmet (Lv. 3)" },
    { id = 1502003036, id2 = 1502002036, name = "Cupid Helmet (Lv. 3)" },
    { id = 1502003037, id2 = 1502002037, name = "X Marks the Spot Helmet (Lv. 3)" },
    { id = 1502003038, id2 = 1502002038, name = "Arachnoid Helmet (Lv. 3)" },
    { id = 1502003039, id2 = 1502002039, name = "Dragonling Helmet (Lv. 3)" },
    { id = 1502003040, id2 = 1502002040, name = "Mechanized Helmet (Lv. 3)" },
    { id = 1502003041, id2 = 1502002041, name = "Star Trooper Helmet (Lv. 3)" },
    { id = 1502003042, id2 = 1502002042, name = "Brilliant Anniversary Helmet (Lv. 3)" },
    { id = 1502003043, id2 = 1502002043, name = "Bloodthirsty Fiend Helmet (Lv. 3)" },
    { id = 1502003044, id2 = 1502002044, name = "Decorated Helmet (Lv. 3)" },
    { id = 1502003045, id2 = 1502002045, name = "Mech Rabbit Helmet (Lv. 3)" },
    { id = 1502003046, id2 = 1502002046, name = "Honorable Warrior Helmet (Lv. 3)" },
    { id = 1502003047, id2 = 1502002047, name = "Techno Helmet (Lv. 3)" },
    { id = 1502003048, id2 = 1502002048, name = "Dayman Helmet (Lv. 3)" },
    { id = 1502003049, id2 = 1502002049, name = "Army Men Helmet (Lv. 3)" },
    { id = 1502003050, id2 = 1502002050, name = "Cast Iron Helmet (Lv. 3)" },
    { id = 1502003051, id2 = 1502002051, name = "Pitch Master Helmet (Lv. 3)" },
    { id = 1502003052, id2 = 1502002052, name = "Crimson Fox Helmet (Lv. 3)" },
    { id = 1502003053, id2 = 1502002053, name = "Season 11 Arena Helmet (Lv. 3)" },
    { id = 1502003054, id2 = 1502002054, name = "Ryan Helmet (Lv. 3)" },
    { id = 1502003055, id2 = 1502002055, name = "Pearl Hunter Helmet (Lv. 3)" },
    { id = 1502003058, id2 = 1502002058, name = "Royal Butterfly Helmet (Lv. 3)" },
    { id = 1502003060, id2 = 1502002060, name = "Explorer's Helmet (Lv. 3)" },
    { id = 1502003062, id2 = 1502002062, name = "Radiance Helmet (Lv. 3)" },
    { id = 1502003063, id2 = 1502002063, name = "Bloody Tide Helmet (Lv. 3)" },
    { id = 1502003064, id2 = 1502002064, name = "Winged Helmet (Lv. 3)" },
    { id = 1502003065, id2 = 1502002065, name = "Moon Bunny Helmet (Lv. 3)" },
    { id = 1502003069, id2 = 1502002069, name = "Masked Psychic Helmet (Lv. 3)" },
    { id = 1502003070, id2 = 1502002070, name = "Shining Star Helmet (Lv. 3)" },
    { id = 1502003071, id2 = 1502002071, name = "Past Glory Helmet (Lv. 3)" },
    { id = 1502003072, id2 = 1502002072, name = "Red - Helmet (Lv. 3)" },
    { id = 1502003073, id2 = 1502002073, name = "Cybernetic Guardian Helmet (Lv. 3)" },
    { id = 1502003074, id2 = 1502002074, name = "Snowflake Girl Helmet (Lv. 3)" },
    { id = 1502003075, id2 = 1502002075, name = "Jubilant Baby Seal Helmet (Lv. 3)" },
    { id = 1502003076, id2 = 1502002076, name = "Futuristic Streetwear Helmet (Lv. 3)" },
    { id = 1502003077, id2 = 1502002077, name = "Field Commander Helmet (Lv. 3)" },
    { id = 1502003078, id2 = 1502002078, name = "Forest Ninja Helmet (Lv. 3)" },
    { id = 1502003079, id2 = 1502002079, name = "Blood Lotus Helmet (Lv. 3)" },
    { id = 1502003080, id2 = 1502002080, name = "Sleepy Slug Helmet (Lv. 3)" },
    { id = 1502003081, id2 = 1502002081, name = "The Pummeler Helmet (Lv. 3)" },
    { id = 1502003082, id2 = 1502002082, name = "Sweet Treats Helmet (Lv. 3)" },
    { id = 1502003084, id2 = 1502002084, name = "Golden Eagle Helmet (Lv. 3)" },
    { id = 1502003085, id2 = 1502002085, name = "Armed Hound Helmet (Lv. 3)" },
    { id = 1502003086, id2 = 1502002086, name = "Adorable Mouse Helmet (Lv. 3)" },
    { id = 1502003087, id2 = 1502002087, name = "Arctic Hunter Helmet (Lv. 3)" },
    { id = 1502003088, id2 = 1502002088, name = "Rock 'n' Roll Helmet (Lv. 3)" },
    { id = 1502003089, id2 = 1502002089, name = "Baby Chick Helmet (Lv. 3)" },
    { id = 1502003090, id2 = 1502002090, name = "Pink Demoness Helmet (Lv. 3)" },
    { id = 1502003091, id2 = 1502002091, name = "Naughty Kitty Helmet (Lv. 3)" },
    { id = 1502003092, id2 = 1502002092, name = "Sky Barrier Helmet (Lv. 3)" },
    { id = 1502003093, id2 = 1502002093, name = "Anubian Magistrate Helmet (Lv. 3)" },
    { id = 1502003094, id2 = 1502002094, name = "Plump Strawberry Helmet (Lv. 3)" },
    { id = 1502003096, id2 = 1502002096, name = "Fortune Teller Helmet (Lv. 3)" },
    { id = 1502003097, id2 = 1502002097, name = "Gold Kitten Helmet (Lv. 3)" },
    { id = 1502003098, id2 = 1502002098, name = "Will of Horus Helmet (Lv. 3)" },
    { id = 1502003099, id2 = 1502002099, name = "Puppy Love Helmet (Lv. 3)" },
    { id = 1502003100, id2 = 1502002100, name = "GACKT Helmet (Lv. 3)" },
    { id = 1502003101, id2 = 1502002101, name = "Dazzling Youth Helmet (Lv. 3)" },
    { id = 1502003102, id2 = 1502002102, name = "Bad Apple Helmet (Lv. 3)" },
    { id = 1502003103, id2 = 1502002103, name = "Cuckoo Bird Helmet (Lv. 3)" },
    { id = 1502003104, id2 = 1502002104, name = "Anubis Acolyte Helmet (Lv. 3)" },
    { id = 1502003105, id2 = 1502002105, name = "Stealth Agent Helmet (Lv. 3)" },
    { id = 1502003106, id2 = 1502002106, name = "Rainbow Splash Helmet (Lv. 3)" },
    { id = 1502003107, id2 = 1502002107, name = "Sparkly Universe Helmet (Lv. 3)" },
    { id = 1502003108, id2 = 1502002108, name = "Ragtag Goon Helmet (Lv. 3)" },
    { id = 1502003109, id2 = 1502002109, name = "Lion's Claw Helmet (Lv. 3)" },
    { id = 1502003110, id2 = 1502002110, name = "Podium Placer Helmet (Lv. 3)" },
    { id = 1502003111, id2 = 1502002111, name = "Nightmare Helmet (Lv. 3)" },
    { id = 1502003113, id2 = 1502002113, name = "Rose Unicorn Helmet (Lv. 3)" },
    { id = 1502003114, id2 = 1502002114, name = "Mechforged Helmet (Lv. 3)" },
    { id = 1502003115, id2 = 1502002115, name = "Ladybug Helmet (Lv. 3)" },
    { id = 1502003119, id2 = 1502002119, name = "Persian Warrior Helmet (Lv. 3)" },
    { id = 1502003121, id2 = 1502002121, name = "Waffle Cone Helmet (Lv. 3)" },
    { id = 1502003123, id2 = 1502002123, name = "Sleepy Bear Helmet (Lv. 3)" },
    { id = 1502003124, id2 = 1502002124, name = "Samurai Ops Helmet (Lv. 3)" },
    { id = 1502003125, id2 = 1502002125, name = "Squirrel Helmet (Lv. 3)" },
    { id = 1502003126, id2 = 1502002126, name = "Seductress Helmet (Lv. 3)" },
    { id = 1502003127, id2 = 1502002127, name = "Stars & Stripes Helmet (Lv. 3)" },
    { id = 1502003128, id2 = 1502002128, name = "Gold and Silk Helmet (Lv. 3)" },
    { id = 1502003129, id2 = 1502002129, name = "Violet Wonder Helmet (Lv. 3)" },
    { id = 1502003130, id2 = 1502002130, name = "Officer's Helmet (Lv. 3)" },
    { id = 1502003132, id2 = 1502002132, name = "Castle Helmet (Lv. 3)" },
    { id = 1502003133, id2 = 1502002133, name = "Jack-o'-lantern Helmet (Lv. 3)" },
    { id = 1502003134, id2 = 1502002134, name = "New Year Lion Helmet (Lv. 3)" },
    { id = 1502003135, id2 = 1502002135, name = "Cutie Cream Helmet (Lv. 3)" },
    { id = 1502003136, id2 = 1502002136, name = "Cute Penguin Helmet (Lv. 3)" },
    { id = 1502003137, id2 = 1502002137, name = "Cute Baddie Helmet (Lv. 3)" },
    { id = 1502003138, id2 = 1502002138, name = "Grave Lord Helmet (Lv. 3)" },
    { id = 1502003141, id2 = 1502002141, name = "Tulip Helmet (Lv. 3)" },
    { id = 1502003143, id2 = 1502002143, name = "Dream Idol Helmet (Lv. 3)" },
    { id = 1502003145, id2 = 1502002145, name = "Clockwork Tin Soldier Helmet (Lv. 3)" },
    { id = 1502003146, id2 = 1502002146, name = "Resplendent Dawn Helmet (Lv. 3)" },
    { id = 1502003149, id2 = 1502002149, name = "Lucky Carp Helmet (Lv. 3)" },
    { id = 1502003150, id2 = 1502002150, name = "Acolyte of Justice Helmet (Lv. 3)" },
    { id = 1502003151, id2 = 1502002151, name = "Regal Overlord Helmet (Lv. 3)" },
    { id = 1502003154, id2 = 1502002154, name = "Shining Eagle Helmet (Lv. 3)" },
    { id = 1502003155, id2 = 1502002155, name = "Cactus Sheriff Helmet (Lv. 3)" },
    { id = 1502003156, id2 = 1502002156, name = "Angry Chicken Helmet (Lv. 3)" },
    { id = 1502003157, id2 = 1502002157, name = "Present Helmet (Lv. 3)" },
    { id = 1502003159, id2 = 1502002159, name = "Notes of Affection Helmet (Lv. 3)" },
    { id = 1502003160, id2 = 1502002160, name = "Snow Sakura Helmet (Lv. 3)" },
    { id = 1502003163, id2 = 1502002163, name = "Golden Prince Helmet (Lv. 3)" },
    { id = 1502003164, id2 = 1502002164, name = "Red Battlecat Helmet (Lv. 3)" },
    { id = 1502003165, id2 = 1502002165, name = "Reindog Helmet (Lv. 3)" },
    { id = 1502003167, id2 = 1502002167, name = "Bamboomz Helmet (Lv. 3)" },
    { id = 1502003169, id2 = 1502002169, name = "Crimson Beetle Helmet (Lv. 3)" },
    { id = 1502003170, id2 = 1502002170, name = "Rainbow Unicorn Helmet (Lv. 3)" },
    { id = 1502003171, id2 = 1502002171, name = "Project Idol Helmet (Lv. 3)" },
    { id = 1502003172, id2 = 1502002172, name = "Woolly Dragon Helmet (Lv. 3)" },
    { id = 1502003173, id2 = 1502002173, name = "Ghillie Lion Helmet (Lv. 3)" },
    { id = 1502003174, id2 = 1502002174, name = "Night Ensemble Helmet (Lv. 3)" },
    { id = 1502003175, id2 = 1502002175, name = "B.Duck Helmet (Lv. 3)" },
    { id = 1502003177, id2 = 1502002177, name = "QUACK Agent - Helmet (Lv. 3)" },
    { id = 1502003179, id2 = 1502002179, name = "Iron Tortoise Helmet (Lv. 3)" },
    { id = 1502003180, id2 = 1502002180, name = "Mutant Warlord Helmet (Lv. 3)" },
    { id = 1502003181, id2 = 1502002181, name = "Chromatic Brilliance Helmet (Lv. 3)" },
    { id = 1502003182, id2 = 1502002182, name = "Mecha Ant Helmet (Lv. 3)" },
    { id = 1502003183, id2 = 1502002183, name = "Godzilla Helmet (Lv. 3)" },
    { id = 1502003184, id2 = 1502002184, name = "Masked Wasp Helmet (Lv. 3)" },
    { id = 1502003185, id2 = 1502002185, name = "Mr. Busybee Helmet (Lv. 3)" },
    { id = 1502003186, id2 = 1502002186, name = "Noctus Sovereign Helmet (Lv. 3)" },
    { id = 1502003187, id2 = 1502002187, name = "Cute Bazzi Helmet (Lv. 3)" },
    { id = 1502003189, id2 = 1502002189, name = "Belligerent Fiend Helmet (Lv. 3)" },
    { id = 1502003190, id2 = 1502002190, name = "Cyber Monkey Helmet (Lv. 3)" },
    { id = 1502003191, id2 = 1502002191, name = "Azure Warrior - Helmet (Lv. 3)" },
    { id = 1502003192, id2 = 1502002192, name = "Sally Helmet (Lv. 3)" },
    { id = 1502003193, id2 = 1502002193, name = "Cool Rebel Helmet (Lv. 3)" },
    { id = 1502003194, id2 = 1502002194, name = "MECHAGODZILLA Helmet (Lv. 3)" },
    { id = 1502003195, id2 = 1502002195, name = "Tidal Wargod Helmet (Lv. 3)" },
    { id = 1502003196, id2 = 1502002196, name = "Chrono Cyborg Helmet (Lv. 3)" },
    { id = 1502003197, id2 = 1502002197, name = "I SEE YOU Helmet (Lv. 3)" },
    { id = 1502003198, id2 = 1502002198, name = "Magic Adventure Helmet (Lv. 3)" },
    { id = 1502003199, id2 = 1502002199, name = "Alloy Conqueror Helmet (Lv. 3)" },
    { id = 1502003200, id2 = 1502002200, name = "Coral Beasts Helmet (Lv. 3)" },
    { id = 1502003201, id2 = 1502002201, name = "Emerald Punk Helmet (Lv. 3)" },
    { id = 1502003202, id2 = 1502002202, name = "Cosmic Probe Helmet (Lv. 3)" },
    { id = 1502003203, id2 = 1502002203, name = "Techno Beast Helmet (Lv. 3)" },
    { id = 1502003204, id2 = 1502002204, name = "BUG Helmet (Lv. 3)" },
    { id = 1502003205, id2 = 1502002205, name = "Extreme Diver Helmet (Lv. 3)" },
    { id = 1502003207, id2 = 1502002207, name = "Lobster Avenger Helmet (Lv. 3)" },
    { id = 1502003209, id2 = 1502002209, name = "Scarecrow Minstrel Helmet (Lv. 3)" },
    { id = 1502003210, id2 = 1502002210, name = "Cupcake Cutie Helmet (Lv. 3)" },
    { id = 1502003211, id2 = 1502002211, name = "Urban Assassin Helmet (Lv. 3)" },
    { id = 1502003214, id2 = 1502002214, name = "Wild Frontier Helmet (Lv. 3)" },
    { id = 1502003217, id2 = 1502002217, name = "Festive Moments Helmet (Lv. 3)" },
    { id = 1502003219, id2 = 1502002219, name = "Winner Dinner Helmet (Lv. 3)" },
    { id = 1502003220, id2 = 1502002220, name = "Jolly Festival Helmet (Lv. 3)" },
    { id = 1502003221, id2 = 1502002221, name = "Aureate Assassin Helmet (Lv. 3)" },
    { id = 1502003222, id2 = 1502002222, name = "Majestic Cavalry Helmet (Lv. 3)" },
    { id = 1502003223, id2 = 1502002223, name = "Gold Porcelain Helmet (Lv. 3)" },
    { id = 1502003224, id2 = 1502002224, name = "Fairyland Helmet (Lv. 3)" },
    { id = 1502003225, id2 = 1502002225, name = "Savage Treant Helmet (Lv. 3)" },
    { id = 1502003227, id2 = 1502002227, name = "Shimmer Power Helmet (Lv. 3)" },
    { id = 1502003228, id2 = 1502002228, name = "Winter Fantasy - Helmet (Lv. 3)" },
    { id = 1502003229, id2 = 1502002229, name = "Joyful Kitten Helmet (Lv. 3)" },
    { id = 1502003230, id2 = 1502002230, name = "Mech Dragon Helmet (Lv. 3)" },
    { id = 1502003231, id2 = 1502002231, name = "Slime Tech Helmet (Lv. 3)" },
    { id = 1502003232, id2 = 1502002232, name = "Bunny Friends Helmet (Lv. 3)" },
    { id = 1502003233, id2 = 1502002233, name = "Winter Bunny Helmet (Lv. 3)" },
    { id = 1502003234, id2 = 1502002234, name = "Sweet Cub Helmet (Lv. 3)" },
    { id = 1502003235, id2 = 1502002235, name = "Baby Dragon Helmet (Lv. 3)" },
    { id = 1502003236, id2 = 1502002236, name = "Baby Parrot Helmet (Lv. 3)" },
    { id = 1502003237, id2 = 1502002237, name = "Roguish Imp Helmet (Lv. 3)" },
    { id = 1502003238, id2 = 1502002238, name = "Elite Helmet (Lv. 3)" },
    { id = 1502003239, id2 = 1502002239, name = "Mystic Artificer Helmet (Lv. 3)" },
    { id = 1502003241, id2 = 1502002241, name = "Nocturnal Rhapsody Helmet (Lv. 3)" },
    { id = 1502003242, id2 = 1502002242, name = "Gackt Moon Helmet (Lv. 3)" },
    { id = 1502003243, id2 = 1502002243, name = "Honey Jar Helmet (Lv. 3)" },
    { id = 1502003244, id2 = 1502002244, name = "Urban Ogre Helmet (Lv. 3)" },
    { id = 1502003246, id2 = 1502002246, name = "Tribal Warfare Helmet (Lv. 3)" },
    { id = 1502003247, id2 = 1502002247, name = "Green Age Helmet (Lv. 3)" },
    { id = 1502003248, id2 = 1502002248, name = "Clockwork Helmet (Lv. 3)" },
    { id = 1502003249, id2 = 1502002249, name = "Voracious Trapper Helmet (Lv. 3)" },
    { id = 1502003252, id2 = 1502002252, name = "Forged Vigilante Helmet (Lv. 3)" },
    { id = 1502003253, id2 = 1502002253, name = "Valorian Helmet (Lv. 3)" },
    { id = 1502003254, id2 = 1502002254, name = "Jelly Bear Helmet (Lv. 3)" },
    { id = 1502003255, id2 = 1502002255, name = "Cheeky Cat Helmet (Lv. 3)" },
    { id = 1502003256, id2 = 1502002256, name = "Ursa Hunter Helmet (Lv. 3)" },
    { id = 1502003257, id2 = 1502002257, name = "Ornate Engraving Helmet (Lv. 3)" },
    { id = 1502003258, id2 = 1502002258, name = "Baby Shark Helmet (Lv. 3)" },
    { id = 1502003259, id2 = 1502002259, name = "Vibrant Celebration Helmet (Lv. 3)" },
    { id = 1502003260, id2 = 1502002260, name = "Clockwork Defender Helmet (Lv. 3)" },
    { id = 1502003261, id2 = 1502002261, name = "Atlantic Tech Helmet (Lv. 3)" },
    { id = 1502003263, id2 = 1502002263, name = "Wild Rave Helmet (Lv. 3)" },
    { id = 1502003264, id2 = 1502002264, name = "SOS Voyager Helmet (Lv. 3)" },
    { id = 1502003265, id2 = 1502002265, name = "Pumpkin Throne Helmet (Lv. 3)" },
    { id = 1502003267, id2 = 1502002267, name = "Glorious Ruins Helmet (Lv. 3)" },
    { id = 1502003268, id2 = 1502002268, name = "Donkey Party Helmet (Lv. 3)" },
    { id = 1502003269, id2 = 1502002269, name = "Pink Parrot Helmet (Lv. 3)" },
    { id = 1502003270, id2 = 1502002270, name = "Golden Guard Helmet (Lv. 3)" },
    { id = 1502003271, id2 = 1502002271, name = "Clan Defender Helmet (Lv. 3)" },
    { id = 1502003272, id2 = 1502002272, name = "Mystic Battle Helmet (Lv. 3)" },
    { id = 1502003273, id2 = 1502002273, name = "Radiation Trooper Helmet (Lv. 3)" },
    { id = 1502003274, id2 = 1502002274, name = "Royal Artisan Helmet (Lv. 3)" },
    { id = 1502003275, id2 = 1502002275, name = "Ultimate Trendsetter Helmet (Lv. 3)" },
    { id = 1502003276, id2 = 1502002276, name = "Mysterious Dancer Helmet (Lv. 3)" },
    { id = 1502003277, id2 = 1502002277, name = "Exploding Ape Helmet (Lv. 3)" },
    { id = 1502003278, id2 = 1502002278, name = "Evangelion-01 Helmet (Lv. 3)" },
    { id = 1502003279, id2 = 1502002279, name = "Gojek Driver Helmet (Lv. 3)" },
    { id = 1502003280, id2 = 1502002280, name = "Bony Bunny Helmet (Lv. 3)" },
    { id = 1502003284, id2 = 1502002284, name = "FM/AM Helmet (Lv. 3)" },
    { id = 1502003285, id2 = 1502002285, name = "Magical Night Helmet (Lv. 3)" },
    { id = 1502003286, id2 = 1502002286, name = "Markhor Helmet (Lv. 3)" },
    { id = 1502003287, id2 = 1502002287, name = "First Love Helmet (Lv. 3)" },
    { id = 1502003288, id2 = 1502002288, name = "Final Happiness Helmet (Lv. 3)" },
    { id = 1502003289, id2 = 1502002289, name = "Movie Night Helmet (Lv. 3)" },
    { id = 1502003290, id2 = 1502002290, name = "Beat Pirate Helmet (Lv. 3)" },
    { id = 1502003292, id2 = 1502002292, name = "Royal Apparel Helmet (Lv. 3)" },
    { id = 1502003293, id2 = 1502002293, name = "Hiemal Shadows Helmet (Lv. 3)" },
    { id = 1502003294, id2 = 1502002294, name = "Court Sorcerer Helmet (Lv. 3)" },
    { id = 1502003295, id2 = 1502002295, name = "Nebula Trail Helmet (Lv. 3)" },
    { id = 1502003297, id2 = 1502002297, name = "Dino Trooper Helmet (Lv. 3)" },
    { id = 1502003298, id2 = 1502002298, name = "Eternal Kingdom Helmet (Lv. 3)" },
    { id = 1502003299, id2 = 1502002299, name = "Supernova Helmet (Lv. 3)" },
    { id = 1502003300, id2 = 1502002300, name = "Exalted Warrior Helmet (Lv. 3)" },
    { id = 1502003301, id2 = 1502002301, name = "Illustrious Archon Helmet (Lv. 3)" },
    { id = 1502003302, id2 = 1502002302, name = "Lethal Code Helmet (Lv. 3)" },
    { id = 1502003305, id2 = 1502002305, name = "Steel Morpher Helmet (Lv. 3)" },
    { id = 1502003306, id2 = 1502002306, name = "Galactic Adventure Helmet (Lv. 3)" },
    { id = 1502003307, id2 = 1502002307, name = "BoBoiBoy Helmet (Lv. 3)" },
    { id = 1502003309, id2 = 1502002309, name = "Magical Flora Helmet (Lv. 3)" },
    { id = 1502003311, id2 = 1502002311, name = "Blood Sucker Helmet (Lv. 3)" },
    { id = 1502003314, id2 = 1502002314, name = "Imperial Enforcer Helmet (Lv. 3)" },
    { id = 1502003315, id2 = 1502002315, name = "Floral Snowflake Helmet (Lv. 3)" },
    { id = 1502003317, id2 = 1502002317, name = "Spec Ops Captain Helmet (Lv. 3)" },
    { id = 1502003320, id2 = 1502002320, name = "Messi Football Icon Helmet (Lv. 3)" },
    { id = 1502003322, id2 = 1502002322, name = "Honored Chieftain Helmet (Lv. 3)" },
    { id = 1502003323, id2 = 1502002323, name = "Royal Orchestrion Helmet (Lv. 3)" },
    { id = 1502003325, id2 = 1502002325, name = "Tide Sentinel Helmet (Lv. 3)" },
    { id = 1502003327, id2 = 1502002327, name = "Magma Skull Helmet (Lv. 3)" },
    { id = 1502003328, id2 = 1502002328, name = "Violet Feather Helmet (Lv. 3)" },
    { id = 1502003330, id2 = 1502002330, name = "Cardboard Kraken Helmet (Lv. 3)" },
    { id = 1502003332, id2 = 1502002332, name = "Rising Rebel Helmet (Lv. 3)" },
    { id = 1502003333, id2 = 1502002333, name = "Auric Sentinel Helmet (Lv. 3)" },
    { id = 1502003335, id2 = 1502002335, name = "Minimalist Tech Helmet (Lv. 3)" },
    { id = 1502003336, id2 = 1502002336, name = "Dragon Guard Helmet (Lv. 3)" },
    { id = 1502003337, id2 = 1502002337, name = "Cheeky Teddy Helmet (Lv. 3)" },
    { id = 1502003338, id2 = 1502002338, name = "Purple Frenzy Helmet (Lv. 3)" },
    { id = 1502003339, id2 = 1502002339, name = "Pan Pan Helmet (Lv. 3)" },
    { id = 1502003341, id2 = 1502002341, name = "Harlequin Helmet (Lv. 3)" },
    { id = 1502003342, id2 = 1502002342, name = "Moondrop Eterna Helmet (Lv. 3)" },
    { id = 1502003343, id2 = 1502002343, name = "Cucumber Genius Helmet (Lv. 3)" },
    { id = 1502003344, id2 = 1502002344, name = "Crimson Agenda Helmet (Lv. 3)" },
    { id = 1502003345, id2 = 1502002345, name = "Crimson Storm Helmet (Lv. 3)" },
    { id = 1502003346, id2 = 1502002346, name = "Vitatech Helmet (Lv. 3)" },
    { id = 1502003347, id2 = 1502002347, name = "Clever Dino Helmet (Lv. 3)" },
    { id = 1502003348, id2 = 1502002348, name = "Chomper Helmet (Lv. 3)" },
    { id = 1502003349, id2 = 1502002349, name = "Crimson Ephialtes Helmet (Lv. 3)" },
    { id = 1502003350, id2 = 1502002350, name = "Noctum Sunder Helmet (Lv. 3)" },
    { id = 1502003351, id2 = 1502002351, name = "Golden Reaper Helmet (Lv. 3)" },
    { id = 1502003352, id2 = 1502002352, name = "DJ Vibe Helmet (Lv. 3)" },
    { id = 1502003353, id2 = 1502002353, name = "Quick Wits Helmet (Lv. 3)" },
    { id = 1502003354, id2 = 1502002354, name = "Cap'n Feathers Helmet (Lv. 3)" },
    { id = 1502003355, id2 = 1502002355, name = "Rainbow Blitz Helmet (Lv. 3)" },
    { id = 1502003357, id2 = 1502002357, name = "Son Goku Helmet (Lv. 3)" },
    { id = 1502003358, id2 = 1502002358, name = "Aurora Diva Helmet (Lv. 3)" },
    { id = 1502003359, id2 = 1502002359, name = "Ghastly Gloom Helmet (Lv. 3)" },
    { id = 1502003360, id2 = 1502002360, name = "Pastel Puff Helmet (Lv. 3)" },
    { id = 1502003361, id2 = 1502002361, name = "Neuro Dynamo Helmet (Lv. 3)" },
    { id = 1502003362, id2 = 1502002362, name = "Conch Tech Helmet (Lv. 3)" },
    { id = 1502003363, id2 = 1502002363, name = "Bone Survivor Helmet (Lv. 3)" },
    { id = 1502003364, id2 = 1502002364, name = "2023 PMGC Helmet (Lv. 3)" },
    { id = 1502003365, id2 = 1502002365, name = "Swift Scarlet Helmet (Lv. 3)" },
    { id = 1502003367, id2 = 1502002367, name = "Devoted Defender Helmet (Lv. 3)" },
    { id = 1502003368, id2 = 1502002368, name = "Fiestafolk Helmet (Lv. 3)" },
    { id = 1502003369, id2 = 1502002369, name = "Panda Sweetie Helmet (Lv. 3)" },
    { id = 1502003370, id2 = 1502002370, name = "Dracostride Helmet (Lv. 3)" },
    { id = 1502003371, id2 = 1502002371, name = "Lion Reign Helmet (Lv. 3)" },
    { id = 1502003372, id2 = 1502002372, name = "Sonicshock Helmet (Lv. 3)" },
    { id = 1502003373, id2 = 1502002373, name = "LINE FRIENDS BROWN Helmet (Lv. 3)" },
    { id = 1502003374, id2 = 1502002374, name = "Inkstripe Tiger Helmet (Lv. 3)" },
    { id = 1502003375, id2 = 1502002375, name = "Floral Bear Helmet (Lv. 3)" },
    { id = 1502003376, id2 = 1502002376, name = "Kitsune Omen Helmet (Lv. 3)" },
    { id = 1502003377, id2 = 1502002377, name = "Phantom Luster Helmet (Lv. 3)" },
    { id = 1502003378, id2 = 1502002378, name = "Striped Sweetheart Helmet (Lv. 3)" },
    { id = 1502003379, id2 = 1502002379, name = "Auric Guardian Helmet (Lv. 3)" },
    { id = 1502003381, id2 = 1502002381, name = "Ignis Helmet (Lv. 3)" },
    { id = 1502003382, id2 = 1502002382, name = "Magick Delight Helmet (Lv. 3)" },
    { id = 1502003383, id2 = 1502002383, name = "Gallant Jockey Helmet (Lv. 3)" },
    { id = 1502003384, id2 = 1502002384, name = "Bygone Realm Helmet (Lv. 3)" },
    { id = 1502003385, id2 = 1502002385, name = "Mech Hero Helmet (Lv. 3)" },
    { id = 1502003386, id2 = 1502002386, name = "Melodic Feline Helmet (Lv. 3)" },
    { id = 1502003387, id2 = 1502002387, name = "Squeakology Helmet (Lv. 3)" },
    { id = 1502003388, id2 = 1502002388, name = "Wasteland Samurai Helmet (Lv. 3)" },
    { id = 1502003389, id2 = 1502002389, name = "Shrine Keeper Helmet (Lv. 3)" },
    { id = 1502003390, id2 = 1502002390, name = "Lover's Barrier Helmet (Lv. 3)" },
    { id = 1502003391, id2 = 1502002391, name = "Dr. Quirk Helmet (Lv. 3)" },
    { id = 1502003392, id2 = 1502002392, name = "Bio Scout Helmet (Lv. 3)" },
    { id = 1502003393, id2 = 1502002393, name = "Soundwave Beast Helmet (Lv. 3)" },
    { id = 1502003394, id2 = 1502002394, name = "Shadow Empress Helmet (Lv. 3)" },
    { id = 1502003395, id2 = 1502002395, name = "Night Maiden Helmet (Lv. 3)" },
    { id = 1502003396, id2 = 1502002396, name = "Lieutenant Chaos Helmet (Lv. 3)" },
    { id = 1502003397, id2 = 1502002397, name = "Galadria Helmet (Lv. 3)" },
    { id = 1502003398, id2 = 1502002398, name = "Rippling Charm Helmet (Lv. 3)" },
    { id = 1502003399, id2 = 1502002399, name = "Magical Flora Helmet (Lv. 3)" },
    { id = 1502003400, id2 = 1502002400, name = "Moody Clownfish Helmet (Lv. 3)" },
    { id = 1502003401, id2 = 1502002401, name = "Spiny Bite Helmet (Lv. 3)" },
    { id = 1502003404, id2 = 1502002404, name = "Manic Bunny Helmet (Lv. 3)" },
    { id = 1502003405, id2 = 1502002405, name = "Chaos Academy Helmet (Lv. 3)" },
    { id = 1502003406, id2 = 1502002406, name = "Heart Warden Helmet (Lv. 3)" },
    { id = 1502003407, id2 = 1502002407, name = "Lightcore Helmet (Lv. 3)" },
    { id = 1502003408, id2 = 1502002408, name = "Piercing Fang Helmet (Lv. 3)" },
    { id = 1502003409, id2 = 1502002409, name = "Cosmic Beast Helmet (Lv. 3)" },
    { id = 1502003410, id2 = 1502002410, name = "Feral Ravager Helmet (Lv. 3)" },
    { id = 1502003411, id2 = 1502002411, name = "Spirit Sentry Helmet (Lv. 3)" },
    { id = 1502003412, id2 = 1502002412, name = "Underworld Aristocrat Helmet (Lv. 3)" },
    { id = 1502003413, id2 = 1502002413, name = "Quasar Clan Helmet (Lv. 3)" },
    { id = 1502003414, id2 = 1502002414, name = "Winter Warrior Helmet (Lv. 3)" },
    { id = 1502003415, id2 = 1502002415, name = "Hypernova Fission Helmet (Lv. 3)" },
    { id = 1502003416, id2 = 1502002416, name = "2024 PMGC Helmet (Lv. 3)" },
    { id = 1502003417, id2 = 1502002417, name = "Penguin Pal Helmet (Lv. 3)" },
    { id = 1502003418, id2 = 1502002418, name = "Wintry Aegis Helmet (Lv. 3)" },
    { id = 1502003419, id2 = 1502002419, name = "Blue Bewitchment Helmet (Lv. 3)" },
    { id = 1502003421, id2 = 1502002421, name = "Dreamy Koi Helmet (Lv. 3)" },
    { id = 1502003422, id2 = 1502002422, name = "New Age Channeler Helmet (Lv. 3)" },
    { id = 1502003423, id2 = 1502002423, name = "Dragontide Pulse Helmet (Lv. 3)" },
    { id = 1502003424, id2 = 1502002424, name = "Prowling Lion Head Helmet (Lv. 3)" },
    { id = 1502003425, id2 = 1502002425, name = "Inky Allure Helmet (Lv. 3)" },
    { id = 1502003426, id2 = 1502002426, name = "Elysian Bloom Helmet (Lv. 3)" },
    { id = 1502003428, id2 = 1502002428, name = "Netherbound Rider Helmet (Lv. 3)" },
    { id = 1502003429, id2 = 1502002429, name = "Ecliptic Guardian Helmet (Lv. 3)" },
    { id = 1502003430, id2 = 1502002430, name = "Lazy Chomper Helmet (Lv. 3)" },
    { id = 1502003431, id2 = 1502002431, name = "Godzilla Chomp Helmet (Lv. 3)" },
    { id = 1502003432, id2 = 1502002432, name = "Foxie Moxie Helmet (Lv. 3)" },
    { id = 1502003433, id2 = 1502002433, name = "Sinister Bunny Helmet (Lv. 3)" },
    { id = 1502003434, id2 = 1502002434, name = "Goldensands Sentry Helmet (Lv. 3)" },
    { id = 1502003435, id2 = 1502002435, name = "Galvanic Judge Helmet (Lv. 3)" },
    { id = 1502003436, id2 = 1502002436, name = "Clockwork Pal Helmet (Lv. 3)" },
    { id = 1502003437, id2 = 1502002437, name = "Caramel Cat Helmet (Lv. 3)" },
    { id = 1502003438, id2 = 1502002438, name = "Chemical Clash Helmet (Lv. 3)" },
    { id = 1502003439, id2 = 1502002439, name = "Auric Reign Helmet (Lv. 3)" },
    { id = 1502003440, id2 = 1502002440, name = "War Hammer Titan Helmet (Lv. 3)" },
    { id = 1502003441, id2 = 1502002441, name = "Deepsea Maw Helmet (Lv. 3)" },
    { id = 1502003442, id2 = 1502002442, name = "Steamwork Artisan Helmet (Lv. 3)" },
    { id = 1502003443, id2 = 1502002443, name = "Waveform Frenzy Helmet (Lv. 3)" },
    { id = 1502003445, id2 = 1502002445, name = "Graviton Sentinel Helmet (Lv. 3)" },
    { id = 1502003446, id2 = 1502002446, name = "Astral Anomaly Helmet (Lv. 3)" },
    { id = 1502003447, id2 = 1502002447, name = "Goldline Ace Helmet (Lv. 3)" },
    { id = 1502003448, id2 = 1502002448, name = "Draconic Aegis Helmet (Lv. 3)" },
    { id = 1502003449, id2 = 1502002449, name = "Nebula Valkyrie Helmet (Lv. 3)" },
    { id = 1502003450, id2 = 1502002450, name = "Captain Woof Helmet (Lv. 3)" },
    { id = 1502003451, id2 = 1502002451, name = "Luminarch Watcher Helmet (Lv. 3)" },
    { id = 1502003453, id2 = 1502002453, name = "2025 Esports Helmet (Lv. 3)" },
    { id = 1502003454, id2 = 1502002454, name = "Ribclad Reaper Helmet (Lv. 3)" },
    { id = 1502003455, id2 = 1502002455, name = "Saccharine Riot Helmet (Lv. 3)" },
    { id = 1502003456, id2 = 1502002456, name = "Graffiti Vandal Helmet (Lv. 3)" },
    { id = 1502003457, id2 = 1502002457, name = "Kaiju No. 8 Helmet (Lv. 3)" },
    { id = 1502003458, id2 = 1502002458, name = "Nebulight Drift Helmet (Lv. 3)" },
    { id = 1502003459, id2 = 1502002459, name = "Havoc Horns Helmet (Lv. 3)" },
    { id = 1502003460, id2 = 1502002460, name = "Madcap Punk Helmet (Lv. 3)" },
    { id = 1502003461, id2 = 1502002461, name = "Chromacore Pulse Helmet (Lv. 3)" },
    { id = 1502003462, id2 = 1502002462, name = "Spectral Dreamweaver Helmet (Lv. 3)" },
    { id = 1502003463, id2 = 1502002463, name = "Chocobear Delight Helmet (Lv. 3)" },
    { id = 1502003464, id2 = 1502002464, name = "Snowward Stranger Helmet (Lv. 3)" },
    { id = 1502003465, id2 = 1502002465, name = "Yarn Beast Helmet (Lv. 3)" },
    { id = 1502003466, id2 = 1502002466, name = "Faux Fur Helmet (Lv. 3)" },
    { id = 1502003467, id2 = 1502002467, name = "Whiteout Apex Helmet (Lv. 3)" },
    { id = 1502003468, id2 = 1502002468, name = "Blizzard Party Helmet (Lv. 3)" },
    { id = 1502003469, id2 = 1502002469, name = "Polar Wonderland Helmet (Lv. 3)" },
    { id = 1502003470, id2 = 1502002470, name = "Snowfeather Sapphire Helmet (Lv. 3)" },
    { id = 1502003471, id2 = 1502002471, name = "Turbo Granny(Beckoning cat) Helmet (Lv. 3)" },
    { id = 1502003472, id2 = 1502002472, name = "Spirited Veil Helmet (Lv. 3)" },
    { id = 1502003473, id2 = 1502002473, name = "Noh Mask Ninja Helmet (Lv. 3)" },
    { id = 1502003474, id2 = 1502002474, name = "Panda Darling Helmet (Lv. 3)" },
    { id = 1502003475, id2 = 1502002475, name = "Dune Prince Helmet (Lv. 3)" },
    { id = 1502003476, id2 = 1502002476, name = "Arcade KO Helmet (Lv. 3)" },
    { id = 1502003477, id2 = 1502002477, name = "Jade Viper Helmet (Lv. 3)" },
    { id = 1502003478, id2 = 1502002478, name = "Fragmented Moon Helmet (Lv. 3)" },
    { id = 1502003479, id2 = 1502002479, name = "Lotus Koi Helmet (Lv. 3)" },
    { id = 1502003480, id2 = 1502002480, name = "PUBG MOBILE × aespa Helmet (Lv. 3)" },
    { id = 1502003481, id2 = 1502002481, name = "CrankGuard Helmet (Lv. 3)" },
    { id = 1502003482, id2 = 1502002482, name = "S28 Helmet (Lv. 3)" },
    { id = 1502003483, id2 = 1502002483, name = "Jester's Gambit Helmet (Lv. 3)" },
    { id = 1502003484, id2 = 1502002484, name = "Gilded Beetle Helmet (Lv. 3)" },
    { id = 1502003485, id2 = 1502002485, name = "Punk Vanguard Helmet (Lv. 3)" },
    { id = 1502003486, id2 = 1502002486, name = "Jogo Helmet (Lv. 3)" },
    { id = 1502003487, id2 = 1502002487, name = "Dynamic Realm Helmet (Lv. 3)" },
    { id = 1502003488, id2 = 1502002488, name = "Colorburst Helmet (Lv. 3)" },
    { id = 1502003489, id2 = 1502002489, name = "Charming Defender Helmet (Lv. 3)" },
    { id = 1502003491, id2 = 1502002491, name = "S29 Helmet (Lv. 3)" },
    { id = 1502003492, id2 = 1502002492, name = "Mirage Phantom Helmet (Lv. 3)" },
    { id = 1502003493, id2 = 1502002493, name = "Queen of Suits Helmet (Lv. 3)" },
    { id = 1502003494, id2 = 1502002494, name = "Legendary Noble Helmet (Lv. 3)" },
    { id = 1502003495, id2 = 1502002495, name = "Jigsaw Puzzle Helmet (Lv. 3)" },
    { id = 1502003496, id2 = 1502002496, name = "Speed Rush Helmet (Lv. 3)" },
    { id = 1502003497, id2 = 1502002497, name = "Dioscuri Helmet (Lv. 3)" },
    { id = 1502003498, id2 = 1502002498, name = "Serpent Handler Helmet (Lv. 3)" },
    { id = 1502003499, id2 = 1502002499, name = "Bloodfeather Spartan Helmet (Lv. 3)" },
    { id = 1502003500, id2 = 1502002500, name = "Laurel Academy Helmet (Lv. 3)" },
    { id = 1502003501, id2 = 1502002501, name = "Field Frenzy Helmet (Lv. 3)" },
    { id = 1502003502, id2 = 1502002502, name = "Lightning Visor Helmet (Lv. 3)" },
    { id = 1502003503, id2 = 1502002503, name = "Psionic Electrobolt Helmet (Lv. 3)" },
    { id = 1502003504, id2 = 1502002504, name = "S30 Helmet (Lv. 3)" },
    { id = 1502003505, id2 = 1502002505, name = "Cybernetic Samurai Helmet (Lv. 3)" },
    { id = 1502003506, id2 = 1502002506, name = "Nightfall Stalker Helmet (Lv. 3)" },
    { id = 1502003507, id2 = 1502002507, name = "Pink Bunny Cadet Helmet (Lv. 3)" },
    { id = 1502003508, id2 = 1502002508, name = "Pakkun Helmet (Lv. 3)" },
    { id = 1502003509, id2 = 1502002509, name = "Sakura Neko Helmet (Lv. 3)" },
    { id = 1502003510, id2 = 1502002510, name = "Sacred Grove Helmet (Lv. 3)" },
    { id = 1502003511, id2 = 1502002511, name = "Wave Cascade Helmet (Lv. 3)" },
    { id = 1502003512, id2 = 1502002512, name = "Dimension Guardian Helmet (Lv. 3)" },
    { id = 1502003514, id2 = 1502002514, name = "999HUMANITY Helmet (Lv. 3)" },
    { id = 1502003516, id2 = 1502002516, name = "Midnight Thorns Helmet (Lv. 3)" },
    { id = 1502003517, id2 = 1502002517, name = "Shiba Explorer Helmet (Lv. 3)" },
    { id = 1502003518, id2 = 1502002518, name = "Saitama Helmet (Lv. 3)" },
    { id = 1502003519, id2 = 1502002519, name = "Metropia Hunter Helmet (Lv. 3)" },
    { id = 1502003520, id2 = 1502002520, name = "Chroma Frontline Helmet (Lv. 3)" },
    { id = 1502003521, id2 = 1502002521, name = "B.Duck Ducky Royale Helmet (Lv. 3)" },
    { id = 1502003522, id2 = 1502002522, name = "Orbital Rider Helmet (Lv. 3)" },
    { id = 1502003523, id2 = 1502002523, name = "Scorpius Gem Helmet (Lv. 3)" },
    { id = 1502003524, id2 = 1502002524, name = "Annihilation Pact Helmet (Lv. 3)" },
    { id = 1502003525, id2 = 1502002525, name = "Nightrose Aegis Helmet (Lv. 3)" },
    { id = 1502003527, id2 = 1502002527, name = "S32 Helmet (Lv. 3)" },
}

local BACKPACK_LV3_SKINS = {
    -- id = Level 3 skin ID; id2 = matching Level 2 skin ID from the 4.7 dump.
    -- id2 = 0 means no Level-2 counterpart was found in the dump.
    
	
    { id = 844003001, id2 = 844002001, name = "Hot Pizza Backpack (Lv. 3)" },
	{ id = 1501003741, id2 = 1501002741, name = "Sanctuary Traveler Backpack (Lv. 3)" },
    { id = 844003003, id2 = 844002003, name = "Skeleton Hand Backpack (Lv. 3)" },
    { id = 844003011, id2 = 844002011, name = "Winning Chicken Backpack (Lv. 3)" },
    { id = 844003012, id2 = 844002012, name = "Rock Star Backpack (Lv. 3)" },
    { id = 844003013, id2 = 844002013, name = "Rose Backpack (Lv. 3)" },
    { id = 844004018, id2 = 844003018, name = "Time Traveler Backpack (Lv. 3)" },
    { id = 911003007, id2 = 911002007, name = "The Skulls Backpack (Lv. 3)" },
    { id = 911003013, id2 = 911002013, name = "Rose Backpack (Lv. 3)" },
    { id = 911003033, id2 = 911002033, name = "Meadows Backpack (Lv. 3)" },
    { id = 911004002, id2 = 911003002, name = "White Rabbit Backpack (Lv. 3)" },
    { id = 911005009, id2 = 911003009, name = "Cobalt Storm Backpack (Lv. 3)" },
    { id = 914003003, id2 = 914002003, name = "Skeleton Hand Backpack (Lv. 3)" },
    { id = 914003006, id2 = 914002006, name = "Circus Backpack (Lv. 3)" },
    { id = 914003011, id2 = 914002011, name = "Winning Chicken Backpack (Lv. 3)" },
    { id = 914003012, id2 = 914002012, name = "Rock Star Backpack (Lv. 3)" },
    { id = 914003014, id2 = 914002014, name = "Drifter Backpack (Lv. 3)" },
    { id = 914003016, id2 = 914002016, name = "Lifesaver Backpack (Lv. 3)" },
    { id = 914004017, id2 = 914003017, name = "Swordsman Backpack (Lv. 3)" },
    { id = 914004018, id2 = 914003018, name = "Time Traveler Backpack (Lv. 3)" },
    { id = 931003033, id2 = 931002033, name = "Meadows Backpack (Lv. 3)" },
    { id = 934003002, id2 = 934002002, name = "White Rabbit Backpack (Lv. 3)" },
    { id = 934003009, id2 = 934002009, name = "Cobalt Storm Backpack (Lv. 3)" },
    { id = 934003012, id2 = 934002012, name = "Rock Star Backpack (Lv. 3)" },
    { id = 934003016, id2 = 934002016, name = "Lifesaver Backpack (Lv. 3)" },
    { id = 934003017, id2 = 934002017, name = "Swordsman Backpack (Lv. 3)" },
    { id = 934003018, id2 = 934002018, name = "Time Traveler Backpack (Lv. 3)" },
    { id = 1501003001, id2 = 1501002001, name = "Hot Pizza Backpack (Lv. 3)" },
    { id = 1501003002, id2 = 1501002002, name = "White Rabbit Backpack (Lv. 3)" },
    { id = 1501003003, id2 = 1501002003, name = "Skeleton Hand Backpack (Lv. 3)" },
    { id = 1501003006, id2 = 1501002006, name = "Circus Backpack (Lv. 3)" },
    { id = 1501003007, id2 = 1501002007, name = "The Skulls Backpack (Lv. 3)" },
    { id = 1501003008, id2 = 1501002008, name = "Red & Black Backpack (Lv. 3)" },
    { id = 1501003009, id2 = 1501002009, name = "Cobalt Storm Backpack (Lv. 3)" },
    { id = 1501003011, id2 = 1501002011, name = "Winning Chicken Backpack (Lv. 3)" },
    { id = 1501003012, id2 = 1501002012, name = "Rock Star Backpack (Lv. 3)" },
    { id = 1501003013, id2 = 1501002013, name = "Rose Backpack (Lv. 3)" },
    { id = 1501003014, id2 = 1501002014, name = "Drifter Backpack (Lv. 3)" },
    { id = 1501003015, id2 = 1501002015, name = "Pink Bear Backpack (Lv. 3)" },
    { id = 1501003016, id2 = 1501002016, name = "Lifesaver Backpack (Lv. 3)" },
    { id = 1501003017, id2 = 1501002017, name = "Swordsman Backpack (Lv. 3)" },
    { id = 1501003018, id2 = 1501002018, name = "Time Traveler Backpack (Lv. 3)" },
    { id = 1501003019, id2 = 1501002019, name = "Bag Lunch Backpack (Lv. 3)" },
    { id = 1501003020, id2 = 1501002020, name = "Rugged Backpack (Lv. 3)" },
    { id = 1501003021, id2 = 1501002021, name = "Shiny Silver Backpack (Lv. 3)" },
    { id = 1501003022, id2 = 1501002022, name = "Trickster Backpack (Lv. 3)" },
    { id = 1501003023, id2 = 1501002023, name = "Night Fright Backpack (Lv. 3)" },
    { id = 1501003024, id2 = 1501002024, name = "Count Backpack (Lv. 3)" },
    { id = 1501003025, id2 = 1501002025, name = "Turkey Feast Backpack (Lv. 3)" },
    { id = 1501003026, id2 = 1501002026, name = "Silly Chicken Backpack (Lv. 3)" },
    { id = 1501003027, id2 = 1501002027, name = "Sanguine Backpack (Lv. 3)" },
    { id = 1501003028, id2 = 1501002028, name = "Master of the Land Backpack (Lv. 3)" },
    { id = 1501003029, id2 = 1501002029, name = "Outing Backpack (Lv. 3)" },
    { id = 1501003030, id2 = 1501002030, name = "Nutcracker Backpack (Lv. 3)" },
    { id = 1501003031, id2 = 1501002031, name = "Yeti Backpack (Lv. 3)" },
    { id = 1501003032, id2 = 1501002032, name = "Cuddly Panda Backpack (Lv. 3)" },
    { id = 1501003033, id2 = 1501002033, name = "Meadows Backpack (Lv. 3)" },
    { id = 1501003034, id2 = 1501002034, name = "Naughty Christmas Backpack (Lv. 3)" },
    { id = 1501003035, id2 = 1501002035, name = "Urban Scavenger Backpack (Lv. 3)" },
    { id = 1501003036, id2 = 1501002036, name = "Silly Reindeer Backpack (Lv. 3)" },
    { id = 1501003037, id2 = 1501002037, name = "MOMMYSON Backpack (Lv. 3)" },
    { id = 1501003038, id2 = 1501002038, name = "Jungle Predator Backpack (Lv. 3)" },
    { id = 1501003039, id2 = 1501002039, name = "Bling Backpack (Lv. 3)" },
    { id = 1501003041, id2 = 1501002041, name = "Cherubic Angel Backpack (Lv. 3)" },
    { id = 1501003042, id2 = 1501002042, name = "Invader Backpack (Lv. 3)" },
    { id = 1501003043, id2 = 1501002043, name = "Illusion Judge Backpack (Lv. 3)" },
    { id = 1501003044, id2 = 1501002044, name = "Anniversary Backpack (Lv. 3)" },
    { id = 1501003045, id2 = 1501002045, name = "Brilliant Anniversary Backpack (Lv. 3)" },
    { id = 1501003046, id2 = 1501002046, name = "Red Armored Backpack (Lv. 3)" },
    { id = 1501003047, id2 = 1501002047, name = "Butterfly Wings Backpack (Lv. 3)" },
    { id = 1501003048, id2 = 1501002048, name = "Star Trooper Backpack (Lv. 3)" },
    { id = 1501003051, id2 = 1501002051, name = "The Fool Backpack (Lv. 3)" },
    { id = 1501003052, id2 = 1501002052, name = "Pitch Master Backpack (Lv. 3)" },
    { id = 1501003053, id2 = 1501002053, name = "Draconian Champion Backpack (Lv. 3)" },
    { id = 1501003054, id2 = 1501002054, name = "Expedition Backpack (Lv. 3)" },
    { id = 1501003055, id2 = 1501002055, name = "Sea Turtle Backpack (Lv. 3)" },
    { id = 1501003056, id2 = 1501002056, name = "Wanderer Backpack (Lv. 3)" },
    { id = 1501003057, id2 = 1501002057, name = "Ryan Backpack (Lv. 3)" },
    { id = 1501003058, id2 = 1501002058, name = "【entity-BAPE¦canonical_name=BAPE】 X PUBGM CAMO Backpack (Lv. 3)" },
    { id = 1501003059, id2 = 1501002059, name = "Extreme Adventure Backpack (Lv. 3)" },
    { id = 1501003060, id2 = 1501002060, name = "Battlefield Geek Backpack (Lv. 3)" },
    { id = 1501003061, id2 = 1501002061, name = "【entity-Godzilla¦canonical_name=Godzilla】 Backpack (Lv. 3)" },
    { id = 1501003062, id2 = 1501002062, name = "King Ghidorah Backpack (Lv. 3)" },
    { id = 1501003064, id2 = 1501002064, name = "Chick Princess Backpack (Lv. 3)" },
    { id = 1501003065, id2 = 1501002065, name = "Monster Backpack (Lv. 3)" },
    { id = 1501003066, id2 = 1501002066, name = "Dolphin Backpack (Lv. 3)" },
    { id = 1501003067, id2 = 1501002067, name = "Squid Squad Backpack (Lv. 3)" },
    { id = 1501003068, id2 = 1501002068, name = "Victory Lap Backpack (Lv. 3)" },
    { id = 1501003069, id2 = 1501002069, name = "Hungry Shark Backpack (Lv. 3)" },
    { id = 1501003070, id2 = 1501002070, name = "Milky Way Backpack (Lv. 3)" },
    { id = 1501003071, id2 = 1501002071, name = "Bloody Knife Backpack (Lv. 3)" },
    { id = 1501003072, id2 = 1501002072, name = "Explorer's Backpack (Lv. 3)" },
    { id = 1501003073, id2 = 1501002073, name = "Sailing Ape Backpack (Lv. 3)" },
    { id = 1501003074, id2 = 1501002074, name = "Smiling Pal Backpack (Lv. 3)" },
    { id = 1501003075, id2 = 1501002075, name = "Sad Pal Backpack (Lv. 3)" },
    { id = 1501003076, id2 = 1501002076, name = "Clever Pal Backpack (Lv. 3)" },
    { id = 1501003077, id2 = 1501002077, name = "Amorous Pal Backpack (Lv. 3)" },
    { id = 1501003078, id2 = 1501002078, name = "Fan Backpack (Lv. 3)" },
    { id = 1501003079, id2 = 1501002079, name = "Moon Bunny Backpack (Lv. 3)" },
    { id = 1501003081, id2 = 1501002081, name = "Angel Wings Backpack (Lv. 3)" },
    { id = 1501003082, id2 = 1501002082, name = "Black Tortoise Defender Backpack (Lv. 3)" },
    { id = 1501003083, id2 = 1501002083, name = "Legend of the Fjord Backpack (Lv. 3)" },
    { id = 1501003084, id2 = 1501002084, name = "Demigod Gladiator Backpack (Lv. 3)" },
    { id = 1501003085, id2 = 1501002085, name = "Trickling Backpack (Lv. 3)" },
    { id = 1501003086, id2 = 1501002086, name = "Blood Rain Backpack (Lv. 3)" },
    { id = 1501003087, id2 = 1501002087, name = "Futuristic Streetwear Backpack (Lv. 3)" },
    { id = 1501003088, id2 = 1501002088, name = "Black Cat Backpack (Lv. 3)" },
    { id = 1501003089, id2 = 1501002089, name = "Irradiated Frog Backpack (Lv. 3)" },
    { id = 1501003090, id2 = 1501002090, name = "Mischievous Night Backpack (Lv. 3)" },
    { id = 1501003091, id2 = 1501002091, name = "Red Backpack (Lv. 3)" },
    { id = 1501003092, id2 = 1501002092, name = "Snow Blush Backpack (Lv. 3)" },
    { id = 1501003093, id2 = 1501002093, name = "Arctic Witch Backpack (Lv. 3)" },
    { id = 1501003094, id2 = 1501002094, name = "Shadow Soldier Backpack (Lv. 3)" },
    { id = 1501003095, id2 = 1501002095, name = "Winter Warmth Backpack (Lv. 3)" },
    { id = 1501003097, id2 = 1501002097, name = "Snowflake Girl Backpack (Lv. 3)" },
    { id = 1501003098, id2 = 1501002098, name = "Rowdy Red Panda Backpack (Lv. 3)" },
    { id = 1501003099, id2 = 1501002099, name = "Ninja Kitty Backpack (Lv. 3)" },
    { id = 1501003100, id2 = 1501002100, name = "Blood Lotus Backpack (Lv. 3)" },
    { id = 1501003101, id2 = 1501002101, name = "Field Commander Backpack (Lv. 3)" },
    { id = 1501003102, id2 = 1501002102, name = "The Pummeler Backpack (Lv. 3)" },
    { id = 1501003103, id2 = 1501002103, name = "Forest Ninja Backpack (Lv. 3)" },
    { id = 1501003104, id2 = 1501002104, name = "Sleepy Slug Backpack (Lv. 3)" },
    { id = 1501003105, id2 = 1501002105, name = "Amphibian Hunter Backpack (Lv. 3)" },
    { id = 1501003107, id2 = 1501002107, name = "Will of Horus Backpack (Lv. 3)" },
    { id = 1501003108, id2 = 1501002108, name = "Cherry Blossom Backpack (Lv. 3)" },
    { id = 1501003109, id2 = 1501002109, name = "Savage Psycho Backpack (Lv. 3)" },
    { id = 1501003110, id2 = 1501002110, name = "Honeycomb Backpack (Lv. 3)" },
    { id = 1501003112, id2 = 1501002112, name = "Angry King Pig Backpack (Lv. 3)" },
    { id = 1501003114, id2 = 1501002114, name = "Wasteland Survivor Backpack (Lv. 3)" },
    { id = 1501003115, id2 = 1501002115, name = "Golden Eagle Backpack (Lv. 3)" },
    { id = 1501003116, id2 = 1501002116, name = "Sweet Treats Backpack (Lv. 3)" },
    { id = 1501003118, id2 = 1501002118, name = "8-bit Unicorn Backpack (Lv. 3)" },
    { id = 1501003120, id2 = 1501002120, name = "Buskin' Monkey Backpack (Lv. 3)" },
    { id = 1501003122, id2 = 1501002122, name = "Frog Prince Backpack (Lv. 3)" },
    { id = 1501003123, id2 = 1501002123, name = "Lieutenant Parsec Backpack (Lv. 3)" },
    { id = 1501003125, id2 = 1501002125, name = "Midnight Angel Backpack (Lv. 3)" },
    { id = 1501003126, id2 = 1501002126, name = "Wings of Dawn Backpack (Lv. 3)" },
    { id = 1501003127, id2 = 1501002127, name = "Wings of Fantasy Backpack (Lv. 3)" },
    { id = 1501003128, id2 = 1501002128, name = "Iridescent Feathers Backpack (Lv. 3)" },
    { id = 1501003129, id2 = 1501002129, name = "Poker King Backpack (Lv. 3)" },
    { id = 1501003130, id2 = 1501002130, name = "Fortune Teller Backpack (Lv. 3)" },
    { id = 1501003131, id2 = 1501002131, name = "Purple Witch Doctor Backpack (Lv. 3)" },
    { id = 1501003132, id2 = 1501002132, name = "Puppy Love Backpack (Lv. 3)" },
    { id = 1501003133, id2 = 1501002133, name = "Bloodthirsty Joker Backpack (Lv. 3)" },
    { id = 1501003134, id2 = 1501002134, name = "Fortune Kitty Backpack (Lv. 3)" },
    { id = 1501003135, id2 = 1501002135, name = "Gambling Master Backpack (Lv. 3)" },
    { id = 1501003136, id2 = 1501002136, name = "Stealth Agent Backpack (Lv. 3)" },
    { id = 1501003137, id2 = 1501002137, name = "Cute Animal Backpack (Lv. 3)" },
    { id = 1501003140, id2 = 1501002140, name = "Winged Elephant Backpack (Lv. 3)" },
    { id = 1501003141, id2 = 1501002141, name = "I SEE YOU Backpack (Lv. 3)" },
    { id = 1501003142, id2 = 1501002142, name = "Ragtag Goon Backpack (Lv. 3)" },
    { id = 1501003143, id2 = 1501002143, name = "Dazzling Youth Backpack (Lv. 3)" },
    { id = 1501003144, id2 = 1501002144, name = "Cute Kitten Backpack (Lv. 3)" },
    { id = 1501003145, id2 = 1501002145, name = "Captain Pengyoo Backpack (Lv. 3)" },
    { id = 1501003146, id2 = 1501002146, name = "Sparkly Universe Backpack (Lv. 3)" },
    { id = 1501003147, id2 = 1501002147, name = "Mr. Cluck Backpack (Lv. 3)" },
    { id = 1501003149, id2 = 1501002149, name = "Firefighter Backpack (Lv. 3)" },
    { id = 1501003150, id2 = 1501002150, name = "Mechforged Backpack (Lv. 3)" },
    { id = 1501003151, id2 = 1501002151, name = "Podium Placer Backpack (Lv. 3)" },
    { id = 1501003153, id2 = 1501002153, name = "Sticky Rice Dumpling Backpack (Lv. 3)" },
    { id = 1501003154, id2 = 1501002154, name = "Nightmare Backpack (Lv. 3)" },
    { id = 1501003155, id2 = 1501002155, name = "Dino Park Backpack (Lv. 3)" },
    { id = 1501003156, id2 = 1501002156, name = "Sugar Rush Backpack (Lv. 3)" },
    { id = 1501003157, id2 = 1501002157, name = "Lion's Claw Backpack (Lv. 3)" },
    { id = 1501003158, id2 = 1501002158, name = "Matryoshka Doll Backpack (Lv. 3)" },
    { id = 1501003160, id2 = 1501002160, name = "Ladybug Backpack (Lv. 3)" },
    { id = 1501003161, id2 = 1501002161, name = "Alloy Armor Backpack (Lv. 3)" },
    { id = 1501003162, id2 = 1501002162, name = "Gourmet Diner Backpack (Lv. 3)" },
    { id = 1501003163, id2 = 1501002163, name = "Vivid Star Backpack (Lv. 3)" },
    { id = 1501003164, id2 = 1501002164, name = "Crocodile Backpack (Lv. 3)" },
    { id = 1501003165, id2 = 1501002165, name = "Stars & Stripes Backpack (Lv. 3)" },
    { id = 1501003166, id2 = 1501002166, name = "Samurai Ops Backpack (Lv. 3)" },
    { id = 1501003168, id2 = 1501002168, name = "Golden Nights Backpack (Lv. 3)" },
    { id = 1501003169, id2 = 1501002169, name = "Persian Warrior Backpack (Lv. 3)" },
    { id = 1501003170, id2 = 1501002170, name = "Tricky Fox Backpack (Lv. 3)" },
    { id = 1501003171, id2 = 1501002171, name = "Pink Plume Backpack (Lv. 3)" },
    { id = 1501003172, id2 = 1501002172, name = "Gold and Silk Backpack (Lv. 3)" },
    { id = 1501003173, id2 = 1501002173, name = "Retro Police Backpack (Lv. 3)" },
    { id = 1501003174, id2 = 1501002174, name = "Pharaoh's Regalia Backpack (Lv. 3)" },
    { id = 1501003175, id2 = 1501002175, name = "Victorian Maiden Backpack (Lv. 3)" },
    { id = 1501003176, id2 = 1501002176, name = "Doggy Cabin Backpack (Lv. 3)" },
    { id = 1501003177, id2 = 1501002177, name = "Fox Skull Backpack (Lv. 3)" },
    { id = 1501003178, id2 = 1501002178, name = "Eerie Doll Backpack (Lv. 3)" },
    { id = 1501003179, id2 = 1501002179, name = "Wraith Lord Backpack (Lv. 3)" },
    { id = 1501003180, id2 = 1501002180, name = "Snowflake Fairy Backpack (Lv. 3)" },
    { id = 1501003182, id2 = 1501002182, name = "Hallows' Eve Backpack (Lv. 3)" },
    { id = 1501003183, id2 = 1501002183, name = "Gothic Lady Backpack (Lv. 3)" },
    { id = 1501003185, id2 = 1501002185, name = "Red Racecar Knight Backpack (Lv. 3)" },
    { id = 1501003187, id2 = 1501002187, name = "Taiyaki Backpack (Lv. 3)" },
    { id = 1501003188, id2 = 1501002188, name = "Resplendent Dawn Backpack (Lv. 3)" },
    { id = 1501003189, id2 = 1501002189, name = "Homestead Protector Backpack (Lv. 3)" },
    { id = 1501003190, id2 = 1501002190, name = "Xiqu Backpack (Lv. 3)" },
    { id = 1501003191, id2 = 1501002191, name = "Arena Champion Backpack (Lv. 3)" },
    { id = 1501003193, id2 = 1501002193, name = "Underworld Sovereign Backpack (Lv. 3)" },
    { id = 1501003194, id2 = 1501002194, name = "Skeleton Knight Backpack (Lv. 3)" },
    { id = 1501003195, id2 = 1501002195, name = "Lady of Blood Backpack (Lv. 3)" },
    { id = 1501003196, id2 = 1501002196, name = "Leopard Print Backpack (Lv. 3)" },
    { id = 1501003197, id2 = 1501002197, name = "Witch Coven Backpack (Lv. 3)" },
    { id = 1501003198, id2 = 1501002198, name = "Dauntless Backpack (Lv. 3)" },
    { id = 1501003199, id2 = 1501002199, name = "Cactus Sheriff Backpack (Lv. 3)" },
    { id = 1501003200, id2 = 1501002200, name = "Fantasy City Backpack (Lv. 3)" },
    { id = 1501003201, id2 = 1501002201, name = "Tulip Backpack (Lv. 3)" },
    { id = 1501003202, id2 = 1501002202, name = "Nut Protector Backpack (Lv. 3)" },
    { id = 1501003204, id2 = 1501002204, name = "Dream Idol Backpack (Lv. 3)" },
    { id = 1501003205, id2 = 1501002205, name = "Jolly Snowman Backpack (Lv. 3)" },
    { id = 1501003206, id2 = 1501002206, name = "Bewitching Enchantress Backpack (Lv. 3)" },
    { id = 1501003207, id2 = 1501002207, name = "Acolyte of Justice Backpack (Lv. 3)" },
    { id = 1501003209, id2 = 1501002209, name = "Vintage Clockwork Backpack (Lv. 3)" },
    { id = 1501003210, id2 = 1501002210, name = "Thorn Trooper Backpack (Lv. 3)" },
    { id = 1501003211, id2 = 1501002211, name = "Punk Rhino Backpack (Lv. 3)" },
    { id = 1501003212, id2 = 1501002212, name = "Dracoguard Backpack (Lv. 3)" },
    { id = 1501003213, id2 = 1501002213, name = "Dayman Backpack (Lv. 3)" },
    { id = 1501003215, id2 = 1501002215, name = "Keep Out Backpack (Lv. 3)" },
    { id = 1501003216, id2 = 1501002216, name = "Winter Queen Backpack (Lv. 3)" },
    { id = 1501003217, id2 = 1501002217, name = "Snowwoman Backpack (Lv. 3)" },
    { id = 1501003220, id2 = 1501002220, name = "Blood Raven Backpack (Lv. 3)" },
    { id = 1501003221, id2 = 1501002221, name = "Lady Butterfly Backpack (Lv. 3)" },
    { id = 1501003222, id2 = 1501002222, name = "Heart of the Sea Backpack (Lv. 3)" },
    { id = 1501003224, id2 = 1501002224, name = "Modern Lord Backpack (Lv. 3)" },
    { id = 1501003225, id2 = 1501002225, name = "Nutcracker King Backpack (Lv. 3)" },
    { id = 1501003226, id2 = 1501002226, name = "Ghillie Lion Backpack (Lv. 3)" },
    { id = 1501003227, id2 = 1501002227, name = "Bestial Aurum Backpack (Lv. 3)" },
    { id = 1501003229, id2 = 1501002229, name = "Kiss emoji Backpack (Lv. 3)" },
    { id = 1501003231, id2 = 1501002231, name = "Bard Backpack (Lv. 3)" },
    { id = 1501003233, id2 = 1501002233, name = "Techno Sensation Backpack (Lv. 3)" },
    { id = 1501003236, id2 = 1501002236, name = "Homeland Backpack (Lv. 3)" },
    { id = 1501003237, id2 = 1501002237, name = "Chromatic Brilliance Backpack (Lv. 3)" },
    { id = 1501003238, id2 = 1501002238, name = "Gemstone Scarab Backpack (Lv. 3)" },
    { id = 1501003239, id2 = 1501002239, name = "Butterfly Buddies Backpack (Lv. 3)" },
    { id = 1501003240, id2 = 1501002240, name = "Silly Kitten Backpack (Lv. 3)" },
    { id = 1501003241, id2 = 1501002241, name = "Cherry Crystal Backpack (Lv. 3)" },
    { id = 1501003242, id2 = 1501002242, name = "Mystic Artificer Backpack (Lv. 3)" },
    { id = 1501003243, id2 = 1501002243, name = "B.Duck Backpack (Lv. 3)" },
    { id = 1501003244, id2 = 1501002244, name = "QUACK Agent Backpack (Lv. 3)" },
    { id = 1501003245, id2 = 1501002245, name = "Snow Sakura Backpack (Lv. 3)" },
    { id = 1501003246, id2 = 1501002246, name = "Bug Box Backpack (Lv. 3)" },
    { id = 1501003247, id2 = 1501002247, name = "Cyber Monkey Backpack (Lv. 3)" },
    { id = 1501003248, id2 = 1501002248, name = "Neon Wave Backpack (Lv. 3)" },
    { id = 1501003249, id2 = 1501002249, name = "Masked Wasp Backpack (Lv. 3)" },
    { id = 1501003250, id2 = 1501002250, name = "Noctus Sovereign Backpack (Lv. 3)" },
    { id = 1501003251, id2 = 1501002251, name = "Night Ensemble Backpack (Lv. 3)" },
    { id = 1501003252, id2 = 1501002252, name = "Futuristic Hive Backpack (Lv. 3)" },
    { id = 1501003253, id2 = 1501002253, name = "Banana Bonanza Backpack (Lv. 3)" },
    { id = 1501003258, id2 = 1501002258, name = "Ice Avenger Backpack (Lv. 3)" },
    { id = 1501003259, id2 = 1501002259, name = "Iron Tortoise Backpack (Lv. 3)" },
    { id = 1501003260, id2 = 1501002260, name = "Urban Assassin Backpack (Lv. 3)" },
    { id = 1501003261, id2 = 1501002261, name = "Dino Brown Backpack (Lv. 3)" },
    { id = 1501003262, id2 = 1501002262, name = "Fluorescent Jesterette Backpack (Lv. 3)" },
    { id = 1501003263, id2 = 1501002263, name = "Mecha Ant Backpack (Lv. 3)" },
    { id = 1501003265, id2 = 1501002265, name = "Poseidon Backpack (Lv. 3)" },
    { id = 1501003266, id2 = 1501002266, name = "Sally Backpack (Lv. 3)" },
    { id = 1501003267, id2 = 1501002267, name = "Recyclable Backpack (Lv. 3)" },
    { id = 1501003268, id2 = 1501002268, name = "Juris Owl Backpack (Lv. 3)" },
    { id = 1501003269, id2 = 1501002269, name = "Cute Bazzi Backpack (Lv. 3)" },
    { id = 1501003270, id2 = 1501002270, name = "Amazing Journey Backpack (Lv. 3)" },
    { id = 1501003271, id2 = 1501002271, name = "Red Battlecat Backpack (Lv. 3)" },
    { id = 1501003273, id2 = 1501002273, name = "MECHAGODZILLA Backpack (Lv. 3)" },
    { id = 1501003274, id2 = 1501002274, name = "Magenta Skies Backpack (Lv. 3)" },
    { id = 1501003275, id2 = 1501002275, name = "Lapis Barrier Backpack (Lv. 3)" },
    { id = 1501003276, id2 = 1501002276, name = "B.Duck Backpack (Lv. 3)" },
    { id = 1501003277, id2 = 1501002277, name = "Godzilla Backpack (Lv. 3)" },
    { id = 1501003279, id2 = 1501002279, name = "Justice Defender Backpack (Lv. 3)" },
    { id = 1501003280, id2 = 1501002280, name = "Kegs Up Backpack (Lv. 3)" },
    { id = 1501003281, id2 = 1501002281, name = "Electro Bunny Backpack (Lv. 3)" },
    { id = 1501003282, id2 = 1501002282, name = "Chicken Delight Backpack (Lv. 3)" },
    { id = 1501003283, id2 = 1501002283, name = "Droid Backpack (Lv. 3)" },
    { id = 1501003286, id2 = 1501002286, name = "Untamed Magnate Backpack (Lv. 3)" },
    { id = 1501003287, id2 = 1501002287, name = "Magic Box Backpack (Lv. 3)" },
    { id = 1501003288, id2 = 1501002288, name = "Retro Gamer Backpack (Lv. 3)" },
    { id = 1501003291, id2 = 1501002291, name = "Veggie Carton Backpack (Lv. 3)" },
    { id = 1501003292, id2 = 1501002292, name = "Oven Fresh Backpack (Lv. 3)" },
    { id = 1501003293, id2 = 1501002293, name = "Biometal Backpack (Lv. 3)" },
    { id = 1501003294, id2 = 1501002294, name = "Snow Hunter Backpack (Lv. 3)" },
    { id = 1501003295, id2 = 1501002295, name = "Savage Totem Backpack (Lv. 3)" },
    { id = 1501003296, id2 = 1501002296, name = "Deep Sea Cyscout Backpack (Lv. 3)" },
    { id = 1501003297, id2 = 1501002297, name = "Bento Love Backpack (Lv. 3)" },
    { id = 1501003298, id2 = 1501002298, name = "Chef's Kit Backpack (Lv. 3)" },
    { id = 1501003300, id2 = 1501002300, name = "Sweet Raccoon Backpack (Lv. 3)" },
    { id = 1501003301, id2 = 1501002301, name = "Tender Cactus Backpack (Lv. 3)" },
    { id = 1501003302, id2 = 1501002302, name = "Mushroom Buddy Backpack (Lv. 3)" },
    { id = 1501003304, id2 = 1501002304, name = "Demon Guise Backpack (Lv. 3)" },
    { id = 1501003305, id2 = 1501002305, name = "Past Relics Backpack (Lv. 3)" },
    { id = 1501003306, id2 = 1501002306, name = "Riot Handler Backpack (Lv. 3)" },
    { id = 1501003307, id2 = 1501002307, name = "Austere Gold Backpack (Lv. 3)" },
    { id = 1501003308, id2 = 1501002308, name = "Cheesy Backpack (Lv. 3)" },
    { id = 1501003309, id2 = 1501002309, name = "Spectral Scanner Backpack (Lv. 3)" },
    { id = 1501003310, id2 = 1501002310, name = "Pixelated Dinosaur Backpack (Lv. 3)" },
    { id = 1501003311, id2 = 1501002311, name = "Crystal Casket Backpack (Lv. 3)" },
    { id = 1501003312, id2 = 1501002312, name = "Merry Tank Backpack (Lv. 3)" },
    { id = 1501003314, id2 = 1501002314, name = "Amphibian Wings Backpack (Lv. 3)" },
    { id = 1501003316, id2 = 1501002316, name = "Merry Tidings Backpack (Lv. 3)" },
    { id = 1501003317, id2 = 1501002317, name = "Wintry Ruler Backpack (Lv. 3)" },
    { id = 1501003318, id2 = 1501002318, name = "Majestic Cavalry Backpack (Lv. 3)" },
    { id = 1501003320, id2 = 1501002320, name = "Aurous Elegance Backpack (Lv. 3)" },
    { id = 1501003323, id2 = 1501002323, name = "Dazed Cat Backpack (Lv. 3)" },
    { id = 1501003324, id2 = 1501002324, name = "Snow Pixie Backpack (Lv. 3)" },
    { id = 1501003325, id2 = 1501002325, name = "【entity-Liverpool FC¦canonical_name=Liverpool FC】 Backpack (Lv. 3)" },
    { id = 1501003326, id2 = 1501002326, name = "Rabbit Plushie Backpack (Lv. 3)" },
    { id = 1501003330, id2 = 1501002330, name = "Extreme Athlete Backpack (Lv. 3)" },
    { id = 1501003331, id2 = 1501002331, name = "Jinx's  Backpack (Lv. 3)" },
    { id = 1501003332, id2 = 1501002332, name = "Hextech Crystal Backpack (Lv. 3)" },
    { id = 1501003333, id2 = 1501002333, name = "Gundala Backpack (Lv. 3)" },
    { id = 1501003336, id2 = 1501002336, name = "Alfheim Wonder Backpack (Lv. 3)" },
    { id = 1501003337, id2 = 1501002337, name = "Dive-A-Tron Backpack (Lv. 3)" },
    { id = 1501003338, id2 = 1501002338, name = "Sweet Tiggy Backpack (Lv. 3)" },
    { id = 1501003339, id2 = 1501002339, name = "Winter Bunny Backpack (Lv. 3)" },
    { id = 1501003340, id2 = 1501002340, name = "Snowy Seal Backpack (Lv. 3)" },
    { id = 1501003341, id2 = 1501002341, name = "Sweet Cub Backpack (Lv. 3)" },
    { id = 1501003342, id2 = 1501002342, name = "Adorbs Baddie Backpack (Lv. 3)" },
    { id = 1501003343, id2 = 1501002343, name = "Baby Dragon Backpack (Lv. 3)" },
    { id = 1501003344, id2 = 1501002344, name = "Capsule Toy Backpack (Lv. 3)" },
    { id = 1501003345, id2 = 1501002345, name = "Roguish Imp Backpack (Lv. 3)" },
    { id = 1501003346, id2 = 1501002346, name = "Bunny Friends Backpack (Lv. 3)" },
    { id = 1501003348, id2 = 1501002348, name = "Pixel Bolt Backpack (Lv. 3)" },
    { id = 1501003349, id2 = 1501002349, name = "Lost Civilization Backpack (Lv. 3)" },
    { id = 1501003350, id2 = 1501002350, name = "Blissful Backpack (Lv. 3)" },
    { id = 1501003351, id2 = 1501002351, name = "Snowcapped Berg Backpack (Lv. 3)" },
    { id = 1501003352, id2 = 1501002352, name = "Future Fuel Backpack (Lv. 3)" },
    { id = 1501003354, id2 = 1501002354, name = "Steampunk Herbalist Backpack (Lv. 3)" },
    { id = 1501003355, id2 = 1501002355, name = "Nebula Visitor Backpack (Lv. 3)" },
    { id = 1501003356, id2 = 1501002356, name = "Hungry Vine Backpack (Lv. 3)" },
    { id = 1501003357, id2 = 1501002357, name = "Demonic Orb Backpack (Lv. 3)" },
    { id = 1501003359, id2 = 1501002359, name = "Spiky Carry Backpack (Lv. 3)" },
    { id = 1501003361, id2 = 1501002361, name = "Wasteland Explorer Backpack (Lv. 3)" },
    { id = 1501003362, id2 = 1501002362, name = "Twilight Vigilante Backpack (Lv. 3)" },
    { id = 1501003363, id2 = 1501002363, name = "Jack-In-The-Box Backpack (Lv. 3)" },
    { id = 1501003364, id2 = 1501002364, name = "Munchkin Bearbox Backpack (Lv. 3)" },
    { id = 1501003366, id2 = 1501002366, name = "Cheeky Cat Backpack (Lv. 3)" },
    { id = 1501003367, id2 = 1501002367, name = "Jelly Bear Backpack (Lv. 3)" },
    { id = 1501003368, id2 = 1501002368, name = "Cute Bunny Backpack (Lv. 3)" },
    { id = 1501003369, id2 = 1501002369, name = "Opulence Backpack (Lv. 3)" },
    { id = 1501003370, id2 = 1501002370, name = "Ursa Hunter Backpack (Lv. 3)" },
    { id = 1501003371, id2 = 1501002371, name = "Tiger's Roar Backpack (Lv. 3)" },
    { id = 1501003372, id2 = 1501002372, name = "Stellar Sense Backpack (Lv. 3)" },
    { id = 1501003373, id2 = 1501002373, name = "Cutie Shark Backpack (Lv. 3)" },
    { id = 1501003374, id2 = 1501002374, name = "School Special Backpack (Lv. 3)" },
    { id = 1501003375, id2 = 1501002375, name = "Vibrant Celebration Backpack (Lv. 3)" },
    { id = 1501003376, id2 = 1501002376, name = "Vintage Record Backpack (Lv. 3)" },
    { id = 1501003377, id2 = 1501002377, name = "Emerald Soul Backpack (Lv. 3)" },
    { id = 1501003378, id2 = 1501002378, name = "Punk Shark Backpack (Lv. 3)" },
    { id = 1501003380, id2 = 1501002380, name = "Lovey-Dovey Backpack (Lv. 3)" },
    { id = 1501003381, id2 = 1501002381, name = "Masameer's Trad Backpack (Lv. 3)" },
    { id = 1501003383, id2 = 1501002383, name = "Emerald Power Backpack (Lv. 3)" },
    { id = 1501003384, id2 = 1501002384, name = "Underwraith Backpack (Lv. 3)" },
    { id = 1501003385, id2 = 1501002385, name = "Mechanized Era Backpack (Lv. 3)" },
    { id = 1501003386, id2 = 1501002386, name = "Mechanized Era Backpack (Lv. 3)" },
    { id = 1501003387, id2 = 1501002387, name = "Evangelion-01 Backpack (Lv. 3)" },
    { id = 1501003388, id2 = 1501002388, name = "Razor Edge Backpack (Lv. 3)" },
    { id = 1501003389, id2 = 1501002389, name = "Cute Stroll Backpack (Lv. 3)" },
    { id = 1501003390, id2 = 1501002390, name = "Gilded Flower Backpack (Lv. 3)" },
    { id = 1501003391, id2 = 1501002391, name = "Polar Fluff Backpack (Lv. 3)" },
    { id = 1501003392, id2 = 1501002392, name = "Adorable Ghost Backpack (Lv. 3)" },
    { id = 1501003393, id2 = 1501002393, name = "Cute Manta Ray Backpack (Lv. 3)" },
    { id = 1501003394, id2 = 1501002394, name = "Starry Wishes Backpack (Lv. 3)" },
    { id = 1501003395, id2 = 1501002395, name = "Fine Leather Backpack (Lv. 3)" },
    { id = 1501003396, id2 = 1501002396, name = "Gemshell Backpack (Lv. 3)" },
    { id = 1501003397, id2 = 1501002397, name = "Steampunk Captain Backpack (Lv. 3)" },
    { id = 1501003398, id2 = 1501002398, name = "Imperial Emblem Backpack (Lv. 3)" },
    { id = 1501003399, id2 = 1501002399, name = "Time Bomb Backpack (Lv. 3)" },
    { id = 1501003400, id2 = 1501002400, name = "Baby Shark Backpack (Lv. 3)" },
    { id = 1501003401, id2 = 1501002401, name = "Forest Tribe Backpack (Lv. 3)" },
    { id = 1501003402, id2 = 1501002402, name = "Cool Critter Backpack (Lv. 3)" },
    { id = 1501003408, id2 = 1501002408, name = "Fishing Legend Backpack (Lv. 3)" },
    { id = 1501003409, id2 = 1501002409, name = "Cursed Heir Backpack (Lv. 3)" },
    { id = 1501003410, id2 = 1501002410, name = "Submarine Backpack (Lv. 3)" },
    { id = 1501003411, id2 = 1501002411, name = "Flamewraith Backpack (Lv. 3)" },
    { id = 1501003412, id2 = 1501002412, name = "Treasure Casket Backpack (Lv. 3)" },
    { id = 1501003414, id2 = 1501002414, name = "Winged Ascent Backpack (Lv. 3)" },
    { id = 1501003415, id2 = 1501002415, name = "Fiery Wings Backpack (Lv. 3)" },
    { id = 1501003416, id2 = 1501002416, name = "Vending Machine Backpack (Lv. 3)" },
    { id = 1501003417, id2 = 1501002417, name = "Butterfinger Backpack (Lv. 3)" },
    { id = 1501003418, id2 = 1501002418, name = "Red, White and Ready Backpack (Lv. 3)" },
    { id = 1501003419, id2 = 1501002419, name = "Payback Backpack (Lv. 3)" },
    { id = 1501003420, id2 = 1501002420, name = "Dino Egg Backpack (Lv. 3)" },
    { id = 1501003421, id2 = 1501002421, name = "Bony Bunny Backpack (Lv. 3)" },
    { id = 1501003422, id2 = 1501002422, name = "Bramble Overlord Backpack (Lv. 3)" },
    { id = 1501003423, id2 = 1501002423, name = "CyberGen: Zero Backpack (Lv. 3)" },
    { id = 1501003424, id2 = 1501002424, name = "Markhor Backpack (Lv. 3)" },
    { id = 1501003425, id2 = 1501002425, name = "First Love Backpack (Lv. 3)" },
    { id = 1501003426, id2 = 1501002426, name = "Lil Burger Backpack (Lv. 3)" },
    { id = 1501003430, id2 = 1501002430, name = "Bone Gala Backpack (Lv. 3)" },
    { id = 1501003433, id2 = 1501002433, name = "Frilly Ribbon Backpack (Lv. 3)" },
    { id = 1501003437, id2 = 1501002437, name = "Mutant Warlord Backpack (Lv. 3)" },
    { id = 1501003441, id2 = 1501002441, name = "Clown Cannon Backpack (Lv. 3)" },
    { id = 1501003443, id2 = 1501002443, name = "Luminous Galaxy Backpack (Lv. 3)" },
    { id = 1501003444, id2 = 1501002444, name = "Royal Apparel Backpack (Lv. 3)" },
    { id = 1501003446, id2 = 1501002446, name = "Super Corn Backpack (Lv. 3)" },
    { id = 1501003448, id2 = 1501002448, name = "Secret Legacy Backpack (Lv. 3)" },
    { id = 1501003451, id2 = 1501002451, name = "Floral Bouquet Backpack (Lv. 3)" },
    { id = 1501003452, id2 = 1501002452, name = "Basta Backpack (Lv. 3)" },
    { id = 1501003453, id2 = 1501002453, name = "Dino Trooper Backpack (Lv. 3)" },
    { id = 1501003454, id2 = 1501002454, name = "Potion Master Backpack (Lv. 3)" },
    { id = 1501003457, id2 = 1501002457, name = "Ancient Civilization Backpack (Lv. 3)" },
    { id = 1501003458, id2 = 1501002458, name = "Sweet Bunny Backpack (Lv. 3)" },
    { id = 1501003459, id2 = 1501002459, name = "Stern Kitty Backpack (Lv. 3)" },
    { id = 1501003462, id2 = 1501002462, name = "Yak Warrior Backpack (Lv. 3)" },
    { id = 1501003463, id2 = 1501002463, name = "【entity-BoBoiBoy¦canonical_name=BoBoiBoy】 Backpack (Lv. 3)" },
    { id = 1501003466, id2 = 1501002466, name = "Mystique Splendor Backpack (Lv. 3)" },
    { id = 1501003467, id2 = 1501002467, name = "Draco Rascal Backpack (Lv. 3)" },
    { id = 1501003468, id2 = 1501002468, name = "Cuddly Bear Backpack (Lv. 3)" },
    { id = 1501003469, id2 = 1501002469, name = "Floral Snowflake Backpack (Lv. 3)" },
    { id = 1501003471, id2 = 1501002471, name = "Aquatic Fury Backpack (Lv. 3)" },
    { id = 1501003474, id2 = 1501002474, name = "Digiwolf Backpack (Lv. 3)" },
    { id = 1501003475, id2 = 1501002475, name = "Ultimate Predator Backpack (Lv. 3)" },
    { id = 1501003476, id2 = 1501002476, name = "【entity-Messi¦canonical_name=Messi】 Football Icon Backpack (Lv. 3)" },
    { id = 1501003478, id2 = 1501002478, name = "Cha-Ching Backpack (Lv. 3)" },
    { id = 1501003479, id2 = 1501002479, name = "Mithu Tota Backpack (Lv. 3)" },
    { id = 1501003480, id2 = 1501002480, name = "【entity-Indomie¦canonical_name=Indomie】 Taste of the Nation Backpack (Lv. 3)" },
    { id = 1501003481, id2 = 1501002481, name = "Viet Indie Prince Astronaut Backpack (Lv. 3)" },
    { id = 1501003482, id2 = 1501002482, name = "Kooky Creature Backpack (Lv. 3)" },
    { id = 1501003483, id2 = 1501002483, name = "Cardboard Dino Backpack (Lv. 3)" },
    { id = 1501003484, id2 = 1501002484, name = "Fortified Arms Backpack (Lv. 3)" },
    { id = 1501003485, id2 = 1501002485, name = "Rabbit Sprite's Carrot Backpack (Lv. 3)" },
    { id = 1501003486, id2 = 1501002486, name = "Red Tuxedo Backpack (Lv. 3)" },
    { id = 1501003487, id2 = 1501002487, name = "Deadly Glare Backpack (Lv. 3)" },
    { id = 1501003489, id2 = 1501002489, name = "Sinister Ghoulie Backpack (Lv. 3)" },
    { id = 1501003490, id2 = 1501002490, name = "Clockwork Ursa Backpack (Lv. 3)" },
    { id = 1501003492, id2 = 1501002492, name = "Bling Cat Backpack (Lv. 3)" },
    { id = 1501003494, id2 = 1501002494, name = "Rising Rebel Backpack (Lv. 3)" },
    { id = 1501003495, id2 = 1501002495, name = "Bunny Lover Backpack (Lv. 3)" },
    { id = 1501003496, id2 = 1501002496, name = "Pixel Kitty Backpack (Lv. 3)" },
    { id = 1501003497, id2 = 1501002497, name = "Sealed Case Backpack (Lv. 3)" },
    { id = 1501003500, id2 = 1501002500, name = "Defiant Defense Backpack (Lv. 3)" },
    { id = 1501003501, id2 = 1501002501, name = "Stray Rebellion Backpack (Lv. 3)" },
    { id = 1501003502, id2 = 1501002502, name = "Deluxe Treasure Backpack (Lv. 3)" },
    { id = 1501003503, id2 = 1501002503, name = "Silver Guru Backpack (Lv. 3)" },
    { id = 1501003506, id2 = 1501002506, name = "Lucky Cat Backpack (Lv. 3)" },
    { id = 1501003507, id2 = 1501002507, name = "Mousy Knockout Backpack (Lv. 3)" },
    { id = 1501003509, id2 = 1501002509, name = "Radiant Ram Backpack (Lv. 3)" },
    { id = 1501003510, id2 = 1501002510, name = "Handicraft Backpack (Lv. 3)" },
    { id = 1501003511, id2 = 1501002511, name = "Ocean Treasury Backpack (Lv. 3)" },
    { id = 1501003512, id2 = 1501002512, name = "Seafoam Assassin Backpack (Lv. 3)" },
    { id = 1501003513, id2 = 1501002513, name = "Cuddly Seahorse Backpack (Lv. 3)" },
    { id = 1501003514, id2 = 1501002514, name = "Lucky Panda Backpack (Lv. 3)" },
    { id = 1501003515, id2 = 1501002515, name = "Bloodstained Nemesis Backpack (Lv. 3)" },
    { id = 1501003516, id2 = 1501002516, name = "Pink Sweetie Backpack (Lv. 3)" },
    { id = 1501003517, id2 = 1501002517, name = "Cucumber Genius Backpack (Lv. 3)" },
    { id = 1501003519, id2 = 1501002519, name = "Flipped Bear Backpack (Lv. 3)" },
    { id = 1501003520, id2 = 1501002520, name = "Goldfinch Backpack (Lv. 3)" },
    { id = 1501003521, id2 = 1501002521, name = "Kamesennin's Turtle Shell Backpack (Lv. 3)" },
    { id = 1501003522, id2 = 1501002522, name = "Customer Basket Backpack (Lv. 3)" },
    { id = 1501003523, id2 = 1501002523, name = "Palace Guard Backpack (Lv. 3)" },
    { id = 1501003524, id2 = 1501002524, name = "Swift Mirage Backpack (Lv. 3)" },
    { id = 1501003525, id2 = 1501002525, name = "Bunny Munchkin Backpack (Lv. 3)" },
    { id = 1501003526, id2 = 1501002526, name = "Rave Critter Backpack (Lv. 3)" },
    { id = 1501003527, id2 = 1501002527, name = "Picnic Weave Backpack (Lv. 3)" },
    { id = 1501003528, id2 = 1501002528, name = "Biohazard Backpack (Lv. 3)" },
    { id = 1501003529, id2 = 1501002529, name = "Falcon Totem Backpack (Lv. 3)" },
    { id = 1501003530, id2 = 1501002530, name = "Capsule Backpack (Lv. 3)" },
    { id = 1501003531, id2 = 1501002531, name = "Seadrake Champion Backpack (Lv. 3)" },
    { id = 1501003532, id2 = 1501002532, name = "Batblitz Backpack (Lv. 3)" },
    { id = 1501003533, id2 = 1501002533, name = "Retro Rhapsody Backpack (Lv. 3)" },
    { id = 1501003534, id2 = 1501002534, name = "Juicebox Backpack (Lv. 3)" },
    { id = 1501003535, id2 = 1501002535, name = "Gulping Gull Backpack (Lv. 3)" },
    { id = 1501003536, id2 = 1501002536, name = "Vinyl Wave Backpack (Lv. 3)" },
    { id = 1501003537, id2 = 1501002537, name = "Boxerbolt Backpack (Lv. 3)" },
    { id = 1501003538, id2 = 1501002538, name = "Panthera Prime Backpack (Lv. 3)" },
    { id = 1501003539, id2 = 1501002539, name = "2023 PMGC Backpack (Lv. 3)" },
    { id = 1501003540, id2 = 1501002540, name = "Royale Delight Backpack (Lv. 3)" },
    { id = 1501003541, id2 = 1501002541, name = "Classified Label Backpack (Lv. 3)" },
    { id = 1501003542, id2 = 1501002542, name = "Rubific Backpack (Lv. 3)" },
    { id = 1501003543, id2 = 1501002543, name = "Mousetech Backpack (Lv. 3)" },
    { id = 1501003544, id2 = 1501002544, name = "Avian Charmer Backpack (Lv. 3)" },
    { id = 1501003546, id2 = 1501002546, name = "Elysian Vault Backpack (Lv. 3)" },
    { id = 1501003547, id2 = 1501002547, name = "Bony Totem Backpack (Lv. 3)" },
    { id = 1501003548, id2 = 1501002548, name = "Ancient Eon Backpack (Lv. 3)" },
    { id = 1501003549, id2 = 1501002549, name = "Foxy Flare Backpack (Lv. 3)" },
    { id = 1501003550, id2 = 1501002550, name = "Frosty Snowglobe Backpack (Lv. 3)" },
    { id = 1501003551, id2 = 1501002551, name = "Fiestafeast Backpack (Lv. 3)" },
    { id = 1501003552, id2 = 1501002552, name = "Ebil Bunny Backpack (Lv. 3)" },
    { id = 1501003553, id2 = 1501002553, name = "Sweetheart Arrow Backpack (Lv. 3)" },
    { id = 1501003554, id2 = 1501002554, name = "【entity-LINE FRIENDS¦canonical_name=LINE FRIENDS】 SALLY Backpack (Lv. 3)" },
    { id = 1501003555, id2 = 1501002555, name = "Rose Warrior Princess Backpack (Lv. 3)" },
    { id = 1501003556, id2 = 1501002556, name = "Gold Ink Tiggy Backpack (Lv. 3)" },
    { id = 1501003557, id2 = 1501002557, name = "Love Letter Backpack (Lv. 3)" },
    { id = 1501003558, id2 = 1501002558, name = "Mech Soul Ninja Backpack (Lv. 3)" },
    { id = 1501003559, id2 = 1501002559, name = "Serpengleam Backpack (Lv. 3)" },
    { id = 1501003560, id2 = 1501002560, name = "Golden Porcelain Secret Treasure Backpack (Lv. 3)" },
    { id = 1501003561, id2 = 1501002561, name = "Love Mouse Backpack (Lv. 3)" },
    { id = 1501003562, id2 = 1501002562, name = "Cute Owl Backpack (Lv. 3)" },
    { id = 1501003563, id2 = 1501002563, name = "Zanmang Loopy Backpack (Lv. 3)" },
    { id = 1501003564, id2 = 1501002564, name = "Aetherial Azure Backpack (Lv. 3)" },
    { id = 1501003565, id2 = 1501002565, name = "Auric Guardian Backpack (Lv. 3)" },
    { id = 1501003566, id2 = 1501002566, name = "Royal Rogue Backpack (Lv. 3)" },
    { id = 1501003567, id2 = 1501002567, name = "Ignis Backpack (Lv. 3)" },
    { id = 1501003568, id2 = 1501002568, name = "Magick Delight Backpack (Lv. 3)" },
    { id = 1501003569, id2 = 1501002569, name = "Gallant Jockey Backpack (Lv. 3)" },
    { id = 1501003570, id2 = 1501002570, name = "Origin Lumen Backpack (Lv. 3)" },
    { id = 1501003571, id2 = 1501002571, name = "Luminous Muse Backpack (Lv. 3)" },
    { id = 1501003572, id2 = 1501002572, name = "Bygone Realm Backpack (Lv. 3)" },
    { id = 1501003573, id2 = 1501002573, name = "Bunny Dessert Backpack (Lv. 3)" },
    { id = 1501003574, id2 = 1501002574, name = "Mech Hero Backpack (Lv. 3)" },
    { id = 1501003575, id2 = 1501002575, name = "Gearpunk Backpack (Lv. 3)" },
    { id = 1501003576, id2 = 1501002576, name = "Shrine Keeper Backpack (Lv. 3)" },
    { id = 1501003577, id2 = 1501002577, name = "Feathered Nobility Backpack (Lv. 3)" },
    { id = 1501003578, id2 = 1501002578, name = "Iron Warden Backpack (Lv. 3)" },
    { id = 1501003579, id2 = 1501002579, name = "Dr. Quirk Backpack (Lv. 3)" },
    { id = 1501003581, id2 = 1501002581, name = "Mercury Soldier Backpack (Lv. 3)" },
    { id = 1501003582, id2 = 1501002582, name = "Neon Vessel Backpack (Lv. 3)" },
    { id = 1501003583, id2 = 1501002583, name = "Pulsebox Backpack (Lv. 3)" },
    { id = 1501003584, id2 = 1501002584, name = "Soundwave Beast Backpack (Lv. 3)" },
    { id = 1501003585, id2 = 1501002585, name = "Darling Hedgehog Backpack (Lv. 3)" },
    { id = 1501003586, id2 = 1501002586, name = "Night Maiden Backpack (Lv. 3)" },
    { id = 1501003587, id2 = 1501002587, name = "Lieutenant Chaos Backpack (Lv. 3)" },
    { id = 1501003588, id2 = 1501002588, name = "Galadria Backpack (Lv. 3)" },
    { id = 1501003589, id2 = 1501002589, name = "Ancient Colossus Backpack (Lv. 3)" },
    { id = 1501003590, id2 = 1501002590, name = "Rippling Charm Backpack (Lv. 3)" },
    { id = 1501003591, id2 = 1501002591, name = "Serene Lumina Backpack (Lv. 3)" },
    { id = 1501003592, id2 = 1501002592, name = "Ghostly Snare Backpack (Lv. 3)" },
    { id = 1501003593, id2 = 1501002593, name = "Octosurprise Backpack (Lv. 3)" },
    { id = 1501003594, id2 = 1501002594, name = "Amphibious Sage Backpack (Lv. 3)" },
    { id = 1501003598, id2 = 1501002598, name = "Anjat Backpack (Lv. 3)" },
    { id = 1501003599, id2 = 1501002599, name = "Manic Bunny Backpack (Lv. 3)" },
    { id = 1501003600, id2 = 1501002600, name = "Chaos Academy Backpack (Lv. 3)" },
    { id = 1501003601, id2 = 1501002601, name = "Heart Warden Backpack (Lv. 3)" },
    { id = 1501003602, id2 = 1501002602, name = "Pocong Wanderer Backpack (Lv. 3)" },
    { id = 1501003603, id2 = 1501002603, name = "Zooming Backpack (Lv. 3)" },
    { id = 1501003604, id2 = 1501002604, name = "Paranormal Feline Backpack (Lv. 3)" },
    { id = 1501003605, id2 = 1501002605, name = "Blackthorn Specter Backpack (Lv. 3)" },
    { id = 1501003606, id2 = 1501002606, name = "Cosmic Beast Backpack (Lv. 3)" },
    { id = 1501003607, id2 = 1501002607, name = "Vampiric Compulsion Backpack (Lv. 3)" },
    { id = 1501003608, id2 = 1501002608, name = "Brimstone Demise Backpack (Lv. 3)" },
    { id = 1501003609, id2 = 1501002609, name = "Spirit Sentry Backpack (Lv. 3)" },
    { id = 1501003610, id2 = 1501002610, name = "Underworld Aristocrat Backpack (Lv. 3)" },
    { id = 1501003611, id2 = 1501002611, name = "Winter Warrior Backpack (Lv. 3)" },
    { id = 1501003612, id2 = 1501002612, name = "Hypernova Fission Backpack (Lv. 3)" },
    { id = 1501003613, id2 = 1501002613, name = "Frosty Wildwood Backpack (Lv. 3)" },
    { id = 1501003614, id2 = 1501002614, name = "Skadiwynn Sentinel Backpack (Lv. 3)" },
    { id = 1501003615, id2 = 1501002615, name = "Royal Deeress Backpack (Lv. 3)" },
    { id = 1501003616, id2 = 1501002616, name = "PMGC × ROLLIO Backpack (Lv. 3)" },
    { id = 1501003617, id2 = 1501002617, name = "Penguin Pal Backpack (Lv. 3)" },
    { id = 1501003618, id2 = 1501002618, name = "Frostblade Snow Backpack (Lv. 3)" },
    { id = 1501003619, id2 = 1501002619, name = "Magical Charm Backpack (Lv. 3)" },
    { id = 1501003620, id2 = 1501002620, name = "Tundra Knight Backpack (Lv. 3)" },
    { id = 1501003621, id2 = 1501002621, name = "Darkrose Crystal Backpack (Lv. 3)" },
    { id = 1501003623, id2 = 1501002623, name = "Crate Glutton Backpack (Lv. 3)" },
    { id = 1501003624, id2 = 1501002624, name = "Dragontide Pulse Backpack (Lv. 3)" },
    { id = 1501003625, id2 = 1501002625, name = "Serpent's Treasure Backpack (Lv. 3)" },
    { id = 1501003626, id2 = 1501002626, name = "Gold Feather Mask Backpack (Lv. 3)" },
    { id = 1501003627, id2 = 1501002627, name = "Prowling Lion Head Backpack (Lv. 3)" },
    { id = 1501003628, id2 = 1501002628, name = "Ink Library Backpack (Lv. 3)" },
    { id = 1501003629, id2 = 1501002629, name = "Celestine Charm Backpack (Lv. 3)" },
    { id = 1501003630, id2 = 1501002630, name = "Deep Nocturne Backpack (Lv. 3)" },
    { id = 1501003631, id2 = 1501002631, name = "Elysian Bloom Backpack (Lv. 3)" },
    { id = 1501003633, id2 = 1501002633, name = "Neon Drop BE 6 Backpack (Lv. 3)" },
    { id = 1501003634, id2 = 1501002634, name = "Ecliptic Guardian Backpack (Lv. 3)" },
    { id = 1501003635, id2 = 1501002635, name = "Lazy Chomper Backpack (Lv. 3)" },
    { id = 1501003636, id2 = 1501002636, name = "Neon Renegade Backpack (Lv. 3)" },
    { id = 1501003637, id2 = 1501002637, name = "Godzilla King of the Monsters Backpack (Lv. 3)" },
    { id = 1501003638, id2 = 1501002638, name = "Foxie Moxie Backpack (Lv. 3)" },
    { id = 1501003639, id2 = 1501002639, name = "Serpent's Relic Backpack (Lv. 3)" },
    { id = 1501003640, id2 = 1501002640, name = "Corrupted Crown Backpack (Lv. 3)" },
    { id = 1501003641, id2 = 1501002641, name = "Sinister Bunny Backpack (Lv. 3)" },
    { id = 1501003642, id2 = 1501002642, name = "Goldensands Sentry Backpack (Lv. 3)" },
    { id = 1501003645, id2 = 1501002645, name = "Steam Paws Backpack (Lv. 3)" },
    { id = 1501003646, id2 = 1501002646, name = "Crocodile Backpack (Lv. 3)" },
    { id = 1501003647, id2 = 1501002647, name = "Skateboard Streak Backpack (Lv. 3)" },
    { id = 1501003648, id2 = 1501002648, name = "Scarlet Momentum Backpack (Lv. 3)" },
    { id = 1501003649, id2 = 1501002649, name = "Aetherflare Essence Backpack (Lv. 3)" },
    { id = 1501003650, id2 = 1501002650, name = "Colossal Titan Backpack (Lv. 3)" },
    { id = 1501003651, id2 = 1501002651, name = "Frostblue Fang Backpack (Lv. 3)" },
    { id = 1501003652, id2 = 1501002652, name = "Bloodcurse Core Backpack (Lv. 3)" },
    { id = 1501003653, id2 = 1501002653, name = "Glitchwave Shift Backpack (Lv. 3)" },
    { id = 1501003654, id2 = 1501002654, name = "Mad Lab Backpack (Lv. 3)" },
    { id = 1501003655, id2 = 1501002655, name = "Vinyl Wave Backpack (Lv. 3)" },
    { id = 1501003657, id2 = 1501002657, name = "Astral Anomaly Backpack (Lv. 3)" },
    { id = 1501003658, id2 = 1501002658, name = "Goldline Ace Backpack (Lv. 3)" },
    { id = 1501003659, id2 = 1501002659, name = "Cuddly Nailoong Backpack (Lv. 3)" },
    { id = 1501003660, id2 = 1501002660, name = "Destiny's Embrace Backpack (Lv. 3)" },
    { id = 1501003661, id2 = 1501002661, name = "Draconic Vault Backpack (Lv. 3)" },
    { id = 1501003662, id2 = 1501002662, name = "Nebula Valkyrie Backpack (Lv. 3)" },
    { id = 1501003663, id2 = 1501002663, name = "Prism Pod Backpack (Lv. 3)" },
    { id = 1501003664, id2 = 1501002664, name = "Sinkeeper's Coffer Backpack (Lv. 3)" },
    { id = 1501003665, id2 = 1501002665, name = "Captain Woof Backpack (Lv. 3)" },
    { id = 1501003666, id2 = 1501002666, name = "Starweld Engine Backpack (Lv. 3)" },
    { id = 1501003668, id2 = 1501002668, name = "Corrupted Crown Backpack (Lv. 3)" },
    { id = 1501003669, id2 = 1501002669, name = "Saccharine Riot Backpack (Lv. 3)" },
    { id = 1501003670, id2 = 1501002670, name = "Boxing Brawl Backpack (Lv. 3)" },
    { id = 1501003671, id2 = 1501002671, name = "Kaiju No. 8 Backpack (Lv. 3)" },
    { id = 1501003672, id2 = 1501002672, name = "Stellarwing Flutter Backpack (Lv. 3)" },
    { id = 1501003673, id2 = 1501002673, name = "Highstreet Haze Backpack (Lv. 3)" },
    { id = 1501003674, id2 = 1501002674, name = "Cotton Carnage Backpack (Lv. 3)" },
    { id = 1501003675, id2 = 1501002675, name = "Madcap Punk Backpack (Lv. 3)" },
    { id = 1501003676, id2 = 1501002676, name = "Specter Shrine Backpack (Lv. 3)" },
    { id = 1501003677, id2 = 1501002677, name = "Talisdrake Rift Backpack (Lv. 3)" },
    { id = 1501003678, id2 = 1501002678, name = "Colorburst Candy Backpack (Lv. 3)" },
    { id = 1501003679, id2 = 1501002679, name = "Spectral Dreamweaver Backpack (Lv. 3)" },
    { id = 1501003680, id2 = 1501002680, name = "Jungle Core Backpack (Lv. 3)" },
    { id = 1501003681, id2 = 1501002681, name = "Captain Cub Backpack (Lv. 3)" },
    { id = 1501003682, id2 = 1501002682, name = "Yarn Knight Backpack (Lv. 3)" },
    { id = 1501003683, id2 = 1501002683, name = "【entity-Balenciaga¦canonical_name=Balenciaga】 Backpack (Lv. 3)" },
    { id = 1501003684, id2 = 1501002684, name = "Whiteout Apex Backpack (Lv. 3)" },
    { id = 1501003685, id2 = 1501002685, name = "Onyxis Witch Backpack (Lv. 3)" },
    { id = 1501003686, id2 = 1501002686, name = "Blizzard Party Backpack (Lv. 3)" },
    { id = 1501003687, id2 = 1501002687, name = "Deathknell Shroud Backpack (Lv. 3)" },
    { id = 1501003688, id2 = 1501002688, name = "Polar Prism Backpack (Lv. 3)" },
    { id = 1501003689, id2 = 1501002689, name = "Snowy Weasel Backpack (Lv. 3)" },
    { id = 1501003690, id2 = 1501002690, name = "Melodic Crown Backpack (Lv. 3)" },
    { id = 1501003691, id2 = 1501002691, name = "Turbo Granny(Beckoning cat) Backpack (Lv. 3)" },
    { id = 1501003692, id2 = 1501002692, name = "Bamboo Treat Backpack (Lv. 3)" },
    { id = 1501003693, id2 = 1501002693, name = "Dune Prince Backpack (Lv. 3)" },
    { id = 1501003694, id2 = 1501002694, name = "Locked & Loaded Backpack (Lv. 3)" },
    { id = 1501003695, id2 = 1501002695, name = "Arcade KO Backpack (Lv. 3)" },
    { id = 1501003696, id2 = 1501002696, name = "Veiled Enchantress Backpack (Lv. 3)" },
    { id = 1501003697, id2 = 1501002697, name = "Celadon Aether Backpack (Lv. 3)" },
    { id = 1501003698, id2 = 1501002698, name = "Well of Souls Backpack (Lv. 3)" },
    { id = 1501003699, id2 = 1501002699, name = "Mystic Seal Backpack (Lv. 3)" },
    { id = 1501003700, id2 = 1501002700, name = "Fragmented Moon Backpack (Lv. 3)" },
    { id = 1501003701, id2 = 1501002701, name = "Auspicious Coffer Backpack (Lv. 3)" },
    { id = 1501003702, id2 = 1501002702, name = "Roadborn Rucksack Backpack (Lv. 3)" },
    { id = 1501003703, id2 = 1501002703, name = "【entity-Peaky Blinders¦canonical_name=Peaky Blinders】 Backpack (Lv. 3)" },
    { id = 1501003704, id2 = 1501002704, name = "S28 Backpack (Lv. 3)" },
    { id = 1501003705, id2 = 1501002705, name = "Twirling Sands Backpack (Lv. 3)" },
    { id = 1501003706, id2 = 1501002706, name = "Punk Vanguard Backpack (Lv. 3)" },
    { id = 1501003707, id2 = 1501002707, name = "Prison Realm Backpack (Lv. 3)" },
    { id = 1501003708, id2 = 1501002708, name = "Coldsteel Hacker Backpack (Lv. 3)" },
    { id = 1501003709, id2 = 1501002709, name = "Dynamic Realm Backpack (Lv. 3)" },
    { id = 1501003710, id2 = 1501002710, name = "Delicate Dance Backpack (Lv. 3)" },
    { id = 1501003711, id2 = 1501002711, name = "Multiverse Traveler Backpack (Lv. 3)" },
    { id = 1501003712, id2 = 1501002712, name = "Eternal Vigil Backpack (Lv. 3)" },
    { id = 1501003713, id2 = 1501002713, name = "Arcade Kitty Backpack (Lv. 3)" },
    { id = 1501003717, id2 = 1501002717, name = "S29 Backpack (Lv. 3)" },
    { id = 1501003718, id2 = 1501002718, name = "Queen of Suits Backpack (Lv. 3)" },
    { id = 1501003719, id2 = 1501002719, name = "Legendary Noble Backpack (Lv. 3)" },
    { id = 1501003720, id2 = 1501002720, name = "BLUE LOCK Backpack (Lv. 3)" },
    { id = 1501003721, id2 = 1501002721, name = "Speed Rush Backpack (Lv. 3)" },
    { id = 1501003722, id2 = 1501002722, name = "Rose Requiem Backpack (Lv. 3)" },
    { id = 1501003723, id2 = 1501002723, name = "Mimic Jester Backpack (Lv. 3)" },
    { id = 1501003724, id2 = 1501002724, name = "Dioscuri Backpack (Lv. 3)" },
    { id = 1501003725, id2 = 1501002725, name = "Serpent Handler Backpack (Lv. 3)" },
    { id = 1501003726, id2 = 1501002726, name = "Wrath of Retribution Backpack (Lv. 3)" },
    { id = 1501003727, id2 = 1501002727, name = "Temptuous Whisper Backpack (Lv. 3)" },
    { id = 1501003728, id2 = 1501002728, name = "Laurel Academy Backpack (Lv. 3)" },
    { id = 1501003729, id2 = 1501002729, name = "Field Frenzy Backpack (Lv. 3)" },
    { id = 1501003731, id2 = 1501002731, name = "Rock Reverb Backpack (Lv. 3)" },
    { id = 1501003732, id2 = 1501002732, name = "Psionic Electrobolt Backpack (Lv. 3)" },
    { id = 1501003733, id2 = 1501002733, name = "S30 Backpack (Lv. 3)" },
    { id = 1501003734, id2 = 1501002734, name = "Nightfall Stalker Backpack (Lv. 3)" },
    { id = 1501003735, id2 = 1501002735, name = "Pink Bunny Cadet Backpack (Lv. 3)" },
    { id = 1501003736, id2 = 1501002736, name = "Atlantean Ranger Backpack (Lv. 3)" },
    { id = 1501003737, id2 = 1501002737, name = "Track Legend Backpack (Lv. 3)" },
    { id = 1501003738, id2 = 1501002738, name = "【entity-Ferrari¦canonical_name=Ferrari】 Backpack (Lv. 3)" },
    { id = 1501003739, id2 = 1501002739, name = "Tide Tracker Backpack (Lv. 3)" },
    { id = 1501003740, id2 = 1501002740, name = "Sakura Neko Backpack (Lv. 3)" },
    { id = 1501003741, id2 = 1501002741, name = "Sanctuary Traveler Backpack (Lv. 3)" },
    { id = 1501003742, id2 = 1501002742, name = "NARUTO Ninja Scroll Backpack (Lv. 3)" },
    { id = 1501003743, id2 = 1501002743, name = "Tempting Nest Backpack (Lv. 3)" },
    { id = 1501003744, id2 = 1501002744, name = "Wave Cascade Backpack (Lv. 3)" },
    { id = 1501003745, id2 = 1501002745, name = "Dimensional Armory Backpack (Lv. 3)" },
    { id = 1501003748, id2 = 1501002748, name = "Cryo Core Backpack (Lv. 3)" },
    { id = 1501003750, id2 = 1501002750, name = "Voodoo Scarecrow Backpack (Lv. 3)" },
    { id = 1501003751, id2 = 1501002751, name = "Midnight Thorns Backpack (Lv. 3)" },
    { id = 1501003752, id2 = 1501002752, name = "Shiba Explorer Backpack (Lv. 3)" },
    { id = 1501003753, id2 = 1501002753, name = "One-Punch Man Backpack (Lv. 3)" },
    { id = 1501003754, id2 = 1501002754, name = "Collector's Pride Backpack (Lv. 3)" },
    { id = 1501003755, id2 = 1501002755, name = "B.Duck Playful Collectibles Backpack (Lv. 3)" },
    { id = 1501003756, id2 = 1501002756, name = "Wakala Backpack (Lv. 3)" },
    { id = 1501003757, id2 = 1501002757, name = "Orbital Rider Backpack (Lv. 3)" },
    { id = 1501003758, id2 = 1501002758, name = "Scorpius Casket Backpack (Lv. 3)" },
    { id = 1501003759, id2 = 1501002759, name = "Soulbind Traveler Backpack (Lv. 3)" },
    { id = 1501003760, id2 = 0, name = "Bloodrose Bond Backpack (Lv. 3)" },
    { id = 1501003761, id2 = 1501002761, name = "Annihilation Pact Backpack (Lv. 3)" },
    { id = 1501003762, id2 = 1501002762, name = "Cozy Coffin Backpack (Lv. 3)" },
    { id = 1501003764, id2 = 1501002764, name = "S32 Backpack (Lv. 3)" },
}

local function getPresetIndex(list, itemId)
    itemId = tonumber(itemId) or 0
    if itemId <= 0 then return 0 end
    for i, item in ipairs(list) do
        if item.id == itemId then return i end
    end
    return 0
end

local function getPresetLabel(list, itemId)
    itemId = tonumber(itemId) or 0
    if itemId <= 0 then return "Default / Not Set" end
    for _, item in ipairs(list) do
        if item.id == itemId then
            return item.name .. " | ID: " .. tostring(item.id)
        end
    end
    return "Custom ID: " .. tostring(itemId)
end

local function getIdListIndex(list, itemId)
    itemId = tonumber(itemId) or 0
    for i, id in ipairs(list) do
        if id == itemId then return i end
    end
    return 0
end

local function getIdListLabel(list, itemId, defaultId, itemType)
    itemId = tonumber(itemId) or 0
    if itemId <= 0 or itemId == defaultId then
        return "Default " .. itemType .. " | ID: " .. tostring(defaultId)
    end
    for i, id in ipairs(list) do
        if id == itemId then
            return itemType .. " option " .. tostring(i) .. " | ID: " .. tostring(id)
        end
    end
    return "Custom ID: " .. tostring(itemId)
end

-- Slot 5 detects whether the entered item is a full outfit or separate clothing.
-- Pants / shoes use the existing mutual-exclusion logic in Wumingking.SetSlot.
local INPUT_ITEMS = {
    { label = "Clothes / Outfit (Auto Detect)", slot = 5,
      help = "Slot 5 automatically detects a full outfit or separate clothing. A full outfit clears pants and shoes." },
    { label = "Hairstyle / Hair",               slot = 2 },
    { label = "Hat / Headwear",                 slot = 3 },
    { label = "Face Accessory",                 slot = 4 },
    { label = "Mask / Eyewear",                  slot = 12 },
    { label = "Pants",                          slot = 6,
      help = "Setting pants automatically exits full-outfit mode, using the existing wardrobe rules." },
    { label = "Shoes",                           slot = 7,
      help = "Setting shoes automatically exits full-outfit mode, using the existing wardrobe rules." },
    { label = "Custom Parachute ID (Manual)",    slot = 11,
      help = "Use the parachute slider above for listed IDs, or enter a custom ID. Input 0 restores default ID 1401469." },
    { label = "Custom Glider ID (Manual)",       slot = 15,
      help = "Use the glider slider above for listed IDs, or enter a custom ID. Input 0 restores default ID 4151133." },
}

    SST.BuildStack = function()
        local AM = getAliasMap(); if not AM then return nil end
        local C = _G.Wumingking
        local stack = {}

        table.insert(stack, { UI = AM.Title, Text = Reg("◆ FORMULA // CHARACTER STUDIO") })
        table.insert(stack, { UI = AM.Spacer, Height = 14 })

        -- ========== Pet ==========
table.insert(stack, { UI = AM.Title, Text = Reg("01 | COMPANION COLLECTION") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

local petList = SST.PET_SKIN_LIST or {}
local petCount = (#petList > 0 and #petList or 1)

-- ========== Pet Slider (Saves Real ID, Next Startup Reverse-Lookup Index by ID) ==========
table.insert(stack, {
    Key = "WK_PetSlider",
    UI = AM.Slider,
    Text = Reg("COMPANION SKIN PRESET"),
    Help = "Slide to switch pet (total " .. #petList .. " types)\nAfter saving, auto-locate on next startup",
    Min = 1,
    Max = petCount,
    IsPercent = false,
    GetFunc = function()
        -- 1) Read the real pet ID from wumingking.h (D.P)
        local petId = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            petId = _G.Wumingking.GetPet() or 0
        end

        -- 2) Reverse-lookup index -> locate slider
        if petId and petId > 0 then
            for i, id in ipairs(petList) do
                if id == petId then
                    return i
                end
            end
        end

        -- 3) Fallback: Use the index in memory
        local idx = _G.PetSkinMapIndex
        if type(idx) ~= "number" or idx < 1 then idx = 1 end
        idx = math.floor(idx)
        if idx < 1 then idx = 1 end
        if idx > petCount then idx = petCount end
        return idx
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 1)
        if idx < 1 then idx = 1 end
        if idx > petCount then idx = petCount end
        local petId = petList[idx]

        _G.PetSkinMapIndex = idx
        _G.PetSkin = petId

        -- Star Only save real ID to wumingking.h (do not save index, avoid two data sets conflicting)
        if _G.Wumingking and _G.Wumingking.SetPet then
            _G.Wumingking.SetPet(petId)
        end

        if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
        if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end

        print("[Pet] Switch to ID=" .. tostring(petId) .. " (index " .. tostring(idx) .. ")")
        return true
    end
})

-- ========== Pet ID Read-Only Display Box ==========
table.insert(stack, {
    Key = "WK_PetIDDisplay",
    UI = AM.OpenWindow,
    Text = Reg("    ↳ CURRENT COMPANION ID"),
    Help = "Read-only, tap to view currently effective pet ID",
    GetFunc = function()
        local petId = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            petId = _G.Wumingking.GetPet() or 0
        end
        if petId and petId > 0 then
            return tostring(petId)
        end
        return "Not Set"
    end,
    SetFunc = function()
        -- Read-only popup, viewable and copyable, no modification
        if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
        local cur = 0
        if _G.Wumingking and _G.Wumingking.GetPet then
            cur = _G.Wumingking.GetPet() or 0
        end
        _G.DazhiMH_Config.ShowNumberInputPopup({
            title = "Current Pet ID (read-only, use slider above to modify)",
            value = cur, min = 0, max = 9999999999,
            refreshKey = "WK_PetIDDisplay",
            onConfirm = function()
                -- Do nothing (read-only)
            end
        })
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ========== X-Suit Preset Slider ==========
table.insert(stack, { UI = AM.Title, Text = Reg("02 | X-SUIT COLLECTION") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })
table.insert(stack, {
    Key = "WK_XSuitPresetSlider",
    UI = AM.Slider,
    Text = Reg("X-SUIT PRESET"),
    Help = "Select a preset from the X-Suit collection. 0 restores the default outfit. The selected item ID is displayed below.",
    Min = 0,
    Max = #OUTFIT_XSUIT_SKINS,
    IsPercent = false,
    GetFunc = function()
        local current = 0
        if C and C.GetSuit then current = C.GetSuit() or 0
        elseif C and C.GetSlot then current = C.GetSlot(5) or 0 end
        return getPresetIndex(OUTFIT_XSUIT_SKINS, current)
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 0)
        if idx < 0 then idx = 0 end
        if idx > #OUTFIT_XSUIT_SKINS then idx = #OUTFIT_XSUIT_SKINS end
        local itemId = (idx == 0) and 0 or OUTFIT_XSUIT_SKINS[idx].id
        if not (C and C.SetSlot) then return false end
        C.SetSlot(5, itemId)
        if C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
        if C.ApplyToLobby then pcall(C.ApplyToLobby) end
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        return true
    end
})
table.insert(stack, {
    Key = "WK_XSuitPresetCurrent",
    UI = AM.OpenWindow,
    Text = Reg("    ↳ SELECTED X-SUIT / ID"),
    GetFunc = function()
        local current = 0
        if C and C.GetSuit then current = C.GetSuit() or 0
        elseif C and C.GetSlot then current = C.GetSlot(5) or 0 end
        return getPresetLabel(OUTFIT_XSUIT_SKINS, current)
    end,
    SetFunc = function() end
})
table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ========== Parachute Skin Preset Slider ==========
table.insert(stack, { UI = AM.Title, Text = Reg("03 | PARACHUTE COLLECTION") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })
table.insert(stack, {
    Key = "WK_ParachutePresetSlider",
    UI = AM.Slider,
    Text = Reg("PARACHUTE PRESET"),
    Help = "Browse the supplied parachute collection. 0 restores the default parachute; the active ID is displayed below.",
    Min = 0,
    Max = #PARACHUTE_SKINS,
    IsPercent = false,
    GetFunc = function()
        local id = (C and C.GetSlot and C.GetSlot(11)) or _G.ParachuteSkin or PARACHUTE_DEFAULT_ID
        return getIdListIndex(PARACHUTE_SKINS, id)
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 0)
        if idx < 0 then idx = 0 end
        if idx > #PARACHUTE_SKINS then idx = #PARACHUTE_SKINS end
        local itemId = (idx == 0) and PARACHUTE_DEFAULT_ID or PARACHUTE_SKINS[idx]
        if not (C and C.SetSlot) then return false end
        local ok = pcall(C.SetSlot, 11, itemId)
        if not ok then return false end
        if C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
        if C.ApplyToLobby then pcall(C.ApplyToLobby) end
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        return true
    end
})
table.insert(stack, {
    Key = "WK_ParachutePresetCurrent",
    UI = AM.OpenWindow,
    Text = Reg("    ↳ SELECTED PARACHUTE / ID"),
    GetFunc = function()
        local id = (C and C.GetSlot and C.GetSlot(11)) or _G.ParachuteSkin or PARACHUTE_DEFAULT_ID
        return getIdListLabel(PARACHUTE_SKINS, id, PARACHUTE_DEFAULT_ID, "Parachute")
    end,
    SetFunc = function() end
})
table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ========== Glider Skin Preset Slider ==========
table.insert(stack, { UI = AM.Title, Text = Reg("04 | GLIDER COLLECTION") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })
table.insert(stack, {
    Key = "WK_GliderPresetSlider",
    UI = AM.Slider,
    Text = Reg("GLIDER PRESET"),
    Help = "Browse the supplied glider collection. 0 restores the default glider; the active ID is displayed below.",
    Min = 0,
    Max = #GLIDER_SKINS,
    IsPercent = false,
    GetFunc = function()
        local id = (C and C.GetSlot and C.GetSlot(15)) or _G.GliderSkin or GLIDER_DEFAULT_ID
        return getIdListIndex(GLIDER_SKINS, id)
    end,
    SetFunc = function(_, value)
        local idx = math.floor(tonumber(value) or 0)
        if idx < 0 then idx = 0 end
        if idx > #GLIDER_SKINS then idx = #GLIDER_SKINS end
        local itemId = (idx == 0) and GLIDER_DEFAULT_ID or GLIDER_SKINS[idx]
        if not (C and C.SetSlot) then return false end
        local ok = pcall(C.SetSlot, 15, itemId)
        if not ok then return false end
        if C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
        if C.ApplyToLobby then pcall(C.ApplyToLobby) end
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        return true
    end
})
table.insert(stack, {
    Key = "WK_GliderPresetCurrent",
    UI = AM.OpenWindow,
    Text = Reg("    ↳ SELECTED GLIDER / ID"),
    GetFunc = function()
        local id = (C and C.GetSlot and C.GetSlot(15)) or _G.GliderSkin or GLIDER_DEFAULT_ID
        return getIdListLabel(GLIDER_SKINS, id, GLIDER_DEFAULT_ID, "Glider")
    end,
    SetFunc = function() end
})
table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ========== Character Clothing / Outfit / Accessories ==========
table.insert(stack, { UI = AM.Title, Text = Reg("05 | OUTFIT & ACCESSORIES") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

for _, item in ipairs(INPUT_ITEMS) do
    local slotId = item.slot
    local key = "WK_Outfit_" .. slotId

    table.insert(stack, {
        Key = key, UI = AM.OpenWindow, Text = Reg(item.label),
        Help = item.help or "Enter the skin item ID. Input 0 reloads the value saved in the configuration.",
        GetFunc = function()
            local v = (C and C.GetSlot and C.GetSlot(slotId)) or 0
            if v and v > 0 then return tostring(v) end
            return "Not Set"
        end,
        SetFunc = function()
            if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
            local cur = (C and C.GetSlot and C.GetSlot(slotId)) or 1
            _G.DazhiMH_Config.ShowNumberInputPopup({
                title = item.label .. " (Input 0=Use config saved value)",
                value = cur, min = 0, max = 9999999999,
                refreshKey = key,
                onConfirm = function(v)
                    v = math.floor(tonumber(v) or 0)
                    if v < 0 then v = 0 end

                    -- Star Parachute / Glider: 0 forces default value (100% installed)
                    if slotId == 11 and v <= 0 then v = 1401469 end
                    if slotId == 15 and v <= 0 then v = 4151133 end

                    if v == 0 then
                        if C and C.Load then C.Load() end
                        if C and C.ApplyToGlobals then C.ApplyToGlobals() end
                    else
                        if C and C.SetSlot then C.SetSlot(slotId, v) end
                        if C and C.ApplyToGlobals then C.ApplyToGlobals() end
                    end

                    pcall(function()
                        if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                            _G.Wumingking.ApplyToLobby()
                        end
                    end)
                end
            })
        end
    })
    table.insert(stack, { UI = AM.Spacer, Height = 5 })
end

-- ==================== Star Star Star Garage Display Vehicle Series Selection Star Star Star ====================
table.insert(stack, { UI = AM.Spacer, Height = 15 })
table.insert(stack, { UI = AM.Title, Text = Reg("06 | GARAGE DISPLAY") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "GarageBrandMode",
    UI = AM.Switcher,
    Text = Reg("Select Default Display Vehicle Series"),
    Help = "Select series shown when entering garage theme\n1=Ferrari Series\n2=Bugatti Series\n3=Lamborghini Series",
    SwitcherText = { Reg("Ferrari"), Reg("Bugatti"), Reg("Lamborghini") },
    SwitcherValue = { 1, 2, 3 },
    GetFunc = function()
        return DazhiMH_Config.Get("GARAGE_BRAND", 1)
    end,
    SetFunc = function(_, value)
        value = tonumber(value) or 1
        DazhiMH_Config.Set("GARAGE_BRAND", value)
        
        -- Immediately force-refresh garage model
        pcall(function()
            local MM = require("client.module_framework.ModuleManager")
            local mgr = MM.GetModule(MM.LobbyModuleConfig.ThemeVehicleManager)
            if mgr then
                if mgr._ShowSelfVehicle then mgr:_ShowSelfVehicle() end
                if mgr.OnVehicleChange then mgr:OnVehicleChange() end
            end
        end)
        return true
    end
})
table.insert(stack, { UI = AM.Spacer, Height = 15 })


-- ==================== Gloves Beautify / Gloves ====================
table.insert(stack, { UI = AM.Title, Text = Reg("07 | GLOVE CUSTOMIZATION") })
table.insert(stack, { UI = AM.Spacer, Height = 6 })

table.insert(stack, {
    Key = "WK_GlovesInput",
    UI = AM.OpenWindow,
    Text = Reg("GLOVE SKIN ID"),
    Help = "1=Hide Gloves (450001)\n2=Frost (452001)\n3=Ink (452002)\n4=Quicksand (452003)\n5=Spider Silk (452004)\n6=Swing (452105)\nInput 0=Do Not Modify\nInput Other Number=Use That ID Directly",
    GetFunc = function()
        local v = (C and C.GetSlot and C.GetSlot(16)) or 0
        -- If internally saved is hidden glove ID, UI directly shows "Not Set"
        if v == 450001 or v == 0 then
            return "Not Set"
        end
        return tostring(v)
    end,
    SetFunc = function()
        if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
        local cur = (C and C.GetSlot and C.GetSlot(16)) or 0
        if cur == 450001 then cur = 1 end -- If currently hidden, popup shows 1 by default
        
        _G.DazhiMH_Config.ShowNumberInputPopup({
            title = "Input 1~6 quick select, or fill glove ID\n(1=Hide, 2=Frost, 3=Ink, 4=Quicksand, 5=Spider Silk, 6=Swing)",
            value = cur, min = 0, max = 9999999999,
            refreshKey = "WK_GlovesInput",
            onConfirm = function(v)
                v = math.floor(tonumber(v) or 0)
                
                -- Star Shortcut code mapping table
                local GLOVE_MAP = {
                    [1] = 450001, -- Hide gloves / No-glove model
                    [2] = 452001,
                    [3] = 452002,
                    [4] = 452003,
                    [5] = 452004,
                    [6] = 452105,
                }
                
                local targetId = v
                if GLOVE_MAP[v] then
                    targetId = GLOVE_MAP[v]
                end
                
                -- Input 0 also means hide gloves (fallback)
                if v == 0 then
                    targetId = 450001
                end

                -- 1. Save to config and apply
                if C and C.SetSlot then C.SetSlot(16, targetId) end
                _G.GlovesSkin = targetId

                if C and C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
                pcall(function()
                    if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                        _G.Wumingking.ApplyToLobby()
                    end
                end)
                if _G.GameAvatarHandlerplayers then
                    pcall(_G.GameAvatarHandlerplayers)
                end
            end
        })
    end
})

table.insert(stack, {
    Key = "WK_GlovesHideOnGun",
    UI = AM.Switcher,
    Text = Reg("HIDE GLOVES WHILE HOLDING A WEAPON"),
    Help = "After enabling, auto-hide gloves when holding gun, restore when holstering / bare hands",
    GetFunc = function()
        return (DazhiMH_Config.Get("GLOVES_HIDE_ON_GUN", 0) == 1)
    end,
    SetFunc = function(_, value)
        DazhiMH_Config.Set("GLOVES_HIDE_ON_GUN", value and 1 or 0)
        if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
        return true
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 15 })

-- ==================== Feature Toggles / Functional Toggles ====================
table.insert(stack, { UI = AM.Title, Text = Reg("08 | PERFORMANCE OPTIONS") })
table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_GrenadeFastRefresh",
    UI = AM.Switcher,
    Text = Reg("GRENADE SKIN FAST REFRESH"),
    Help = "After enabling, grenade skin refresh rate greatly increases\n(Note: May increase power consumption slightly)",
    GetFunc = function() return DazhiMH_Config.Get("GRENADE_FAST_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("GRENADE_FAST_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_WeaponFastRefresh",
    UI = AM.Switcher,
    Text = Reg("WEAPON & ATTACHMENT FAST REFRESH"),
    Help = "After enabling, weapon and attachment refresh interval shortened to 1 sec\nOff keeps default 1.5 sec",
    GetFunc = function() return DazhiMH_Config.Get("WEAPON_FAST_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("WEAPON_FAST_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 5 })

table.insert(stack, {
    Key = "WK_WeaponBackRefresh",
    UI = AM.Switcher,
    Text = Reg("REFRESH WEAPONS ON BACK"),
    Help = "After enabling, guns picked up on back also auto-refresh skin\nOff means only refresh when held in hand",
    GetFunc = function() return DazhiMH_Config.Get("WEAPON_BACK_REFRESH", 0) == 1 end,
    SetFunc = function(_, value) 
        DazhiMH_Config.Set("WEAPON_BACK_REFRESH", value and 1 or 0) 
        return true 
    end
})

table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== Paired Backpack Level 3 + Level 2 Preset Slider ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("09 | BACKPACK PRESETS - LEVEL 3 + LEVEL 2") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })
        table.insert(stack, {
            Key = "WK_BackpackLv3Slider",
            UI = AM.Slider,
            Text = Reg("BACKPACK PRESET - LEVEL 3 / LEVEL 2"),
            Help = "Select one Level-3 preset; its matching Level-2 backpack skin ID is applied too. 0 = Default for both levels.",
            Min = 0,
            Max = #BACKPACK_LV3_SKINS,
            IsPercent = false,
            GetFunc = function()
                local id = (C and C.GetLevelSkin and C.GetLevelSkin(8, 3)) or DazhiMH_Config.Get("BACKPACK3", 0)
                return getPresetIndex(BACKPACK_LV3_SKINS, id)
            end,
            SetFunc = function(_, value)
                local idx = math.floor(tonumber(value) or 0)
                if idx < 0 then idx = 0 end
                if idx > #BACKPACK_LV3_SKINS then idx = #BACKPACK_LV3_SKINS end

                local preset = (idx > 0) and BACKPACK_LV3_SKINS[idx] or nil
                local backpackLv3Id = preset and (tonumber(preset.id) or 0) or 0
                local backpackLv2Id = preset and (tonumber(preset.id2) or 0) or 0

                -- Save/apply both backpack levels independently through the existing multi-level config system.
                DazhiMH_Config.Set("BACKPACK3", backpackLv3Id)
                DazhiMH_Config.Set("BACKPACK2", backpackLv2Id)

                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })
        table.insert(stack, {
            Key = "WK_BackpackLv3Current",
            UI = AM.OpenWindow,
            Text = Reg("    ↳ SELECTED BACKPACK / LEVEL 3 + LEVEL 2 IDs"),
            GetFunc = function()
                local id = (C and C.GetLevelSkin and C.GetLevelSkin(8, 3)) or DazhiMH_Config.Get("BACKPACK3", 0)
                for _, preset in ipairs(BACKPACK_LV3_SKINS) do
                    if preset.id == tonumber(id) then
                        local lv2 = tonumber(preset.id2) or 0
                        local lv2Text = (lv2 > 0) and tostring(lv2) or "No matching Lv. 2 ID"
                        return preset.name .. " | Lv. 3 ID: " .. tostring(preset.id) .. " | Lv. 2 ID: " .. lv2Text
                    end
                end
                return getPresetLabel(BACKPACK_LV3_SKINS, id)
            end,
            SetFunc = function() end
        })
        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== Backpack Toggle (On=450001, Off=Restore Saved Per-Level Config) ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("10 | BACKPACK CONFIGURATION") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_BackpackSwitch",
            UI = AM.Switcher,
            Text = Reg("HIDE BACKPACK"),
            Help = "On: Temporarily force all backpack levels to 450001\nOff: Restore each level's saved skin ID",
            GetFunc = function()
                return _G.Backpack1Skin == 450001 and _G.Backpack2Skin == 450001
                    and _G.Backpack3Skin == 450001 and _G.Backpack4Skin == 450001
                    and _G.Backpack5Skin == 450001 and _G.Backpack6Skin == 450001
            end,
            SetFunc = function(_, value)
                _G.__WM_ForceBackpackSkin = value and true or false
                if C and C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
                if C and C.ApplyToLobby then pcall(C.ApplyToLobby) end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== Paired Helmet Level 3 + Level 2 Preset Slider ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("11 | HELMET PRESETS - LEVEL 3 + LEVEL 2") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })
        table.insert(stack, {
            Key = "WK_HelmetLv3Slider",
            UI = AM.Slider,
            Text = Reg("HELMET PRESET - LEVEL 3 / LEVEL 2"),
            Help = "Select one Level-3 preset; its matching Level-2 skin ID is applied too. 0 = Default for both levels.",
            Min = 0,
            Max = #HELMET_LV3_SKINS,
            IsPercent = false,
            GetFunc = function()
                local id = (C and C.GetLevelSkin and C.GetLevelSkin(9, 3)) or DazhiMH_Config.Get("HELMET3", 0)
                return getPresetIndex(HELMET_LV3_SKINS, id)
            end,
            SetFunc = function(_, value)
                local idx = math.floor(tonumber(value) or 0)
                if idx < 0 then idx = 0 end
                if idx > #HELMET_LV3_SKINS then idx = #HELMET_LV3_SKINS end

                local preset = (idx > 0) and HELMET_LV3_SKINS[idx] or nil
                local helmetLv3Id = preset and (tonumber(preset.id) or 0) or 0
                local helmetLv2Id = preset and (tonumber(preset.id2) or 0) or 0

                -- Save/apply both levels independently through the existing multi-level config system.
                DazhiMH_Config.Set("HELMET3", helmetLv3Id)
                DazhiMH_Config.Set("HELMET2", helmetLv2Id)

                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })
        table.insert(stack, {
            Key = "WK_HelmetLv3Current",
            UI = AM.OpenWindow,
            Text = Reg("    ↳ SELECTED HELMET / LEVEL 3 + LEVEL 2 IDs"),
            GetFunc = function()
                local id = (C and C.GetLevelSkin and C.GetLevelSkin(9, 3)) or DazhiMH_Config.Get("HELMET3", 0)
                for _, preset in ipairs(HELMET_LV3_SKINS) do
                    if preset.id == tonumber(id) then
                        local lv2 = tonumber(preset.id2) or 0
                        local lv2Text = (lv2 > 0) and tostring(lv2) or "No matching Lv. 2 ID"
                        return preset.name .. " | Lv. 3 ID: " .. tostring(preset.id) .. " | Lv. 2 ID: " .. lv2Text
                    end
                end
                return getPresetLabel(HELMET_LV3_SKINS, id)
            end,
            SetFunc = function() end
        })
        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== Helmet Toggle (On=450001, Off=Restore Saved Per-Level Config) ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("12 | HELMET CONFIGURATION") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_HelmetSwitch",
            UI = AM.Switcher,
            Text = Reg("HIDE HELMET"),
            Help = "On: Temporarily force all helmet levels to 450001\nOff: Restore each level's saved skin ID",
            GetFunc = function()
                return _G.Helmet1Skin == 450001 and _G.Helmet2Skin == 450001
                    and _G.Helmet3Skin == 450001 and _G.Helmet4Skin == 450001
                    and _G.Helmet5Skin == 450001 and _G.Helmet6Skin == 450001
            end,
            SetFunc = function(_, value)
                _G.__WM_ForceHelmetSkin = value and true or false
                if C and C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
                if C and C.ApplyToLobby then pcall(C.ApplyToLobby) end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        table.insert(stack, { UI = AM.Spacer, Height = 15 })

        -- ========== Bulletproof Vest Toggle (Exception: Off=Restore Original) ==========
        table.insert(stack, { UI = AM.Title, Text = Reg("13 | ARMOR CONFIGURATION") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_ArmorSwitch",
            UI = AM.Switcher,
            Text = Reg("ENABLE ARMOR OVERRIDE"),
            Help = "On: All level bulletproof vests show 450001 skin\nOff: Restore original",
            GetFunc = function()
                return _G.Armor1Skin == 450001 and _G.Armor2Skin == 450001
                    and _G.Armor3Skin == 450001 and _G.Armor4Skin == 450001
                    and _G.Armor5Skin == 450001 and _G.Armor6Skin == 450001
            end,
            SetFunc = function(_, value)
                _G.__WM_ForceArmorSkin = value and true or false
                if C and C.ApplyToGlobals then pcall(C.ApplyToGlobals) end
                if C and C.ApplyToLobby then pcall(C.ApplyToLobby) end
                if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                return true
            end
        })

        -- ========== Warning Clear Config Button ==========
        table.insert(stack, { UI = AM.Spacer, Height = 20 })
        table.insert(stack, { UI = AM.Title, Text = Reg("14 | DANGER ZONE - CONFIGURATION RESET") })
        table.insert(stack, { UI = AM.Spacer, Height = 5 })

        table.insert(stack, {
            Key = "WK_ClearAll",
            UI = AM.OpenWindow,
            Text = Reg("RESET ALL SAVED CONFIGURATIONS"),
            Help = "Clear all saved skin configs (clothes/outfit/headwear/mask/weapon/pet/vehicle/feature toggles)\nWarning: Irreversible!",
            GetFunc = function()
                return "Click to Clear"
            end,
            SetFunc = function()
                if not (_G.DazhiMH_Config and _G.DazhiMH_Config.ShowNumberInputPopup) then return end
                _G.DazhiMH_Config.ShowNumberInputPopup({
                    title = "Confirm clear all configs? Input 1 to confirm, other values cancel",
                    value = 0, min = 0, max = 1,
                    refreshKey = "WK_ClearAll",
                    onConfirm = function(v)
                        if tonumber(v) == 1 then
                            if _G.Wumingking and _G.Wumingking.ClearAll then
                                _G.Wumingking.ClearAll()
                            end
                        else
                            print("[Wumingking] User cancelled clear")
                        end
                    end
                })
            end
        })

        return stack
    end
end

    _G.__DazhiMH_CachedCustomPages = nil
    _G.__DazhiMH_SettingMainPatched = nil
    _G.__DazhiMH_SettingHooksInstalled = nil
end


-- ==================== Hair Lock Guard (Prevent Loss on Rebuild) ====================
-- As long as _G.HairSkin > 0, no matter how character rebuilds / changes outfit / enters-exits match,
-- Always force keep configured hair. Only changing settings can change it.
-- Core idea: Hook OnRep_BodySlotStateChanged -> Fix immediately after rebuild completes
pcall(function()
    if _G.__HairGuardInstalled then return end
    _G.__HairGuardInstalled = true

    local HAIR_SLOT = 2

    local function getComp(target)
        if not target or not slua.isValid(target) then return nil end
        local comp = target.AvatarComponent2
        if comp and slua.isValid(comp) then return comp end
        pcall(function()
            if target.getAvatarComponent2 then
                local c = target:getAvatarComponent2()
                if c and slua.isValid(c) then comp = c end
            end
        end)
        return comp
    end

    local function fixHair(comp)
    -- Star Star Star Core Fix: If Switching Lobby Theme or Just Exited Match, Skip Fix, Avoid Interrupting Game Native Model Rebuild Star Star Star
    if _G.__IsThemeSwitching or _G.__justExitedMatch then return end
    if not comp or not slua.isValid(comp) then return end
    local hair = _G.HairSkin or 0

        local ad
        pcall(function()
            local nad = comp.NetAvatarData
            if nad and slua.isValid(nad) then ad = nad.SlotSyncData end
        end)
        if not ad then return end

        local idx, cur = -1, 0
        for i = 0, ad:Num() - 1 do
            local e = ad:Get(i)
            if e and e.SlotID == HAIR_SLOT then idx = i; cur = e.ItemId or 0; break end
        end

        if idx < 0 then
            ad:Add({ SlotID = HAIR_SLOT, ItemId = hair })
        elseif cur == hair then
            return   -- Already correct, do not trigger again
        else
            local e = ad:Get(idx)
            e.ItemId = hair
            ad:Set(idx, e)
        end

        -- Notify rebuild (use flag to avoid mutual recursion with Hook)
        comp.__hairGuardSuppress = true
        pcall(function()
            if comp.OnRep_BodySlotStateChanged then
                comp.OnRep_BodySlotStateChanged(comp)
            end
        end)
        comp.__hairGuardSuppress = false
        print("[HairGuard] Fix hair -> " .. tostring(hair))
    end

    local function hookComp(target, tag)
        local comp = getComp(target)
        if not comp then return false end
        if comp.__hairGuardHooked then
            -- Already hooked, fix once along the way
            pcall(fixHair, comp)
            return true
        end
        comp.__hairGuardHooked = true

        local orig = comp.OnRep_BodySlotStateChanged
if type(orig) == "function" then
    comp.OnRep_BodySlotStateChanged = function(self, ...)
        if orig then orig(self, ...) end
        -- Key: Only fix when not called inside our own fixHair, avoid infinite loop
        if not self.__hairGuardSuppress then
            -- Star Star Star Core Fix: Add 0.5 Sec Debounce Delay, Wait for Model Skeleton to Fully Load Before Fixing Star Star Star
            if self.__hairGuardTimer then
                pcall(function() _G.Mytimer_ticker.RemoveTimer(self.__hairGuardTimer) end)
            end
            if _G.Mytimer_ticker then
                self.__hairGuardTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                    if slua.isValid(self) and not self.__hairGuardSuppress then
                        pcall(fixHair, self)
                    end
                end)
            else
                pcall(fixHair, self)
            end
        end
    end
            print("[HairGuard] Hook OnRep: " .. tag)
            pcall(fixHair, comp)
            return true
        end
        return false
    end

    local function tryHookAll()
        -- Lobby character
        pcall(function()
            local LAM = require("client.logic.avatar.LobbyAvatarManager")
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    hookComp(v, "Lobby")
                    break
                end
            end
        end)
        -- Match character
        pcall(function()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if pc and slua.isValid(pc) then
                local ch = pc:GetPlayerCharacterSafety()
                if ch and slua.isValid(ch) then
                    hookComp(ch, "Match")
                end
            end
        end)
    end

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1.5, tryHookAll)
        -- Re-hook every 1 sec (Hook will be lost after character rebuild, need to re-hook to new component)
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(tryHookAll)
        end, -1, 1)
    else
        tryHookAll()
    end

    print("[HairGuard] Hair Lock Guard started")
end)


-- ============================================================
-- ★★★ Lobby Theme Auto-Refresh (HallThemeSync v2 Fixed Version)★★★
-- Fix:
--   1. Path priority: Use the actual wumingking.h path, avoid writing the wrong file with multiple package names
--   2. Verify the file exists before writing to disk, do not create it if it does not exist (prevent clearing the config)
--   3. ProcPutOnHook reads from both [parameters] and [self fields], taking the first valid value
--   4. Save loop only captures "in-game active switch" outside the lock period, does not overwrite the user's expected value
--   5. User operation lock from 10 sec -> 30 sec, to prevent being overwritten during async rebound
-- ============================================================
_G.HallThemeSync = _G.HallThemeSync or {}
do
    local HTS = _G.HallThemeSync
    local KEY = "BACKGROUND"
    local KEY_INST = "BACKGROUND_INST"

    -- ========== State Variables ==========
    local autoApplyTargetItem = 0
    local autoApplyTargetInst = 0
    local _inLobby = false
    local _lastSavedItem = -1
    local _lastForceApplyAt = 0
    local _expectedItemId = 0
    local _expectedInstId = 0
    local _userChangeLockUntil = 0

    -- ★★★ Fix 1: Path Priority Use Wumingking Actual Path ★★★
    local function GetWuming()
        -- 1) Wumingking already initialized (most accurate, locate by current package name)
        local W = _G.Wumingking
        if W and type(W.Path) == "string" and W.Path ~= "" then
            return W.Path
        end
        -- 2) Dynamically locate by current package name
        if _G.GetCurrentWumingPath then
            local p = _G.GetCurrentWumingPath()
            if p then return p end
        end
        -- 3) Fallback: Iterate (may write the wrong file, but at least not nil)
        local OBB_DIRS = {
            "/storage/emulated/0/Android/obb/com.tencent.ig/",
            "/storage/emulated/0/Android/obb/com.pubg.krmobile/",
            "/storage/emulated/0/Android/obb/com.vng.pubgmobile/",
            "/storage/emulated/0/Android/obb/com.rekoo.pubgm/",
            "/storage/emulated/0/Android/obb/com.pubg.imobile/",
        }
        for _, d in ipairs(OBB_DIRS) do
            local f = io.open(d .. "wumingking.h", "r")
            if f then f:close(); return d .. "wumingking.h" end
        end
        return OBB_DIRS[1] .. "wumingking.h"
    end

    local function GetThemeMod()
        local ok, m = pcall(require, "client.logic.lobby.hall_theme_utils")
        if ok and m then return m end
    end

    local function ReadKey(k)
        local f = io.open(GetWuming(), "r")
        if not f then return 0 end
        local val = 0
        for line in f:lines() do
            local kk, vv = line:match("^%s*([%w_]+)%s*=%s*(%d+)")
            if kk == k then val = tonumber(vv) or 0 end
        end
        f:close()
        return val
    end

    -- ★★★ Fix 2: Skip If File Does Not Exist, Never Create Empty File Containing Only BACKGROUND ★★★
    local function WriteKey(k, v)
        v = math.floor(tonumber(v) or 0)
        local p = GetWuming()
        local probe = io.open(p, "r")
        if not probe then
            -- File does not exist -> Means Wumingking not initialized yet, skip this time
            print("[HallThemeSync] WARN: Config file does not exist, skip writing " .. k .. "=" .. v)
            return false
        end
        local lines, replaced = {}, false
        for line in probe:lines() do
            local kk = line:match("^%s*([%w_]+)%s*=")
            if kk == k then
                lines[#lines+1] = k .. "=" .. tostring(v)
                replaced = true
            else
                lines[#lines+1] = line
            end
        end
        probe:close()
        if not replaced then lines[#lines+1] = k .. "=" .. tostring(v) end
        local w = io.open(p, "w")
        if not w then return false end
        w:write(table.concat(lines, "\n") .. "\n")
        w:close()
        return true
    end

    function HTS.ReadSaved()       return ReadKey(KEY) end
    function HTS.WriteSaved(id)    return WriteKey(KEY, id) end
    function HTS.ReadSavedInst()   return ReadKey(KEY_INST) end
    function HTS.WriteSavedInst(v) return WriteKey(KEY_INST, v) end

    -- ========== Install Hook ==========
    local function InstallHooks()
        local m = GetThemeMod()
        if not m then return false end

        if not m._HookedGetCurShow and type(m.GetCurShowThemeItemId) == "function" then
            m._origGetCurShow = m.GetCurShowThemeItemId
            m.GetCurShowThemeItemId = function(self, ...)
                if autoApplyTargetItem > 0 then
                    return autoApplyTargetItem
                end
                return m._origGetCurShow(self, ...)
            end
            m._HookedGetCurShow = true
        end

        if not m._HookedGetInst and type(m.GetThemeInstId) == "function" then
            m._origGetInst = m.GetThemeInstId
            m.GetThemeInstId = function(self, ...)
                if autoApplyTargetInst > 0 then
                    return autoApplyTargetInst
                end
                return m._origGetInst(self, ...)
            end
            m._HookedGetInst = true
        end

        -- ★★★ Fix 3: ProcPutOnHallTheme reads from params + self both sides ★★★
        if not m._HookedProcPutOn and type(m.ProcPutOnHallTheme) == "function" then
            m._origProcPutOn = m.ProcPutOnHallTheme
            m.ProcPutOnHallTheme = function(self, ...)
                -- ForceApply internal call -> Pass through directly (avoid triggering save recursively)
                if autoApplyTargetItem > 0 then
                    return m._origProcPutOn(self, ...)
                end

                -- Find itemId / instId from parameters (supports number / table two forms)
                local args = { n = select("#", ...), ... }
                local wantItem, wantInst = 0, 0
                for i = 1, args.n do
                    local v = args[i]
                    if type(v) == "number" and v > 0 then
                        if wantItem == 0 then wantItem = v
                        elseif wantInst == 0 then wantInst = v end
                    elseif type(v) == "table" then
                        local a = tonumber(v.itemId or v.themeItemId or v.homeThemeItemId or v.id)
                        local b = tonumber(v.instId or v.themeInstId or v.homeThemeInstId)
                        if a and a > 0 and wantItem == 0 then wantItem = a end
                        if b and b > 0 and wantInst == 0 then wantInst = b end
                    end
                end

                -- Parameter not given -> Read self field
                if wantItem == 0 then
                    wantItem = tonumber(self.homeThemeItemId) or 0
                end
                if wantInst == 0 then
                    wantInst = tonumber(self.homeThemeInstId) or 0
                end

                local ret = m._origProcPutOn(self, ...)

                if wantItem > 0 then
                    _expectedItemId = wantItem
                    _expectedInstId = wantInst
                    _userChangeLockUntil = os.clock() + 30   -- Star Lock 30 sec
                    _lastSavedItem = wantItem
                    _lastForceApplyAt = os.clock()
                    HTS.WriteSaved(wantItem)
                    if wantInst > 0 then HTS.WriteSavedInst(wantInst) end
                    print(string.format("[HallThemeSync] User applied theme: item=%d inst=%d(Locked 30 sec)",
                        wantItem, wantInst))
                else
                    -- Star Fallback: When hook gets no value, delay 0.3 sec then read self field
                    local tt = _G.Mytimer_ticker
                    if tt and tt.AddTimer then
                        tt.AddTimer(0.3, function()
                            local m2 = GetThemeMod()
                            if not m2 then return end
                            local it = tonumber(m2.homeThemeItemId) or 0
                            local ins = tonumber(m2.homeThemeInstId) or 0
                            if it > 0 and it ~= _lastSavedItem then
                                _expectedItemId = it
                                _expectedInstId = ins
                                _userChangeLockUntil = os.clock() + 30
                                _lastSavedItem = it
                                _lastForceApplyAt = os.clock()
                                HTS.WriteSaved(it)
                                if ins > 0 then HTS.WriteSavedInst(ins) end
                                print(string.format("[HallThemeSync] Fallback delayed save: item=%d", it))
                            end
                        end)
                    end
                end
                return ret
            end
            m._HookedProcPutOn = true
        end

        return true
    end

    -- On entering lobby restore last saved theme (no user operation involved)
    function HTS.ForceApply()
        local m = GetThemeMod()
        if not m then return end
        local targetItem = HTS.ReadSaved()
        local targetInst = HTS.ReadSavedInst()
        if targetItem <= 0 then return end

        local cur = tonumber(m.homeThemeItemId) or 0
        if cur == targetItem then return end

        autoApplyTargetItem = targetItem
        autoApplyTargetInst = targetInst
        pcall(function()
            if m.ProcPutOnHallTheme then
                m:ProcPutOnHallTheme()
            end
        end)
        autoApplyTargetItem = 0
        autoApplyTargetInst = 0
        m.homeThemeItemId = targetItem
        if targetInst > 0 then
            m.homeThemeInstId = targetInst
        end
        _lastForceApplyAt = os.clock()
    end

    local function Attach()
        local t = _G.Mytimer_ticker
        if not t then
            local ok, tk = pcall(require, "common.time_ticker")
            if ok then t = tk end
        end
        if not t or not t.AddTimerLoop then return false end

        if not InstallHooks() then
            t.AddTimer(2, InstallHooks)
            t.AddTimer(5, InstallHooks)
            t.AddTimer(10, InstallHooks)
        end

        -- ========== Enter Lobby Detection + Restore ==========
        t.AddTimerLoop(1, function()
            pcall(function()
                local curInLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true

                if curInLobby and not _inLobby then
                    _inLobby = true
                    _lastSavedItem = -1
                    _expectedItemId = 0
                    _expectedInstId = 0
                    _userChangeLockUntil = 0

                    for _, delay in ipairs({0.5, 1.5, 3.0, 5.0, 8.0}) do
                        t.AddTimer(delay, function()
                            if os.clock() < _userChangeLockUntil then return end
                            local m = GetThemeMod()
                            if m then
                                local target = HTS.ReadSaved()
                                if target > 0 and tonumber(m.homeThemeItemId) ~= target then
                                    pcall(HTS.ForceApply)
                                end
                            end
                        end)
                    end
                elseif not curInLobby and _inLobby then
                    _inLobby = false
                end
            end)
        end, -1, 1)

        -- ========== Guard Loop (1.5 sec)==========
        t.AddTimerLoop(1.5, function()
            pcall(function()
                if not _inLobby then return end
                if os.clock() < _userChangeLockUntil then return end   -- Do not move during user operation lock period

                local m = GetThemeMod()
                if not m then return end

                local target = _expectedItemId
                if target <= 0 then target = HTS.ReadSaved() end
                if target <= 0 then return end

                local cur = tonumber(m.homeThemeItemId) or 0
                if cur == target then return end

                local now = os.clock()
                if now - _lastForceApplyAt > 3.0 then
                    m.homeThemeItemId = target
                    local wantInst = _expectedInstId
                    if wantInst <= 0 then wantInst = HTS.ReadSavedInst() end
                    if wantInst > 0 then m.homeThemeInstId = wantInst end
                    _lastForceApplyAt = now
                    print(string.format("[HallThemeSync] Guard: Bounced back -> Force back item=%d(Silent)", target))
                end
            end)
        end, -1, 1)

        -- ========== Save Loop (1 sec) -- Only Capture "In-Game Active Switch" ==========
        t.AddTimerLoop(1, function()
            pcall(function()
                if not _inLobby then return end
                if os.clock() < _userChangeLockUntil then return end

                local m = GetThemeMod()
                if not m then return end
                local item = tonumber(m.homeThemeItemId) or 0
                local inst = tonumber(m.homeThemeInstId) or 0

                -- Star Key fix: Only save "game field changed + different from expected + not bounced back"
                --   If item is the same as _expectedItemId -> it was just changed back by the guard loop, do not save again
                --   If item is the same as _lastSavedItem -> no change, do not save again
                if item > 0 and item ~= _lastSavedItem and item ~= _expectedItemId then
                    -- Only write to disk when game field really changed (means user switched theme again)
                    HTS.WriteSaved(item)
                    if inst > 0 then HTS.WriteSavedInst(inst) end
                    _expectedItemId = item
                    _expectedInstId = inst
                    _lastSavedItem = item
                    print(string.format("[HallThemeSync] Captured theme change: item=%d", item))
                end
            end)
        end, -1, 1)
        return true
    end

    if not Attach() then
        local tries = 0
        local function Retry()
            tries = tries + 1
            if Attach() then return end
            if tries < 30 then
                local ok, tk = pcall(require, "common.time_ticker")
                if ok and tk and tk.AddTimer then tk.AddTimer(1, Retry) end
            end
        end
        Retry()
    end
end


-- ============================================================
-- ★★★ V8: Lobby Weapon Skin (Original Hook Version)★★★
-- ============================================================
pcall(function()
    local LAM = require("client.logic.avatar.LobbyAvatarManager")
    if not LAM or type(LAM.EquipWeapon) ~= "function" then return end

    -- Only Hook once
    if rawget(LAM, "__wmEqOrig") == nil then
        rawset(LAM, "__wmEqOrig", LAM.EquipWeapon)
    end
    local origFn = rawget(LAM, "__wmEqOrig")

    local function GetSavedSkin(baseWid)
        if _G.Wumingking and _G.Wumingking.GetWeapon then
            return _G.Wumingking.GetWeapon(baseWid) or 0
        end
        return 0
    end

    local function SaveSkin(baseWid, skinId)
        if _G.Wumingking and _G.Wumingking.SetWeapon then
            _G.Wumingking.SetWeapon(baseWid, skinId)
        end
    end

    LAM.EquipWeapon = function(self, arg1, arg2, arg3, ...)
    _G.__lastEquipTime = os.clock()  -- Star Record gun-switch timestamp, prevent TryFix collision
    if type(arg1) == "table" then
        local wid = tonumber(arg1.weaponId) or 0
            local sid = tonumber(arg1.skinId) or 0
            local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid

            if base and base > 0 then
                if sid >= 1100000000 then
                    -- User actively selected specific skin -> Respect + Save
                    SaveSkin(base, sid)
                    if DataMgr then DataMgr.Weapon_Skin_ResID = sid end
                else
                    -- Change gun / default skin -> Apply saved skin
                    local saved = GetSavedSkin(base)
                    if saved > 0 and saved ~= sid then
                        arg1.skinId = saved
                        arg1.usingDiyRecommend = false
                        if DataMgr then DataMgr.Weapon_Skin_ResID = saved end
                    end
                end
            end
        end
        return origFn(self, arg1, arg2, arg3, ...)
    end

    -- Fallback refresh: After entering lobby, if skin in DataMgr differs from saved, actively trigger EquipWeapon (let Hook take over)
    local function TryFix()
    -- Star Fix: Skip within 2 sec after switching gun, avoid TryFix force-refresh overwriting user action causing display delay
    if _G.__lastEquipTime and os.clock() - _G.__lastEquipTime < 2 then
        return
    end
    if type(DataMgr) ~= "table" then return end
    local wid = tonumber(DataMgr.Weapon_ID) or 0
    if wid <= 0 then return end
        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        if not base or base <= 0 then return end
        local saved = GetSavedSkin(base)
        if saved <= 0 then return end

        local curSid = tonumber(DataMgr.Weapon_Skin_ResID) or 0
        if curSid == saved then return end

        local tbl = {
            usingDiyRecommend = false,
            diyPlanId = "0-0",
            weaponId = base,
            skinId = saved,
        }
        if DataMgr then DataMgr.Weapon_Skin_ResID = saved end
        pcall(function() LAM:EquipWeapon(tbl, nil, true) end)
    end

    function _G.WMV4_Refresh()
        TryFix()
    end

    if _G.Mytimer_ticker then
        local _wasInLobby = false
        _G.Mytimer_ticker.AddTimerLoop(3, function()
            local ok, inLobby = pcall(function()
                return GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true
            end)
            if not (ok and inLobby) then
                _wasInLobby = false
                return
            end
            if not _wasInLobby then
                _wasInLobby = true
            end
            pcall(TryFix)
        end, -1, 1)
    end
    print("[WMV8] Loaded: Hook version, apply saved skin on gun switch, respect user when selecting skin")
end)


-- ==================== Lobby Warehouse Tick Sync (Read Config + Auto-Tick + Save) ====================
pcall(function()
    local WK = _G.Wumingking
    if not WK then
        print("[WardrobeSync] Wumingking not loaded, skip")
        return
    end

    -- Watched slots: Slot ID -> Name
    local SLOT_NAMES = {
        [5]  = "Outfit / Clothes",
        [3]  = "Headwear",
        [12] = "Eyewear",
        [4]  = "Mask",
        [6]  = "Pants",
        [7]  = "Shoes",
        [8]  = "Backpack",
        [9]  = "Helmet",
        [16] = "Gloves",
    }

    -- ==================== Utility Functions ====================
    local function getResIdFromInsId(insId)
        insId = tonumber(insId)
        if not insId then return nil end

        local LSI = _G.LobbySkinInjector
        if LSI and insId >= LSI.BASE_ID then
            local realId = insId - LSI.BASE_ID
            -- ★★★ Fix: Recognize as long as in reasonable range (originally only recognized customSet, causing backpack/helmet tick requests to be discarded)
            if realId > 0 and realId < 1000000000 then
                return realId
            end
        end

        -- Real item: Take from wardrobe data
        local resId = nil
        pcall(function()
            local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
            if WardrobeData and WardrobeData.GetHallDepotItemDataByInsID then
                local data = WardrobeData:GetHallDepotItemDataByInsID(tostring(insId))
                if data then
                    resId = data.resID or data.res_id or data.item_res_id
                end
            end
        end)
        return resId
    end

    local function getItemSubType(resId)
        if not resId then return nil end
        local cfg = nil
        pcall(function()
            if CDataTable and CDataTable.GetTableData then
                cfg = CDataTable.GetTableData("Item", resId)
            end
        end)
        return cfg and cfg.ItemSubType or nil
    end
    
    local function getItemSlotId(resId)
    if not resId then return nil end
    local cfg = nil
    pcall(function()
        if CDataTable and CDataTable.GetTableData then
            cfg = CDataTable.GetTableData("Item", resId)
        end
    end)
    if not cfg then return nil end

    -- 1. Use direct field if available (some versions have it)
    local slot = cfg.SlotID or cfg.EquipSlot or cfg.SlotId or cfg.Slot or cfg.EquipSlotID
    if slot and tonumber(slot) and tonumber(slot) > 0 then
        return tonumber(slot)
    end

    -- 2. This version has no SlotID, derive via WardrobeTab
    -- Mapping based on your 13:07 log test:
    --   1411193 WardrobeTab=1  -> Top
    --   1400165 WardrobeTab=2  -> Pants
    --   1404049 WardrobeTab=3  -> Hoodie / Top (BAPE)
    --   1404050 WardrobeTab=4  -> Pants (BAPE)
    --   1404051 WardrobeTab=5  -> Shoes (BAPE)
    --   1407895 WardrobeTab=10 -> Outfit (Blood Raven)
    --   1410646 WardrobeTab=14 -> Face Accessory / Mask
    local wtab = tonumber(cfg.WardrobeTab) or 0
    local WMAP = {
        [1]  = 5,
        [2]  = 6,
        [3]  = 5,
        [4]  = 6,
        [5]  = 7,
        [10] = 5,
        [14] = 4,
    }
    if WMAP[wtab] then return WMAP[wtab] end

    return nil
end

    -- ==================== 1. Read Config and Auto-Tick Warehouse ====================
    local function ApplySavedToWardrobe()
        if not _G.LobbySkinInjector then return false end
        
        -- Only allow tick once, prevent multiple triggers causing lag
        if _G.__WM_WardrobeApplyingOnce then return false end
        _G.__WM_WardrobeApplyingOnce = true
        
        local LSI = _G.LobbySkinInjector

        local WardRobeHandler = nil
        pcall(function()
            WardRobeHandler = require("client.network.Protocol.WardRobeHandler")
        end)
        if not WardRobeHandler or not WardRobeHandler.send_depot_put_on_req then
            return false
        end

        -- Re-read config file
        WK.Load()

        local applied = false
        _G.__WM_AUTO_WEARING = true

        local shirtId = WK.GetShirt and WK.GetShirt() or 0
local suitId = WK.GetSuit and WK.GetSuit() or 0
local pantId  = WK.GetSlot and WK.GetSlot(6) or 0
local shoeId  = WK.GetSlot and WK.GetSlot(7) or 0

-- ★★★ Actively Clean Conflict Items: Do Not Rely on Game Exclusion, Script Directly Sends Unequip Request ★★★
local function PurgeConflicts(activeSuit, activeShirt, activePant, activeShoe)
    local rolewear = DataMgr and DataMgr.rolewear
    if type(rolewear) ~= "table" then return 0 end

    local toRemove = {}
    for _, insId in ipairs(rolewear) do
        local insNum = tonumber(insId)
        if insNum and insNum > 0 then
            local resId = getResIdFromInsId(insNum)
            if resId then
                local isSuit = _G.isSuitItem and _G.isSuitItem(resId) or false
                local slotId = getItemSlotId(resId)
                local remove = false

                -- Wear outfit -> Unequip pants / shoes
                if activeSuit > 0 and (slotId == 6 or slotId == 7) then
                    remove = true
                end
                -- Wear clothes / pants / shoes -> Unequip outfit
                if (activeShirt > 0 or activePant > 0 or activeShoe > 0) and isSuit then
                    remove = true
                end

                if remove then toRemove[#toRemove + 1] = insNum end
            end
        end
    end

    if #toRemove == 0 then return 0 end

    local WRH = nil
    pcall(function()
        WRH = require("client.network.Protocol.WardRobeHandler")
    end)
    if not WRH or not WRH.send_depot_put_down_req then return 0 end

    for _, insId in ipairs(toRemove) do
        pcall(WRH.send_depot_put_down_req, tostring(insId))
    end
    print("[WardrobeSync] Actively unequip conflict items: " .. tostring(#toRemove) .. " ")
    return #toRemove
end

-- First judge which side to clear per config (unequip conflicts before formal equip)
if suitId > 0 then
    pcall(PurgeConflicts, suitId, 0, 0, 0)
elseif (shirtId > 0) or (pantId > 0) or (shoeId > 0) then
    pcall(PurgeConflicts, 0, shirtId, pantId, shoeId)
end

        for slot, name in pairs(SLOT_NAMES) do
            if slot == 5 then
                -- Star Outfit has config, wear outfit directly. Never actively unequip anyone, leave to game native exclusion
                if suitId > 0 then
                    if _G.AddCustomSkinItem then pcall(_G.AddCustomSkinItem, suitId) end
                    local insSuit = LSI.BASE_ID + suitId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insSuit))
                    applied = true
                    print("[WardrobeSync] Auto-tick: Outfit = " .. tostring(suitId))
                -- Star Clothes have config, wear clothes
                elseif shirtId > 0 then
                    if _G.AddCustomSkinItem then pcall(_G.AddCustomSkinItem, shirtId) end
                    local insShirt = LSI.BASE_ID + shirtId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insShirt))
                    applied = true
                    print("[WardrobeSync] Auto-tick: Clothes = " .. tostring(shirtId))
                end
            elseif slot == 6 or slot == 7 then
                -- Star If wearing outfit, skip auto-equip of pants (6) / shoes (7)
                if suitId <= 0 then
                    local itemId = WK.GetSlot(slot)
                    if itemId and itemId > 0 then
                        if _G.AddCustomSkinItem then
                            pcall(_G.AddCustomSkinItem, itemId)
                        end
                        local insId = LSI.BASE_ID + itemId
                        pcall(WardRobeHandler.send_depot_put_on_req, tostring(insId))
                        applied = true
                    end
                end
            else
                -- ★★★ Other slots: Headwear 3, Mask 4, Eyewear 12, Backpack 8, Helmet 9, Gloves 16
                local itemId = WK.GetSlot(slot)
                if itemId and itemId > 0 then
                    if _G.AddCustomSkinItem then
                        pcall(_G.AddCustomSkinItem, itemId)
                    end
                    local insId = LSI.BASE_ID + itemId
                    pcall(WardRobeHandler.send_depot_put_on_req, tostring(insId))
                    applied = true
                    print("[WardrobeSync] Auto-tick: " .. tostring(name) .. " = " .. tostring(itemId))

            -- Star Star Star Backpack (8) / Helmet (9) / Mask (4) / Eyewear (12) Extra Inject into rolewear, Let Warehouse UI Show Ticked
            if slot == 4 or slot == 8 or slot == 9 or slot == 12 then
                pcall(function()
                    if DataMgr and type(DataMgr.rolewear) == "table" then
                        local insStr = tostring(insId)
                        local found = false
                        for _, v in ipairs(DataMgr.rolewear) do
                            if tostring(v) == insStr then found = true; break end
                        end
                        if not found then
                            table.insert(DataMgr.rolewear, insStr)
                            print("[WardrobeSync] Inject into rolewear: slot=" .. tostring(slot) .. " ins=" .. insStr)
                        end
                    end
                end)
                pcall(function()
                    if EventSystem and EVENTTYPE_DATA_MGR and EVENTID_DATAMGR_ROLEWEAR_CHANGE then
                        EventSystem:postEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_ROLEWEAR_CHANGE)
                    end
                end)
            end
        end
    end
end
_G.__WM_AUTO_WEARING = false

    -- Star Fallback: After equip request async completes, do one more conflict cleanup (prevent first-round rolewear not refreshed)
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(1.0, function()
            _G.__WM_AUTO_WEARING = true
            if suitId > 0 then
                pcall(PurgeConflicts, suitId, 0, 0, 0)
            elseif (shirtId > 0) or (pantId > 0) or (shoeId > 0) then
                pcall(PurgeConflicts, 0, shirtId, pantId, shoeId)
            end
            _G.__WM_AUTO_WEARING = false
            if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
        end)
    end

    return applied
end

    -- ==================== 2. Hook Equip / Unequip, Save to Config File ====================
    local function InstallSaveHook()
        local WardRobeHandler = nil
        pcall(function()
            WardRobeHandler = require("client.network.Protocol.WardRobeHandler")
        end)
        if not WardRobeHandler then return false end

        -- Wrap equip request
if not WardRobeHandler._wm_save_hooked_on then
    WardRobeHandler._wm_save_hooked_on = true
    local origOn = WardRobeHandler.send_depot_put_on_req
    if type(origOn) == "function" then
        WardRobeHandler.send_depot_put_on_req = function(insId)
            local resId = getResIdFromInsId(insId)
            local slotId = resId and getItemSlotId(resId) or nil
            local isSuit = resId and _G.isSuitItem and _G.isSuitItem(resId)

            -- Star Star Star New: Before Wearing slot 5, Record If Character Is Wearing Pants / Shoes
            local prePantsOn, preShoesOn = false, false
            if slotId == 5 then
                pcall(function()
                    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                    if not LAM then return end
                    for _, v in pairs(LAM.playerList or {}) do
                        if type(v) == "userdata" and slua.isValid(v) then
                            local comp = v.AvatarComponent2
                            if comp and slua.isValid(comp) then
                                local nad = comp.NetAvatarData
                                if nad and slua.isValid(nad) then
                                    local ad = nad.SlotSyncData
                                    if ad then
                                        for i = 0, ad:Num() - 1 do
                                            local e = ad:Get(i)
                                            if e and e.SlotID == 6 and e.ItemId and e.ItemId > 0 then prePantsOn = true end
                                            if e and e.SlotID == 7 and e.ItemId and e.ItemId > 0 then preShoesOn = true end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                end)
            end

            -- Star Core: Let game handle mutual exclusion itself (wearing clothes, gameunderlying auto removes pants/shoes), script never interferes
            local ret = origOn(insId)
            
            -- Star Script only silently records the result
            if _G.__WM_AUTO_WEARING then return ret end
            
            if resId then
    if slotId == 5 or isSuit then
        -- Star Star Star New: When Judging Separate Pieces, Delay-Verify If Game Natively Removed Pants / Shoes
        if slotId == 5 and not isSuit and (prePantsOn or preShoesOn) and _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.8, function()
                pcall(function()
                    local nowPantsOn, nowShoesOn = false, false
                    local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                    if not LAM then return end
                    for _, v in pairs(LAM.playerList or {}) do
                        if type(v) == "userdata" and slua.isValid(v) then
                            local comp = v.AvatarComponent2
                            if comp and slua.isValid(comp) then
                                local nad = comp.NetAvatarData
                                if nad and slua.isValid(nad) then
                                    local ad = nad.SlotSyncData
                                    if ad then
                                        for i = 0, ad:Num() - 1 do
                                            local e = ad:Get(i)
                                            if e and e.SlotID == 6 and e.ItemId and e.ItemId > 0 then nowPantsOn = true end
                                            if e and e.SlotID == 7 and e.ItemId and e.ItemId > 0 then nowShoesOn = true end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                    -- Had before, now gone -> Game auto removed -> It is outfit
                    if (prePantsOn and not nowPantsOn) or (preShoesOn and not nowShoesOn) then
                        if _G.Wumingking and _G.Wumingking.SetSuitDirect then
                            _G.Wumingking.SetSuitDirect(resId)
                            print("[WardrobeSync] Native exclusion verification: Identified as outfit id=" .. tostring(resId))
                        end
                    end
                end)
            end)
        end

if WK.SetSlotSilent then
    WK.SetSlotSilent(5, resId, isSuit)   -- Star Pass externally already-judged isSuit, avoid second judgment failure
    if isSuit then
        WK.SetSlotSilent(6, 0)
        WK.SetSlotSilent(7, 0)
    end
else
    WK.SetSlot(5, resId)
end
                    -- Star Actively send unequip request, let UI really cancel tick (wearing outfit clears 5/6/7, wearing clothes clears outfit)
                    pcall(function()
                        local LSI = _G.LobbySkinInjector
                        if not LSI or type(DataMgr.rolewear) ~= "table" then return end
                        if not WardRobeHandler.send_depot_put_down_req then return end
                        local justOn = tonumber(insId) or -1
                        for i = 1, #DataMgr.rolewear do
                            local insNum = tonumber(DataMgr.rolewear[i])
                            if insNum and insNum > 0 and insNum ~= justOn and insNum >= LSI.BASE_ID then
                                local realId = insNum - LSI.BASE_ID
                                local cfg = CDataTable.GetTableData("Item", realId)
                                if cfg then
                                    local rSlot = cfg.SlotID
                                    local rIsSuit = _G.isSuitItem and _G.isSuitItem(realId) or false
                                    local remove = false
                                    if isSuit then
                                        if rSlot == 5 or rSlot == 6 or rSlot == 7 then remove = true end
                                    else
                                        if rIsSuit then remove = true end
                                    end
                                    if remove then
                                        pcall(WardRobeHandler.send_depot_put_down_req, tostring(insNum))
                                    end
                                end
                            end
                        end
                    end)
                    if _G._wkSaveDebounceTimer then
                        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
                    end
                    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
                    end)
                    return ret
                end

            -- ★★★ Fix: Remove getItemSubType fallback ★★★
            -- ItemSubType is the game's internal item category (mask may be 6, top may be 1, etc. small numbers),
            -- Completely different system from equipment slot SLOT_NAMES keys (5/3/12/4/6/7/8/9/16)!
            -- Once mask ItemSubType == 6, it will be misjudged as "pants" and written to D.G[6],
            -- Next time entering game PANT=Mask ID, wearing pants wears mask.
            -- Now only use SlotID precise match, unrecognized items go via SlotSyncData delayed fallback below (more accurate).
            local finalSlot = slotId
if finalSlot and SLOT_NAMES[finalSlot] then
    WK.SetSlot(finalSlot, resId)
    -- Wear pants (6) / shoes (7) -> Only clear outfit config, never touch SHIRT
    if finalSlot == 6 or finalSlot == 7 then
        -- Check Mark New: Only Clear SUIT, Keep All SHIRT/PANT/SHOE
        if WK.ClearSuitOnly then WK.ClearSuitOnly() end
        -- Star Actively send unequip request, let UI cancel outfit tick
        pcall(function()
            local LSI = _G.LobbySkinInjector
            if not LSI or type(DataMgr.rolewear) ~= "table" then return end
            if not WardRobeHandler.send_depot_put_down_req then return end
            local justOn = tonumber(insId) or -1
            for i = 1, #DataMgr.rolewear do
                local insNum = tonumber(DataMgr.rolewear[i])
                if insNum and insNum > 0 and insNum ~= justOn and insNum >= LSI.BASE_ID then
                    local realId = insNum - LSI.BASE_ID
                    if _G.isSuitItem and _G.isSuitItem(realId) then
                        pcall(WardRobeHandler.send_depot_put_down_req, tostring(insNum))
                    end
                end
            end
        end)
    end
    if _G._wkSaveDebounceTimer then
        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
    end
    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
    end)
    print("[WardrobeSync] Tick save: " .. tostring(SLOT_NAMES[finalSlot]) .. " = " .. tostring(resId))
else
    -- ★★★ Fallback: Slot Recognition Failed -> Delayed Compare SlotSyncData to Find Real Slot ★★★
    -- Used for mask / face accessory / eyewear etc. items with no SlotID field and no WardrobeTab match
    if resId and _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(0.8, function()
            pcall(function()
                local LAM = package.loaded["client.logic.avatar.LobbyAvatarManager"]
                if not LAM then return end
                for _, v in pairs(LAM.playerList or {}) do
                    if type(v) == "userdata" and slua.isValid(v) then
                        local comp = v.AvatarComponent2
                        local ad = comp and comp.NetAvatarData and comp.NetAvatarData.SlotSyncData
                        if ad then
                            -- Iterate all slots, find slot where ItemId == resId
                            for i = 0, ad:Num() - 1 do
                                local e = ad:Get(i)
                                if e and e.ItemId == resId and e.SlotID then
                                    local realSlot = e.SlotID
                                    if SLOT_NAMES[realSlot] then
                                        local curVal = WK.GetSlot(realSlot) or 0
                                        if curVal ~= resId then
                                            WK.SetSlot(realSlot, resId)
                                            print("[WardrobeSync] ★ SlotSyncData fallback save: " .. tostring(SLOT_NAMES[realSlot]) .. " = " .. tostring(resId))
                                        end
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end)
        end)
    end
end
            end
            return ret
        end
    end
end

        -- Wrap unequip request
if not WardRobeHandler._wm_save_hooked_down then
    WardRobeHandler._wm_save_hooked_down = true
    local origDown = WardRobeHandler.send_depot_put_down_req
    if type(origDown) == "function" then
        WardRobeHandler.send_depot_put_down_req = function(insId)
            local resId = getResIdFromInsId(insId)
            local isSlot5 = false
            
            if resId then
                isSlot5 = (getItemSlotId(resId) == 5) or (_G.isSuitItem and _G.isSuitItem(resId))
            end

            local LSI = _G.LobbySkinInjector
            if not isSlot5 and LSI and tonumber(insId) and tonumber(insId) >= LSI.BASE_ID then
                local realId = tonumber(insId) - LSI.BASE_ID
                if (getItemSlotId(realId) == 5) or (_G.isSuitItem and _G.isSuitItem(realId)) then
                    isSlot5 = true
                    resId = realId
                end
            end

            local ret = origDown(insId)

            if _G.__WM_AUTO_WEARING then return ret end
            if not resId then return ret end

            -- Star Only clear when "current config is this ID", avoid mistakenly clearing just-worn outfit when actively cleaning conflicts
            local isSuit = _G.isSuitItem and _G.isSuitItem(resId) or false
            if isSlot5 then
                local curSuit = (WK.GetSuit and WK.GetSuit()) or 0
                local curShirt = (WK.GetShirt and WK.GetShirt()) or 0
                if (isSuit and curSuit == resId) or ((not isSuit) and curShirt == resId) then
                    WK.SetSlot(5, 0)
                    if _G._wkSaveDebounceTimer then
                        pcall(function() _G.Mytimer_ticker.RemoveTimer(_G._wkSaveDebounceTimer) end)
                    end
                    _G._wkSaveDebounceTimer = _G.Mytimer_ticker.AddTimer(0.5, function()
                        if WK.ApplyToGlobals then pcall(WK.ApplyToGlobals) end
                    end)
                    print("[WardrobeSync] Unequip clothes/outfit: " .. tostring(resId))
                end
                return ret
            end

            -- Star Unequip backpack / helmet / headwear / mask / eyewear / gloves: Prefer SlotID, fallback to ItemSubType
            local checkSlot = getItemSlotId(resId)
            if not checkSlot or not SLOT_NAMES[checkSlot] then
                checkSlot = getItemSubType(resId)
            end
            if checkSlot and SLOT_NAMES[checkSlot] then
                local curVal = WK.GetSlot(checkSlot) or 0
                if curVal == resId then
                    WK.SetSlot(checkSlot, 0)
                    print("[WardrobeSync] Unequip: " .. tostring(SLOT_NAMES[checkSlot]) .. " = 0")
                end
            end
            return ret
        end
    end
end
    return true
end

-- ==========================================================
-- ★★★ Outfit Mutual-Exclusion Continuous Guard (100% Effective Core)★★★
-- As long as D.S > 0 (wearing outfit), force-clear character slot 6/7 every 0.5 sec
-- Does not rely on game native exclusion, does not rely on DataMgr.rolewear reverse lookup
-- ==========================================================
if _G.Mytimer_ticker and not _G.__WM_SuitGuardInstalled then
    _G.__WM_SuitGuardInstalled = true
    local _suitGuardTick = 0
    _G.Mytimer_ticker.AddTimerLoop(0.5, function()
        pcall(function()
            -- 1. Condition: Only run in lobby + when outfit exists
            if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
            -- Star Only outfit mode (SUIT>0) needs guard
            local needClear = (WK.GetSuit and WK.GetSuit() > 0)
            if not needClear then return end
            if not (WK.HasAnyConfig and WK.HasAnyConfig()) then return end

            -- 2. Get lobby character
            local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
            if not ok or type(LAM) ~= "table" or type(LAM.playerList) ~= "table" then return end
            local ch = nil
            for _, v in pairs(LAM.playerList) do
                if type(v) == "userdata" and slua.isValid(v) then ch = v; break end
            end
            if not ch then return end

            local comp = ch.AvatarComponent2
            if not comp or not slua.isValid(comp) then return end
            local nad = comp.NetAvatarData
            if not nad or not slua.isValid(nad) then return end
            local ad = nad.SlotSyncData
            if not ad then return end

            -- 3. Clear slot 6/7 character data
            local dirty = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e and (e.SlotID == 6 or e.SlotID == 7) and e.ItemId ~= 0 then
                    e.ItemId = 0
                    ad:Set(i, e)
                    dirty = true
                end
            end

            if dirty then
                pcall(function() comp:OnRep_BodySlotStateChanged() end)
                _suitGuardTick = _suitGuardTick + 1
                -- Only print once when really cleared (avoid spamming every 0.5 sec)
                if _suitGuardTick % 10 == 1 then
                    print("[SuitGuard] Force-cleared character slot 6/7 (wearing outfit)")
                end
            end

            -- 4. Scan rolewear every 2 sec, actively send unequip request (clear warehouse UI tick)
            if _suitGuardTick % 4 == 0 then
                pcall(function()
                    local WRH = require("client.network.Protocol.WardRobeHandler")
                    local rolewear = DataMgr and DataMgr.rolewear
                    if type(rolewear) ~= "table" then return end
                    if not WRH or not WRH.send_depot_put_down_req then return end
                    local LSI = _G.LobbySkinInjector
                    for _, insId in ipairs(rolewear) do
                        local insNum = tonumber(insId)
                        if insNum and insNum > 0 then
                            local realId = nil
                            if LSI and insNum >= LSI.BASE_ID then
                                realId = insNum - LSI.BASE_ID
                            end
                            if realId then
                                local cfg = CDataTable.GetTableData("Item", realId)
                                if cfg and (cfg.SlotID == 6 or cfg.SlotID == 7) then
                                    pcall(WRH.send_depot_put_down_req, tostring(insNum))
                                    print("[SuitGuard] Actively unequip slot 6/7 in rolewear: " .. tostring(realId))
                                end
                            end
                        end
                    end
                end)
            end
            _suitGuardTick = _suitGuardTick + 1
        end)
    end, -1, 1)
    print("[SuitGuard] Outfit mutual-exclusion guard started (scan every 0.5 sec)")
end

-- ==================== 3. Startup Flow ====================
local function TryStart()
    if not _G.LobbySkinInjector then return false end
    local ok = InstallSaveHook()
    if not ok then return false end
    ApplySavedToWardrobe()
    return true
end

    if not TryStart() then
        local tries = 0
        local function Retry()
            tries = tries + 1
            if TryStart() then return end
            if tries < 3 then
                local ok, tt = pcall(require, "common.time_ticker")
                if ok and tt and tt.AddTimer then
                    tt.AddTimer(1, Retry)
                end
            end
        end
        Retry()
    end

    if _G.Mytimer_ticker then
        local wasInLobby = false
        _G.Mytimer_ticker.AddTimerLoop(2, function()
            local inLobby = false
            pcall(function()
                inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity
                    and GameStatus.IsInLobbyOrMainCity() == true
            end)
            if inLobby and not wasInLobby then
                wasInLobby = true
                if not _G.__WM_WardrobeApplyingOnce then
                    pcall(ApplySavedToWardrobe)
                end
            elseif not inLobby then
                wasInLobby = false
                _G.__WM_WardrobeApplyingOnce = nil
            end
        end, -1, 1)
    end
end)




-- ==================== Outfit (Jumpsuit) Independent Save Support ====================
-- Because outfit and clothes share SlotID 5, but in game they are independent categories
-- Judge type via ItemSubType:
--   Outfit -> Save to SUIT= line
--   Clothes -> Save to SHIRT= line
-- The two are mutually exclusive, only one valid at a time
--
-- [Important] Values in SUIT_ITEM_SUBTYPES are "Outfit ItemSubType"
-- Common version may be 13, if outfit is still counted as clothes in test, adjust this value
-- Star Common outfit ItemSubType (may vary by version / skin, list as many as possible)
-- If outfit is still treated as clothes in test, print ItemSubType and add to list
_G.SUIT_ITEM_SUBTYPES = {}

_G.SuitSaver = _G.SuitSaver or {}
do
    local SS = _G.SuitSaver

    -- Judge if outfit (jumpsuit) -- The only kept function
function _G.isSuitItem(resId)
    if not resId or resId <= 0 then return false end
    local cfg = nil
    pcall(function()
        if CDataTable and CDataTable.GetTableData then
            cfg = CDataTable.GetTableData("Item", resId)
        end
    end)
    if not cfg then return false end
    -- Star Game wardrobe categories: Tab=10 is outfit, Tab=3 is single top
    local tab = tonumber(cfg.WardrobeTab) or 0
    if tab == 10 then return true end
    return false
end

    -- Compatible with old interface: Read / Write SUIT= directly via Wumingking's D.S
    function SS.Read()
        if _G.Wumingking and _G.Wumingking.GetSuit then
            return _G.Wumingking.GetSuit()
        end
        return 0
    end
    function SS.Write(itemId)
        itemId = math.floor(tonumber(itemId) or 0)
        if _G.Wumingking and _G.Wumingking.SetSlot then
            _G.Wumingking.SetSlot(5, itemId)
        end
        return true
    end

    print("[SuitSaver] Integrated into Wumingking.D.S, SUIT_ITEM_SUBTYPES=" ..
        table.concat(_G.SUIT_ITEM_SUBTYPES, ","))
end

pcall(function()
    local IDS = {1407550, 1400129, 404000, 405000}

    -- Clear LobbySkinInjector cache
    if _G.LobbySkinInjector then
        local LSI = _G.LobbySkinInjector
        for _, id in ipairs(IDS) do
            if LSI.customWorn then LSI.customWorn[id] = nil end
            if LSI.fakeByRes then LSI.fakeByRes[id] = nil end
            if LSI.customSet then LSI.customSet[id] = nil end
        end
    end

    -- Clear fake instances in DataMgr.rolewear
    if DataMgr and type(DataMgr.rolewear) == "table" then
        for i = #DataMgr.rolewear, 1, -1 do
            local v = tonumber(DataMgr.rolewear[i])
            if v and v >= 900000000 then
                local realId = v - 900000000
                for _, id in ipairs(IDS) do
                    if realId == id then
                        table.remove(DataMgr.rolewear, i)
                        break
                    end
                end
            end
        end
    end
end)


-- ==================== Gloves Fast Response System (Hide When Holding Gun / Show When Holstered) ====================
if _G.Mytimer_ticker then
    local _lastGunState = nil
    local _originalGloves = nil   -- Original glove ID recorded before taking gun

    _G.Mytimer_ticker.AddTimerLoop(0.5, function()
        local enabled = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("GLOVES_HIDE_ON_GUN", 0) == 1)
        -- Star Performance: If toggle off and gloves never hidden before, skip directly, do not fetch character chain
        if not enabled and _lastGunState == nil and _originalGloves == nil then return end

        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return end

        local comp = ch.AvatarComponent2
        if not comp or not slua.isValid(comp) then return end
        local nad = comp.NetAvatarData
        if not nad or not slua.isValid(nad) then return end
        local ad = nad.SlotSyncData
        if not ad then return end

        -- When toggle off: If gloves were hidden before, restore
        if not enabled then
            if _lastGunState ~= nil then
                _lastGunState = nil
                if _originalGloves ~= nil then
                    for i = 0, ad:Num() - 1 do
                        local e = ad:Get(i)
                        if e and e.SlotID == 16 then
                            if e.ItemId ~= _originalGloves then
                                e.ItemId = _originalGloves
                                ad:Set(i, e)
                                pcall(function() comp:OnRep_BodySlotStateChanged() end)
                            end
                            break
                        end
                    end
                    _originalGloves = nil
                end
            end
            return
        end

        local weapon = ch:GetCurrentWeapon()
        local wid = 0
        if weapon and slua.isValid(weapon) then
            local did = weapon:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end

        local baseWid = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        -- Firearm ID range: 101000~107999 (exclude melee 108xxx, grenade, bare hands)
        local isGun = (baseWid and baseWid >= 101000 and baseWid < 108000)

        if _lastGunState == isGun then return end
        _lastGunState = isGun

        local targetGloves
        if isGun then
            -- Record original gloves (for holster restore)
            if _originalGloves == nil then
                for i = 0, ad:Num() - 1 do
                    local e = ad:Get(i)
                    if e and e.SlotID == 16 then
                        _originalGloves = e.ItemId or 0
                        break
                    end
                end
            end
            targetGloves = 450001   -- Hide gloves
        else
            if _originalGloves ~= nil then
                targetGloves = _originalGloves
                _originalGloves = nil
            else
                targetGloves = _G.GlovesSkin or 0
            end
        end

        local found = false
        for i = 0, ad:Num() - 1 do
            local e = ad:Get(i)
            if e and e.SlotID == 16 then
                found = true
                if e.ItemId ~= targetGloves then
                    e.ItemId = targetGloves
                    ad:Set(i, e)
                    pcall(function() comp:OnRep_BodySlotStateChanged() end)
                end
                break
            end
        end

        if not found and targetGloves > 0 then
            ad:Add({ SlotID = 16, ItemId = targetGloves })
            pcall(function() comp:OnRep_BodySlotStateChanged() end)
        end
    end, -1, 0.15)   -- Star Interval 0.15 sec
end


-- ==================== In-Match Only Refresh 0x24 and 0x28 ====================
if _G.Mytimer_ticker then
    _G.Mytimer_ticker.AddTimerLoop(1.0, function()
        -- Only effective in-match
        local inGame = false
        pcall(function() inGame = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true end)
        
        if inGame then
            -- Read value from your settings menu
            local color = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("TEAM_UNIFORM_COLOR", 0)) or 0
            local pattern = (_G.DazhiMH_Config and _G.DazhiMH_Config.Get("TEAM_UNIFORM_PATTERN", 0)) or 0
            
            -- As long as you selected a value and environment has xsnb_tbys, call directly
            if (color > 0 or pattern > 0) and _G.xsnb_tbys then
                
                -- Star Core: Only write 0x24 (Color)
                if color > 0 then 
                    pcall(_G.xsnb_tbys, 5, color, nil, 0x24) 
                end
                
                -- Star Core: Only write 0x28 (Icon)
                if pattern > 0 then 
                    pcall(_G.xsnb_tbys, 5, pattern, nil, 0x28) 
                end
                
            end
        end
    end, -1, 1)
end


-- ==================== Lobby Weapon Skin Final Refresh V36 (Backpack / Helmet / Armor Full Anti-Overwrite) ====================
if not _G.__LobbyWeaponV14 then
    _G.__LobbyWeaponV14 = true

    local function safeRequire(paths)
        for _, path in ipairs(paths) do
            local ok, mod = pcall(require, path)
            if ok and mod then return mod end
        end
        return nil
    end

    -- 1. Warehouse tick spoofing
    local function InjectArmorySystem()
        local ArmorySystem = safeRequire({ "client.logic.armory.logic_armory", "Client.logic.armory.logic_armory" })
        if not ArmorySystem then return end
        if not ArmorySystem.rsp_list then ArmorySystem.rsp_list = {} end
        if not ArmorySystem.rsp_list.install_list then ArmorySystem.rsp_list.install_list = {} end

        if _G.Wumingking and _G.WeaponNameToID then
            for weaponName, baseId in pairs(_G.WeaponNameToID) do
                local targetSkin = _G.Wumingking.GetWeapon(baseId)
                if targetSkin and targetSkin > 0 then
                    local fakeInst = 900000000 + targetSkin
                    local cur = ArmorySystem.rsp_list.install_list[baseId]
                    local curSkin = cur and cur.skin_id
                    if curSkin ~= targetSkin then
                        if ArmorySystem.install_weapon_skin_rsp then
                            pcall(function()
                                ArmorySystem.install_weapon_skin_rsp({}, 0, baseId, fakeInst)
                            end)
                        end
                    end
                end
            end
        end
    end

    -- 2. Hook protocol layer
    local ArmoryHandler = safeRequire({ "client.network.Protocol.ArmoryHandler", "Client.network.Protocol.ArmoryHandler" })
    if ArmoryHandler then
        local ArmorySystem = safeRequire({ "client.logic.armory.logic_armory", "Client.logic.armory.logic_armory" })
        if ArmorySystem then
            if ArmoryHandler.send_install_weapon_skin and not ArmoryHandler._fake_hooked_install then
                ArmoryHandler._fake_hooked_install = true
                local original = ArmoryHandler.send_install_weapon_skin
                ArmoryHandler.send_install_weapon_skin = function(client_data, weapon_id, instanceID)
                    if tonumber(instanceID) >= 900000000 or instanceID == 0 then
                        ArmorySystem.install_weapon_skin_rsp(client_data, 0, weapon_id, tonumber(instanceID))
                        return
                    end
                    return original(client_data, weapon_id, instanceID)
                end
            end
            if ArmoryHandler.send_uninstall_weapon_skin and not ArmoryHandler._fake_hooked_uninstall then
                ArmoryHandler._fake_hooked_uninstall = true
                local original = ArmoryHandler.send_uninstall_weapon_skin
                ArmoryHandler.send_uninstall_weapon_skin = function(client_data, weapon_id)
                    local cur = ArmorySystem.rsp_list and ArmorySystem.rsp_list.install_list and ArmorySystem.rsp_list.install_list[weapon_id]
                    local skinId = cur and cur.instance_id
                    if skinId and tonumber(skinId) >= 900000000 then
                        ArmorySystem.uninstall_weapon_skin_rsp(client_data, 0, weapon_id)
                        return
                    end
                    return original(client_data, weapon_id)
                end
            end
        end
    end

    -- ★★★ 3. Ultimate Anti-Misalignment: Complete All Backpack, Helmet, Armor Fixes! ★★★
    local function FixHairAndBodyNoRebuild(LAM)
    pcall(function()
        local targetActor = nil
        -- Star Only fix local player, prevent writing backpack / helmet / armor / mask to teammates
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList or {}) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    targetActor = v
                    break
                end
            end
        end
        if not slua.isValid(targetActor) then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then targetActor = first end
        end
        if not slua.isValid(targetActor) then return end
            if not slua.isValid(targetActor) then return end
            
            local comp = targetActor.AvatarComponent2
            if not comp or not slua.isValid(comp) then return end
            local nad = comp.NetAvatarData
            if not nad or not slua.isValid(nad) then return end
            local ad = nad.SlotSyncData
            if not ad then return end

            -- Basic parts
            local fixes = {
                [2]  = _G.HairSkin,     [3]  = _G.HatSkin,      [4]  = _G.FaceSkin,
                [12] = _G.MaskSkin,     [5]  = _G.SuitSkin,     [6]  = _G.PantSkin,
                [7]  = _G.ShoeSkin,     [16] = _G.GlovesSkin,
            }

            local changed = false
            for i = 0, ad:Num() - 1 do
                local e = ad:Get(i)
                if e then
                    local slot = e.SlotID
                    local targetId = fixes[slot]
                    
                    -- Basic slot overwrite
                    if targetId and targetId > 0 then
                        if e.ItemId ~= targetId then
                            e.ItemId = targetId
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- Star Star Star New: Backpack (8) Star Star Star
                    if slot == 8 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local bagSkin = _G["Backpack" .. lvl .. "Skin"] or 0
                        if bagSkin > 0 and e.ItemId ~= bagSkin then
                            e.ItemId = bagSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- Star Star Star New: Helmet (9) Star Star Star
                    if slot == 9 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local helmetSkin = _G["Helmet" .. lvl .. "Skin"] or 0
                        if helmetSkin > 0 and e.ItemId ~= helmetSkin then
                            e.ItemId = helmetSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end

                    -- Star Star Star New: Bulletproof Vest (10) Star Star Star
                    if slot == 10 then
                        local lvl = tonumber(e.AdditionalItemID) or 1
                        local armorSkin = _G["Armor" .. lvl .. "Skin"] or 0
                        if armorSkin > 0 and e.ItemId ~= armorSkin then
                            e.ItemId = armorSkin
                            ad:Set(i, e)
                            changed = true
                        end
                    end
                end
            end

            if changed then
                pcall(function() comp:OnRep_BodySlotStateChanged() end)
            end
        end)
    end

    -- 4. Force-refresh 3D weapon models across the whole map
    local function LobbyAllWeaponsRefresh()
        local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
        if not slua.isValid(world) then return end

        pcall(function()
            local UGS = import("GameplayStatics")
            -- Star Performance: Do not scan all scene Actors, only scan weapon class
            local clsw = nil
            for _, cn in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local okc, c = pcall(import, cn)
                if okc and c then clsw = c; break end
            end
            if not clsw then return end
            local allActors = UGS.GetAllActorsOfClass(world, clsw, {})
            if not allActors then return end
            for i = 0, allActors:Num() - 1 do
                local a = allActors:Get(i)
                if slua.isValid(a) then
                    local arr = a.synData
                    if arr and slua.isValid(arr) then
                        local d = arr:Get(7)
                        if d and slua.isValid(d) then
                            local curId = slua.IndexReference(d, "defineID").TypeSpecificID
                            local baseWid = _G.getBaseWeaponID and _G.getBaseWeaponID(curId) or curId
                            local targetSkin = (_G.Wumingking and _G.Wumingking.GetWeapon and _G.Wumingking.GetWeapon(baseWid)) or 0
                            
                            if targetSkin > 0 and targetSkin ~= curId then
                                slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
                                arr:Set(7, d)
                                if a.ChangeItemAvatar then pcall(function() a:ChangeItemAvatar(targetSkin, true) end) end
                                if a.DelayHandleAvatarMeshChanged then pcall(function() a:DelayHandleAvatarMeshChanged() end) end
                                local wac = a.WeaponAvatarComponent
                                if wac and slua.isValid(wac) then
                                    if wac.ChangeItemAvatar then pcall(function() wac:ChangeItemAvatar(targetSkin, true) end) end
                                    if wac.OnRep_AvatarId then pcall(function() wac:OnRep_AvatarId() end) end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    _G.__LobbyRefreshRunning = false
    _G.__justExitedMatch = false

    -- ========== 5. Original Ultimate Combo ==========
    _G.LobbyWeaponRefreshFinal = function(skinOverride)
    -- Star Star Star Ultimate Defense: If Not in Lobby, Do Not Execute This Refresh-Hide Logic Star Star Star
    if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true) then
        return
    end

    if _G.__justExitedMatch then
        print("[DazhiMH] Just exited match, force block refresh to prevent underground!")
        return
    end

    if _G.__LobbyRefreshRunning then return end
    _G.__LobbyRefreshRunning = true

        InjectArmorySystem()

        if not DataMgr then _G.__LobbyRefreshRunning = false; return end
        local wid = tonumber(DataMgr.Weapon_ID) or 0
        if wid <= 0 then _G.__LobbyRefreshRunning = false; return end

        local base = _G.getBaseWeaponID and _G.getBaseWeaponID(wid) or wid
        local target = skinOverride or (_G.Wumingking and _G.Wumingking.GetWeapon and _G.Wumingking.GetWeapon(base)) or 0
        if target <= 0 then _G.__LobbyRefreshRunning = false; return end

        local ok, LAM = pcall(require, "client.logic.avatar.LobbyAvatarManager")
        if not ok or not LAM then _G.__LobbyRefreshRunning = false; return end

        DataMgr.Weapon_Skin_ResID = target

        local targetActor, w, wac, comp
pcall(function()
    local actor = nil
    pcall(function() actor = LAM:GetOperateAvatarByAvatarID(401985) end)
    if not slua.isValid(actor) then
        -- Star Only take local player, prevent refreshing onto teammate's weapon
        local selfUid = nil
        pcall(function()
            if DataMgr and DataMgr.roleData and DataMgr.roleData.uid then
                selfUid = tostring(DataMgr.roleData.uid)
            end
        end)
        if selfUid then
            for uid, v in pairs(LAM.playerList or {}) do
                if tostring(uid) == selfUid and type(v) == "userdata" and slua.isValid(v) then
                    actor = v
                    break
                end
            end
        end
        if not slua.isValid(actor) then
            local first, count = nil, 0
            for _, v in pairs(LAM.playerList or {}) do
                if type(v) == "userdata" and slua.isValid(v) then
                    count = count + 1
                    if not first then first = v end
                end
            end
            if count == 1 then actor = first end
        end
    end
            if slua.isValid(actor) then
                targetActor = actor
                local wm = nil
                pcall(function() wm = actor:GetWeaponManager() end)
                if wm and slua.isValid(wm) then pcall(function() w = wm:GetCurrentWeapon() end) end
                if w and slua.isValid(w) then pcall(function() wac = w.WeaponAvatarComponent end) end
                pcall(function() comp = actor.AvatarComponent2 end)
            end
        end)

        local tbl = { usingDiyRecommend = false, diyPlanId = "0-0", weaponId = base, skinId = target }
        local emptyTbl = { usingDiyRecommend = false, diyPlanId = "0-0", weaponId = 0, skinId = 0 }

        local function doSyncData()
            if not DataMgr then return end
            DataMgr.Weapon_Skin_ResID = target
            if not slua.isValid(w) then return end
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    slua.IndexReference(d, "defineID").TypeSpecificID = target
                    arr:Set(7, d)
                end
            end
        end

        pcall(function()
            doSyncData()
            if slua.isValid(w) and w.ChangeItemAvatar then w:ChangeItemAvatar(target, true) end
            if slua.isValid(w) and w.DelayHandleAvatarMeshChanged then w:DelayHandleAvatarMeshChanged() end
            if slua.isValid(wac) and wac.ChangeItemAvatar then wac:ChangeItemAvatar(target, true) end
            if slua.isValid(wac) and wac.OnRep_AvatarId then wac:OnRep_AvatarId() end
            if slua.isValid(wac) and wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
            if slua.isValid(wac) and wac.OnRep_SkinChanged then wac:OnRep_SkinChanged() end
            if slua.isValid(comp) and comp.OnRep_BodySlotStateChanged then comp:OnRep_BodySlotStateChanged() end
            if slua.isValid(comp) and comp.InitDepotCommonPutOn then comp:InitDepotCommonPutOn() end
        end)

        pcall(function() LAM:EquipWeapon(emptyTbl, nil, true) end)
        
        if _G.Mytimer_ticker then
            _G.Mytimer_ticker.AddTimer(0.1, function()
                pcall(function() LAM:EquipWeapon(tbl, nil, true) end)
                
                _G.Mytimer_ticker.AddTimer(0.2, function()
                    local origLoc = nil
                    if slua.isValid(targetActor) then
                        origLoc = targetActor:K2_GetActorLocation()
                    end

if slua.isValid(targetActor) then
    pcall(function() LAM:UpdatePlayer(targetActor) end)
    pcall(function() LAM:RefreshAvatar() end)
    pcall(function() LAM:RefreshMyAvatar() end)
end

-- Star New: Clean up possible leftover clone models in lobby
pcall(function()
    local validActors = {}
    if slua.isValid(targetActor) then table.insert(validActors, targetActor) end
    
    local world = slua_GameFrontendHUD and slua_GameFrontendHUD:GetWorld()
    if slua.isValid(world) then
        local UGS = import("GameplayStatics")
        -- Star Performance: Do not scan all scene Actors, only scan character class
        local clsc = nil
        for _, cn in ipairs({ "Character", "Avatar" }) do
            local okc, c = pcall(import, cn)
            if okc and c then clsc = c; break end
        end
        local allActors = clsc and UGS.GetAllActorsOfClass(world, clsc, {}) or nil
        if allActors then
            for i = 0, allActors:Num() - 1 do
                local a = allActors:Get(i)
                local name = a:GetClass():GetName() or ""
                -- Only clean player character class, never touch other scene objects
                if (name:find("Character") or name:find("Avatar")) and not name:find("Weapon") and not name:find("DeadBox") then
                    local isTracked = false
                    for _, valid in ipairs(validActors) do
                        if a == valid then isTracked = true; break end
                    end
                    if not isTracked then
                        pcall(function() a:K2_DestroyActor() end)
                    end
                end
            end
        end
    end
end)

                    _G.Mytimer_ticker.AddTimer(1.2, function()
                        FixHairAndBodyNoRebuild(LAM) -- Star This function now refreshes backpack, helmet, armor all back!
                        LobbyAllWeaponsRefresh()
                        _G.__LobbyRefreshRunning = false
                    end)
                end)
            end)
        end
    end

    -- ========== Trigger Mechanism ==========
    if _G.Mytimer_ticker then
        local _wasInLobby = false
        local _wasInGame = false
        
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus() == true
                local inLobby = GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity() == true
                
                if _wasInGame and not inGame and inLobby then
                    _G.__justExitedMatch = true
                    print("[DazhiMH] Detected exiting match, enabling anti-underground lock for 5 sec. ")
                    _G.Mytimer_ticker.AddTimer(5.0, function()
                        _G.__justExitedMatch = false
                    end)
                end

                if inLobby and not _wasInLobby then
                    _wasInLobby = true
                    if not _G.__justExitedMatch then
                        _G.Mytimer_ticker.AddTimer(0.5, function()
                            pcall(_G.LobbyWeaponRefreshFinal)
                        end)
                    end
                elseif not inLobby then
                    _wasInLobby = false
                end
                
                _wasInGame = inGame
            end)
        end, -1, 1)
    end

    pcall(function()
        local C = _G.DazhiMH_Config
        if C and type(C.ApplyWeaponSkin) == "function" and not C.__v14Wrapped then
            C.__v14Wrapped = true
            local orig = C.ApplyWeaponSkin
            C.ApplyWeaponSkin = function(k, v)
                local r = orig(k, v)
                if _G.Mytimer_ticker then
                    _G.Mytimer_ticker.AddTimer(0.1, function() pcall(_G.LobbyWeaponRefreshFinal) end)
                end
                return r
            end
        end
    end)
end


-- ==================== Star Melee Weapon Easy Skin Apply (Absolute Defense V2 - Fully Prevents Firearm Contamination) Star ====================
_G.MeleeSkinRefresher = _G.MeleeSkinRefresher or {}
do
    local M = _G.MeleeSkinRefresher
    M._installed = true

    M.Enabled  = true
    M.TICK_SEC = 2.0

    -- Melee base ID (only legal melee base whitelist)
    local MELEE_BASE = {
        [108001] = "Machete",
        [108004] = "PAN",
        [108005] = "Dagger",
    }

    -- Melee 7-digit variant -> Base (1080041 -> 108004 etc.)
    local MELEE_ID_BASE = {
        [108001] = 108001, [1080010] = 108001, [1080011] = 108001, [1080019] = 108001,
        [108004] = 108004, [1080040] = 108004, [1080041] = 108004, [1080042] = 108004,
        [1080043] = 108004, [1080044] = 108004, [1080049] = 108004,
        [108005] = 108005, [1080050] = 108005, [1080059] = 108005,
    }

    -- Melee skin ID -> Base (for distinguishing when sharing skin range, e.g. 1108001xxx)
    local MELEE_SKIN_BASE = {
        [1108005052] = 108005, -- Night Butterfly Kiss Dagger
        [1108004027] = 108004, -- Ice Snow Crystal Core
        [1108004416] = 108004, -- Flame Dance Folding Fan Pan
        [1108004380] = 108004, -- Red Lotus Godzilla Pan
        [1108004283] = 108004, -- Supreme Bulwark Pan
        [1108004230] = 108004, -- Sally - Pan
        [1108001081] = 108001, -- Red Lotus Battle Axe
        [1108001099] = 108001, -- Juan Soto Baseball Bat
    }

    -- ============ Skin Range Check ============
    local function isMeleeSkin(skinId)
        skinId = tonumber(skinId) or 0
        if skinId <= 0 then return false end
        if MELEE_BASE[skinId] then return true end
        if MELEE_ID_BASE[skinId] then return true end
        if skinId == 1081201 then return true end
        if skinId >= 1108001001 and skinId <= 1108001999 then return true end
        if skinId >= 1108004001 and skinId <= 1108004999 then return true end
        if skinId >= 1108005001 and skinId <= 1108005999 then return true end
        return false
    end

    -- ============ ID Range Check (Validity of User Input / Config ID) ============
    local function isMeleeWeaponId(wid)
        wid = tonumber(wid) or 0
        if wid <= 0 then return false end
        if MELEE_BASE[wid] then return true end
        if wid == 1081201 then return true end
        if wid >= 108001 and wid <= 108999 then return true end
        if wid >= 1080011 and wid <= 1089999 then return true end
        if wid >= 1108001001 and wid <= 1108005999 then return true end
        return false
    end

    -- ============================================================
    -- Star Star Star Core Defense 1: Get "Real Base Weapon ID" Star Star Star
    -- Always only trust GetItemDefineID().TypeSpecificID (this is item definition, not skin)
    -- Never trust synData[7] or GetWeaponID (may be contaminated skin ID)
    -- ============================================================
    local function getRealBaseWeaponID(w)
        if not w or not slua.isValid(w) then return 0 end

        local wid = 0

        -- 1. First choice: Item definition ID (most authoritative)
        pcall(function()
            local did = w:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end)

        -- 2. Fallback: GetWeaponID
        if wid <= 0 then
            pcall(function() wid = w:GetWeaponID() or 0 end)
        end

        if wid <= 0 then return 0 end

        -- 3. Reduce to base
        local base = wid
        if _G.getBaseWeaponID then
            local ok, b = pcall(_G.getBaseWeaponID, wid)
            if ok and b and b > 0 then base = b end
        end
        return base
    end

    -- ============================================================
    -- Star Star Star Core Defense 2: Strict Whitelist Check "Is It Really Melee" Star Star Star
    -- Only recognize {108001, 108004, 108005} these three bases
    -- Any firearm in 101xxx~107xxx range is always false
    -- ============================================================
    local function isActuallyMeleeWeapon(w)
        local base = getRealBaseWeaponID(w)
        return base > 0 and MELEE_BASE[base] ~= nil
    end

    -- ============ Skin / Weapon ID -> Melee Base ============
    local function getMeleeBaseId(wid, ctxBase)
        wid = tonumber(wid) or 0
        if wid <= 0 then return nil end
        if not isMeleeWeaponId(wid) then return nil end
        if wid == 1081201 then return ctxBase or 108004 end
        if MELEE_BASE[wid] then return wid end
        if MELEE_ID_BASE[wid] then return MELEE_ID_BASE[wid] end
        if MELEE_SKIN_BASE[wid] then return MELEE_SKIN_BASE[wid] end
        if wid >= 1080011 and wid <= 1089999 then
            local b = math.floor(wid / 10)
            if MELEE_BASE[b] then return b end
            if _G.WeaponIDSets then
                for _, idSet in pairs(_G.WeaponIDSets) do
                    if idSet[wid] then
                        for id in pairs(idSet) do
                            if MELEE_BASE[id] then return id end
                        end
                    end
                end
            end
        end
        if _G.getBaseWeaponID then
            local ok, base = pcall(_G.getBaseWeaponID, wid)
            if ok and base and MELEE_BASE[base] then return base end
        end
        if _G.WeaponIDSets then
            for _, idSet in pairs(_G.WeaponIDSets) do
                if idSet[wid] then
                    for id in pairs(idSet) do
                        if MELEE_BASE[id] then return id end
                    end
                end
            end
        end
        if wid >= 1108001001 and wid <= 1108001999 then return 108001 end
        if wid >= 1108004001 and wid <= 1108004999 then return 108004 end
        if wid >= 1108005001 and wid <= 1108005999 then return 108005 end
        return nil
    end

    -- ============================================================
    -- Star Star Star Core Defense 3: In applyToWeapon Assert Again "w Must Be Real Melee" Star Star Star
    -- Three locks together: targetSkin is melee skin + w is real melee + data valid
    -- ============================================================
    local function applyToWeapon(w, targetSkin)
        if not w or not slua.isValid(w) then return false end

        -- Lock 1: Target skin must fall in melee skin range
        if not isMeleeSkin(targetSkin) then return false end
        targetSkin = tonumber(targetSkin) or 0
        if targetSkin <= 0 then return false end

        -- Lock 2: Star Ultimate assertion: w itself must be real melee, not a gun! Star
        if not isActuallyMeleeWeapon(w) then
            return false
        end

        -- Lock 3: Data structure must be complete
        local arr = w.synData
        if not arr or not slua.isValid(arr) then return false end
        local d = arr:Get(7)
        if not d or not slua.isValid(d) then return false end
        local cur = slua.IndexReference(d, "defineID").TypeSpecificID
        if cur == targetSkin then return false end

        slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
        arr:Set(7, d)

        pcall(function() w:DelayHandleAvatarMeshChanged() end)
        pcall(function()
            local wac = w.WeaponAvatarComponent
            if wac and slua.isValid(wac) then
                if wac.OnRep_AvatarId      then wac:OnRep_AvatarId()      end
                if wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
                if wac.OnRep_SkinChanged   then wac:OnRep_SkinChanged()   end
                if wac.ChangeItemAvatar then
                    pcall(function() wac:ChangeItemAvatar(targetSkin, true) end)
                end
            end
        end)
        return true
    end

    local function tryOneWeapon(w, applied)
        if not w or not slua.isValid(w) then return end

        -- Star Star Star Judge by "Real Base Weapon ID", Not GetWeaponID Star Star Star
        -- GetWeaponID may return a contaminated skin ID, causing false melee detection
        if not isActuallyMeleeWeapon(w) then
            return
        end

        local wid = getRealBaseWeaponID(w)
        if wid <= 0 then return end

        -- Record context base (for 1108001xxx shared range to distinguish machete / dagger)
        local ctxBase = nil
        pcall(function()
            local ar = w.synData
            if ar and slua.isValid(ar) then
                local dd = ar:Get(7)
                if dd and slua.isValid(dd) then
                    local cc = slua.IndexReference(dd, "defineID").TypeSpecificID
                    if cc and MELEE_SKIN_BASE[cc] then ctxBase = MELEE_SKIN_BASE[cc] end
                end
            end
        end)

        local base = getMeleeBaseId(wid, ctxBase)
        if not base then return end -- This weapon base not in melee whitelist, skip directly

        local target = (_G.WeaponSkinID and _G.WeaponSkinID[base]) or 0

        -- Auto-clean: Config accidentally wrote M416 skin ID -> Force clear to zero, do not contaminate melee
        if target > 0 and not isMeleeSkin(target) then
            _G.WeaponSkinID[base] = 0
            target = 0
        end

        -- Config is 0 (not set) -> Check if contaminated skin, need to revert to original skin
        if target == 0 then
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                    -- Only when currently displayed is "melee skin" (means wrongly applied melee skin) then revert
                    -- Firearm skins will not hit isMeleeSkin, naturally skipped
                    if cur ~= base and cur ~= wid and isMeleeSkin(cur) then
                        applyToWeapon(w, base)
                    end
                end
            end
            return
        end

        if applyToWeapon(w, target) then
            applied[1] = applied[1] + 1
        end
    end

    function M.Refresh()
        if not M.Enabled then return 0 end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return 0 end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return 0 end

        local applied = { 0 }
        local seen = {}

        -- Path 1: Backpack
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) and not seen[w] then
                    seen[w] = true
                    tryOneWeapon(w, applied)
                end
            end
        end)

        -- Path 2: In hand
        pcall(function()
            local w = ch:GetCurrentWeapon()
            if w and slua.isValid(w) and not seen[w] then
                seen[w] = true
                tryOneWeapon(w, applied)
            end
        end)

        -- Path 3: Full map scan (prevent missing)
        pcall(function()
            local UGS = import("GameplayStatics")
            local world = ch:GetWorld()
            if not slua.isValid(world) then return end
            for _, clsName in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local ok, cls = pcall(import, clsName)
                if ok and cls then
                    local ok2, arr = pcall(function()
                        return UGS.GetAllActorsOfClass(world, cls, {})
                    end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local w = arr:Get(i)
                            if w and slua.isValid(w) and not seen[w] then
                                local owner = nil
                                pcall(function() owner = w.Owner or w:GetOwner() end)
                                if owner == ch then
                                    seen[w] = true
                                    tryOneWeapon(w, applied)
                                end
                            end
                        end
                    end
                end
            end
        end)

        return applied[1]
    end

    -- Scan once every 2 seconds
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(M.TICK_SEC, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus
                    and GameStatus.IsInFightingStatus() == true
                if inGame then M.Refresh() end
            end)
        end, -1, 1)
    end

    -- Accelerated re-apply on entering match
    local _origRefresh = M.Refresh
    if _G.Mytimer_ticker then
        for _, _d in ipairs({ 0.2, 0.6, 1.2, 2.5 }) do
            _G.Mytimer_ticker.AddTimer(_d, function()
                pcall(function()
                    local inGame = GameStatus and GameStatus.IsInFightingStatus
                        and GameStatus.IsInFightingStatus() == true
                    if inGame then _origRefresh() end
                end)
            end, 1)
        end
    end
end

-- ==================== Star Melee Weapon Easy Skin Apply (Absolute Defense V2 - Fully Prevents Firearm Contamination) Star ====================
_G.MeleeSkinRefresher = _G.MeleeSkinRefresher or {}
do
    local M = _G.MeleeSkinRefresher
    M._installed = true

    M.Enabled  = true
    M.TICK_SEC = 2.0

    -- Melee base ID (only legal melee base whitelist)
    local MELEE_BASE = {
        [108001] = "Machete",
        [108004] = "PAN",
        [108005] = "Dagger",
    }

    -- Melee 7-digit variant -> Base (1080041 -> 108004 etc.)
    local MELEE_ID_BASE = {
        [108001] = 108001, [1080010] = 108001, [1080011] = 108001, [1080019] = 108001,
        [108004] = 108004, [1080040] = 108004, [1080041] = 108004, [1080042] = 108004,
        [1080043] = 108004, [1080044] = 108004, [1080049] = 108004,
        [108005] = 108005, [1080050] = 108005, [1080059] = 108005,
    }

    -- Melee skin ID -> Base (for distinguishing when sharing skin range, e.g. 1108001xxx)
    local MELEE_SKIN_BASE = {
        [1108005052] = 108005, -- Night Butterfly Kiss Dagger
        [1108004027] = 108004, -- Ice Snow Crystal Core
        [1108004416] = 108004, -- Flame Dance Folding Fan Pan
        [1108004380] = 108004, -- Red Lotus Godzilla Pan
        [1108004283] = 108004, -- Supreme Bulwark Pan
        [1108004230] = 108004, -- Sally - Pan
        [1108001081] = 108001, -- Red Lotus Battle Axe
        [1108001099] = 108001, -- Juan Soto Baseball Bat
    }

    -- ============ Skin Range Check ============
    local function isMeleeSkin(skinId)
        skinId = tonumber(skinId) or 0
        if skinId <= 0 then return false end
        if MELEE_BASE[skinId] then return true end
        if MELEE_ID_BASE[skinId] then return true end
        if skinId == 1081201 then return true end
        if skinId >= 1108001001 and skinId <= 1108001999 then return true end
        if skinId >= 1108004001 and skinId <= 1108004999 then return true end
        if skinId >= 1108005001 and skinId <= 1108005999 then return true end
        return false
    end

    -- ============ ID Range Check (Validity of User Input / Config ID) ============
    local function isMeleeWeaponId(wid)
        wid = tonumber(wid) or 0
        if wid <= 0 then return false end
        if MELEE_BASE[wid] then return true end
        if wid == 1081201 then return true end
        if wid >= 108001 and wid <= 108999 then return true end
        if wid >= 1080011 and wid <= 1089999 then return true end
        if wid >= 1108001001 and wid <= 1108005999 then return true end
        return false
    end

    -- ============================================================
    -- Star Star Star Core Defense 1: Get "Real Base Weapon ID" Star Star Star
    -- Always only trust GetItemDefineID().TypeSpecificID (this is item definition, not skin)
    -- Never trust synData[7] or GetWeaponID (may be contaminated skin ID)
    -- ============================================================
    local function getRealBaseWeaponID(w)
        if not w or not slua.isValid(w) then return 0 end

        local wid = 0

        -- 1. First choice: Item definition ID (most authoritative)
        pcall(function()
            local did = w:GetItemDefineID()
            if did and did.TypeSpecificID then
                wid = did.TypeSpecificID
            end
        end)

        -- 2. Fallback: GetWeaponID
        if wid <= 0 then
            pcall(function() wid = w:GetWeaponID() or 0 end)
        end

        if wid <= 0 then return 0 end

        -- 3. Reduce to base
        local base = wid
        if _G.getBaseWeaponID then
            local ok, b = pcall(_G.getBaseWeaponID, wid)
            if ok and b and b > 0 then base = b end
        end
        return base
    end

    -- ============================================================
    -- Star Star Star Core Defense 2: Strict Whitelist Check "Is It Really Melee" Star Star Star
    -- Only recognize {108001, 108004, 108005} these three bases
    -- Any firearm in 101xxx~107xxx range is always false
    -- ============================================================
    local function isActuallyMeleeWeapon(w)
        local base = getRealBaseWeaponID(w)
        return base > 0 and MELEE_BASE[base] ~= nil
    end

    -- ============ Skin / Weapon ID -> Melee Base ============
    local function getMeleeBaseId(wid, ctxBase)
        wid = tonumber(wid) or 0
        if wid <= 0 then return nil end
        if not isMeleeWeaponId(wid) then return nil end
        if wid == 1081201 then return ctxBase or 108004 end
        if MELEE_BASE[wid] then return wid end
        if MELEE_ID_BASE[wid] then return MELEE_ID_BASE[wid] end
        if MELEE_SKIN_BASE[wid] then return MELEE_SKIN_BASE[wid] end
        if wid >= 1080011 and wid <= 1089999 then
            local b = math.floor(wid / 10)
            if MELEE_BASE[b] then return b end
            if _G.WeaponIDSets then
                for _, idSet in pairs(_G.WeaponIDSets) do
                    if idSet[wid] then
                        for id in pairs(idSet) do
                            if MELEE_BASE[id] then return id end
                        end
                    end
                end
            end
        end
        if _G.getBaseWeaponID then
            local ok, base = pcall(_G.getBaseWeaponID, wid)
            if ok and base and MELEE_BASE[base] then return base end
        end
        if _G.WeaponIDSets then
            for _, idSet in pairs(_G.WeaponIDSets) do
                if idSet[wid] then
                    for id in pairs(idSet) do
                        if MELEE_BASE[id] then return id end
                    end
                end
            end
        end
        if wid >= 1108001001 and wid <= 1108001999 then return 108001 end
        if wid >= 1108004001 and wid <= 1108004999 then return 108004 end
        if wid >= 1108005001 and wid <= 1108005999 then return 108005 end
        return nil
    end

    -- ============================================================
    -- Star Star Star Core Defense 3: In applyToWeapon Assert Again "w Must Be Real Melee" Star Star Star
    -- Three locks together: targetSkin is melee skin + w is real melee + data valid
    -- ============================================================
    local function applyToWeapon(w, targetSkin)
        if not w or not slua.isValid(w) then return false end

        -- Lock 1: Target skin must fall in melee skin range
        if not isMeleeSkin(targetSkin) then return false end
        targetSkin = tonumber(targetSkin) or 0
        if targetSkin <= 0 then return false end

        -- Lock 2: Star Ultimate assertion: w itself must be real melee, not a gun! Star
        if not isActuallyMeleeWeapon(w) then
            return false
        end

        -- Lock 3: Data structure must be complete
        local arr = w.synData
        if not arr or not slua.isValid(arr) then return false end
        local d = arr:Get(7)
        if not d or not slua.isValid(d) then return false end
        local cur = slua.IndexReference(d, "defineID").TypeSpecificID
        if cur == targetSkin then return false end

        slua.IndexReference(d, "defineID").TypeSpecificID = targetSkin
        arr:Set(7, d)

        pcall(function() w:DelayHandleAvatarMeshChanged() end)
        pcall(function()
            local wac = w.WeaponAvatarComponent
            if wac and slua.isValid(wac) then
                if wac.OnRep_AvatarId      then wac:OnRep_AvatarId()      end
                if wac.OnRep_AvatarChanged then wac:OnRep_AvatarChanged() end
                if wac.OnRep_SkinChanged   then wac:OnRep_SkinChanged()   end
                if wac.ChangeItemAvatar then
                    pcall(function() wac:ChangeItemAvatar(targetSkin, true) end)
                end
            end
        end)
        return true
    end

    local function tryOneWeapon(w, applied)
        if not w or not slua.isValid(w) then return end

        -- Star Star Star Judge by "Real Base Weapon ID", Not GetWeaponID Star Star Star
        -- GetWeaponID may return a contaminated skin ID, causing false melee detection
        if not isActuallyMeleeWeapon(w) then
            return
        end

        local wid = getRealBaseWeaponID(w)
        if wid <= 0 then return end

        -- Record context base (for 1108001xxx shared range to distinguish machete / dagger)
        local ctxBase = nil
        pcall(function()
            local ar = w.synData
            if ar and slua.isValid(ar) then
                local dd = ar:Get(7)
                if dd and slua.isValid(dd) then
                    local cc = slua.IndexReference(dd, "defineID").TypeSpecificID
                    if cc and MELEE_SKIN_BASE[cc] then ctxBase = MELEE_SKIN_BASE[cc] end
                end
            end
        end)

        local base = getMeleeBaseId(wid, ctxBase)
        if not base then return end -- This weapon base not in melee whitelist, skip directly

        local target = (_G.WeaponSkinID and _G.WeaponSkinID[base]) or 0

        -- Auto-clean: Config accidentally wrote M416 skin ID -> Force clear to zero, do not contaminate melee
        if target > 0 and not isMeleeSkin(target) then
            _G.WeaponSkinID[base] = 0
            target = 0
        end

        -- Config is 0 (not set) -> Check if contaminated skin, need to revert to original skin
        if target == 0 then
            local arr = w.synData
            if arr and slua.isValid(arr) then
                local d = arr:Get(7)
                if d and slua.isValid(d) then
                    local cur = slua.IndexReference(d, "defineID").TypeSpecificID
                    -- Only when currently displayed is "melee skin" (means wrongly applied melee skin) then revert
                    -- Firearm skins will not hit isMeleeSkin, naturally skipped
                    if cur ~= base and cur ~= wid and isMeleeSkin(cur) then
                        applyToWeapon(w, base)
                    end
                end
            end
            return
        end

        if applyToWeapon(w, target) then
            applied[1] = applied[1] + 1
        end
    end

    function M.Refresh()
        if not M.Enabled then return 0 end
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not pc or not slua.isValid(pc) then return 0 end
        local ch = pc:GetPlayerCharacterSafety()
        if not ch or not slua.isValid(ch) then return 0 end

        local applied = { 0 }
        local seen = {}

        -- Path 1: Backpack
        pcall(function()
            local wm = ch:GetWeaponManager()
            if not wm or not slua.isValid(wm) then return end
            local list = wm:GetAllInventoryWeaponList(false)
            if not list or not slua.isValid(list) then return end
            for i = 0, list:Num() - 1 do
                local w = list:Get(i)
                if w and slua.isValid(w) and not seen[w] then
                    seen[w] = true
                    tryOneWeapon(w, applied)
                end
            end
        end)

        -- Path 2: In hand
        pcall(function()
            local w = ch:GetCurrentWeapon()
            if w and slua.isValid(w) and not seen[w] then
                seen[w] = true
                tryOneWeapon(w, applied)
            end
        end)

        -- Path 3: Full map scan (prevent missing)
        pcall(function()
            local UGS = import("GameplayStatics")
            local world = ch:GetWorld()
            if not slua.isValid(world) then return end
            for _, clsName in ipairs({ "WeaponBase", "STExtraWeaponBase", "BattleWeaponBase" }) do
                local ok, cls = pcall(import, clsName)
                if ok and cls then
                    local ok2, arr = pcall(function()
                        return UGS.GetAllActorsOfClass(world, cls, {})
                    end)
                    if ok2 and arr then
                        for i = 0, arr:Num() - 1 do
                            local w = arr:Get(i)
                            if w and slua.isValid(w) and not seen[w] then
                                local owner = nil
                                pcall(function() owner = w.Owner or w:GetOwner() end)
                                if owner == ch then
                                    seen[w] = true
                                    tryOneWeapon(w, applied)
                                end
                            end
                        end
                    end
                end
            end
        end)

        return applied[1]
    end

    -- Scan once every 2 seconds
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(M.TICK_SEC, function()
            pcall(function()
                local inGame = GameStatus and GameStatus.IsInFightingStatus
                    and GameStatus.IsInFightingStatus() == true
                if inGame then M.Refresh() end
            end)
        end, -1, 1)
    end

    -- Accelerated re-apply on entering match
    local _origRefresh = M.Refresh
    if _G.Mytimer_ticker then
        for _, _d in ipairs({ 0.2, 0.6, 1.2, 2.5 }) do
            _G.Mytimer_ticker.AddTimer(_d, function()
                pcall(function()
                    local inGame = GameStatus and GameStatus.IsInFightingStatus
                        and GameStatus.IsInFightingStatus() == true
                    if inGame then _origRefresh() end
                end)
            end, 1)
        end
    end
end

-- ==================== Star Lobby Theme Switch Auto-Refresh Vehicle Patch Star ====================
-- When you switch lobby theme in game, immediately re-apply vehicle skin once
pcall(function()
    if _G.__WM_ThemeChangeHookInstalled then return end
    _G.__WM_ThemeChangeHookInstalled = true

    local _lastThemeItem = -1
    local _lastThemeInst = -1

    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                -- Only effective in lobby
                if not (GameStatus and GameStatus.IsInLobbyOrMainCity and GameStatus.IsInLobbyOrMainCity()) then return end
                
                -- Get current theme data (Star Performance: Module only require once, not every sec)
                if _G.__hThemeMod == nil then
                    local okm, mm = pcall(require, "client.logic.lobby.hall_theme_utils")
                    _G.__hThemeMod = (okm and mm) or false
                end
                local m = _G.__hThemeMod
                if not m then return end
                
                local curItem = tonumber(m.homeThemeItemId) or 0
                local curInst = tonumber(m.homeThemeInstId) or 0

                -- Initialize record
                if _lastThemeItem == -1 then
                    _lastThemeItem = curItem
                    _lastThemeInst = curInst
                    return
                end

                -- Detected theme change
if curItem ~= _lastThemeItem or curInst ~= _lastThemeInst then
    _lastThemeItem = curItem
    _lastThemeInst = curInst
    
    -- Star Star Star Core Fix: When Switching Theme, Enable Protection Lock for 3 Sec, Prevent HairGuard Forcibly Overwriting Model Data Star Star Star
    _G.__IsThemeSwitching = true
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimer(2.0, function()
            _G.__IsThemeSwitching = false
            -- After theme loads, safely re-apply once
            pcall(_G.LobbyVehicleRefresh)
            if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                pcall(_G.Wumingking.ApplyToLobby, true)
            end
        end)
    end

    -- Blacklist theme skip directly (ensure native safety)
    if curItem == 202408061 or curItem == 202408087 then return end
                    
                    -- After switching theme, delay 1 sec to wait for model load, then refresh vehicle
                    if _G.Mytimer_ticker then
                        _G.Mytimer_ticker.AddTimer(1.0, function()
                            pcall(_G.LobbyVehicleRefresh) -- Only execute refresh
                        end)
                    end
                end
            end)
        end, -1, 1)
    end
end)


-- ============================================================
-- Metro warehouse data layer intercept (perfectly solves Metro lobby weapon skin sync)
-- Core: Intercept TxMission module, directly tamper underlying item table, bypass render layer reset
-- ============================================================
pcall(function()
    if _G.__txMissionPatched then return end
    _G.__txMissionPatched = true

    -- Core logic: Directly tamper data source
    local function patchItemData(t)
        if type(t) ~= "table" then return end
        local iid = tonumber(t.itemID)
        local sid = tonumber(t.skinID)
        
        -- Must be legal weapon ID range
        if iid and iid > 999999 and iid < 1e15 then
            local classic = nil
            if iid < 9999999 then
                -- 7 digits and below (variant ID), remove the trailing digit
                classic = math.floor(iid / 10)
            else
                -- 8 digits and above (skin ID), use the built-in conversion function
                classic = _G.getBaseWeaponID and _G.getBaseWeaponID(iid) or nil
            end
            
            -- Ensure got base weapon ID, and fake skin is configured
            if classic and classic ~= iid and classic >= 100000 and classic <= 999999 then
                local fakeSkin = _G.WeaponSkinID and _G.WeaponSkinID[classic]
                if fakeSkin and fakeSkin > 0 then
                    -- Before game renders, forcibly write fake skin
                    t.skinID = fakeSkin
                end
            end
        end
    end

    -- Deep Hook Metro module
    local function hookTxMission()
        for path, mod in pairs(package.loaded) do
            if type(path) == "string" and (path:find("TxMission") or path:find("logic_xmission")) then
                if type(mod) == "table" and not rawget(mod, "__txm_hooked") then
                    rawset(mod, "__txm_hooked", true)
                    
                    -- Iterate all functions in module
                    for k, v in pairs(mod) do
                        if type(k) == "string" and type(v) == "function" and not k:match("^_") then
                            local orig = v
                            mod[k] = function(self, arg1, ...)
                                -- If passed is table, try to tamper
                                if type(arg1) == "table" then
                                    patchItemData(arg1)
                                end
                                return orig(self, arg1, ...)
                            end
                        end
                    end
                end
            end
        end
    end

    -- Mount timer, continuously monitor newly loaded modules
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(hookTxMission)
        end, -1, 1)
    end
    
    hookTxMission()
end)



-- ==================== Metro Backpack Skin Ultimate Intercept (Precise Anti-Overlap) ====================
do
    local function GetFakeBagSkin()
        for i = 1, 6 do
            local v = _G["Backpack"..i.."Skin"]
            if v and v > 0 then return v end
        end
        return 0
    end

    local _hooked = false
    local function HookMCAC()
        if _hooked then return true end
        pcall(function()
            local ok, MCAC = pcall(require, "GameLua.Mod.TPlan.Component.MetroCharacterAvatarComponent")
            if not ok or not MCAC then return end
            local impl = MCAC.__inner_impl
            if not impl or impl.__bagFinalHooked then _hooked = true; return end
            impl.__bagFinalHooked = true

            -- 1. Intercept getting the base skin ID
            local orig_Get = impl.GetLocalEquipmentSkinID
            if type(orig_Get) == "function" then
                impl.GetLocalEquipmentSkinID = function(self, slotID, ...)
                    local ok2, r = pcall(orig_Get, self, slotID, ...)
                    if slotID == 8 then
                        local fake = GetFakeBagSkin()
                        if fake > 0 then return fake end
                    end
                    return ok2 and r or nil
                end
            end

            -- 2. Intercept level replacement ID
            local orig_Level = impl.GetReplaceSkinIDByLevel
            if type(orig_Level) == "function" then
                impl.GetReplaceSkinIDByLevel = function(self, skinID, level, ...)
                    local fake = GetFakeBagSkin()
                    if fake > 0 and skinID == fake then return fake end
                    if fake > 0 and skinID == 1501003350 then return fake end
                    local ok2, r = pcall(orig_Level, self, skinID, level, ...)
                    return ok2 and r or nil
                end
            end

            -- 3. Intercept the final applied high-level Avatar (ultimate defense line)
            local orig_High = impl.GetReplaceHighLvEquipmentAvatar
            if type(orig_High) == "function" then
                impl.GetReplaceHighLvEquipmentAvatar = function(self, slotID, resID, addID, ...)
                    -- Strict limit: Only slotID == 8 is backpack!
                    if slotID == 8 then
                        local fake = GetFakeBagSkin()
                        if fake > 0 then return fake end
                    end
                    local ok2, r = pcall(orig_High, self, slotID, resID, addID, ...)
                    return ok2 and r or nil
                end
            end
            _hooked = true
        end)
        return _hooked
    end

    HookMCAC()

    -- Helper: Sync SlotSyncData, ensure backpack UI also shows correctly
    if _G.Mytimer_ticker then
        _G.Mytimer_ticker.AddTimerLoop(1, function()
            pcall(function()
                if not _hooked then HookMCAC() end
                -- Star Performance: If no target skin, do not fetch character chain, skip directly
                local target = GetFakeBagSkin()
                if target <= 0 then return end
                local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                local ch = pc and pc:GetPlayerCharacterSafety()
                local comp = ch and ch.AvatarComponent2
                local ad = comp and comp.NetAvatarData and comp.NetAvatarData.SlotSyncData
                if ad then
                    if target > 0 then
                        for i = 0, ad:Num() - 1 do
                            local e = ad:Get(i)
                            if e and e.SlotID == 8 and e.ItemId ~= target then
                                e.ItemId = target
                                ad:Set(i, e)
                            end
                        end
                    end
                end
            end)
        end, -1, 1)
    end
end


-- ============================================================
-- v10 (Fixed Version): Profile page -> Avatar / Avatar Frame Selection
-- Note:
--   1. IDs in the list will be injected as "Owned" status;
--   2. The choice is not sent to the server, it only takes effect locally;
--   3. The choice result is saved in BeysaProfile.ini;
--   4. All code is placed inside do ... end to avoid exceeding the 200 local limit.
-- Fix log:
--   1. Add the missing self parameter (the original code missed one parameter, causing the whole hook to fail)
--   2. Change expire_time=1 to a future timestamp (otherwise it is judged expired as soon as you enter the page)
--   3. Auto fallback when BeysaFake is missing (otherwise the whole block crashes)
--   4. Change F.later to Mytimer_ticker / common.time_ticker retry
--   5. Use independent variables _G.__BeysaUserAvatarPick / _G.__BeysaUserFramePick
--      Record the user's choice in this script's Hook, to prevent it from being overwritten by refresh_basic_data
--   6. on_change_user_avatar_rsp / on_change_avatar_box_rsp must be called with dot notation
-- ============================================================
do
    -- ============ 1. BeysaFake Fallback (Prevent Whole Block Crash) ============
    if not _G.BeysaFake then
        local _fakeAvatar, _fakeBox = 0, 0
        _G.BeysaFake = {
            GetProfile   = function() return _fakeAvatar, _fakeBox end,
            SetAvatar    = function(id) _fakeAvatar = tonumber(id) or 0 end,
            SetAvatarBox = function(id) _fakeBox    = tonumber(id) or 0 end,
        }
    end

    -- Star Star Star Independent Variable Init (For _resolveAvatarIds to Read First)
    _G.__BeysaUserAvatarPick = _G.__BeysaUserAvatarPick or 0
    _G.__BeysaUserFramePick  = _G.__BeysaUserFramePick  or 0

    -- ============ Avatar ID List (Kept As-Is) ============
    local AVATAR_IDS = {
        30019, 30023, 30024, 30055, 30056, 30057, 30058, 30059, 30063, 30064, 30065, 30066,
        30067, 30068, 30069, 30070, 30071, 30072, 30073, 30074, 30076, 30077, 30078, 30080,
        30081, 30082, 30083, 30084, 30085, 30086, 30087, 30088, 30089, 30091, 30093, 30096,
        30097, 30099, 30100, 30110, 30113, 30114, 30115, 30120, 30121, 30124, 30126, 30127,
        30130, 30131, 30132, 30133, 30134, 30135, 30136, 30137, 30138, 30139, 30143, 30153,
        30154, 30155, 30160, 30161, 30162, 30165, 30166, 30167, 30168, 30169, 30170, 30171,
        30172, 30173, 30174, 30175, 30176, 30177, 30178, 30179, 30180, 30181, 30182, 30183,
        30184, 30185, 30186, 30188, 30189, 30191, 30192, 30193, 30194, 30195, 30196, 30197,
        30199, 30200, 30201, 30202, 30203, 30204, 30205, 30206, 30207, 30208, 30209, 30210,
        30211, 30212, 30213, 30214, 30215, 30216, 30217, 30218, 30219, 30220, 30221, 30222,
        30223, 30224, 30225, 30226, 30227, 30228, 30229, 30230, 30231, 30232, 30233, 30234,
        30235, 30236, 30237, 30238, 30239, 30240, 30241, 30242, 30243, 30244, 30245, 30246,
        30247, 30248, 30249, 30250, 30251, 30252, 30253, 30254, 30255, 30256, 30257, 30258,
        30259, 30260, 30261, 30262, 30263, 30264, 30265, 30266, 30267, 30268, 30269, 30270,
        30271, 30272, 30273, 30274, 30275, 30276, 30277, 30278, 30279, 30280, 30281, 30282,
        30283, 30284, 30285, 30286, 30287, 30288, 30289, 30290, 30291, 30292, 30293, 30294,
        30295, 30296, 30297, 30298, 30299, 30300, 30301, 30302, 30303, 30304, 30305, 30306,
        30307, 30308, 30309, 30310, 30311, 30312, 30313, 30314, 30315, 30316, 30317, 30318,
        30319, 30320, 30321, 30322, 30323, 30324, 30325, 30326, 30327, 30328, 30329, 30330,
        30331, 30332, 30333, 30334, 30335, 30336, 30337, 30338, 30339, 30340, 30341, 30342,
        30343, 30344, 30345, 30346, 30347, 30348, 30349, 30350, 30351, 30352, 30353, 30354,
        30355, 30356, 30357, 30358, 30359, 30360, 30361, 30362, 30363, 30364, 30365, 30366,
        30367, 30368, 30369, 30370, 30371, 30372, 30373, 30374, 30375, 30376, 30377, 30378,
        30379, 30380, 30381, 30382, 30383, 30384, 30385, 30386, 30387, 30388, 30389, 30390,
        30391, 30392, 30393, 30394, 30395, 30396, 30397, 30398, 30400, 30401, 30402, 30403,
        30404, 30405, 30406, 30407, 30408, 30409, 30410, 30411, 30412, 30413, 30414, 30415,
        30416, 30417, 30418, 30419, 30420, 30421, 30422, 30423, 30424, 30601, 30602, 30603,
        30604, 30605, 30606, 30607, 30608, 30609, 30610, 30611, 30612, 30613, 30614, 30615,
        30616, 30617, 30618, 30619, 30620, 30621, 30622, 30623, 30624, 30625, 30626, 30627,
        30628, 30629, 30630, 30631, 30632, 30633, 30634, 30635, 30636, 30637, 30638, 30639,
        30640, 31001, 31003, 31004, 31005, 31006, 31007, 31008, 31009, 31010, 31011, 31012,
        31013, 31014, 31015, 31016, 31017, 31018, 31019, 31020, 31021, 31022, 31023, 31024,
        31025, 31026, 31027, 31028, 31029, 31030, 31031, 31032, 31033, 31034, 31035, 31036,
        31037, 31038, 31039, 31040, 31041, 31042, 31043, 31044, 31045, 31046, 31047, 31048,
        31049, 31051, 31052, 31053, 31054, 31055, 31056, 31057, 31058, 31059, 31060, 31061,
        31062, 31063, 31064, 31065, 31066, 31067, 31068, 31069, 31070, 31071, 31072, 31073,
        31074, 31075, 31076, 31077, 31078, 31079, 31080, 31081, 31082, 31083, 31084, 31085,
        31086, 31087, 31088, 31089, 31090, 31091, 31092, 31093, 31094, 31095, 31096, 31097,
        31098, 31099, 31100, 31101, 31102, 31103, 31104, 31105, 31106, 31107, 31108, 31109,
        31110, 31111, 31112, 31113, 31114, 31115, 31116, 31117, 31118, 31119, 31120, 31122,
        31123, 31124, 31125, 31126, 31127, 31128, 31129, 31130, 31131, 31132, 31133, 31134,
        31135, 31136, 31137, 31138, 31139, 31140, 31141, 31142, 31143, 31144, 31145, 31146,
        31147, 31148, 31149, 31150, 31151, 31152, 31153, 31154, 31155, 31156, 31157, 31158,
        31159, 31160, 31161, 31162, 31163, 31164, 31165, 31166, 31167, 31168, 31169, 31170,
        31171, 31172, 31173, 31174, 31175, 31176, 31177, 31178, 31179, 31180, 31181, 31182,
        31183, 31184, 31185, 31186, 31187, 31188, 31189, 31190, 31191, 31192, 31194, 31195,
        31196, 31197, 31198, 31199, 31200, 31201, 31202, 31203, 31204, 31205, 31206, 31207,
        31209, 31210, 31211, 31212, 31213, 31214, 31215, 31216, 31217, 31218, 31219, 31220,
        31221, 31222, 31225, 31226, 31227, 31228, 31229, 31230, 31231, 31234, 31236, 31237,
        31238, 31239, 31240, 31241, 31242, 31243, 31244, 31245, 31246, 31250, 31251, 31252,
        31253, 31254, 31255, 31256, 31257, 31258, 31259, 31260, 31261, 31262, 31264, 31265,
        31266, 31267, 31268, 31269, 31270, 31271, 31272, 31273, 31274, 31275, 31276, 31277,
        31278, 31279, 31280, 31281, 31282, 31283, 31284, 31287, 31290, 31291, 31292, 31293,
        31294, 31295, 31296, 31297, 31298, 31299, 31300, 31303, 31304, 31305, 31312, 31313,
        31315, 31316, 31318, 31319, 31320, 31321, 31322, 31323, 31324, 31325, 31326, 31327,
        31328, 31330, 31331, 31332, 31333, 31334, 31335, 31364, 31400, 31401, 31403, 31404,
        31405, 31410, 31411, 31412, 31413, 31414, 31415, 31430, 31431, 31432, 31433, 31434,
        31437, 31438, 31439, 31441, 31442, 31443, 31444, 31445, 31446, 31447, 31448, 31449,
        31451, 31452, 31453, 31454, 31455, 31456, 31457, 31459, 31460, 31461, 31462, 31465,
        31466, 31467, 31468, 31470, 31475, 31476, 31477, 31501, 31502, 31503, 31504, 31505,
        31506, 31507, 31508, 31509, 31510, 31511, 31512, 31513, 31514, 31515, 31516, 32002,
        32003, 32004, 32005, 32006, 32007, 32008, 32009, 32010, 32011, 35001, 35002, 35003,
        35004, 35005, 35006, 35007, 35008, 35009, 35010, 40001, 40002, 40004, 40005, 40007,
        40008, 40010, 40011, 40013, 40014, 40016, 40017, 40019, 40020, 40022, 40023, 40025,
        40026, 40028, 40029, 40031, 40032, 40034, 40035, 40037, 40038, 40040, 40041, 40043,
        40044, 40046, 40047, 40049, 40050, 40232, 40233, 40242, 40243, 40252, 40253, 40262,
        40263, 60001, 60003, 60005, 60007, 60009, 60011, 60013, 60015, 60017, 60019, 60021,
        60023, 60025, 60027, 60029, 60031, 60033, 60035, 60037, 60039, 60041, 60043, 60044,
        60046, 60048, 60050, 60052, 60054, 60056, 60058, 60060, 60062, 60064, 60066, 60068,
        60070, 60072, 60074, 60076, 60078, 70001, 70002, 70003, 70004, 70005, 70006, 70007,
        70008, 70009, 70010, 70011, 70012, 1522195, 1522196, 1522240, 1522329, 1540259, 2000103, 2000104,
        2000105, 2001000, 2001001, 2001002, 2001003, 2001004, 2001005, 2001006, 2001007, 2001008, 2001009, 2001010,
        2001011, 2001012, 2001013, 2001014, 2001015, 2001016, 2001017, 2001018, 2001019, 2001020, 2001021, 2001022,
        2001023, 2001024, 2001025, 2001026, 2001027, 2001028, 2001029, 2001030, 2001031, 2001032, 2001033, 2001034,
        2001035, 2001036, 2001037, 2001038, 2001039, 2001040, 2001041, 2001042, 2001043, 2001044, 2001045, 2001046,
        2001047, 2001048, 2001049, 2001050, 2001051, 2001052, 2001053, 2001054, 2001055, 2001056, 2001057, 2001058,
        2001059, 2001060, 2001061, 2001062, 2001063, 2001064, 2001065, 2001066, 2001067, 2001068, 2001069, 2001070,
        2001071, 2001072, 2001073, 2001074, 2001075, 2001076, 2001079, 2001080, 2001081, 2001082, 2001083, 2001084,
        2001085, 2001086, 2001087, 2001088, 2001089, 2001090, 2001091, 2001092, 2001093, 2001094, 2001095, 2001096,
        2001097, 2001098, 2001099, 2001100, 2001101, 2001102, 2001103, 2001104, 2001105, 2001106, 2001107, 2001108,
        2001109, 2001110, 2001111, 2001112, 2001113, 2001114, 2001115, 2001116, 2001117, 2001118, 2001119, 2001120,
        2001121, 2001122, 2001123, 2001124, 2001125, 2001126, 2001127, 2001128, 2001129, 2001130, 2001131, 2001132,
        2001133, 2001134, 2001135, 2001136, 2001137, 2001138, 2001139, 2001140, 2001141, 2001142, 2001143, 2001144,
        2001145, 2001146, 2001147, 2001148, 2001149, 2001150, 2001151, 2001152, 2001153, 2001154, 2001155, 2001156,
        2001157, 2001158, 2001159, 2001160, 2001161, 2001162, 2001163, 2001164, 2001165, 2001166, 2001169, 2001170,
        2001171, 2001172, 2001173, 2001174, 2001175, 2001176, 2001177, 2001178, 2001179, 2001180, 2001181, 2001182,
        2001183, 2001184, 2001185, 2001186, 2001187, 2001188, 2001189, 2001190, 2001191, 2001193, 2001194, 2001195,
        2001196, 2001197, 2001198, 2001199, 2001200, 2001201, 2001202, 2001203, 2001204, 2001205, 2001206, 2001207,
        2001208, 2001209, 2001210, 2001211, 2001212, 2001213, 2001214, 2001215, 2001216, 2001217, 2001218, 2001219,
        2001220, 2001221, 2001222, 2001223, 2001224, 2002000, 2002101, 2002102, 2002103, 2002201, 2002202, 2002203,
        2002204, 2002205, 2002206, 2002901, 2002902, 2002903, 2002904, 2002905, 2002906, 2002907, 2002920, 2002921,
        2002922, 2002923, 2002924, 2002925, 2002926, 2002927, 2002928, 2002929, 2002930, 2002931, 2002932, 2002933,
        2002934, 2002935, 2002936, 2002937, 2002938, 2002939, 2002940, 2002941, 2002942, 2002943, 2002944, 2002945,
        2002946, 2002947, 2002948, 2002949, 2002950, 2002951, 2002952, 2002965, 2002966, 2002967, 2002968, 2002969,
        2002970, 2003000, 2003001, 2003002, 2003003, 2003004, 2003005, 2003006, 2003007, 2003008, 2003009, 2003010,
        2003011, 2003012, 2003013, 2003014, 2003015, 2003016, 2003017, 2003018, 2003019, 2003020, 2003021, 2003022,
        2003023, 2003024, 2003025, 2003026, 2003027, 2003028, 2003029, 2004006, 2005001, 2005002, 2005003, 2005007,
        2005008, 2005009, 2005023, 2005024, 2005025, 2005028, 2005031, 2005034, 2005038, 2005041, 2005043, 2005047,
        2005048, 2005049, 2005050, 2005051, 2005052, 2005053, 2005058, 2005059, 2005060, 2005062, 2005063, 2005064,
        2005065, 2005066, 2005067, 2005068, 2005069, 2005070, 2005071, 2005072, 2005073, 2005074, 2005075, 2005076,
        2005078, 2005079, 2005080, 2005081, 2005082, 2005083, 2005084, 2005085, 2005086, 2005087, 2005088, 2005092,
        2005093, 2005094, 2005096, 2005097, 2005098, 2005099, 2005100, 2005101, 2005105, 2005106, 2005107, 2005108,
        2005111, 2005112, 2005113, 2005114, 2005115, 2005116, 2005117, 2005119, 2005123, 2005124, 2005125, 2005126,
        2005127, 2005128, 2005129, 2005130, 2005131, 2005132, 2005133, 2005134, 2005135, 2005136, 2005137, 2005138,
        2005139, 2005140, 2005141, 2005143, 2005144, 2005145, 2005147, 2005148, 2005149, 2005150, 2005151, 2005152,
        2005154, 2005155, 2005158, 2005159, 2005160, 2005161, 2005162, 2005163, 2005164, 2005165, 2005166, 2005167,
        2005168, 2005169, 2005170, 2005171, 2005172, 2005173, 2005174, 2005175, 2005176, 2005177, 2005178, 2005179,
        2005180, 2005181, 2005183, 2005184, 2005185, 2005186, 2005187, 2005188, 2005190, 2005191, 2005192, 2005193,
        2005194, 2005195, 2005196, 2005197, 2005198, 2005199, 2005200, 2005202, 2005203, 2005204, 2005205, 2005206,
        2005207, 2005208, 2005211, 2005212, 2005213, 2005214, 2005215, 2005216, 2005217, 2005218, 2005219, 2005220,
        2005221, 2005224, 2005225, 2005226, 2005227, 2005228, 2005237, 2005239, 2005245, 2005247, 2005248, 2005249,
        2005250, 2005251, 2005252, 2005253, 2005254, 2005255, 2005256, 2005257, 2005258, 2005259, 2005260, 2005261,
        2005262, 2005263, 2005264, 2005265, 2005266, 2005267, 2005268, 2005269, 2010001, 2010002, 2010003, 2010004,
        2010005, 2010006, 2010007, 2010008, 2010009, 2200002, 2200003, 2200004, 2200005, 2200006, 2200007, 2200008,
        2200009, 2200010, 2200011, 2200012, 2200013, 2200014, 2200015, 2200016, 2200017, 2200018, 2200019, 2200020,
        2200021, 2200022, 2200023, 2200024, 2200025, 2200026, 2200027, 2200028, 2200029, 2200030, 2200031, 2200032,
        2200033, 2200034, 2200035, 2200036, 2200037, 2200038, 2200039, 2200041, 2200043, 2200044, 2200045, 2200046,
        2200047, 2200048, 2200049, 2200050, 2200051, 2200052, 2200053, 2200054, 2200055, 2200056, 2200057, 2200058,
        2200059, 2200063, 2200064, 2200065, 2200066, 2200067, 2200068, 2200069, 2200070, 2200071, 2200072, 2200073,
        2200074, 2200075, 2200076, 2200077, 2200078, 2200079, 2200080, 2200081, 2200082, 2200083, 2200084, 2200085,
        2200086, 2200087, 2200088, 2200089, 2200090, 2200091, 2200092, 2200093, 2200094, 2200095, 2200096, 2200097,
        2200098, 2200099, 2200100, 2200102, 2200103, 2200104, 2200105, 2200107, 2200108, 2200110, 2200111, 2200112,
        2200113, 2200114, 2200115, 2200116, 2200118, 2200119, 2200120, 2200121, 2200123, 2200124, 2200125, 2200126,
        2200140, 2200141, 2200142, 2200143, 2200144, 2200158, 2200161, 2200167, 2200168, 2200169, 2200170, 2200171,
        2200172, 2200173, 2200174, 2200210, 2200211, 2200212, 2200217, 2200218, 2200219, 2200222, 2200223, 2200224,
        2200228, 2200229, 2200231, 2200232, 2200233, 2200235, 2200236, 2200237, 2200238, 2200239, 2200240, 2200241,
        2200244, 2200245, 2200246, 2200248, 2200249, 2200250, 2200253, 2200260, 2200261, 2200262, 2201048, 4507702,
        4507703, 12222958, 22001034, 22001036, 22001037, 22001038, 22001039, 22001044, 22001045, 22001049, 80080001, 80080002,
        80080003, 80080004, 80080005, 220010450, 220010451, 220010452, 220010453, 220010454, 220010455, 220010456, 220010457, 220010458,
        220010459, 220010460, 220010462, 220010492, 300000001, 300000002, 300000003, 300000004, 300000005, 300000006, 300000007, 300000008,
        300000009, 300000010, 300000011, 300000012, 300000013, 300000014, 300000015, 300000016, 300000017, 300000018, 300000019, 300000020,
        300000021, 300000022, 300000023, 300000024, 300000025, 300000026, 300010001, 300010002, 300010003, 300010004, 300010005,
    }

    -- ============ Avatar Frame ID List (Kept As-Is) ============
    local FRAME_IDS = {
        30079, 30090, 30092, 30094, 30095, 30098, 30111, 30112, 30116, 30117, 30118, 30119,
        30122, 30123, 30125, 30128, 30129, 30130, 30142, 30143, 30144, 30145, 30146, 30147,
        30148, 30149, 30150, 30151, 30152, 30156, 30157, 30158, 30159, 30163, 30164, 30167,
        30168, 30169, 30176, 30177, 30185, 30186, 30191, 30194, 30195, 30202, 30204, 30216,
        30217, 30238, 30239, 30254, 30255, 30257, 30263, 30264, 30286, 30287, 30294, 30295,
        30298, 30299, 30300, 30301, 30302, 30303, 30306, 30307, 30309, 30312, 30313, 30314,
        30315, 30317, 30318, 30319, 30322, 30323, 30326, 30327, 30328, 30329, 30332, 30333,
        30334, 30335, 30338, 30341, 30342, 30343, 30344, 30345, 30346, 30349, 30350, 30351,
        30352, 30355, 30356, 30357, 30359, 30360, 30363, 30364, 30367, 30368, 30369, 30370,
        30373, 30374, 30375, 30376, 30377, 30380, 30381, 30382, 30383, 30386, 30387, 30388,
        30389, 30392, 30393, 30394, 30395, 30601, 30602, 30605, 30606, 30609, 30610, 30611,
        30612, 30615, 30616, 30617, 30618, 30621, 30622, 30623, 30624, 30625, 30627, 30630,
        30631, 30632, 30633, 30634, 30637, 30638, 30639, 30640, 31001, 31261, 40002, 40005,
        40008, 40011, 40014, 40017, 40020, 40023, 40026, 40029, 40032, 40035, 40038, 40041,
        40044, 40047, 40050, 60003, 60005, 60009, 60011, 60015, 60017, 60021, 60023, 60027,
        60029, 60033, 60035, 60039, 60041, 60043, 60046, 60048, 60052, 60054, 60058, 60060,
        60064, 60066, 60070, 60072, 60076, 60078, 70002, 70004, 70006, 70008, 70010, 70012,
        1403200, 1602266, 1602267, 2000103, 2000104, 2000105, 2001000, 2001001, 2001002, 2001003, 2001004, 2001005,
        2001006, 2001007, 2001008, 2001009, 2001010, 2001011, 2001012, 2001013, 2001014, 2001015, 2001016, 2001017,
        2001018, 2001019, 2001020, 2001021, 2001022, 2001023, 2001024, 2001025, 2001026, 2001027, 2001028, 2001029,
        2001030, 2001031, 2001032, 2001033, 2001034, 2001035, 2001036, 2001037, 2001038, 2001039, 2001040, 2001041,
        2001042, 2001043, 2001044, 2001045, 2001046, 2001047, 2001048, 2001049, 2001050, 2001051, 2001052, 2001053,
        2001054, 2001055, 2001056, 2001057, 2001058, 2001059, 2001060, 2001061, 2001062, 2001063, 2001064, 2001065,
        2001066, 2001067, 2001068, 2001069, 2001070, 2001071, 2001072, 2001073, 2001074, 2001075, 2001076, 2001079,
        2001080, 2001081, 2001082, 2001083, 2001084, 2001085, 2001086, 2001087, 2001088, 2001089, 2001090, 2001091,
        2001092, 2001093, 2001094, 2001095, 2001096, 2001097, 2001098, 2001099, 2001100, 2001101, 2001102, 2001103,
        2001104, 2001105, 2001106, 2001107, 2001108, 2001109, 2001110, 2001111, 2001112, 2001113, 2001114, 2001115,
        2001116, 2001117, 2001118, 2001119, 2001120, 2001121, 2001122, 2001123, 2001124, 2001125, 2001126, 2001127,
        2001128, 2001129, 2001130, 2001131, 2001132, 2001133, 2001134, 2001135, 2001136, 2001137, 2001138, 2001139,
        2001140, 2001141, 2001142, 2001143, 2001144, 2001145, 2001146, 2001147, 2001148, 2001149, 2001150, 2001151,
        2001152, 2001153, 2001154, 2001155, 2001156, 2001157, 2001158, 2001159, 2001160, 2001161, 2001162, 2001163,
        2001164, 2001165, 2001166, 2001169, 2001170, 2001171, 2001172, 2001173, 2001174, 2001175, 2001176, 2001177,
        2001178, 2001179, 2001180, 2001181, 2001182, 2001183, 2001184, 2001185, 2001186, 2001187, 2001188, 2001189,
        2001190, 2001191, 2001193, 2001194, 2001195, 2001196, 2001197, 2001198, 2001199, 2001200, 2001201, 2001202,
        2001203, 2001204, 2001205, 2001206, 2001207, 2001208, 2001209, 2001210, 2001211, 2001212, 2001213, 2001214,
        2001215, 2001216, 2001217, 2001218, 2001219, 2001220, 2001221, 2001222, 2001223, 2001224, 2002000, 2002001,
        2002002, 2002003, 2002004, 2002005, 2002006, 2002007, 2002101, 2002102, 2002103, 2002201, 2002202, 2002203,
        2002204, 2002205, 2002206, 2002901, 2002902, 2002903, 2002904, 2002905, 2002906, 2002907, 2002908, 2002909,
        2002910, 2002911, 2002912, 2002913, 2002914, 2002915, 2002916, 2002917, 2002918, 2002919, 2002920, 2002921,
        2002922, 2002923, 2002924, 2002925, 2002926, 2002927, 2002928, 2002929, 2002930, 2002931, 2002932, 2002933,
        2002934, 2002935, 2002936, 2002937, 2002938, 2002939, 2002940, 2002941, 2002942, 2002943, 2002944, 2002945,
        2002946, 2002947, 2002948, 2002949, 2002950, 2002951, 2002952, 2002965, 2002966, 2002967, 2002968, 2002969,
        2002970, 2003000, 2003001, 2003002, 2003003, 2003004, 2003005, 2003006, 2003007, 2003008, 2003009, 2003010,
        2003011, 2003012, 2003013, 2003014, 2003015, 2003016, 2003017, 2003018, 2003019, 2003020, 2003021, 2003022,
        2003023, 2003024, 2003025, 2003026, 2003027, 2003028, 2003029, 2004003, 2004005, 2004006, 2005001, 2005002,
        2005003, 2005004, 2005007, 2005008, 2005009, 2005010, 2005012, 2005013, 2005014, 2005015, 2005016, 2005017,
        2005018, 2005019, 2005020, 2005021, 2005022, 2005023, 2005024, 2005025, 2005026, 2005027, 2005028, 2005029,
        2005030, 2005031, 2005032, 2005033, 2005034, 2005035, 2005036, 2005037, 2005038, 2005039, 2005040, 2005041,
        2005042, 2005043, 2005044, 2005045, 2005046, 2005047, 2005048, 2005049, 2005050, 2005051, 2005052, 2005053,
        2005056, 2005057, 2005058, 2005059, 2005060, 2005061, 2005062, 2005063, 2005064, 2005065, 2005066, 2005067,
        2005068, 2005069, 2005070, 2005071, 2005072, 2005073, 2005074, 2005075, 2005076, 2005077, 2005078, 2005079,
        2005080, 2005081, 2005082, 2005083, 2005084, 2005085, 2005086, 2005087, 2005088, 2005089, 2005090, 2005091,
        2005092, 2005093, 2005094, 2005095, 2005096, 2005097, 2005098, 2005099, 2005100, 2005101, 2005102, 2005103,
        2005104, 2005105, 2005106, 2005107, 2005108, 2005111, 2005112, 2005113, 2005114, 2005115, 2005116, 2005117,
        2005118, 2005119, 2005120, 2005121, 2005122, 2005123, 2005124, 2005125, 2005126, 2005127, 2005128, 2005129,
        2005130, 2005131, 2005132, 2005133, 2005134, 2005135, 2005136, 2005137, 2005138, 2005139, 2005140, 2005141,
        2005142, 2005143, 2005144, 2005145, 2005146, 2005147, 2005148, 2005149, 2005150, 2005151, 2005152, 2005153,
        2005154, 2005155, 2005156, 2005157, 2005158, 2005159, 2005160, 2005161, 2005163, 2005164, 2005165, 2005166,
        2005167, 2005168, 2005169, 2005170, 2005171, 2005172, 2005173, 2005174, 2005175, 2005176, 2005177, 2005178,
        2005179, 2005180, 2005181, 2005182, 2005183, 2005184, 2005185, 2005186, 2005187, 2005188, 2005189, 2005190,
        2005191, 2005192, 2005193, 2005194, 2005195, 2005196, 2005197, 2005198, 2005199, 2005200, 2005201, 2005202,
        2005203, 2005204, 2005205, 2005206, 2005207, 2005208, 2005209, 2005210, 2005211, 2005212, 2005213, 2005214,
        2005215, 2005216, 2005217, 2005218, 2005219, 2005220, 2005221, 2005222, 2005223, 2005224, 2005225, 2005226,
        2005227, 2005228, 2005237, 2005239, 2005240, 2005241, 2005242, 2005243, 2005244, 2005245, 2005246, 2005247,
        2005248, 2005249, 2005250, 2005251, 2005252, 2005253, 2005254, 2005255, 2005256, 2005257, 2005258, 2005259,
        2005260, 2005261, 2005262, 2005263, 2005264, 2005265, 2005266, 2005267, 2005268, 2005269, 2010001, 2010002,
        2010003, 2010004, 2010005, 2010006, 2010007, 2010008, 2010009, 2200002, 2200003, 2200004, 2200005, 2200006,
        2200007, 2200008, 2200009, 2200010, 2200011, 2200012, 2200013, 2200014, 2200015, 2200016, 2200017, 2200018,
        2200019, 2200020, 2200021, 2200022, 2200023, 2200024, 2200025, 2200026, 2200027, 2200028, 2200029, 2200030,
        2200031, 2200032, 2200033, 2200034, 2200035, 2200036, 2200037, 2200038, 2200039, 2200040, 2200041, 2200043,
        2200044, 2200045, 2200046, 2200047, 2200048, 2200049, 2200050, 2200051, 2200052, 2200053, 2200054, 2200055,
        2200056, 2200057, 2200058, 2200059, 2200060, 2200063, 2200064, 2200065, 2200066, 2200067, 2200068, 2200069,
        2200070, 2200071, 2200072, 2200073, 2200074, 2200075, 2200076, 2200077, 2200078, 2200079, 2200080, 2200081,
        2200082, 2200083, 2200084, 2200085, 2200086, 2200087, 2200088, 2200089, 2200090, 2200091, 2200092, 2200093,
        2200094, 2200095, 2200096, 2200097, 2200098, 2200099, 2200100, 2200102, 2200103, 2200104, 2200105, 2200106,
        2200107, 2200108, 2200109, 2200110, 2200111, 2200112, 2200113, 2200114, 2200115, 2200116, 2200117, 2200118,
        2200119, 2200120, 2200121, 2200122, 2200123, 2200124, 2200125, 2200126, 2200140, 2200141, 2200142, 2200143,
        2200144, 2200145, 2200146, 2200147, 2200148, 2200149, 2200150, 2200151, 2200155, 2200156, 2200157, 2200158,
        2200161, 2200162, 2200163, 2200164, 2200165, 2200166, 2200167, 2200168, 2200169, 2200170, 2200171, 2200172,
        2200173, 2200174, 2200210, 2200211, 2200212, 2200213, 2200214, 2200216, 2200217, 2200218, 2200219, 2200220,
        2200221, 2200222, 2200223, 2200224, 2200225, 2200226, 2200227, 2200228, 2200229, 2200230, 2200231, 2200232,
        2200233, 2200234, 2200235, 2200236, 2200237, 2200238, 2200239, 2200240, 2200241, 2200242, 2200243, 2200244,
        2200245, 2200246, 2200248, 2200249, 2200250, 2200251, 2200252, 2200253, 2200256, 2200260, 2200261, 2200262,
        2201048, 4507703, 12219672, 12219673, 12220609, 12220611, 12222958, 22001034, 22001036, 22001037, 22001038, 22001039,
        22001040, 22001041, 22001042, 22001043, 22001044, 22001045, 22001047, 22001048, 22001049, 61830001, 61830002, 61830003,
        62310001, 62410001, 66631070, 66631704, 66631705, 66631706, 66631707, 66631708, 66631709, 66631710, 66632393, 220010450,
        220010451, 220010452, 220010453, 220010454, 220010455, 220010456, 220010457, 220010458, 220010459, 220010460, 220010462, 220010492,
        300000001, 300000002, 300000003, 300000004, 300000005, 300000006, 300000007, 300000008, 300000009, 300000010, 300000011, 300000012,
        300000013, 300000014, 300000015, 300000016, 300000017, 300000018, 300000019, 300000020, 300000021, 300000022, 300000023, 300000024,
        300000025, 300000026,
    }

    -- ============ Get BeysaFake Reference ============
    local BF = _G.BeysaFake

    -- ============ Local Config File (Save Selected Avatar / Avatar Frame) ============
    local PROFILE_INI = "/storage/emulated/0/Android/data/com.tencent.ig/files/BeysaProfile.ini"
    local function saveProfile()
        pcall(function()
            local a, b = BF.GetProfile()
            -- Star Key: Prefer writing user choice recorded by this script's Hook, prevent BF.GetProfile returning server old value
            if (_G.__BeysaUserAvatarPick or 0) > 0 then a = _G.__BeysaUserAvatarPick end
            if (_G.__BeysaUserFramePick  or 0) > 0 then b = _G.__BeysaUserFramePick  end
            local f = io.open(PROFILE_INI, "w")
            if not f then return end
            f:write("[Profile]\nAVATAR=" .. tostring(a or 0) ..
                    "\nFRAME="  .. tostring(b or 0) .. "\n")
            f:close()
        end)
    end

    -- Star Wrap original setting function: First update independent variable (for _resolveAvatarIds to read first), then call original, then write to disk
    local rawSetAvatar, rawSetBox = BF.SetAvatar, BF.SetAvatarBox

    BF.SetAvatar = function(id)
        local n = tonumber(id) or 0
        if n > 0 then _G.__BeysaUserAvatarPick = n end
        rawSetAvatar(id)
        saveProfile()
    end

    BF.SetAvatarBox = function(id)
        local n = tonumber(id) or 0
        if n > 0 then _G.__BeysaUserFramePick = n end
        rawSetBox(id)
        saveProfile()
    end

    -- Restore last selection on startup: First write independent variable (for _resolveAvatarIds to read), then call original
    pcall(function()
        local f = io.open(PROFILE_INI, "r")
        if not f then return end
        local txt = f:read("*a"); f:close()
        local a = tonumber(txt:match("AVATAR%s*=%s*(%d+)"))
        local b = tonumber(txt:match("FRAME%s*=%s*(%d+)"))
        if a and a > 0 then
            _G.__BeysaUserAvatarPick = a
            rawSetAvatar(a)
        end
        if b and b > 0 then
            _G.__BeysaUserFramePick = b
            rawSetBox(b)
        end
    end)

    -- ============ Safe Send Event (Auto Skip When Module Missing) ============
    local function post(evType, evId, arg1)
        pcall(function()
            if EventSystem and _G[evType] and _G[evId] then
                EventSystem:postEvent(_G[evType], _G[evId], arg1)
            end
        end)
    end

    -- Star Star Star Core Fix: Use 2033 Timestamp (Never Use 4.9 Billion, Otherwise Triggers int32 Overflow to Negative!) Star Star Star
    local FOREVER_TS = 2000000000

    -- Injected ID set (for quickly judging if locally handled)
    local INJ_A, INJ_F = {}, {}

    -- ============ Merge Avatar IDs into Avatar List ============
    local function mergeAvatars(sys)
        if not _G.FormulaFeatureEnabled("avatarLists") then return end
        sys.HeadportraitList = sys.HeadportraitList or {}

        -- Star Star Star Core: Permanent Utility Function (All Time-Limit Fields = Future Timestamp) Star Star Star
        local function makePermanent(template)
            local item = {}
            if type(template) == "table" then
                for kk, vv in pairs(template) do
                    item[kk] = vv
                end
            end
            rawset(item, "state",          1)
            rawset(item, "valid_hours",    0)
            rawset(item, "expire_time",    FOREVER_TS)
            rawset(item, "expire_ts",      FOREVER_TS)
            rawset(item, "expire_at",      FOREVER_TS)
            rawset(item, "expired_at",     FOREVER_TS)
            rawset(item, "receive_time",   os.time())
            rawset(item, "have_used",      1)
            rawset(item, "is_expired",     0)
            rawset(item, "expired",        false)
            return item
        end

        local template = nil
        local templateType = nil
        for _, v in pairs(sys.HeadportraitList) do
            if type(v) == "number" and v > 0 then
                template = v
                templateType = "number"
                break
            elseif type(v) == "table" then
                local st = tonumber(v.state) or 0
                local vh = tonumber(v.valid_hours)
                if st > 0 and vh == 0 then
                    template = v
                    templateType = "table"
                    break
                end
            end
        end

        local nAvatar = #AVATAR_IDS
        for i = 1, nAvatar do
            local id = AVATAR_IDS[i]
            local k = tostring(id)
            local existing = sys.HeadportraitList[k] or sys.HeadportraitList[id]
            if existing == nil then
                if templateType == "number" then
                    sys.HeadportraitList[k] = template
                else
                    sys.HeadportraitList[k] = makePermanent(templateType == "table" and template or nil)
                end
                INJ_A[k] = true
                INJ_A[id] = true
            elseif type(existing) == "table" then
                local function _fix(it)
                    if tonumber(it.state) ~= 1 then rawset(it, "state", 1) end
                    if tonumber(it.valid_hours or 0) ~= 0 then rawset(it, "valid_hours", 0) end
                    if tonumber(it.expire_time or 0) < FOREVER_TS then rawset(it, "expire_time", FOREVER_TS) end
                    if tonumber(it.expire_ts   or 0) < FOREVER_TS then rawset(it, "expire_ts",   FOREVER_TS) end
                    if tonumber(it.expire_at   or 0) < FOREVER_TS then rawset(it, "expire_at",   FOREVER_TS) end
                    if tonumber(it.expired_at  or 0) < FOREVER_TS then rawset(it, "expired_at",  FOREVER_TS) end
                    if tonumber(it.is_expired  or 0) ~= 0 then rawset(it, "is_expired", 0) end
                    if it.expired == true then rawset(it, "expired", false) end
                end
                _fix(existing)
                if sys.HeadportraitList[k] and type(sys.HeadportraitList[k]) == "table" then
                    _fix(sys.HeadportraitList[k])
                end
                if sys.HeadportraitList[id] and type(sys.HeadportraitList[id]) == "table" then
                    _fix(sys.HeadportraitList[id])
                end
                INJ_A[k] = true
                INJ_A[id] = true
            end
        end
    end

    -- ============ Merge Avatar Frame IDs into Avatar Frame List ============
    local function mergeFrames(sys)
        if not _G.FormulaFeatureEnabled("avatarLists") then return end
        sys.AvatarFrameList = sys.AvatarFrameList or {}

        local function makePermanent(template)
            local item = {}
            if type(template) == "table" then
                for kk, vv in pairs(template) do
                    item[kk] = vv
                end
            else
                item = {
                    rank = 0, rank_id = 0, nation = "",
                }
            end
            rawset(item, "state",          1)
            rawset(item, "valid_hours",    0)
            rawset(item, "expire_time",    FOREVER_TS)
            rawset(item, "expire_ts",      FOREVER_TS)
            rawset(item, "expire_at",      FOREVER_TS)
            rawset(item, "expired_at",     FOREVER_TS)
            rawset(item, "receive_time",   os.time())
            rawset(item, "have_used",      1)
            rawset(item, "is_expired",     0)
            rawset(item, "expired",        false)
            return item
        end

        local template = nil
        for _, v in pairs(sys.AvatarFrameList) do
            if type(v) == "table" then
                local st = tonumber(v.state) or 0
                local vh = tonumber(v.valid_hours)
                if st > 0 and vh == 0 then
                    template = v
                    break
                end
            end
        end

        for _, id in ipairs(FRAME_IDS) do
            local existing = sys.AvatarFrameList[id] or sys.AvatarFrameList[tostring(id)]
            if existing == nil then
                sys.AvatarFrameList[id] = makePermanent(template)
                INJ_F[id] = true
            elseif type(existing) == "table" then
                local function _fix(it)
                    if tonumber(it.state) ~= 1 then rawset(it, "state", 1) end
                    if tonumber(it.valid_hours or 0) ~= 0 then rawset(it, "valid_hours", 0) end
                    if tonumber(it.expire_time or 0) < FOREVER_TS then rawset(it, "expire_time", FOREVER_TS) end
                    if tonumber(it.expire_ts   or 0) < FOREVER_TS then rawset(it, "expire_ts",   FOREVER_TS) end
                    if tonumber(it.expire_at   or 0) < FOREVER_TS then rawset(it, "expire_at",   FOREVER_TS) end
                    if tonumber(it.expired_at  or 0) < FOREVER_TS then rawset(it, "expired_at",  FOREVER_TS) end
                    if tonumber(it.is_expired  or 0) ~= 0 then rawset(it, "is_expired", 0) end
                    if it.expired == true then rawset(it, "expired", false) end
                end
                _fix(existing)
                if sys.AvatarFrameList[id] and type(sys.AvatarFrameList[id]) == "table" then
                    _fix(sys.AvatarFrameList[id])
                end
                if sys.AvatarFrameList[tostring(id)] and type(sys.AvatarFrameList[tostring(id)]) == "table" then
                    _fix(sys.AvatarFrameList[tostring(id)])
                end
                INJ_F[id] = true
            end
        end
    end

    -- ============ Generic Parameter Cleanup (Compatible with / without self) ============
    local function unpackCall(...)
        local n = select("#", ...)
        if n >= 4 then
            local a1, a2, a3, a4 = ...
            return a1, a2, a3, a4
        elseif n == 3 then
            local a1, a2, a3 = ...
            if type(a1) == "table" then
                return a1, a2, a3, nil
            else
                return nil, a1, a2, a3
            end
        elseif n == 2 then
            local a1, a2 = ...
            if type(a1) == "table" then
                return a1, a2, nil, nil
            else
                return nil, a1, a2, nil
            end
        else
            local a1 = ...
            if type(a1) == "table" then
                return a1, nil, nil, nil
            else
                return nil, a1, nil, nil
            end
        end
    end

    -- Star Fix: Uniformly parse "first real parameter", compatible with self / without self calls
    local function pickFirstArg(self, arg1)
        if type(self) == "table" then
            return arg1
        end
        return self or arg1
    end

    -- ============ Hook Avatar Module ============
    local function hookAvatar()
        local ok, sys = pcall(require, "client.slua.logic.roleInfo.logic_roleInfo_Avatar")
        if not ok or type(sys) ~= "table" then
            print("[Beysa] Avatar module not loaded")
            return false
        end

        if not sys.__orig_send_change_user_avatar then
            sys.__orig_send_change_user_avatar = sys.send_change_user_avatar
        end

        sys.send_change_user_avatar = function(...)
            if not _G.FormulaFeatureEnabled("avatarLists") then
                if type(sys.__orig_send_change_user_avatar) == "function" then
                    return sys.__orig_send_change_user_avatar(...)
                end
                return
            end
            local self, arg1 = unpackCall(...)
            local item_url = pickFirstArg(self, arg1)
            local id = tonumber(item_url)

            if id then
                -- 1. Force locally (write independent variable first)
                BF.SetAvatar(id)
                pcall(function()
                    if DataMgr then DataMgr.UpdateHeadIconUrl(tostring(id)) end
                end)

                -- 2. Fake server success response (dot call! Must not change to colon)
                if type(sys.on_change_user_avatar_rsp) == "function" then
                    pcall(sys.on_change_user_avatar_rsp, 0, tostring(id))
                end

                -- 3. Send refresh event
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_USE_AVATAR")
                post("EVENTTYPE_LOBBY",     "EVENTID_UPDATE_LOBBY_AVATAR")
                pcall(function() if ShowNotice then ShowNotice("Paint applied") end end)
                print("[Beysa] Avatar locally effective (fake response): " .. tostring(id))

                return
            end

            if type(sys.__orig_send_change_user_avatar) == "function" then
                return sys.__orig_send_change_user_avatar(...)
            end
        end

        local origRsp = sys.get_user_avatar_list_rsp
        sys.get_user_avatar_list_rsp = function(...)
            local self, err, list, url = unpackCall(...)
            if type(origRsp) == "function" then pcall(origRsp, ...) end
            if not _G.FormulaFeatureEnabled("avatarLists") then return end
            if err == 0 then
                mergeAvatars(sys)
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_HEAD_INFO",
                     DataMgr and DataMgr.roleData and DataMgr.roleData.headIconUrl)
            end
        end

        mergeAvatars(sys)
        print("[Beysa] Avatar hook mounted successfully")
        return true
    end

    -- ============ Hook Avatar Frame Module ============
    local function hookFrame()
        local ok, sys = pcall(require, "client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
        if not ok or type(sys) ~= "table" then
            print("[Beysa] Avatar frame module not loaded")
            return false
        end

        if not sys.__orig_change_avatar_box then
            sys.__orig_change_avatar_box = sys.change_avatar_box
        end

        sys.change_avatar_box = function(...)
            if not _G.FormulaFeatureEnabled("avatarLists") then
                if type(sys.__orig_change_avatar_box) == "function" then
                    return sys.__orig_change_avatar_box(...)
                end
                return
            end
            local self, arg1 = unpackCall(...)
            local item_id = pickFirstArg(self, arg1)
            local id = tonumber(item_id)

            if id then
                -- 1. Force locally (write independent variable first)
                BF.SetAvatarBox(id)
                pcall(function()
                    if DataMgr and DataMgr.roleData then
                        DataMgr.roleData.cur_avatar_box_id = id
                    end
                end)
                pcall(function() sys.UpdateCurAvatarBoxID(id) end)

                -- 2. Fake server success response (dot call! Must not change to colon)
                if type(sys.on_change_avatar_box_rsp) == "function" then
                    pcall(sys.on_change_avatar_box_rsp, 0, id)
                end

                -- 3. Send refresh event
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO")
                post("EVENTTYPE_LOBBY",     "EVENTID_UPDATE_LOBBY_AVATAR")
                pcall(function() if ShowNotice then ShowNotice("Paint applied") end end)
                print("[Beysa] Avatar frame locally effective (fake response): " .. tostring(id))

                return
            end

            if type(sys.__orig_change_avatar_box) == "function" then
                return sys.__orig_change_avatar_box(...)
            end
        end

        local origRsp = sys.get_avatar_box_list_rsp
        sys.get_avatar_box_list_rsp = function(...)
            local self, err, list, cur = unpackCall(...)
            if type(origRsp) == "function" then pcall(origRsp, ...) end
            if not _G.FormulaFeatureEnabled("avatarLists") then return end
            if err == 0 then
                mergeFrames(sys)
                post("EVENTTYPE_ROLEINFO", "EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO")
            end
        end

        mergeFrames(sys)
        print("[Beysa] Avatar frame hook mounted successfully")
        return true
    end

    -- Star Star Star Ultimate Safety: Intercept Underlying Prompt Box, Forcibly Swallow "Limited Item Expired" Star Star Star
    local function blockExpirePopup()
        pcall(function()
            local MsgBox = require("client.slua.logic.common.logic_common_msg_box")
            if not MsgBox or not MsgBox.Show or MsgBox.__beysa_hooked then return end
            MsgBox.__beysa_hooked = true

            local origShow = MsgBox.Show
            MsgBox.Show = function(...)
                if not _G.FormulaFeatureEnabled("avatarLists") then return origShow(...) end
                local n = select("#", ...)
                local a = { ... }
                local content = nil
                if n >= 4 and type(a[1]) == "table" then
                    content = a[4]
                elseif n == 3 then
                    content = a[3]
                elseif n == 2 and type(a[1]) == "table" then
                    content = a[2]
                end

                if content then
                    local cStr = tostring(content)
                    if cStr:find("Limited item expired") or cStr:find("Expired") or cStr:find("Expired") then
                        print("[Beysa] Successfully intercepted underlying expiry popup!! ")
                        return
                    end
                end
                return origShow(...)
            end
        end)
    end

    -- Star Star Star New: Hook Generic Expiry Check Function (Double Safety) Star Star Star
    local function hookExpireCheck()
        if _G.__beysa_expire_hooked then return end
        _G.__beysa_expire_hooked = true

        pcall(function()
            local BU = import("BackpackUtils")
            if BU and type(BU.IsBattleItemHandleExist) == "function" and not BU.__beysa_hooked then
                BU.__beysa_hooked = true
                local orig = BU.IsBattleItemHandleExist
                BU.IsBattleItemHandleExist = function(defID, ...)
                    local ok, res = pcall(orig, defID, ...)
                    if not _G.FormulaFeatureEnabled("avatarLists") then return res end
                    if not ok or res == false then
                        local rid = defID and (defID.TypeSpecificID or defID.resID or defID)
                        rid = tonumber(rid)
                        if _G.FormulaFeatureEnabled("avatarLists") and rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                            return true
                        end
                    end
                    return res
                end
            end
        end)

        pcall(function()
            local AU = import("AvatarUtils")
            if AU and type(AU.IsItemExpired) == "function" and not AU.__beysa_hooked then
                AU.__beysa_hooked = true
                local orig = AU.IsItemExpired
                AU.IsItemExpired = function(itemId, ...)
                    local rid = tonumber(itemId)
                    if _G.FormulaFeatureEnabled("avatarLists") and rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                        return false
                    end
                    return orig(itemId, ...)
                end
            end
        end)

        pcall(function()
            local LIU = package.loaded["client.slua.logic.common.Logic_ItemUtils"]
            if not LIU then return end
            for _, name in ipairs({ "IsItemExpired", "IsExpired", "CheckItemExpired" }) do
                local orig = LIU[name]
                if type(orig) == "function" and not LIU["__beysa_hooked_" .. name] then
                    LIU["__beysa_hooked_" .. name] = true
                    LIU[name] = function(itemId, ...)
                        local rid = tonumber(itemId)
                        if _G.FormulaFeatureEnabled("avatarLists") and rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                            return false
                        end
                        return orig(itemId, ...)
                    end
                end
            end
        end)

        pcall(function()
            local UBU = import("UBackpackUtils")
            if UBU and not UBU.__beysa_hooked then
                UBU.__beysa_hooked = true
                for _, name in ipairs({ "IsItemExpired", "IsExpired", "CheckItemValid" }) do
                    local orig = UBU[name]
                    if type(orig) == "function" then
                        UBU[name] = function(itemId, ...)
                            local rid = tonumber(itemId)
                            if _G.FormulaFeatureEnabled("avatarLists") and rid and (INJ_A[tostring(rid)] or INJ_F[rid]) then
                                return false
                            end
                            return orig(itemId, ...)
                        end
                    end
                end
            end
        end)
    end

    -- Star New: Explicitly force-refresh lobby UI (one more safety layer beyond events)
    local function ForceRefreshLobbyUI()
        pcall(function()
            if not UIManager or not UIManager.UI_Config then return end
            local cfg = UIManager.UI_Config.Lobby_Main_UIBP
                     or (UIManager.UI_Config.Lobby and UIManager.UI_Config.Lobby.Lobby_Main_UIBP)
            if not cfg or not UIManager.GetUI then return end
            local ui = UIManager.GetUI(cfg)
            if not ui then return end
            if ui.OnRefresh   then pcall(ui.OnRefresh, ui)   end
            if ui.RefreshData then pcall(ui.RefreshData, ui) end
        end)
    end

    local function hookAll()
        if not _G.FormulaFeatureEnabled("avatarLists") then return false end
        pcall(hookExpireCheck)
        pcall(blockExpirePopup)
        local a = hookAvatar()
        local b = hookFrame()
        if a or b then
            local function _refresh()
                pcall(ForceRefreshLobbyUI)
            end
            if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
                _G.Mytimer_ticker.AddTimer(0.1, _refresh)
            else
                _refresh()
            end
        end
        return a and b
    end

    -- Install hooks only when the Avatar / Frame Lists switch is enabled.
    _G.FORMULA_ApplyAvatarLists = function(enabled)
        if not enabled then return true end
        local _ok, _res = pcall(hookAll)
        if not _ok or not _res then
            local retryList = { 3.0, 8.0, 20.0, 40.0, 60.0 }
            for _, sec in ipairs(retryList) do
                if _G.Mytimer_ticker then
                    _G.Mytimer_ticker.AddTimer(sec, function()
                        if _G.FormulaFeatureEnabled("avatarLists") then pcall(hookAll) end
                    end)
                else
                    local ok2, tk = pcall(require, "common.time_ticker")
                    if ok2 and tk and tk.AddTimer then
                        tk.AddTimer(sec, function()
                            if _G.FormulaFeatureEnabled("avatarLists") then pcall(hookAll) end
                        end)
                    end
                end
            end
        end
        return _ok and _res == true
    end
end


-- ============================================================
-- Collection lobby unlock + all display platforms unlock
-- ============================================================

local SOCIAL_HALL_CONFIG = {
    ROOM_SCENE_NAME = "Lobby_Social_CH_Mesh",   -- Collection lobby scene name
    CAMERA_ID       = 10151,                    -- Lobby camera ID
    DEFAULT_SKIN_ID = 6680102,                  -- Default character skin (backup)
    DEFAULT_BG_WALL = 6680201,                  -- Default background wall item ID
    MONUMENT_ID     = 6680702,                  -- Monument item ID (backup)
}

-- ============================================================
-- 1) Load the collection lobby scene
-- Star Fix 4: Change to async loading (first param false), avoid main thread freeze
-- ============================================================
function _G.LoadCollectionHallScene()
    pcall(function()
        if LobbySceneManager and LobbySceneManager.LoadStreamLevel then
            -- Second param true was originally blocking load, change to false to let engine async load
            LobbySceneManager.LoadStreamLevel(
                false,                          -- Star Async, does not block main thread
                SOCIAL_HALL_CONFIG.ROOM_SCENE_NAME,
                SOCIAL_HALL_CONFIG.CAMERA_ID,
                "Lobby_Light"
            )
        end
    end)
end

-- ============================================================
-- 2) Set the background wall behind yourself
-- Star Fix 3: DataMgr nil check, avoid error before loading
-- ============================================================
function _G.SetBehindPlayerBackground(bgItemId)
    pcall(function()
        bgItemId = bgItemId or SOCIAL_HALL_CONFIG.DEFAULT_BG_WALL

        -- Star New: Skip directly when DataMgr not loaded
        if not DataMgr or not DataMgr.roleData or not DataMgr.roleData.uid then
            return
        end

        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end

        local Logic_SocialLobbyModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if not Logic_SocialLobbyModule then return end

        local myUid = tonumber(DataMgr.roleData.uid)
        if not myUid then return end

        Logic_SocialLobbyModule:SetBGWallPicItemId(myUid, bgItemId)

        -- Notify UI refresh
        if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
            EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
        end
    end)
end

-- ============================================================
-- 3) Unlock all collection platforms
-- Star Fix 1 2 3: All three Hooks changed to "save original function first then wrap"
--   · CheckSlotTypeIsUCUnlock returns false (means "No UC needed")
--   · GetSlotIsUnlock... / GetSlotIsUnlocked... only take effect for your own UID
-- ============================================================
function _G.UnlockAllCollectionPlatforms()
    if not _G.FormulaFeatureEnabled("collectionUnlock") then return false end
    pcall(function()
        local ModuleManager = require("client.module_framework.ModuleManager")
        if not ModuleManager or not ModuleManager.LobbyModuleConfig then return end

        local Logic_SocialLobbyModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
        if not Logic_SocialLobbyModule then return end

        -- Judge if UID is self (only fully unlock when viewing self, keep original when viewing others)
        local function isSelfUid(uid)
            if not uid or not DataMgr or not DataMgr.roleData then return false end
            return tonumber(uid) == tonumber(DataMgr.roleData.uid)
        end

        -- ====================================================
        -- 1. GetSlotIsUnlockBySlotTypeAndIndex -- Check if slot is unlocked
        -- Star Fix 2: Only takes effect for self
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_slotUnlockHook then
            Logic_SocialLobbyModule.__zeroKali_slotUnlockHook = true
            local orig_GetSlotIsUnlock = Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex
            Logic_SocialLobbyModule.GetSlotIsUnlockBySlotTypeAndIndex =
                function(self, nUId, nSlotType, nSlotIndex)
                    if _G.FormulaFeatureEnabled("collectionUnlock") and isSelfUid(nUId) then
                        return true
                    end
                    if orig_GetSlotIsUnlock then
                        return orig_GetSlotIsUnlock(self, nUId, nSlotType, nSlotIndex)
                    end
                    return false
                end
        end

        -- ====================================================
        -- 2. CheckSlotTypeIsUCUnlock -- Check if slot "requires UC to unlock"
        -- Star Fix 1: Original code returning true is wrong, here must return false
        --   false = No UC needed; true = UC needed (will show "Unlock with UC")
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_ucUnlockHook then
            Logic_SocialLobbyModule.__zeroKali_ucUnlockHook = true
            local orig_CheckUCUnlock = Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock
            Logic_SocialLobbyModule.CheckSlotTypeIsUCUnlock =
                function(self, nSlotType, nSlotIndex)
                    if _G.FormulaFeatureEnabled("collectionUnlock") then
                        return false -- Local UI preview: no UC prompt for this slot.
                    end
                    if orig_CheckUCUnlock then
                        return orig_CheckUCUnlock(self, nSlotType, nSlotIndex)
                    end
                    return false
                end
        end

        -- ====================================================
        -- 3. GetSlotIsUnlockedByCollectHallLevel -- Check if locked due to collection level not met
        -- Star Fix 2: Only takes effect for self
        -- ====================================================
        if not Logic_SocialLobbyModule.__zeroKali_levelLockHook then
            Logic_SocialLobbyModule.__zeroKali_levelLockHook = true
            local orig_GetSlotIsUnlockedByLevel =
                Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel
            Logic_SocialLobbyModule.GetSlotIsUnlockedByCollectHallLevel =
                function(self, nUId, nSlotType, nSlotIndex)
                    if _G.FormulaFeatureEnabled("collectionUnlock") and isSelfUid(nUId) then
                        return true
                    end
                    if orig_GetSlotIsUnlockedByLevel then
                        return orig_GetSlotIsUnlockedByLevel(self, nUId, nSlotType, nSlotIndex)
                    end
                    return false
                end
        end

        -- ====================================================
        -- 4. Edit manager: Mark "current data is latest"
        --   (Let the edit flow allow save/apply)
        -- ====================================================
        local Logic_SocialLobbyEditMgrModule = ModuleManager.GetModule(
            ModuleManager.LobbyModuleConfig.Logic_SocialLobbyEditMgrModule)
        if Logic_SocialLobbyEditMgrModule
           and not Logic_SocialLobbyEditMgrModule.__zeroKali_latestHook then
            Logic_SocialLobbyEditMgrModule.__zeroKali_latestHook = true
            local orig_GetCurIsLatestData = Logic_SocialLobbyEditMgrModule.GetCurIsLatestData
            Logic_SocialLobbyEditMgrModule.GetCurIsLatestData = function(self, ...)
                if _G.FormulaFeatureEnabled("collectionUnlock") then return true end
                if type(orig_GetCurIsLatestData) == "function" then
                    return orig_GetCurIsLatestData(self, ...)
                end
                return false
            end
        end

        -- Notify UI refresh
        if EventSystem and EVENTTYPE_LOBBY_SOCIAL and EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE then
            EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SLOT_DATA_UPDATE)
        end
    end)
end

-- ============================================================
-- 4) Startup flow
-- Star Fix 3: Originally 3 lines executed directly, now changed to delayed + step-by-step execution
--   · Run only after modules finish loading
--   · Set the background wall only after the scene finishes loading
-- ============================================================
local function _zeroKaliBoot()
    -- Step 1: Load collection lobby scene
    pcall(_G.LoadCollectionHallScene)

    -- Step 2: Unlock all platforms
    pcall(_G.UnlockAllCollectionPlatforms)

    -- Step 3: Delay 1.5 sec then set background wall (wait for scene load)
    local function applyBgWall()
        pcall(function()
            _G.SetBehindPlayerBackground(SOCIAL_HALL_CONFIG.DEFAULT_BG_WALL)
        end)
    end

    if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
        _G.Mytimer_ticker.AddTimer(1.5, applyBgWall)
    else
        local ok, tk = pcall(require, "common.time_ticker")
        if ok and tk and tk.AddTimer then
            tk.AddTimer(1.5, applyBgWall)
        else
            applyBgWall()   -- If really no timer, execute directly
        end
    end
end

-- The Collection Hall scene / unlock override is never launched at startup.
-- Only the Profile & Stats switch can request the local preview.
_G.FORMULA_ApplyCollectionUnlock = function(enabled)
    if not enabled then return true end
    if not _G.__ZERO_KALI_SOCIAL_HALL_LOADED then
        _G.__ZERO_KALI_SOCIAL_HALL_LOADED = true
        if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
            _G.Mytimer_ticker.AddTimer(2.0, function()
                if _G.FormulaFeatureEnabled("collectionUnlock") then pcall(_zeroKaliBoot) end
            end)
        else
            local ok, tk = pcall(require, "common.time_ticker")
            if ok and tk and tk.AddTimer then
                tk.AddTimer(2.0, function()
                    if _G.FormulaFeatureEnabled("collectionUnlock") then pcall(_zeroKaliBoot) end
                end)
            else
                pcall(_zeroKaliBoot)
            end
        end
    else
        pcall(_G.UnlockAllCollectionPlatforms)
    end
    return true
end



-- ============================================================
-- v27: All titles unlocked + Local switch + UI real-time refresh (Pure function version)
-- ============================================================
do
    local function getObbDir()
        if _G.GetCurrentWumingPath then
            local wp = _G.GetCurrentWumingPath()
            if wp then return wp:match("^(.*)/[^/]+$") end
        end
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/obb/" .. pkg
    end

    local OBB_DIR   = getObbDir()
    local TITLE_INI = OBB_DIR .. "/BeysaTitle.ini"

    local unpackFn = unpack or (table and table.unpack)
    local T = { use = 0 }
    _G.BeysaTitle = T

    local function saveT()
        pcall(function()
            local f = io.open(TITLE_INI, "w")
            if not f then return end
            f:write("[Title]\nUSE=" .. tostring(T.use) .. "\n")
            f:close()
        end)
    end

    pcall(function()
        local f = io.open(TITLE_INI, "r")
        if not f then return end
        local txt = f:read("*a"); f:close()
        T.use = tonumber(txt:match("USE%s*=%s*(%d+)")) or 0
    end)

    local function packArgs(...)
        return { n = select("#", ...), ... }
    end

    local function post(evType, evId, a1)
        pcall(function()
            if EventSystem and _G[evType] and _G[evId] then
                EventSystem:postEvent(_G[evType], _G[evId], a1)
            end
        end)
    end

    local function findTitleModule()
        local paths = {
            "client.slua.logic.roleInfo.logic_roleinfo_title",
            "client.slua.logic.roleinfo.logic_roleinfo_title",
            "client.logic.roleinfo.logic_roleinfo_title",
        }
        for _, p in ipairs(paths) do
            local ok, m = pcall(require, p)
            if ok and type(m) == "table" then return m end
        end
        return nil
    end

    -- Unlock all entries with state=0 in list + Apply local "In Use"
    local function unlockList(list)
        if type(list) ~= "table" then return 0 end
        local unlocked = 0
        for k, v in pairs(list) do
            if type(v) == "table" then
                if v.id == nil then v.id = tonumber(k) end
                if v.expire_ts == nil then v.expire_ts = 0 end
                if v.rank == nil then v.rank = 0 end
                if v.rank_id == nil then v.rank_id = 0 end
                if v.nation == nil then v.nation = "" end
                if v.receive_time == nil then v.receive_time = os.time() end
                if v.have_used == nil then v.have_used = 1 end
                if (tonumber(v.state) or 0) == 0 then
                    v.state = 1
                    unlocked = unlocked + 1
                end
            end
        end
        if T.use ~= 0 then
            for k, v in pairs(list) do
                if type(v) == "table"
                   and tonumber(v.state) == 2
                   and tonumber(k) ~= T.use then
                    v.state = 1
                end
            end
            local e = list[T.use] or list[tostring(T.use)]
            if e then e.state = 2 end
        end
        return unlocked
    end

    -- Sync alias_list_info to aliasInfo (UI reads this)
    local function syncAliasInfo(S)
        if type(S.alias_list_info) ~= "table" then return 0 end
        if type(S.aliasInfo) ~= "table" then S.aliasInfo = {} end
        local cnt = 0
        for k, v in pairs(S.alias_list_info) do
            S.aliasInfo[k] = v
            cnt = cnt + 1
        end
        return cnt
    end

    -- Immediately refresh UI after switching
    local function refreshUI(S)
        syncAliasInfo(S)
        if type(S.refreshAliasList) == "function" then
            pcall(S.refreshAliasList, S)
        end
        if type(S.initAliasInfo) == "function" then
            pcall(S.initAliasInfo, S)
        end
    end

    local function hookAll()
        local S = findTitleModule()
        if not S then return false end
        if S._BeysaV27 then return true end
        if type(S.alias_list_res) ~= "function" then return false end
        S._BeysaV27 = true

        local orig = S.alias_list_res
        S.alias_list_res = function(...)
            local args = packArgs(...)
            local n = args.n
            local hasSelf = (n >= 4 and type(args[1]) == "table"
                            and type(args[2]) == "number"
                            and type(args[3]) == "table")
            local list = hasSelf and args[3] or args[2]

            if type(list) ~= "table" then
                return orig(unpackFn(args, 1, n))
            end

            unlockList(list)

            local ok = pcall(orig, unpackFn(args, 1, n))
            if ok then
                syncAliasInfo(S)
                return
            end
            return orig(unpackFn(args, 1, n))
        end

        -- Switch title
        local origReq = S.change_alias_req
        if type(origReq) == "function" then
            S.change_alias_req = function(...)
                local a = { ... }
                local n = select("#", ...)
                local selfObj, id, state
                if n >= 3 and type(a[1]) == "table" then
                    selfObj, id, state = a[1], a[2], a[3]
                else
                    selfObj, id, state = nil, a[1], a[2]
                end

                local nid = tonumber(id)
                local list = S.alias_list_info
                local cur = type(list) == "table" and nid and (list[id] or list[nid])
                if cur then
                    if cur.state == 2 then
                        T.use = 0
                        cur.state = 1
                    else
                        T.use = nid
                    end
                    saveT()
                    pcall(unlockList, list)
                    pcall(refreshUI, S)

                    S.newCheckId = nid
                    post("EVENTTYPE_LOBBY_SOCIAL", "EVENTID_LOBBY_SOCIAL_ALIAS_LIST")
                    post("EVENTTYPE_LOBBY_SOCIAL", "EVENTID_LOBBY_SOCIAL_GOT_ALIAS_DATA")
                    pcall(function() if ShowNotice then ShowNotice(49951) end end)
                    return
                end
                if selfObj then
                    return origReq(selfObj, id, state)
                else
                    return origReq(id, state)
                end
            end
        end

        pcall(function()
            if S.get_alias_list then
                S.get_alias_list()
            end
        end)

        return true
    end

    local ok, res = pcall(hookAll)
    if not ok or not res then
        for _, sec in ipairs({ 3.0, 8.0, 20.0, 40.0 }) do
            if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
                _G.Mytimer_ticker.AddTimer(sec, function() pcall(hookAll) end)
            end
        end
    end
end


-- ============================================================
-- BEYSA RP Module (V18.1 Fixed Version)
-- Feature: Lobby RP shows as purchased Elite + claim all rewards
-- Where to place: In main file, the line `_G.SkinConfigPath = "...SkinMenu.ini"`
--          Directly above (after v10 profile module, after wallet module)
-- Required dependencies: ITEMS, F, _G.BeysaWallet (already in V16)
-- Note: V18 file already has RP module, do not add duplicate on V18;
--       This module was added in V16.
-- Will not send any data to server. Items will be written to ITEMS list in BeysaWallet.ini.
-- Log: Android/data/<package name>/files/BeysaRP.log
-- Place inside do ... end, avoid occupying 200 local slots in main file
-- Author: PatronPubgBeysa  Creator: Neysa
-- ============================================================
do
    -- ============ Basic Config ============
    local RP_LEVEL = 100
    local AWARD_MODS = {                          -- Star Fix: Multi-path fallback
        "client.slua.logic.unknow_pass.logic_unknowpass_award",
        "client.slua.logic.unknown_pass.logic_unknownpass_award",
        "client.slua.logic.unknownpass.logic_unknownpass_award",
        "client.logic.unknow_pass.logic_unknowpass_award",
    }

    -- Star Fix: Locate log path by package name
    local function getRpLog()
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/data/" .. pkg .. "/files/BeysaRP.log"
    end
    local RP_LOG = getRpLog()

    local R = { hooked = false, needParse = true, claimedAll = false, logN = 0 }
    _G.BeysaRP = R

    -- ============ Log (Max 100 Lines) ============
    local function rlog(msg)
        if R.logN > 100 then return end
        R.logN = R.logN + 1
        pcall(function()
            local f = io.open(RP_LOG, "a")
            if f then
                f:write(os.date("%H:%M:%S") .. " " .. tostring(msg) .. "\n")
                f:close()
            end
        end)
    end

    -- ============ Check if ITEMS Already Contains This Item ============
    -- Star Fix: When ITEMS is nil return true (treat as "already have", avoid crash and duplicate add)
    local function hasItem(id)
        if type(ITEMS) ~= "table" then return true end
        for _, v in ipairs(ITEMS) do
            if tonumber(v) == id then return true end
        end
        return false
    end

    -- ============ Grant Items (Write to ITEMS + BeysaWallet) ============
    local function giveItems(ids)
        local W = _G.BeysaWallet
        if not W then return 0 end
        if type(ITEMS) ~= "table" then return 0 end
        local added = 0
        for _, id in ipairs(ids) do
            id = tonumber(id)
            if id and id >= 100000 and not hasItem(id) then
                ITEMS[#ITEMS + 1] = id
                if type(W.items) == "table" then
                    W.items[#W.items + 1] = id
                end
                added = added + 1
            end
        end
        if added > 0 then
            pcall(W.save)
            if _G.F then
                pcall(F.injectAll)
                pcall(F.scheduleInjectRefresh)
            end
        end
        return added
    end

    -- ============ Get Reward Module (Multi-Path Fallback) ============
    local function getAward()
        for _, path in ipairs(AWARD_MODS) do
            local ok, A = pcall(require, path)
            if ok and type(A) == "table" then
                return A, path
            end
        end
        return nil, nil
    end

    -- ============ Collect Reward IDs from a Level Info ============
    -- isElite: true=Elite, false=Normal, nil=Collect Both
    -- groupId: Specify group ID, nil/0=Unlimited
    local function collect(info, isElite, groupId, out)
        if type(info) ~= "table" then return end
        local lists
        if isElite == nil then
            lists = { info.OrdinaryAwardList, info.EliteAwardList }
        elseif isElite then
            lists = { info.EliteAwardList }
        else
            lists = { info.OrdinaryAwardList }
        end
        for _, lst in ipairs(lists) do
            if type(lst) == "table" then
                for _, it in pairs(lst) do
                    if type(it) == "table" then
                        -- Star Fix: Field name multi-path fallback
                        local rid = it.resId or it.resid or it.res_id
                        if rid then
                            local okGroup = (groupId == nil or groupId == 0)
                                          or (it.groupId == nil)
                                          or (it.groupId == groupId)
                            if okGroup then
                                out[#out + 1] = rid
                            end
                        end
                    end
                end
            end
        end
    end

    -- ============ Convert ID List to Reward List Structure Required by Protocol ============
    local function toRewardList(ids)
        local rl = {}
        for _, id in ipairs(ids) do
            -- Also provide resid / res_id / resId / count / num / number,
            -- Different versions read different field names, writing all will hit
            rl[#rl + 1] = {
                resid = id, res_id = id, resId = id,
                count = 1, num = 1, number = 1,
            }
        end
        return rl
    end

    -- ============ Call on_xxx_rsp (Compatible with Method / Static) ============
    -- Star Fix: Parameter misalignment
    local function callRsp(UH, name, ...)
        local fn = UH[name]
        if type(fn) ~= "function" then return false end
        local args = { n = select("#", ...), ... }
        -- Try method first
        local ok1 = pcall(fn, UH, table.unpack and table.unpack(args, 1, args.n)
                                       or unpack(args, 1, args.n))
        if ok1 then return true end
        -- Try static again
        local ok2 = pcall(fn, table.unpack and table.unpack(args, 1, args.n)
                             or unpack(args, 1, args.n))
        return ok2
    end

    -- ============ Claim All Rewards ============
    function R.claimAll()
        local A = getAward()
        local list = A and A.AwardLevelList
        if type(list) ~= "table" then return false end
        local ids = {}
        for _, info in ipairs(list) do
            collect(info, nil, nil, ids)
        end
        local n = giveItems(ids)
        rlog("All rewards: Total=" .. #ids .. " New=" .. n)
        R.claimedAll = true
        return true
    end

    -- ============ Apply RP Status ============
    function R.apply()
        local S = rawget(_G, "UnknowPassSystem")
        if type(S) ~= "table" then return end

        -- Star Fix: Clear needParse when level changes
        if S.IsBuyElite ~= true or S.Level ~= RP_LEVEL then
            R.needParse = true
        end
        S.IsBuyElite    = true
        S.IsBuyEliteSeg2 = true
        S.PassType      = 2
        S.Level         = RP_LEVEL
        if type(S.Data) == "table" and type(S.Data.base) == "table" then
            S.Data.base.cur_value = RP_LEVEL
        end

        -- First parse reward data
        if R.needParse and type(S.Data) == "table" and S.Data.base then
            local A = getAward()
            if A and A.GetAwardLevelList then
                -- Star Fix: Try method first then static
                local ok, e = pcall(A.GetAwardLevelList, A, true)
                if not ok then
                    ok, e = pcall(A.GetAwardLevelList, true)
                end
                if ok then
                    R.needParse = false
                else
                    rlog("Parse failed: " .. tostring(e))
                end
            end
        end

        if not R.claimedAll then
            R.claimAll()
        end
    end

    -- ============ Install Hook ============
    function R.installHook()
        if R.hooked then return end
        local ok, UH = pcall(require, "client.network.Protocol.UpassHandle")
        if not ok or type(UH) ~= "table"
           or type(UH.send_upass_get_level_award_req) ~= "function" then
            return
        end
        R.hooked = true

        -- ---- Hook single claim ----
        local origOne = UH.send_upass_get_level_award_req
        UH.send_upass_get_level_award_req = function(level, is_elite_task, group_id, is_elite_plus, ...)
            local A = getAward()
            local info = A and A.AwardLevelList and A.AwardLevelList[level]
            if not info then
                rlog("Claim: No level info level=" .. tostring(level) .. " -> Use game original logic")
                return origOne(level, is_elite_task, group_id, is_elite_plus, ...)
            end

            -- Star Fix: Collect by group first
            local ids = {}
            collect(info, is_elite_task and true or false, group_id, ids)

            -- Star Fix: When elite+, no second collection (avoid duplicates)
            -- If group_id is nil/0 and is elite+, collect all elite rewards at once
            if is_elite_task and is_elite_plus and (group_id == nil or group_id == 0) then
                ids = {}
                collect(info, true, nil, ids)
            end

            giveItems(ids)
            rlog("Claim level=" .. tostring(level) .. " ids=" .. tostring(table.concat(ids, ",")))
            callRsp(UH, "on_upass_get_level_award_rsp",
                    0, level, is_elite_task, toRewardList(ids),
                    group_id, {}, is_elite_plus)
        end

        -- ---- Hook batch claim ----
        if type(UH.send_upass_batch_get_level_award_req) == "function" then
            local origBatch = UH.send_upass_batch_get_level_award_req
            UH.send_upass_batch_get_level_award_req = function(selects, ...)
                local A = getAward()
                local list = A and A.AwardLevelList
                if type(list) ~= "table" then
                    rlog("Batch claim: No list -> Use game original logic")
                    return origBatch(selects, ...)
                end
                local ids = {}
                for _, info in ipairs(list) do
                    collect(info, nil, nil, ids)
                end
                giveItems(ids)
                rlog("Batch claim item count=" .. #ids)
                callRsp(UH, "on_upass_batch_get_level_award_rsp",
                        0, toRewardList(ids), {})
            end
        end
    end

    -- ============ Main tick ============
    function R.tick()
        if not R.hooked then pcall(R.installHook) end
        local ok, e = pcall(R.apply)
        if not ok then rlog("apply error: " .. tostring(e)) end
    end

    -- ============ Mount to BeysaWalletTick (Prevent Duplicate Wrapping) ============
    -- Star Fix: Most serious bug -- Every execution wraps old tick one more layer,
    --   After multiple loads (hot update, multiple file references), tick nesting gets deeper and deeper, eventually freezing the main thread.
    --   Use an independent flag to avoid duplicate wrapping.
    if not _G.__BeysaRPTickInstalled then
        _G.__BeysaRPTickInstalled = true
        local oldTick = _G.BeysaWalletTick
        _G.BeysaWalletTick = function(...)
            if oldTick then pcall(oldTick, ...) end
            pcall(R.tick)
        end
    else
        -- Already installed, this time only update R reference
        if _G.BeysaRP and _G.BeysaRP.tick then
            -- Do nothing, old tick already calls BeysaRP.tick
        end
    end
end


-- ============================================================
-- LuckybackHandler Final Version
-- Feature:
--   1. Single draw: Draw from the real prize pool by weight (just click the in-game button)
--   2. Draw again: Works normally
--   3. Ten-draw: Call _G.DoLuckyTenDraw() manually
-- Log: /storage/emulated/0/Android/obb/<package name>/BeysaLuckyback.log
-- ============================================================
local function InitLuckybackFinal()
    -- ============ obb Log ============
    local function getObbDir()
        if _G.GetCurrentWumingPath then
            local wp = _G.GetCurrentWumingPath()
            if wp then return wp:match("^(.*)/[^/]+$") end
        end
        local pkg = (_G.GetCurrentGamePackage and _G.GetCurrentGamePackage())
                    or "com.tencent.ig"
        return "/storage/emulated/0/Android/obb/" .. pkg
    end
    local LOG_PATH = getObbDir() .. "/BeysaLuckyback.log"

    local function LOG(msg)
        pcall(function()
            local f = io.open(LOG_PATH, "a+")
            if f then
                f:write(os.date("[%H:%M:%S] ") .. tostring(msg) .. "\n")
                f:close()
            end
        end)
        pcall(function() print("[Luckyback] " .. tostring(msg)) end)
    end

    LOG("")
    LOG("========== Luckyback Final Version " ..
        os.date("%Y-%m-%d %H:%M:%S") .. " ==========")

    -- ============ Load Module ============
    local ok, LB = pcall(require, "client.network.Protocol.LuckybackHandler")
    if not ok or type(LB) ~= "table" then
        LOG("❌ LuckybackHandler load failed")
        return
    end

    -- ============ Parameter Parsing (Compatible with / without self) ============
    local function parseArgs(...)
        local args = { n = select("#", ...), ... }
        if args.n >= 1 and type(args[1]) == "table" and args[1] == LB then
            return true, args
        end
        return false, args
    end

    -- ============ Activity Cache ============
    local activityCache = {}
    local function cacheActivity(activityId, data)
        activityId = tonumber(activityId)
        if not activityId or activityId <= 0 then return end
        if type(data) ~= "table" then return end
        activityCache[activityId] = data
        local cnt = 0
        if type(data.item_table) == "table" then
            for _ in pairs(data.item_table) do cnt = cnt + 1 end
        end
        LOG("✅ Cached activity " .. activityId .. ", prize pool " .. cnt .. " ")
    end

    -- ============ Draw by Weight ============
    local function pickByWeight(itemTable, count, useUnique)
        local items = {}
        local totalWeight = 0
        for _, v in pairs(itemTable or {}) do
            if type(v) == "table" then
                local id = tonumber(v.award_item_id)
                local w  = tonumber(v.award_weight) or 0
                if id and id > 0 and w > 0 then
                    items[#items + 1] = {
                        id    = id,
                        num   = tonumber(v.award_item_num) or 1,
                        weight = w,
                    }
                    totalWeight = totalWeight + w
                end
            end
        end
        if #items == 0 or totalWeight <= 0 then
            LOG("  ⚠ Prize pool invalid")
            return {}
        end

        local result = {}
        if useUnique then
            -- Shuffle and take first count (ten-draw no duplicates)
            for i = #items, 2, -1 do
                local j = math.random(i)
                items[i], items[j] = items[j], items[i]
            end
            for i = 1, math.min(count, #items) do
                result[#result + 1] = items[i]
            end
        else
            -- Random by weight (single draw)
            for i = 1, count do
                local r = math.random() * totalWeight
                local acc = 0
                for _, item in ipairs(items) do
                    acc = acc + item.weight
                    if r <= acc then
                        result[#result + 1] = item
                        break
                    end
                end
            end
        end

        local ids = {}
        for _, item in ipairs(result) do
            ids[#ids + 1] = tostring(item.id) .. "x" .. tostring(item.num)
        end
        LOG("  Drew: " .. table.concat(ids, ","))
        return result
    end

    -- ============ Build Reward List ============
    local function toRewards(picked)
        local rl = {}
        for i, item in ipairs(picked) do
            rl[i] = {
                resid = item.id, res_id = item.id, count = item.num or 1,
                valid_hours = 0, is_luck = (i == 1), order = i,
                drop_fun = 0, must_reward = (i == 1) and 1 or 0,
                to_res_id = 0, to_res_cnt = 0,
            }
        end
        return rl
    end

    -- ============ Add to Warehouse ============
    local function addToInventory(picked)
        pcall(function()
            local wd = require("client.slua.logic.wardrobe.wardrobe_data")
            local center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            local de = center.GetWardrobeData()
            if not de then return end
            local changes = {}
            for _, item in ipairs(picked) do
                if not de:GetDataByResID(item.id, false) then
                    local instid = tonumber(os.time()) * 1000 + math.random(1, 999)
                    changes[instid] = {
                        instid = instid, res_id = item.id, count = item.num or 1,
                        isnew = 1, valid_hours = 0, expire_ts = 0,
                        lock_cnt = 0, source = 0,
                    }
                end
            end
            if next(changes) then wd:OnHallDepotDataNotify(changes) end
        end)
    end

    -- ============ Show Reward Panel ============
    local function showPanel(picked, isTen)
        pcall(function()
            local rl = toRewards(picked)
            local cfg = UIManager and UIManager.UI_Config
                        and UIManager.UI_Config.new_supply_get_panel
            if not cfg then return end
            if UIManager.IsUIShow and UIManager.IsUIShow(cfg) then
                local ui = UIManager.GetUI(cfg)
                if ui and ui.TryShowSupplyGetPanel then
                    ui:TryShowSupplyGetPanel(rl, isTen, {needShowMovie = true})
                end
            else
                UIManager.ShowUI(cfg, rl, isTen, {needShowMovie = true})
            end
        end)
    end

    -- ============ Hook Activity Data Response (Cache Prize Pool) ============
    if type(LB.on_get_lucky_draw_back_activity_rsp) == "function"
       and not LB.__final_cache then
        LB.__final_cache = true
        local orig = LB.on_get_lucky_draw_back_activity_rsp
        LB.__orig_rsp = orig

        LB.on_get_lucky_draw_back_activity_rsp = function(...)
            local hasSelf, args = parseArgs(...)
            local errCode, activityData, playerState
            if hasSelf then
                errCode      = args[2]
                activityData = args[3]
                playerState  = args[4]
            else
                errCode      = args[1]
                activityData = args[2]
                playerState  = args[3]
            end

            if errCode == 0 and type(playerState) == "table" then
                local aid = tonumber(playerState.activity_id)
                if aid then cacheActivity(aid, activityData) end
            end
            return orig(...)
        end
        LOG("✅ hook activity data response")
    end

    -- ============ Hook Single Draw (Draw from Real Prize Pool + Call rsp) ============
    if type(LB.send_do_one_draw_back_by_activity_req) == "function"
       and not LB.__final_draw then
        LB.__final_draw = true
        local orig = LB.send_do_one_draw_back_by_activity_req
        LB.__orig_draw = orig

        LB.send_do_one_draw_back_by_activity_req = function(...)
            local hasSelf, args = parseArgs(...)
            local activityId, drawParam
            if hasSelf then
                activityId = args[2]; drawParam = args[3]
            else
                activityId = args[1]; drawParam = args[2]
            end

            LOG("★ Single draw: activityId=" .. tostring(activityId) ..
                " param=" .. tostring(drawParam))

            local cache = activityCache[tonumber(activityId) or 0]
            if not cache or type(cache.item_table) ~= "table" then
                LOG("  ⚠ No cache -> Use original logic")
                return orig(...)
            end

            local picked = pickByWeight(cache.item_table, 1, false)
            if #picked == 0 then return orig(...) end

            addToInventory(picked)
            showPanel(picked, false)

            -- Call rsp to make "Draw Again" button usable
            local rspFn = LB.on_do_one_draw_back_by_activity_rsp
            if type(rspFn) == "function" then
                local rewards = toRewards(picked)
                local okR = pcall(rspFn, LB, 0, activityId, rewards, drawParam)
                if okR then
                    LOG("  ✅ rsp callback succeeded")
                end
            end

            LOG("  ✅ Single draw complete")
            return
        end
        LOG("✅ hook single draw")
    end

    -- ============ Global Function: Manual Ten-Draw ============
    _G.DoLuckyTenDraw = function(activityId)
        activityId = tonumber(activityId)
        if not activityId or activityId <= 0 then
            -- Auto-select first cached activity
            for aid in pairs(activityCache) do
                activityId = aid
                break
            end
        end
        if not activityId then
            LOG("⚠ DoLuckyTenDraw: No cached activity, please open draw UI once first")
            return false
        end

        LOG("★★ Ten-draw: activityId=" .. activityId)
        local cache = activityCache[activityId]
        if not cache or type(cache.item_table) ~= "table" then
            LOG("  ⚠ No cached prize pool")
            return false
        end

        local picked = pickByWeight(cache.item_table, 10, true)
        if #picked == 0 then return false end

        addToInventory(picked)
        showPanel(picked, true)

        -- Call rsp to update UI state
        local rspFn = LB.on_do_one_draw_back_by_activity_rsp
        if type(rspFn) == "function" then
            pcall(rspFn, LB, 0, activityId, toRewards(picked), 10)
        end

        LOG("  ✅ Ten-draw complete (" .. #picked .. " items)")
        return true
    end

    LOG("========== Load Complete ==========")
    LOG("[Usage] Single draw: Click game single-draw button")
    LOG("[Usage] Ten-draw: Call _G.DoLuckyTenDraw()")
end


pcall(InitLuckybackFinal)

pcall(function()
    math.randomseed(os.time() + math.floor(math.clock and math.clock() * 100000 or 0))
end)


-- ============================================================
-- ProfileBeautify - Personal Homepage Beautify (Old Implementation)
-- Requires FeatureSwitch config items: PROFILE_BG, PROFILE_CARD, CI_GOLD_NAME
-- ============================================================
_G.ProfileBeautify = _G.ProfileBeautify or {}
do
    -- The following IDs can be directly changed to desired resource ID
    local SELF_BG_ID    = 61510029   -- Personal homepage background
    local SELF_CARTE_ID = 61100155   -- Social namecard frame
    local GOLD_PLAN_ID  = 61910003   -- Golden nickname (configured ID)
    local AVATAR_FRAME_ID = 2002000  -- Avatar frame
    local AVATAR_ID       = 30397        -- Avatar (0=Do not replace)

    local SWAP_LIST = {
        [61510000] = 61510001,61510002,61510003,61510004,61510005,61510006,61510007,61510008,61510009,61510010,61510011,61510012,61510013,61510014,61510015,61510016,61510017,61510018,61510019,61510020,61510021,61510022,61510023,61510024,61510025,61510026,61510027,
        [61100001] = 61100002,61100003,61100004,61100005,61100006,61100007,61100008,61100009,61100010,61100011,61100012,61100013,61100014,61100015,61100016,61100017,61100018,61100019,61100020,61100021,61100022,61100023,61100024,61100025,61100026,61100027,61100028,61100029,61100030,61100031,61100032,61100033,61100034,61100035,61100036,61100037,61100038,61100039,61100040,61100041,61100042,61100043,61100044,61100045,61100046,61100047,61100048,61100049,61100050,61100051,61100052,61100053,61100054,61100055,61100056,61100057,61100058,61100059,61100060,61100061,61100062,61100063,61100064,61100065,61100066,61100067,61100068,61100069,61100070,61100071,61100072,61100073,61100074,61100075,61100076,61100077,61100078,61100079,61100080,61100081,61100082,61100083,61100084,61100085,61100086,61100087,61100088,61100089,61100090,61100091,61100092,61100093,61100094,61100095,61100096,61100097,61100098,61100099,61100100,61100101,61100102,61100103,61100104,61100105,61100106,61100107,61100108,61100109,61100110,61100111,61100112,61100113,61100114,61100115,61100116,61100117,61100118,61100119,61100120,61100121,61100122,61100123,61100124,61100125,61100126,61100127,61100128,61100129,61100130,61100131,61100132,61100134,61100135,61100136,61100137,61100138,61100139,61100140,61100141,61100142,61100143,61100144,61100145,61100146,61100147,61100148,61100149,61100150,61100151,61100174,61100175,61100176,
        [61300001] = 61300002,61300003,61300004,61300005,61300006,61300007,61300008,61300009,61300010,61300011,61300012,61300013,61300014,61300015,61300016,61300017,61300018,61300019,61300020,61300021,61300022,61300023,61300024,61300025,61300026,61300027,61300028,61300029,61300030,61300031,61300032,61300033,61300034,61300035,61300037,61300038,61300039,61300040,61300041,61300042,61300043,61300044,61300045,61300046,61300047,61300048,61300049,61300050,61300052,61300053,61300054,61300055,61300056,61300058,61300059,61300060,61300061,61300062,61300063,61300064,61300065,61300066,61300067,61300068,61300070,61300071,61300072,61300073,61300074,61300075,61300076,61300077,61300078,61300079,61300080,61300081,61300082,61300110,
        [61910002] = 10925004,61300002,61300003,61300004,61300005,61300006,61300007,61300008,61300009,61300010,61300011,61300012,61300013,61300014,61300015,61300016,61300017,61300018,61300019,61300020,61300021,61300022,61300023,61300024,61300025,61300026,61300027,61300028,61300029,61300030,61300031,61300032,61300033,61300034,61300035,61300037,61300038,61300039,61300040,61300041,61300042,61300043,61300044,61300045,61300046,61300047,61300048,61300049,61300050,61300052,61300053,61300054,61300055,61300056,61300058,61300059,61300060,61300061,61300062,61300063,61300064,61300065,61300066,61300067,61300068,61300070,61300071,61300072,61300073,61300074,61300075,61300076,61300077,61300078,61300079,61300080,61300081,61300082,61300110,61910001,61910002,61910003,61910004,62510001,62510002,62510003,
		[41020001] = 41020002,41020003,41020004,41020005,41020006,41020007,41020008,41020009,
		[41030001] = 41030002,41030003,41030004,41030005,41030006,41030007,41030008,41030009,
		[22200001] = 22200002,22200003,22200004,22200005,22200006,22200007,
		[202408133] = 202408001,202408014,202408035,202408037,202408039,202408040,202408042,202408043,202408045,202408046,202408048,202408049,202408051,202408053,202408054,202408055,202408056,202408057,202408058,202408059,202408060,202408062,202408063,202408065,202408066,202408067,202408068,202408069,202408071,202408072,202408073,202408074,202408075,202408076,202408077,202408078,202408079,202408080,202408081,202408082,202408083,202408084,202408085,202408086,202408088,202408089,202408090,202408091,202408092,202408093,202408094,202408095,202408096,202408097,202408098,202408099,202408100,202408101,202408102,202408103,202408104,202408105,202408106,202408107,202408108,202408109,202408110,202408111,202408112,202408113,202408114,202408115,202408116,202408117,202408118,202408119,202408120,202408121,202408122,202408123,202408124,202408125,202408126,202408127,202408128,202408129,202408130,202408131,202408132,
		[62110001] = 62110002,62110003,62110004,62110005,62110006,62110007,62110008,62110009,62110010,62110011,62110012,62110013,62110014,62110015,62110016,62110017,62110018,62110019,62110020,62110021,62110022,62110023,62110024,62110025,62110026,62110027,62110028,62110029,62110030,62110031,62110032,62110033,62110034,62110035,62110036,
		[61820001]  = 61820001,61820002,61820003,
		[6680200]  = 6680201,
		[61510000]  = 61510001,61510002,61510003,61510004,61510005,61510006,61510007,61510008,61510009,61510010,61510011,61510012,61510013,61510014,61510015,61510016,61510017,61510018,61510019,61510020,61510021,61510022,61510023,61510024,61510025,61510026,61510027,
		[61600001]  = 61600002,61600003,61600004,61600005,61600006,61600007,61600008,61600009,
		[61820001]  = 61820002,61820003,
		[6680200]  = 6680201,
		[62110002]  = 62110003,62110004,62110005,62110006,62110007,62110008,62110009,62110010,62110011,62110012,62110013,62110014,62110015,62110016,62110017,62110018,62110019,62110020,62110021,62110022,62110023,62110024,62110025,62110026,62110027,62110028,62110029,62110030,62110031,62110032,62110033,62110034,62110035,62110036,62110101,62110102,62110103,62110104,62110105,62110106,62110107,62110108,62110109,62110110,62110111,62110112,62110113,62120101,
		[62410001]  = 62410002,62410003,62410004,62410005,
		[61200001]  = 61200002,61200003,61200004,61200005,61200006,61200007,61200008,61200009,61200010,61200011,61200012,61200013,61200014,61200015,61200016,61200017,61200018,61200019,61200020,61200021,61200022,61200023,61200024,61200025,61200026,61200027,61200028,61200029,61200030,61200031,61200032,61200033,61200034,61200035,61200036,61200037,61200038,61200039,61200040,61200041,61200042,61200043,61200044,61200045,61200046,61200047,61200048,61200049,61200050,61200051,61200052,61200053,61200054,61200055,61200056,61200057,61200058,61200059,61200060,61200061,61200062,61200063,61200064,61200065,61200066,61200067,61200068,61200069,61200070,61200071,61200072,61200073,61200074,61200075,61200076,61200077,61200078,61200079,61200080,61200081,61200082,61200083,61200084,61200085,61200086,61200087,61200088,61200089,61200090,61200091,61200092,61200093,61200094,61200095,61200096,61200097,61200098,61200099,61200100,61200101,61200102,61200103,61200104,61200105,61200106,61200108,61200109,61200110,61200111,61200112,61200113,61200114,61200115,61200116,61200117,61200118,61200119,61200120,61200121,61200122,61200123,61200124,61200125,61200126,61200127,61200128,61200129,61200130,61200131,61200132,61200133,61200134,61200135,61200136,61200137,61200138,61200139,61200140,61200141,61200142,61200143,61200144,61200145,61200146,61200147,61200148,61200149,61200183,
		[40003]  = 40006,40009,40012,40015,40018,40021,40024,40027,40030,40033,40036,40039,40042,40045,40048,40051,60002,60004,60006,60008,60010,60012,60014,60016,60018,60020,60022,60024,60026,60028,60030,60032,60034,60036,60038,60040,60042,60045,60047,60049,60051,60053,60055,60057,60059,60061,60063,60065,60067,60069,60071,60073,60075,60077,60079,211001,211002,211003,211004,211005,211006,211007,211008,211009,211010,211011,211012,211013,211014,211015,211016,211017,211018,211019,211020,211021,211022,211023,211024,211025,211026,211027,211028,211029,211030,211031,211032,211033,211034,211035,211036,211037,211038,211039,211040,211041,211042,211043,211044,211045,211046,211047,211048,211049,211050,211051,211052,211053,211054,211055,211056,211057,211058,211059,211060,211061,211062,211063,211064,211065,211066,211067,211068,211069,211070,211071,211072,211073,211074,211075,211076,211077,211078,211079,211080,211081,211082,211083,211084,211085,211086,211187,211188,211189,211190,211191,211192,211193,211194,211195,211196,211197,211198,211199,211200,211201,211202,211203,211204,211205,211206,211207,211208,211209,211210,211211,211212,211213,211214,211215,211216,211217,211218,211219,211220,211221,211222,211223,211224,211225,211226,211227,211228,211229,211230,211231,211232,211233,211234,211235,211236,211237,211238,211239,211240,211241,211242,211243,211244,211245,211246,211247,211248,211249,211250,211251,211252,211253,211254,211255,211256,211257,211258,211259,211260,211261,211262,211263,211264,211265,211266,211267,211268,211269,211270,211271,211272,211273,211274,211275,211276,211277,211278,211279,211292,211293,211294,211295,211296,212001,212002,212003,212004,212005,212016,212017,212030,212031,212032,212033,212034,212035,212036,212037,212038,212039,212040,212060,212061,221292,221293,221294,221295,221296,221392,221393,221394,221395,221396,221492,221493,221494,221495,221496,221497,221592,221593,221594,221595,221596,1534128,2020001,2020002,2020003,2020004,2020005,	
    }

    local function isSelfUid(uid)
        local l = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
        return l and tostring(uid) == tostring(l)
    end

    local function getTicker()
        return _G.Mytimer_ticker or _G.timer_ticker
    end

    -- 1) Resource ID replacement table
    do
        local installed = false
        local function install()
            if installed then return true end
            if type(CDataTable) ~= "table" or type(CDataTable.GetTableData) ~= "function" then return false end
            local orig = CDataTable.GetTableData
            CDataTable.GetTableData = function(tblName, id, ...)
                if not _G.FormulaFeatureEnabled("profileCosmetics") then
                    return orig(tblName, id, ...)
                end
                local swapTo = SWAP_LIST[tonumber(id)]
                if swapTo then
                    local ok, cfg = pcall(orig, tblName, swapTo, ...)
                    if ok and cfg then return cfg end
                end
                return orig(tblName, id, ...)
            end
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 2) Homepage background
    do
        local installed = false
        local function install()
            if installed then return true end
            if not (ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig) then return false end
            local ok, m = pcall(ModuleManager.GetModule, ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
            if not ok or type(m) ~= "table" then return false end
            if type(m.GetSelfRoleInfoBGID) == "function" and not m.__bgHooked then
                local origSelfBG = m.GetSelfRoleInfoBGID
                m.GetSelfRoleInfoBGID = function(...)
                    if _G.FormulaFeatureEnabled("profileCosmetics") then return SELF_BG_ID end
                    return origSelfBG(...)
                end
                m.__bgHooked = true
            end
            if type(m.GetPlayerRoleInfoBGID) == "function" and not m.__bgHooked2 then
                local orig = m.GetPlayerRoleInfoBGID
                m.GetPlayerRoleInfoBGID = function(self, uid, ...)
                    if _G.FormulaFeatureEnabled("profileCosmetics") and isSelfUid(uid) then
                        return SELF_BG_ID
                    end
                    return orig(self, uid, ...)
                end
                m.__bgHooked2 = true
            end
            installed = m.__bgHooked == true
            return installed
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 3) Social namecard frame
    do
        local installed = false
        local function install()
            if installed then return true end
            local ok, sc = pcall(require, "client.slua.logic.lobby.Left.logic_social_card")
            if not ok or type(sc) ~= "table" or type(sc.GetCarteFrameEquipIdByProfile) ~= "function" then return false end
            if sc.__carteHooked then installed = true; return true end
            local orig = sc.GetCarteFrameEquipIdByProfile
            sc.GetCarteFrameEquipIdByProfile = function(profile, ...)
                if _G.FormulaFeatureEnabled("profileCosmetics")
                   and profile and type(profile) == "table" and isSelfUid(profile.uid) then
                    return SELF_CARTE_ID
                end
                return orig(profile, ...)
            end
            sc.__carteHooked = true
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 4) Golden nickname
    do
        local installed = false
        local function install()
            if installed then return true end
            if not (ModuleManager and ModuleManager.GetModule and ModuleManager.CommonModuleConfig) then return false end
            local ok, mgr = pcall(ModuleManager.GetModule, ModuleManager.CommonModuleConfig.NicknameColorManager)
            if not ok or type(mgr) ~= "table" or type(mgr.GetUserData) ~= "function" then return false end
            if mgr.__goldNameHooked then installed = true; return true end
            local orig = mgr.GetUserData
            mgr.GetUserData = function(self, UID)
                if _G.FormulaFeatureEnabled("profileCosmetics") and isSelfUid(UID) then
                    return GOLD_PLAN_ID
                end
                return orig(self, UID)
            end
            mgr.__goldNameHooked = true
            installed = true
            return true
        end
        local ticker = getTicker()
        if not install() and ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(3, function()
                if not installed then install() end
            end, 100, 1)
        end
    end

    -- 5) Avatar frame + Avatar
    do
        local function applyAvatar()
            if not _G.FormulaFeatureEnabled("profileAltAvatar") then return end
            if not (DataMgr and DataMgr.roleData) then return end
            local rd = DataMgr.roleData
            local changed = false
            if AVATAR_FRAME_ID > 0 then
                local cur = tonumber(rd.cur_avatar_box_id) or 0
                if cur ~= AVATAR_FRAME_ID then
                    local ok = pcall(function() DataMgr.UpdateAvatarBoxId(AVATAR_FRAME_ID) end)
                    if not ok then pcall(function() rd.cur_avatar_box_id = AVATAR_FRAME_ID end) end
                    changed = true
                end
                pcall(function()
                    local af = require("client.slua.logic.roleInfo.logic_RoleInfoAvatarFrame")
                    if af then
                        af.AvatarFrameList = af.AvatarFrameList or {}
                        af.AvatarFrameList[AVATAR_FRAME_ID] = af.AvatarFrameList[AVATAR_FRAME_ID] or { expire_time = 1 }
                        af.AvatarFrameList[AVATAR_FRAME_ID].expire_time = 1
                        af.HasGet = true
                        af._hasGotData = true
                    end
                end)
            end
            if AVATAR_ID > 0 then
                local want = tostring(AVATAR_ID)
                if tostring(rd.headIconUrl) ~= want then
                    local ok = pcall(function() DataMgr.UpdateHeadIconUrl(want) end)
                    if not ok then pcall(function() rd.headIconUrl = want end) end
                    changed = true
                    pcall(function()
                        local big = require("client.slua.logic.roleInfo.logic_roleInfo_BigAvatar")
                        if big and big.RefreshBigImage then big.RefreshBigImage(want) end
                    end)
                end
                pcall(function()
                    local av = require("client.slua.logic.roleInfo.logic_roleInfo_Avatar")
                    if av then
                        av.HeadportraitList = av.HeadportraitList or {}
                        if av.HeadportraitList[want] == nil then av.HeadportraitList[want] = 1 end
                    end
                end)
            end
            if changed then
                pcall(function()
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_AVATAR_FRAME_INFO)
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_HEAD_INFO, DataMgr.roleData.headIconUrl)
                    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_USE_AVATAR)
                    EventSystem:postEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR)
                    EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_UPDATE_HEAD_ICON)
                end)
            end
        end
        local ticker = getTicker()
        if not (ticker and ticker.AddTimerLoop) then
            pcall(function() ticker = require("common.time_ticker") end)
        end
        if ticker and ticker.AddTimerLoop then
            pcall(applyAvatar)
            ticker.AddTimerLoop(0.5, function()
                local okF, inFight = pcall(function()
                    return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
                end)
                if okF and inFight then return end
                pcall(applyAvatar)
            end, -1, 1)
        end
    end
end


-- ============================================================
-- SocialStatsSpoof -- Personal Social Data Spoof (4 in 1)
--   1. Credit Score   2. Like Count   3. Popularity Value   4. Weapon Power
--
-- Config keys (set via UltimateEngine_Config.Set, effective when value >0):
--   CI_CREDIT_SCORE    Credit Score
--   CI_LIKE_COUNT      Collection page like count
--   CI_POPULARITY      Personal space popularity value
--   CI_WEAPON_POWER    Weapon Power
--
-- Usage:
--   UltimateEngine_Config.Set("CI_CREDIT_SCORE", 1000)
--   UltimateEngine_Config.Set("CI_LIKE_COUNT", 999999)
--   UltimateEngine_Config.Set("CI_POPULARITY", 999999)
--   UltimateEngine_Config.Set("CI_WEAPON_POWER", 99999)
--   SocialStatsSpoof.Apply()
-- ============================================================
_G.SocialStatsSpoof = _G.SocialStatsSpoof or {}
do
    local M = _G.SocialStatsSpoof

    -- ============================================================
    -- Internal tools
    -- ============================================================
    local function GetTicker()
        return _G.Mytimer_ticker or _G.timer_ticker
    end

    -- Read config value (return 0 means not effective)
    local function CfgNum(key, def)
        local featureByKey = {
            CI_CREDIT_SCORE = "creditScore",
            CI_LIKE_COUNT = "collectionLikes",
            CI_POPULARITY = "personalPopularity",
            CI_WEAPON_POWER = "weaponPower",
        }
        local requiredFeature = featureByKey[key]
        if requiredFeature and not _G.FormulaFeatureEnabled(requiredFeature) then
            return 0
        end
        local ok, v = pcall(function()
            if _G.UltimateEngine_Config and _G.UltimateEngine_Config.Get then
                return _G.UltimateEngine_Config.Get(key, def or 0)
            end
        end)
        if ok then return tonumber(v) or (def or 0) end
        return def or 0
    end
    M.CfgNum = CfgNum

    -- Judge if it is self
    local function IsSelfUid(uid)
        local u = DataMgr and DataMgr.roleData and tonumber(DataMgr.roleData.uid)
        if not u then
            local ok, ret = pcall(function()
                if TeamUpNewSystem and TeamUpNewSystem.GetSelfUID then
                    return tonumber(TeamUpNewSystem.GetSelfUID())
                end
            end)
            if ok then u = ret end
        end
        return u and tostring(uid) == tostring(u)
    end
    M.IsSelfUid = IsSelfUid

    -- Install hook (retry periodically on failure)
    local function Install(tag, installFn)
        local installed = false
        local function try()
            if installed then return true end
            local ok, ret = pcall(installFn)
            if ok and ret then installed = true end
            return installed
        end
        if not try() then
            local ticker = GetTicker()
            if not (ticker and ticker.AddTimerLoop) then
                pcall(function() ticker = require("common.time_ticker") end)
            end
            if ticker and ticker.AddTimerLoop then
                ticker.AddTimerLoop(3, function()
                    local okF, inFight = pcall(function()
                        return GameStatus and GameStatus.IsInFightingStatus and GameStatus.IsInFightingStatus()
                    end)
                    if okF and inFight then return end
                    try()
                end, 100, 1)
            end
        end
        return installed
    end

    -- ============================================================
    -- 1. Credit score spoof
    -- Module: client.slua.logic.ReputationSystem.logic_reputation_system
    -- Hook: GetCreditScore
    -- ============================================================
    local function InstallCredit()
        local ok, m = pcall(require, "client.slua.logic.ReputationSystem.logic_reputation_system")
        if not ok or type(m) ~= "table" or type(m.GetCreditScore) ~= "function" then
            return false
        end
        if m.__ciCreditHooked then return true end

        local orig = m.GetCreditScore
        m.GetCreditScore = function(self, ...)
            local v = CfgNum("CI_CREDIT_SCORE", 0)
            if v > 0 then return v end
            return orig(self, ...)
        end
        m.__ciCreditHooked = true
        return true
    end
    Install("ci_credit", InstallCredit)

    -- ============================================================
    -- 2. Like count spoof
    -- Module: LobbyModuleConfig.collect_module
    -- Hook: GetLikeCount
    -- ============================================================
    local function InstallLikeCount()
        if not (ModuleManager and ModuleManager.GetModule and ModuleManager.LobbyModuleConfig) then
            return false
        end
        local ok, m = pcall(ModuleManager.GetModule, ModuleManager.LobbyModuleConfig.collect_module)
        if not ok or type(m) ~= "table" or type(m.GetLikeCount) ~= "function" then
            return false
        end
        if m.__ciLikeHooked then return true end

        local orig = m.GetLikeCount
        m.GetLikeCount = function(self, ...)
            local v = CfgNum("CI_LIKE_COUNT", 0)
            if v > 0 then return v end
            return orig(self, ...)
        end
        m.__ciLikeHooked = true
        return true
    end
    Install("ci_likeCount", InstallLikeCount)

    -- ============================================================
    -- 3. Popularity value spoof
    -- Module: client.slua.logic.person_space.logic_roleinfo_popularity
    -- Hook: get_popularity_rsp (replace total_devote on response)
    -- ============================================================
    local function InstallPopularity()
        local ok, m = pcall(require, "client.slua.logic.person_space.logic_roleinfo_popularity")
        if not ok or type(m) ~= "table" or type(m.get_popularity_rsp) ~= "function" then
            return false
        end
        if m.__ciPopHooked then return true end

        local orig = m.get_popularity_rsp
        m.get_popularity_rsp = function(ok2, uid, total_devote, ...)
            local v = CfgNum("CI_POPULARITY", 0)
            if v > 0 and IsSelfUid(uid) then
                total_devote = v
            end
            return orig(ok2, uid, total_devote, ...)
        end
        m.__ciPopHooked = true
        return true
    end
    Install("ci_popularity", InstallPopularity)

    -- ============================================================
    -- 4. Weapon power spoof
    -- Module: client.slua.logic.weapon_strength.logic_weapon_strength
    -- Hook: proc_get_weapon_power_data_rsp
    -- Replace fields: power_count / power / max_power
    -- ============================================================
    local function InstallWeaponPower()
        local ok, m = pcall(require, "client.slua.logic.weapon_strength.logic_weapon_strength")
        if not ok or type(m) ~= "table" or type(m.proc_get_weapon_power_data_rsp) ~= "function" then
            return false
        end
        if m.__ciWpHooked then return true end

        local orig = m.proc_get_weapon_power_data_rsp
        m.proc_get_weapon_power_data_rsp = function(self, cur, history, ...)
            local v = CfgNum("CI_WEAPON_POWER", 0)
            if v > 0 then
                local function rewrite(tbl)
                    if type(tbl) ~= "table" then return end
                    for _, e in pairs(tbl) do
                        if type(e) == "table" then
                            if tonumber(e.power_count) then e.power_count = v end
                            if tonumber(e.power)       then e.power = v end
                            if tonumber(e.max_power)   then e.max_power = v end
                        end
                    end
                end
                pcall(rewrite, cur)
                pcall(rewrite, history)
            end
            return orig(self, cur, history, ...)
        end
        m.__ciWpHooked = true
        return true
    end
    Install("ci_weaponPower", InstallWeaponPower)

    -- ============================================================
    -- Unified external interface
    -- ============================================================
    function M.Apply()
        pcall(InstallCredit)
        pcall(InstallLikeCount)
        pcall(InstallPopularity)
        pcall(InstallWeaponPower)
    end

    function M.SetCreditScore(n)  _G.UltimateEngine_Config.Set("CI_CREDIT_SCORE", n);  pcall(InstallCredit);       end
    function M.SetLikeCount(n)    _G.UltimateEngine_Config.Set("CI_LIKE_COUNT", n);    pcall(InstallLikeCount);    end
    function M.SetPopularity(n)   _G.UltimateEngine_Config.Set("CI_POPULARITY", n);    pcall(InstallPopularity);   end
    function M.SetWeaponPower(n)  _G.UltimateEngine_Config.Set("CI_WEAPON_POWER", n);  pcall(InstallWeaponPower);  end

    -- Try once immediately after module loads
    pcall(M.Apply)
end



local function InitFakeEconomyAndCrates()

    local function SafeRequire(modulePath)
        local success, result = pcall(require, modulePath)
        if not success or not result then return nil end
        return result
    end

    local EventDefine = SafeRequire("client.slua.common.EventDefine") 
                     or SafeRequire("client.slua.config.event_config") 
                     or SafeRequire("client.slua.config.EventConst")
    if EventDefine and type(EventDefine) == "table" then
        for k, v in pairs(EventDefine) do
            if _G[k] == nil then _G[k] = v end
        end
    end

    local function SafePostEvent(eventType, eventId, ...)
        if EventSystem and eventType and eventId then
            pcall(EventSystem.postEvent, EventSystem, eventType, eventId, ...)
        end
    end


    local FAKE_UC_DEFAULT = tonumber(_G.FORMULA_CURRENCY_VALUES and _G.FORMULA_CURRENCY_VALUES.fake_uc_default) or 999999999
    local _fakeCurrencySnapshots = setmetatable({}, { __mode = "k" })
    local function snapshotCurrencyObject(obj, keys)
        if type(obj) ~= "table" then return end
        local snap = _fakeCurrencySnapshots[obj]
        if not snap then snap = {}; _fakeCurrencySnapshots[obj] = snap end
        for _, key in ipairs(keys) do
            if snap[key] == nil then snap[key] = { value = rawget(obj, key) } end
        end
    end
    local function restoreCurrencyObjects()
        for obj, snap in pairs(_fakeCurrencySnapshots) do
            if type(obj) == "table" then
                for key, item in pairs(snap) do rawset(obj, key, item.value) end
            end
        end
        _fakeCurrencySnapshots = setmetatable({}, { __mode = "k" })
    end
    _G.FORMULA_RestoreFakeCurrencies = restoreCurrencyObjects
    local fakeCurrencyPath = "/sdcard/storage/emulated/0/Android/data/com.pubg.imobile/files/FakeCurrency.json"

    local function getFakeWallet()
        _G.FakeCurrency = _G.FakeCurrency or { uc = FAKE_UC_DEFAULT }
        _G.FakeCurrency.uc = tonumber(_G.FakeCurrency.uc) or FAKE_UC_DEFAULT
        if _G.FakeCurrency.uc < 0 then _G.FakeCurrency.uc = 0 end
        return _G.FakeCurrency
    end

    local function GetFakeUC()
        return getFakeWallet().uc
    end

    local function saveFakeWallet()
        pcall(function()
            local w = getFakeWallet()
            local file = io.open(fakeCurrencyPath, "w")
            if not file then return end
            local ok, jsonStr = pcall(function()
                return (_G.json and _G.json.encode(w)) or (slua.json and slua.json.encode(w))
            end)
            if ok and jsonStr then file:write(jsonStr) end
            file:close()
        end)
    end

    local function loadFakeWallet()
        pcall(function()
            local file = io.open(fakeCurrencyPath, "r")
            if not file then return end
            local content = file:read("*a")
            file:close()
            if not content or content == "" then return end
            local ok, data = pcall(function()
                return (_G.json and _G.json.decode(content)) or (slua.json and slua.json.decode(content))
            end)
            if ok and type(data) == "table" then
                _G.FakeCurrency = data
                getFakeWallet()
            end
        end)
    end


    local function RefreshFakeCurrencyUI()
        if not _G.FormulaFeatureEnabled("fakeWallet") then return end
        local uc = GetFakeUC()
        local cv = _G.FORMULA_CURRENCY_VALUES or {}
        local gcoin = tonumber(cv.gcoin) or 78787878
        local shownUC = tonumber(cv.uc) or 99999991
        local silver = tonumber(cv.silver) or 78916613
        pcall(function()
            local dMgr = DataMgr or _G.DataMgr
            if dMgr then
                rawset(dMgr, "ticket", shownUC)
                rawset(dMgr, "uc", shownUC)
                rawset(dMgr, "UC", shownUC)
                rawset(dMgr, "gold", gcoin)
                rawset(dMgr, "gcoin", gcoin)
                rawset(dMgr, "GCoin", gcoin)
                rawset(dMgr, "diamond", shownUC)
                rawset(dMgr, "eternal_diamond", shownUC)
                rawset(dMgr, "money", shownUC)
                rawset(dMgr, "currency", shownUC)
                rawset(dMgr, "ag", silver)
                rawset(dMgr, "silver", silver)
                if dMgr.roleData then
                    rawset(dMgr.roleData, "ticket", shownUC)
                    rawset(dMgr.roleData, "uc", shownUC)
                    rawset(dMgr.roleData, "gold", gcoin)
                    rawset(dMgr.roleData, "gcoin", gcoin)
                    rawset(dMgr.roleData, "silver", silver)
                    rawset(dMgr.roleData, "diamond", shownUC)
                end
            end
        end)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc)
        SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc)
        SafePostEvent(EVENTTYPE_ROLE, EVENTID_ROLE_DATA_UPDATE)
        SafePostEvent(EVENTTYPE_STORE, EVENTID_STORE_CURRENCY_UPDATE)
        SafePostEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_TICKET_UPDATE)
        SafePostEvent(EVENTTYPE_STORE_DATA, EVENTID_STORE_UPDATE_EXCHANGE_COIN)
    end

    local function SpendFakeUC(amount)
        if not _G.FormulaFeatureEnabled("fakeWallet") then return false end
        amount = math.floor(tonumber(amount) or 0)
        if amount <= 0 then return true end
        local w = getFakeWallet()
        if w.uc < amount then return false end
        w.uc = w.uc - amount
        saveFakeWallet()
        RefreshFakeCurrencyUI()
        return true
    end

    local function HasEnoughUC(amount)
        if not _G.FormulaFeatureEnabled("fakeWallet") then return false end
        amount = tonumber(amount) or 0
        if amount <= 0 then return GetFakeUC() > 0 end
        return GetFakeUC() >= amount
    end

    local function CaptureUCPrice(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            local n = tonumber(v)
            if n and n >= 1 and n <= 20000 then
                _G._lastUCCheckPrice = n
                return n
            end
        end
        return tonumber(_G._lastUCCheckPrice) or 0
    end

    local function TrySpendUC(cost)
        cost = tonumber(cost) or 0
        if cost <= 0 then cost = tonumber(_G._lastUCCheckPrice) or 0 end
        if cost <= 0 then return true end
        return SpendFakeUC(cost)
    end

    loadFakeWallet()
    saveFakeWallet()
    _G.GetFakeUC = GetFakeUC
    _G.SpendFakeUC = SpendFakeUC


    _G.ApplyAllFakeCurrencies = function(target)
        if not _G.FormulaFeatureEnabled("fakeWallet") then return false end
        local uc = GetFakeUC()
        local cv = _G.FORMULA_CURRENCY_VALUES or {}
        local gcoin = tonumber(cv.gcoin) or 78787878
        local shownUC = tonumber(cv.uc) or 99999991
        local silver = tonumber(cv.silver) or 78916613
        local function enough(a, b, ...)
            local price = tonumber(b)
            if not price or price <= 0 then
                price = CaptureUCPrice(a, b, ...)
            else
                _G._lastUCCheckPrice = price
            end
            return HasEnoughUC(price)
        end

        local dMgr = target or DataMgr or _G.DataMgr or SafeRequire("client.slua.logic.common.DataMgr") or SafeRequire("client.data.DataMgr")
        if dMgr then
            snapshotCurrencyObject(dMgr, {
                "ticket", "eternal_diamond", "home_coin", "gold", "gcoin", "GCoin", "diamond", "pp", "bp",
                "coupon", "voucher", "fp_token", "gold_chip", "gen_ticket", "corps_money", "smelt", "battle_coin",
                "uc", "UC", "money", "currency", "ag", "silver", "GetCurrency", "GetMoney", "GetTicket",
                "GetUC", "GetGold", "GetDiamond", "GetMoneyByType", "CheckMoney", "CheckCurrency", "CheckTicket",
                "CheckUC", "CheckIsEnough", "IsMoneyEnough", "IsCurrencyEnough"
            })
            if type(dMgr.roleData) == "table" then
                snapshotCurrencyObject(dMgr.roleData, { "bgbg_vip", "level", "ticket", "gold", "gcoin", "silver", "diamond", "uc" })
            end
            dMgr.ticket = shownUC
            dMgr.eternal_diamond = shownUC
            dMgr.home_coin = gcoin
            dMgr.gold = gcoin
            dMgr.gcoin = gcoin
            dMgr.GCoin = gcoin
            dMgr.diamond = shownUC
            dMgr.pp = uc
            dMgr.bp = uc
            dMgr.coupon = uc
            dMgr.voucher = uc
            dMgr.fp_token = uc
            dMgr.gold_chip = uc
            dMgr.gen_ticket = uc
            dMgr.corps_money = uc
            dMgr.smelt = uc
            dMgr.battle_coin = uc
            dMgr.uc = shownUC
            dMgr.UC = shownUC
            dMgr.money = shownUC
            dMgr.currency = shownUC
            dMgr.ag = silver
            dMgr.silver = silver

            if dMgr.roleData then
                dMgr.roleData.bgbg_vip = 1
                dMgr.roleData.level = 100
                dMgr.roleData.ticket = shownUC
                dMgr.roleData.gold = gcoin
                dMgr.roleData.gcoin = gcoin
                dMgr.roleData.silver = silver
                dMgr.roleData.diamond = shownUC
                dMgr.roleData.uc = shownUC
            end

            dMgr.GetCurrency = function(...) return GetFakeUC() end
            dMgr.GetMoney = function(...) return GetFakeUC() end
            dMgr.GetTicket = function(...) return GetFakeUC() end
            dMgr.GetUC = function(...) return GetFakeUC() end
            dMgr.GetGold = function(...) return GetFakeUC() end
            dMgr.GetDiamond = function(...) return GetFakeUC() end
            dMgr.GetMoneyByType = function(...) return GetFakeUC() end
            dMgr.CheckMoney = enough
            dMgr.CheckCurrency = enough
            dMgr.CheckTicket = enough
            dMgr.CheckUC = enough
            dMgr.CheckIsEnough = enough
            dMgr.IsMoneyEnough = enough
            dMgr.IsCurrencyEnough = enough

            if EventSystem and EVENTTYPE_DATA_MGR then
                if EVENTID_DATAMGR_GOLD_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_GOLD_CHANGE, uc) end
                if EVENTID_DATAMGR_TICKET_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_TICKET_CHANGE, uc) end
                if EVENTID_DATAMGR_DIAMOND_CHANGE then SafePostEvent(EVENTTYPE_DATA_MGR, EVENTID_DATAMGR_DIAMOND_CHANGE, uc) end
            end
        end

        local role_data = SafeRequire("client.slua.logic.role.role_data") or SafeRequire("client.slua.logic.role.logic_role") or SafeRequire("client.slua.logic.role.RoleData")
        if role_data then
            snapshotCurrencyObject(role_data, {
                "ticket", "uc", "gold", "gcoin", "diamond", "money", "currency", "ag", "silver",
                "GetTicket", "GetUC", "GetGold", "GetMoney", "GetDiamond", "GetCurrency"
            })
            role_data.ticket = shownUC
            role_data.uc = shownUC
            role_data.gold = gcoin
            role_data.gcoin = gcoin
            role_data.diamond = shownUC
            role_data.money = shownUC
            role_data.currency = shownUC
            role_data.ag = silver
            role_data.silver = silver
            role_data.GetTicket = function(...) return GetFakeUC() end
            role_data.GetUC = function(...) return GetFakeUC() end
            role_data.GetGold = function(...) return GetFakeUC() end
            role_data.GetMoney = function(...) return GetFakeUC() end
            role_data.GetDiamond = function(...) return GetFakeUC() end
            role_data.GetCurrency = function(...) return GetFakeUC() end
        end

        pcall(function()
            local StoreUtils = SafeRequire("client.slua.logic.store.utils.store_utils")
            if StoreUtils and StoreUtils.GetMoneyInfo then
                if StoreUtils.__formula_orig_GetMoneyInfo == nil then
                    StoreUtils.__formula_orig_GetMoneyInfo = StoreUtils.GetMoneyInfo
                end
                snapshotCurrencyObject(StoreUtils, { "GetMoneyInfo" })
                StoreUtils.GetMoneyInfo = function()
                    local n = GetFakeUC()
                    return { nDiamond = n, nUC = n, nSilver = n, nGold = n, nTicket = n }
                end
            end
        end)

        pcall(function()
            local Logic_ItemUtils = SafeRequire("client.slua.logic.common.Logic_ItemUtils")
            if Logic_ItemUtils and Logic_ItemUtils.GetItemCount then
                if Logic_ItemUtils.__formula_orig_GetItemCount == nil then
                    Logic_ItemUtils.__formula_orig_GetItemCount = Logic_ItemUtils.GetItemCount
                end
                local origGIC = Logic_ItemUtils.__formula_orig_GetItemCount
                snapshotCurrencyObject(Logic_ItemUtils, { "GetItemCount" })
                Logic_ItemUtils.GetItemCount = function(nItemId, bForever)
                    local num = tonumber(nItemId)
                    if num == 1109 or num == 1006 or num == 1001 or num == 1002 or num == 1003 then return GetFakeUC() end
                    return origGIC and origGIC(nItemId, bForever) or 0
                end
            end
        end)
    end

    -- تجاوز صناديق الدفع وشاشات الشحن
    local logic_common_pay_box = SafeRequire("client.slua.logic.common.Payclass.logic_common_pay_box")
    if logic_common_pay_box then
        if logic_common_pay_box.__formula_orig_paybox == nil then
            logic_common_pay_box.__formula_orig_paybox = {
                ShowUcRechargeMsg = logic_common_pay_box.ShowUcRechargeMsg,
                ShowPayBox = logic_common_pay_box.ShowPayBox,
                CheckIsEnoughUC = logic_common_pay_box.CheckIsEnoughUC,
            }
        end
        local origPaybox = logic_common_pay_box.__formula_orig_paybox
        logic_common_pay_box.ShowUcRechargeMsg = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return true end
            if type(origPaybox.ShowUcRechargeMsg) == "function" then return origPaybox.ShowUcRechargeMsg(...) end
        end
        logic_common_pay_box.ShowPayBox = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return true end
            if type(origPaybox.ShowPayBox) == "function" then return origPaybox.ShowPayBox(...) end
        end
        logic_common_pay_box.CheckIsEnoughUC = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return true end
            if type(origPaybox.CheckIsEnoughUC) == "function" then return origPaybox.CheckIsEnoughUC(...) end
            return false
        end
    end


    local _fakeInsIdCounter = 900000000
    local _loadedFakeItems = nil

    local function loadFakeItems()
        if _loadedFakeItems then return _loadedFakeItems end
        _loadedFakeItems = {}
        pcall(function()
            local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
            local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSupplyRepeatedList)
            if data and type(data) == "table" and data.fakeItems then
                for _, resId in pairs(data.fakeItems) do
                    _loadedFakeItems[tonumber(resId)] = true
                end
            end
        end)
        return _loadedFakeItems
    end

    local function saveFakeItems()
        pcall(function()
            local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
            local items = {}
            for resId, _ in pairs(_loadedFakeItems or {}) do
                table.insert(items, resId)
            end
            PlayerPrefsSystem.SaveTableToFile_N({ fakeItems = items }, PlayerPrefsSystem.ePlayerPrefsType.eSupplyRepeatedList)
        end)
    end

    local function addItemToInventory(resId)
        pcall(function()
            local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
            local logic_wardrobe_data_center = require("client.slua.logic.wardrobe.logic_wardrobe_data_center")
            local DataEntity = logic_wardrobe_data_center.GetWardrobeData()
            if not DataEntity then return end
            if DataEntity:GetDataByResID(resId, false) then return end

            _fakeInsIdCounter = _fakeInsIdCounter + 1
            local instid = _fakeInsIdCounter

            local changeEntry = {
                instid = instid,
                res_id = resId,
                count = 1,
                isnew = 1,
                valid_hours = 0,
                expire_ts = 0,
                lock_cnt = 0,
                source = 0,
            }

            local changelist = {}
            changelist[instid] = changeEntry
            wardrobe_data:OnHallDepotDataNotify(changelist)

            _loadedFakeItems = _loadedFakeItems or {}
            _loadedFakeItems[resId] = true
            saveFakeItems()
        end)
    end

    -- استخراج محتويات البكج المفتوح حالياً من شاشة اللعبة
    local function getCrateItemsFromUI()
        local result = {}
        pcall(function()
            if UIManager and UIManager.UI_Config then
                local store_supply_switcher = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
                if store_supply_switcher then
                    local supplySystem = store_supply_switcher:GetSupplySystem()
                    if supplySystem and supplySystem.PageListPanel and supplySystem.PageListPanel.itemDataList then
                        for _, v in pairs(supplySystem.PageListPanel.itemDataList) do
                            if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                table.insert(result, tonumber(v.itemId))
                            end
                        end
                    end
                    if #result == 0 then
                        local storeSystem = store_supply_switcher:GetStoreSystem()
                        if storeSystem and storeSystem.PageListPanel and storeSystem.PageListPanel.itemDataList then
                            for _, v in pairs(storeSystem.PageListPanel.itemDataList) do
                                if v.itemId and tonumber(v.itemId) and tonumber(v.itemId) > 0 then
                                    table.insert(result, tonumber(v.itemId))
                                end
                            end
                        end
                    end
                end
            end
        end)
        return result
    end

    local function makeFakeItemList(count)
        count = count or 1
        local list = {}
        local pool = getCrateItemsFromUI()
        if #pool == 0 and _G.ITEMS then pool = _G.ITEMS end
        if #pool == 0 then return list end

        for i = 1, count do
            local resId = pool[math.random(#pool)]
            table.insert(list, {
                resid = resId,
                res_id = resId,
                count = 1,
                valid_hours = 0,
                is_luck = (i == 1),
                order = i,
                drop_fun = 0,
                must_reward = (i == 1) and 1 or 0,
                to_res_id = 0,
                to_res_cnt = 0,
                ShowUseTime = true,
                getTags = 0,
            })
            addItemToInventory(resId)
        end
        return list
    end

    -- إظهار واجهة المكافآت مع الأنيميشن والفيديو
    local function showGetPanel(itemList, isTen)
        pcall(function()
            local rewardList = {}
            for _, v in pairs(itemList) do
                table.insert(rewardList, {
                    res_id = v.res_id or v.resid,
                    count = v.count or 1,
                    valid_hours = v.valid_hours or 0,
                    getTags = v.drop_fun or 0,
                    to_res_id = v.to_res_id or 0,
                    to_res_cnt = v.to_res_cnt or 0,
                    ShowUseTime = true,
                })
            end
            if UIManager and UIManager.UI_Config and UIManager.UI_Config.new_supply_get_panel then
                if UIManager.IsUIShow and UIManager.IsUIShow(UIManager.UI_Config.new_supply_get_panel) then
                    local boxUI = UIManager.GetUI(UIManager.UI_Config.new_supply_get_panel)
                    if boxUI and boxUI.TryShowSupplyGetPanel then
                        boxUI:TryShowSupplyGetPanel(rewardList, isTen, {needShowMovie = true})
                    end
                else
                    UIManager.ShowUI(UIManager.UI_Config.new_supply_get_panel, rewardList, isTen, {needShowMovie = true})
                end
            end
        end)
    end--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources

    local LogicSupply = SafeRequire("client.slua.logic.supply.logic_supply")
    if LogicSupply and not LogicSupply._supplyHooked then
        LogicSupply._supplyHooked = true
        LogicSupply.__formula_orig_IsCanBuySupplyBox = LogicSupply.IsCanBuySupplyBox
        LogicSupply.__formula_orig_CheckHasSelectWish = LogicSupply.CheckHasSelectWish
        LogicSupply.__formula_orig_CheckCrateLimitTime = LogicSupply.CheckCrateLimitTime
        LogicSupply.__formula_orig_ShowTipsWhenHaveFreeBan = LogicSupply.ShowTipsWhenHaveFreeBan
        LogicSupply.IsCanBuySupplyBox = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return true end
            if type(LogicSupply.__formula_orig_IsCanBuySupplyBox) == "function" then return LogicSupply.__formula_orig_IsCanBuySupplyBox(...) end
            return false
        end
        LogicSupply.CheckHasSelectWish = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return true end
            if type(LogicSupply.__formula_orig_CheckHasSelectWish) == "function" then return LogicSupply.__formula_orig_CheckHasSelectWish(...) end
            return false
        end
        LogicSupply.CheckCrateLimitTime = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return false end
            if type(LogicSupply.__formula_orig_CheckCrateLimitTime) == "function" then return LogicSupply.__formula_orig_CheckCrateLimitTime(...) end
            return true
        end
        LogicSupply.ShowTipsWhenHaveFreeBan = function(...)
            if _G.FormulaFeatureEnabled("fakeWallet") then return false end
            if type(LogicSupply.__formula_orig_ShowTipsWhenHaveFreeBan) == "function" then return LogicSupply.__formula_orig_ShowTipsWhenHaveFreeBan(...) end
        end
    end

    local StoreHandler = SafeRequire("client.network.Protocol.StoreHandler")
    if StoreHandler and not StoreHandler._crateHooked then
        StoreHandler._crateHooked = true


        StoreHandler.__formula_orig_send_buy_shop_by_id_req = StoreHandler.send_buy_shop_by_id_req
        StoreHandler.send_buy_shop_by_id_req = function(params)
            if not _G.FormulaFeatureEnabled("fakeWallet") then
                if type(StoreHandler.__formula_orig_send_buy_shop_by_id_req) == "function" then
                    return StoreHandler.__formula_orig_send_buy_shop_by_id_req(params)
                end
                return
            end
            local isTen = false
            local shopId = 0
            if type(params) == "table" then
                shopId = tonumber(params[1]) or 0
                local buyCount = tonumber(params[8]) or 1
                if buyCount == 10 then isTen = true end
            end


            TrySpendUC(isTen and 540 or 60)

            local itemList = makeFakeItemList(isTen and 10 or 1)
            if StoreHandler.on_buy_shop_by_id_rsp then
                pcall(StoreHandler.on_buy_shop_by_id_rsp, 0, shopId, itemList)
            end
            showGetPanel(itemList, isTen)
        end
    end


    local RechargePurchaseHandler = SafeRequire("client.network.Protocol.RechargePurchaseHandler")
    if RechargePurchaseHandler then
        RechargePurchaseHandler.__formula_orig_send_direct_buy_pre_check = RechargePurchaseHandler.send_direct_buy_pre_check
        RechargePurchaseHandler.__formula_orig_send_unified_purchase = RechargePurchaseHandler.send_unified_purchase
        RechargePurchaseHandler.send_direct_buy_pre_check = function(activityId, ...)
            if not _G.FormulaFeatureEnabled("fakeWallet") then
                if type(RechargePurchaseHandler.__formula_orig_send_direct_buy_pre_check) == "function" then
                    return RechargePurchaseHandler.__formula_orig_send_direct_buy_pre_check(activityId, ...)
                end
                return
            end
            if RechargePurchaseHandler.on_direct_buy_pre_check_rsp then
                RechargePurchaseHandler.on_direct_buy_pre_check_rsp(0, activityId)
            end
        end
        RechargePurchaseHandler.send_unified_purchase = function(activityId, selectedNumber, couponId, ...)
            if not _G.FormulaFeatureEnabled("fakeWallet") then
                if type(RechargePurchaseHandler.__formula_orig_send_unified_purchase) == "function" then
                    return RechargePurchaseHandler.__formula_orig_send_unified_purchase(activityId, selectedNumber, couponId, ...)
                end
                return
            end
            local amount = tonumber(selectedNumber) or 6000
            local w = getFakeWallet()
            w.uc = w.uc + amount
            saveFakeWallet()
            RefreshFakeCurrencyUI()
            if RechargePurchaseHandler.on_unified_purchase_rsp then
                RechargePurchaseHandler.on_unified_purchase_rsp(0, 1109, amount, 0)
            end
        end
    end


    if _G.ApplyAllFakeCurrencies then
        pcall(_G.ApplyAllFakeCurrencies)
    end
end


_G.FORMULA_ApplyFakeEconomy = function(enabled)
    if not enabled then
        if _G.FORMULA_RestoreFakeCurrencies then
            pcall(_G.FORMULA_RestoreFakeCurrencies)
        end
        return true
    end
    if not _G.__FORMULA_FAKE_ECONOMY_INITIALIZED then
        local okInit, initErr = pcall(InitFakeEconomyAndCrates)
        if not okInit then
            print("[FORMULA] Fake wallet initialization failed: " .. tostring(initErr))
            return false
        end
        _G.__FORMULA_FAKE_ECONOMY_INITIALIZED = true
        if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimerLoop then
            _G.Mytimer_ticker.AddTimerLoop(1, function()
                if _G.FormulaFeatureEnabled("fakeWallet") and _G.ApplyAllFakeCurrencies then
                    pcall(_G.ApplyAllFakeCurrencies)
                end
            end, -1, 1)
        end
    elseif _G.ApplyAllFakeCurrencies then
        pcall(_G.ApplyAllFakeCurrencies)
    end
    return true
end


--Join channel @xmymfx
--Delete / Replace channel - curse line (kept as original intent: do not delete/replace channel)
--Channel @xmymfx has more resources
-- ============================================================
-- FORMULA HAX | Professional Startup Welcome
-- ============================================================
do
    local N = rawget(_G, "FormulaStartupPopup")

    if type(N) ~= "table" then
        N = {
            Shown = false,
            Pending = false,
            Attempts = 0,
            MaxAttempts = 10
        }
        _G.FormulaStartupPopup = N
    end

    function N.Show()
        if N.Shown then return true end
        if N.Showing then return false end

        N.Attempts = (N.Attempts or 0) + 1
        N.Showing = true

        local ok, result = pcall(function()
            local LegalMsg = require(
                "client.slua.logic.common.logic_common_legal_msg"
            )

            if not LegalMsg
                or type(LegalMsg.ShowOnePopUI) ~= "function" then
                error("Startup popup API is not ready")
            end

            local content = table.concat({
                "       FORMULA HAX | FREEMIUM EDITION",
                "",
                "       WELCOME TO FORMULA",
                "Your skin customization experience starts here.",
                "",
                "━━━━━━━━━━━━━━━━━━━━━━━━",
                "          FEATURES",
                "━━━━━━━━━━━━━━━━━━━━━━━━",
                "",
                "• Expanded Weapon Skin Collection",
                "• X-Suit & Character Outfit Skins",
                "• Backpack & Helmet Customization",
                "• Parachute & Glider Selection",
                "• Additional Visual Features",
                "",
                "64-bit / 64x compatibility may vary.",
                "",
                "━━━━━━━━━━━━━━━━━━━━━━━━",
                "          SUPPORT",
                "━━━━━━━━━━━━━━━━━━━━━━━━",
                "",
                "Need assistance or have a problem?",
                "Contact: @saailformula",
                "Helper Lua: @saailformula",
                "",
                "Thank you for choosing FORMULA HAX.",
                "          ENJOY THE EXPERIENCE!"
            }, "\n")

            return LegalMsg.ShowOnePopUI({
                tabType = 999,
                title = "FORMULA HAX | WELCOME",
                content = content,
                btnOKText = "CONTINUE",
                btnCancleText = "CLOSE",
                acceptFunc = function() end,
                refuseFunc = function() end
            })
        end)

        N.Showing = false

        if ok and result ~= false then
            N.Shown = true
            N.LastError = nil
            return true
        end

        N.LastError = ok
            and "Startup popup request was rejected"
            or tostring(result)

        return false
    end
end

-- ========== FORMULA STARTUP WELCOME ========== 
if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimer then
    local function TryShowFormulaWelcome()
        local popup = rawget(_G, "FormulaStartupPopup")
        if not popup or popup.Shown then return end

        local maxAttempts = popup.MaxAttempts or 10
        if (popup.Attempts or 0) >= maxAttempts then
            print("[FORMULA] Welcome popup retry limit reached")
            return
        end

        local success = popup.Show()
        if not success and popup.Attempts < maxAttempts then
            _G.Mytimer_ticker.AddTimer(2, TryShowFormulaWelcome)
        end
    end

    -- Wait 3 seconds for the game UI to initialize.
    _G.Mytimer_ticker.AddTimer(3, TryShowFormulaWelcome)
end

-- ============================================================
-- FORMULA HAX | EXTERNAL WINDOWS OVERLAY BRIDGE
-- The Windows companion app writes one command to:
-- /storage/emulated/0/Android/obb/<game-package>/formula_overlay_cmd.txt
-- This bridge forwards supported commands to the existing Lua APIs.
-- ============================================================
do
    if not _G.__FORMULA_EXTERNAL_OVERLAY_BRIDGE then
        _G.__FORMULA_EXTERNAL_OVERLAY_BRIDGE = true

        local function getFormulaOverlayPath()
            local wp = _G.Wumingking and _G.Wumingking.Path
            if type(wp) == "string" and wp ~= "" then
                local p = wp:gsub("[^/]+$", "formula_overlay_cmd.txt")
                return p
            end

            local current = _G.GetCurrentWumingPath and _G.GetCurrentWumingPath()
            if type(current) == "string" and current ~= "" then
                return current:gsub("[^/]+$", "formula_overlay_cmd.txt")
            end

            local pkg = _G.GetCurrentGamePackage and _G.GetCurrentGamePackage()
            if type(pkg) == "string" and pkg ~= "" then
                return "/storage/emulated/0/Android/obb/" .. pkg .. "/formula_overlay_cmd.txt"
            end
            return nil
        end

        local function splitFormulaCommand(line)
            local out = {}
            for part in (tostring(line) .. "|"):gmatch("(.-)|") do
                out[#out + 1] = part
            end
            return out
        end

        local function formulaRefreshCharacter()
            pcall(function()
                if _G.Wumingking and _G.Wumingking.ApplyToLobby then
                    _G.Wumingking.ApplyToLobby()
                end
            end)
            pcall(function()
                if _G.GameAvatarHandlerplayers then _G.GameAvatarHandlerplayers() end
            end)
        end

        local function applyFormulaExternalCommand(line)
            local a = splitFormulaCommand(line)
            local cmd = string.upper(a[1] or "")
            local x, y, z = a[2], a[3], a[4]
            local W = _G.Wumingking
            local C = _G.DazhiMH_Config

            if cmd == "SLOT" then
                local slot, itemId = tonumber(x), tonumber(y)
                if not W or not W.SetSlot or not slot or not itemId then return false end
                W.SetSlot(slot, itemId)
                formulaRefreshCharacter()
                return true

            elseif cmd == "LEVEL" then
                local slot, level, itemId = tonumber(x), tonumber(y), tonumber(z)
                if not W or not W.SetLevelSkin or not slot or not level or not itemId then return false end
                if slot ~= 8 and slot ~= 9 then return false end
                if level < 1 or level > 6 then return false end
                W.SetLevelSkin(slot, level, itemId)
                formulaRefreshCharacter()
                return true

            elseif cmd == "PET" then
                local petId = tonumber(x)
                if not petId or petId < 0 or petId > 999999999 then return false end
                if W and W.SetPet then W.SetPet(petId) end
                _G.PetSkin = petId
                if _G.HandlePetLogic then pcall(_G.HandlePetLogic) end
                if _G.ApplyPetSkinInGame then pcall(_G.ApplyPetSkinInGame) end
                return true

            elseif cmd == "WEAPON" then
                local key = tostring(x or "")
                local index = tonumber(y)
                if not C or not C.Set or not _G.WeaponNameToID or not _G.WeaponNameToID[key] then return false end
                if not index or index < 1 or index > 100 then return false end
                C.Set(key, index)
                return true

            elseif cmd == "WEAPON_ID" then
                local key = tostring(x or "")
                local itemId = tonumber(y)
                local baseId = _G.WeaponNameToID and _G.WeaponNameToID[key]
                if not W or not W.SetWeapon or not baseId or not itemId or itemId <= 0 then return false end
                W.SetWeapon(baseId, itemId)
                _G.WeaponSkinID = _G.WeaponSkinID or {}
                _G.WeaponSkinID[baseId] = itemId
                if _G.GameAvatarHandlerweapons then pcall(_G.GameAvatarHandlerweapons) end
                return true

            elseif cmd == "VEHICLE" then
                local key = string.upper(tostring(x or ""))
                local index = tonumber(y)
                local allowed = {
                    DACIA=true, COUPERB=true, BUGGY=true, UAZ=true, MOTO=true,
                    SIDECARMOTO=true, BLOOMSC=true, RONY=true, RZR=true, BIGFOOT=true,
                    HORSE=true, MINIBUS=true, BOAT=true, ROADSTER=true, MIRADO=true, MIRADOC=true
                }
                if not C or not C.Set or not allowed[key] or not index or index < 1 or index > 100 then return false end
                C.Set(key, index)
                return true

            elseif cmd == "TOGGLE" then
                local key = string.upper(tostring(x or ""))
                local value = tonumber(y)
                local allowed = {
                    DEADBOX_SKIN=true, WEAPON_ANIM=true, WATERMARK=true, TRAIL_ENABLE=true,
                    GLOVES_HIDE_ON_GUN=true, GRENADE_FAST_REFRESH=true,
                    WEAPON_FAST_REFRESH=true, WEAPON_BACK_REFRESH=true
                }
                if not C or not C.Set or not allowed[key] or (value ~= 0 and value ~= 1) then return false end
                C.Set(key, value)
                if key == "DEADBOX_SKIN" then
                    _G.EnableDeadBoxSkin = (value == 1)
                elseif key == "WEAPON_ANIM" then
                    if _G.SetWeaponAnimation then pcall(_G.SetWeaponAnimation, value == 1) end
                elseif key == "WATERMARK" then
                    _G.WatermarkEnabled = (value == 1)
                elseif key == "TRAIL_ENABLE" then
                    if _G.GoldenLeavesTrail then
                        _G.GoldenLeavesTrail.Enabled = (value == 1)
                        if value == 1 and _G.GoldenLeavesTrail.Apply then
                            pcall(_G.GoldenLeavesTrail.Apply)
                        elseif value == 0 and _G.GoldenLeavesTrail.Stop then
                            pcall(_G.GoldenLeavesTrail.Stop)
                        end
                    end
                elseif key == "GLOVES_HIDE_ON_GUN" then
                    if _G.GameAvatarHandlerplayers then pcall(_G.GameAvatarHandlerplayers) end
                end
                return true

            elseif cmd == "TRAIL" then
                local trailId = tonumber(x)
                if not trailId then return false end
                if _G.GoldenLeavesTrail and type(_G.GoldenLeavesTrail.SetType) == "function" then
                    pcall(_G.GoldenLeavesTrail.SetType, trailId)
                elseif C and C.Set then
                    C.Set("TRAIL_TYPE", trailId)
                    if _G.GoldenLeavesTrail then _G.GoldenLeavesTrail.TRAIL_ITEM_ID = trailId end
                else
                    return false
                end
                return true

            elseif cmd == "WEATHER" then
                local value = tonumber(x)
                if not value or value < 0 or value > 4 or not C or not C.Set then return false end
                _G.WeatherMode = value
                C.Set("WEATHER", value)
                if _G.UpdateWeatherMode then pcall(_G.UpdateWeatherMode, value) end
                return true

            elseif cmd == "FOV_ENABLE" then
                local value = tonumber(x)
                if (value ~= 0 and value ~= 1) or not C or not C.Set then return false end
                _G.ConfigFOVEnable = (value == 1)
                C.Set("FOV_ENABLE", value)
                if _G.GameCameraView then pcall(_G.GameCameraView) end
                return true

            elseif cmd == "FOV_VALUE" then
                local value = tonumber(x)
                if not value or value < 90 or value > 120 or not C or not C.Set then return false end
                _G.ConfigFOV = value
                C.Set("FOV_VALUE", value)
                if _G.GameCameraView then pcall(_G.GameCameraView) end
                return true
            end

            return false
        end

        local function pollFormulaExternalCommand()
            local path = getFormulaOverlayPath()
            if not path then return end
            local f = io.open(path, "r")
            if not f then return end
            local data = f:read("*a") or ""
            f:close()
            if data == "" then return end

            -- Clear before applying, so a failed command is never replayed every tick.
            local clear = io.open(path, "w")
            if clear then clear:write(""); clear:close() end

            for line in data:gmatch("[^\r\n]+") do
                local ok, result = pcall(applyFormulaExternalCommand, line)
                if ok and result then
                    print("[FORMULA OVERLAY] Applied: " .. tostring(line))
                else
                    print("[FORMULA OVERLAY] Rejected: " .. tostring(line) .. " / " .. tostring(result))
                end
            end
        end

        if _G.Mytimer_ticker and _G.Mytimer_ticker.AddTimerLoop then
            _G.Mytimer_ticker.AddTimerLoop(0.5, function()
                pcall(pollFormulaExternalCommand)
            end, -1, 1)
            print("[FORMULA OVERLAY] External command bridge installed")
        else
            print("[FORMULA OVERLAY] Timer unavailable; external bridge not started")
        end
    end
end

-- ======================================================================
-- iPad View While Scoped  ::  toggle + FOV slider  (Camera Control)
-- Applies an iPad-style wide FOV only while aiming down sights and
-- restores the normal camera the instant the scope is released.
-- Drop-in: hooks the existing Feature Toggles page, no other edits needed.
-- ======================================================================
do
    local KEY_ON  = "IPAD_SCOPE"      -- 0 / 1 in wumingking.h
    local KEY_FOV = "IPAD_SCOPEFOV"   -- 30 .. 120 in wumingking.h
    local FOV_MIN, FOV_MAX, FOV_DEFAULT = 30, 120, 60

    local enabled        = nil        -- nil = not read from file yet
    local scopeFOV       = nil
    local savedDefaultFOV = nil       -- original PlayerCameraManager.DefaultFOV
    local loaded         = false

    local function cfgGet(key, def)
        local C = _G.DazhiMH_Config
        if C and type(C.Get) == "function" then
            local v = C.Get(key, def)
            if v ~= nil then return v end
        end
        return def
    end

    local function cfgSet(key, value)
        local C = _G.DazhiMH_Config
        if C and type(C.Set) == "function" then
            pcall(C.Set, key, value)
        end
    end

    local function clampFOV(v)
        v = math.floor(tonumber(v) or FOV_DEFAULT)
        if v < FOV_MIN then v = FOV_MIN end
        if v > FOV_MAX then v = FOV_MAX end
        return v
    end

    local function loadOnce()
        if loaded then return end
        loaded   = true
        enabled  = (tonumber(cfgGet(KEY_ON, 0)) or 0) == 1
        scopeFOV = clampFOV(cfgGet(KEY_FOV, FOV_DEFAULT))
    end

    local function getPC()
        local hud = slua_GameFrontendHUD
        if not hud then return nil end
        local pc = hud:GetPlayerController()
        if not pc or not slua.isValid(pc) then return nil end
        return pc
    end

    local function applyFOV(pc, camMgr, fov)
        pcall(function()
            if type(pc.FOV) == "function" then pc:FOV(fov) else pc.FOV = fov end
        end)
        if camMgr then
            pcall(function()
                if savedDefaultFOV == nil then savedDefaultFOV = camMgr.DefaultFOV end
                camMgr.DefaultFOV = fov
                if type(camMgr.SetFOV) == "function" then camMgr:SetFOV(fov) end
            end)
        end
    end

    local function restoreFOV(pc, camMgr)
        pcall(function()
            if type(pc.FOV) == "function" then pc:FOV(0) else pc.FOV = 0 end
        end)
        if camMgr then
            pcall(function()
                if savedDefaultFOV ~= nil then camMgr.DefaultFOV = savedDefaultFOV end
                if type(camMgr.UnlockFOV) == "function" then camMgr:UnlockFOV() end
            end)
        end
        savedDefaultFOV = nil
    end

    function _G.IpadScopeHandler()
        pcall(function()
            loadOnce()
            local pc = getPC()
            if not pc then return end
            local ch = pc:GetPlayerCharacterSafety()
            if not ch or not slua.isValid(ch) then return end

            local camMgr = pc.PlayerCameraManager
            if camMgr and not slua.isValid(camMgr) then camMgr = nil end

            local aiming = (ch.bIsWeaponAiming == true) or (ch.bIsGunADS == true)
            if not enabled or not aiming then
                restoreFOV(pc, camMgr)
                return
            end
            applyFOV(pc, camMgr, scopeFOV or FOV_DEFAULT)
        end)
    end

    -- ---------------- Menu entries (camera section) ----------------
    local function injectScopeUI(stack)
        if type(stack) ~= "table" then return end
        local ok, AliasMap = pcall(require, "client.slua.umg.NewSetting.Item.AliasMap")
        if not ok or not AliasMap then return end

        table.insert(stack, { UI = AliasMap.Spacer, Height = 20 })
        table.insert(stack, { UI = AliasMap.Title, Text = "07 | IPAD VIEW WHILE SCOPE" })
        table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

        table.insert(stack, {
            Key = "IpadViewScopeToggle",
            UI = AliasMap.Switcher,
            Text = "ENABLE IPAD VIEW WHILE SCOPE",
            Help = "iPad-style wide view only while aiming down sights.\n8x/6x/4x/3x -> set 40 | Holo/2x/Red Dot -> set 60",
            GetFunc = function()
                loadOnce()
                return enabled == true
            end,
            SetFunc = function(_, value)
                loadOnce()
                enabled = (value == true)
                cfgSet(KEY_ON, enabled and 1 or 0)
                pcall(_G.IpadScopeHandler)
                return true
            end
        })

        table.insert(stack, { UI = AliasMap.Spacer, Height = 10 })

        table.insert(stack, {
            Key = "IpadViewScopeFOV",
            UI = AliasMap.Slider,
            Text = "SCOPE FOV  (8x/6x/4x/3x=40 | Holo/2x/RedDot=60)",
            Help = "Field of view used while aiming.\n40 for 3x-8x scopes, 60 for holographic / 2x / red dot.",
            Min = FOV_MIN,
            Max = FOV_MAX,
            IsPercent = false,
            GetFunc = function()
                loadOnce()
                return scopeFOV or FOV_DEFAULT
            end,
            SetFunc = function(_, value)
                loadOnce()
                scopeFOV = clampFOV(value)
                cfgSet(KEY_FOV, scopeFOV)
                pcall(_G.IpadScopeHandler)
                return true
            end
        })
    end

    local BoxTab = _G.BoxSettingTab
    if BoxTab and type(BoxTab.BuildStack) == "function" and not _G.__ipadScopeBuildHooked then
        _G.__ipadScopeBuildHooked = true
        local origBuildStack = BoxTab.BuildStack
        BoxTab.BuildStack = function(...)
            local stack = origBuildStack(...)
            pcall(injectScopeUI, stack)
            return stack
        end
    end

    -- ---------------- Ticker ----------------
    local ticker = _G.Mytimer_ticker
    if not ticker then
        local ok, t = pcall(require, "common.time_ticker")
        if ok then ticker = t end
    end
    if ticker and type(ticker.AddTimerLoop) == "function" then
        if _G.__ipadScopeTimer and ticker.IsRunning and ticker.IsRunning(_G.__ipadScopeTimer) then
            pcall(function() ticker.RemoveTimer(_G.__ipadScopeTimer) end)
        end
        _G.__ipadScopeTimer = ticker.AddTimerLoop(0, function()
            pcall(_G.IpadScopeHandler)
        end, -1, 0.05)
    end

    loadOnce()
    print("[IpadScope] Loaded - scope toggle ready (state=" .. tostring(enabled)
        .. ", fov=" .. tostring(scopeFOV) .. ")")
end