-- 346プロプロデューサー - 武内P
local s,id,o=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000

function s.initial_effect(c)
	-- ペンデュラム属性
	aux.EnablePendulumAttribute(c)

	-- P効果 ① EXデッキ除外で発動
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id) -- P効果1ターン1回
	e1:SetTarget(s.pentg)
	e1:SetOperation(s.penop)
	c:RegisterEffect(e1)

	-- モンスター効果 ルール上「im@scgs」として扱う
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_ADD_SETCODE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(SETCODE)
	c:RegisterEffect(e2)

	-- モンスター効果 ① 召喚成功時にデッキ除外
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.montg1)
	e3:SetOperation(s.monop1)
	c:RegisterEffect(e3)

	-- モンスター効果 ② 手札から捨てて発動
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_HAND)
	e4:SetCountLimit(1,{id,2})
	e4:SetCost(s.moncost2)
	e4:SetTarget(s.montg2)
	e4:SetOperation(s.monop2)
	c:RegisterEffect(e4)
end

-- ==========================
-- P効果① EXデッキ除外
-- ==========================
function s.penfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end
function s.penfilter2(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end

function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
end

function s.penop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local excard=g:GetFirst()
	if not excard or Duel.Remove(excard,POS_FACEUP,REASON_EFFECT)==0 then return end
	if c:IsRelateToEffect(e) then
		Duel.Remove(c,POS_FACEUP,REASON_EFFECT)
	end
	-- 除外したカードがPモンスターならデッキから手札に加える
	if excard:IsType(TYPE_PENDULUM) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g2=Duel.SelectMatchingCard(tp,s.penfilter2,tp,LOCATION_DECK,0,1,1,nil,SETCODE)
		if #g2>0 then
			Duel.SendtoHand(g2,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g2)
		end
	end
end

-- ==========================
-- モンスター効果① 召喚成功時デッキ除外
-- ==========================
function s.monfilter1(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end

function s.montg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.monfilter1,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end

function s.monop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.monfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end

-- ==========================
-- モンスター効果② 手札から捨てて魔法の靴を手札に加える
-- ==========================
function s.moncost2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end

function s.monfilter2(c)
	return c:IsCode(346002) and c:IsAbleToHand()
end

function s.montg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.monfilter2,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.monop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.monfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
