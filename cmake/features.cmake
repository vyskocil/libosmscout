# add ccache support
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CCCACHE_EXPORTS "")
  set(CCACHE_OPTIONS "" CACHE STRING "options for ccache")
  foreach(option ${CCACHE_OPTIONS})
    set(CCCACHE_EXPORTS "${CCCACHE_EXPORTS}\nexport ${option}")
  endforeach()
  set(C_LAUNCHER "${CCACHE_PROGRAM}")
  set(CXX_LAUNCHER "${CCACHE_PROGRAM}")
  configure_file("${OSMSCOUT_BASE_DIR_SOURCE}/cmake/launch-c.in" "${CMAKE_BINARY_DIR}/launch-c")
  configure_file("${OSMSCOUT_BASE_DIR_SOURCE}/cmake/launch-cxx.in" "${CMAKE_BINARY_DIR}/launch-cxx")
  execute_process(COMMAND chmod a+rx
    "${CMAKE_BINARY_DIR}/launch-c"
    "${CMAKE_BINARY_DIR}/launch-cxx"
  )
  if(CMAKE_GENERATOR STREQUAL "Xcode")
    set(CMAKE_XCODE_ATTRIBUTE_CC         "${CMAKE_BINARY_DIR}/launch-c" CACHE INTERNAL "")
    set(CMAKE_XCODE_ATTRIBUTE_CXX        "${CMAKE_BINARY_DIR}/launch-cxx" CACHE INTERNAL "")
    set(CMAKE_XCODE_ATTRIBUTE_LD         "${CMAKE_BINARY_DIR}/launch-c" CACHE INTERNAL "")
    set(CMAKE_XCODE_ATTRIBUTE_LDPLUSPLUS "${CMAKE_BINARY_DIR}/launch-cxx" CACHE INTERNAL "")
  else()
    set(CMAKE_C_COMPILER_LAUNCHER   "${CMAKE_BINARY_DIR}/launch-c" CACHE INTERNAL "")
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CMAKE_BINARY_DIR}/launch-cxx")
  endif()
endif()

# detect available compiler features and libraries
include(CheckCXXSourceCompiles)
include(CheckPrototypeDefinition)
include(CheckCCompilerFlag)
include(CheckTypeSize)
include(CheckFunctionExists)
include(CheckCXXCompilerFlag)

# detect 32 or 64 bits
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
  set(OSMSCOUT_PLATFORM_X64 ON)
else ()
  set(OSMSCOUT_PLATFORM_X64 OFF)
endif ()

# check for SSE etc.
if(NOT MSVC)
  check_c_compiler_flag(-faltivec HAVE_ALTIVEC)
  check_c_compiler_flag(-mavx HAVE_AVX)
  check_c_compiler_flag(-mmmx HAVE_MMX)
  option(OSMSCOUT_ENABLE_SSE "Enable SSE support (not working on all platforms!)" OFF)
  if(OSMSCOUT_ENABLE_SSE)
    check_c_compiler_flag(-msse HAVE_SSE)
    check_c_compiler_flag(-msse2 HAVE_SSE2)
    check_c_compiler_flag(-msse3 HAVE_SSE3)
    check_c_compiler_flag(-msse4.1 HAVE_SSE4_1)
    check_c_compiler_flag(-msse4.2 HAVE_SSE4_2)
    check_c_compiler_flag(-mssse3 HAVE_SSSE3)
  endif()
  if(HAVE_SSE2)
    try_compile(SSE_OK "${PROJECT_BINARY_DIR}"
        "${PROJECT_SOURCE_DIR}/cmake/TestSSE.c"
        COMPILE_DEFINITIONS "-msse2" )
    if(NOT SSE_OK)
      message(STATUS "SSE test compilation fails")
      set(HAVE_SSE2 FALSE)
    endif()
  endif()
  if(HAVE_SSE2)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse2")
  endif()
