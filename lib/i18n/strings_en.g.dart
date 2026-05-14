///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAppEn app = TranslationsAppEn.internal(_root);
	late final TranslationsMenuEn menu = TranslationsMenuEn.internal(_root);
	late final TranslationsPreferencesEn preferences = TranslationsPreferencesEn.internal(_root);
	late final TranslationsAppMenuEn appMenu = TranslationsAppMenuEn.internal(_root);
	late final TranslationsKeybindingsEn keybindings = TranslationsKeybindingsEn.internal(_root);
	late final TranslationsCommandPaletteEn commandPalette = TranslationsCommandPaletteEn.internal(_root);
	late final TranslationsToastEn toast = TranslationsToastEn.internal(_root);
	late final TranslationsDragHintEn dragHint = TranslationsDragHintEn.internal(_root);
	late final TranslationsFileViewEn fileView = TranslationsFileViewEn.internal(_root);
	late final TranslationsSidebarEn sidebar = TranslationsSidebarEn.internal(_root);
	late final TranslationsToolbarEn toolbar = TranslationsToolbarEn.internal(_root);
	late final TranslationsNotificationsEn notifications = TranslationsNotificationsEn.internal(_root);
	late final TranslationsSearchEn search = TranslationsSearchEn.internal(_root);
	late final TranslationsStatusBarEn statusBar = TranslationsStatusBarEn.internal(_root);
	late final TranslationsDialogEn dialog = TranslationsDialogEn.internal(_root);
	late final TranslationsOperationsEn operations = TranslationsOperationsEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsTasksEn tasks = TranslationsTasksEn.internal(_root);
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Waydir'
	String get title => 'Waydir';
}

// Path: menu
class TranslationsMenuEn {
	TranslationsMenuEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Open $count Items'
	String openItems({required Object count}) => 'Open ${count} Items';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Cut'
	String get cut => 'Cut';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Copy Path'
	String get copyPath => 'Copy Path';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Delete $count Items'
	String deleteItems({required Object count}) => 'Delete ${count} Items';

	/// en: 'Show Hidden Files'
	String get showHidden => 'Show Hidden Files';

	/// en: 'Select All'
	String get selectAll => 'Select All';

	/// en: 'Open in Terminal'
	String get openInTerminal => 'Open in Terminal';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Open Location'
	String get openLocation => 'Open Location';

	/// en: 'Open in New Tab'
	String get openInNewTab => 'Open in New Tab';

	/// en: 'Remove Bookmark'
	String get removeBookmark => 'Remove Bookmark';

	/// en: 'Dual Pane Mode'
	String get dualPaneMode => 'Dual Pane Mode';
}

// Path: preferences
class TranslationsPreferencesEn {
	TranslationsPreferencesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Preferences'
	String get title => 'Preferences';

	/// en: 'Preferences…'
	String get menuLabel => 'Preferences…';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Coming soon'
	String get comingSoon => 'Coming soon';

	late final TranslationsPreferencesCategoriesEn categories = TranslationsPreferencesCategoriesEn.internal(_root);
	late final TranslationsPreferencesGeneralEn general = TranslationsPreferencesGeneralEn.internal(_root);
	late final TranslationsPreferencesAppearanceEn appearance = TranslationsPreferencesAppearanceEn.internal(_root);
	late final TranslationsPreferencesBookmarksEn bookmarks = TranslationsPreferencesBookmarksEn.internal(_root);
	late final TranslationsPreferencesAboutEn about = TranslationsPreferencesAboutEn.internal(_root);
}

// Path: appMenu
class TranslationsAppMenuEn {
	TranslationsAppMenuEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Quit'
	String get quit => 'Quit';
}

// Path: keybindings
class TranslationsKeybindingsEn {
	TranslationsKeybindingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keyboard Shortcuts'
	String get title => 'Keyboard Shortcuts';

	/// en: 'Shortcuts'
	String get menuLabel => 'Shortcuts';

	late final TranslationsKeybindingsCategoriesEn categories = TranslationsKeybindingsCategoriesEn.internal(_root);

	/// en: 'Open'
	String get openItem => 'Open';

	/// en: 'Go up'
	String get goUp => 'Go up';

	/// en: 'Go back'
	String get goBack => 'Go back';

	/// en: 'Go forward'
	String get goForward => 'Go forward';

	/// en: 'Move up'
	String get cursorUp => 'Move up';

