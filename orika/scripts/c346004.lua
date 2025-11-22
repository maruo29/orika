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
    e3:SetCategory(CATEGORY_DRAW+CATEGORY_REMOVE)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,id)           -- このカード名の③の効果は1ターンに1度
    e3:SetCode(EVENT_REMOVE)
    e3:SetTarget(s.drtg)
    e3:SetOperation(s.drop)
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
-- ③：除外時ドロー＆手札除外
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
            and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,LOCATION_HAND,0,1,nil)
    end
    -- 自分だけ1ドロー
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
    -- 手札から1枚除外
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,1,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		Duel.ShuffleHand(tp)
        -- 手札から1枚選んで除外
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
        local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,LOCATION_HAND,0,1,1,nil)
        if #g>0 then
            Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
        end
	end
end