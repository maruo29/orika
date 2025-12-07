-- im@scgs - [普通の私に特別な魔法を] 島村卯月
local s,id=GetID()
local SETCODE=0x2fd286a
local UZUKI_ID=348101      -- ★要差し替え：「im@scgs - 島村卯月」の実IDを入れてください
local SHOE_ID=346002       -- 「im@scgs - 魔法の靴」
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000

function s.initial_effect(c)
	--------------------------------
	-- リンク召喚
	--------------------------------
	c:EnableReviveLimit()
	-- 「im@scgs」モンスター4体以上（4～∞体）のみを素材にしてL召喚
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,SETCODE),4,99)

	--------------------------------
	-- 名義：卯月として扱う（フィールド・墓地）
	--------------------------------
	s.imascgs_name_list={UZUKI_ID}
	aux.AddCodeList(c,UZUKI_ID)
	aux.EnableChangeCode(c,UZUKI_ID,LOCATION_MZONE+LOCATION_GRAVE)

	--------------------------------
	-- このカードはL召喚でしか特殊召喚できない
	--------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(aux.lnklimit) -- リンク召喚のみ
	c:RegisterEffect(e0)

	--------------------------------
	-- ① このカードは融合・S・X・L素材にできず
	--    リリースできず、コントロールを変更できない。
	--    （このカードの①②の効果は無効化されない）
	--------------------------------
	-- 素材にできない（融合/S/X/リンク）
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e1b)
	local e1c=e1:Clone()
	e1c:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e1c)
	local e1d=e1:Clone()
	e1d:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e1d)

	-- リリースできない
	local e1e=Effect.CreateEffect(c)
	e1e:SetType(EFFECT_TYPE_SINGLE)
	e1e:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e1e:SetRange(LOCATION_MZONE)
	e1e:SetCode(EFFECT_UNRELEASABLE_SUM)
	e1e:SetValue(1)
	c:RegisterEffect(e1e)
	local e1f=e1e:Clone()
	e1f:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e1f)

	-- コントロール変更不可
	local e1g=Effect.CreateEffect(c)
	e1g:SetType(EFFECT_TYPE_SINGLE)
	e1g:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e1g:SetRange(LOCATION_MZONE)
	e1g:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	c:RegisterEffect(e1g)

	--------------------------------
	-- ② このカードを対象とする効果以外の
	--    相手が発動した効果を受けない。
	--    （このカードの①②の効果は無効化されない）
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)

	--------------------------------
	-- ③ 1ターンに1度、
	--    デッキ・EXデッキから「im@scgs」モンスター1体を
	--    「魔法の靴」の効果扱い（SUMMON_TYPE_SHOE）で特殊召喚
	--------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	--------------------------------
	-- ④ ③の発動が無効になった場合、
	--    そのターン中、このカードはカードの効果では破壊されない。
	--------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_CHAIN_NEGATED)
	e4:SetRange(LOCATION_MZONE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCondition(s.indcon)
	e4:SetOperation(s.indop)
	c:RegisterEffect(e4)
end

--------------------------------
-- ②：対象に取らない相手の発動した効果を受けない
--------------------------------
function s.efilter(e,te)
	local c=e:GetHandler()
	-- 自分の効果 / 発動していない効果は対象外
	if te:GetOwnerPlayer()==c:GetControler() or not te:IsActivated() then
		return false
	end
	-- 対象を取らない効果は全部無効
	if not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		return true
	end
	-- 対象を取る場合、「このカードを対象にしているか」で分岐
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	return not g or not g:IsContains(c)
end

--------------------------------
-- ③：靴SS扱いで「im@scgs」モンスターをSS
--------------------------------
function s.spfilter(c,e,tp)
    if not c:IsSetCard(SETCODE) or not c:IsType(TYPE_MONSTER) then return false end
    -- ★ここを消す or コメントアウトする
    -- if c:IsLocation(LOCATION_EXTRA) and not c:IsFaceup() then return false end
    return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SHOE,tp,true,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end
	-- 「im@scgs - 魔法の靴」による特殊召喚扱い（SUMMON_TYPE_SHOE）
	if Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)>0 then
		tc:CompleteProcedure()
	end
end

--------------------------------
-- ④：③の発動が無効になった場合の破壊耐性付与
--------------------------------
function s.indcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 無効にされたチェーンの効果が「このカードの③」かどうか
	if not re or re:GetHandler()~=c then return false end
	-- フィールドで発動した効果のみ対象（墓地などからの発動は想定外）
	if not c:IsRelateToEffect(re) and c:GetLocation()~=LOCATION_MZONE then return false end
	-- 発動した効果が③（IGNITION・カテゴリSS）であることを緩くチェック
	return re:IsHasType(EFFECT_TYPE_IGNITION)
		and re:GetCategory()&CATEGORY_SPECIAL_SUMMON~=0
end
function s.indop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFaceup() or not c:IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end
