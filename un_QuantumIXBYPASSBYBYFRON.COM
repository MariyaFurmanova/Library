-- ⚙️ Required ⚙️ --
local ServiceName = "Quantumix"
local HubName = "Quantumix HUB"
local KeyFile = "QuantumixSaved.txt"
local CoreGUI = game:GetService('CoreGui')
local AntiBypass = true
--local PandaAuth = loadstring(game:HttpGet('https://raw.githubusercontent.com/SaltyHB/Poggers/main/Auth'))()
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/notification_gui_library.lua", true))()
local Stores = {
  you = {
    GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    lplr = game.Players.LocalPlayer,
		char = game.Players.LocalPlayer.Character,
		hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"),
		status = {
			matchId = 0,
			inMatch = false,
			gamemode = "classic",
			team = nil
		}
  },
  remotes = {
    shootEvent = game.ReplicatedStorage.Remotes.Shoot,
		throwStartEvent = game.ReplicatedStorage.Remotes.ThrowStart,
		throwHitEvent = game.ReplicatedStorage.Remotes.ThrowHit,
		stabEvent = game.ReplicatedStorage.Remotes.Stab,
		onMatchFinished = game.ReplicatedStorage.Remotes.OnMatchFinished,
		onRoundEnded = game.ReplicatedStorage.Remotes.OnRoundEnded,
		onPlayerKilled = game.ReplicatedStorage.Remotes.OnPlayerKilled,
		onRoleSelection = game.ReplicatedStorage.Remotes.OnRoleSelection
  },
  services = {
    RunService = game:GetService("RunService")
  }
}
local Functions = {
	calculateAngleBetweenPositions = function(pos1,pos2)
		local normal = Vector3.new()
		if pos1 and pos2 then
			normal = (pos1-pos2).Unit
		end
		return -normal
	end,
	getMouseLocation = function()
		return game:GetService("UserInputService"):GetMouseLocation()
	end,
	sayMessage = function(message)
		game:GetService("TextChatService").ChatInputBarConfiguration.TargetTextChannel:SendAsync(message)
	end,
	getEnemies = function()
		local enemies = {}
		if Stores.you.status.inMatch then
			for _,plr in next,game.Players:GetPlayers() do
				if plr ~= Stores.you.lplr and plr:GetAttribute("Match") and plr:GetAttribute("Match") == Stores.you.status.matchId and plr.Team ~= Stores.you.status.team then
					table.insert(enemies,plr)
				end
			end
		end
		return enemies
	end,
	getAllies = function()
		local teammates = {}
		if Stores.you.status.inMatch then
			for _,plr in next,game.Players:GetPlayers() do
				if plr ~= Stores.you.lplr and plr:GetAttribute("Match") and plr:GetAttribute("Match") == Stores.you.status.matchId and plr.Team == Stores.you.status.team then
					table.insert(teammates,plr)
				end
			end
		end
		return teammates
	end,
	getTeamStatus = function(plr)
		if plr ~= Stores.you.lplr and plr:GetAttribute("Match") == Stores.you.status.matchId then
			if plr.Team ~= Stores.you.status.team then
				return "Enemy"
			else
				return "Ally"
			end
		end
	end,
	getGamemode = function()
		return Stores.you.lplr:GetAttribute("Gamemode")
	end,
	isAlive = function(character)
		return character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0
	end,
	getPlayerNearestCursor = function(size)
		local closest = size
		local target = nil
		for _,plr in next,game.Players:GetPlayers() do
			if plr ~= Stores.you.lplr and plr:GetAttribute("Match") == Stores.you.status.matchId then
				if plr.Team ~= Stores.you.status.team then
					if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						local vector = workspace.CurrentCamera:WorldToScreenPoint(plr.Character.HumanoidRootPart.Position)
						if vector then
							local magnitude = (game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(vector.X,vector.Y)).Magnitude
							if magnitude <= closest then
								closest = magnitude
								target = plr
							end
						end
					end
				end
			end
		end
		return target
	end,
	getKnife = function()
		local knife = nil
		for _,tool in next,Stores.you.lplr.Backpack:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"KnifeTool") then
					knife = tool
				end
			end
		end
		for _,tool in next,Stores.you.char:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"KnifeTool") then
					knife = tool
				end
			end
		end
		return knife
	end,
	getRevolver = function()
		local revolver = nil
		for _,tool in next,Stores.you.lplr.Backpack:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"GunTool") then
					revolver = tool
				end
			end
		end
		for _,tool in next,Stores.you.char:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"GunTool") then
					revolver = tool
				end
			end
		end
		return revolver
	end,
	antiafk = function()
	  game:GetService("Players").LocalPlayer.Idled:connect(function()
		  vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		  wait(1)
		  vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		end)
	end,
	joinHigh = function()
    local HttpService = game:GetService("HttpService")
    local request = syn and syn.request or http and http.request or http_request or request or httprequest
    
    local response = HttpService:JSONDecode(request({
        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=25&excludeFullGames=true",
        Method = "GET"
      }
     ).Body
    )
    
    local firstServer = response.data[1]
    if firstServer then
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,firstServer.id,game.Players.LocalPlayer)
    end
	end,
  joinLow = function()
    local HttpService = game:GetService("HttpService")
    local request = syn and syn.request or http and http.request or http_request or request or httprequest
    
    local response = HttpService:JSONDecode(request({
        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25",
        Method = "GET"
      }
     ).Body
    )
    
    local firstServer = response.data[1]
    if firstServer then
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,firstServer.id,game.Players.LocalPlayer)
    end
    
  end,
  rejoin = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
  end,
}

-- 🔗 Connections 🔗 --
local QuantumixConnections = {
    connections = {}
}

function QuantumixConnections:BindConnection(name,connect)
    if not QuantumixConnections.connections[name] then
		QuantumixConnections.connections[name] = connect
	else
		QuantumixConnections.connections[name]:Disconnect()
		QuantumixConnections.connections[name] = connect
	end
end

function QuantumixConnections:BindToRenderStep(name,func)
	local connect = game:GetService("RunService").RenderStepped:Connect(func)
	if not QuantumixConnections.connections[name] then
		QuantumixConnections.connections[name] = connect
	else
		QuantumixConnections.connections[name]:Disconnect()
		QuantumixConnections.connections[name] = connect
	end
end

function QuantumixConnections:BindToHeartbeat(name,func)
	local connect = game:GetService("RunService").Heartbeat:Connect(func)
	if not QuantumixConnections.connections[name] then
		QuantumixConnections.connections[name] = connect
	else
		QuantumixConnections.connections[name]:Disconnect()
		QuantumixConnections.connections[name] = connect
	end
end

function QuantumixConnections:BindToStep(name,func)
	local connect = game:GetService("RunService").Stepped:Connect(func)
	if not QuantumixConnections.connections[name] then
		QuantumixConnections.connections[name] = connect
	else
		QuantumixConnections.connections[name]:Disconnect()
		QuantumixConnections.connections[name] = connect
	end
