-- im@scgs - ライラ＆ナターリア
local s,id=GetID()
local SETCODE=0x2fd286a

local LAILA_ID     = 349501    -- 「im@scgs - ライラ」
local NATALIA_ID   = 349401    -- 「im@scgs - ナターリア」
local LAILA_NAT_ID = 349201    -- 「im@scgs - ライラ＆ナターリア」自身（必要なら参照用）

--------------------------------
-- 「名が記された」共通ヘルパ
--------------------------------
-- スクリプトテーブルから imascgs_name_list を取得
function s.get_name_list(c)
	if not c then return nil end
	local code=c:GetOriginalCode()
	local mt=_G["c"..code]
	if mt and mt.imascgs_name_list then
		return mt.imascgs_name_list
	end
	-- 後方互換：昔の "s.imascgs_name = xxx" 形式にも対応
	if mt and mt.imascgs_name then
		return {mt.imascgs_name}
	end
	return nil
end

-- カード c が「tcode の名が記されたカード」かどうか
function s.has_name(c,tcode)
	local list=s.get_name_list(c)
	if not list then return false end
	for _,v in ipairs(list) do
		if v==tcode then return true end
	end
	return false
end

-- このカードの名義情報（ライラ＆ナターリア両名義を持つ）
s.imascgs_name_list={LAILA_ID,NATALIA_ID}

function s.initial_effect(c)
	--------------------------------
	-- リンク召喚
	--------------------------------
	c:EnableReviveLimit()
	-- 「im@scgs」モンスター2体
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,SETCODE),2,2)

	--------------------------------
	-- フィールド・墓地では「im@scgs - ライラ」として扱う（基本）
	--------------------------------
	aux.AddCodeList(c,LAILA_ID)
	aux.AddCodeList(c,NATALIA_ID)
	aux.EnableChangeCode(c,LAILA_ID,LOCATION_MZONE+LOCATION_GRAVE)

	--------------------------------
	-- ①：1ターンに1度、以下1つを選択
	-- ● 手札1枚除外して1ドローし、このカードを「ライラ」として扱う。
	-- ● 攻撃力500アップし、このカードを「ナターリア」として扱う。
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DRAW+CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id) -- このカード名の①の効果は1ターンに1度
	e1:SetTarget(s.e1tg)
	e1:SetOperation(s.e1op)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：このカードが墓地へ送られた場合、
	--     自身を除外し、ナターリア名義カードをサーチ
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+1) -- このカード名の②の効果は1ターンに1度
	e2:SetTarget(s.e2tg)
	e2:SetOperation(s.e2op)
	c:RegisterEffect(e2)
end

--------------------------------
-- ① ターゲット処理：どちらのモードを選ぶか
--------------------------------
function s.rmfilter_hand(c)
	return c:IsAbleToRemove()
end

function s.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	-- ●手札1枚除外＋1ドロー（＋ライラ扱い）
	local b1=Duel.IsExistingMatchingCard(s.rmfilter_hand,tp,LOCATION_HAND,0,1,nil)
		and Duel.IsPlayerCanDraw(tp,1)
	-- ●攻撃力500アップ（＋ナターリア扱い）
	local b2=c:IsFaceup()

	if chk==0 then return b1 or b2 end

	local ops={}
	local opval={}
	local off=1
	if b1 then
		ops[off]=aux.Stringid(id,2) -- テキスト1（手札除外＋ドロー）
		opval[off-1]=1
		off=off+1
	end
	if b2 then
		ops[off]=aux.Stringid(id,3) -- テキスト2（ATK+500）
		opval[off-1]=2
		off=off+1
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	local sel=Duel.SelectOption(tp,table.unpack(ops))
	e:SetLabel(opval[sel])

	if opval[sel]==1 then
		e:SetCategory(CATEGORY_REMOVE+CATEGORY_DRAW)
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_HAND)
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	else
		e:SetCategory(CATEGORY_ATKCHANGE)
	end
end

function s.e1op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	local op=e:GetLabel()
	if op==1 then
		--------------------------------
		-- ● 手札1枚除外して1ドロー
		--    ＋ このカードを「ライラ」として扱う
		--------------------------------
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.rmfilter_hand,tp,LOCATION_HAND,0,1,1,nil)
		if #g==0 then return end
		if Duel.Remove(g,POS_FACEUP,REASON_EFFECT)==0 then return end
		if Duel.Draw(tp,1,REASON_EFFECT)==0 then return end

		-- このカードを「im@scgs - ライラ」として扱う（改めてライラ名義に固定）
		if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(LAILA_ID)
		e1:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	elseif op==2 then
		--------------------------------
		-- ● 攻撃力を500アップ
		--    ＋ このカードを「ナターリア」として扱う
		--------------------------------
		-- ATK+500
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(500)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)  -- ★ここを修正
		c:RegisterEffect(e1)

		-- このカードを「im@scgs - ナターリア」として扱う
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CHANGE_CODE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetValue(NATALIA_ID)
		e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e2)
	end
end

--------------------------------
-- ②：墓地へ送られた場合、自身を除外し、
--     ナターリア名義カードをサーチ
--------------------------------
function s.e2filter(c)
	return s.has_name(c,NATALIA_ID) and c:IsAbleToHand()
end

function s.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemove()
			and Duel.IsExistingMatchingCard(s.e2filter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,c,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.e2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.Remove(c,POS_FACEUP,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.e2filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
