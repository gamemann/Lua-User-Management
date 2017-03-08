require("tmysql4");

--[[ Database. ]]--
local Database, lastError = ""; 

--[[ Predefined functions ]]--
local error, ErrorNoHalt, GetConVarNumber, GetConVarString, Msg, pairs, print, ServerLog, tonumber, tostring, tobool, unpack =
      error, ErrorNoHalt, GetConVarNumber, GetConVarString, Msg, pairs, print, ServerLog, tonumber, tostring, tobool, unpack ;

local concommand, game, hook, math, os, player, string, table, timer, mysqloo, gatekeeper =
      concommand, game, hook, math, os, player, string, table, timer, mysqloo, gatekeeper ;
	  
local tmysql, PrintTable, file = tmysql, PrintTable, file;

local function RecreateConnection() end

module("usermanagement");

local config = 
{
    hostname = "localhost";
    username = "root";
    password = "";
    database = "usermanagement";
	group1 = "Member";
	group2 = "Supporter";
	group3 = "VIP";
	debugToFile = true;
	debugNotificationsFile = "notifications.txt";
	debugErrorsFile = "errors.txt";
	debug = true;
	retryTimer = true;
	retryTimerValue = 300;
	refreshTimer = 300;
};

--[[ Tables ]]--
local users;

local queries = 
{
	["LoadUser"] = "SELECT `groupid` FROM `sb_perks` WHERE `steamid`='%s'"
};

--[[ Convenience Functions ]]--
local function notifyerror(...)
    ErrorNoHalt("[", os.date(), "][UserManagement.lua] ", ...);
    ErrorNoHalt("\n");
    print();
	
	if (config.debugToFile and config.debug) then
		local words = table.concat({"[",os.date(),"][UserManagement.lua] ",...},"").."\n";
		
		-- Create direction if it doesn't exist.
		if (not file.Exists("usermanagement/", "DATA")) then
			file.CreateDir("usermanagement");
		end
		
		file.Append("usermanagement/" .. config.debugErrorsFile, words);
	end
end

local function notifymessage(...)
    local words = table.concat({"[",os.date(),"][UserManagement.lua] ",...},"").."\n";
    print(words);
	
	if (config.debugToFile and config.debug) then
		-- Create direction if it doesn't exist.
		if (not file.Exists("usermanagement/", "DATA")) then
			file.CreateDir("usermanagement");
		end

		file.Append("usermanagement/" .. config.debugNotificationsFile, words);
	end
	
end

--[[ Query Functions ]]--
local loadUser;

local function loadUserCallback(ply, results)
	if (results == nil or not ply or not ply:IsPlayer() or not results[1].data[1]) then
		if (config.debug) then
			notifymessage("[GFL-UserManagement]loadUserCallback() :: Results are nil for \"" .. ply:SteamID64() .. "\".");
		end
			
		return;
	end
	
	local groupID = results[1].data[1].groupid;
	local sGroup = ply:GetUserGroup();
	
	if (sGroup == config.group1 or sGroup == config.group2 or sGroup == config.group3 or sGroup == "user") then
		if (groupID == 1) then
			-- Member.
			ply:SetUserGroup(config.group1);
		elseif (groupID == 2) then
			-- Supporter.
			ply:SetUserGroup(config.group2);
		elseif (groupID == 3) then
			-- VIP.
			ply:SetUserGroup(config.group3);
		end
		
		if (config.debug) then
			notifymessage("[GFL-UserManagement]loadUserCallback() :: User added with group ID " .. groupID .. " (" .. ply:SteamID64() .. ")");
		end
	else
		--[[ If they already have a custom group, go away! ]]--
		if (config.debug) then
			notifymessage("[GFL-UserManagement]loadUserCallback() :: User \"" .. ply:SteamID64() .. "\" (" .. ply:SteamID() .. ") is already in a group (" .. ply:GetUserGroup() .. ")! Aborting!");
		end
		
		return;
	end
end

-- Functions
function loadUser(ply)
	if (not ply or not ply:IsPlayer() or not Database or not Database:IsConnected()) then
		if (config.debug) then
			notifyerror("[GFL-UserManagement]loadUser() :: Connection not valid... Error: " .. lastError);
		end
		
		return;
	end
	
	if (config.debug) then
		notifymessage("[GFL-UserManagement]loadUser() :: " .. ply:Nick() .. " (\"" .. ply:SteamID64() .. "\") authed!");
	end
	
	local sSteamIDEscaped = Database:Escape(ply:SteamID64());
	local sQuery = queries["LoadUser"]:format(sSteamIDEscaped);
	
	Database:Query(sQuery, loadUserCallback, ply, false);
