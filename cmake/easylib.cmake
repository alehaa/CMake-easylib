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


# This module should help to create static and shared libraries with a single
# function call.
#
function(add_library TARGET SOURCES)
	# remove ${TARGET} from ${ARGV} to use ${ARGV} as ${SOURCES}
	list(REMOVE_AT ARGV 0)

	# get library type
	if (${ARGV1} STREQUAL "OBJECT")
		list(REMOVE_AT ARGV 0)
		set(lib_type "OBJECT")

	else ()
		set(lib_type "LIBRARY")
	endif()


	# Extract expressions out of source list. If there is a equal namked target,
	# the expression will be copied. If there are static and shared targets for
	# the expression, the expression will be deleted and the library linked to
	# the new target.
	set(sources "")
	set(link_libs "")
	foreach (source ${ARGV})
		string(REGEX MATCH "TARGET_OBJECTS:([^ >]+)" _source ${source})

		# If expression was found, check if there are targets for static and
		# shared libs.
		if (NOT "${_source}" STREQUAL "")
			string(REGEX REPLACE "TARGET_OBJECTS:([^ >]+)" "\\1" tgt ${_source})

			if (TARGET "${tgt}_static" AND TARGET ${tgt}_shared)
				list(APPEND link_libs ${tgt})
			else ()
				list(APPEND sources ${_source})
			endif()
		else ()
			list(APPEND sources ${source})
		endif ()
	endforeach(source)


	# Create static and shared target for library. If a method is disabled by
	# CMake, the library type will not be build.
	foreach (ltype STATIC SHARED)
		string(TOLOWER ${ltype} _ltype)

		# OBJECT libraried will be build as static libraries
		if (${lib_type} STREQUAL "OBJECT")
			set(ltype "STATIC")
		endif ()

		# add new target
		_add_library(${TARGET}_${_ltype} ${ltype} ${sources})
		foreach (lib ${link_libs})
			target_link_libraries(${TARGET}_${_ltype} ${lib}_${_ltype})
		endforeach ()

		# if type is shared, we have to build with PiC flag
		if (${lib_type} STREQUAL "OBJECT" AND ${ltype} STREQUAL "SHARED")
			set_target_properties(${TARGET}_${_ltype} PROPERTIES
				POSITION_INDEPENDENT_CODE True
			)
		endif()

		# set output name to ${TARGET}
		if (NOT ${lib_type} STREQUAL "OBJECT")
			set_target_properties(${TARGET}_${_ltype} PROPERTIES
				OUTPUT_NAME ${TARGET}
			)
		endif ()
	endforeach ()
endfunction(add_library)