end

function QuantumixConnections:UnbindConnection(name)
	if QuantumixConnections.connections[name] then
		QuantumixConnections.connections[name]:Disconnect()
	end
end

-- ✏️ Locals ✏️ --
Stores.you.status.team = Stores.you.lplr.Team or game.Players.LocalPlayer.Team
Stores.you.status.matchId = game.Players.LocalPlayer:GetAttribute("Match") ~= nil and game.Players.LocalPlayer:GetAttribute("Match") or 0
Stores.you.status.inMatch = (Stores.you.status.matchId ~= 0)
Stores.you.lplr.CharacterAdded:Connect(function(nchar)
	currentlyRespawning = true
	task.wait(1.5) -- "long" respawn debug delay because the script recieves errors for some reason :skull:
	Stores.you.char = nchar
	Stores.you.Humanoid = Stores.you.char:FindFirstChildOfClass("Humanoid") or nchar:FindFirstChildOfClass("Humanoid")
	Stores.you.status.team = Stores.you.lplr.Team or game.Players.LocalPlayer.Team
	Stores.you.status.matchId = game.Players.LocalPlayer:GetAttribute("Match") ~= nil and game.Players.LocalPlayer:GetAttribute("Match") or 0
	Stores.you.status.inMatch = (Stores.you.status.matchId ~= 0)
	task.wait()
	currentlyRespawning = false
end)
local currentlyRespawning = false
getgenv().autoKill = false
getgenv().headsize = 20
getgenv().usingHitbox = false
getgenv().usingEsp = false
getgenv().usingEspusingEspAllies = false
getgenv().usingLightSpeed = false
getgenv().usingSpeedSpoof = false
getgenv().usingThrowTroll = false
getgenv().usingBhop = false

-- 💉 Functions 💉 --
function killAll()
  spawn(function()
    while getgenv().autoKill == true do
      if not currentlyRespawning then
        if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
          local knife = Functions.getKnife()
          local revolver = Functions.getRevolver()
          if knife then
            if knife.Parent == Stores.you.lplr.Backpack then
              pcall(function() knife.Parent = Stores.you.char end)
            end
          else
            if revolver then
              if revolver.Parent == Stores.you.lplr.Backpack then
                pcall(function() revolver.Parent = Stores.you.char end)
              end
            end
        end
        for _,i in next, Functions.getEnemies() do
          local Character = i.Character
          local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
          local root = Character and Character:FindFirstChild("HumanoidRootPart")
          if root and Functions.isAlive(Character) then
            if knife then
              Stores.remotes.throwHitEvent:FireServer(unpack({
                [1] = Character.Head:FindFirstChild('Part'),
                [2] = Vector3.new()
              }))
            else
              if revolver then
                Stores.remotes.shootEvent:FireServer(unpack({
                  [1] = root.Position,
                  [2] = root.Position,
                  [3] = Character.Head:FindFirstChild("Part"),
                  [4] = root.Position
                }))
              end
            end
            -- wait()
          end
        end
      end
    end
      wait()
    end
  end)
end
function killAllV2()
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/notification_gui_library.lua", true))()
local Stores = {
  related = {
    GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
    LocalPlayer = game.Players.LocalPlayer,
		Character = game.Players.LocalPlayer.Character,
		Humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"),
		status = {
			matchId = 0,
			inMatch = false,
			gamemode = "classic",
			team = nil
		}
  },
  remotes = {
    shootEvent = game.ReplicatedStorage.Remotes.Shoot,
		throwStartEvent = game.ReplicatedStorage.Remotes.ThrowStart,
		throwHitEvent = game.ReplicatedStorage.Remotes.ThrowHit,
		stabEvent = game.ReplicatedStorage.Remotes.Stab,
		onMatchFinished = game.ReplicatedStorage.Remotes.OnMatchFinished,
		onRoundEnded = game.ReplicatedStorage.Remotes.OnRoundEnded,
		onPlayerKilled = game.ReplicatedStorage.Remotes.OnPlayerKilled,
		onRoleSelection = game.ReplicatedStorage.Remotes.OnRoleSelection
  }
}
local Functions = {
	calculateAngleBetweenPositions = function(pos1,pos2)
		local normal = Vector3.new()
		if pos1 and pos2 then
			normal = (pos1-pos2).Unit
		end
		return -normal
	end,
	getMouseLocation = function()
		return game:GetService("UserInputService"):GetMouseLocation()
	end,
	sayMessage = function(message)
		game:GetService("TextChatService").ChatInputBarConfiguration.TargetTextChannel:SendAsync(message)
	end,
	getEnemies = function()
		local enemies = {}
		if Stores.you.status.inMatch then
			for _,plr in next,game.Players:GetPlayers() do
				if plr ~= Stores.you.lplr and plr:GetAttribute("Match") and plr:GetAttribute("Match") == Stores.you.status.matchId and plr.Team ~= Stores.you.status.team then
					table.insert(enemies,plr)
				end
			end
		end
		return enemies
	end,
	getAllies = function()
		local teammates = {}
		if Stores.you.status.inMatch then
			for _,plr in next,game.Players:GetPlayers() do
				if plr ~= Stores.you.lplr and plr:GetAttribute("Match") and plr:GetAttribute("Match") == Stores.you.status.matchId and plr.Team == Stores.you.status.team then
					table.insert(teammates,plr)
				end
			end
		end
		return teammates
	end,
	getTeamStatus = function(plr)
		if plr ~= Stores.you.lplr and plr:GetAttribute("Match") == Stores.you.status.matchId then
			if plr.Team ~= Stores.you.status.team then
				return "Enemy"
			else
				return "Ally"
			end
		end
	end,
	getGamemode = function()
		return Stores.you.lplr:GetAttribute("Gamemode")
	end,
	isAlive = function(character)
		return character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0
	end,
	getPlayerNearestCursor = function(size)
		local closest = size
		local target = nil
		for _,plr in next,game.Players:GetPlayers() do
			if plr ~= Stores.you.lplr and plr:GetAttribute("Match") == Stores.you.status.matchId then
				if plr.Team ~= Stores.you.status.team then
					if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						local vector = workspace.CurrentCamera:WorldToScreenPoint(plr.Character.HumanoidRootPart.Position)
						if vector then
							local magnitude = (game:GetService("UserInputService"):GetMouseLocation() - Vector2.new(vector.X,vector.Y)).Magnitude
							if magnitude <= closest then
								closest = magnitude
								target = plr
							end
						end
					end
				end
			end
		end
		return target
	end,
	getKnife = function()
		local knife = nil
		for _,tool in next,Stores.you.lplr.Backpack:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"KnifeTool") then
					knife = tool
				end
			end
		end
		for _,tool in next,Stores.you.char:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"KnifeTool") then
					knife = tool
				end
			end
		end
		return knife
	end,
	getRevolver = function()
		local revolver = nil
		for _,tool in next,Stores.you.lplr.Backpack:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"GunTool") then
					revolver = tool
				end
			end
		end
		for _,tool in next,Stores.you.char:GetChildren() do
			if tool:IsA("Tool") then
				if game:GetService("CollectionService"):HasTag(tool,"GunTool") then
					revolver = tool
				end
			end
		end
		return revolver
	end,
	antiafk = function()
	  game:GetService("Players").LocalPlayer.Idled:connect(function()
		  vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		  wait(1)
		  vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		end)
	end,
	joinHigh = function()
    local HttpService = game:GetService("HttpService")
    local request = syn and syn.request or http and http.request or http_request or request or httprequest
    
    local response = HttpService:JSONDecode(request({
        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=25&excludeFullGames=true",
        Method = "GET"
      }
     ).Body
    )
    
    local firstServer = response.data[1]
    if firstServer then
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,firstServer.id,game.Players.LocalPlayer)
    end
	end,
  joinLow = function()
    local HttpService = game:GetService("HttpService")
    local request = syn and syn.request or http and http.request or http_request or request or httprequest
    
    local response = HttpService:JSONDecode(request({
        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25",
        Method = "GET"
      }
     ).Body
    )
    
    local firstServer = response.data[1]
    if firstServer then
      game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,firstServer.id,game.Players.LocalPlayer)
    end
    
  end,
  rejoin = function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
  end,
}