else()
  set(HAVE_ALTIVEC OFF)
  set(HAVE_AVX ON)
  set(HAVE_MMX ON)
  set(HAVE_SSE ON)
  set(HAVE_SSE2 ON)
  set(HAVE_SSE3 OFF)
  set(HAVE_SSE4_1 OFF)
  set(HAVE_SSE4_2 OFF)
  set(HAVE_SSSE3 OFF)
  if (NOT OSMSCOUT_PLATFORM_X64)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE2")
  endif()
endif()

if(CMAKE_COMPILER_IS_GNUCXX)
  check_cxx_compiler_flag(-fvisibility=hidden HAVE_VISIBILITY)
  if(HAVE_VISIBILITY)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fvisibility=hidden")
  endif()
else()
  set(HAVE_VISIBILITY OFF)
endif()

# check headers exists
include(CheckIncludeFileCXX)
check_include_file(dlfcn.h HAVE_DLFCN_H)
check_include_file(fcntl.h HAVE_FCNTL_H)
check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(memory.h HAVE_MEMORY_H)
check_include_file(stdint.h HAVE_STDINT_H)
check_include_file(stdlib.h HAVE_STDLIB_H)
check_include_file(strings.h HAVE_STRINGS_H)
check_include_file(string.h HAVE_STRING_H)
check_include_file(sys/stat.h HAVE_SYS_STAT_H)
check_include_file(sys/time.h HAVE_SYS_TIME_H)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file_cxx(codecvt HAVE_CODECVT)
if(HAVE_STDINT_H AND HAVE_STDLIB_H AND HAVE_INTTYPES_H AND HAVE_STRING_H AND HAVE_MEMORY_H)
  set(STDC_HEADERS ON)
else()
  set(STDC_HEADERS OFF)
endif()

# check data types exists
set(CMAKE_EXTRA_INCLUDE_FILES inttypes.h)
check_type_size(int16_t HAVE_INT16_T)
check_type_size(int32_t HAVE_INT32_T)
check_type_size(int64_t HAVE_INT64_T)
check_type_size(int8_t HAVE_INT8_T)
check_type_size("long long" HAVE_LONG_LONG)
check_type_size(uint16_t HAVE_UINT16_T)
check_type_size(uint32_t HAVE_UINT32_T)
check_type_size(uint64_t HAVE_UINT64_T)
check_type_size(uint8_t HAVE_UINT8_T)
check_type_size("unsigned long long" HAVE_UNSIGNED_LONG_LONG)
set(CMAKE_EXTRA_INCLUDE_FILES wchar.h)
check_type_size(wchar_t SIZEOF_WCHAR_T)
set(CMAKE_EXTRA_INCLUDE_FILES)

# check functions exists
check_function_exists(fseeko HAVE_FSEEKO)
check_function_exists(mmap HAVE_MMAP)
check_function_exists(posix_fadvise HAVE_POSIX_FADVISE)
check_function_exists(posix_madvise HAVE_POSIX_MADVISE)
check_function_exists(mallinfo2 HAVE_MALLINFO2)

# prefer static libraries if shared are disabled
if(NOT BUILD_SHARED_LIBS AND (CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANGXX OR CMAKE_COMPILER_IS_GNUCC))
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
endif()

# check libraries and tools
macro(target_exists target var)
  if(TARGET ${target})
    set(${var} 1)
  else()
    set(${var} 0)
  endif()
endmacro()

if(NOT IOS)
  find_package(Marisa)
endif()
set(HAVE_LIB_MARISA ${MARISA_FOUND})
set(OSMSCOUT_HAVE_LIB_MARISA ${HAVE_LIB_MARISA})
set(OSMSCOUT_IMPORT_HAVE_LIB_MARISA ${MARISA_FOUND})

