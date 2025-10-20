-- im@scgs [ありすとワンダーランド] 橘ありす
local s,id=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」による特殊召喚

-- 魔法の靴の対象となるためのコードリンク
s.imascgs_name=346001

function s.initial_effect(c)
    -- このカード名はフィールド・墓地では「橘ありす」として扱う
    aux.EnableChangeCode(c,346001,LOCATION_MZONE+LOCATION_GRAVE)
    aux.AddCodeList(c,346001)
    
    Duel.EnableGlobalFlag(GLOBALFLAG_SPSUMMON_COUNT)

    --魔法の靴で特殊召喚されたというフラグを付けるためだけの処理。
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
    e0:SetCode(EVENT_SPSUMMON_SUCCESS)
    e0:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_SHOE) end)
    e0:SetOperation(function(e)
        e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
    end)
    c:RegisterEffect(e0)
    
    -- ① 魔法の靴でSSされた場合、EXからim@scgsモンスターを1体除外
    --上のe0だとフラグ処理が間に合わない可能性があるので、こちらは個別で「魔法の靴」でのSSかの管理。
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOHAND)
    e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetCondition(s.sscon)   -- ← ここを変更（フラグではなく直接判定）
    e1:SetTarget(s.thtg)
    e1:SetOperation(s.thop)
    c:RegisterEffect(e1)
    --1ターンに1度しか特殊召喚できない。
	--splimit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_SPSUMMON_CONDITION)
	e2:SetRange(LOCATION_EXTRA)
	e2:SetValue(s.splimit)
	c:RegisterEffect(e2)
	--indes
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)
	--spsummon count limit
    local e4=Effect.CreateEffect(c)
    e4:SetType(EFFECT_TYPE_FIELD)
    e4:SetCode(EFFECT_SPSUMMON_COUNT_LIMIT)
    e4:SetRange(LOCATION_MZONE)
    e4:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e4:SetTargetRange(1,1)
    e4:SetValue(1)
    e4:SetCondition(function(e) 
        return e:GetHandler():GetFlagEffect(id)>0
    end)
    c:RegisterEffect(e4)
    local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,{id,1})
	e5:SetCondition(s.rmcon)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)
end

-- 魔法の靴SS判定
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    -- Debug.Message(c:IsSummonType(SUMMON_TYPE_SHOE))
    return c:IsSummonType(SUMMON_TYPE_SHOE)
end


function s.thfilter(c)
	return c:IsCode(346002) and c:IsAbleToHand() -- 魔法の靴のカードID
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

function s.splimit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION
end

-- ③ 条件：相手ターンのエンドフェイズ
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end

function s.rmfilter(c)
	return c:IsSetCard(SETCODE) and c:IsAbleToHand()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end