-- ✏️ Locals ✏️ --
Stores.you.status.team = Stores.you.lplr.Team or game.Players.LocalPlayer.Team
Stores.you.status.matchId = game.Players.LocalPlayer:GetAttribute("Match") ~= nil and game.Players.LocalPlayer:GetAttribute("Match") or 0
Stores.you.status.inMatch = (Stores.you.status.matchId ~= 0)
Stores.you.lplr.CharacterAdded:Connect(function(nchar)
	currentlyRespawning = true
	task.wait(1.5) -- "long" respawn debug delay because the script recieves errors for some reason :skull:
	Stores.you.char = nchar
	Stores.you.Humanoid = Stores.you.char:FindFirstChildOfClass("Humanoid") or nchar:FindFirstChildOfClass("Humanoid")
	Stores.you.status.team = Stores.you.lplr.Team or game.Players.LocalPlayer.Team
	Stores.you.status.matchId = game.Players.LocalPlayer:GetAttribute("Match") ~= nil and game.Players.LocalPlayer:GetAttribute("Match") or 0
	Stores.you.status.inMatch = (Stores.you.status.matchId ~= 0)
	task.wait()
	currentlyRespawning = false
end)
local currentlyRespawning = false
getgenv().autoKill = false
getgenv().headsize = 20
getgenv().usingHitbox = false
getgenv().usingEsp = false
getgenv().usingEspusingEspAllies = false
getgenv().usingLightSpeed = false
getgenv().usingSpeedSpoof = false

local highlight = Instance.new('Highlight')
highlight.Name = "Highlight"

-- 💉 Functions 💉 --
function killAll()
  spawn(function()
    while getgenv().autoKill == true do
      if not currentlyRespawning then
        if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
          local knife = Functions.getKnife()
          local revolver = Functions.getRevolver()
          if revolver then
            if revolver.Parent == Stores.you.lplr.Backpack then
              pcall(function() revolver.Parent = Stores.you.char end)
            end
          else
            if knife then
              if knife.Parent == Stores.you.lplr.Backpack then
                pcall(function() knife.Parent = Stores.you.char end)
              end
            end
        end
        for _,i in next, Functions.getEnemies() do
          local Character = i.Character
          local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
          local root = Character and Character:FindFirstChild("HumanoidRootPart")
          if root and Functions.isAlive(Character) then
            if revolver then
              Stores.remotes.shootEvent:FireServer(unpack({
                  [1] = root.Position,
                  [2] = root.Position,
                  [3] = Character.Head:FindFirstChild("Part"),
                  [4] = root.Position
                }))
            else
              if knife then
                Stores.remotes.throwHitEvent:FireServer(unpack({
                  [1] = Character.Head:FindFirstChild("Part"),
                  [2] = Vector3.new()
                }))
              end
            end
            -- wait()
          end
        end
      end
    end
      wait()
    end
  end)
end
function killAllV2()
  spawn(function()
    while getgenv().autoKill == true do
      if not currentlyRespawning then
        wait()
        if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
          local knife = Functions.getKnife()
          local revolver = Functions.getRevolver()
          if knife then
            if knife.Parent == Stores.you.lplr.Backpack then
              pcall(function() knife.Parent = Stores.you.char end)
            end
          else
            if revolver then
              if revolver.Parent == Stores.you.lplr.Backpack then
                pcall(function() revolver.Parent = Stores.you.char end)
              end
            end
        end
        for _,i in next, Functions.getEnemies() do
          local Character = i.Character
          local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
          local root = Character and Character:FindFirstChild("HumanoidRootPart")
          if root and Functions.isAlive(Character) then
            if knife then
              wait()
              Stores.remotes.throwHitEvent:FireServer(unpack({
                [1] = Character.Head:FindFirstChild("Part"),
                [2] = Vector3.new()
              }))
            else
              if revolver then
                wait()
                Stores.remotes.shootEvent:FireServer(unpack({
                  [1] = root.Position,
                  [2] = root.Position,
                  [3] = Character.Head:FindFirstChild("Part"),
                  [4] = root.Position
                }))
              end
            end
            wait()
          end
        end
      end
    end
      wait()
    end
  end)
end
function espEnemy()
  spawn(function()
    if getgenv().usingEsp == true then
      if not currentlyRespawning then
        game:GetService('RunService').RenderStepped:Connect(function()
          if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
            for i,v in next, Functions.getEnemies() do
              local Character = v.Character
              local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
              local root = Character and Character:FindFirstChild("HumanoidRootPart")
              repeat wait() until Character
              if root and Functions.isAlive(Character) then
                if not root:FindFirstChild('Highlight') then
                  local highlightClone = highlight:Clone()
                  highlightClone.Adornee = Character
                  highlightClone.Parent = root
                  highlightClone.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                  highlightClone.Name = "Highlight"
                end
              end
            end
          end
        end)
      end
    end
  end)
end
function espAllies()
  spawn(function()
    if getgenv().usingEspAllies == true then
      if not currentlyRespawning then
        game:GetService('RunService').RenderStepped:Connect(function()
          if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
            for i,v in next, Functions.getAllies() do
              local Character = v.Character
              local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
              local root = Character and Character:FindFirstChild("HumanoidRootPart")
              repeat wait() until Character
              if root and Functions.isAlive(Character) then
                if not root:FindFirstChild('Highlight') then
                  local highlightClone = highlight:Clone()
                  highlightClone.Adornee = Character
                  highlightClone.Parent = root
                  highlightClone.FillColor = Color3.fromRGB(100, 100, 255)
                  highlightClone.FillTransparency = 0.3
                  highlightClone.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                  highlightClone.Name = "Highlight"
                end
              end
            end
          end
        end)
      end
    end
  end)
