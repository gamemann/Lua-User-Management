require("mysqloo");

--[[ Predefined functions ]]--
local error, ErrorNoHalt, GetConVarNumber, GetConVarString, Msg, pairs, print, ServerLog, tonumber, tostring, tobool, unpack =
      error, ErrorNoHalt, GetConVarNumber, GetConVarString, Msg, pairs, print, ServerLog, tonumber, tostring, tobool, unpack;

local concommand, game, hook, math, os, player, string, table, timer, mysqloo, gatekeeper, IsValid =
      concommand, game, hook, math, os, player, string, table, timer, mysqloo, gatekeeper, IsValid;
	  
local tmysql, PrintTable, file = tmysql, PrintTable, file;


--[[ Database. ]]--
local Db
local bActive = false

--[[ Query functions. ]]--
local queryLoadUser

module("usermanagement");

local config = 
{
    hostname = "localhost";
    username = "root";
    password = "";
    database = "usermanagement";
	port = 3306;
	groups = {};
	excludeAdmins = true;
	debug = false;
	debugDebugFile = "notifications.txt";
	debugErrorsFile = "errors.txt";
};

--[[ Convenience Functions ]]--
local function printMsg(sFile, sMsg)
	local words = table.concat({"[UM] ", sMsg}, "") .. "\n";
	print(words)
		
	-- Create direction if it doesn't exist.
	if (not file.Exists("usermanagement/", "DATA")) then
		file.CreateDir("usermanagement");
	end
	
	file.Append("usermanagement/" .. sFile, "[" .. os.date() .. "] " .. words);
end

function SetConfig(key, value)
    if (config[key] == nil) then
        error("Invalid key provided. Please check your information.",2);
    end
	
    config[key] = value;
end

--[[ Queries ]] --
local arrQueries = 
{
	["LoadUser"] = "SELECT `groupid` FROM `sb_perks` WHERE `steamid`='%s'"
}

local function ConnectToDB()
	Db = mysqloo.connect(config.hostname, config.username, config.password, config.database, config.port)
	
	Db:setAutoReconnect(true)
	
	--[[ Database connection functions ]]--
	function Db:onConnected()
		bActive = true
		
		if config.debug then
			printMsg(config.debugDebugFile, "Successfully connected to the database!")
		end
	end

	function Db:onConnectionFailed(sErr)
		printMsg(config.debugErrorsFile, "Error connecting to the database. User Management not active. Error: " .. sErr)
		bActive = false
	end
	
	-- Connect to the database!
	Db:connect()
end

function Activate()
	ConnectToDB()
end

local function loadUser(ply)
	if not ply or not bActive then return end
	
	if config.excludeAdmins and ply:IsAdmin() then return end
	
	local sSteamID = ply:SteamID64()
	local sLookUp = Db:escape(sSteamID)
	
	local sqlStr = arrQueries["LoadUser"]:format(sLookUp)
	
	queryLoadUser = Db:query(sqlStr)
	
	function queryLoadUser:onError(sErr, sSQL)
		printMsg(config.debugErrorsFile, "Error executing query: \"" .. sSQL .. "\". Error: " .. sErr)
	end

	function queryLoadUser:onData(data)
		if not data then return end
		
		if config.debug then
			printMsg(config.debugDebugFile, "Loading user " .. ply:Nick() .. " (" .. sSteamID .. ") with group '" .. config.groups[data["groupid"]] .. "' (" .. data["groupid"] .. ")!")
		end
		
		ply:SetUserGroup(config.groups[data["groupid"]])
	end
	
	queryLoadUser:start()
end

local function loadUsers()
	for k,v in pairs(player.GetAll()) do
		loadUser(v)
	end
end

hook.Add("PlayerInitialSpawn", "UM_PlayerInitialSpawn", function (ply)
	loadUser(ply)
end)

concommand.Add("um_reloadusers", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then
		ply:ChatPrint("[UM] You must be a Super Admin to run this command!")
		return
	end
	
	loadUsers()
	
	if IsValid(ply) then
		ply:ChatPrint("[UM] All users reloaded.")
	else
		print("[UM] All users reloaded.")
	end
end)

concommand.Add("um_restart", function(ply)
	if IsValid(ply) and not ply:IsSuperAdmin() then
		ply:ChatPrint("[UM] You must be a Super Admin to run this command!")
		return
	end
	
	Db:disconnect(true)
	
	ConnectToDB()
	
	if IsValid(ply) then
		ply:ChatPrint("[UM] Attempting to restart User Management.")
	else
		print("[UM] Attempting to restart User Management.")
	end
end)