-- im@scgs [ありすのティーバーティ―] 橘ありす
local s, id = GetID()
local SHOE_ID = 346002 -- 「im@scgs - 魔法の靴」
local FLAG_SHOE = id + 1000 -- 魔法の靴でSSされたフラグ
local SETCODE = 0x2fd286a

-- 魔法の靴の対象となるためのコードリンク
s.imascgs_name = 346001

function s.initial_effect(c)
    -- このカード名はフィールド・墓地では「橘ありす」として扱う
    aux.EnableChangeCode(c, 346001, LOCATION_MZONE + LOCATION_GRAVE)
    aux.AddCodeList(c, 346001)

    -- 通常のシンクロ召喚では召喚できない
    c:EnableReviveLimit()
    local e1 = Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e1)

    -- 相手が手札にカードを加えた場合、そのカードを墓地へ送る（ターン1）
    local e2 = Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCategory(CATEGORY_TOGRAVE + CATEGORY_HANDES)
    e2:SetCode(EVENT_TO_HAND)
    e2:SetCondition(s.condition2)
    e2:SetCountLimit(1, id)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.target2)
    e2:SetOperation(s.activate2)
    c:RegisterEffect(e2)

    -- 除外された場合の効果(ターン1)
    local e3 = Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id, 0))
    e3:SetCategory(CATEGORY_HANDES + CATEGORY_DRAW)
    e3:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCountLimit(1, id + 1)
    e3:SetCode(EVENT_REMOVE)
    e3:SetCost(s.spcost)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
end

-- 魔法の靴でSSされたか判定
function s.sscon(e, tp, eg, ep, ev, re, r, rp)
    return re and re:GetHandler():IsCode(SHOE_ID)
end

-- フラグ付与
function s.flgop(e, tp, eg, ep, ev, re, r, rp)
    e:GetHandler():RegisterFlagEffect(FLAG_SHOE, RESET_EVENT + RESETS_STANDARD, 0, 1)
end

-- 除外置換対象（モンスター全般）
function s.rmtarget(e, c)
    return c:IsType(TYPE_MONSTER)
end

-- 除外時ドロー効果
function s.target(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return Duel.IsPlayerCanDraw(tp, 1)
    end
    Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, PLAYER_ALL, 1)
    Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, PLAYER_ALL, 1)
end

function s.activate(e, tp, eg, ep, ev, re, r, rp)
    if Duel.Draw(tp, 1, REASON_EFFECT) > 0 then
        Duel.BreakEffect()
        Duel.ShuffleHand(tp)
        Duel.DiscardHand(tp, aux.TRUE, 1, 1, REASON_EFFECT + REASON_DISCARD)
    end
end

function s.cfilter(c, tp)
    return c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK)
end
function s.condition2(e, tp, eg, ep, ev, re, r, rp)
    return ep ~= tp and eg:IsExists(s.cfilter, 1, nil, ep)
end
function s.target2(e, tp, eg, ep, ev, re, r, rp, chk)
    if chk == 0 then
        return true
    end
    Duel.SetTargetCard(eg)
    Duel.SetOperationInfo(0, CATEGORY_HANDES, nil, 0, 1 - tp, 1)
end
function s.filter(c, e, tp)
    return c:IsRelateToEffect(e) and c:IsControler(tp) and c:IsPreviousLocation(LOCATION_DECK)
end
function s.activate2(e, tp, eg, ep, ev, re, r, rp)
    local g = eg:Filter(Card.IsControler, nil, ep)
    if #g > 0 then
        Duel.Hint(HINT_SELECTMSG, ep, HINTMSG_TOGRAVE)
        local sg = g:Select(ep, 1, 1, nil)
        Duel.SendtoGrave(sg, REASON_EFFECT)
    end
end

function s.spcost(e, tp, eg, ep, ev, re, r, rp, chk)
    local g = Duel.GetDecktopGroup(tp, 3)
    if chk == 0 then
        return g:FilterCount(Card.IsAbleToRemoveAsCost, nil, POS_FACEUP) == 3
    end
    Duel.DisableShuffleCheck()
    Duel.Remove(g, POS_FACEUP, REASON_COST)
end

-- 除外時のサルベージ処理
function s.thfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsSetCard(SETCODE) and c:IsAbleToHand()
end
function s.thtg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
    if chkc then
        return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.thfilter(chkc)
    end
    if chk == 0 then
        return Duel.IsExistingTarget(s.thfilter, tp, LOCATION_REMOVED, 0, 1, nil)
    end
    Duel.Hint(HINT_SELECTMSG, tp, HINTMSG_ATOHAND)
    local g = Duel.SelectTarget(tp, s.thfilter, tp, LOCATION_REMOVED, 0, 1, 1, nil)
    Duel.SetOperationInfo(0, CATEGORY_TOHAND, g, 1, 0, 0)
end
function s.thop(e, tp, eg, ep, ev, re, r, rp)
    local tc = Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc, nil, REASON_EFFECT)
        Duel.ConfirmCards(1 - tp, tc)
    end
end