	/// en: 'Move down'
	String get cursorDown => 'Move down';

	/// en: 'New tab'
	String get newTab => 'New tab';

	/// en: 'Close tab'
	String get closeTab => 'Close tab';

	/// en: 'Next tab'
	String get nextTab => 'Next tab';

	/// en: 'Previous tab'
	String get prevTab => 'Previous tab';

	/// en: 'Switch to tab'
	String get switchTab => 'Switch to tab';

	/// en: 'Toggle dual pane'
	String get toggleDual => 'Toggle dual pane';

	/// en: 'Switch active pane'
	String get switchPane => 'Switch active pane';

	/// en: 'Toggle sidebar'
	String get toggleSidebar => 'Toggle sidebar';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Cut'
	String get cut => 'Cut';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'New folder'
	String get newFolder => 'New folder';

	/// en: 'Copy to other pane'
	String get dualCopy => 'Copy to other pane';

	/// en: 'Move to other pane'
	String get dualMove => 'Move to other pane';

	/// en: 'Select all'
	String get selectAll => 'Select all';

	/// en: 'Deselect all'
	String get deselectAll => 'Deselect all';

	/// en: 'Toggle select'
	String get toggleSelect => 'Toggle select';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Recursive search'
	String get recursiveSearch => 'Recursive search';

	/// en: 'Close search'
	String get closeSearch => 'Close search';

	/// en: 'Command palette'
	String get commandPalette => 'Command palette';

	/// en: 'Preferences'
	String get preferences => 'Preferences';
}

// Path: commandPalette
class TranslationsCommandPaletteEn {
	TranslationsCommandPaletteEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Command Palette'
	String get title => 'Command Palette';

	/// en: 'Type a command or setting…'
	String get placeholder => 'Type a command or setting…';

	/// en: 'No matching commands'
	String get empty => 'No matching commands';

	/// en: 'Open Preferences'
	String get openPreferences => 'Open Preferences';

	/// en: 'Open the full settings dialog'
	String get preferencesSubtitle => 'Open the full settings dialog';

	/// en: 'Enabled'
	String get enabled => 'Enabled';

	/// en: 'Disabled'
	String get disabled => 'Disabled';
}

// Path: toast
class TranslationsToastEn {
	TranslationsToastEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copied $count items'
	String copiedItems({required Object count}) => 'Copied ${count} items';

	/// en: 'Cut $count items'
	String cutItems({required Object count}) => 'Cut ${count} items';

	/// en: '$label — $count errors'
	String taskErrors({required Object label, required Object count}) => '${label} — ${count} errors';

	/// en: 'An item named '$name' already exists'
	String renameAlreadyExists({required Object name}) => 'An item named \'${name}\' already exists';

	/// en: 'Invalid name'
	String get renameInvalidName => 'Invalid name';

	/// en: 'Could not rename: $message'
	String renameError({required Object message}) => 'Could not rename: ${message}';
}

// Path: dragHint
class TranslationsDragHintEn {
	TranslationsDragHintEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copy to "$name"'
	String copyTo({required Object name}) => 'Copy to "${name}"';

	/// en: 'Move to "$name"'
	String moveTo({required Object name}) => 'Move to "${name}"';

	/// en: '(Alt+drag to move)'
	String get tabToSwitch => '(Alt+drag to move)';
}

// Path: fileView
class TranslationsFileViewEn {
	TranslationsFileViewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moving $count items'
	String movingItems({required Object count}) => 'Moving ${count} items';

	/// en: 'Folder is empty'
	String get empty => 'Folder is empty';

	late final TranslationsFileViewColumnsEn columns = TranslationsFileViewColumnsEn.internal(_root);
}

// Path: sidebar
class TranslationsSidebarEn {
	TranslationsSidebarEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Favorites'
	String get favorites => 'Favorites';

	/// en: 'Devices'
	String get devices => 'Devices';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Desktop'
	String get desktop => 'Desktop';

	/// en: 'Documents'
	String get documents => 'Documents';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Pictures'
	String get pictures => 'Pictures';

	/// en: 'Music'
	String get music => 'Music';

	/// en: 'Videos'
	String get videos => 'Videos';

	/// en: 'Root'
	String get root => 'Root';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'Drop folder to bookmark'
	String get dropBookmark => 'Drop folder to bookmark';

	/// en: 'Collapse sidebar'
	String get collapse => 'Collapse sidebar';

