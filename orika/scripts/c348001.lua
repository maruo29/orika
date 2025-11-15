-- im@scgs - ユニット結成
local s,id=GetID()
local SETCODE=0x2fd286a

------------------------------------
-- im@scgs共通：スクリプトから imascgs_name のリストを取得
------------------------------------
function s.get_imascgs_name_list(c)
    if not c then return nil end
    local code=c:GetOriginalCode()
    local mt=_G["c"..code]
    if not mt then return nil end

    -- 新方式：テーブルで定義されている場合
    if type(mt.imascgs_name)=="table" then
        return mt.imascgs_name
    end
    -- 旧方式：1つだけ数値で持っている場合も配列にラップする
    if type(mt.imascgs_name)=="number" then
        return {mt.imascgs_name}
    end
    return nil
end

-- 指定したコードが「名が記された」中に含まれているか
function s.has_imascgs_name(c,target_code)
    local list=s.get_imascgs_name_list(c)
    if not list then return false end
    for _,v in ipairs(list) do
        if v==target_code then
            return true
        end
    end
    return false
end

------------------------------------
-- 初期効果
------------------------------------
function s.initial_effect(c)
    ------------------------------------
    -- ①：発動（手札からSS＋サーチ＋その後1枚捨てる）
    -- このカード名の①②の効果は1ターンに1度しか発動できない
    ------------------------------------
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id) 
    e1:SetTarget(s.tg1)
    e1:SetOperation(s.op1)
    c:RegisterEffect(e1)

    ------------------------------------
    -- ②：墓地からの効果（自己除外＋除外3枚戻して1ドロー）
    ------------------------------------
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetCountLimit(1,id+1) 
    e2:SetCost(s.cost2)
    e2:SetTarget(s.tg2)
    e2:SetOperation(s.op2)
    c:RegisterEffect(e2)
end

------------------------------------
-- ① 対象：手札から火・水・光属性のim@scgsモンスター1体をSS
------------------------------------
function s.spfilter1(c,e,tp)
    return c:IsSetCard(SETCODE)
        and c:IsType(TYPE_MONSTER)
        and (c:IsAttribute(ATTRIBUTE_FIRE)
            or c:IsAttribute(ATTRIBUTE_WATER)
            or c:IsAttribute(ATTRIBUTE_LIGHT))
        and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
            and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_HAND,0,1,nil,e,tp)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

------------------------------------
-- ① 処理：
-- ・対象をSS
-- ・そのモンスターの「名が記された」闇属性im@scgsモンスターをデッキからサーチ
-- ・サーチに成功した場合のみ手札を1枚捨てる
-- ・SSしたモンスターは攻撃できず、エンドフェイズに墓地へ送る
------------------------------------
function s.thfilter1(c,code)
    return c:IsSetCard(SETCODE)
        and c:IsType(TYPE_MONSTER)
        and c:IsAttribute(ATTRIBUTE_DARK)
        and s.has_imascgs_name(c,code)
        and c:IsAbleToHand()
end

-- エンドフェイズにこのカードを墓地へ送る処理
function s.send_eg_end(e,tp,eg,ep,ev,re,r,rp)
    local sc=e:GetHandler()
    if sc:IsFaceup() then
        Duel.SendtoGrave(sc,REASON_EFFECT)
    end
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_HAND,0,1,1,nil,e,tp)
    local tc=g:GetFirst()
    if not tc then return end
    if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

    -- フィールドに出た時点でのカード名コード（名前変更を反映）
    local code=tc:GetCode()

    -- デッキから「そのモンスターの名が記された」闇属性im@scgsをサーチ
    local added=false
    if Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil,code) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil,code)
        if #sg>0 and Duel.SendtoHand(sg,nil,REASON_EFFECT)>0 then
            Duel.ConfirmCards(1-tp,sg)
            added=true
        end
    end

    -- サーチに成功していた場合のみ、手札を1枚捨てる
    if added and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
        Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_EFFECT+REASON_DISCARD,nil)
    end

    -- このターン、攻撃不可
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_CANNOT_ATTACK)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)

    -- エンドフェイズに墓地へ送る
    local e2=Effect.CreateEffect(tc)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
    e2:SetCode(EVENT_PHASE+PHASE_END)
    e2:SetRange(LOCATION_MZONE)
    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
    e2:SetCountLimit(1)
    e2:SetOperation(s.send_eg_end)
    tc:RegisterEffect(e2)
end

------------------------------------
-- ② コスト：墓地のこのカードを除外
------------------------------------
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
    Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

------------------------------------
-- ② 対象：除外されている「im@scgs - ユニット結成」以外のim@scgsカード3枚
------------------------------------
function s.tdfilter(c)
    return c:IsSetCard(SETCODE) and not c:IsCode(id) and c:IsAbleToDeck()
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then
        return Duel.IsPlayerCanDraw(tp,1)
            and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_REMOVED,0,3,nil)
    end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_REMOVED)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

------------------------------------
-- ② 処理：3枚デッキに戻して1ドロー
------------------------------------
function s.op2(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_REMOVED,0,3,3,nil)
    if #g~=3 then return end
    local ct=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    if ct>0 then
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end