find_package(LibXml2 QUIET)
if (TARGET LibXml2::LibXml2 AND NOT BUILD_SHARED_LIBS)
  # seems that FindLibXml2.cmake don't handle static libraries properly
  # as a workaround we append PC_LIBXML_STATIC_LIBRARIES to LIBXML2_LIBRARIES
  set(LIBXML2_LIBRARIES ${LIBXML2_LIBRARIES} ${PC_LIBXML_STATIC_LIBRARIES})

  if (CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANGXX OR CMAKE_COMPILER_IS_GNUCC)
    # Libxml contains tiny http client that is using libc gethostbyname and getaddrinfo.
    # These functions are using dlopen in glibc, so it requires libdl dependency
    # and glibc libraries at runtime! Resulted binary is not fully static.
    list(APPEND LIBXML2_LIBRARIES "dl")
  endif()
endif()
target_exists(LibXml2::LibXml2 HAVE_LIB_XML)
target_exists(LibXml2::LibXml2 OSMSCOUT_GPX_HAVE_LIB_XML)

find_package(Protobuf QUIET)
if (TARGET protobuf::libprotobuf AND NOT EXISTS ${PROTOBUF_PROTOC_EXECUTABLE})
  message(STATUS "Protobuf library found, but protoc compiler is missing")
endif()
target_exists(protobuf::libprotobuf HAVE_LIB_PROTOBUF)

find_package(ZLIB QUIET)
target_exists(ZLIB::ZLIB HAVE_LIB_ZLIB)

find_package(LibLZMA QUIET)

find_package(PNG QUIET)
set(HAVE_LIB_PNG ${PNG_FOUND})

find_package(Cairo QUIET)
if(CAIRO_FOUND)
  option(CAIRO_STATIC "Switch on if the found cairo library is static" OFF)
  if(CAIRO_STATIC)
    add_definitions(-DCAIRO_WIN32_STATIC_BUILD)
  endif()
  mark_as_advanced(CAIRO_STATIC)
endif()
set(HAVE_LIB_CAIRO ${CAIRO_FOUND})

find_package(LibAgg QUIET)
set(HAVE_LIB_AGG ${LIBAGG_FOUND})

find_package(Freetype QUIET)
set(HAVE_LIB_FREETYPE ${FREETYPE_FOUND})

find_package(Pango QUIET)
set(HAVE_LIB_PANGO ${PANGO_FOUND})
set(OSMSCOUT_MAP_CAIRO_HAVE_LIB_PANGO ${PANGOCAIRO_FOUND})
set(OSMSCOUT_MAP_SVG_HAVE_LIB_PANGO ${PANGOFT2_FOUND})

find_package(harfbuzz QUIET)
target_exists(harfbuzz::harfbuzz HAVE_LIB_HARFBUZZ)

set(OpenGL_GL_PREFERENCE "GLVND") # Prever non-legacy OpenGL libraries
find_package(OpenGL QUIET)
set(HAVE_LIB_OPENGL ${OPENGL_FOUND})

find_package(GLEW QUIET)

find_package(glm QUIET)
if(NOT TARGET glm::glm)
  message(STATUS "glm NOT found")
  find_package(Git QUIET)
  if(Git_FOUND)
    option(OSMSCOUT_DOWNLOAD_GLM_IF_NOT_FOUND "Load GLM via Git automatically if the library was not found offline" OFF)
	if(OSMSCOUT_DOWNLOAD_GLM_IF_NOT_FOUND)
      set(GLM_ROOT_DIR ${CMAKE_BINARY_DIR}/glm)
      execute_process(
        COMMAND ${GIT_EXECUTABLE} clone https://github.com/g-truc/glm.git --recursive ${GLM_ROOT_DIR}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        RESULT_VARIABLE git_result
        OUTPUT_VARIABLE git_output)
      find_package(GLM)
	endif()
	mark_as_advanced(OSMSCOUT_DOWNLOAD_GLM_IF_NOT_FOUND)
  endif()
endif()

find_package(glfw3 QUIET)

