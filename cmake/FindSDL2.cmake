# Locate SDL2 library
# This module defines
# SDL2_LIBRARY, the name of the library to link against
# SDL2_FOUND, if false, do not try to link to SDL2
# SDL2_INCLUDE_DIR, where to find SDL.h
#
# This module responds to the the flag:
# SDL2_BUILDING_LIBRARY
# If this is defined, then no SDL2main will be linked in because
# only applications need main().
# Otherwise, it is assumed you are building an application and this
# module will attempt to locate and set the the proper link flags
# as part of the returned SDL2_LIBRARY variable.
#
# Don't forget to include SDLmain.h and SDLmain.m your project for the
# OS X framework based version. (Other versions link to -lSDL2main which
# this module will try to find on your behalf.) Also for OS X, this
# module will automatically add the -framework Cocoa on your behalf.
#
#
# Additional Note: If you see an empty SDL2_LIBRARY_TEMP in your configuration
# and no SDL2_LIBRARY, it means CMake did not find your SDL2 library
# (SDL2.dll, libsdl2.so, SDL2.framework, etc).
# Set SDL2_LIBRARY_TEMP to point to your SDL2 library, and configure again.
# Similarly, if you see an empty SDL2MAIN_LIBRARY, you should set this value
# as appropriate. These values are used to generate the final SDL2_LIBRARY
# variable, but when these values are unset, SDL2_LIBRARY does not get created.
#
#
# $SDL2DIR is an environment variable that would
# correspond to the ./configure --prefix=$SDL2DIR
# used in building SDL2.
# l.e.galup  9-20-02
#
# Modified by Eric Wing.
# Added code to assist with automated building by using environmental variables
# and providing a more controlled/consistent search behavior.
# Added new modifications to recognize OS X frameworks and
# additional Unix paths (FreeBSD, etc).
# Also corrected the header search path to follow "proper" SDL guidelines.
# Added a search for SDL2main which is needed by some platforms.
# Added a search for threads which is needed by some platforms.
# Added needed compile switches for MinGW.
#
# On OSX, this will prefer the Framework version (if found) over others.
# People will have to manually change the cache values of
# SDL2_LIBRARY to override this selection or set the CMake environment
# CMAKE_INCLUDE_PATH to modify the search paths.
#
# Note that the header path has changed from SDL2/SDL.h to just SDL.h
# This needed to change because "proper" SDL convention
# is #include "SDL.h", not <SDL2/SDL.h>. This is done for portability
# reasons because not all systems place things in SDL2/ (see FreeBSD).

#=============================================================================
# Copyright 2003-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# Caveat: If you want to find standard libraries or headers before frameworks,
#         you must pass -DCMAKE_FIND_FRAMEWORK=LAST to cmake.
SET(SDL2_SEARCH_PATHS
	# other paths like ~/Library/Frameworks and /usr/local
	# should be provided/prioritized by setting $ENV{SDL2DIR}
	/Library/Frameworks
	/usr
)

# CPU architecture detection for MSVC
IF(CMAKE_SIZEOF_VOID_P MATCHES 8)
	SET(CPU_ARCH "x64")
ELSE()
	SET(CPU_ARCH "x86")
ENDIF()

# Precedence (CMake 2.6+): HINTS > SYSTEM_PATHS > PATHS
FIND_PATH(SDL2_INCLUDE_DIR
	NAMES SDL.h
	PATH_SUFFIXES include/SDL2 SDL2 include
	HINTS $ENV{SDL2DIR}
	PATHS ${SDL2_SEARCH_PATHS}
)

FIND_LIBRARY(SDL2_LIBRARY_TEMP
	NAMES SDL2
	PATH_SUFFIXES lib64 lib lib/${CPU_ARCH}
	HINTS $ENV{SDL2DIR}
	PATHS ${SDL2_SEARCH_PATHS}
)

FIND_PATH(SDL2_mixer_INCLUDE_DIR
	NAMES SDL_mixer.h
	PATH_SUFFIXES include/SDL2 SDL2 include
	HINTS $ENV{SDL2DIR}
	PATHS ${SDL2_SEARCH_PATHS}
)

FIND_LIBRARY(SDL2_mixer_LIBRARY_TEMP
	NAMES SDL2_mixer
	PATH_SUFFIXES lib64 lib lib/${CPU_ARCH}
	HINTS $ENV{SDL2DIR}
	PATHS ${SDL2_SEARCH_PATHS}
)

IF((SDL2_INCLUDE_DIR MATCHES "\\.framework") OR (SDL2_mixer_INCLUDE_DIR MATCHES "\\.framework"))
	IF ((NOT SDL2_INCLUDE_DIR MATCHES "\\.framework") OR (NOT SDL2_mixer_INCLUDE_DIR MATCHES "\\.framework"))
	MESSAGE(WARNING
		"You don't seem to have all of these frameworks installed in your system:\n"
		"    SDL2.framework: ${SDL2_INCLUDE_DIR};${SDL2_LIBRARY_TEMP}\n"
		"    SDL2_mixer.framework: ${SDL2_mixer_INCLUDE_DIR};${SDL2_mixer_LIBRARY_TEMP}\n"
		"Pass -DCMAKE_FIND_FRAMEWORK=LAST to cmake if you don't want to use the framework bundles.")
	ENDIF()
