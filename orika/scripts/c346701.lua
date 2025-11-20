-- -- im@scgs - スターライトステージ
local s,id,o=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--発動時処理（①）
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)

    --攻撃力アップ
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD)
	e6:SetCode(EFFECT_UPDATE_ATTACK)
	e6:SetRange(LOCATION_FZONE)
    e6:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
    e6:SetTarget(function(e,c) return c:IsSetCard(SETCODE) end)
	e6:SetValue(s.value)
	c:RegisterEffect(e6)

	-- 常在効果群（②）
	-- ●3種類以上：「im@scgs」罠カードの発動時、相手はチェーンできない
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_CHAIN)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetValue(s.chainlimit)
	e2:SetCondition(s.ct3con)
	c:RegisterEffect(e2)

	-- ●5種類以上：「im@scgs」モンスターの戦闘時に相手は発動不可
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetCode(EFFECT_CANNOT_ACTIVATE)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(0,1)
	e3:SetValue(1)
	e3:SetCondition(s.ct5con)
	c:RegisterEffect(e3)

	-- ●19種類以上：5体戻してデュエル勝利（デバッグ中は1種類）
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(s.victg)
	e4:SetOperation(s.vicop)
	e4:SetCondition(s.ct19con)
	c:RegisterEffect(e4)

	-- 破壊・離脱身代わり（③）
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_DESTROY_REPLACE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTarget(s.reptg)
	c:RegisterEffect(e5)
end

function s.atkfilter(c)
	return c:IsSetCard(SETCODE) 
end
function s.value(e,c)
	local g=Duel.GetMatchingGroup(s.atkfilter,c:GetControler(),LOCATION_REMOVED,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	return ct*100
end

--------------------------------
-- カード検索・除外処理（①）
--------------------------------
function s.tgfilter(c,attr)
	return c:IsSetCard(SETCODE) and c:IsAttribute(attr) and c:IsAbleToHand()
end
function s.rmfilter(c,tp)
	return c:IsSetCard(SETCODE) and c:IsAbleToRemove()
		and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil,c:GetAttribute())
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_EXTRA,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_EXTRA,0,1,1,nil,tp)
	if #g>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)~=0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil,g:GetFirst():GetAttribute())
		if #sg>0 then
			Duel.SendtoHand(sg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg)
		end
	end
end

--------------------------------
-- 汎用カウント関数
--------------------------------
function s.rmfilter2(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsFaceup()
end
function s.ctcheck(tp)
	local g=Duel.GetMatchingGroup(s.rmfilter2,tp,LOCATION_REMOVED,0,nil)
	return g:GetClassCount(Card.GetCode)
end

--------------------------------
-- 条件分岐関数群（②）
--------------------------------
function s.ct3con(e)
	return s.ctcheck(e:GetHandlerPlayer())>=3
end
function s.ct5con(e)
	return s.ctcheck(e:GetHandlerPlayer())>=5
end
function s.ct19con(e)
	return s.ctcheck(e:GetHandlerPlayer())>=19
end

--------------------------------
-- 効果の詳細
--------------------------------
-- チェーン制限（3種以上）
function s.chainlimit(e,re,tp)
	local rc=re:GetHandler()
	return rc and rc:IsSetCard(SETCODE) and rc:IsType(TYPE_TRAP) and rc:IsControler(e:GetHandlerPlayer())
end

-- 戦闘発動不可（5種以上）
function s.actcon(e)
	local tp=e:GetHandlerPlayer()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return (a and a:IsControler(tp) and a:IsSetCard(SETCODE)) or (d and d:IsControler(tp) and d:IsSetCard(SETCODE))
end

-- 勝利効果（19種以上）
-- フィルター：im@scgs かつモンスターかつペンデュラムでない（場の対象）
function s.vicfilter(c)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and not c:IsType(TYPE_PENDULUM)
end

s.VICTORY_COUNT = 5-- ← この値を変えるだけで簡単に調整可能

-- 勝利効果の発動条件（チェック）
function s.victg(e,tp,eg,ep,ev,re,r,rp,chk)
	local need = s.VICTORY_COUNT
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.vicfilter,tp,LOCATION_MZONE,0,nil)
		-- 種類数（同名は1）を数える
		return g:GetClassCount(Card.GetCode) >= need
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,need,tp,LOCATION_MZONE)
end

-- 実行：プレイヤーに「種類が重複しない」ようにN体選ばせてデッキに戻し勝利
function s.vicop(e,tp,eg,ep,ev,re,r,rp)
	local need = s.VICTORY_COUNT
	-- まず候補群を取得
	local candidates=Duel.GetMatchingGroup(s.vicfilter,tp,LOCATION_MZONE,0,nil)
	if candidates:GetClassCount(Card.GetCode) < need then return end

	local sel=Group.CreateGroup()
	local used_codes = {}

	for i=1,need do
		-- フィルタ：まだコードが使われていないカードのみ
		local function available_filter(c)
			return not used_codes[c:GetCode()]
		end

		local avail = candidates:Filter(available_filter,nil)
		if #avail==0 then break end

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local tg = avail:Select(tp,1,1,nil)
		local tc = tg:GetFirst()
		if not tc then break end

		sel:AddCard(tc)
		used_codes[tc:GetCode()] = true

		-- 候補から選んだカードを取り除く（次回以降の選択を簡単に）
		candidates:RemoveCard(tc)
	end

	if #sel < need then
		-- 選択が完了しなければ処理しない
		return
	end

	-- 選ばれたN枚をデッキに戻す（シャッフル）
	Duel.SendtoDeck(sel,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	-- 勝利（WIN_REASON_EXODIA を流用）
	Duel.Win(tp,WIN_REASON_EXODIA)
end

--------------------------------
-- 破壊・離脱身代わり（③）
--------------------------------
function s.repfilter(c)
	return c:IsSetCard(SETCODE) and c:IsAbleToDeck()
end

function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		-- フィールド魔法が「ルールで墓地に送られる」場合はNG
		-- それ以外の破壊ならOK（サイクロンなど）
		return not c:IsReason(REASON_RULE)
			and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_REMOVED,0,2,nil)
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_REMOVED,0,2,2,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_REPLACE)
			return true
		end
	end
	return false
end


