-- im@scgs - [マウジュのまにまに] ライラ
local s,id=GetID()
local SETCODE=0x2fd286a

local LAILA_ID   = 349501    -- ★要差し替え：『im@scgs - ライラ』のカードID
local NATALIA_ID = 349401    -- ★要差し替え：『im@scgs - ナターリア』のカードID

--------------------------------
-- 名義共通処理（他カードからも使う想定のテンプレ）
--------------------------------
-- スクリプトテーブルから imascgs_name_list を取得
function s.get_name_list(c)
	if not c then return nil end
	local code=c:GetOriginalCode()
	local mt=_G["c"..code]
	if mt and mt.imascgs_name_list then
		return mt.imascgs_name_list
	end
	-- 後方互換：昔の "s.imascgs_name = xxx" にも対応
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

--------------------------------
-- メイン効果
--------------------------------
function s.initial_effect(c)
	--------------------------------
	-- フィールド・墓地では「im@scgs - ライラ」として扱う
	--------------------------------
	-- 名が記されたリスト（新仕様）
	s.imascgs_name_list={LAILA_ID}
	-- 旧仕様との互換（必要なら）
	s.imascgs_name=LAILA_ID
	aux.AddCodeList(c,LAILA_ID)
	aux.EnableChangeCode(c,LAILA_ID,LOCATION_MZONE+LOCATION_GRAVE)

	--------------------------------
	-- ①：ナターリアが除外されていれば手札からSSできる
	--    （このカード名の①の効果は1ターンに1度）
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- 「このカード名の①の効果は1ターンに1度」
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--------------------------------
	-- ②：このカードが除外された場合、自身をSSし、
	--    離れたら除外される
	--    （このカード名の②の効果は1ターンに1度）
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
end

--------------------------------
-- ①：ナターリアが除外されているかチェック
--------------------------------
function s.natfilter(c)
	-- 表側除外のみカウント
	if not c:IsFaceup() then return false end
	-- 「im@scgs - ナターリア」そのものか、その名が記されたカード
	return c:IsCode(NATALIA_ID) or s.has_name(c,NATALIA_ID)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.natfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,1,nil)
end

--------------------------------
-- ②：このカードが除外された場合、自身をSS
--------------------------------
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end

function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		-- フィールドから離れたとき除外される
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		e1:SetValue(LOCATION_REMOVED)
		c:RegisterEffect(e1,true)
	end
end
