local apiKeys = {"YOUR KEYS HERE"}

local stocks = {
	{"RBLX", "Roblox Corp", "NYSE"},
	{"SPY", "SPDR S&P 500 ETF Trust", "NYSE"},
	{"TSLA", "Tesla Inc", "NASDAQ"},
	{"MSFT", "Microsoft Corporation", "NASDAQ"},
	{"GOOG", "Alphabet Inc Class C (Google)", "NASDAQ"},
	{"AMZN", "Amazon.com, Inc.", "NASDAQ"},
	{"FB", "Facebook, Inc.", "NASDAQ"},
	{"AMD", "Advanced Micro Devices, Inc.", "NASDAQ"},
	{"DIS", "Walt Disney Co", "NYSE"},
	{"NFLX", "Netflix Inc", "NASDAQ"},
	{"NKE", "Nike Inc", "NYSE"},
	{"MCD", "McDonald's Corp", "NYSE"},
	{"SBUX", "Starbucks Corporation", "NASDAQ"},
	{"GME", "GameStop Corp.", "NYSE"},
	{"AMC", "AMC Entertainment Holdings Inc", "NYSE"},
	{"BB", "BlackBerry Ltd", "NYSE"},
	--{"BTC", "Bitcoin", "Crypto"},
	--{"ETH", "Ethereum", "Crypto"},
}

local greenColor = Color3.fromRGB(0, 158, 100)
local redColor = Color3.fromRGB(225, 54, 54)
local barlineColor = Color3.fromRGB(200, 200, 200)

local maxPriceBarCount = 25

---------------------
-----SOURCE-CODE-----
---------------------

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local i = 0
local stockButton = script.Parent.Parent.Parent.Toggles.Ticker.Selecter.StockButton
for v, stock in pairs(stocks) do
	local newButton = stockButton:Clone()
	newButton.Parent = script.Parent.Parent.Parent.Toggles.Ticker.Selecter
	newButton.Name = stock[1]:upper()
	newButton.Text = stock[1]:upper()
	newButton.Position = UDim2.new(0, 0, i, 1)
	newButton.CompanyName.Value = stock[2]
	i = i + 1
end
stockButton:Destroy()

function format(number, add_zeros) --I stole this code from stackoverflow and then modified it a lil to add commas to big numbers and add 0s to ones that need it. Only use for final numbers
	local number2 = math.floor(tonumber(number)*100)/100
	local i, j, minus, int, fraction = tostring(number2):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	local final = minus .. int:reverse():gsub("^,", "") .. fraction
	if add_zeros == true then
		if math.floor(number2) == number2 then
			final = final .. ".00"
		elseif math.floor(number2*10)/10 == number2 then
			final = final .. "0"
		end
	end
	return final
end

script.Parent.Parent.Parent.Trading.Buy.BackgroundColor3 = greenColor
script.Parent.Parent.Parent.Trading.Sell.BackgroundColor3 = redColor