end
function hitboxExpander()
  spawn(function()
    if getgenv().usingHitbox == true then
      if not currentlyRespawning then
        game:GetService('RunService').RenderStepped:connect(function()
          if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
            for i,v in next, Functions.getEnemies() do
              local Character = v.Character
              local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
              local root = Character and Character:FindFirstChild("HumanoidRootPart")
              repeat wait() until Character
              if root and Functions.isAlive(Character) then
                pcall(function()
                  root.Size = Vector3.new(getgenv().headsize, getgenv().headsize, getgenv().headsize)
                  root.Transparency = 0.8
                  root.BrickColor = BrickColor.new("Black")
                  root.Material = "Neon"
                  root.CanCollide = false
                end)
              else
                getgenv().headsize = 0
                root.Size = Vector3.new(getgenv().headsize, getgenv().headsize, getgenv().headsize)
                root.Transparency = 0.8
                root.BrickColor = BrickColor.new("Black")
                root.Material = "Neon"
                root.CanCollide = false
              end
            end
          end
        end)
      end
    end
  end)
end

-- 📂 Library 📂 --
local Window = OrionLib:MakeWindow({
  Name = "Quantumix HUB",
  HidePremium = false,
  SaveConfig = true, 
  ConfigFolder = "Quantumix",
  IntroEnabled = true,
  IntroText = "Quantumix HUB",
  IntroIcon = "rbxassetid://14692184203",
  Icon = "rbxassetid://14692184203"
})
local Tabs = {
  Home = Window:MakeTab({
    Name = "Home",
    Icon = "rbxassetid://14112128639",
    PremiumOnly = false
  }),
  Combat = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://14292092030",
    PremiumOnly = false
  }),
  Visuals = Window:MakeTab({
    Name = "Visuals",
    Icon = "rbxassetid://14700939807",
    PremiumOnly = false
  }),
  Players = Window:MakeTab({
    Name = "Players",
    Icon = "rbxassetid://14700969949",
    PremiumOnly = false
  }),
}

Tabs.Home:AddParagraph('Quantumix', 'Enhance your Roblox game experience with our innovative scripts and join us in building a vibrant exploiting community.')
Tabs.Home:AddParagraph("Info: ", "Executor: "..identifyexecutor().." | Game: "..Stores.you.GameName)
Tabs.Home:AddToggle({
  Name = "Anti AFK",
  Default = false,
  Callback = function(bool)
    if bool then
      Functions.antiafk()
    end
  end
})
Tabs.Home:AddButton({
  Name = "TP Highest Server",
  Callback = function()
    Functions.joinHigh()
  end
})
Tabs.Home:AddButton({
  Name = "TP Lowest Server",
  Callback = function()
    Functions.joinLow()
  end
})
Tabs.Home:AddButton({
  Name = "Rejoin",
  Callback = function()
    Functions.rejoin()
  end
})

Tabs.Combat:AddParagraph('Combat', 'Not yet finished and still has bugs')
Tabs.Combat:AddBind({
  Name = "Kill All (Bind)",
  Default = Enum.KeyCode.R,
  Callback = function()
    killAllV2()
  end
})
Tabs.Combat:AddBind({
  Name = 'Kill One (Bind)',
  Default = Enum.KeyCode.E,
  Callback = function()
    if Stores.you.inMatch and Functions.isAlive(Stores.you.char) then
      local revolver = Functions.getRevolver()
        if revolver then
          if revolver.Parent == Stores.you.lplr.Backpack then
            pcall(function() revolver.Parent = Stores.you.char end)
          end
          task.wait()
          for _,i in next, Functions.getEnemies() do
            local Character = i.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local root = Character and Character:FindFirstChild("HumanoidRootPart")
            if root and Functions.isAlive(Character) then
              if revolver then
                wait()
                Stores.remotes.shootEvent:FireServer(unpack({
                  [1] = root.Position,
                  [2] = root.Position,
                  [3] = Character.Head:FindFirstChild("Part"),
                  [4] = root.Position
                }))
              return
              end
            end
          end
        end
      end
    end
})
Tabs.Combat:AddToggle({
  Name = "Kill All",
  Default = false,
  Callback = function(bool)
    getgenv().autoKill = bool
    if bool then
      killAll()
    end
  end
})
Tabs.Combat:AddToggle({
  Name = "Hitbox Expander",
  Default = false,
  Callback = function(bool)
    getgenv().usingHitbox = bool
    if bool == true then
      getgenv().headsize = 20
      hitboxExpander()
    else
      getgenv().headsize = 0
      hitboxExpander()
    end
  end
})
Tabs.Combat:AddToggle({
  Name = "Lightspeed Knife",
  Default = false,
  Callback = function(bool)
    getgenv().usingLightSpeed = bool
    if bool then
      spawn(function()
        repeat
          local knife = Functions.getKnife()
          if knife then
            knife:SetAttribute("ThrowSpeed",1000)
          end
          wait()
        until getgenv().usingLightSpeed == false
      end)
    else
      local knife = Functions.getKnife()
      if knife then
        knife:SetAttribute("ThrowSpeed",125)
      end
    end
  end
})
Tabs.Combat:AddToggle({
  Name = "Fast Gun Cooldown",
  Default = false,
  Callback = function(bool)
    getgenv().usingSpeedSpoof = bool
    if bool then
      spawn(function()
        repeat
          local revolver = Functions.getRevolver()
          if revolver then
            revolver:SetAttribute("Cooldown",0.1)
          end
          wait()
        until getgenv().usingSpeedSpoof == false
      end)
    else
      local revolver = Functions.getRevolver()
      if revolver then
        revolver:SetAttribute("Cooldown",2.5)
      end
    end
  end
})

Tabs.Visuals:AddParagraph('ESP', 'Not yet finished, it still has a lot of bugs')
Tabs.Visuals:AddToggle({
  Name = "ESP Enemy",
  Default = false,
  Callback = function(bool)
    getgenv().usingEsp = bool
    if bool then
      espEnemy()
    end
  end
})
Tabs.Visuals:AddToggle({
  Name = "ESP Allies",
  Default = false,
  Callback = function(bool)
    getgenv().usingEspAllies = bool
    if bool then
      espAllies()
    end
  end
})
  spawn(function()
    while getgenv().autoKill == true do
      if not currentlyRespawning then
        wait()
        if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
          local knife = Functions.getKnife()
          local revolver = Functions.getRevolver()
          if knife then
            if knife.Parent == Stores.you.lplr.Backpack then
              pcall(function() knife.Parent = Stores.you.char end)
            end
          else
            if revolver then
              if revolver.Parent == Stores.you.lplr.Backpack then
                pcall(function() revolver.Parent = Stores.you.char end)
              end
            end
        end
        for _,i in next, Functions.getEnemies() do
          local Character = i.Character
          local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
          local root = Character and Character:FindFirstChild("HumanoidRootPart")
          if root and Functions.isAlive(Character) then
            if knife then
              wait()
              Stores.remotes.throwHitEvent:FireServer(unpack({
                [1] = Character.Head:FindFirstChild("Part"),
                [2] = Vector3.new()
              }))
            else
              if revolver then
                wait()
                Stores.remotes.shootEvent:FireServer(unpack({
                  [1] = root.Position,
                  [2] = root.Position,
                  [3] = Character.Head:FindFirstChild("Part"),
                  [4] = root.Position
                }))
              end
            end
            wait()
          end
        end
      end
    end
      wait()
    end
  end)
