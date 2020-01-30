local C = class("ServiceLayer",BaseLayer)
ServiceLayer = C

C.RESOURCE_FILENAME = "base/ServiceLayer.csb"
C.RESOURCE_BINDING = {
	closeBtn = {path="box_img.close_btn",events={{event="click",method="hide"}}},
	contactTabBtn = {path="box_img.contact_tab_btn",events={{event="click",method="onClickContactTabBtn"}}},
	commonTabBtn = {path="box_img.common_tab_btn",events={{event="click",method="onClickCommonTabBtn"}}},
	contactPanel = {path="box_img.contact_panel"},
	commonPanel = {path="box_img.common_panel"},
	listview = {path="box_img.contact_panel.listview"},
	inputBg = {path="box_img.contact_panel.bottom_img.input_img"},
	sendBtn = {path="box_img.contact_panel.bottom_img.send_btn",events={{event="click",method="onClickSendBtn"}}},
	templateLeft = {path="left_item"},
	templateRight = {path="right_item"},
}

function C:onCreate()
	C.super.onCreate(self)
	self.inputEditBox = self:createEditBox()
	self.inputBg:addChild(self.inputEditBox)
	self.templateLeft:setVisible(false)
	self.templateRight:setVisible(false)
	local headImg = self.templateRight:getChildByName("head_panel"):getChildByName("head_img")
	local headId = dataManager.userInfo.headid
	local headUrl = dataManager.userInfo.wxheadurl
	SET_HEAD_IMG(headImg,headId,headUrl)
	self.listview:setScrollBarWidth(5)
	self.listview:setScrollBarPositionFromCornerForVertical(cc.p(5,5))
	self.listview:setTopPadding(10)
	self.listview:setBottomPadding(10)
	self.commonPanel:setScrollBarWidth(5)
	self.commonPanel:setScrollBarPositionFromCornerForVertical(cc.p(5,5))
end

function C:createEditBox()
	local bg = cc.Scale9Sprite:create("base/images/service_popup/scale9sprite.png")
	local editBox = ccui.EditBox:create(cc.size(443,46),bg,bg,bg)
	editBox:setAnchorPoint(cc.p(0,0.5))
	editBox:setPosition(cc.p(8,37))
	editBox:setFontSize(24)
	editBox:setFontColor(INPUT_COLOR)
	editBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	editBox:setMaxLength(140)
	local label = ccui.Text:create()
	label:setFontSize(24)
	label:setString("输入您想咨询的问题")
	label:setTextColor(cc.c3b(172,219,255))
	label:setTag(10000)
	label:setContentSize(cc.size(410,50))
	label:setPosition(cc.p(205,25))
	editBox:addChild(label)
	editBox:onEditHandler(handler(self,self["onEditHandler"]))
	return editBox
end

function C:onEditHandler( event )
	if event.name == "began" then
		local l = event.target:getChildByTag(10000)
		l:setVisible(false)
	elseif event.name == "ended" then
		if event.target:getText() == nil or event.target:getText() == "" then
			local l = event.target:getChildByTag(10000)
			l:setVisible(true)
		end
	end
end

function C:show()
	C.super.show(self)
	self:showTabIndex(1)
	self:loadMessage()

    self.receiveNewRespHandler = handler(self,self.receiveNewResp)
    eventManager:on("CustomServiceMsgReply",self.receiveNewRespHandler)
    self.refreshListviewHandler = handler(self,self.refreshListview)
    eventManager:on("UpdateCustomServiceMsg",self.refreshListviewHandler)

    dataManager:setLastReadMsgTime(os.time())
    eventManager:publish("SetCustomServiceRedDot",false)
end

function C:onExit()
    eventManager:off("CustomServiceMsgReply",self.receiveNewRespHandler)
    eventManager:off("UpdateCustomServiceMsg",self.refreshListviewHandler)
    dataManager:setLastReadMsgTime(os.time())
	C.super.onExit(self)
end

--加载数据
function C:loadMessage()
	local items = dataManager.customServiceMsgList
	if #items == 0 then
        eventManager:publish("CustomServiceMsgList")
	else
		utils:delayInvoke("hall.service",0.5,function()
			self:refreshListview(items)
		end)
	end
