# CMake-easylib

CMake module for easy library handling.



## Include into your project

To use [easylib.cmake](cmake/easylib.cmake), simply add this repository as git submodule into your own repository
```Shell
mkdir externals
git submodule add git://github.com/alehaa/CMake-easylib.git externals/CMake-easylib
```
and adding ```externals/CMake-easylib/cmake``` to your ```CMAKE_MODULE_PATH```
```CMake
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/externals/CMake-easylib/cmake" ${CMAKE_MODULE_PATH})
```

If you don't use git or dislike submodules you can copy the [[easylib.cmake](cmake/easylib.cmake)file into your repository. *Be careful when there are version updates of this repository!*


## Usage

[easylib.cmake](cmake/easylib.cmake) is a wrapper arround the CMake internal functions ```add_library``` and ```target_link_libraries```. To enable the wrapper, you have to include it into your project before you call ```add_library``` or ```target_link_libraries```. A good place for this is your root CMakeLists.txt file before you call ```add_subdirectory```.

After that ```add_library``` will behave like the following chart shows:

| function call  | description |
|---------|-------------|
|```add_library(TARGET <libtype> SOURCES)```|```add_library``` will behave as without CMake-easylib.|
|```add_library(TARGET SOURCES)```|```add_library``` will create a static target named ```${TARGET}_static``` and a second ```${TARGET}_shared``` for the shared library.|
|```add_library(TARGET OBJECT SOURCES)```|```add_library``` will create a static object library named ```${TARGET}``` and a second ```${TARGET}_pic``` with position independent code enabled for the shared libraries.|

If you'll use ```OBJECT``` libraries, the behavior will be changed as described below:

* ```add_library``` will create two ```OBJECT``` libraries with and without position independent code enabled.
* ```$<TARGET_OBJECTS:obj>``` will be expanded to ```$<TARGET_OBJECTS:obj_pic>``` for ```SHARED``` and ```MODULE``` libraries.


## Example

```CMake
# setup easylib
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/externals/CMake-easylib/cmake" ${CMAKE_MODULE_PATH})
include(easylib)

# add an object library
add_library(myobj OBJECT a.c b.c)


# add a static and shared library
add_library(mylib
	sample.c
	$<TARGET_OBJECTS:myobj>
)

# install both libraries
install(TARGETS mylib_static mylib_shared DESTINATION lib)
```


## Copyright

Copyright (c) 2015 [Alexander Haase](alexander.haase@rwth-aachen.de).

See the [LICENSE](LICENSE) file in the base directory for details.

All rights reserved.
