#!/usr/bin/env python3
"""Write Vermessa.xcodeproj so the SwiftUI app links the local VermessaCore package."""

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "Vermessa.xcodeproj"
APP_DIR = ROOT / "App"

SWIFT_FILES = sorted(p.name for p in APP_DIR.glob("*.swift"))


def xid(label: str) -> str:
    return hashlib.sha1(f"vermessa:{label}".encode()).hexdigest()[:24].upper()


def main() -> None:
    file_refs = {}
    build_files = {}
    for name in SWIFT_FILES:
        file_refs[name] = xid(f"fileref:{name}")
        build_files[name] = xid(f"build:{name}")

    assets_ref = xid("fileref:Assets.xcassets")
    assets_build = xid("build:Assets.xcassets")
    privacy_ref = xid("fileref:PrivacyInfo.xcprivacy")
    privacy_build = xid("build:PrivacyInfo.xcprivacy")
    plist_ref = xid("fileref:Info.plist")
    product_ref = xid("fileref:Vermessa.app")
    app_group = xid("group:App")
    root_group = xid("group:root")
    products_group = xid("group:products")
    sources_phase = xid("phase:sources")
    resources_phase = xid("phase:resources")
    frameworks_phase = xid("phase:frameworks")
    target_id = xid("target:Vermessa")
    project_id = xid("project:Vermessa")
    package_ref = xid("package:local")
    product_dep = xid("product:VermessaCore")
    core_build = xid("build:VermessaCore")
    debug_proj = xid("cfg:proj:debug")
    release_proj = xid("cfg:proj:release")
    debug_tgt = xid("cfg:tgt:debug")
    release_tgt = xid("cfg:tgt:release")
    proj_list = xid("list:project")
    tgt_list = xid("list:target")

    def file_ref_line(name: str, ref: str, kind: str) -> str:
        return (
            f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; "
            f"lastKnownFileType = {kind}; path = {name}; sourceTree = \"<group>\"; }};"
        )

    swift_build_lines = "\n".join(
        f"\t\t{build_files[name]} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[name]} /* {name} */; }};"
        for name in SWIFT_FILES
    )
    swift_ref_lines = "\n".join(
        file_ref_line(name, file_refs[name], "sourcecode.swift") for name in SWIFT_FILES
    )
    swift_children = "\n".join(
        f"\t\t\t\t{file_refs[name]} /* {name} */," for name in SWIFT_FILES
    )
    swift_sources = "\n".join(
        f"\t\t\t\t{build_files[name]} /* {name} in Sources */," for name in SWIFT_FILES
    )

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{swift_build_lines}
		{assets_build} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_ref} /* Assets.xcassets */; }};
		{privacy_build} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {privacy_ref} /* PrivacyInfo.xcprivacy */; }};
		{core_build} /* VermessaCore in Frameworks */ = {{isa = PBXBuildFile; productRef = {product_dep} /* VermessaCore */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{swift_ref_lines}
		{assets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
		{privacy_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; }};
		{plist_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
		{product_ref} /* Vermessa.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Vermessa.app; sourceTree = BUILT_PRODUCTS_DIR; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{core_build} /* VermessaCore in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{app_group} /* App */ = {{
			isa = PBXGroup;
			children = (
{swift_children}
				{assets_ref} /* Assets.xcassets */,
				{privacy_ref} /* PrivacyInfo.xcprivacy */,
				{plist_ref} /* Info.plist */,
			);
			path = App;
			sourceTree = "<group>";
		}};
		{products_group} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{product_ref} /* Vermessa.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{root_group} = {{
			isa = PBXGroup;
			children = (
				{app_group} /* App */,
				{products_group} /* Products */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_id} /* Vermessa */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {tgt_list} /* Build configuration list for PBXNativeTarget "Vermessa" */;
			buildPhases = (
				{sources_phase} /* Sources */,
				{frameworks_phase} /* Frameworks */,
				{resources_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Vermessa;
			packageProductDependencies = (
				{product_dep} /* VermessaCore */,
			);
			productName = Vermessa;
			productReference = {product_ref} /* Vermessa.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = YES;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
				ORGANIZATIONNAME = "Jacky Liu";
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 16.0;
					}};
				}};
			}};
			buildConfigurationList = {proj_list} /* Build configuration list for PBXProject "Vermessa" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {root_group};
			packageReferences = (
				{package_ref} /* XCLocalSwiftPackageReference "." */,
			);
			productRefGroup = {products_group} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_id} /* Vermessa */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{assets_build} /* Assets.xcassets in Resources */,
				{privacy_build} /* PrivacyInfo.xcprivacy in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{swift_sources}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_proj} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{release_proj} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{debug_tgt} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.jackyliu.vermessa;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = minimal;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{release_tgt} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = App/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.jackyliu.vermessa;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_STRICT_CONCURRENCY = minimal;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{proj_list} /* Build configuration list for PBXProject "Vermessa" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_proj} /* Debug */,
				{release_proj} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{tgt_list} /* Build configuration list for PBXNativeTarget "Vermessa" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_tgt} /* Debug */,
				{release_tgt} /* Release */,
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
		{product_dep} /* VermessaCore */ = {{
			isa = XCSwiftPackageProductDependency;
			package = {package_ref} /* XCLocalSwiftPackageReference "." */;
			productName = VermessaCore;
		}};
/* End XCSwiftPackageProductDependency section */
	}};
	rootObject = {project_id} /* Project object */;
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
    schemes = proj_dir / "xcshareddata" / "xcschemes"
    schemes.mkdir(parents=True, exist_ok=True)
    (schemes / "Vermessa.xcscheme").write_text(
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
               BlueprintIdentifier = "{target_id}"
               BuildableName = "Vermessa.app"
               BlueprintName = "Vermessa"
               ReferencedContainer = "container:Vermessa.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
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
            BlueprintIdentifier = "{target_id}"
            BuildableName = "Vermessa.app"
            BlueprintName = "Vermessa"
            ReferencedContainer = "container:Vermessa.xcodeproj">
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
            BlueprintIdentifier = "{target_id}"
            BuildableName = "Vermessa.app"
            BlueprintName = "Vermessa"
            ReferencedContainer = "container:Vermessa.xcodeproj">
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
    print(f"Wrote {proj_dir} with {len(SWIFT_FILES)} Swift files")


if __name__ == "__main__":
    main()
