-- im@scgs [聖夜の願い] 橘ありす
local s,id=GetID()
local SHOE_ID=346002 -- 「im@scgs - 魔法の靴」
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」による特殊召喚


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

    -- ① 魔法の靴でSS成功時の効果: 相手モンスター1体の効果を無効化
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL+0x1000) -- 魔法の靴によるSS
    end)
    e1:SetTarget(s.distg)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    -- ② 除外して魔法の靴による特殊召喚
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCode(EVENT_FREE_CHAIN)
    -- 発動可能場所（モンス・手札・墓地）を維持
    e2:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE)
    e2:SetCountLimit(1,id+100)
    -- ← ここでコストを設定（自身を除外して発動する）
    e2:SetCost(function(e,tp,eg,ep,ev,re,r,rp,chk)
        local c=e:GetHandler()
        if chk==0 then return c:IsAbleToRemoveAsCost() end
        Duel.Remove(c,POS_FACEUP,REASON_COST)
    end)
    -- あると良いヒントタイミング（任意）
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

-- 魔法の靴でSSされたか判定
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    return re and re:GetHandler():IsCode(SHOE_ID)
end

-- フラグ付与
function s.flgop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():RegisterFlagEffect(FLAG_SHOE,RESET_EVENT+RESETS_STANDARD,0,1)
end

-- ①対象選択
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISABLE)
    local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e2)
    end
end

-- ②対象選択（手札の橘ありすカードを魔法の靴SS扱いでSS）
function s.spfilter(c,e,tp)
    return c.imascgs_name==346001 and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        -- 発動前チェック：
        -- (1) 自分自身が除外コストにできること
        -- (2) 手札に対象となるカードがあること
        local c=e:GetHandler()
        if not c:IsAbleToRemoveAsCost() then return false end
        return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end


function s.spop(e,tp,eg,ep,ev,re,r,rp)
    -- コストは既に支払われている（除外済み）のでここではそのまま処理
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if tc then
        -- 魔法の靴扱いで特殊召喚
        if Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,false,false,POS_FACEUP)>0 then
            tc:CompleteProcedure()
        end
    end
end