end
function hitboxExpander()
  spawn(function()
    if getgenv().usingHitbox == true then
      if not currentlyRespawning then
        game:GetService('RunService').RenderStepped:connect(function()
          if Stores.you.status.inMatch and Functions.isAlive(Stores.you.char) then
            for i,v in next, Functions.getEnemies() do
              local Character = v.Character
              local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
              local root = Character and Character:FindFirstChild("HumanoidRootPart")
              repeat wait() until Character
              if root and Functions.isAlive(Character) then
                pcall(function()
                  root.Size = Vector3.new(getgenv().headsize, getgenv().headsize, getgenv().headsize)
                  root.Transparency = 0.8
                  root.BrickColor = BrickColor.new("Black")
                  root.Material = "Neon"
                  root.CanCollide = false
                end)
              else
                getgenv().headsize = 0
                root.Size = Vector3.new(getgenv().headsize, getgenv().headsize, getgenv().headsize)
                root.Transparency = 0.8
                root.BrickColor = BrickColor.new("Black")
                root.Material = "Neon"
                root.CanCollide = false
              end
            end
          end
        end)
      end
    end
  end)
end
function removeUI()
  do
    local keyUI = game.CoreGui:FindFirstChild('QuantumixFPS')
    local keyUI2 = game:GetService('CoreGui').RobloxGui:FindFirstChild('QuantumixFPS')
    if keyUI or keyUI2 then
      keyUI:Destroy()
    end
  end
end
removeUI()

-- 📂 Library 📂 --
function createUI()
  if syn and typeof(syn) == "table" and RenderWindow then 
    syn.protect_gui = gethui
  end
  local function Hide_UI(gui)
    if HIDEUI then
      gui["Parent"] = HIDEUI()
    elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
      syn.protect_gui(gui)
      gui["Parent"] = CoreGUI
    elseif CoreGUI:FindFirstChild('RobloxGui') then
      gui["Parent"] = CoreGUI.RobloxGui
    else
      gui["Parent"] = CoreGUI
    end
  end
 
  local ScreenGUI = Instance.new("ScreenGui")
  local FPSLabel = Instance.new('TextLabel')
  
  ScreenGUI.Name = "QuantumixFPS"
  ScreenGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  ScreenGUI.IgnoreGuiInset = false
  ScreenGUI.ResetOnSpawn = false
  ScreenGUI.Parent = game.CoreGui
  Hide_UI(ScreenGUI)
  
  FPSLabel.Name = "Counter"
  FPSLabel.BackgroundTransparency = 1
  FPSLabel.Size = UDim2.new(1,0, 0, 30)
  FPSLabel.Position = UDim2.new(0, 0, 0, -10)
  FPSLabel.TextSize = 10
  FPSLabel.TextWrapped = true
  FPSLabel.TextColor3 = Color3.fromRGB(255,130,87)
  FPSLabel.Font = Enum.Font.Gotham
  FPSLabel.Parent = ScreenGUI
  
  Stores.services.RunService.RenderStepped:Connect(function(frame)
    FPSLabel.Text = "FPS: "..math.round(1/frame)
  end)
