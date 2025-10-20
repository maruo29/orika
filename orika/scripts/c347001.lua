-- 346プロアシスタント - 千川ちひろ
local s,id,o=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」扱い特殊召喚
local STAGE_CODE=346701 -- ステージのカードコード

function s.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	------------------------------------------------------------
	--① このカードを破壊して発動できる：デッキから「im@scgs」Pモンスター1体をPゾーンに置く。
	------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_PZONE)
	e3:SetTarget(s.pentg)
	e3:SetOperation(s.penop)
	c:RegisterEffect(e3)
	------------------------------------------------------------
	--② このカードが表側表示で存在する限り、「im@scgs」カードは１ターンに１度だけ、対象を取らない効果では破壊されない。
	------------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e4:SetRange(LOCATION_PZONE)
	e4:SetTargetRange(LOCATION_ONFIELD,0)
	e4:SetTarget(function(e,c) return c:IsSetCard(SETCODE) and not c:IsCode(id) end)
	e4:SetValue(s.indct)
	e4:SetCountLimit(1)
	c:RegisterEffect(e4)
	------------------------------------------------------------
	--③ 召喚成功時：通常モンスターを公開して除外 → 対応モンスターを「魔法の靴」扱いでSS
	------------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,0})
	e1:SetCost(s.discost)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)
	------------------------------------------------------------
	--④ 除外された場合：「im@scgs - スターライトステージ」を魔法＆罠ゾーンに表側で置く
	------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.target2)
	e2:SetOperation(s.activate2)
	c:RegisterEffect(e2)
end

------------------------------------------------------------
--①：デッキからPモンスターをPゾーンに置く
------------------------------------------------------------
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.penfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_PENDULUM) and not c:IsCode(id) and not c:IsForbidden()
end
function s.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDestructable()
		and Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
end
function s.penop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Destroy(e:GetHandler(),REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_DECK,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
		end
	end
end

------------------------------------------------------------
--②：対象を取らない効果による破壊を1ターンに1度だけ防ぐ
------------------------------------------------------------
function s.indct(e,re,r,rp)
	return bit.band(r,REASON_EFFECT)~=0 and not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
end

------------------------------------------------------------
--③：通常モンスターを公開して除外 → 対応モンスターを「魔法の靴」扱いでSS
------------------------------------------------------------
function s.filter1(c,e,tp)
	local code=c:GetCode()
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_NORMAL)
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK,0,1,nil,e,tp,code)
end
function s.filter2(c,e,tp,tcode)
	return c.imascgs_name==tcode and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SHOE,tp,true,false)
end

function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	-- 通常モンスターを公開して除外
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	local tc1=g1:GetFirst()
	if not tc1 then return end
	Duel.ConfirmCards(1-tp,tc1)
	if Duel.Remove(tc1,POS_FACEUP,REASON_EFFECT)==0 then return end

	-- 対応モンスターを魔法の靴扱いで特殊召喚
	local code=tc1:GetCode()
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g2=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_DECK,0,1,1,nil,e,tp,code)
	local tc2=g2:GetFirst()
	if tc2 and Duel.SpecialSummon(tc2,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)>0 then
		tc2:CompleteProcedure()
	end
end

------------------------------------------------------------
--④：除外時、「スターライトステージ」を魔法＆罠ゾーンに置く
------------------------------------------------------------
function s.stagefilter(c)
	return c:IsCode(STAGE_CODE) and not c:IsForbidden()
end
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.stagefilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.stagefilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	-- フィールド魔法として扱う場合
	if tc:IsType(TYPE_FIELD) then
		-- 既存のフィールド魔法を破壊
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then Duel.Destroy(fc,REASON_RULE) end
		-- フィールドゾーンに置く
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
	else
		-- 通常の魔法・罠カードはSZONE
		local seq=0
		if Duel.CheckLocation(tp,LOCATION_SZONE,0) then
			seq=0
		elseif Duel.CheckLocation(tp,LOCATION_SZONE,1) then
			seq=1
		else
			return
		end
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true,seq)
	end
end