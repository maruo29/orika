-- im@scgs [笑顔のカーテンコール] 島村卯月
local s,id,o=GetID()
local SETCODE=0x2fd286a
local UZUKI_ID=348101
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000

------------------------------------------------------------
-- ■ 共通：imascgs_name_list / imascgs_name を参照する関数
------------------------------------------------------------
function s.get_name_list(c)
	if not c then return nil end
	local mt=_G["c"..c:GetOriginalCode()]
	if not mt then return nil end

	if mt.imascgs_name_list then
		return mt.imascgs_name_list
	end
	if mt.imascgs_name then
		return {mt.imascgs_name}
	end
	return nil
end

function s.has_name(c,tcode)
	local list=s.get_name_list(c)
	if not list then return false end
	for _,v in ipairs(list) do
		if v==tcode then return true end
	end
	return false
end

------------------------------------------------------------
-- ■ 魔法の靴①効果互換（手札限定）に必要なフィルタ
------------------------------------------------------------
-- 除外する候補（フィールドのim@scgs）
function s.shoe_rmfilter(c,e,tp)
	local code=c:GetCode()
	return c:IsFaceup() and c:IsSetCard(SETCODE)
		and Duel.GetMZoneCount(tp,c)>0
		and Duel.IsExistingMatchingCard(s.shoe_spfilter,tp,LOCATION_HAND,0,1,nil,e,tp,code)
		and c:IsAbleToRemove()
end

-- 手札から「名が記された」モンスターをSS
function s.shoe_spfilter(c,e,tp,code)
	return c:IsSetCard(SETCODE)
		and c:IsType(TYPE_MONSTER)
		and s.has_name(c,code)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SHOE,tp,true,false)
end

------------------------------------------------------------
-- ■ メイン効果
------------------------------------------------------------
function s.initial_effect(c)
	--------------------------------------------------------
	-- リンク召喚
	--------------------------------------------------------
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,SETCODE),1,1)

	-- このカードは卯月として扱う
	s.imascgs_name_list={UZUKI_ID}
	aux.EnableChangeCode(c,UZUKI_ID,LOCATION_MZONE+LOCATION_GRAVE)
	aux.AddCodeList(c,UZUKI_ID)

	-- リンク素材にできない
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e0:SetValue(1)
	c:RegisterEffect(e0)

	--------------------------------------------------------
	-- ①：通常モンスターを素材にリンク召喚 → 永続魔法化
	--------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.lkcon)
	e1:SetTarget(s.lktg)
	e1:SetOperation(s.lkop)
	c:RegisterEffect(e1)

	-- MATERIAL_CHECK
	local eMC=Effect.CreateEffect(c)
	eMC:SetType(EFFECT_TYPE_SINGLE)
	eMC:SetCode(EFFECT_MATERIAL_CHECK)
	eMC:SetLabelObject(e1)
	eMC:SetValue(s.mcheck)
	c:RegisterEffect(eMC)

	--------------------------------------------------------
	-- ②：クイック効果（魔法の靴①を内蔵／手札限定SS）
	--------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	-- e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END) -- ★ここを削除★
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.shoetg)
	e2:SetOperation(s.shoeop)
	c:RegisterEffect(e2)

	--------------------------------------------------------
	-- ③：靴SSされた時に別属性サーチ
	--------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

------------------------------------------------------------
-- ① 通常モンスターを素材にしたリンク召喚か？
------------------------------------------------------------
function s.normfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_NORMAL)
end
function s.mcheck(e,c)
	local g=c:GetMaterial()
	if g:IsExists(s.normfilter,1,nil) then
		e:GetLabelObject():SetLabel(1)
	else
		e:GetLabelObject():SetLabel(0)
	end
end
function s.lkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetLabel()==1 and e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

-- 永続魔法化可能な im@scgs
function s.setfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end

function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil)
	end
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		tc:RegisterEffect(e1)
	end
end

------------------------------------------------------------
-- ② 魔法の靴①内蔵（手札のみSS）
------------------------------------------------------------
function s.shoetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.shoe_rmfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_MZONE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.shoeop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	-- 除外するモンスター選択
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,s.shoe_rmfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	local rc=rg:GetFirst()
	if not rc then return end
	local tcode=rc:GetCode()

	if Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)==0 then return end

	-- 手札限定SS
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.shoe_spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,tcode)
	local sc=sg:GetFirst()
	if not sc then return end

	if Duel.SpecialSummon(sc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end

------------------------------------------------------------
-- ③ 靴SSされた時に別属性サーチ
------------------------------------------------------------
function s.shoe_summoned(c,tp)
	return c:IsSetCard(SETCODE)
		and c:IsSummonPlayer(tp)
		and c:IsSummonType(SUMMON_TYPE_SHOE)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.shoe_summoned,1,nil,tp)
end

function s.thfilter(c,attr)
	return c:IsSetCard(SETCODE)
		and c:IsType(TYPE_MONSTER)
		and not c:IsAttribute(attr)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local sc=eg:Filter(s.shoe_summoned,nil,tp):GetFirst()
	local attr=sc:GetAttribute()
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,attr) end
	e:SetLabel(attr)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local attr=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,attr)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
