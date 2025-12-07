-- im@scgs - ザ・スターライトコンティニュー
local s,id=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--------------------------------
	-- ① このカードの発動
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	-- このカード名の①の効果は１ターンに１枚しか発動できない
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 除外された場合の効果
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	-- このカード名の②の効果は１ターンに１枚しか発動できない
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)

	--------------------------------
	-- 三戦の才方式の「相手が自分メイン中にモンスター効果を発動したか」カウンタ
	--------------------------------
	Duel.AddCustomActivityCounter(id,ACTIVITY_CHAIN,s.chainfilter)
end

--------------------------------
-- 三戦の才と同じチェーンフィルタ
-- 「カウントしたくないチェーン」を false にする
--------------------------------
function s.chainfilter(re,tp,cid)
	local ph=Duel.GetCurrentPhase()
	-- 「自分メインフェイズ中のモンスター効果」だけカウントしない
	return not (re:IsActiveType(TYPE_MONSTER) and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2))
end

--------------------------------
-- ①：このターンの自分メインフェイズに
--     相手がモンスター効果を発動している場合
-- （三戦の才と同じく、相手側のカウンタを参照）
--------------------------------
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetCustomActivityCount(id,1-tp,ACTIVITY_CHAIN)~=0
end

--------------------------------
-- ①：効果選択＆サーチ処理
--------------------------------
-- ●共通フィルタ
function s.thfilter1(c)
	return c:IsSetCard(SETCODE) and c:IsAbleToHand()
end
function s.thfilter2(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
-- 通常召喚可能な im@scgs モンスター
function s.nsfilter(c)
	return c:IsSetCard(SETCODE) and c:IsSummonable(true,nil)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- ●デッキから「im@scgs」カード1枚を手札に加える。
	local b1=Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK,0,1,nil)
	-- ●デッキから「im@scgs」モンスター1体を手札に加える。その後、手札から「im@scgs」モンスター1体の召喚を行う。
	--   （召喚は「可能なら」なので、ここではサーチだけチェック）
	local b2=Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil)

	if chk==0 then return b1 or b2 end

	local off=1
	local ops={}
	local opval={}
	if b1 then
		ops[off]=aux.Stringid(id,0)   -- 「im@scgs」カード1枚サーチ
		opval[off-1]=1
		off=off+1
	end
	if b2 then
		ops[off]=aux.Stringid(id,1)   -- 「im@scgs」モンスターサーチ＋召喚
		opval[off-1]=2
		off=off+1
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EFFECT)
	local op=Duel.SelectOption(tp,table.unpack(ops))
	e:SetLabel(opval[op])

	if opval[op]==1 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	elseif opval[op]==2 then
		e:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SUMMON)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		--------------------------------
		-- ●「im@scgs」カード1枚サーチ
		--------------------------------
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	elseif op==2 then
		--------------------------------
		-- ●「im@scgs」モンスター1体サーチ → その後、可能なら召喚
		--------------------------------
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
		if #g==0 then return end
		if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then return end
		Duel.ConfirmCards(1-tp,g)
		Duel.BreakEffect()
		-- 手札から「im@scgs」モンスター1体の通常召喚（可能なら）
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
		if not Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil) then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		local tc=sg:GetFirst()
		if tc then
			Duel.Summon(tp,tc,true,nil)
		end
	end
end

--------------------------------
-- ②：このカードが除外された場合
-- デッキから「im@scgs」カード1枚を除外
-- （テキスト「ims@csgs」は誤記とみなして im@scgs で処理）
--------------------------------
function s.rmfilter(c)
	return c:IsSetCard(SETCODE) and c:IsAbleToRemove()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
	end
end
