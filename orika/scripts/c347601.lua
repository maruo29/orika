-- im@scgs [キャッチマイスイート] 橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local SHOE_ID=346002 -- 魔法の靴
local ARISU_CODE=346001
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 魔法の靴特殊召喚


function s.initial_effect(c)
    s.imascgs_name=ARISU_CODE

    -- このカード名はフィールド・墓地で「橘ありす」として扱う
    aux.EnableChangeCode(c,ARISU_CODE,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,ARISU_CODE)
    c:EnableReviveLimit()

    ------------------------------------
    -- ①魔法の靴SS時のみ発動可能の除外効果
    ------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetHintTiming(0,TIMING_STANDBY_PHASE)
    e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e1:SetCondition(s.ex_cond)      -- 発動条件を追加
    e1:SetTarget(s.ex_target)
    e1:SetOperation(s.ex_operation)
    c:RegisterEffect(e1)

    ------------------------------------
    -- ②除外時ATKダウン効果
    ------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_REMOVE)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCountLimit(1,{id,1})
    e2:SetOperation(s.atkdown_op)
    c:RegisterEffect(e2)
end

------------------------------------
-- ①効果発動条件（魔法の靴SSであること）
------------------------------------
function s.ex_cond(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsSummonType(SUMMON_TYPE_SPECIAL) and re and re:GetHandler():IsCode(SHOE_ID)
end

------------------------------------
-- ①除外効果のターゲット
------------------------------------
function s.ex_filter_self(c)
    return c:IsFaceup() and c:IsSetCard(SETCODE)
end
function s.ex_filter_op(c)
    return c:IsFaceup() and c:IsType(TYPE_MONSTER)
end
function s.ex_target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return false end
    if chk==0 then
        return Duel.IsExistingTarget(s.ex_filter_self,tp,LOCATION_MZONE,0,1,nil)
           and Duel.IsExistingTarget(s.ex_filter_op,tp,0,LOCATION_MZONE,1,nil)
    end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g1=Duel.SelectTarget(tp,s.ex_filter_self,tp,LOCATION_MZONE,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g2=Duel.SelectTarget(tp,s.ex_filter_op,tp,0,LOCATION_MZONE,1,1,nil)
    local tg=Group.FromCards(g1:GetFirst(), g2:GetFirst())
    e:SetLabelObject(tg)
end

------------------------------------
-- ①除外処理
------------------------------------
function s.ex_operation(e,tp,eg,ep,ev,re,r,rp)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.Remove(g,POS_FACEUP,REASON_EFFECT+REASON_TEMPORARY)
    local c=e:GetHandler()
    local fid=c:GetFieldID()
    for tc in aux.Next(g) do
        tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY,0,1,fid)
    end
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
    e1:SetCountLimit(1)
    e1:SetLabel(fid)
    e1:SetLabelObject(g)
    e1:SetReset(RESET_PHASE+PHASE_STANDBY+RESET_SELF_TURN)
    e1:SetOperation(s.ret_op)
    Duel.RegisterEffect(e1,tp)
end

function s.ret_op(e,tp,eg,ep,ev,re,r,rp)
    local g=e:GetLabelObject()
    for tc in aux.Next(g) do
        if tc:GetFlagEffectLabel(id)==e:GetLabel() then
            Duel.ReturnToField(tc)
        end
    end
end

------------------------------------
-- ②ATKダウン効果
------------------------------------
function s.atkfilter(c)
    return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER)
end

function s.value(e,c)
    local tp=e:GetHandlerPlayer() -- この効果を発動したカードのコントローラー
    local g=Duel.GetMatchingGroup(s.atkfilter,tp,LOCATION_REMOVED,0,nil)
    local ct=g:GetClassCount(Card.GetCode)
    return ct * -100
end

function s.atkdown_op(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_UPDATE_ATTACK)
        e1:SetValue(s.value)
        e1:SetReset(RESET_PHASE+PHASE_END)
        tc:RegisterEffect(e1)
    end
end

