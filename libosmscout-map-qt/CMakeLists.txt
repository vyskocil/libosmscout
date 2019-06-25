if(NOT Qt5Gui_FOUND)
	message(SEND_ERROR "Qt5 is required for Qt map drawing backend")
endif()
if(NOT ${OSMSCOUT_BUILD_MAP})
	message(SEND_ERROR "The main map drawing interface is required for Qt map drawing backend")
endif()

set(HEADER_FILES
	include/osmscout/MapQtImportExport.h
    include/osmscout/MapPainterQt.h
)

set(SOURCE_FILES
    src/osmscout/MapPainterQt.cpp
)

if(IOS)
  add_library(osmscout-map-qt STATIC ${SOURCE_FILES} ${HEADER_FILES})
else()
  add_library(osmscout-map-qt ${SOURCE_FILES} ${HEADER_FILES})
endif()

set_target_properties(osmscout-map-qt PROPERTIES
		CXX_STANDARD 14
		OUTPUT_NAME "osmscout_map_qt")

target_include_directories(osmscout-map-qt PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Public features Header
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/include/osmscout/MapQtFeatures.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/include/osmscout/MapQtFeatures.h)
target_include_directories(osmscout-map-qt PUBLIC include ${CMAKE_CURRENT_BINARY_DIR}/include)

# Private config header
create_private_config("${CMAKE_CURRENT_BINARY_DIR}/privateinclude/osmscout/private/Config.h" "osmscout-map-qt")
target_include_directories(osmscout-map-qt PRIVATE include ${CMAKE_CURRENT_BINARY_DIR}/privateinclude)

if(${IOS})
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fembed-bitcode")
endif()

if(APPLE AND BUILD_FRAMEWORKS)
set_target_properties(osmscout-map-qt PROPERTIES
  		FRAMEWORK TRUE
  		FRAMEWORK_VERSION C
  		MACOSX_FRAMEWORK_IDENTIFIER com.cmake.dynamicFramework
  		#MACOSX_FRAMEWORK_INFO_PLIST Info.plist
  		PUBLIC_HEADER     "${HEADER_FILES}"
  		CODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
		OUTPUT_NAME "osmscout-map-qt")
endif()

target_link_libraries(osmscout-map-qt
		osmscout
		osmscout-map
		Qt5::Gui
		Qt5::Svg)

target_compile_definitions(osmscout-map-qt PRIVATE -DOSMSCOUT_MAP_QT_EXPORT_SYMBOLS)

install(TARGETS osmscout-map-qt
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        FRAMEWORK DESTINATION lib)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/osmscout DESTINATION include FILES_MATCHING PATTERN "*.h" PATTERN "private/Config.h" EXCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/osmscout/MapQtFeatures.h DESTINATION include/osmscout)