	/// en: 'Expand sidebar'
	String get expand => 'Expand sidebar';
}

// Path: toolbar
class TranslationsToolbarEn {
	TranslationsToolbarEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Forward'
	String get forward => 'Forward';

	/// en: 'Up'
	String get up => 'Up';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'View Options'
	String get viewOptions => 'View Options';

	/// en: 'New Folder'
	String get newFolder => 'New Folder';

	/// en: 'Operations'
	String get operations => 'Operations';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Search'
	String get search => 'Search';
}

// Path: notifications
class TranslationsNotificationsEn {
	TranslationsNotificationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notifications'
	String get title => 'Notifications';

	/// en: 'No notifications yet'
	String get empty => 'No notifications yet';

	/// en: 'Clear'
	String get clear => 'Clear';
}

// Path: search
class TranslationsSearchEn {
	TranslationsSearchEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filter…'
	String get placeholder => 'Filter…';

	/// en: 'Subfolders'
	String get subfolders => 'Subfolders';

	/// en: 'Close search'
	String get close => 'Close search';

	/// en: '$count results'
	String results({required Object count}) => '${count} results';

	/// en: '$count found'
	String found({required Object count}) => '${count} found';

	/// en: '$dirs scanned'
	String scanning({required Object dirs}) => '${dirs} scanned';

	/// en: '(first $limit)'
	String truncated({required Object limit}) => '(first ${limit})';

	/// en: 'No matches'
	String get noMatches => 'No matches';

	/// en: 'Starting…'
	String get starting => 'Starting…';

	/// en: 'Clear search'
	String get clear => 'Clear search';
}

// Path: statusBar
class TranslationsStatusBarEn {
	TranslationsStatusBarEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '$count items'
	String items({required Object count}) => '${count} items';

	/// en: '$count folders'
	String folders({required Object count}) => '${count} folders';

	/// en: '$count files'
	String files({required Object count}) => '${count} files';

	/// en: '$count selected'
	String selected({required Object count}) => '${count} selected';
}

// Path: dialog
class TranslationsDialogEn {
	TranslationsDialogEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Folder name'
	String get folderNameHint => 'Folder name';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Delete?'
	String get confirmDeleteTitle => 'Delete?';

	/// en: 'Delete "$name"? This cannot be undone.'
	String confirmDeleteSingle({required Object name}) => 'Delete "${name}"? This cannot be undone.';

	/// en: 'Delete $count items? This cannot be undone.'
	String confirmDeleteMultiple({required Object count}) => 'Delete ${count} items? This cannot be undone.';
}

// Path: operations
class TranslationsOperationsEn {
	TranslationsOperationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Operations'
	String get title => 'Operations';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'No active operations'
	String get noActive => 'No active operations';

	/// en: 'Resolve Conflicts'
	String get resolveConflicts => 'Resolve Conflicts';

	/// en: '$count errors'
	String errorsCount({required Object count}) => '${count} errors';

	/// en: 'just now'
	String get justNow => 'just now';

	/// en: '${count}s ago'
	String secondsAgo({required Object count}) => '${count}s ago';

	/// en: '${count}m ago'
	String minutesAgo({required Object count}) => '${count}m ago';

	/// en: '${count}h ago'
	String hoursAgo({required Object count}) => '${count}h ago';

	/// en: 'Conflicts Detected'
	String get conflictsDetected => 'Conflicts Detected';

	/// en: '$count files already exist at the destination.'
	String filesExist({required Object count}) => '${count} files already exist at the destination.';

	/// en: 'Overwrite All'
	String get overwriteAll => 'Overwrite All';

	/// en: 'Skip All'
	String get skipAll => 'Skip All';

	/// en: 'Review'
	String get review => 'Review';

	/// en: 'File Conflict ($index/$total)'
	String fileConflict({required Object index, required Object total}) => 'File Conflict (${index}/${total})';

	/// en: 'Replace'
	String get replace => 'Replace';

	/// en: 'Keep Both'
	String get keepBoth => 'Keep Both';

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Errors ($count)'
	String errors({required Object count}) => 'Errors (${count})';

	/// en: '$processed / $count files'
	String filesCount({required Object processed, required Object count}) => '${processed} / ${count} files';

	/// en: 'A file with this name already exists:'
	String get fileExists => 'A file with this name already exists:';

	/// en: 'Source: $size · $date'
	String source({required Object size, required Object date}) => 'Source:  ${size} · ${date}';

