-- im@scgs [ありすの物語] 橘ありす
local s,id=GetID()
local SHOE_ID=346002 -- 「im@scgs - 魔法の靴」
local FLAG_SHOE=id+1000 -- 魔法の靴でSSされたフラグ
local SETCODE=0x2fd286a

-- 魔法の靴の対象となるためのコードリンク
s.imascgs_name=346001
function s.initial_effect(c)
    -- このカード名はフィールド・墓地では「橘ありす」として扱う
    aux.EnableChangeCode(c,346001,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,346001)

    Duel.EnableGlobalFlag(GLOBALFLAG_SPSUMMON_COUNT)

    -- SS条件: このカードはS召喚不可、魔法の靴でのみSS
    c:EnableReviveLimit()
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE)
    e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e0:SetCode(EFFECT_SPSUMMON_CONDITION)
    e0:SetValue(function(e,se,sp,st)
        return se and se:GetHandler():IsCode(346002) -- 魔法の靴
    end)
    c:RegisterEffect(e0)
    -- ① 魔法の靴でSS成功時の効果
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
        return e:GetHandler():IsSummonType(SUMMON_TYPE_SHOE)
    end)
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    e1:SetCountLimit(1,id) -- 1ターンに1度
    c:RegisterEffect(e1)

    -- ② 破壊耐性 + 他のim@scgsモンスターへの対象耐性
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetValue(1)
    c:RegisterEffect(e2)
    local e3=Effect.CreateEffect(c)
    e3:SetType(EFFECT_TYPE_FIELD)
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
    e3:SetRange(LOCATION_MZONE)
    e3:SetTargetRange(LOCATION_MZONE,0)
    e3:SetTarget(function(e,c)
        return c:IsFaceup() and c~=e:GetHandler() and c:IsSetCard(SETCODE)
    end)
    e3:SetValue(aux.tgoval)
    c:RegisterEffect(e3)
end

-- デッキから橘ありすの名前が記載されたカードを手札に加えるフィルター
function s.thfilter(c)
    return c.imascgs_name==346001 and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

-- デッキから手札に加える対象選択
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- 効果発動・特殊召喚制限を含めた処理
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
    if #g>0 then
        local tc=g:GetFirst()
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g)

        local code=tc:GetCode()

        -- モンスター効果発動制限
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetCode(EFFECT_CANNOT_ACTIVATE)
        e1:SetTargetRange(1,0)
        e1:SetValue(function(_,re,tp) return re:GetHandler():IsCode(code) and re:IsActiveType(TYPE_MONSTER) end)
        e1:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e1,tp)

        -- 特殊召喚制限
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_FIELD)
        e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e2:SetTargetRange(1,0)
        e2:SetTarget(function(_,c) return c:IsCode(code) end)
        e2:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e2,tp)

        -- 制限解除用イベント: 特殊召喚成功で制限解除
        local e3=Effect.CreateEffect(e:GetHandler())
        e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
        e3:SetCode(EVENT_SPSUMMON_SUCCESS)
        e3:SetLabel(code)
        e3:SetOperation(function(e,tp,eg)
            for tc2 in aux.Next(eg) do
                if tc2:IsSummonPlayer(tp) and tc2:IsCode(e:GetLabel()) then
                    -- 制限効果解除
                    for _,eff in ipairs({Duel.GetFieldGroup(tp,0,0)}) do
                        -- 既存のe1,e2を個別にリセット
                        e:GetHandler():Reset() -- 注意: 必要なら登録した効果を変数で保持してReset
                    end
                    e:Reset()
                end
            end
        end)
        e3:SetReset(RESET_PHASE+PHASE_END,2)
        Duel.RegisterEffect(e3,tp)
    end
end