end

--收到新回复消息
function C:receiveNewResp( item )
	local item = self:createFromItem(item.content)
	self.listview:pushBackCustomItem(item)
	self.listview:jumpToBottom()
end

--刷新列表
function C:refreshListview(items)
	self.listview:removeAllItems()
	for i,v in ipairs(items) do
		if v.type == "to" then
			local item = self:createToItem(v.content)
			self.listview:pushBackCustomItem(item)
		elseif v.type == "from" then
			local item = self:createFromItem(v.content)
			self.listview:pushBackCustomItem(item)
		end
	end
	self.listview:jumpToBottom()
end

function C:onClickContactTabBtn( event )
	self:showTabIndex(1)
end

function C:onClickCommonTabBtn( event )
	self:showTabIndex(2)
end

function C:showTabIndex( index )
	self.contactPanel:setVisible(index==1)
	self.contactTabBtn:setEnabled(index~=1)
	self.commonPanel:setVisible(index==2)
	self.commonTabBtn:setEnabled(index~=2)
end

--点击发送按钮
function C:onClickSendBtn( event )
	local text = self.inputEditBox:getText()
	if text == nil or text == "" then
		toastLayer:show("请输入内容")
		return
	end
	printInfo("====text:"..#text)
	if #text < 12 then
		toastLayer:show("输入内容过少")
		return
	end
	local item = self:createToItem(text)
	self.listview:pushBackCustomItem(item)
	self.listview:jumpToBottom()
	self.inputEditBox:setText("")
	self.inputEditBox:getChildByTag(10000):setVisible(true)
	--发送出去
    eventManager:publish("CustomServiceMsg",text)
end

function C:createFromItem( text )
	local item = self.templateLeft:clone()
	item:setVisible(true)
	local head = item:getChildByName("head_panel")
	local bg = item:getChildByName("content_img")

	local label = cc.LabelTTF:create()
	label:setFontSize(26)
	label:setColor(cc.c3b(0,0,0))
	label:setAnchorPoint(cc.p(0,0.5))
	label:setDimensions(cc.size(420,0))
	label:setString(text)
	bg:addChild(label)
	label:setDimensions(cc.size(0,26))
	local width = label:getContentSize().width
	if width > 420 then
		label:setDimensions(cc.size(420,0))
	end
	width = label:getContentSize().width
	local height = label:getContentSize().height
	
	local bgWidth = width + 30
	local bgHeight = height + 34

	if bgWidth < 40 then
		bgWidth = 40
	end
	if bgHeight < 60 then
		bgHeight = 60
	end

	local itemWidth = item:getContentSize().width
	local itemHeight = bgHeight+20

	bg:setContentSize(cc.size(bgWidth,bgHeight))
	label:setPosition(cc.p(18,bgHeight/2))
	item:setContentSize(cc.size(itemWidth,itemHeight))
	head:setPositionY(itemHeight-10)
	return item
end

function C:createToItem( text )
	local item = self.templateRight:clone()
	item:setVisible(true)
	local head = item:getChildByName("head_panel")
	local bg = item:getChildByName("content_img")

	local label = cc.LabelTTF:create()
	label:setFontSize(26)
	label:setColor(cc.c3b(0,0,0))
	label:setAnchorPoint(cc.p(1,0.5))
	label:setString(text)
	bg:addChild(label)
	label:setDimensions(cc.size(0,26))
	local width = label:getContentSize().width
	if width > 420 then
		label:setDimensions(cc.size(420,0))
	end
	width = label:getContentSize().width
	local height = label:getContentSize().height
	
	local bgWidth = width + 30
	local bgHeight = height + 34

	if bgWidth < 40 then
		bgWidth = 40
	end
	if bgHeight < 60 then
		bgHeight = 60
	end

	local itemWidth = item:getContentSize().width
	local itemHeight = bgHeight+20

	bg:setContentSize(cc.size(bgWidth,bgHeight))
	label:setPosition(cc.p(bgWidth-18,bgHeight/2))
	item:setContentSize(cc.size(itemWidth,itemHeight))
	head:setPositionY(itemHeight-10)
	return item
end

return ServiceLayer