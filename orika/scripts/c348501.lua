-- im@scgs - [愛の森でかくれんぼ] 関裕美
local s,id=GetID()
local SETCODE=0x2fd286a
local HIROMI_ID=346901      -- im@scgs - 関裕美
local SHOE_ID=346002        -- im@scgs - 魔法の靴
local COUNTER_HIROMI=0x1349 -- このカード専用のカウンター（適当なID）

function s.initial_effect(c)
	------------------------------------
	-- 基本設定
	------------------------------------
	-- このカードはフィールド・墓地に存在する限り「im@scgs - 関裕美」として扱う
	s.imascgs_name_list={HIROMI_ID}
	s.imascgs_name=HIROMI_ID
	aux.EnableChangeCode(c,HIROMI_ID,LOCATION_MZONE+LOCATION_GRAVE)
	aux.AddCodeList(c,HIROMI_ID)
	c:EnableReviveLimit()
	c:EnableCounterPermit(COUNTER_HIROMI)

	------------------------------------
	-- EXデッキからの特殊召喚条件
	-- 手札・フィールド上の「関裕美」と「魔法の靴」を
	-- それぞれ1枚ずつ除外した場合のみ特殊召喚できる
	------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop)
	c:RegisterEffect(e0)

	------------------------------------
	-- ①：特殊召喚成功時に除外ゾーンのim@scgs種類数だけカウンター
	------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)	-- ① 名称ターン1
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	------------------------------------
	-- ②：カウンター6個取り除いて相手モンスター1体破壊（クイック）
	------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	-- テキスト上、②は名称ターン1指定がないので CountLimit は付けない
	e2:SetCost(s.descost)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	------------------------------------
	-- ③：フィールドから破壊・除外された場合、墓地のim@scgs魔法・罠回収
	------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetCountLimit(1,{id,1}) -- ③ 名称ターン1
	e3:SetCondition(s.thcon3)
	e3:SetTarget(s.thtg3)
	e3:SetOperation(s.thop3)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EVENT_REMOVE)
	c:RegisterEffect(e4)
end

------------------------------------
-- EXデッキからの特殊召喚条件
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
	-- 手札・フィールドに「裕美」と「魔法の靴」がそれぞれ存在
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.spfilter_hiromi,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
		and Duel.IsExistingMatchingCard(s.spfilter_shoe,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	-- 「裕美」を選んで除外
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
-- ①：カウンターを置く
-- 除外されている「im@scgs」カードの種類数だけ
------------------------------------
function s.remfilter(c)
	return c:IsSetCard(SETCODE)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	local g=Duel.GetMatchingGroup(s.remfilter,tp,LOCATION_REMOVED,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	if ct>0 then
		c:AddCounter(COUNTER_HIROMI,ct)
	end
end

------------------------------------
-- ②：カウンター6つ取り除いて相手モンスター破壊
------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsCanRemoveCounter(tp,COUNTER_HIROMI,6,REASON_COST)
	end
	c:RemoveCounter(tp,COUNTER_HIROMI,6,REASON_COST)
end

function s.desfilter(c,tp)
	return c:IsOnField() and c:IsControler(1-tp) and c:IsType(TYPE_MONSTER)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_MONSTER)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.desfilter,tp,0,LOCATION_MZONE,1,nil,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,s.desfilter,tp,0,LOCATION_MZONE,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

------------------------------------
-- ③：破壊・除外されたときに墓地のim@scgs魔法・罠を回収
------------------------------------
function s.thcon3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- フィールドから離れて破壊 or 除外された場合
	return c:IsPreviousLocation(LOCATION_MZONE)
end

function s.thfilter3(c)
	return c:IsSetCard(SETCODE)
		and c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsAbleToHand()
end

function s.thtg3(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and chkc:IsControler(tp)
			and s.thfilter3(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.thfilter3,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter3,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