ENDIF()

IF(NOT SDL2_BUILDING_LIBRARY)
	IF(NOT SDL2_INCLUDE_DIR MATCHES "\\.framework")
		# Non-OS X framework versions expect you to also dynamically link to
		# SDL2main. This is mainly for Windows and OS X. Other (Unix) platforms
		# seem to provide SDL2main for compatibility even though they don't
		# necessarily need it.
		FIND_LIBRARY(SDL2MAIN_LIBRARY
			NAMES SDL2main
			PATH_SUFFIXES lib64 lib "lib/${CPU_ARCH}"
			HINTS $ENV{SDL2DIR}
			PATHS ${SDL2_SEARCH_PATHS}
		)
	ENDIF(NOT SDL2_INCLUDE_DIR MATCHES "\\.framework")
ENDIF(NOT SDL2_BUILDING_LIBRARY)

# SDL2 may require threads on your system.
# The Apple build may not need an explicit flag because one of the
# frameworks may already provide it.
# But for non-OSX systems, I will use the CMake Threads package.
IF(NOT APPLE)
	FIND_PACKAGE(Threads)
ENDIF(NOT APPLE)

# MinGW needs an additional link flag, -mwindows
# It's total link flags should look like -lmingw32 -lSDL2main -lSDL2 -mwindows
IF(MINGW)
	SET(MINGW32_LIBRARY mingw32 "-mwindows" CACHE STRING "mwindows for MinGW")
ENDIF(MINGW)

IF(SDL2_LIBRARY_TEMP)
	# For SDL2main
	IF(NOT SDL2_BUILDING_LIBRARY)
		IF(SDL2MAIN_LIBRARY)
			SET(SDL2_LIBRARY_TEMP ${SDL2MAIN_LIBRARY} ${SDL2_LIBRARY_TEMP})
		ENDIF(SDL2MAIN_LIBRARY)
	ENDIF(NOT SDL2_BUILDING_LIBRARY)
ENDIF(SDL2_LIBRARY_TEMP)

MACRO(SET_SDL2_LIBRARY_WITH_TEMP SDL_LIB)
	IF(${SDL_LIB}_LIBRARY_TEMP)
		# For OS X, SDL2 uses Cocoa as a backend so it must link to Cocoa.
		# CMake doesn't display the -framework Cocoa string in the UI even
		# though it actually is there if I modify a pre-used variable.
		# I think it has something to do with the CACHE STRING.
		# So I use a temporary variable until the end so I can set the
		# "real" variable in one-shot.
		IF(APPLE)
			SET(${SDL_LIB}_LIBRARY_TEMP ${${SDL_LIB}_LIBRARY_TEMP} "-framework Cocoa")
		ENDIF(APPLE)

		# For threads, as mentioned Apple doesn't need this.
		# In fact, there seems to be a problem if I used the Threads package
		# and try using this line, so I'm just skipping it entirely for OS X.
		IF(NOT APPLE)
			SET(${SDL_LIB}_LIBRARY_TEMP ${${SDL_LIB}_LIBRARY_TEMP} ${CMAKE_THREAD_LIBS_INIT})
		ENDIF(NOT APPLE)

		# For MinGW library
		IF(MINGW)
			SET(${SDL_LIB}_LIBRARY_TEMP ${MINGW32_LIBRARY} ${${SDL_LIB}_LIBRARY_TEMP})
		ENDIF(MINGW)

		# Set the final string here so the GUI reflects the final state.
		SET(${SDL_LIB}_LIBRARY ${${SDL_LIB}_LIBRARY_TEMP} CACHE STRING "Where the ${SDL_LIB} Library can be found")
		# Set the temp variable to INTERNAL so it is not seen in the CMake GUI
		SET(${SDL_LIB}_LIBRARY_TEMP "${${SDL_LIB}_LIBRARY_TEMP}" CACHE INTERNAL "")
	ENDIF(${SDL_LIB}_LIBRARY_TEMP)
ENDMACRO(SET_SDL2_LIBRARY_WITH_TEMP)

SET_SDL2_LIBRARY_WITH_TEMP(SDL2)
SET_SDL2_LIBRARY_WITH_TEMP(SDL2_mixer)

INCLUDE(FindPackageHandleStandardArgs)

FIND_PACKAGE_HANDLE_STANDARD_ARGS(SDL2 REQUIRED_VARS SDL2_LIBRARY SDL2_INCLUDE_DIR SDL2_mixer_LIBRARY SDL2_mixer_INCLUDE_DIR)
