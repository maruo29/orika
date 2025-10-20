-- im@scgs [ミューズ・オン・ユー]橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」による特殊召喚
local FLAG_SET=id+2000  -- 手札からS/Tをセット済みフラグ

-- 魔法の靴の対象となるためのコードリンク
s.imascgs_name=346001

function s.initial_effect(c)
    -- このカード名はフィールド・墓地では「橘ありす」として扱う
    aux.EnableChangeCode(c,346001,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,346001)

    --魔法の靴で特殊召喚されたというフラグを付けるためだけの処理。
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)  -- 継続効果
    e0:SetCode(EVENT_SPSUMMON_SUCCESS)                     -- SS成功時
    e0:SetCondition(s.sscon)
    e0:SetOperation(s.flgop)
    c:RegisterEffect(e0)
    

    -- ① 魔法の靴でSSされた場合、EXからim@scgsモンスターを1体除外
    --上のe0だとフラグ処理が間に合わない可能性があるので、こちらは個別で「魔法の靴」でのSSかの管理。
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.sscon)   -- ← ここを変更（フラグではなく直接判定）
    e1:SetTarget(s.rmtg)
    e1:SetOperation(s.rmop)
    c:RegisterEffect(e1)

    -- ② モンスターゾーンに存在する限り、1ターン1枚のS/Tセット制限
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
    e2:SetCode(EFFECT_CANNOT_SSET)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCondition(s.setcon1)
    e2:SetTarget(s.settg)
    e2:SetTargetRange(1,0)
    c:RegisterEffect(e2)

    local e3=e2:Clone()
    e3:SetTargetRange(0,1)
    e3:SetCondition(s.setcon2)
    c:RegisterEffect(e3)

    -- ③ モンスターゾーンに存在する限り、EXからSSされたモンスターはそのターン攻撃できない
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_CANNOT_ATTACK)
    e4:SetRange(LOCATION_MZONE)
    e4:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e4:SetTarget(s.attg)
    c:RegisterEffect(e4)

    -- ④ 除外された場合、除外中のim@scgsモンスター1体を手札に加える
    local e5=Effect.CreateEffect(c)
    e5:SetDescription(aux.Stringid(id,2))
    e5:SetCategory(CATEGORY_TOHAND)
    e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e5:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e5:SetCode(EVENT_REMOVE)
    e5:SetCountLimit(1,id+100)
    e5:SetTarget(s.thtg)
    e5:SetOperation(s.thop)
    c:RegisterEffect(e5)

    -- 1ターン1枚セットフラグ管理
    if not s.global_check then
        s.global_check=true
        local ge1=Effect.CreateEffect(c)
        ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        ge1:SetCode(EVENT_SSET)
        ge1:SetOperation(s.checkop)
        Duel.RegisterEffect(ge1,0)
    end
end

-- 魔法の靴SS判定
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Debug.Message(c:IsSummonType(SUMMON_TYPE_SHOE))
    return c:IsSummonType(SUMMON_TYPE_SHOE)
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:GetFlagEffect(FLAG_SHOE)>0
end

function s.rmfilter(c)
    return c:IsType(TYPE_MONSTER) and c:IsSetCard(SETCODE) and c:IsAbleToRemove()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_EXTRA,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_EXTRA)
end

function s.flgop(e,tp,eg,ep,ev,re,r,rp)
    e:GetHandler():RegisterFlagEffect(FLAG_SHOE,RESET_EVENT+RESETS_STANDARD,0,1)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_EXTRA,0,1,1,nil)
    if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 then
    end
end

-- 1ターン1枚S/Tセットフラグ管理
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
    if eg:IsExists(Card.IsPreviousLocation,1,nil,LOCATION_HAND) then
        Duel.RegisterFlagEffect(rp,FLAG_SET,RESET_PHASE+PHASE_END,0,1)
    end
end

-- S/Tセット制限：モンスターゾーンに存在する間
function s.setcon1(e)
    local c=e:GetHandler()
    return c:IsLocation(LOCATION_MZONE) and c:GetFlagEffect(FLAG_SHOE)>0 and Duel.GetFlagEffect(c:GetControler(),FLAG_SET)>0
end
function s.setcon2(e)
    local c=e:GetHandler()
    return c:IsLocation(LOCATION_MZONE) and c:GetFlagEffect(FLAG_SHOE)>0 and Duel.GetFlagEffect(1-c:GetControler(),FLAG_SET)>0
end
function s.settg(e,c)
    return c:IsLocation(LOCATION_HAND)
end

-- EXからSSされたモンスターはそのターン攻撃不可（モンスターゾーン限定）
function s.attg(e,c)
    return c:IsStatus(STATUS_SPSUMMON_TURN) and c:IsSummonLocation(LOCATION_EXTRA)
end

-- 除外時のサルベージ処理
function s.thfilter(c)
    return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsSetCard(SETCODE) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,tc)
    end
end
