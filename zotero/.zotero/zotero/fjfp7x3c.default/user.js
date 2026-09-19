// Zotero rewrites prefs.js on exit, so settings kept under version control go
// here instead - user.js is applied over prefs.js at every startup.
// https://www.zotero.org/support/kb/profile_directory
//
// The parent directory name is this install's random profile id; on a new
// machine check profiles.ini and rename to match before stowing.

user_pref("extensions.zotero.fontSize", "1.38");
user_pref("extensions.zotero.uiDensity", "compact");
user_pref("extensions.zotero.reader.darkTheme", "black");
user_pref("extensions.zotero.reader.textSelectionAnnotationMode", "underline");
user_pref("extensions.zotero.import.fileHandling", "copy");
user_pref("extensions.zotero.import.createCollection", false);
user_pref("extensions.zotero.sync.reminder.setUp.enabled", false);
