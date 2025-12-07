-- im@scgs [瞳のトゥインクル] 関裕美
local s,id=GetID()
local SETCODE=0x2fd286a
local HIROMI_ID=346901      -- im@scgs - 関裕美
local SHOE_ID=346002        -- im@scgs - 魔法の靴

function s.initial_effect(c)
	------------------------------------
	-- 基本設定
	------------------------------------
	-- このカードはフィールド・墓地に存在する限り、「im@scgs - 関裕美」として扱う
	s.imascgs_name_list={HIROMI_ID}
	s.imascgs_name=HIROMI_ID
	aux.EnableChangeCode(c,HIROMI_ID,LOCATION_MZONE+LOCATION_GRAVE)
	aux.AddCodeList(c,HIROMI_ID)

	------------------------------------
	-- ① 手札から永続魔法化
	-- 手札から「im@scgs - 魔法の靴」を見せて発動
	------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)           -- ① 名称ターン1
	e1:SetCost(s.cost1)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)

	------------------------------------
	-- ② 永続魔法扱いのとき、自分im@scgsモンスター強化
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetCondition(s.atkcon)
	e2:SetTarget(s.atktg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	------------------------------------
	-- ③ 永続魔法扱いのとき、自分メインフェイズに自己SS
	------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,1}) -- ③ 名称ターン1
	e3:SetCondition(s.spcon3)
	e3:SetTarget(s.sptg3)
	e3:SetOperation(s.spop3)
	c:RegisterEffect(e3)
end

------------------------------------
-- ① コスト：「魔法の靴」を手札から見せる
------------------------------------
function s.cfilter1(c)
	return c:IsCode(SHOE_ID) and not c:IsPublic()
end
function s.cost1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.cfilter1,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.cfilter1,tp,LOCATION_HAND,0,1,1,nil)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end

------------------------------------
-- ① 対象：Sゾーンに空きがあるか
--   （千年の眠りから覚めし原人の①と同じ形）
------------------------------------
function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
end

------------------------------------
-- ① 処理：永続魔法カード扱いで置く
--   （千年の眠りから覚めし原人の operation をほぼそのまま）
------------------------------------
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
		local e1=Effect.CreateEffect(c)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		c:RegisterEffect(e1)
	end
end


------------------------------------
-- ② ATKアップ条件 & 対象 & 値
------------------------------------
-- このカードが永続魔法カード扱い（表側）で存在するか
function s.is_cont_spell(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL) and c:IsType(TYPE_CONTINUOUS)
end

function s.atkcon(e)
	local c=e:GetHandler()
	return s.is_cont_spell(c)
end

function s.atktg(e,c)
	return c:IsFaceup() and c:IsSetCard(SETCODE)
end

-- フィールド上のim@scgsカードの「種類数」×100
function s.fieldsetfilter(c)
	return c:IsSetCard(SETCODE)
end

function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.fieldsetfilter,0,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	local ct=g:GetClassCount(Card.GetCode)
	return ct*100
end

------------------------------------
-- ③ 自己特殊召喚
------------------------------------
function s.spcon3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return s.is_cont_spell(c) and Duel.IsMainPhase() and Duel.GetTurnPlayer()==tp
end

function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end
