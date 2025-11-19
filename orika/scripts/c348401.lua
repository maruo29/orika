-- im@scgs [忘失のローズルージュ] 関裕美
local s,id=GetID()
local SETCODE=0x2fd286a
local HIROMI_ID=346901      -- im@scgs - 関裕美
local SHOE_ID=346002        -- im@scgs - 魔法の靴

function s.initial_effect(c)
	------------------------------------
	-- このカードはフィールド・墓地に存在する限り「im@scgs - 関裕美」として扱う
	------------------------------------
	s.imascgs_name_list={HIROMI_ID}
	s.imascgs_name=HIROMI_ID
	aux.EnableChangeCode(c,HIROMI_ID,LOCATION_MZONE+LOCATION_GRAVE)
	aux.AddCodeList(c,HIROMI_ID)
	c:EnableReviveLimit()

	------------------------------------
	-- 手札からの特殊召喚手順
	-- 「im@scgs - 関裕美」＋「im@scgs - 魔法の靴」を
	-- 手札・フィールドからそれぞれ1枚ずつ除外
	------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	------------------------------------
	-- ① 自分の「im@scgs」魔法・罠を相手効果から守る
	------------------------------------
	-- 対象耐性
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetRange(LOCATION_MZONE+LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetTargetRange(LOCATION_SZONE,0)
	e1:SetCondition(s.protcon)
	e1:SetTarget(s.prottg)
	e1:SetValue(s.tgval)
	c:RegisterEffect(e1)
	-- 効果破壊耐性
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_MZONE+LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetCondition(s.protcon)
	e2:SetTarget(s.prottg)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)

	------------------------------------
	-- ② 破壊・除外された場合、永続魔法として置く（名称ターン1）
	------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.sztg)
	e3:SetOperation(s.szop)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e4)
end

------------------------------------
-- 手札からの特殊召喚条件・処理
------------------------------------
function s.spfilter_hiromi(c)
	return c:IsCode(HIROMI_ID) and c:IsAbleToRemoveAsCost()
end
function s.spfilter_shoe(c)
	return c:IsCode(SHOE_ID) and c:IsAbleToRemoveAsCost()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	-- モンスターゾーンに空き ＋
	-- 「関裕美」1枚 ＋ 「魔法の靴」1枚 を用意できるか
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter_hiromi,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter_shoe,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	-- 「関裕美」を選んで除外
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g1=Duel.SelectMatchingCard(tp,s.spfilter_hiromi,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	-- 「魔法の靴」を選んで除外
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectMatchingCard(tp,s.spfilter_shoe,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	g1:Merge(g2)
	Duel.Remove(g1,POS_FACEUP,REASON_COST)
	c:SetMaterial(g1)
end

------------------------------------
-- ① 保護効果の条件・対象・値
------------------------------------
-- このカードが表側で存在する間のみ
function s.protcon(e)
	local c=e:GetHandler()
	return c:IsFaceup()
end

-- 守る対象：このカード以外の自分フィールド上の「im@scgs」魔法・罠
function s.prottg(e,c)
	return c~=e:GetHandler()
		and c:IsSetCard(SETCODE)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
end

-- 対象耐性：相手の効果のみ弾く
function s.tgval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

-- 効果破壊耐性：相手の効果のみ弾く
function s.indval(e,re,rp)
	return rp~=e:GetHandlerPlayer()
end

------------------------------------
-- ② フィールドから破壊・除外されたときに永続魔法化
------------------------------------
function s.sztg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- フィールドから離れていること（破壊／除外時）
		return c:IsPreviousLocation(LOCATION_ONFIELD)
			and Duel.GetLocationCount(tp,LOCATION_SZONE)>0
	end
end

function s.szop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
		-- 永続魔法カード扱いに変更
		local e1=Effect.CreateEffect(c)
		e1:SetCode(EFFECT_CHANGE_TYPE)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD-RESET_TURN_SET)
		e1:SetValue(TYPE_SPELL+TYPE_CONTINUOUS)
		c:RegisterEffect(e1)
	end
end
