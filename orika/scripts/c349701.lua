-- im@scgs - [一夜の煌きは永遠に] ナターリア
local s,id=GetID()
local SETCODE=0x2fd286a
local SHOE_ID=346002        -- 「im@scgs - 魔法の靴」
local NATALIA_ID=349401     -- 「im@scgs - ナターリア」
local FLAG_SHOE=id+1000     -- 靴でSSされたフラグ

-- 「名が記された」情報
s.imascgs_name_list={NATALIA_ID}

function s.initial_effect(c)
	--------------------------------
	-- エクシーズ召喚
	-- レベル4「im@scgs」モンスター×3
	--------------------------------
	c:EnableReviveLimit()
	aux.AddXyzProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,SETCODE),4,3)

	--------------------------------
	-- フィールド・墓地では「im@scgs - ナターリア」として扱う
	--------------------------------
	aux.AddCodeList(c,NATALIA_ID)
	aux.EnableChangeCode(c,NATALIA_ID,LOCATION_MZONE+LOCATION_GRAVE)

	--------------------------------
	-- ★①関連
	-- 靴の効果でSSされたときフラグを立てる（常在的な条件）
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e0:SetCode(EVENT_SPSUMMON_SUCCESS)
	e0:SetCondition(s.flagcon)
	e0:SetOperation(s.flagop)
	c:RegisterEffect(e0)

	-- ①：1ターンに1度、デッキ・墓地・除外から靴を素材にする
	--    「靴でSSされている場合のみ」使える常在型の起動効果
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_LEAVE_GRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1) -- 「1ターンに1度発動できる」（カード単位）
	e1:SetCondition(s.macon)
	e1:SetTarget(s.mattg)
	e1:SetOperation(s.matop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：戦闘破壊＋素材1枚でバーン
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DAMAGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCondition(s.damcon)
	e2:SetCost(s.damcost)
	e2:SetTarget(s.damtg)
	e2:SetOperation(s.damop)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③：除外されたとき、墓地の靴を1枚デッキに戻す
	--     （このカードの③の効果は1ターンに1度）
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TODECK)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.tdtg)
	e3:SetOperation(s.tdop)
	c:RegisterEffect(e3)
end

--------------------------------
-- ①：靴でSSされたかどうかをフラグで管理
--------------------------------
function s.flagcon(e,tp,eg,ep,ev,re,r,rp)
	-- 「im@scgs - 魔法の靴」の効果で特殊召喚されているか
	return re and re:GetHandler():IsCode(SHOE_ID)
end

function s.flagop(e,tp,eg,ep,ev,re,r,rp)
	-- 靴でSSされたフラグをアイツ自身に付ける
	e:GetHandler():RegisterFlagEffect(FLAG_SHOE,RESET_EVENT+RESETS_STANDARD,0,1)
end

-- ①が使えるかどうか（常在条件）
function s.macon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetFlagEffect(FLAG_SHOE)>0
end

-- 素材にする靴の候補（デッキ・墓地・除外）
function s.xyzmatfilter(c)
	if not c:IsCode(SHOE_ID) then return false end
	if c:IsLocation(LOCATION_REMOVED) and not c:IsFaceup() then return false end
	return c:IsLocation(LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsType(TYPE_XYZ)
			and Duel.IsExistingMatchingCard(s.xyzmatfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) or not c:IsType(TYPE_XYZ) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.xyzmatfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end
	Duel.Overlay(c,tc)
end

--------------------------------
-- ②：戦闘破壊＋素材1個でバーン
--------------------------------
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and bc~=nil and bc:IsLocation(LOCATION_GRAVE)
end

function s.damcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if chk==0 then return bc~=nil end
	local atk=bc:GetBaseAttack()
	if atk<0 then atk=0 end
	Duel.SetTargetCard(bc)
	Duel.SetTargetParam(atk)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,atk)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local bc=Duel.GetFirstTarget()
	if not bc or not bc:IsRelateToEffect(e) then return end
	local atk=bc:GetBaseAttack()
	if atk<0 then atk=0 end
	if atk>0 then
		Duel.Damage(1-tp,atk,REASON_EFFECT)
	end
end

--------------------------------
-- ③：除外されたとき、墓地の靴を1枚デッキに戻す
--------------------------------
function s.tdfilter(c)
	return c:IsCode(SHOE_ID) and c:IsAbleToDeck()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
