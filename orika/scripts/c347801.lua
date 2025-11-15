-- im@scgs - 鷺沢文香＆橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local ARISU_ID=346001         -- im@scgs - 橘ありす
local FUMIKA_ID=347701        -- im@scgs - 鷺沢文香
local SUMMON_TYPE_PAIR=SUMMON_TYPE_SPECIAL+0x2000 -- 好きな専用召喚種別（任意）

------------------------------------
-- im@scgs共通：スクリプトから imascgs_name のリストを取得
------------------------------------
function s.get_imascgs_name_list(c)
    if not c then return nil end
    local code=c:GetOriginalCode()
    local mt=_G["c"..code]
    if not mt then return nil end

    -- ① 新方式：テーブルで定義されている場合
    if type(mt.imascgs_name)=="table" then
        return mt.imascgs_name
    end
    -- ② 旧方式：1つだけ数値で持っている場合も配列にラップする
    if type(mt.imascgs_name)=="number" then
        return {mt.imascgs_name}
    end
    return nil
end

-- 指定したコードが「名が記された」中に含まれているか
function s.has_imascgs_name(c, target_code)
    local list=s.get_imascgs_name_list(c)
    if not list then return false end
    for _,v in ipairs(list) do
        if v==target_code then
            return true
        end
    end
    return false
end

function s.initial_effect(c)
    -- このカードは「橘ありす」として扱う（フィールド・墓地）
    s.imascgs_name = {ARISU_ID, FUMIKA_ID}
    aux.EnableChangeCode(c,ARISU_ID,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,ARISU_ID)
    c:EnableReviveLimit()

    ------------------------------------
    -- 通常召喚・セット不可
    ------------------------------------
    local eNS=Effect.CreateEffect(c)
    eNS:SetType(EFFECT_TYPE_SINGLE)
    eNS:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    eNS:SetCode(EFFECT_CANNOT_SUMMON)
    c:RegisterEffect(eNS)
    local eSet=eNS:Clone()
    eSet:SetCode(EFFECT_CANNOT_MSET)
    c:RegisterEffect(eSet)

    ------------------------------------
    -- このカードは①の方法でのみ特殊召喚できる
    ------------------------------------
    local eSp=Effect.CreateEffect(c)
    eSp:SetType(EFFECT_TYPE_SINGLE)
    eSp:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    eSp:SetCode(EFFECT_SPSUMMON_CONDITION)
    eSp:SetValue(aux.FALSE)
    c:RegisterEffect(eSp)

    ------------------------------------
    -- 手札からのみの特殊召喚条件（あなたの①の方法）
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
function s.mode_filter(c)
    return c:IsSetCard(SETCODE)
        and c:IsType(TYPE_MONSTER+TYPE_FUSION+TYPE_SYNCHRO+TYPE_XYZ+TYPE_LINK)
        and c:IsAbleToRemove()
        and (s.has_imascgs_name(c,ARISU_ID) or s.has_imascgs_name(c,FUMIKA_ID))
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

    -- 除外前に「どの名前に化けるか」を決める
    local change_code=nil
    if s.has_imascgs_name(tc,ARISU_ID) then
        change_code=ARISU_ID
    elseif s.has_imascgs_name(tc,FUMIKA_ID) then
        change_code=FUMIKA_ID
    end

    if Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)==0 then return end

    -- 保険：どちらにも該当しない場合はそのカード自身のコード
    change_code=change_code or tc:GetCode()

    -- このターン中、このカードは選んだコードのモンスターとして扱う
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
