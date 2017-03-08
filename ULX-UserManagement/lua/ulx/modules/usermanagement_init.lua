require("usermanagement")
usermanagement.SetConfig("hostname", "myHost.com");
usermanagement.SetConfig("username", "myUser");
usermanagement.SetConfig("password", "myPass");
usermanagement.SetConfig("database", "myDatabase");

-- Only three groups supported. Edit this if you absolutely need to edit the group names (e.g. if they have to be lower-case or something). I would prefer keeping it as it is.
usermanagement.SetConfig("group1", "member");
usermanagement.SetConfig("group2", "supporter");
usermanagement.SetConfig("group3", "vip");

-- Other options
usermanagement.SetConfig("debug", false);
usermanagement.SetConfig("debugToFile", true);
usermanagement.SetConfig("debugNotificationsFile", "notifications.txt");
usermanagement.SetConfig("debugErrorsFile", "errors.txt");
usermanagement.SetConfig("retryTimer", false);
usermanagement.SetConfig("retryTimerValue", 300);
usermanagement.SetConfig("refreshTimer", 300);

usermanagement.Activate(false);