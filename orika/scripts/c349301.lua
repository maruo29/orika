-- アンディファインド・ヒストリー
local s,id=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--------------------------------
	-- このカードは除外されている場合「im@scgs」カードとして扱う
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_REMOVED)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SETCODE)
	c:RegisterEffect(e0)

	--------------------------------
	-- ①：相手フィールドの攻撃表示モンスターを全て破壊する
	-- （通常魔法としての発動効果）
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.destg1)
	e1:SetOperation(s.desop1)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：墓地のこのカードを除外して発動できる。
	--     フィールド上のフィールド魔法カードを全て破壊する。
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCost(s.descost2)
	e2:SetTarget(s.destg2)
	e2:SetOperation(s.desop2)
	c:RegisterEffect(e2)
end

--------------------------------
-- ①用：相手攻撃表示モンスター破壊
--------------------------------
function s.desfilter1(c)
	return c:IsFaceup() and c:IsAttackPos() and c:IsDestructable()
end
function s.destg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter1,tp,0,LOCATION_MZONE,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.desfilter1,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop1(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter1,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--------------------------------
-- ②用：コスト（墓地のこのカードを除外）
--------------------------------
function s.descost2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

--------------------------------
-- ②用：フィールド魔法全破壊
--------------------------------
function s.desfilter2(c)
	return c:IsType(TYPE_SPELL) and c:IsType(TYPE_FIELD) and c:IsDestructable()
end
function s.destg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.desfilter2,tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.desfilter2,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter2,tp,LOCATION_FZONE,LOCATION_FZONE,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
