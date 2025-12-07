-- im@scgs - 思い出のアルバム
local s,id=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--------------------------------
	-- ① 発動：デッキ差分を除外＋条件付きサーチ
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- このカード名の①は1ターンに1度
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 墓地効果：通常召喚1回追加（im@scgs限定）
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1}) -- このカード名の②は1ターンに1度
	e2:SetCost(s.extracost)
	e2:SetOperation(s.extraop)
	c:RegisterEffect(e2)
end

---------------------------------------------------
-- ① 条件：自分デッキ > 相手デッキ（隣の芝刈りと同じ）
---------------------------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)
end

---------------------------------------------------
-- ① 対象設定
---------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)-Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)
	if chk==0 then return ct>0 and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=ct end
	-- 「隣の芝刈り」はデッキデスなので CATEGORY_DECKDES だったが、
	-- こちらは除外なので CATEGORY_REMOVE を指定
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,tp,LOCATION_DECK)
end

---------------------------------------------------
-- ① 処理：デッキトップ除外 → 条件達成ならサーチ → 発動制限付与
---------------------------------------------------
function s.rmfilter(c)
	return c:IsSetCard(SETCODE)
end
function s.thfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_NORMAL) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)-Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)
	if ct<=0 then return end
	-- デッキトップからその差分を除外する
	if Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)<ct then return end
	local g=Duel.GetDecktopGroup(tp,ct)
	Duel.DisableShuffleCheck()
	if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)==0 then return end

	-- 除外されている「im@scgs」カードが10種類以上ならサーチ
	local rg=Duel.GetMatchingGroup(s.rmfilter,tp,LOCATION_REMOVED,0,nil)
	local kind=rg:GetClassCount(Card.GetCode)
	if kind>=10 and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) then
		if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local sg=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
			if #sg>0 then
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end

	-- このターン、自分は「im@scgs」モンスター以外のモンスター効果を発動できない
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- モンスター効果で、かつim@scgsモンスター以外なら発動不可
function s.aclimit(e,re,tp)
	if not re:IsActiveType(TYPE_MONSTER) then return false end
	local rc=re:GetHandler()
	return not rc:IsSetCard(SETCODE)
end

---------------------------------------------------
-- ② コスト：墓地のこのカードを除外
---------------------------------------------------
function s.extracost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemoveAsCost() end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

---------------------------------------------------
-- ② 処理：im@scgsモンスターにだけ追加通常召喚権付与
---------------------------------------------------
function s.extfilter(c)
	return c:IsSetCard(SETCODE)
end
function s.extraop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- このターン中、im@scgsモンスターにだけ追加通常召喚を許可
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(function(e,c) return c:IsSetCard(SETCODE) end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
