# This file is part of X-ARF tools.
#
# X-ARF tools is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License and GNU
# Lesser General Public License along with this program. If not, see
#
# http://www.gnu.org/licenses/
#
#
# Copyright (C)
#   2015 Alexander Haase <alexander.haase@rwth-aachen.de>
#


# This module should help to create static and shared libraries with a single
# function call.
#
function(add_lib TARGET SOURCES)
	# remove ${TARGET} from ${ARGV} to use ${ARGV} as ${SOURCES}
	list(REMOVE_AT ARGV 0)

	# if ${ARGV1} is OBJECT, then we should build an object library.
	set(lib_type "")
	if (${ARGV1} STREQUAL "OBJECT")
		set(lib_type "OBJECT")
		list(REMOVE_AT ARGV 0)

		# build object library for static files
		add_library(${TARGET}_static OBJECT ${ARGV})

		# build object library for shared files
		add_library(${TARGET}_shared OBJECT ${ARGV})
		set_target_properties(${TARGET}_shared PROPERTIES
			POSITION_INDEPENDENT_CODE True
		)
	else ()
		# replace $<TARGET_OBJECT:...> by the names of shared / static target
		foreach (lib_type STATIC SHARED)
			string(TOLOWER ${lib_type} lib_type_lower)

			set(source_list_${lib_type} "")
			foreach (source ${ARGV})
				string(REGEX REPLACE
					"TARGET_OBJECTS:([^ >]+)" "TARGET_OBJECTS:\\1_${lib_type_lower}"
					r_source
					${source}
				)
				list(APPEND source_list_${lib_type} ${r_source})
			endforeach(source)

			# build library for lib_type
			add_library(${TARGET}_${lib_type_lower} ${lib_type}
				${source_list_${lib_type}}
			)

			# set output name to ${TARGET}
			set_target_properties(${TARGET}_${lib_type_lower} PROPERTIES
				OUTPUT_NAME ${TARGET}
			)
		endforeach(lib_type)
	endif ()
endfunction(add_lib)
