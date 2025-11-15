-- im@scgs - ダミーカード（鷺沢文香）
local s,id=GetID()
local SETCODE=0x2fd286a
local FUMIKA_ID=347701        -- im@scgs - 鷺沢文香
local SUMMON_TYPE_PAIR=SUMMON_TYPE_SPECIAL+0x2000 -- 好きな専用召喚種別（任意）

function s.initial_effect(c)
    s.imascgs_name = FUMIKA_ID
    aux.EnableChangeCode(c,FUMIKA_ID,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,FUMIKA_ID)
    c:EnableReviveLimit()
end