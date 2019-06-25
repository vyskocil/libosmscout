if(NOT APPLE)
	message(SEND_ERROR "Mac OS X or iOS required for iOSX map drawing backend")
endif()

if(NOT ${OSMSCOUT_BUILD_MAP})
	message(SEND_ERROR "The main map drawing interface is required for cairo map drawing backend")
endif()

set(HEADER_FILES
        include/osmscout/MapPainterIOS.h
)

set(SOURCE_FILES
    src/osmscout/MapPainterIOS.mm
)

if(IOS)
  add_library(osmscout-map-iosx STATIC ${SOURCE_FILES} ${HEADER_FILES})
else()
  add_library(osmscout-map-iosx ${SOURCE_FILES} ${HEADER_FILES})
endif()

set_target_properties(osmscout-map-iosx PROPERTIES
		CXX_STANDARD 14
		OUTPUT_NAME "osmscout-map-iosx")

target_include_directories(osmscout-map-iosx PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Private config header
create_private_config("${CMAKE_CURRENT_BINARY_DIR}/privateinclude/osmscout/private/Config.h" "osmscout-map-iosx")
target_include_directories(osmscout-map-iosx PRIVATE include ${CMAKE_CURRENT_BINARY_DIR}/privateinclude)

set_target_properties(osmscout-map-iosx PROPERTIES
  FRAMEWORK TRUE
  FRAMEWORK_VERSION C
  MACOSX_FRAMEWORK_IDENTIFIER com.cmake.dynamicFramework
  #MACOSX_FRAMEWORK_INFO_PLIST Info.plist
  PUBLIC_HEADER     include/osmscout/MapPainterIOS.h
  CODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
  OUTPUT_NAME "osmscout-map-iosx")

find_library(FOUNDATION Foundation)
find_library(COREGRAPHICS CoreGraphics)
find_library(CORETEXT CoreText)

if(${IOS})
find_library(UIKIT UIKit)

target_link_libraries(osmscout-map-iosx
		osmscout
		osmscout-map
		${FOUNDATION}
		${UIKIT}
		${CORETEXT}
		${COREGRAPHICS})
else()
find_library(COCOA Cocoa)
find_library(APPKIT AppKit)

target_link_libraries(osmscout-map-iosx
		osmscout
		osmscout-map
		${FOUNDATION}
		${COCOA}
		${APPKIT}
		${CORETEXT}
		${COREGRAPHICS})
endif()

if(IOS)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fobjc-arc -fembed-bitcode")
else()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fobjc-arc")
endif()

target_compile_definitions(osmscout-map-iosx PRIVATE -DOSMSCOUTMAPIOSX_EXPORT_SYMBOLS)

install(TARGETS osmscout-map-iosx
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        FRAMEWORK DESTINATION lib)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/osmscout DESTINATION include FILES_MATCHING PATTERN "*.h" PATTERN "private/Config.h" EXCLUDE)
#install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/osmscout/MapCairoFeatures.h DESTINATION include/osmscout)