	/// en: 'Target: $size · $date'
	String target({required Object size, required Object date}) => 'Target:  ${size} · ${date}';

	/// en: ' ← newer'
	String get newer => '  ← newer';

	/// en: 'Apply to all remaining conflicts ($count)'
	String applyToAll({required Object count}) => 'Apply to all remaining conflicts (${count})';
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Permission denied'
	String get permissionDenied => 'Permission denied';

	/// en: 'No space left on device'
	String get noSpace => 'No space left on device';

	/// en: 'Read-only file system'
	String get readOnly => 'Read-only file system';

	/// en: 'File not found'
	String get notFound => 'File not found';

	/// en: 'Directory not empty'
	String get notEmpty => 'Directory not empty';

	/// en: 'Cannot move across devices'
	String get crossDevice => 'Cannot move across devices';

	/// en: 'File appeared at destination during operation'
	String get appearedDuring => 'File appeared at destination during operation';
}

// Path: tasks
class TranslationsTasksEn {
	TranslationsTasksEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copying $name'
	String copyingSingle({required Object name}) => 'Copying ${name}';

	/// en: 'Copying $count items'
	String copyingMultiple({required Object count}) => 'Copying ${count} items';

	/// en: 'Moving $name'
	String movingSingle({required Object name}) => 'Moving ${name}';

	/// en: 'Moving $count items'
	String movingMultiple({required Object count}) => 'Moving ${count} items';

	/// en: 'Deleting $name'
	String deletingSingle({required Object name}) => 'Deleting ${name}';

	/// en: 'Deleting $count items'
	String deletingMultiple({required Object count}) => 'Deleting ${count} items';

	late final TranslationsTasksStatusEn status = TranslationsTasksStatusEn.internal(_root);
}

// Path: preferences.categories
class TranslationsPreferencesCategoriesEn {
	TranslationsPreferencesCategoriesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get general => 'General';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'About'
	String get about => 'About';
}

// Path: preferences.general
class TranslationsPreferencesGeneralEn {
	TranslationsPreferencesGeneralEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get title => 'General';

	/// en: 'Startup, file operations and terminal integration.'
	String get subtitle => 'Startup, file operations and terminal integration.';

	/// en: 'Startup'
	String get startupSection => 'Startup';

	/// en: 'Restore last session'
	String get restoreSession => 'Restore last session';

	/// en: 'Reopen previously open tabs and panes on launch.'
	String get restoreSessionHint => 'Reopen previously open tabs and panes on launch.';

	/// en: 'Default starting path'
	String get defaultPath => 'Default starting path';

	/// en: 'Used when session restore is disabled or empty.'
	String get defaultPathHint => 'Used when session restore is disabled or empty.';

	/// en: 'Browse…'
	String get browse => 'Browse…';

	/// en: 'File operations'
	String get fileOpsSection => 'File operations';

	/// en: 'Confirm before delete'
	String get confirmDelete => 'Confirm before delete';

	/// en: 'Show a dialog before removing files or folders.'
	String get confirmDeleteHint => 'Show a dialog before removing files or folders.';

	/// en: 'Terminal'
	String get terminalSection => 'Terminal';

	/// en: 'Default terminal'
	String get terminalLabel => 'Default terminal';

	/// en: 'Used by "Open in Terminal".'
	String get terminalHint => 'Used by "Open in Terminal".';

	/// en: 'Auto-detect'
	String get terminalAuto => 'Auto-detect';

	/// en: 'Custom command…'
	String get terminalCustom => 'Custom command…';

	/// en: 'Command'
	String get terminalCustomLabel => 'Command';

	/// en: 'e.g. kitty --working-directory={dir}'
	String get terminalCustomHint => 'e.g. kitty --working-directory={dir}';

	/// en: 'Use {dir} as a placeholder for the directory path.'
	String get terminalCustomHelp => 'Use {dir} as a placeholder for the directory path.';
}

// Path: preferences.appearance
class TranslationsPreferencesAppearanceEn {
	TranslationsPreferencesAppearanceEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Appearance'
	String get title => 'Appearance';

	/// en: 'Defaults for how files and the sidebar are displayed.'
	String get subtitle => 'Defaults for how files and the sidebar are displayed.';

	/// en: 'Files'
	String get filesSection => 'Files';

	/// en: 'Show hidden files by default'
	String get showHidden => 'Show hidden files by default';

