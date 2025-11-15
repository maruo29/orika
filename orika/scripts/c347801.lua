-- im@scgs - 鷺沢文香＆橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local ARISU_ID=346001         -- im@scgs - 橘ありす
local FUMIKA_ID=347701        -- im@scgs - 鷺沢文香
local SUMMON_TYPE_PAIR=SUMMON_TYPE_SPECIAL+0x2000 -- 好きな専用召喚種別（任意）

function s.initial_effect(c)
    -- このカードは「橘ありす」として扱う（フィールド・墓地）
    s.imascgs_name=ARISU_ID
    s.imascgs_name=FUMIKA_ID
    aux.EnableChangeCode(c,ARISU_ID,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,ARISU_ID)
    c:EnableReviveLimit()

    ------------------------------------
    -- 手札からのみの特殊召喚条件
    ------------------------------------
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_PROC)
    e0:SetRange(LOCATION_HAND)
    e0:SetCondition(s.spcon)
    e0:SetOperation(s.spop)
    c:RegisterEffect(e0)

    ------------------------------------
    -- ① EXデッキから除外して「なりきり」
    ------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.mode_tg)
    e1:SetOperation(s.mode_op)
    c:RegisterEffect(e1)

    ------------------------------------
    -- ② 相手モンスターを守備表示にする
    ------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_SET_POSITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.target)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetValue(POS_FACEUP_DEFENSE)
	c:RegisterEffect(e2)

    ------------------------------------
    -- ③ 除外された時のLP回復
    ------------------------------------
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,1))
    e3:SetCategory(CATEGORY_RECOVER)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetCode(EVENT_REMOVE)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1,{id,1})
    e3:SetTarget(s.rectg)
    e3:SetOperation(s.recop)
    c:RegisterEffect(e3)
end

------------------------------------
-- 特殊召喚条件（手札からのみ）
-- 「フィールドのありす」＋「手札/フィールド/デッキの文香」を除外
------------------------------------
function s.spfilter_arisu(c,tp)
    return c:IsFaceup() and c:IsCode(ARISU_ID)
        and Duel.GetMZoneCount(tp,c)>0
end
function s.spfilter_fumika(c)
    return c:IsCode(FUMIKA_ID) and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    -- フィールドに表側の「im@scgs - 橘ありす」がいるか
    if not Duel.IsExistingMatchingCard(s.spfilter_arisu,tp,LOCATION_MZONE,0,1,nil,tp) then
        return false
    end
    -- 手札・フィールド・デッキに「im@scgs - 鷺沢文香」がいるか
    return Duel.IsExistingMatchingCard(s.spfilter_fumika,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK,0,1,nil)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g1=Duel.SelectMatchingCard(tp,s.spfilter_arisu,tp,LOCATION_MZONE,0,1,1,nil,tp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g2=Duel.SelectMatchingCard(tp,s.spfilter_fumika,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK,0,1,1,nil)
    g1:Merge(g2)
    Duel.Remove(g1,POS_FACEUP,REASON_COST)
    -- 専用召喚種別を付けておく（必要なら）
    c:SetMaterial(g1)
end
------------------------------------
-- im@scgs共通：スクリプトから imascgs_name を取得するヘルパー
------------------------------------
function s.get_imascgs_name(c)
    if not c then return nil end
    local code=c:GetOriginalCode()
    local mt=_G["c"..code]
    if mt and mt.imascgs_name then
        return mt.imascgs_name
    end
    return nil
end

------------------------------------
-- ① EXデッキから「名が記されたカード」を除外してなりきり
------------------------------------
-- 「im@scgs - 橘ありす」または「im@scgs - 鷺沢文香」の imascgs_name を持つカード
function s.mode_filter(c)
    -- スクリプト側に設定された imascgs_name を参照
    local name_code=s.get_imascgs_name(c)
    return c:IsSetCard(SETCODE)
        and c:IsType(TYPE_MONSTER+TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
        and name_code~=nil
        and (name_code==ARISU_ID or name_code==FUMIKA_ID)
        and c:IsAbleToRemove()
end

function s.mode_tg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsExistingMatchingCard(s.mode_filter,tp,LOCATION_EXTRA,0,1,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_EXTRA)
end

function s.mode_op(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.mode_filter,tp,LOCATION_EXTRA,0,1,1,nil)
    local tc=g:GetFirst()
    if not tc then return end

    -- 除外前に imascgs_name を拾っておく
    local name_code=s.get_imascgs_name(tc)
    if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)==0 then return end

    -- imascgs_name が取れなければ保険でそのカードのコードを使う
    local change_code=name_code or tc:GetCode()

    -- このターン中、このカードは imascgs_name のモンスターとして扱う
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CHANGE_CODE)
    e1:SetValue(change_code)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    c:RegisterEffect(e1)
end


------------------------------------
-- ② 相手フィールドのモンスターを守備表示にする
------------------------------------
function s.target(e,c)
    return c:IsFaceup() and c:IsAttackPos()
end

------------------------------------
-- ③ 除外されているim@scgsの種類数 × 500 回復
------------------------------------
function s.rcfilter(c)
    return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER)
end
function s.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g=Duel.GetMatchingGroup(s.rcfilter,tp,LOCATION_REMOVED,0,nil)
    local ct=g:GetClassCount(Card.GetCode)
    if chk==0 then return ct>0 end
    Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,ct*500)
end
function s.recop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.rcfilter,tp,LOCATION_REMOVED,0,nil)
    local ct=g:GetClassCount(Card.GetCode)
    if ct>0 then
        Duel.Recover(tp,ct*500,REASON_EFFECT)
    end
end
