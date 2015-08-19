# This file is part of CMake-easylib.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Copyright (C)
#   2015 Alexander Haase <alexander.haase@rwth-aachen.de>
#
# All rights reserved.
#

# Global option to select wheter static or shared libraries should be used for
# lining when both exist as CMake targets and no specific one is selected.
option(LINK_SHARED_LIBS "Selects whether static or shared libs will
	be used for linking when both exist." TRUE)


# This module should help to create static and shared libraries with a single
# function call.
#
function(add_library TARGET SOURCES)
	# remove ${TARGET} from ${ARGV} to use ${ARGV} as ${SOURCES}
	list(REMOVE_AT ARGV 0)

	# Get library type. If it is set as first ARGV, the value will be used.
	# Otherwise the word "LIBRARY" indicates that both static and shared
	# libraries should be build.
	set(lib_type "LIBRARY")
	if (${ARGV1} STREQUAL "STATIC" OR ${ARGV1} STREQUAL "SHARED"
	OR ${ARGV1} STREQUAL "MODULE" OR ${ARGV1} STREQUAL "OBJECT")
		set(lib_type ${ARGV1})
		list(REMOVE_AT ARGV 0)
	endif()

	# Processing of EXTRACT_FROM_ALL keyword can be passed, due it will be seen
	# parsed like a normal source file and thus passed to _add_library.

	# Extract expressions out of source list. If there is a equal namked target,
	# the expression will be copied. If there are static and shared targets for
	# the expression, the expression will be deleted and the library linked to
	# the new target.
	set(sources "")
	set(objects "")
	set(obj_sources "")
	set(obj_sources_pic "")
	foreach (source ${ARGV})
		string(REGEX MATCH "TARGET_OBJECTS:([^ >]+)" _source ${source})

		# If expression was found, check if there are targets for normal and
		# position independent code object libraries.
		if (NOT "${_source}" STREQUAL "")
			string(REGEX REPLACE "TARGET_OBJECTS:([^ >]+)" "\\1" tgt ${_source})

			if (TARGET "${tgt}" AND TARGET "${tgt}_pic")
				list(APPEND objects "${tgt}")
				list(APPEND obj_sources "$<TARGET_OBJECTS:${tgt}>")
				list(APPEND obj_sources_pic "$<TARGET_OBJECTS:${tgt}_pic>")
			else ()
				list(APPEND sources ${source})
			endif()
		else ()
			list(APPEND sources ${source})
		endif ()
	endforeach(source)


	# Build library for specific build types.
	if ("${lib_type}" STREQUAL "LIBRARY")
		_add_library(${TARGET}_static STATIC ${sources} ${obj_sources})
		_add_library(${TARGET}_shared SHARED ${sources} ${obj_sources_pic})
		set_target_properties(${TARGET}_static PROPERTIES OUTPUT_NAME ${TARGET})
		set_target_properties(${TARGET}_shared PROPERTIES OUTPUT_NAME ${TARGET})

	elseif ("${lib_type}" STREQUAL "OBJECT")
		_add_library(${TARGET} OBJECT ${sources} ${obj_sources})
		_add_library(${TARGET}_pic OBJECT ${sources} ${obj_sources_pic})
		set_target_properties(${TARGET}_pic PROPERTIES
			POSITION_INDEPENDENT_CODE True)

	else ()
		set(objects_to_use "${obj_sources}")
		if ("${lib_type}" STREQUAL "SHARED" OR "${lib_type}" STREQUAL "MODULE")
			set(objects_to_use "${obj_sources_pic}")
		endif ()

		_add_library(${TARGET} ${lib_type} ${sources} ${objects_to_use})
	endif ()


	# Which libraries should this library be linked against, which were defined
	# for object libraries?
	set(link_libs "")
	foreach (obj ${objects})
		list(APPEND link_libs "${${obj}_LINK_AGAINST}")
	endforeach ()

	if (NOT "${link_libs}" STREQUAL "")
		list(REMOVE_DUPLICATES link_libs)
		list(REMOVE_ITEM link_libs "")

		if (NOT "${lib_type}" STREQUAL "OBJECT")
			target_link_libraries(${TARGET} "${link_libs}")
		endif ()
	endif ()
endfunction(add_library)


# This function overloads the default target_link_libraries. If TARGET is a
# library that is build static and shared, target_link_libraries will be called
# for both targets.
function(target_link_libraries TARGET LIBRARIES)
	# remove ${TARGET} from ${ARGV} to use ${ARGV} as ${LIBRARIES}
	list(REMOVE_AT ARGV 0)

	# If target is an OBJECT library, target will not be linked against the
	# libraries, but they will be added to a global variable for the OBJECT lib.
	if (TARGET ${TARGET} AND TARGET ${TARGET}_pic)
		set(${TARGET}_LINK_AGAINST "${${TARGET}_LINK_AGAINST};${ARGV}")
		list(REMOVE_DUPLICATES ${TARGET}_LINK_AGAINST)
		list(REMOVE_ITEM ${TARGET}_LINK_AGAINST "")
		set(${TARGET}_LINK_AGAINST "${${TARGET}_LINK_AGAINST}"
			CACHE INTERNAL "")
		return()
	endif ()


	# If there are static and shared targets for an entry in ${ARGV}, replace it
	# by the responding targets for each of them.
	set(link_libs_static)
	set(link_libs_shared)
	foreach (arg ${ARGV})
		if (TARGET ${arg}_static AND TARGET ${arg}_shared)
			list(APPEND link_libs_static "${arg}_static")
			list(APPEND link_libs_shared "${arg}_shared")
		else ()
			list(APPEND link_libs_static "${arg}")
			list(APPEND link_libs_shared "${arg}")
		endif ()
	endforeach ()

	# If there are static and shared targets for ${TARGET}, call original
	# function for both of them.
	if (TARGET ${TARGET}_static AND TARGET ${TARGET}_shared)
		_target_link_libraries(${TARGET}_static ${link_libs_static})
		_target_link_libraries(${TARGET}_shared ${link_libs_shared})
		return()
	endif ()


	# Fallback to normal handling, if there are no static and shared targets for
	# ${TARGET}. If LINK_SHARED_LIBS option is true, link_libs_shared will be
	# used, otherwise link_libs_static.
	if (${LINK_SHARED_LIBS})
		_target_link_libraries(${TARGET} ${link_libs_shared})
	else ()
		_target_link_libraries(${TARGET} ${link_libs_static})
	endif()
endfunction(target_link_libraries)
