#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "digest/md5"

ROOT = File.expand_path("..", __dir__)
PROJECT_DIR = File.join(ROOT, "IndustrialRouter.xcodeproj")
SHARED_SCHEME_DIR = File.join(PROJECT_DIR, "xcshareddata", "xcschemes")

def uuid(seed)
  Digest::MD5.hexdigest(seed).upcase[0, 24]
end

def quote(value)
  return value if value =~ /\A[A-Z0-9]{24}\z/

  escaped = value.to_s.gsub("\\", "\\\\\\").gsub('"', '\"')
  "\"#{escaped}\""
end

def list(values, indent = 4)
  return "()" if values.empty?

  inner = values.map { |value| "#{"\t" * indent}#{value}," }.join("\n")
  "(\n#{inner}\n#{"\t" * (indent - 1)})"
end

source_files = Dir[File.join(ROOT, "Sources", "IndustrialRouter", "*.swift")]
  .sort
  .map { |path| path.delete_prefix("#{ROOT}/") }

resource_files = Dir[File.join(ROOT, "Sources", "IndustrialRouter", "Resources", "**", "*")]
  .select { |path| File.file?(path) }
  .sort
  .map { |path| path.delete_prefix("#{ROOT}/") }

demo_files = Dir[File.join(ROOT, "Demo", "IndustrialRouterDemo", "*.swift")]
  .sort
  .map { |path| path.delete_prefix("#{ROOT}/") }

demo_development_team = ENV.fetch("DEVELOPMENT_TEAM", "6E9ARQD7Y3").strip

ids = {
  project: uuid("project"),
  main_group: uuid("main_group"),
  sources_group: uuid("sources_group"),
  demo_group: uuid("demo_group"),
  products_group: uuid("products_group"),
  framework_resources_group: uuid("framework_resources_group"),
  framework_target: uuid("framework_target"),
  demo_target: uuid("demo_target"),
  framework_sources_phase: uuid("framework_sources_phase"),
  framework_frameworks_phase: uuid("framework_frameworks_phase"),
  framework_resources_phase: uuid("framework_resources_phase"),
  demo_sources_phase: uuid("demo_sources_phase"),
  demo_frameworks_phase: uuid("demo_frameworks_phase"),
  demo_embed_phase: uuid("demo_embed_phase"),
  framework_product: uuid("framework_product"),
  demo_product: uuid("demo_product"),
  framework_dependency: uuid("framework_dependency"),
  framework_proxy: uuid("framework_proxy"),
  project_config_list: uuid("project_config_list"),
  framework_config_list: uuid("framework_config_list"),
  demo_config_list: uuid("demo_config_list"),
  project_debug: uuid("project_debug"),
  project_release: uuid("project_release"),
  framework_debug: uuid("framework_debug"),
  framework_release: uuid("framework_release"),
  demo_debug: uuid("demo_debug"),
  demo_release: uuid("demo_release")
}

objects = []

framework_file_refs = source_files.to_h { |path| [path, uuid("file_ref:#{path}")] }
framework_build_files = source_files.to_h { |path| [path, uuid("build_file:#{path}")] }
framework_resource_refs = resource_files.to_h { |path| [path, uuid("resource_ref:#{path}")] }
framework_resource_build_files = resource_files.to_h { |path| [path, uuid("resource_build_file:#{path}")] }
demo_file_refs = demo_files.to_h { |path| [path, uuid("file_ref:#{path}")] }
demo_build_files = demo_files.to_h { |path| [path, uuid("build_file:#{path}")] }
framework_link_build_file = uuid("framework_link_build_file")
framework_embed_build_file = uuid("framework_embed_build_file")

source_files.each do |path|
  objects << "#{framework_file_refs[path]} = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{quote(File.basename(path))}; sourceTree = \"<group>\"; };"
  objects << "#{framework_build_files[path]} = {isa = PBXBuildFile; fileRef = #{framework_file_refs[path]}; };"
end

resource_files.each do |path|
  objects << "#{framework_resource_refs[path]} = {isa = PBXFileReference; lastKnownFileType = text.xml; path = #{quote(File.basename(path))}; sourceTree = \"<group>\"; };"
  objects << "#{framework_resource_build_files[path]} = {isa = PBXBuildFile; fileRef = #{framework_resource_refs[path]}; };"
end

demo_files.each do |path|
  objects << "#{demo_file_refs[path]} = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{quote(File.basename(path))}; sourceTree = \"<group>\"; };"
  objects << "#{demo_build_files[path]} = {isa = PBXBuildFile; fileRef = #{demo_file_refs[path]}; };"
end

