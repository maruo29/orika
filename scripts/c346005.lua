-- im@scgs - 掴み取った原石
local s,id,o=GetID()
local SETCODE=0x2fd286a
local SUMMON_TYPE_SHOE=SUMMON_TYPE_SPECIAL+0x1000 -- 「魔法の靴」による特殊召喚

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--spsummon
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetTarget(s.smtg)
	e3:SetOperation(s.smop)
	c:RegisterEffect(e3)

    local e4=Effect.CreateEffect(c)
    e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e4:SetType(EFFECT_TYPE_IGNITION)
    e4:SetRange(LOCATION_SZONE)          -- 魔法・罠ゾーンにあるときのみ
    e4:SetCountLimit(1,id+300)          -- 1ターン1回制限
    e4:SetCost(s.spcost3)
    e4:SetTarget(s.sptg3)
    e4:SetOperation(s.spop3)
    c:RegisterEffect(e4)
end

function s.thfilter(c)
	return c:IsSetCard(SETCODE) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if g:GetCount()>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end
end
function s.smfilter(c,e,tp)
	return bit.band(c:GetOriginalType(),TYPE_NORMAL)~=0 and c:IsSetCard(SETCODE) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.smtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.smfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,0,1,nil,e,tp) end
	local g=Duel.GetMatchingGroup(s.smfilter,tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,0,nil,e,tp)
	local sg=Group.CreateGroup()
	local codes={}
	for c in aux.Next(g) do
		local code=c:GetCode()
		if not sg:IsExists(Card.IsCode,1,nil,code) then
			sg:AddCard(c)
			table.insert(codes,code)
		end
	end
	table.sort(codes)
	local afilter={codes[1],OPCODE_ISCODE}
	if #codes>1 then
		--or ... or c:IsCode(codes[i])
		for i=2,#codes do
			table.insert(afilter,codes[i])
			table.insert(afilter,OPCODE_ISCODE)
			table.insert(afilter,OPCODE_OR)
		end
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local code=Duel.AnnounceCard(tp,table.unpack(afilter))
	getmetatable(e:GetHandler()).announce_filter={TYPE_MONSTER,OPCODE_ISTYPE,TYPE_NORMAL,OPCODE_ISTYPE,5405694,OPCODE_ISCODE,OPCODE_OR,OPCODE_AND}
	Duel.SetTargetParam(code)
	Duel.SetOperationInfo(0,CATEGORY_ANNOUNCE,nil,0,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE)
end
function s.smop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		local code=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
		local og=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.smfilter),tp,LOCATION_HAND+LOCATION_GRAVE+LOCATION_DECK,0,nil,e,tp):Filter(Card.IsCode,nil,code)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=og:Select(tp,1,1,nil)
		if g:GetCount()>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) and rc:IsSummonType(SUMMON_TYPE_SPECIAL) and rc:IsLocation(LOCATION_MZONE) and not rc:IsSetCard(SETCODE)
end


-- コスト処理
function s.spcost3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,2500) end
	Duel.PayLPCost(tp,2500)
end

-- 発動条件・対象設定
function s.sptg3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

-- 効果実行
function s.spop3(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 選択肢
	local opt=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3)) -- 0:デッキめくり 1:EXランダム
	if opt==0 then
        if not Duel.IsPlayerCanSpecialSummon(tp) or not Duel.IsPlayerCanDiscardDeck(tp,1) then return end
        local g=Duel.GetMatchingGroup(Card.IsSummonableCard,tp,LOCATION_DECK,0,nil)
        local dcount=Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)
        local seq=-1
        local tc=g:GetFirst()
        local spcard=nil
        while tc do
            if tc:GetSequence()>seq and tc:IsSetCard(SETCODE) then
                seq=tc:GetSequence()
                spcard=tc
            end
            tc=g:GetNext()
        end
        if seq==-1 then
            Duel.ConfirmDecktop(tp,dcount)
            Duel.ShuffleDeck(tp)
            return
        end
        Duel.ConfirmDecktop(tp,dcount-seq)
        if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and spcard:IsCanBeSpecialSummoned(e,0,tp,false,false) then
            Duel.DisableShuffleCheck()
            if dcount-seq==1 then Duel.SpecialSummon(spcard,0,tp,tp,false,false,POS_FACEUP)
            else
			    Duel.SpecialSummon(spcard,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)
                -- Duel.DiscardDeck(tp,dcount-seq-1,REASON_EFFECT)
                Duel.ShuffleDeck(tp)
            end
        else
            -- Duel.DiscardDeck(tp,dcount-seq,REASON_EFFECT)
            Duel.ShuffleDeck(tp)
        end
	else
		-- EXデッキランダム
		local g=Duel.GetMatchingGroup(Card.IsFacedown,tp,LOCATION_EXTRA,0,nil)
		if #g==0 then return end
		local tc=g:RandomSelect(tp,1):GetFirst()
		Duel.ConfirmCards(1-tp,tc)
		if tc:IsType(TYPE_MONSTER) and tc:IsSetCard(SETCODE)
			and tc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SPECIAL,tp,true,false,POS_FACEUP)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(tc,SUMMON_TYPE_SHOE,tp,tp,true,false,POS_FACEUP)
			tc:CompleteProcedure()
		else
			Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
		end
	end
end