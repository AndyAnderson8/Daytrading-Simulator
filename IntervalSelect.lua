local activeInterval = script.Parent.Parent.Parent.Parent.Parent.Interval

function leftClick()
	activeInterval.Value = script.Parent.Name
	script.Parent.Parent.Parent.Text = script.Parent.Name
	script.Parent.Parent.Visible = false
end

script.Parent.MouseButton1Click:Connect(leftClick)