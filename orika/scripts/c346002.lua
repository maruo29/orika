--im@scgs - 魔法の靴 (c346002)
local s,id=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」による特殊召喚

-- スクリプトテーブルから imascgs_name_list を取得
function s.get_name_list(c)
    if not c then return nil end
    local code = c:GetOriginalCode()
    local mt = _G["c"..code]
    if mt and mt.imascgs_name_list then
        return mt.imascgs_name_list
    end
    -- 後方互換：昔の "s.imascgs_name = xxx" にも対応したいなら
    if mt and mt.imascgs_name then
        return { mt.imascgs_name }
    end
    return nil
end

-- カード c が「tcode の名が記されたカード」かどうか
function s.has_name(c,tcode)
    local list = s.get_name_list(c)
    if not list then return false end
    for _,v in ipairs(list) do
        if v==tcode then return true end
    end
    return false
end

function s.initial_effect(c)
	--【起動効果】特殊召喚
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetCountLimit(1,id)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCountLimit(1,id+100)
	e3:SetRange(LOCATION_GRAVE)
	--墓地へ送られたターンに発動できない効果
	-- e3:SetCondition(aux.exccon)
	e3:SetCost(s.thcost)
	e3:SetTarget(s.thtg2)
	e3:SetOperation(s.thop2)
	c:RegisterEffect(e3)
end

-- コスト処理（フラグとしてラベルをセットするのみ）
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	return true
end

-- 除外候補：同セットのモンスター
function s.Filter1(c,e,tp)
	local code=c:GetCode()
	return c:IsType(TYPE_MONSTER) and c:IsSetCard(SETCODE)
		and c:IsAbleToRemoveAsCost()
		and Duel.GetMZoneCount(tp,c)>0
		and Duel.IsExistingMatchingCard(s.Filter2,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp,code)
end

-- デッキから特殊召喚する対象
function s.Filter2(c,e,tp,tcode)
    return s.has_name(c,tcode) and c:IsType(TYPE_MONSTER)
        and (c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
            or c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,true,false,POS_FACEUP))
end

-- 対象設定
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- コストチェック用フラグ
		if e:GetLabel()~=1 then return false end
		e:SetLabel(0)
		return Duel.IsExistingMatchingCard(s.Filter1,tp,LOCATION_MZONE,0,1,nil,e,tp)
	end

	-- 除外するモンスターを選択
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local rg=Duel.SelectMatchingCard(tp,s.Filter1,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
	local removed=rg:GetFirst()
	e:SetLabel(removed:GetCode())

	Duel.Remove(removed,POS_FACEUP,REASON_COST)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_EXTRA)
	--相手のチェーンを阻害する効果。
	Duel.SetChainLimit(s.chlimit)
end

function s.chlimit(e,ep,tp)
	return tp==ep
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	local tcode=e:GetLabel()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.Filter2,tp,LOCATION_HAND+LOCATION_EXTRA,0,1,1,nil,e,tp,tcode)
	local tc=g:GetFirst()
	if not tc then return end

	-- EXデッキかどうかで挙動を分ける
	if tc:IsLocation(LOCATION_EXTRA) then
		-- EXデッキ側は召喚条件を無視して特殊召喚
		if Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
	else
		-- 通常デッキ側は通常通りの特殊召喚
		Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end

--②の効果
function s.rccfilter(c)
	return c:IsFaceup() and c:IsSetCard(SETCODE)
end
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
		and Duel.IsExistingMatchingCard(s.rccfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
	end
end

--③の効果
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToDeckAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_COST)
end

-- 特殊召喚対象：im@scgs 通常モンスター
function s.spfilter(c,e,tp)
	return c:IsSetCard(SETCODE) and c:IsType(TYPE_NORMAL)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end