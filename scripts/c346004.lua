-- im@scgs [アドマイヤ・ブライド] 橘ありす
local s,id=GetID()
local SHOE_ID=346002 -- 「im@scgs - 魔法の靴」
local FLAG_SHOE=id+1000 -- 魔法の靴でSSされたフラグ

-- 魔法の靴の対象となるためのコードリンク
s.imascgs_name=346001

function s.initial_effect(c)
    -- このカード名はフィールド・墓地では「橘ありす」として扱う
    aux.EnableChangeCode(c,346001,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,346001)

    -- 魔法の靴で特殊召喚された場合、フラグを付与
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e0:SetCode(EVENT_SPSUMMON_SUCCESS)
    e0:SetCondition(s.sscon)
    e0:SetOperation(s.flgop)
    c:RegisterEffect(e0)
    
    -- 通常のシンクロ召喚では召喚できない
    c:EnableReviveLimit()
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e1)

    -- 除外置換（墓地送りを除外に変換）
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_TO_GRAVE_REDIRECT)
    e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_IMMUNE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetTarget(s.rmtarget)
    e2:SetTargetRange(LOCATION_HAND+LOCATION_DECK,LOCATION_HAND+LOCATION_DECK)
    e2:SetValue(LOCATION_REMOVED)
    c:RegisterEffect(e2)

    -- 除外された場合の効果(ターン1)
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id)
    e3:SetCode(EVENT_REMOVE)
    e3:SetTarget(s.target)
    e3:SetOperation(s.activate)
    c:RegisterEffect(e3)
end

-- 魔法の靴でSSされたか判定
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:GetHandler():IsCode(SHOE_ID)
end

-- フラグ付与
function s.flgop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():RegisterFlagEffect(FLAG_SHOE,RESET_EVENT+RESETS_STANDARD,0,1)
end

-- 除外置換対象（モンスター全般）
function s.rmtarget(e,c)
	return c:IsType(TYPE_MONSTER)
end

-- 除外時ドロー効果
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,PLAYER_ALL,1)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,PLAYER_ALL,1)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,1,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		Duel.ShuffleHand(tp)
		Duel.DiscardHand(tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end