objects << "#{ids[:framework_product]} = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = IndustrialRouter.framework; sourceTree = BUILT_PRODUCTS_DIR; };"
objects << "#{ids[:demo_product]} = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = IndustrialRouterDemo.app; sourceTree = BUILT_PRODUCTS_DIR; };"
objects << "#{framework_link_build_file} = {isa = PBXBuildFile; fileRef = #{ids[:framework_product]}; };"
objects << "#{framework_embed_build_file} = {isa = PBXBuildFile; fileRef = #{ids[:framework_product]}; settings = {ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }; };"

source_group_children = framework_file_refs.values
if resource_files.any?
  objects << "#{ids[:framework_resources_group]} = {isa = PBXGroup; children = #{list(framework_resource_refs.values, 3)}; path = Resources; sourceTree = \"<group>\"; };"
  source_group_children += [ids[:framework_resources_group]]
end

objects << "#{ids[:sources_group]} = {isa = PBXGroup; children = #{list(source_group_children, 3)}; path = Sources/IndustrialRouter; sourceTree = \"<group>\"; };"
objects << "#{ids[:demo_group]} = {isa = PBXGroup; children = #{list(demo_file_refs.values + [uuid("demo_info_plist_ref")], 3)}; path = Demo/IndustrialRouterDemo; sourceTree = \"<group>\"; };"
objects << "#{uuid("demo_info_plist_ref")} = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };"
objects << "#{ids[:products_group]} = {isa = PBXGroup; children = #{list([ids[:framework_product], ids[:demo_product]], 3)}; name = Products; sourceTree = \"<group>\"; };"
objects << "#{ids[:main_group]} = {isa = PBXGroup; children = #{list([ids[:sources_group], ids[:demo_group], ids[:products_group]], 3)}; sourceTree = \"<group>\"; };"

objects << "#{ids[:framework_sources_phase]} = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = #{list(framework_build_files.values, 3)}; runOnlyForDeploymentPostprocessing = 0; };"
objects << "#{ids[:framework_frameworks_phase]} = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };"
objects << "#{ids[:framework_resources_phase]} = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = #{list(framework_resource_build_files.values, 3)}; runOnlyForDeploymentPostprocessing = 0; };"
objects << "#{ids[:demo_sources_phase]} = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = #{list(demo_build_files.values, 3)}; runOnlyForDeploymentPostprocessing = 0; };"
objects << "#{ids[:demo_frameworks_phase]} = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (#{framework_link_build_file}, ); runOnlyForDeploymentPostprocessing = 0; };"
objects << "#{ids[:demo_embed_phase]} = {isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = \"\"; dstSubfolderSpec = 10; files = (#{framework_embed_build_file}, ); name = \"Embed Frameworks\"; runOnlyForDeploymentPostprocessing = 0; };"

objects << "#{ids[:framework_proxy]} = {isa = PBXContainerItemProxy; containerPortal = #{ids[:project]}; proxyType = 1; remoteGlobalIDString = #{ids[:framework_target]}; remoteInfo = IndustrialRouter; };"
objects << "#{ids[:framework_dependency]} = {isa = PBXTargetDependency; target = #{ids[:framework_target]}; targetProxy = #{ids[:framework_proxy]}; };"

objects << "#{ids[:framework_target]} = {isa = PBXNativeTarget; buildConfigurationList = #{ids[:framework_config_list]}; buildPhases = (#{ids[:framework_sources_phase]}, #{ids[:framework_frameworks_phase]}, #{ids[:framework_resources_phase]}, ); buildRules = (); dependencies = (); name = IndustrialRouter; productName = IndustrialRouter; productReference = #{ids[:framework_product]}; productType = \"com.apple.product-type.framework\"; };"
objects << "#{ids[:demo_target]} = {isa = PBXNativeTarget; buildConfigurationList = #{ids[:demo_config_list]}; buildPhases = (#{ids[:demo_sources_phase]}, #{ids[:demo_frameworks_phase]}, #{ids[:demo_embed_phase]}, ); buildRules = (); dependencies = (#{ids[:framework_dependency]}, ); name = IndustrialRouterDemo; productName = IndustrialRouterDemo; productReference = #{ids[:demo_product]}; productType = \"com.apple.product-type.application\"; };"