	/// en: 'Applies to new tabs. Existing tabs keep their setting.'
	String get showHiddenHint => 'Applies to new tabs. Existing tabs keep their setting.';

	/// en: 'Row density'
	String get rowDensity => 'Row density';

	/// en: 'Comfortable'
	String get rowDensityComfortable => 'Comfortable';

	/// en: 'Compact'
	String get rowDensityCompact => 'Compact';

	/// en: 'Date format'
	String get dateFormat => 'Date format';

	/// en: 'ISO (2026-05-14 13:45)'
	String get dateFormatIso => 'ISO (2026-05-14 13:45)';

	/// en: 'System locale'
	String get dateFormatLocale => 'System locale';

	/// en: 'Relative (2h ago)'
	String get dateFormatRelative => 'Relative (2h ago)';

	/// en: 'Use relative dates for recent files'
	String get recentDatesRelative => 'Use relative dates for recent files';

	/// en: 'When System locale is selected, files modified in the last 24 hours show as relative.'
	String get recentDatesRelativeHint => 'When System locale is selected, files modified in the last 24 hours show as relative.';

	/// en: 'Sidebar'
	String get sidebarSection => 'Sidebar';

	/// en: 'Collapsed by default'
	String get sidebarCollapsed => 'Collapsed by default';
}

// Path: preferences.bookmarks
class TranslationsPreferencesBookmarksEn {
	TranslationsPreferencesBookmarksEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Bookmarks'
	String get title => 'Bookmarks';

	/// en: 'Manage folders pinned to the sidebar.'
	String get subtitle => 'Manage folders pinned to the sidebar.';

	/// en: 'No bookmarks yet. Drop a folder onto the sidebar to add one.'
	String get empty => 'No bookmarks yet. Drop a folder onto the sidebar to add one.';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Remove'
	String get remove => 'Remove';
}

// Path: preferences.about
class TranslationsPreferencesAboutEn {
	TranslationsPreferencesAboutEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About'
	String get title => 'About';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'Build'
	String get build => 'Build';

	/// en: 'Repository'
	String get repository => 'Repository';

	/// en: 'License'
	String get license => 'License';

	/// en: 'Copy'
	String get copy => 'Copy';
}

// Path: keybindings.categories
class TranslationsKeybindingsCategoriesEn {
	TranslationsKeybindingsCategoriesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Navigation'
	String get navigation => 'Navigation';

	/// en: 'Tabs'
	String get tabs => 'Tabs';

	/// en: 'Panes'
	String get panes => 'Panes';

	/// en: 'File Operations'
	String get fileOps => 'File Operations';

	/// en: 'Selection'
	String get selection => 'Selection';

	/// en: 'Search'
	String get search => 'Search';
}

// Path: fileView.columns
class TranslationsFileViewColumnsEn {
	TranslationsFileViewColumnsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Date modified'
	String get dateModified => 'Date modified';

	/// en: 'Location'
	String get location => 'Location';
}

// Path: tasks.status
class TranslationsTasksStatusEn {
	TranslationsTasksStatusEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Waiting...'
	String get waiting => 'Waiting...';

	/// en: 'Scanning files...'
	String get scanning => 'Scanning files...';

	/// en: '$count conflicts'
	String conflicts({required Object count}) => '${count} conflicts';

	/// en: '$current ($processed/$total)'
	String running({required Object current, required Object processed, required Object total}) => '${current} (${processed}/${total})';

	/// en: 'Cancelling...'
	String get cancelling => 'Cancelling...';

	/// en: 'Completed with $count errors'
	String completedWithErrors({required Object count}) => 'Completed with ${count} errors';