end

function loadUsers()
	for _,v in pairs (player.GetAll()) do
		loadUser(v);
	end
end

--[[ Hooks ]]--
do
    local function ShutDown()
        if Database then
			Database:Disconnect();
		end
	end

	local function PlayerInitialSpawn( ply )
		loadUser(ply)
    end
	
    hook.Add("ShutDown", "UserManagement.lua - ShutDown", ShutDown);
    hook.Add("PlayerInitialSpawn", "UserManagement.lua - PlayerInitialSpawn", PlayerInitialSpawn);
end

-- Keep the MySQL open.
local function KeepMySQLOpen()
	if (config.debug) then
		notifymessage("[GFL-UserManagement]KeepMySQLOpen() :: Checking database connection to ensure it is opened.");
	end
	
	if (not Database or not Database:IsConnected()) then
		if (config.debug) then
			notifyerror("[GFL-UserManagement]KeepMySQLOpen() :: Found the Database down. Reconnecting!");
		end
		
		Activate(true);
	end
end	

---
-- Starts the database and activates the module's functionality.
function Activate(bRetry)
	Database, lastError = tmysql.initialize(config.hostname, config.username, config.password, config.database, 3306, nil, CLIENT_MULTI_STATEMENTS);
	
	notifymessage("[GFL-UserManagement]Activate() :: Connecting to " .. config.hostname .. "!");
	
	if (not Database or not Database:IsConnected()) then
		notifyerror("[GFL-UserManagement]Activate() :: Error connecting to MySQL server. Error: " .. lastError);
	else
		notifymessage("[GFL-UserManagement]Activate() :: Successfully connected!");
		
		if (bRetry) then
			loadUsers();
		end
	end
	
	if (config.retryTimer) then
		if (timer.Exists("UM_KeepMySQLOpen")) then
			timer.Remove("UM_KeepMySQLOpen");
		end
		
		timer.Create("UM_KeepMySQLOpen", config.retryTimerValue, 0, KeepMySQLOpen);
	end
end

function SetConfig(key, value)
    if (config[key] == nil) then
        error("Invalid key provided. Please check your information.",2);
    end
	
    config[key] = value;
end

concommand.Add("um_reloadusers", function(ply, cmd)
    if (ply:IsPlayer() and ply:IsAdmin()) then
		notifymessage("[GFL-UserManagement]um_reloadusers() :: Executed by " .. ply:Nick() .. " (" .. ply:SteamID() .. ").");
		loadUsers();
		ply:ChatPrint("[GFL-UserManagement]Users reloaded.");
	else
		if (not ply:IsPlayer()) then
			loadUsers();
			print("[GFL-UserManagement]Users reloaded. [CONSOLE]");
		else
			notifymessage("[GFL-UserManagement]um_reloadusers() :: " .. ply:SteamID() .. " attempted \"um_reloadusers\" but is not an admin.");
			ply:ChatPrint("[GFL-UserManagement]You do not have access to this command.");
		end
	end
end, nil, "Reloads all users.");

concommand.Add("um_restart", function (ply, cmd)
	if (ply:IsPlayer()) then
		return;
	end
	
	RecreateConnection();
end);

concommand.Add("um_checkconnection", function (ply, cmd)
	if (Database and Database:IsConnected()) then
		print("connected..");
	else
		print("not connected");
	end
end);

-- Completely restart the MySQL connection for this addon.
local function RecreateConnection()
	if (config.debug) then
		notifymessage("[GFL-UserManagement]RecreateConnection() :: Recreating database connection!");
	end
	
	if (Database and Database:IsConnected()) then
		if (config.debug) then
			notifymessage("[GFL-UserManagement]RecreateConnection() :: Database active, releasing it!");
		end
		
		Database:Disconnect();
	end
	
	Activate(true);
end

-- Refresh timer
timer.Create("um_refreshtimer", config.refreshTimer, 0, function()
	loadUsers()
	
	if (config.debug) then
		notifymessage("[GFL-UserManagement]um_refreshtimer() :: Refresh timer ran")
	end
end)