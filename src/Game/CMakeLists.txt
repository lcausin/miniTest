#
# Files Game
set(SOURCE_Game Game.cpp Game.h)

set(SOURCES ${SOURCE_Game})

#
# Create executable/library
if (CMAKE_SYSTEM_NAME MATCHES "Android")

	add_library(Game SHARED ${SOURCES})

	set_target_properties(Game PROPERTIES OUTPUT_NAME "ShineApp")
	set_target_properties(Game PROPERTIES ANDROID_API 28)

	#
	# For NativeActivity, bug fix for method ANativeActivity_OnCreate not found (https://github.com/android-ndk/ndk/issues/381), fixed in ndk r15
	set_property(TARGET Game APPEND_STRING PROPERTY LINK_FLAGS " -u ANativeActivity_onCreate")

else (CMAKE_SYSTEM_NAME MATCHES "Android")

	add_executable(Game WIN32 ${SOURCES})

endif (CMAKE_SYSTEM_NAME MATCHES "Android")

set_property(TARGET Game PROPERTY FOLDER "Runtime")
set_property(TARGET Game APPEND PROPERTY COMPILE_DEFINITIONS "${SHSDK_COMPILE_DEFINITIONS}")
set_property(TARGET Game APPEND PROPERTY COMPILE_FLAGS "${SHSDK_COMPILE_FLAGS}")
set_property(TARGET Game APPEND PROPERTY COMPILE_DEFINITIONS "SH_$<UPPER_CASE:$<CONFIG>>=1")

target_link_libraries(Game PRIVATE "${SHSDK_LIBRARIES}" Plugin) # link with plugins
target_include_directories(Game PRIVATE $<TARGET_PROPERTY:Plugin,INTERFACE_INCLUDE_DIRECTORIES> "${SHSDK_INCLUDE_DIRS}")

CopyToShineSAAS(Game)