end
function createQuantumix()
  local Window = OrionLib:MakeWindow({
    Name = "Quantumix HUB",
    HidePremium = false,
    SaveConfig = true, 
    ConfigFolder = "Quantumix",
    IntroEnabled = true,
    IntroText = "Quantumix HUB",
    IntroIcon = "rbxassetid://14692184203",
    Icon = "rbxassetid://14692184203"
  })
  local Tabs = {
    Home = Window:MakeTab({
      Name = "Home",
      Icon = "rbxassetid://14112128639",
      PremiumOnly = false
    }),
    Combat = Window:MakeTab({
      Name = "Combat",
      Icon = "rbxassetid://14292092030",
      PremiumOnly = false
    }),
    Visuals = Window:MakeTab({
      Name = "Visuals",
      Icon = "rbxassetid://14700939807",
      PremiumOnly = false
    }),
    Players = Window:MakeTab({
      Name = "Players",
      Icon = "rbxassetid://14700969949",
      PremiumOnly = false
    }),
    Changelogs = Window:MakeTab({
      Name = "Changelogs",
      Icon = "rbxassetid://14692184203",
      PremiumOnly = false
    })
  }
  
  spawn(function()
    while wait() do
      local revolver = Functions.getRevolver()
      if revolver then
        revolver:SetAttribute("EquipAnimation","Sniper_Equip")
        revolver:SetAttribute("PulloutAnimation","Sniper_Pullout")
      end
    end
  end)
  
  local function WorldToViewportPoint(position)
	  local npos,vis = workspace.CurrentCamera:WorldToViewportPoint(workspace.CurrentCamera.CFrame:pointToWorldSpace(workspace.CurrentCamera.CFrame:pointToObjectSpace(position)))
	  return npos,vis
  end
  local function WorldToScreenPoint(position)
	  local npos,vis = workspace.CurrentCamera:WorldToScreenPoint(workspace.CurrentCamera.CFrame:pointToWorldSpace(workspace.CurrentCamera.CFrame:pointToObjectSpace(position)))
	  return npos,vis
  end
  
  Tabs.Home:AddParagraph('Quantumix', 'Enhance your Roblox game experience with our innovative scripts and join us in building a vibrant exploiting community.')
  Tabs.Home:AddParagraph("Info: ", "Executor: "..identifyexecutor().." | Game: "..Stores.you.GameName)
  Tabs.Home:AddToggle({
    Name = "Anti AFK",
    Default = false,
    Callback = function(bool)
      if bool then
        Functions.antiafk()
      end
    end
  })
  Tabs.Home:AddButton({
    Name = "TP Highest Server",
    Callback = function()
      Functions.joinHigh()
    end
  })
  Tabs.Home:AddButton({
    Name = "TP Lowest Server",
    Callback = function()
      Functions.joinLow()
    end
  })
  Tabs.Home:AddButton({
    Name = "Rejoin",
    Callback = function()
      Functions.rejoin()
    end
  })
  
  Tabs.Combat:AddParagraph('Combat', 'Not yet finished and still has bugs')
  Tabs.Combat:AddBind({
    Name = "Kill All (Bind)",
    Default = Enum.KeyCode.R,
    Callback = function()
      killAllV2()
    end
  })
  Tabs.Combat:AddBind({
    Name = 'Kill One (Bind)',
    Default = Enum.KeyCode.E,
    Callback = function()
      if Stores.you.inMatch and Functions.isAlive(Stores.you.char) then
        local revolver = Functions.getRevolver()
          if revolver then
            if revolver.Parent == Stores.you.lplr.Backpack then
              pcall(function() revolver.Parent = Stores.you.char end)
            end
            task.wait()
            for _,i in next, Functions.getEnemies() do
              local Character = i.Character
              local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
              local root = Character and Character:FindFirstChild("HumanoidRootPart")
              if root and Functions.isAlive(Character) then
                if revolver then
                  wait()
                  Stores.remotes.shootEvent:FireServer(unpack({
                    [1] = root.Position,
                    [2] = root.Position,
                    [3] = Character.Head:FindFirstChild("Part"),
                    [4] = root.Position
                  }))
                return
                end
              end
            end
          end
        end
      end
  })
  Tabs.Combat:AddToggle({
    Name = "Kill All",
    Default = false,
    Callback = function(bool)
      getgenv().autoKill = bool
      if bool then
        killAll()
      end
    end
  })
  Tabs.Combat:AddToggle({
    Name = "Fast Knife Throw",
    Default = false,
    Callback = function(bool)
      getgenv().usingLightSpeed = bool
      if bool then
        spawn(function()
          repeat
            local knife = Functions.getKnife()
            if knife then
              knife:SetAttribute("ThrowSpeed",1000)
            end
            wait()
          until getgenv().usingLightSpeed == false
        end)
      else
        local knife = Functions.getKnife()
        if knife then
          knife:SetAttribute("ThrowSpeed",125)
        end
      end
    end
  })
  Tabs.Combat:AddToggle({
    Name = "Fast Gun Cooldown",
    Default = false,
    Callback = function(bool)
      getgenv().usingSpeedSpoof = bool
      if bool then
        spawn(function()
          repeat
            local revolver = Functions.getRevolver()
            if revolver then
              revolver:SetAttribute("Cooldown",0.1)
            end
            wait()
          until getgenv().usingSpeedSpoof == false
        end)
      else
        local revolver = Functions.getRevolver()
        if revolver then
          revolver:SetAttribute("Cooldown",2.5)
        end
      end
    end
  })

  Tabs.Combat:AddParagraph('Aimbot Configs', 'Configure aimbot or silent aim!')
  local silentAim = false
  local silentAimFOVSize = 100
  local silentAimFOVVisible = false
  local silentAimWallbang = false
  local espRainbow = false
  
  local silentAimParams = RaycastParams.new()
  silentAimParams.RespectCanCollide = true
  silentAimParams.FilterType = Enum.RaycastFilterType.Exclude
  local circle = Drawing.new("Circle")
  circle.Thickness = 3
  circle.NumSides = 1e9
  circle.Radius = 100
  circle.Transparency = 0.3
  circle.Filled = false
  circle.Visible = false
  spawn(function()
    if espRainbow == true then
      while true do
        for hue = 0, 1, 1/30 do
          local color = Color3.fromHSV(hue, 0.6, 1)
          circle.Color = color
          wait(0.15)
        end
        wait()
      end
    else
      circle.Color = Color3.new(255,166,181)
    end
  end)
  local silentAimHooker
  silentAimHooker = hookmetamethod(game, "__namecall", function(self, ...)
  local args = {...}
  if silentAim and not checkcaller() and tostring(self) == "Shoot" and getnamecallmethod() == "FireServer" then
    local resolution = workspace.CurrentCamera.ViewportSize
    local nearest = Functions.getPlayerNearestCursor(silentAimFOVSize)
    if nearest then
      local hitbox = nearest.Character:FindFirstChild('HumanoidRootPart')
      args[2] = hitbox.CFrame.Position
      silentAimParams.FilterDescendantsInstances = {Stores.you.char, unpack(Functions.getAllies())}
      local result = workspace:Raycast(args[1], Functions.calculateAngleBetweenPositions(args[1], hitbox.CFrame.Position) * 9e9, silentAimParams)
      if result then
        args[3] = result.Instance
        args[4] = result.Position
        if silentAimWallbang then
          args[3] = hitbox:FindFirstChild("Part")
          args[4] = hitbox.CFrame.Position
        end
      else
        args[3] = hitbox:FindFirstChild("Part")
        args[4] = hitbox.CFrame.Position
      end
      end
        return self.FireServer(self,unpack(args))
      end
  return silentAimHooker(self,...)
  end)

  Tabs.Combat:AddToggle({
    Name = "Silent Aim (Gun)",
    Default = false,
    Callback = function(bool)
      silentAim = bool
      if bool then
        local resolution = workspace.CurrentCamera.ViewportSize
        QuantumixConnections:BindToHeartbeat("FOVCircleLoop", function()
            circle.Visible = silentAim and silentAimFOVVisible
            circle.Radius = silentAimFOVSize
            circle.Position = Functions.getMouseLocation()
          end)
      else
        QuantumixConnections:UnbindConnection("FOVCircleLoop")
        circle.Visible = false
      end
    end
  })
  Tabs.Combat:AddToggle({
    Name = "Show FOV Circle",
    Default = false,
    Callback = function(bool) 
      silentAimFOVVisible = bool
    end
  })
  Tabs.Combat:AddToggle({
    Name = "Bullet Wallbang",
    Default = false,
    Callback = function(bool)
      silentAimWallbang = bool
      print(tostring(silentAimWallbang))
    end
  })
  
  local allyColor = Color3.new(0,1,0)
  local enemyColor = Color3.new(1,0,0)
  local espOnlyOnEnemies = true
  local tracerOrigin = "Bottom"
  
  Tabs.Visuals:AddParagraph('Visuals', 'Not yet finished, it still has a lot of bugs')
  task.spawn(function()
    local chamsTable = {}
    
    local function drawHighlight(player)
      local highlight = Instance.new("Highlight",game.CoreGui)
      highlight.Adornee = player.Character
      highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      chamsTable[player.Name] = highlight
    end
    local function renewAdornee(player)
		  local cham = chamsTable[player.Name]
		  if cham then cham.Adornee = player.Character end
    end
    local function renewHighlights()
      for username,cham in next, chamsTable do
        local player = game.Players:FindFirstChild(username)
        if player and player.Character and player.Character.Parent == workspace then
          renewAdornee(player)
          local root = player.Character:FindFirstChild("HumanoidRootPart")
          if root then
            local _,rootVisible = WorldToViewportPoint(root.Position)
            if not rootVisible then
              cham.Enabled = false
              continue
            end
            if not player:GetAttribute("Match") or player:GetAttribute("Match") ~= Stores.you.status.matchId or not Functions.isAlive(player.Character) then
              cham.Enabled = false
              continue
            end
            if player.Character.Parent == game.ReplicatedStorage.HiddenCharacters then
						  cham.Enabled = false
						  continue
            end
            cham.Enabled = true
            if Stores.you.status.inMatch then
              if Functions.getTeamStatus(player) == "Enemy" then
                cham.Enabled = true
                cham.FillColor = enemyColor
                cham.OutlineColor = enemyColor
              elseif Functions.getTeamStatus(player) == "Ally" then
                if espOnlyOnEnemies then
                  cham.Enabled = false
                else
                  cham.Enabled = true
                end
                cham.FillColor = allyColor
                cham.OutlineColor = allyColor
              end
            else
              cham.Enabled = false
            end
          end
        end
      end
    end
    
    local chamsESP = {Default = false}
    chamsESP = Tabs.Visuals:AddToggle({
      Name = "ESP Chams",
      Default = false,
      Callback = function(bool)
        if bool then
          task.spawn(function()
            for _,i in next, game.Players:GetPlayers() do
              if i ~= Stores.you.lplr then
                drawHighlight(i)
              end
            end
            QuantumixConnections:BindConnection("DrawChamsOnEntityAdded",game.Players.PlayerAdded:Connect(function(plr)
						  if not chamsTable[plr.Name] then drawHighlight(plr) end
            end))
				    QuantumixConnections:BindConnection("RemoveChamsOnEntityRemoval",game.Players.PlayerRemoving:Connect(function(plr)
						  if chamsTable[plr.Name] then chamsTable[plr.Name]:Destroy() end
				    end))
				    QuantumixConnections:BindToRenderStep('ChamsUpdateLoop', function()
				      renewHighlights()
				    end)
          end)
        else
          task.spawn(function()
            for _,highlight in next, chamsTable do
              QuantumixConnections:UnbindConnection("DrawChamsOnEntityAdded")
              QuantumixConnections:UnbindConnection("RemoveChamsOnEntityRemoval")
              QuantumixConnections:UnbindConnection("ChamsUpdateLoop")
              highlight:Destroy()
            end
          end)
        end
      end
    })
  end)
  task.spawn(function()
    local tracersTable = {}
    local tracersESP = {Default = false}
    
    local function drawTracers(player)
      local tracer = Drawing.new('Line')
      tracer.Thickness = 2
      tracersTable[player.Name] = tracer
    end
    local function renewTracers()
      for username,tracer in next, tracersTable do
        local player = game.Players:FindFirstChild(username)
        if player and player.Character and player.Character.Parent == workspace then
          local root = player.Character:FindFirstChild("HumanoidRootPart")
          if root then
            local rootPosition,rootVisible = WorldToViewportPoint(root.Position)
            if not rootVisible then
              tracer.Visible = false
              continue
            end
            if not player:GetAttribute("Match") or player:GetAttribute("Match") ~= Stores.you.status.matchId or not Functions.isAlive(player.Character) then
              tracer.Visible = false
              continue
            end
            if player.Character.Parent == game.ReplicatedStorage.HiddenCharacters then
              tracer.Visible = false
              continue
            end
            local resolution = workspace.CurrentCamera.ViewportSize
            if tracerOrigin == "Bottom" then
              tracer.From = Vector2.new(resolution.X / 2,resolution.Y)
            elseif tracerOrigin == "Top" then
              tracer.From = Vector2.new(resolution.X / 2,0)
            elseif tracerOrigin == "Mouse" then
              tracer.From = Functions.getMouseLocation()
            elseif tracerOrigin == "Center" then
              tracer.From = Vector2.new(resolution.X / 2,resolution.Y / 2)
            end
            tracer.To = rootPosition
            tracer.Visible = true
            if Stores.you.status.inMatch then
              if Functions.getTeamStatus(player) == "Enemy" then
                tracer.Visible = true
                tracer.Color = enemyColor
              elseif Functions.getTeamStatus(player) == "Ally" then
                if espOnlyOnEnemies then
                  tracer.Visible = false
                else
                  tracer.Visible = true
                end
                tracer.Color = allyColor
              end
            else
              tracer.Visible = false
            end
          end
        end
      end
    end
    
    tracersESP = Tabs.Visuals:AddToggle({
      Name = "Tracer ESP",
      Default = false,
      Callback = function(bool)
        if bool then
          task.spawn(function()
            for _,i in next,game.Players:GetPlayers() do
              if i ~= Stores.you.lplr then
                drawTracers(i)
              end
            end
            QuantumixConnections:BindConnection("DrawTracersOnEntityAdded", game.Players.PlayerAdded:Connect(function(plr)
              if not tracersTable[plr.Name] then drawTracers(plr) end
            end))
            QuantumixConnections:BindConnection("RemoveTracersOnEntityRemoval",game.Players.PlayerRemoving:Connect(function(plr)
              if tracersTable[plr.Name] then tracersTable[plr.Name]:Destroy() end
            end))
            QuantumixConnections:BindToRenderStep("TracerUpdateLoop",function()
              renewTracers()
            end)
          end)
        else
          task.spawn(function()
            for _,tracer in next,tracersTable do
              QuantumixConnections:UnbindConnection("DrawTracersOnEntityAdded")
              QuantumixConnections:UnbindConnection("RemoveTracersOnEntityRemoval")
              QuantumixConnections:UnbindConnection("TracerUpdateLoop")
              tracer:Destroy()
            end
          end)
        end
      end
    })
  end)
  task.spawn(function()
    local nametagsTable = {}
    local tagTexts = {}
    local nametagsESP = {Default = false}
    local nametagsDisplayNames = {Default = true}
    local nametagsScale = {Default = 10}
    local nametagsDistance = {Default = false}
    
    local nametagsUI = Instance.new("ScreenGui",game.CoreGui)
    nametagsUI.Name = "QuantumixUIS"
    
    local function WorldToScreenPoint(position)
      local vector,vis = workspace.CurrentCamera:WorldToScreenPoint(position)
      return vector,vis
    end
    local function drawNametag(player)
      local tag = Instance.new("TextLabel",nametagsUI)
      tag.BackgroundColor3 = Color3.new()
      tag.Visible = false
      tag.RichText = true
      tag.AnchorPoint = Vector2.new(0.5,1)
      tag.Font = Enum.Font.GothamMedium
      tag.BackgroundTransparency = 0.5
      tagTexts[player.Name] = player.Name
      nametagsTable[player.Name] = tag
    end
    local function updateNametags()
      for username, tag in next, nametagsTable do
        local player = game.Players:FindFirstChild(username)
        if player and player.Character and player.Character.Parent == workspace then
          local root = player.Character:FindFirstChild("HumanoidRootPart")
          local head = player.Character:FindFirstChild("Head")
          if root and head then
            local rootPosition,rootVisible = WorldToViewportPoint(root.Position)
            local headPosition = WorldToScreenPoint((head.CFrame * CFrame.new(0, head.Size.Y + root.Size.Y + 2,0)).Position)
            if not rootVisible then
              tag.Visible = false
              continue
            end
            if not player:GetAttribute("Match") or player:GetAttribute("Match") ~= Stores.you.status.matchId or not Functions.isAlive(player.Character) then
              tag.Visible = false
              continue
            end
            if player.Character.Parent == game.ReplicatedStorage.HiddenCharacters then
              tag.Visible = false
              continue
            end
            tagTexts[player.Name] = nametagsDisplayNames.CurrentValue and player.DisplayName or player.Name
            if nametagsDistance.Default then
              local suc,distance = pcall(function() return (Stores.you.char:FindFirstChild("HumanoidRootPart").Position - root.Position).Magnitude end)
              if suc then
                tagTexts[player.Name] = tagTexts[player.Name] .. ' <font color="rgb(100,255,100)">[</font><font color="rgb(255,255,255)">'..math.floor(distance)..'</font><font color="rgb(100,255,100)">]</font>'
              end
            end
            local relativeSize = game:GetService("TextService"):GetTextSize(string.gsub(string.gsub(tagTexts[player.Name],"<br%s*/>","\n"),"<[^<>]->",""),14 * (nametagsScale.Default / 10),Enum.Font.GothamMedium,Vector2.new(1e5,1e5))
            tag.TextSize = 12 * (nametagsScale.Default / 10)
            tag.Size = UDim2.new(0,relativeSize.X + 4,0,relativeSize.Y)
            tag.Position = UDim2.new(0,headPosition.X,0,headPosition.Y)
            tag.Visible = true
            if Stores.you.status.inMatch then
              if Functions.getTeamStatus(player) == "Enemy" then
                tag.Visible = true
                tag.TextColor3 = enemyColor
              elseif Functions.getTeamStatus(player) == "Ally" then
                if espOnlyOnEnemies then
                  tag.Visible = false
                else
                  tag.Visible = true
                end
                tag.TextColor3 = allyColor
              end
            else
              tag.Visible = false
            end
            tag.Text = tagTexts[player.Name]
          end
        end
      end
    end
    
    nametagsESP = Tabs.Visuals:AddToggle({
      Name = "Nametag ESP",
      Default = false,
      Callback = function(bool)
        if bool then
          spawn(function()
            for _,i in next,game.Players:GetPlayers() do
              if i ~= Stores.you.lplr then
                drawNametag(i)
              end
            end
            QuantumixConnections:BindConnection('DrawNametagsOnEntityAdded', game.Players.PlayerAdded:Connect(function(plr)
              if not nametagsTable[plr.Name] then drawNametag(plr) end
            end))
            QuantumixConnections:BindConnection('RemoveNametagsOnEntityRemoval', game.Players.PlayerRemoving:Connect(function(plr)
              if nametagsTable[plr.Name] then nametagsTable[plr.Name]:Destroy() end
            end))
            QuantumixConnections:BindToRenderStep("NamtagUpdateLoop",function()
              updateNametags()
            end)
          end)
        else
          spawn(function()
            QuantumixConnections:UnbindConnection("DrawNametagsOnEntityAdded")
            QuantumixConnections:UnbindConnection("RemoveNametagsOnEntityRemoval")
            QuantumixConnections:UnbindConnection("NamtagUpdateLoop")
            for _,tracer in next, nametagsTable do
              tracer:Destroy()
            end
          end)
        end
      end
    })
  end)
  Tabs.Visuals:AddParagraph('Visuals Config', 'Configure visuals appearance')
  Tabs.Visuals:AddToggle({
    Name = "Team Check",
    Default = false,
    Callback = function(bool)
      espOnlyOnEnemies = bool
    end
  })
  Tabs.Visuals:AddToggle({
    Name = "Rainbow ESP",
    Default = false,
    Callback = function(bool)
      espRainbow = bool
      if bool then
        task.spawn(function()
          while espRainbow == true do
            for hue = 0, 1, 1/30 do
              local color = Color3.fromHSV(hue, 0.6, 1)
              enemyColor = color
              wait(0.15)
            end
            wait()
          end
        end)
      else
        task.spawn(function()
          espEnemy = Color3.new(1,0,0)
        end)
      end
    end
  })
  Tabs.Visuals:AddDropdown({
    Name = "Tracers Origin",
    Default = "Bottom",
    Options = {"Bottom","Top","Center"},
    Callback = function(value)
      tracerOrigin = value
    end
  })
  
  Tabs.Players:AddParagraph('Players', 'Not yet finished, might have some bugs')
  Tabs.Players:AddToggle({
    Name = "SpinBot",
    Default = false,
    Callback = function(bool)
      if bool then
        QuantumixConnections:BindToHeartbeat('SpinbotLoop', function()
          if not currentlyRespawning and Functions.isAlive(Stores.you.char) then
            local originalRot = Stores.you.char:WaitForChild("HumanoidRootPart").RotVelocity
            Stores.you.char:WaitForChild("HumanoidRootPart").RotVelocity = Vector3.new(originalRot.X,10,originalRot.Z)
          end
        end)
      else
        QuantumixConnections:UnbindConnection("SpinbotLoop")
      end
    end
  })
  Tabs.Players:AddToggle({
    Name = "BHop",
    Default = false,
    Callback = function(bool)
      getgenv().usingBhop = bool
      if bool then
        QuantumixConnections:BindToHeartbeat('SpamJump', function()
          if not currentlyRespawning then
            if Stores.you.char and Functions.isAlive(Stores.you.char) then
              if Stores.you.Humanoid.FloorMaterial ~= Enum.Material.Air and Stores.you.Humanoid.MoveDirection ~= Vector3.new() then
                if getgenv().usingBhop == true then
                  Stores.you.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                else
                  Stores.you.char:FindFirstChild("HumanoidRootPart").Velocity = Vector3.new(Stores.you.char:FindFirstChild("HumanoidRootPart").Velocity.X,25,Stores.you.char:FindFirstChild("HumanoidRootPart").Velocity.Z)
                end
              end
            end
          end
        end)
      else
        QuantumixConnections:UnbindConnection('SpamJump')
      end
    end
  })
  
  Tabs.Changelogs:AddParagraph('Murderer Vs Sheriff Duels | v1.0', 'Update 1, Build 10827102')
  Tabs.Changelogs:AddLabel('[+] Added Silent Aim')
  Tabs.Changelogs:AddLabel('[+] Added Tracers ESP')
end

-- 💾 Load Script 💾 --
--if game.PlaceId == 12355337193 or game.PlaceId == 13771457545 then
  --if PandaAuth:ValidateKey(ServiceName, _G.KeyInput) then
    createUI()
    createQuantumix()
  --end
--else
  --Notification.new('error', 'Bypass!', 'Fuck off!', true, 5)
  --wait(2)
  --game:Shutdown()
--end