if (QT_VERSION_PREFERRED AND QT_VERSION_PREFERRED EQUAL 5)
  message(STATUS "Try loading Qt5 (explicitly preferred)...")
  set(QT5_TRIED 1)
  set(QT_DEFAULT_MAJOR_VERSION 5)
  find_package(Qt5 5.15 COMPONENTS Core Gui Widgets Qml Quick Svg Location Positioning Multimedia LinguistTools QUIET)
  if(Qt5_FOUND)
    message(STATUS "Choosing Qt5, since explicitly preferred")
    set(QT_FOUND 1)
    set(QT_VERSION_MAJOR 5)
  else ()
    message(STATUS "Qt5 NOT found")
  endif()
endif ()

if (QT_VERSION_PREFERRED AND QT_VERSION_PREFERRED EQUAL 6)
  message(STATUS "Try loading preferred Qt6 (explicitly preferred)...")
  set(QT6_TRIED 1)
  set(QT_DEFAULT_MAJOR_VERSION 6)
  find_package(Qt6 COMPONENTS Core Core5Compat Gui Widgets Qml Quick Svg Positioning Multimedia LinguistTools QUIET)
  if(Qt6_FOUND)
    message(STATUS "Choosing Qt6, since explicitly preferred")
    set(QT_FOUND 1)
    set(QT_VERSION_MAJOR 6)
  else ()
    message(STATUS "Qt6 NOT found")
  endif()
endif()

if (NOT QT_FOUND AND NOT QT5_TRIED)
  message(STATUS "Try loading Qt5 (implicitly preferred version)...")
  set(QT_DEFAULT_MAJOR_VERSION 5)
  find_package(Qt5 5.15 COMPONENTS Core Gui Widgets Qml Quick Svg Location Positioning Multimedia LinguistTools QUIET)
endif ()

if(NOT QT_FOUND)
  if (Qt5_FOUND)
    message(STATUS "Choosing Qt5, since implicitly preferred")
    set(QT_FOUND 1)
    set(QT_VERSION_MAJOR 5)
  else ()
    message(STATUS "Qt5 NOT found")
  endif ()
endif ()

if (NOT QT_FOUND AND NOT QT6_TRIED)
  message(STATUS "Try loading Qt6 (implicitly preferred version)...")
  set(QT_DEFAULT_MAJOR_VERSION 6)
  find_package(Qt6 COMPONENTS Core Core5Compat Gui Widgets Qml Quick Svg Positioning Multimedia LinguistTools QUIET)
endif()

if (NOT QT_FOUND)
  if (Qt6_FOUND)
    message(STATUS "Choosing Qt6, since implicitly preferred")
    set(QT_FOUND 1)
    set(QT_VERSION_MAJOR 6)
  else ()
    message(STATUS "Qt6 NOT found")
  endif()
endif()

if(QT_FOUND)
  message(STATUS "Qt version used: ${QT_VERSION_MAJOR}")
  option(QT_QML_DEBUG "Build with QML debugger support" OFF)
  mark_as_advanced(QT_QML_DEBUG)

  if (Qt5_FOUND)
    if (Qt5Core_FOUND AND Qt5Gui_FOUND AND Qt5Widgets_FOUND AND Qt5Svg_FOUND)
      message(STATUS "Qt5 map dependencies found")
      set(QT_MAP_DEPENDENCIES_FOUND 1)
    endif()
    if (Qt5Core_FOUND AND Qt5Gui_FOUND AND Qt5Widgets_FOUND AND Qt5Svg_FOUND AND Qt5Qml_FOUND AND Qt5Quick_FOUND AND Qt5Network_FOUND AND Qt5Location_FOUND AND Qt5Multimedia_FOUND)
      message(STATUS "Qt5 client dependencies found")
      set(QT_CLIENT_DEPENDENCIES_FOUND 1)
    endif()
  endif()

  if (Qt6_FOUND)
    if (Qt6Core_FOUND AND Qt6Gui_FOUND AND Qt6Widgets_FOUND AND Qt6Svg_FOUND)
      message(STATUS "Qt6 map dependencies found")
      set(QT_MAP_DEPENDENCIES_FOUND 1)
    endif()
    if (Qt6Core_FOUND AND Qt6Gui_FOUND AND Qt6Widgets_FOUND AND Qt6Svg_FOUND AND Qt6Qml_FOUND AND Qt6Quick_FOUND AND Qt6Network_FOUND AND Qt6Multimedia_FOUND)
      message(STATUS "Qt6 client dependencies found")
      set(QT_CLIENT_DEPENDENCIES_FOUND 1)
    endif()
  endif()

  if (Qt5_FOUND)
    set(HAVE_LIB_QT5_GUI ${Qt5Gui_FOUND})
    set(HAVE_LIB_QT5_WIDGETS ${Qt5Widgets_FOUND})
  else()
    set(HAVE_LIB_QT5_GUI ${Qt6Gui_FOUND})
    set(HAVE_LIB_QT5_WIDGETS ${Qt6Widgets_FOUND})
  endif()