	/// en: 'Completed'
	String get completed => 'Completed';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Waydir',
			'menu.open' => 'Open',
			'menu.openItems' => ({required Object count}) => 'Open ${count} Items',
			'menu.copy' => 'Copy',
			'menu.cut' => 'Cut',
			'menu.paste' => 'Paste',
			'menu.copyPath' => 'Copy Path',
			'menu.delete' => 'Delete',
			'menu.deleteItems' => ({required Object count}) => 'Delete ${count} Items',
			'menu.showHidden' => 'Show Hidden Files',
			'menu.selectAll' => 'Select All',
			'menu.openInTerminal' => 'Open in Terminal',
			'menu.rename' => 'Rename',
			'menu.openLocation' => 'Open Location',
			'menu.openInNewTab' => 'Open in New Tab',
			'menu.removeBookmark' => 'Remove Bookmark',
			'menu.dualPaneMode' => 'Dual Pane Mode',
			'preferences.title' => 'Preferences',
			'preferences.menuLabel' => 'Preferences…',
			'preferences.close' => 'Close',
			'preferences.comingSoon' => 'Coming soon',
			'preferences.categories.general' => 'General',
			'preferences.categories.appearance' => 'Appearance',
			'preferences.categories.bookmarks' => 'Bookmarks',
			'preferences.categories.about' => 'About',
			'preferences.general.title' => 'General',
			'preferences.general.subtitle' => 'Startup, file operations and terminal integration.',
			'preferences.general.startupSection' => 'Startup',
			'preferences.general.restoreSession' => 'Restore last session',
			'preferences.general.restoreSessionHint' => 'Reopen previously open tabs and panes on launch.',
			'preferences.general.defaultPath' => 'Default starting path',
			'preferences.general.defaultPathHint' => 'Used when session restore is disabled or empty.',
			'preferences.general.browse' => 'Browse…',
			'preferences.general.fileOpsSection' => 'File operations',
			'preferences.general.confirmDelete' => 'Confirm before delete',
			'preferences.general.confirmDeleteHint' => 'Show a dialog before removing files or folders.',
			'preferences.general.terminalSection' => 'Terminal',
			'preferences.general.terminalLabel' => 'Default terminal',
			'preferences.general.terminalHint' => 'Used by "Open in Terminal".',
			'preferences.general.terminalAuto' => 'Auto-detect',
			'preferences.general.terminalCustom' => 'Custom command…',
			'preferences.general.terminalCustomLabel' => 'Command',
			'preferences.general.terminalCustomHint' => 'e.g. kitty --working-directory={dir}',
			'preferences.general.terminalCustomHelp' => 'Use {dir} as a placeholder for the directory path.',
			'preferences.appearance.title' => 'Appearance',
			'preferences.appearance.subtitle' => 'Defaults for how files and the sidebar are displayed.',
			'preferences.appearance.filesSection' => 'Files',
			'preferences.appearance.showHidden' => 'Show hidden files by default',
			'preferences.appearance.showHiddenHint' => 'Applies to new tabs. Existing tabs keep their setting.',
			'preferences.appearance.rowDensity' => 'Row density',
			'preferences.appearance.rowDensityComfortable' => 'Comfortable',
			'preferences.appearance.rowDensityCompact' => 'Compact',
			'preferences.appearance.dateFormat' => 'Date format',
			'preferences.appearance.dateFormatIso' => 'ISO (2026-05-14 13:45)',
			'preferences.appearance.dateFormatLocale' => 'System locale',
			'preferences.appearance.dateFormatRelative' => 'Relative (2h ago)',
			'preferences.appearance.recentDatesRelative' => 'Use relative dates for recent files',
			'preferences.appearance.recentDatesRelativeHint' => 'When System locale is selected, files modified in the last 24 hours show as relative.',
			'preferences.appearance.sidebarSection' => 'Sidebar',
			'preferences.appearance.sidebarCollapsed' => 'Collapsed by default',
			'preferences.bookmarks.title' => 'Bookmarks',
			'preferences.bookmarks.subtitle' => 'Manage folders pinned to the sidebar.',
			'preferences.bookmarks.empty' => 'No bookmarks yet. Drop a folder onto the sidebar to add one.',
			'preferences.bookmarks.rename' => 'Rename',
			'preferences.bookmarks.remove' => 'Remove',
			'preferences.about.title' => 'About',
			'preferences.about.version' => 'Version',
			'preferences.about.build' => 'Build',
			'preferences.about.repository' => 'Repository',
			'preferences.about.license' => 'License',
			'preferences.about.copy' => 'Copy',
			'appMenu.quit' => 'Quit',
			'keybindings.title' => 'Keyboard Shortcuts',
			'keybindings.menuLabel' => 'Shortcuts',
			'keybindings.categories.navigation' => 'Navigation',
			'keybindings.categories.tabs' => 'Tabs',
			'keybindings.categories.panes' => 'Panes',
			'keybindings.categories.fileOps' => 'File Operations',
			'keybindings.categories.selection' => 'Selection',
			'keybindings.categories.search' => 'Search',
			'keybindings.openItem' => 'Open',
			'keybindings.goUp' => 'Go up',
			'keybindings.goBack' => 'Go back',
			'keybindings.goForward' => 'Go forward',
			'keybindings.cursorUp' => 'Move up',
			'keybindings.cursorDown' => 'Move down',
			'keybindings.newTab' => 'New tab',
			'keybindings.closeTab' => 'Close tab',
			'keybindings.nextTab' => 'Next tab',
			'keybindings.prevTab' => 'Previous tab',
			'keybindings.switchTab' => 'Switch to tab',
			'keybindings.toggleDual' => 'Toggle dual pane',
			'keybindings.switchPane' => 'Switch active pane',
			'keybindings.toggleSidebar' => 'Toggle sidebar',
			'keybindings.copy' => 'Copy',
			'keybindings.cut' => 'Cut',
			'keybindings.paste' => 'Paste',
			'keybindings.delete' => 'Delete',
			'keybindings.rename' => 'Rename',
			'keybindings.newFolder' => 'New folder',
			'keybindings.dualCopy' => 'Copy to other pane',
			'keybindings.dualMove' => 'Move to other pane',
			'keybindings.selectAll' => 'Select all',
			'keybindings.deselectAll' => 'Deselect all',
			'keybindings.toggleSelect' => 'Toggle select',
			'keybindings.search' => 'Search',
			'keybindings.recursiveSearch' => 'Recursive search',
			'keybindings.closeSearch' => 'Close search',
			'keybindings.commandPalette' => 'Command palette',
			'keybindings.preferences' => 'Preferences',
			'commandPalette.title' => 'Command Palette',
			'commandPalette.placeholder' => 'Type a command or setting…',
			'commandPalette.empty' => 'No matching commands',
			'commandPalette.openPreferences' => 'Open Preferences',
			'commandPalette.preferencesSubtitle' => 'Open the full settings dialog',
			'commandPalette.enabled' => 'Enabled',
			'commandPalette.disabled' => 'Disabled',
			'toast.copiedItems' => ({required Object count}) => 'Copied ${count} items',
			'toast.cutItems' => ({required Object count}) => 'Cut ${count} items',
			'toast.taskErrors' => ({required Object label, required Object count}) => '${label} — ${count} errors',
			'toast.renameAlreadyExists' => ({required Object name}) => 'An item named \'${name}\' already exists',
			'toast.renameInvalidName' => 'Invalid name',
			'toast.renameError' => ({required Object message}) => 'Could not rename: ${message}',
			'dragHint.copyTo' => ({required Object name}) => 'Copy to "${name}"',
			'dragHint.moveTo' => ({required Object name}) => 'Move to "${name}"',
			'dragHint.tabToSwitch' => '(Alt+drag to move)',
			'fileView.movingItems' => ({required Object count}) => 'Moving ${count} items',
			'fileView.empty' => 'Folder is empty',
			'fileView.columns.name' => 'Name',
			'fileView.columns.size' => 'Size',
			'fileView.columns.dateModified' => 'Date modified',
			'fileView.columns.location' => 'Location',
			'sidebar.favorites' => 'Favorites',
			'sidebar.devices' => 'Devices',
			'sidebar.home' => 'Home',
			'sidebar.desktop' => 'Desktop',
			'sidebar.documents' => 'Documents',
			'sidebar.downloads' => 'Downloads',
			'sidebar.pictures' => 'Pictures',
			'sidebar.music' => 'Music',
			'sidebar.videos' => 'Videos',
			'sidebar.root' => 'Root',
			'sidebar.bookmarks' => 'Bookmarks',
			'sidebar.dropBookmark' => 'Drop folder to bookmark',
			'sidebar.collapse' => 'Collapse sidebar',
			'sidebar.expand' => 'Expand sidebar',
			'toolbar.back' => 'Back',
			'toolbar.forward' => 'Forward',
			'toolbar.up' => 'Up',
			'toolbar.refresh' => 'Refresh',
			'toolbar.viewOptions' => 'View Options',
			'toolbar.newFolder' => 'New Folder',
			'toolbar.operations' => 'Operations',
			'toolbar.notifications' => 'Notifications',
			'toolbar.search' => 'Search',
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'No notifications yet',
			'notifications.clear' => 'Clear',
			'search.placeholder' => 'Filter…',
			'search.subfolders' => 'Subfolders',
			'search.close' => 'Close search',
			'search.results' => ({required Object count}) => '${count} results',
			'search.found' => ({required Object count}) => '${count} found',
			'search.scanning' => ({required Object dirs}) => '${dirs} scanned',
			'search.truncated' => ({required Object limit}) => '(first ${limit})',
			'search.noMatches' => 'No matches',
			'search.starting' => 'Starting…',
			'search.clear' => 'Clear search',
			'statusBar.items' => ({required Object count}) => '${count} items',
			'statusBar.folders' => ({required Object count}) => '${count} folders',
			'statusBar.files' => ({required Object count}) => '${count} files',
			'statusBar.selected' => ({required Object count}) => '${count} selected',
			'dialog.create' => 'Create',
			'dialog.cancel' => 'Cancel',
			'dialog.folderNameHint' => 'Folder name',
			'dialog.close' => 'Close',
			'dialog.delete' => 'Delete',
			'dialog.confirmDeleteTitle' => 'Delete?',
			'dialog.confirmDeleteSingle' => ({required Object name}) => 'Delete "${name}"? This cannot be undone.',
			'dialog.confirmDeleteMultiple' => ({required Object count}) => 'Delete ${count} items? This cannot be undone.',
			'operations.title' => 'Operations',
			'operations.clear' => 'Clear',
			'operations.noActive' => 'No active operations',
			'operations.resolveConflicts' => 'Resolve Conflicts',
			'operations.errorsCount' => ({required Object count}) => '${count} errors',
			'operations.justNow' => 'just now',
			'operations.secondsAgo' => ({required Object count}) => '${count}s ago',
			'operations.minutesAgo' => ({required Object count}) => '${count}m ago',
			'operations.hoursAgo' => ({required Object count}) => '${count}h ago',
			'operations.conflictsDetected' => 'Conflicts Detected',
			'operations.filesExist' => ({required Object count}) => '${count} files already exist at the destination.',
			'operations.overwriteAll' => 'Overwrite All',
			'operations.skipAll' => 'Skip All',
			'operations.review' => 'Review',
			'operations.fileConflict' => ({required Object index, required Object total}) => 'File Conflict (${index}/${total})',
			'operations.replace' => 'Replace',
			'operations.keepBoth' => 'Keep Both',
			'operations.skip' => 'Skip',
			'operations.errors' => ({required Object count}) => 'Errors (${count})',
			'operations.filesCount' => ({required Object processed, required Object count}) => '${processed} / ${count} files',
			'operations.fileExists' => 'A file with this name already exists:',
			'operations.source' => ({required Object size, required Object date}) => 'Source:  ${size} · ${date}',
			'operations.target' => ({required Object size, required Object date}) => 'Target:  ${size} · ${date}',
			'operations.newer' => '  ← newer',
			'operations.applyToAll' => ({required Object count}) => 'Apply to all remaining conflicts (${count})',
			'errors.permissionDenied' => 'Permission denied',
			'errors.noSpace' => 'No space left on device',
			'errors.readOnly' => 'Read-only file system',
			'errors.notFound' => 'File not found',
			'errors.notEmpty' => 'Directory not empty',
			'errors.crossDevice' => 'Cannot move across devices',
			'errors.appearedDuring' => 'File appeared at destination during operation',
			'tasks.copyingSingle' => ({required Object name}) => 'Copying ${name}',
			'tasks.copyingMultiple' => ({required Object count}) => 'Copying ${count} items',
			'tasks.movingSingle' => ({required Object name}) => 'Moving ${name}',
			'tasks.movingMultiple' => ({required Object count}) => 'Moving ${count} items',
			'tasks.deletingSingle' => ({required Object name}) => 'Deleting ${name}',
			'tasks.deletingMultiple' => ({required Object count}) => 'Deleting ${count} items',
			'tasks.status.waiting' => 'Waiting...',
			'tasks.status.scanning' => 'Scanning files...',
			'tasks.status.conflicts' => ({required Object count}) => '${count} conflicts',
			'tasks.status.running' => ({required Object current, required Object processed, required Object total}) => '${current} (${processed}/${total})',
			'tasks.status.cancelling' => 'Cancelling...',
			'tasks.status.completedWithErrors' => ({required Object count}) => 'Completed with ${count} errors',
			'tasks.status.completed' => 'Completed',
			'tasks.status.failed' => 'Failed',
			'tasks.status.cancelled' => 'Cancelled',
			_ => null,
		};
	}
}
