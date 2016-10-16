# This file is part of CMake-easylib.
#
# Copyright (C)
#   2015-2016 Alexander Haase <alexander.haase@rwth-aachen.de>
#
# See the LICENSE file in the base directory for details.
# All rights reserved.
#

# Global option to select wheter static or shared libraries should be used for
# lining when both exist as CMake targets and no specific one is selected.
option(LINK_SHARED_LIBS "Selects whether static or shared libs will
	be used for linking when both exist." TRUE)


# Wrapper function for add_library.
#
# This function aims as a wrapper for add_library. It will be used for two
# cases:
#
#   * add_library should be called for a static and sahred version. These calls
#     will be done by a single call to this wrapper function without a library
#     type defined.
#   * add_library should be called for OBJECT libraries. The wrapper will create
#     a static and shared version of the OBJECT library which may me linked to
#     other targets later.
#
# In any other case, this wrapper will ensure that the right object libraries
# will be selected for the target library.
#
function (easy_add_library NAME ...)
	# Remove NAME from ARGV to use ARGV as SOURCES.
	list(REMOVE_AT ARGV 0)

	# Check the library type. If no type is defined, a static and shared version
	# of the library will be added. The EXTRACT_FROM_ALL keyword does not need
	# to be checked, as it may be passed to add_library as a regular source
	# file.
	set(lib_types "SHARED" "STATIC")
	set(lib_postfix true)
	if (ARGV1 STREQUAL "STATIC" OR ARGV1 STREQUAL "SHARED"
	    OR ARGV1 STREQUAL "MODULE" OR ARGV1 STREQUAL "OBJECT")
		set(lib_types ${ARGV1})
		set(lib_postfix false)

		# Remove the library type from ARGV to use ARGV as SOURCES.
		list(REMOVE_AT ARGV 0)
	endif()


	# Generate lists of sources for the PiC and non-PiC targets. There will be
	# separate lists for source files, real existing object libraries and object
	# libraries depending on the type of library to be built.
	set(sources "")
	set(objects "")
	set(objects_pic "")
	set(link "")

	foreach (source IN LISTS ARGV)
		# Check if the source file is a relevant generator expression or a
		# source file.
		if (NOT source MATCHES "TARGET_OBJECTS:([^ >]+)")
			list(APPEND sources ${source})

		else ()
			# Check if there are targets for a PiC and a non-PiC version of the
			# object. If there are two matching targets, add the different
			# version to the list of PiC-dependent objects, otherwise the object
			# will be added to the sources list.
			string(REGEX REPLACE "[$]<TARGET_OBJECTS:([^ >]+)>" "\\1" tgt
			       ${source})
			if (TARGET "${tgt}" AND TARGET "${tgt}_pic")
				list(APPEND objects "$<TARGET_OBJECTS:${tgt}>")
				list(APPEND objects_pic "$<TARGET_OBJECTS:${tgt}_pic>")
			else ()
				list(APPEND sources ${source})
			endif ()

			# Append a generator expression to the link list. These expressions
			# will be used to link the target library to the libraries the
			# object library is linked against.
			list(APPEND link "$<TARGET_PROPERTY:${tgt},LINK_LIBRARIES>")
		endif ()
	endforeach ()


	foreach (type ${lib_types})
		# Add a PiC and a non-PiC version of the object library.
		if (type STREQUAL "OBJECT")
			add_library("${NAME}" OBJECT EXCLUDE_FROM_ALL ${sources} ${objects})

			add_library("${NAME}_pic" OBJECT EXCLUDE_FROM_ALL ${sources}
			            ${objects_pic})
			set_target_properties("${NAME}_pic" PROPERTIES
			                      POSITION_INDEPENDENT_CODE True)

		else ()
			# Generate the name for the targets, if no type was specified by
			# calling the wrapper.
			set(target_name ${NAME})
			if (lib_postfix)
				string(TOLOWER ${type} type_lower)
				set(target_name "${NAME}_${type_lower}")
			endif ()

			# Add the other library types.
			if (type STREQUAL "STATIC")
				add_library(${target_name} STATIC ${sources} ${objects})

			elseif (type STREQUAL "SHARED" OR type STREQUAL "MODULE")
				add_library(${target_name} ${type} ${sources} ${objects_pic})

				# Link the libraries to the object library linked libraries.
				target_link_libraries(${target_name} ${link})
			endif ()

			# Set the OUTPUT_NAME. Otherwise the libraries would be called
			# *_static.a and *_shared.so.
			set_target_properties(${target_name} PROPERTIES OUTPUT_NAME ${NAME})
		endif ()
	endforeach ()
endfunction ()


# Wrapper function for target_link_libraries.
#
# This function is a wrapper for the target_link_libraries function. It must be
# used to link libraries to OBJECT libraries, as target_link_libraries will
# throw an error message if you use it together with OBJECT libraries.
function (easy_target_link_libraries TARGET)
	# Remove NAME from ARGV to use ARGV as LIBRARIES.
	list(REMOVE_AT ARGV 0)

	# Append all arguments to the LINK_LIBRARIES property of the OBJECT library
	# which will be evaluated by the target library.
	set_property(TARGET ${TARGET} APPEND PROPERTY LINK_LIBRARIES ${ARGV})
endfunction ()