local function getStockData(ticker, interval)
	local apikey = apiKeys[math.random(1,#apiKeys)]
	print("Fetching data for " .. ticker:upper() .. " at " .. interval.. " interval using key " .. apikey .. ".")
	script.Parent.Parent.Parent.Toggles.Interval.Text = interval
	script.Parent.Parent.Parent.Toggles.Ticker.Text = ticker:upper()
	
	script.Parent.Parent.Parent.ChartLoading.Visible = true
	
	local url = "https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=" .. ticker .. "&interval=" .. interval .. "&apikey=" .. apikey
	local response = HttpService:GetAsync(url)
	local data = HttpService:JSONDecode(response)
	
	if data["Note"] ~= nil then
		print("API Key overused. Rerunning function.")
		getStockData(ticker, interval)
		--script.Parent.Parent.Parent.ChartLoading.Visible = false
		--script.Parent.Parent.Parent.ChartNoData.Visible = true
		--wait(2)
		--script.Parent.Parent.Parent.ChartNoData.Visible = false
		
	else
		local chartData = data["Time Series (" .. interval .. ")"]
	
		local sortedDataNames = {} --used to get object titles for next part, ensures data in order
		for value in pairs(chartData) do
			table.insert(sortedDataNames, value)
		end
		table.sort(sortedDataNames)
	
		local chartATH = -999999999999999999 --just leave it
		local chartATL = 9999999999999999999 --just leave it
		for i, values in pairs(chartData) do
			local low = tonumber(values["3. low"]) 
			local high = tonumber(values["2. high"])
			if chartATH < high then
				chartATH = high
			end	
			
			if chartATL > low then
				chartATL = low
			end	
		end
	
		local chartRange = chartATH-chartATL
	
		for i, object in pairs(script.Parent:GetChildren()) do
			if string.find(object.Name, "Candle") or string.find(object.Name, "Wick") or string.find(object.Name, "Bar") or string.find(object.Name, "Text") then
				object:Destroy()
			end
		end
	
		i = 0
		while i < #sortedDataNames do
			local dataSet = chartData[sortedDataNames[#sortedDataNames-i]]
		
			local open = tonumber(dataSet["1. open"])
			local high = tonumber(dataSet["2. high"])
			local low = tonumber(dataSet["3. low"])
			local close = tonumber(dataSet["4. close"])
			local volume = tonumber(dataSet["5. volume"])
		
			local openPos = 1-((open-chartATL)/chartRange)
			local highPos = 1-((high-chartATL)/chartRange)
			local lowPos = 1-((low-chartATL)/chartRange)
			local closePos = 1-((close-chartATL)/chartRange)

			if i == 0 then --most recent value for showling last price
				recentClose = close
				recentVolume = volume
			
				script.Parent.Parent.Parent.Trading.Price.Text = "$" .. format(recentClose, true)
				script.Parent.Parent.Parent.Trading.Volume.Text = format(recentVolume, false) .. " shares"
			
			elseif i == 1 then --designating colors if its up or down
				if recentClose >= close then
					script.Parent.Parent.Parent.Trading.Price.TextColor3 = greenColor
				else
					script.Parent.Parent.Parent.Trading.Price.TextColor3 = redColor
				end
			
				if recentVolume >= volume then
					script.Parent.Parent.Parent.Trading.Volume.TextColor3 = greenColor
				else
					script.Parent.Parent.Parent.Trading.Volume.TextColor3 = redColor
				end
			
			end
		
			local candle = Instance.new("Frame")
			candle.Parent = script.Parent
			candle.Name = "Candle - " .. sortedDataNames[#sortedDataNames-i]
			candle.Size = UDim2.new(0.01, 0, math.abs(openPos-closePos), 0)
			candle.ZIndex = 2
		
			if close >= open then
				candle.BackgroundColor3 = greenColor
				candle.Position = UDim2.new(0.01*(#sortedDataNames-(i+1)), 0, closePos, 0)
			else
				candle.BackgroundColor3 = redColor
				candle.Position = UDim2.new(0.01*(#sortedDataNames-(i+1)), 0, openPos, 0)
			end
			
			local wick = Instance.new("Frame")
			wick.Parent = script.Parent
			wick.Name = "Wick - " .. sortedDataNames[#sortedDataNames-i]
			wick.BackgroundColor3 = Color3.fromRGB(0, 0, 0) --black color
			wick.Size = UDim2.new(0, 1, lowPos-highPos, 0)
			wick.Position = UDim2.new((0.01*(#sortedDataNames-(i+1)))+.005, -1, highPos, 0)
			wick.BorderSizePixel = 0
			wick.ZIndex = 1
		
			i = i + 1
		end
	
		i = 0
		local priceDistance = chartRange/maxPriceBarCount
		while priceDistance < 1.00 do
			i = i - 1
			priceDistance = priceDistance*10
		end
		if priceDistance > 1.00 and priceDistance <= 2 then
			priceDistance = 2.00*10^i
		elseif priceDistance > 2.00 and priceDistance <= 5 then
			priceDistance = 5.00*10^i
		elseif priceDistance > 5.00 and priceDistance <= 10 then
			priceDistance = 10.00*10^i
		else
			priceDistance = 1.00*10^i
		end
	
		i = 0
		local price = math.floor(chartATH*100)/100 - priceDistance*i
		while price >= chartATL do
			local priceBar = Instance.new("Frame")
			priceBar.Parent = script.Parent
			priceBar.Name = "Price Bar - $" .. price
			priceBar.BackgroundColor3 = barlineColor
			priceBar.Size = UDim2.new(1, 10, 0, 1)
			priceBar.Position = UDim2.new(0, 0, 1-((price-chartATL)/chartRange), 0)
			priceBar.BorderSizePixel = 0
			priceBar.ZIndex = 1
		
			local priceText = Instance.new("TextLabel")
			priceText.Parent = script.Parent
			priceText.Name = "Price Text - $" .. price
			priceText.BackgroundTransparency = 1
			priceText.Size = UDim2.new(0, 60, (((chartATH - priceDistance*i)-chartATL)-((chartATH - priceDistance*(i+1))-chartATL))/chartRange, 0)
			priceText.Position = UDim2.new(1, 15, i*((((chartATH - priceDistance*i)-chartATL)-((chartATH - priceDistance*(i+1))-chartATL))/chartRange)-0.5*((((chartATH - priceDistance*i)-chartATL)-((chartATH - priceDistance*(i+1))-chartATL))/chartRange), 0)
			priceText.Font = "Nunito"
			priceText.TextScaled = true
			priceText.Text = "$" .. format(price, true)
			priceText.ZIndex = 1
		
			i = i + 1
			price = math.floor(chartATH*100)/100 - priceDistance*i
		end
		script.Parent.Parent.CompanyName.Text = script.Parent.Parent.Parent.Toggles.Ticker.Selecter[ticker:upper()].CompanyName.Value .. " / US Dollar - " .. interval
		script.Parent.Parent.Parent.ChartLoading.Visible = false
		print("Function completed.")
	end	
end

local activeTicker = script.Parent.Parent.Parent.Ticker.Value
local activeInterval = script.Parent.Parent.Parent.Interval.Value

getStockData(activeTicker, activeInterval) --populate chart initially on game load

elapsed = 0
while true do
	wait(0.01)
	elapsed = elapsed + 0.01
	if activeTicker ~= script.Parent.Parent.Parent.Ticker.Value or activeInterval ~= script.Parent.Parent.Parent.Interval.Value or elapsed > 60 then
		print("Reloading chart data")
		elapsed = 0
		activeTicker = script.Parent.Parent.Parent.Ticker.Value
		activeInterval = script.Parent.Parent.Parent.Interval.Value
		getStockData(activeTicker, activeInterval)
	end
end
