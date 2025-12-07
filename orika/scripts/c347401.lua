-- im@scgs [聖夜の願い] 橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local ARISU_ID=346001       -- im@scgs - 橘ありす
local SHOE_ID=346002        -- im@scgs - 魔法の靴
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000

function s.initial_effect(c)
    --------------------------------
    -- 基本設定
    --------------------------------
    c:EnableReviveLimit()
    -- フィールド・墓地では「im@scgs - 橘ありす」として扱う
    s.imascgs_name=ARISU_ID
    s.imascgs_name_list={ARISU_ID}
    aux.AddCodeList(c,ARISU_ID)
    aux.EnableChangeCode(c,ARISU_ID,LOCATION_MZONE+LOCATION_GRAVE)

    -- このカードはS召喚できず、「魔法の靴」の効果でのみSSできる
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(s.splimit)
    c:RegisterEffect(e0)

    --------------------------------
    -- ① 靴SS成功時：相手モンスター1体の効果をエンドフェイズまで無効
    --------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_DISABLE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e1:SetCountLimit(1,{id,0})
    e1:SetCondition(s.discon)
    e1:SetTarget(s.distg)
    e1:SetOperation(s.disop)
    c:RegisterEffect(e1)

    --------------------------------
    -- ② 自身を除外して、手札の「ありす名が記された」モンスターを
    --    「靴によるSS扱い」で特殊召喚（相手ターンでも可）
    --------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_MZONE)
    e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.spcost)
    e2:SetTarget(s.sptg)
    e2:SetOperation(s.spop)
    c:RegisterEffect(e2)
end

--------------------------------
-- 「魔法の靴」でのみ特殊召喚できる制限
--------------------------------
function s.splimit(e,se,sp,st)
    if not se then return false end
    return se:GetHandler():IsCode(SHOE_ID)
end

--------------------------------
-- 「名が記された」共通処理
--------------------------------
function s.get_name_list(c)
    if not c then return nil end
    local code=c:GetOriginalCode()
    local mt=_G["c"..code]
    if mt and mt.imascgs_name_list then
        return mt.imascgs_name_list
    end
    -- 後方互換
    if mt and mt.imascgs_name then
        return { mt.imascgs_name }
    end
    return nil
end

function s.has_name(c,tcode)
    local list=s.get_name_list(c)
    if not list then return false end
    for _,v in ipairs(list) do
        if v==tcode then return true end
    end
    return false
end

--------------------------------
-- ①：靴SS成功時
--------------------------------
function s.discon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_SHOE)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
    local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
    Duel.SetOperationInfo(0,0,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
    -- エンドフェイズまで効果を無効
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_DISABLE)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)
    local e2=e1:Clone()
    e2:SetCode(EFFECT_DISABLE_EFFECT)
    tc:RegisterEffect(e2)
    -- 罠モンスター対応
    if tc:IsType(TYPE_TRAPMONSTER) then
        local e3=e1:Clone()
        e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
        tc:RegisterEffect(e3)
    end
end

--------------------------------
-- ②：このカードを除外して発動
--------------------------------
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    if chk==0 then return c:IsAbleToRemoveAsCost() end
    Duel.Remove(c,POS_FACEUP,REASON_COST)
end

function s.spfilter(c,e,tp)
    return c:IsSetCard(SETCODE)
        and c:IsType(TYPE_MONSTER)
        and s.has_name(c,ARISU_ID) -- 「im@scgs - 橘ありす」のカード名が記されたモンスター
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SHOE,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if not tc then return end
    -- 「魔法の靴」による特殊召喚扱い
    if Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)>0 then
        tc:CompleteProcedure()
    end
end