endif ()

find_package(OpenMP QUIET)
set(OSMSCOUT_HAVE_OPENMP ${OPENMP_FOUND})

find_package(Doxygen QUIET)
#find_package(SWIG QUIET)
#find_package(JNI QUIET)
#find_package(PythonInterp QUIET)
#find_package(PythonLibs QUIET)
set(Matlab_FIND_COMPONENTS MX_LIBRARY)
find_package(MATLAB QUIET)

find_package(Gperftools QUIET)
set(HAVE_LIB_GPERFTOOLS ${GPERFTOOLS_FOUND})
if(GPERFTOOLS_FOUND)
  set(GPERFTOOLS_USAGE ON)
else()
  set(GPERFTOOLS_USAGE OFF)
endif()

find_package(Direct2D QUIET)

find_package(Threads)
if(THREADS_HAVE_PTHREAD_ARG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${THREADS_PTHREAD_ARG}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${THREADS_PTHREAD_ARG}")
endif()

try_compile(PTHREAD_NAME_OK "${PROJECT_BINARY_DIR}"
  "${PROJECT_SOURCE_DIR}/cmake/TestPThreadName.cpp")
if(PTHREAD_NAME_OK)
  set(OSMSCOUT_PTHREAD_NAME TRUE)
endif()

if(MSVC)
  set(HAVE_STD_EXECUTION 1)
else()
   find_package(TBB QUIET)
   if (TBB_FOUND)
   try_compile(TBB_HAS_SCHEDULER_INIT "${PROJECT_BINARY_DIR}"
         "${PROJECT_SOURCE_DIR}/cmake/TestTBBSchedulerInit.cpp"
         LINK_LIBRARIES TBB::tbb)
   endif()
   set(HAVE_STD_EXECUTION ${TBB_FOUND})
endif()

find_program(HUGO_PATH hugo)

# prepare cmake variables for configuration files
set(OSMSCOUT_HAVE_INT16_T ${HAVE_INT16_T})
set(OSMSCOUT_HAVE_INT32_T ${HAVE_INT32_T})
set(OSMSCOUT_HAVE_INT64_T ${HAVE_INT64_T})
set(OSMSCOUT_HAVE_INT8_T ${HAVE_INT8_T})
set(OSMSCOUT_HAVE_LONG_LONG ${HAVE_LONG_LONG})
set(OSMSCOUT_HAVE_SSE2 ${HAVE_SSE2})
set(OSMSCOUT_HAVE_STDINT_H ${HAVE_STDINT_H})
set(OSMSCOUT_HAVE_STD_WSTRING ${HAVE_STD__WSTRING})
set(OSMSCOUT_HAVE_UINT16_T ${HAVE_UINT16_T})
set(OSMSCOUT_HAVE_UINT32_T ${HAVE_UINT32_T})
set(OSMSCOUT_HAVE_UINT64_T ${HAVE_UINT64_T})
set(OSMSCOUT_HAVE_UINT8_T ${HAVE_UINT8_T})
set(OSMSCOUT_HAVE_ULONG_LONG ${HAVE_UNSIGNED_LONG_LONG})
