#!/usr/bin/env python3
"""Write Lookmira.xcodeproj for the iOS app plus the local LookmiraCore package."""

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "App"
PROJECT = ROOT / "Lookmira.xcodeproj"


def pid(text: str) -> str:
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:24].upper()


def main() -> None:
    swift_files = sorted(p.relative_to(APP) for p in APP.rglob("*.swift"))
    resources = [Path("Assets.xcassets"), Path("PrivacyInfo.xcprivacy")]
    resources += sorted(
        p.relative_to(APP)
        for p in APP.rglob("*")
        if p.suffix.lower() in {".jpg", ".jpeg", ".png"} and "xcassets" not in p.parts
    )

    def file_ref(rel: Path) -> str:
        return pid(f"fileref:{rel.as_posix()}")

    def build_file(rel: Path, kind: str) -> str:
        return pid(f"build:{kind}:{rel.as_posix()}")

    target = pid("target:Lookmira")
    project = pid("project:Lookmira")
    app_group = pid("group:App")
    main_group = pid("group:main")
    products_group = pid("group:products")
    sources_phase = pid("phase:sources")
    resources_phase = pid("phase:resources")
    frameworks_phase = pid("phase:frameworks")
    product_ref = pid("product:Lookmira.app")
    package_ref = pid("package:local")
    package_product = pid("package:LookmiraCore")
    package_build = pid("build:LookmiraCore")
    debug_project = pid("config:project:debug")
    release_project = pid("config:project:release")
    debug_target = pid("config:target:debug")
    release_target = pid("config:target:release")
    project_config_list = pid("list:project")
    target_config_list = pid("list:target")
    info_ref = file_ref(Path("Info.plist"))

    build_files = []
    file_refs = []
    app_children = []
    source_phase_files = []
    resource_phase_files = []

    file_refs.append(
        f"\t\t{info_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};"
    )
    app_children.append(f"\t\t\t\t{info_ref} /* Info.plist */,")

    for rel in swift_files:
        ref = file_ref(rel)
        bf = build_file(rel, "src")
        file_refs.append(
            f"\t\t{ref} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {rel.as_posix()}; sourceTree = \"<group>\"; }};"
        )
        build_files.append(
            f"\t\t{bf} /* {rel.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {rel.name} */; }};"
        )
        app_children.append(f"\t\t\t\t{ref} /* {rel.name} */,")
        source_phase_files.append(f"\t\t\t\t{bf} /* {rel.name} in Sources */,")

    for rel in resources:
        ref = file_ref(rel)
        bf = build_file(rel, "res")
        if rel.suffix == ".xcassets" or rel.name.endswith(".xcassets"):
            ftype = "folder.assetcatalog"
        elif rel.suffix == ".xcprivacy":
            ftype = "text.xml"
        else:
            ftype = "image.jpg" if rel.suffix.lower() in {".jpg", ".jpeg"} else "image.png"
        quoted = rel.as_posix()
        file_refs.append(
            f"\t\t{ref} /* {rel.name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = \"{quoted}\"; sourceTree = \"<group>\"; }};"
        )
        build_files.append(
            f"\t\t{bf} /* {rel.name} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref} /* {rel.name} */; }};"
        )
        app_children.append(f"\t\t\t\t{ref} /* {rel.name} */,")
        resource_phase_files.append(f"\t\t\t\t{bf} /* {rel.name} in Resources */,")

    build_files.append(
        f"\t\t{package_build} /* LookmiraCore in Frameworks */ = {{isa = PBXBuildFile; productRef = {package_product} /* LookmiraCore */; }};"
    )

    file_refs.append(
        f"\t\t{product_ref} /* Lookmira.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Lookmira.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )

    common_target = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = App/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = Lookmira;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.jackyliu.lookmira;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
"""

    project_settings = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_NS_ASSERTIONS = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
"""
    release_project_settings = project_settings.replace("DEBUG_INFORMATION_FORMAT = dwarf;", "DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    release_project_settings = release_project_settings.replace("ENABLE_NS_ASSERTIONS = YES;", "ENABLE_NS_ASSERTIONS = NO;")
    release_project_settings = release_project_settings.replace("MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;", "MTL_ENABLE_DEBUG_INFO = NO;")
    release_project_settings = release_project_settings.replace("ONLY_ACTIVE_ARCH = YES;", "ONLY_ACTIVE_ARCH = NO;")
    release_project_settings = release_project_settings.replace("SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;", "SWIFT_COMPILATION_MODE = wholemodule;")
    release_project_settings = release_project_settings.replace('SWIFT_OPTIMIZATION_LEVEL = "-Onone";', 'SWIFT_OPTIMIZATION_LEVEL = "-O";')

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{chr(10).join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{package_build} /* LookmiraCore in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{app_group} /* App */ = {{
			isa = PBXGroup;
			children = (
{chr(10).join(app_children)}
			);
			path = App;
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* Lookmira.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{main_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* App */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target} /* Lookmira */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list} /* Build configuration list for PBXNativeTarget "Lookmira" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Lookmira;
			packageProductDependencies = (
				{package_product} /* LookmiraCore */,
			);
			productName = Lookmira;
			productReference = {product_ref} /* Lookmira.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				TargetAttributes = {{
					{target} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {project_config_list} /* Build configuration list for PBXProject "Lookmira" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group};
			packageReferences = (
				{package_ref} /* XCLocalSwiftPackageReference "." */,
			);
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target} /* Lookmira */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(resource_phase_files)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{chr(10).join(source_phase_files)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_project} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{project_settings}
			}};
			name = Debug;
		}};
		{release_project} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{release_project_settings}
			}};
			name = Release;
		}};
		{debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target}
			}};
			name = Debug;
		}};
		{release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_target}
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{project_config_list} /* Build configuration list for PBXProject "Lookmira" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_project} /* Debug */,
				{release_project} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{target_config_list} /* Build configuration list for PBXNativeTarget "Lookmira" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_target} /* Debug */,
				{release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		{package_ref} /* XCLocalSwiftPackageReference "." */ = {{
			isa = XCLocalSwiftPackageReference;
			relativePath = ".";
		}};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		{package_product} /* LookmiraCore */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {package_ref} /* XCLocalSwiftPackageReference "." */;
			productName = LookmiraCore;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = {project} /* Project object */;
}}
"""
    proj_dir = PROJECT
    proj_dir.mkdir(parents=True, exist_ok=True)
    (proj_dir / "project.pbxproj").write_text(pbx)
    workspace = proj_dir / "project.xcworkspace"
    workspace.mkdir(exist_ok=True)
    (workspace / "contents.xcworkspacedata").write_text(
        """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""
    )
    scheme_dir = proj_dir / "xcshareddata" / "xcschemes"
    scheme_dir.mkdir(parents=True, exist_ok=True)
    (scheme_dir / "Lookmira.xcscheme").write_text(
        f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target}"
               BuildableName = "Lookmira.app"
               BlueprintName = "Lookmira"
               ReferencedContainer = "container:Lookmira.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target}"
            BuildableName = "Lookmira.app"
            BlueprintName = "Lookmira"
            ReferencedContainer = "container:Lookmira.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target}"
            BuildableName = "Lookmira.app"
            BlueprintName = "Lookmira"
            ReferencedContainer = "container:Lookmira.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    )
    print(f"Wrote {proj_dir / 'project.pbxproj'} with {len(swift_files)} sources and {len(resources)} resources")


if __name__ == "__main__":
    main()