project_settings = {
  "ALWAYS_SEARCH_USER_PATHS" => "NO",
  "CLANG_ANALYZER_NONNULL" => "YES",
  "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION" => "YES_AGGRESSIVE",
  "CLANG_CXX_LANGUAGE_STANDARD" => "gnu++20",
  "CLANG_ENABLE_MODULES" => "YES",
  "CLANG_ENABLE_OBJC_ARC" => "YES",
  "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING" => "YES",
  "CLANG_WARN_BOOL_CONVERSION" => "YES",
  "CLANG_WARN_COMMA" => "YES",
  "CLANG_WARN_CONSTANT_CONVERSION" => "YES",
  "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS" => "YES",
  "CLANG_WARN_DIRECT_OBJC_ISA_USAGE" => "YES_ERROR",
  "CLANG_WARN_DOCUMENTATION_COMMENTS" => "YES",
  "CLANG_WARN_EMPTY_BODY" => "YES",
  "CLANG_WARN_ENUM_CONVERSION" => "YES",
  "CLANG_WARN_INFINITE_RECURSION" => "YES",
  "CLANG_WARN_INT_CONVERSION" => "YES",
  "CLANG_WARN_NON_LITERAL_NULL_CONVERSION" => "YES",
  "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF" => "YES",
  "CLANG_WARN_OBJC_LITERAL_CONVERSION" => "YES",
  "CLANG_WARN_OBJC_ROOT_CLASS" => "YES_ERROR",
  "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER" => "YES",
  "CLANG_WARN_RANGE_LOOP_ANALYSIS" => "YES",
  "CLANG_WARN_STRICT_PROTOTYPES" => "YES",
  "CLANG_WARN_SUSPICIOUS_MOVE" => "YES",
  "CLANG_WARN_UNGUARDED_AVAILABILITY" => "YES_AGGRESSIVE",
  "CLANG_WARN_UNREACHABLE_CODE" => "YES",
  "CLANG_WARN__DUPLICATE_METHOD_MATCH" => "YES",
  "COPY_PHASE_STRIP" => "NO",
  "ENABLE_STRICT_OBJC_MSGSEND" => "YES",
  "GCC_C_LANGUAGE_STANDARD" => "gnu17",
  "GCC_NO_COMMON_BLOCKS" => "YES",
  "GCC_WARN_64_TO_32_BIT_CONVERSION" => "YES",
  "GCC_WARN_ABOUT_RETURN_TYPE" => "YES_ERROR",
  "GCC_WARN_UNDECLARED_SELECTOR" => "YES",
  "GCC_WARN_UNINITIALIZED_AUTOS" => "YES_AGGRESSIVE",
  "GCC_WARN_UNUSED_FUNCTION" => "YES",
  "GCC_WARN_UNUSED_VARIABLE" => "YES",
  "IPHONEOS_DEPLOYMENT_TARGET" => "13.0",
  "SDKROOT" => "iphoneos",
  "SWIFT_VERSION" => "5.7"
}

def build_settings(settings)
  settings.map { |key, value| "\t\t\t\t#{key} = #{quote(value.to_s)};" }.join("\n")
end

