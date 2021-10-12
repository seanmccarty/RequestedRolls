local dungeonsAndDragonsThemeName = "5E Theme - Wizards";
local coreSideBarThemeName = "Core Sidebar for 5e";
local coloredSideBarThemeName = "Colored Sidebar";

function onInit()
	if RFIA.bDebug then debugExtensions(); end
	bCharacterSheetTweaksEnabled = isThemeEnabled("Mad Nomad's Character Sheet Tweaks");
end


function debugExtensions()
	local extensions = Extension.getExtensions();
    for _, extension in ipairs(extensions) do
    	Debug.console("checkAndHandleExtensionCompatibility extension", Extension.getExtensionInfo(extension).name);
    end
end

function is5EThemeEnabled()
	return isThemeEnabled(dungeonsAndDragonsThemeName);
end

function isCoreSideBarThemeEnabled()
	return isThemeEnabled(coreSideBarThemeName);
end

function isColoredSideBarThemeEnabled()
	return isThemeEnabled(coloredSideBarThemeName);
end

function isThemeEnabled(themeName)
	extensions = Extension.getExtensions();
    for _, extension in ipairs(extensions) do
    	if Extension.getExtensionInfo(extension).name == themeName then
			return true;
		end
    end
	return false;
end