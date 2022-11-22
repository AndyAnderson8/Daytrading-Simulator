local activeTicker = script.Parent.Parent.Parent.Ticker
local activeInterval = script.Parent.Parent.Parent.Interval

local function leftClick()
	if script.Parent.Selecter.Visible == false then
		script.Parent.Text = ""
		script.Parent.Selecter.Visible = true
		script.Parent.Parent.Ticker.Selecter.Visible = false
		script.Parent.Parent.Ticker.Text = activeTicker.Value:upper()
	else
		script.Parent.Text = activeInterval.Value
		script.Parent.Selecter.Visible = false
	end
end
script.Parent.MouseButton1Click:Connect(leftClick)