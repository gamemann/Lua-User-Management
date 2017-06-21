require("usermanagement")
usermanagement.SetConfig("hostname", "myHost");
usermanagement.SetConfig("username", "myUser");
usermanagement.SetConfig("password", "myPass");
usermanagement.SetConfig("database", "myDatabase");
usermanagement.SetConfig("port", 3306);

-- Groups (ID => Name)
local groups = 
{
	[1] = "member",
	[2] = "supporter",
	[3] = "vip"
}
usermanagement.SetConfig("groups", groups);
usermanagement.SetConfig("excludeAdmins", true)

-- Other options
usermanagement.SetConfig("debug", true);
usermanagement.SetConfig("debugDebugFile", "debug.txt");
usermanagement.SetConfig("debugErrorsFile", "errors.txt");

usermanagement.Activate();