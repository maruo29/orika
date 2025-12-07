-- im@scgs - [フィロ・ド・ソル] ナターリア
local s,id=GetID()
local SETCODE=0x2fd286a

local LAILA_ID   = 349501    -- ★要差し替え：『im@scgs - ライラ』のカードID
local NATALIA_ID = 349401    -- ★要差し替え：『im@scgs - ナターリア』のカードID
local LAILA_NAT_ID = 349201        -- ★差し替え：「im@scgs - ライラ＆ナターリア」のID

--------------------------------
-- 「名が記された」共通ヘルパ（テンプレ）
--------------------------------
-- スクリプトテーブルから imascgs_name_list を取得
function s.get_name_list(c)
	if not c then return nil end
	local code=c:GetOriginalCode()
	local mt=_G["c"..code]
	if mt and mt.imascgs_name_list then
		return mt.imascgs_name_list
	end
	-- 後方互換：昔の "s.imascgs_name = xxx" にも対応するなら
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

-- このカード自身の名義情報（他カードから参照される）
s.imascgs_name_list={NATALIA_ID}   -- ★必ずテーブルで！

function s.initial_effect(c)
	--------------------------------
	-- フィールド・墓地では「im@scgs - ナターリア」として扱う
	--------------------------------
	aux.AddCodeList(c,NATALIA_ID)
	aux.EnableChangeCode(c,NATALIA_ID,LOCATION_MZONE+LOCATION_GRAVE)

	--------------------------------
	-- ①：このカードを手札から除外して
	--     「ライラ」の名が記されたカードをサーチ
	--     （このカード名の①の効果は1ターンに1度）
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)  -- ①は id
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：除外されたこのカード＋
	--     「ライラ」の名が記されたモンスター1体をデッキに戻して、
	--     EXデッキから「ライラ＆ナターリア」をSS
	--     （このカード名の②の効果は1ターンに1度）
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_REMOVED)
	e2:SetCountLimit(1,id+1)  -- ②は id+1（ユーザー指定スタイル）
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--------------------------------
-- ①：コスト（手札から自身を除外）
--------------------------------
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end
	Duel.Remove(c,POS_FACEUP,REASON_COST)
end

--------------------------------
-- ①：ライラの名が記されたカードをサーチ
--------------------------------
function s.thfilter(c)
	return s.has_name(c,LAILA_ID) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------
-- ②：ライラ名義モンスター＋このカードをデッキに戻して
--     EXから「ライラ＆ナターリア」をSS
--------------------------------
function s.lailafilter(c)
	-- 「im@scgs - ライラ」の名が記されたモンスター（フィールド or 墓地）
	return c:IsType(TYPE_MONSTER)
		and s.has_name(c,LAILA_ID)
		and c:IsAbleToDeck()
		and c:IsLocation(LOCATION_MZONE+LOCATION_GRAVE)
end

function s.spfilter(c,e,tp)
	return c:IsCode(LAILA_NAT_ID) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToDeck()
			and Duel.IsExistingMatchingCard(s.lailafilter,tp,
				LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)  -- ★ここも REMOVED を外す
			and Duel.GetLocationCountFromEx(tp,tp,nil)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_REMOVED+LOCATION_MZONE+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end

	-- ライラ名義モンスター1体を選択
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectMatchingCard(tp,s.lailafilter,tp,
		LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	local tc=g1:GetFirst()
	if not tc then return end

	-- 自身＋ライラ名義モンスターの2枚をデッキに戻す
	local g=g1
	g:AddCard(c)
	if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end

	-- EXデッキから「ライラ＆ナターリア」を特殊召喚
	if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local sc=sg:GetFirst()
	if sc then
		Duel.SpecialSummon(sc,0,tp,tp,true,false,POS_FACEUP)
		sc:CompleteProcedure()
	end
end
