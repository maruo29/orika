-- im@scgs - 対決！ ギョーてん ! しーわーるど !
local s,id=GetID()
local SETCODE=0x2fd286a

function s.initial_effect(c)
	--① このカードの発動
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id) -- このカードの①の効果は1ターンに1度
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

----------------------------------------
-- SS 用フィルター（コード指定）
----------------------------------------
function s.spfilter(c,e,tp,code)
	return c:IsCode(code)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and (not c:IsLocation(LOCATION_REMOVED) or c:IsFaceup())
end

----------------------------------------
-- ① コスト：自分の「im@scgs」モンスター1体をリリース
-- ＋ 同名がデッキ/除外に存在するものだけを選ばせる
----------------------------------------
function s.cfilter(c,e,tp)
	local code=c:GetCode() -- ★あなたの方針どおり GetCode を使用
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_MONSTER) and c:IsReleasable()
		-- 同名がデッキ＋除外に1体以上いるかチェック
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,nil,e,tp,code)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- ★ここで既に「同名が存在するカードのみ」が候補になる
		return Duel.CheckReleaseGroup(tp,s.cfilter,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local g=Duel.SelectReleaseGroup(tp,s.cfilter,1,1,nil,e,tp)
	local rc=g:GetFirst()
	-- リリースしたモンスターの「元々のカード名」を記録
	-- （ここもあなたの方針に合わせて GetCode のまま）
	e:SetLabel(rc:GetCode())
	Duel.Release(g,REASON_COST)
end

----------------------------------------
-- ① 対象＆処理：デッキ・除外から
-- 　リリースしたモンスターと同名の「im@scgs」モンスター1体をSS
-- 　→ そのモンスターに2つの効果を付与
----------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	-- ★ここでは「空きゾーンがあるか」だけ確認すればOK
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_REMOVED)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local code=e:GetLabel()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_REMOVED,0,1,1,nil,e,tp,code)
	local tc=g:GetFirst()
	if not tc then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- ●このカードの元々の攻撃力は2500になる。
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(2500)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	-- ●このカードが戦闘を行ったダメージ計算後に発動できる。～
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_DAMAGE_STEP_END)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e2)
end

----------------------------------------
-- 付与効果用：戦闘後トリガー
----------------------------------------
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	return d~=nil and (a==c or d==c)
end

function s.rmfilter(c)
	return c:IsSetCard(SETCODE) and c:IsAbleToRemove()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or not c:IsFaceup() then return end
	-- デッキから「im@scgs」カード1枚を除外
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #rg==0 then return end
	if Duel.Remove(rg,POS_FACEUP,REASON_EFFECT)==0 then return end
	local rc=rg:GetFirst()
	-- 「水属性の『im@scgs』モンスター」が除外された場合
	if rc:IsLocation(LOCATION_REMOVED)
		and rc:IsSetCard(SETCODE)
		and rc:IsType(TYPE_MONSTER)
		and rc:IsAttribute(ATTRIBUTE_WATER) then

		-- さらに相手フィールド上の表側表示のカード1枚の効果を無効にする。
		if not Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
		local tc=g:GetFirst()
		if not tc then return end

		-- 効果無効（リセットはあなたの方針どおり「なし」のまま）
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		tc:RegisterEffect(e2)
		-- 罠モンスター対応
		if tc:IsType(TYPE_TRAPMONSTER) then
			local e3=e1:Clone()
			e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
			tc:RegisterEffect(e3)
		end
	end
end
