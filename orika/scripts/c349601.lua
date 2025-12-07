-- im@scgs - 皆既日食の誓い
local s,id=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--------------------------------
	-- 共通：除外中は「im@scgs」カードとして扱う
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_REMOVED)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SETCODE)
	c:RegisterEffect(e0)

	--------------------------------
	-- 発動（永続罠）
	--------------------------------
	local eAct=Effect.CreateEffect(c)
	eAct:SetType(EFFECT_TYPE_ACTIVATE)
	eAct:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(eAct)

	--------------------------------
	-- ①：水属性 im@scgs がSSされたときデッキから
	--     光属性 im@scgs をサーチ＋その後召喚
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)  -- このカードの①の効果は1ターンに1度
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：光属性 im@scgs がSSされたとき、
	--     手札の水属性 im@scgs を除外して
	--     相手モンスター1体の効果をエンドフェイズまで無効
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+1) -- このカードの②の効果は1ターンに1度
	e2:SetCondition(s.discon)
	e2:SetCost(s.discost)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③：このカードが除外された次の自分スタンバイフェイズに
	--     自分フィールドに表側で戻す
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)
end

--------------------------------
-- ①用：水属性 im@scgs が自分フィールドにSSされたか
--------------------------------
function s.cfilter_water(c,tp)
	return c:IsFaceup() and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(SETCODE)
		and c:IsAttribute(ATTRIBUTE_WATER)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_water,1,nil,tp)
end

function s.thfilter(c)
	return c:IsSetCard(SETCODE)
		and c:IsAttribute(ATTRIBUTE_LIGHT)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToHand()
end

function s.nsfilter(c)
	return c:IsSetCard(SETCODE)
		and c:IsAttribute(ATTRIBUTE_LIGHT)
		and c:IsType(TYPE_MONSTER)
		and c:IsSummonable(true,nil)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	-- デッキから光属性im@scgsモンスター1体サーチ
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g==0 then return end
	if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
	Duel.ConfirmCards(1-tp,g)

	-- その後、手札から光属性im@scgsモンスター1体の召喚を行う（可能なら）
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
	local tc=sg:GetFirst()
	if tc then
		Duel.Summon(tp,tc,true,nil)
	end
end

--------------------------------
-- ②用：光属性 im@scgs が自分フィールドにSSされたか
--------------------------------
function s.cfilter_light(c,tp)
	return c:IsFaceup() and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsSetCard(SETCODE)
		and c:IsAttribute(ATTRIBUTE_LIGHT)
end

function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter_light,1,nil,tp)
end

-- 手札の水属性im@scgs1体を除外するコスト
function s.costfilter(c)
	return c:IsSetCard(SETCODE)
		and c:IsAttribute(ATTRIBUTE_WATER)
		and c:IsType(TYPE_MONSTER)
		and c:IsAbleToRemoveAsCost()
end

function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

-- 相手フィールドのモンスター1体を対象にして、その効果をエンドフェイズまで無効
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsFaceup() end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,0,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end

	-- 効果をエンドフェイズまで無効
	Duel.NegateRelatedChain(tc,RESET_TURN_SET)

	local c=e:GetHandler()
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
-- ③用：除外された次の自分スタンバイフェイズに戻る
--------------------------------
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsLocation(LOCATION_REMOVED) or not c:IsFaceup() then return end
	-- 次の自分スタンバイフェイズにトリガーする効果をセット
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_REMOVED)
	e1:SetCountLimit(1)
	e1:SetLabel(Duel.GetTurnCount())
	e1:SetCondition(s.retcon)
	e1:SetTarget(s.rettg)
	e1:SetOperation(s.retop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_STANDBY)
	c:RegisterEffect(e1)
end

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	-- 「除外されたターンのスタンバイフェイズ」はスキップして、
	-- その次の自分のスタンバイフェイズのみ
	return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()~=e:GetLabel()
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
end