[
  [:project_debug, "Debug", project_settings.merge("DEBUG_INFORMATION_FORMAT" => "dwarf", "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "DEBUG")],
  [:project_release, "Release", project_settings.merge("DEBUG_INFORMATION_FORMAT" => "dwarf-with-dsym", "SWIFT_COMPILATION_MODE" => "wholemodule", "VALIDATE_PRODUCT" => "YES")],
  [:framework_debug, "Debug", {
    "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
    "DEFINES_MODULE" => "YES",
    "GENERATE_INFOPLIST_FILE" => "YES",
    "IPHONEOS_DEPLOYMENT_TARGET" => "13.0",
    "LD_DYLIB_INSTALL_NAME" => "@rpath/$(EXECUTABLE_PATH)",
    "PRODUCT_BUNDLE_IDENTIFIER" => "com.industrialrouter.framework",
    "PRODUCT_MODULE_NAME" => "IndustrialRouter",
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "SKIP_INSTALL" => "NO",
    "SWIFT_VERSION" => "5.7"
  }],
  [:framework_release, "Release", {
    "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES",
    "DEFINES_MODULE" => "YES",
    "GENERATE_INFOPLIST_FILE" => "YES",
    "IPHONEOS_DEPLOYMENT_TARGET" => "13.0",
    "LD_DYLIB_INSTALL_NAME" => "@rpath/$(EXECUTABLE_PATH)",
    "PRODUCT_BUNDLE_IDENTIFIER" => "com.industrialrouter.framework",
    "PRODUCT_MODULE_NAME" => "IndustrialRouter",
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "SKIP_INSTALL" => "NO",
    "SWIFT_VERSION" => "5.7"
  }],
  [:demo_debug, "Debug", {
    "CODE_SIGN_STYLE" => "Automatic",
    "DEVELOPMENT_TEAM" => demo_development_team,
    "INFOPLIST_FILE" => "Demo/IndustrialRouterDemo/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET" => "13.0",
    "LD_RUNPATH_SEARCH_PATHS" => "$(inherited) @executable_path/Frameworks",
    "PRODUCT_BUNDLE_IDENTIFIER" => "com.industrialrouter.demo",
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "SWIFT_VERSION" => "5.7",
    "TARGETED_DEVICE_FAMILY" => "1,2"
  }],
  [:demo_release, "Release", {
    "CODE_SIGN_STYLE" => "Automatic",
    "DEVELOPMENT_TEAM" => demo_development_team,
    "INFOPLIST_FILE" => "Demo/IndustrialRouterDemo/Info.plist",
    "IPHONEOS_DEPLOYMENT_TARGET" => "13.0",
    "LD_RUNPATH_SEARCH_PATHS" => "$(inherited) @executable_path/Frameworks",
    "PRODUCT_BUNDLE_IDENTIFIER" => "com.industrialrouter.demo",
    "PRODUCT_NAME" => "$(TARGET_NAME)",
    "SWIFT_VERSION" => "5.7",
    "TARGETED_DEVICE_FAMILY" => "1,2"
  }]
].each do |key, name, settings|
  objects << "#{ids[key]} = {isa = XCBuildConfiguration; buildSettings = {\n#{build_settings(settings)}\n\t\t\t}; name = #{name}; };"
end

objects << "#{ids[:project_config_list]} = {isa = XCConfigurationList; buildConfigurations = (#{ids[:project_debug]}, #{ids[:project_release]}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };"
objects << "#{ids[:framework_config_list]} = {isa = XCConfigurationList; buildConfigurations = (#{ids[:framework_debug]}, #{ids[:framework_release]}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };"
objects << "#{ids[:demo_config_list]} = {isa = XCConfigurationList; buildConfigurations = (#{ids[:demo_debug]}, #{ids[:demo_release]}, ); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };"

objects << "#{ids[:project]} = {isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = YES; LastSwiftUpdateCheck = 1540; LastUpgradeCheck = 1540; TargetAttributes = {#{ids[:framework_target]} = {CreatedOnToolsVersion = 15.4;}; #{ids[:demo_target]} = {CreatedOnToolsVersion = 15.4;}; };}; buildConfigurationList = #{ids[:project_config_list]}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, ); mainGroup = #{ids[:main_group]}; productRefGroup = #{ids[:products_group]}; projectDirPath = \"\"; projectRoot = \"\"; targets = (#{ids[:framework_target]}, #{ids[:demo_target]}, ); };"

pbxproj = <<~PBXPROJ
  // !$*UTF8*$!
  {
  	archiveVersion = 1;
  	classes = {
  	};
  	objectVersion = 56;
  	objects = {
  #{objects.map { |line| "\t\t#{line}" }.join("\n")}
  	};
  	rootObject = #{ids[:project]};
  }
PBXPROJ

FileUtils.rm_rf(PROJECT_DIR)
FileUtils.mkdir_p(PROJECT_DIR)
File.write(File.join(PROJECT_DIR, "project.pbxproj"), pbxproj)

FileUtils.mkdir_p(SHARED_SCHEME_DIR)

def scheme_xml(target_id, target_name, project_name, product, runnable: true)
  launch_runnable = if runnable
    <<~XML
          <BuildableProductRunnable runnableDebuggingMode="0">
             <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="#{target_id}" BuildableName="#{product}" BlueprintName="#{target_name}" ReferencedContainer="container:#{project_name}.xcodeproj">
             </BuildableReference>
          </BuildableProductRunnable>
    XML
  else
    ""
  end

  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <Scheme LastUpgradeVersion="1540" version="1.7">
       <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
          <BuildActionEntries>
             <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
                <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="#{target_id}" BuildableName="#{product}" BlueprintName="#{target_name}" ReferencedContainer="container:#{project_name}.xcodeproj">
                </BuildableReference>
             </BuildActionEntry>
          </BuildActionEntries>
       </BuildAction>
       <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
       </TestAction>
       <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="#{runnable ? "Xcode.DebuggerFoundation.Debugger.LLDB" : ""}" selectedLauncherIdentifier="#{runnable ? "Xcode.DebuggerFoundation.Launcher.LLDB" : "Xcode.IDEFoundation.Launcher.PosixSpawn"}" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    #{launch_runnable.rstrip}
       </LaunchAction>
       <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    #{launch_runnable.rstrip}
       </ProfileAction>
       <AnalyzeAction buildConfiguration="Debug">
       </AnalyzeAction>
       <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES">
       </ArchiveAction>
    </Scheme>
  XML
end

File.write(
  File.join(SHARED_SCHEME_DIR, "IndustrialRouter.xcscheme"),
  scheme_xml(ids[:framework_target], "IndustrialRouter", "IndustrialRouter", "IndustrialRouter.framework", runnable: false)
)

File.write(
  File.join(SHARED_SCHEME_DIR, "IndustrialRouterDemo.xcscheme"),
  scheme_xml(ids[:demo_target], "IndustrialRouterDemo", "IndustrialRouter", "IndustrialRouterDemo.app")
)
