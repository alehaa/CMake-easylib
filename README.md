# CMake-easylib

CMake module for easy library handling.


## About

Ẃith `add_library` you have the possibility to structure your project with `OBJECT` libraries, but using these is not very comfortable, especially when building static and shared versions of the same library: Then you have to add different targets vor the static and shared versions for the libraries and all of the used submodules. A second problem is, that libraries can't be linked to the object libraries but have to be linked to the target library.

The easylib interface provides wrappers for `add_library` and `target_link_libraries` to make the use for these special szenarios comfortable. They will ensure that `OBJECT` libraries will be built for static and shared target libraries and libraries linked to the `OBJECT` libraries will be linked to the target library automatically.

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

If you don't use git or dislike submodules you can copy the [easylib.cmake](cmake/easylib.cmake) file into your repository. *Be careful when there are version updates of this repository!*


## Usage

Using easylib is just as easy as using the CMake functions `add_library` and `target_link_libraries`:

Whenerver you use `add_library` for `OBJECT` libraries or the `TARGET_OBJECTS` generator expressions, simply replace `add_library` with `easy_add_library`. `easy_add_library` will ensure that static libraries use the non-PiC objects and shared libraries or modules use the PiC versions:
```diff
-add_library(object OBJECT a.c)
-add_library(object_pic OBJECT a.c)
-set_target_properties(object_pic PROPERTIES POSITION_INDEPENDENT_CODE True)
+easy_add_library(object OBJECT a.c)

-add_library(test STATIC b.c $<TARGET_OBJECTS:object>)
-add_library(test_shared SHARED b.c $<TARGET_OBJECTS:object_pic>)
-set_target_properties(test_shared PROPERTIES OUTPUT_NAME test)
+easy_add_library(test b.c $<TARGET_OBJECTS:object>)
```

The `target_link_libraries` can't be used with `OBJECT` libraries. Instead you may use `easy_target_link_libraries` to define dependencies of your objects to be linked to the target shared library:

```diff
 easy_add_library(object OBJECT a.c)
+easy_target_link_libraries(object curl)

 easy_add_library(test SHARED b.c $<TARGET_OBJECTS:object>)
-target_link_libraries(test curl)
```

#### Order of target definitions

To use the easylib interface, it is essential to take care about the order of defining `OBJECT` libraries. You have to add the `OBJECT` libraries __before__ using them in another target. Otherwise `easy_add_library` will not know about the automatically generated PiC and non-PiC versions of the `OBJECT`-library and will link the wrong (non-PiC) version to shared libraries (which will result in a compile error).


#### Commands on targets

If you use other commands like `add_coverage` from [CMake-codecov](https://github.com/RWTH-ELP/CMake-codecov) or `add_sanitizers` from [sanitizers-cmake](https://github.com/arsenm/sanitizers-cmake), you have to call them on the right targets:

* For `STATIC`, `SHARED` and `MODULE` libraries call them as before for your target.
* For `OBJECT` libraries you have to call them on `TARGET` and `TARGET_pic`.
* For no library type (a static and a shared version will be built) you have to call them on `TARGET_static` and `TARGET_shared`.


## Contribute

Anyone is welcome to contribute. Simply fork this repository, make your changes **in an own branch** and create a pull-request for your change. Please do only one change per pull-request.

You found a bug? Please fill out an issue and include any data to reproduce the bug.

#### Contributors

[Alexander Haase](https://github.com/alehaa)


## Copyright

Copyright (c) 2015-2016 [Alexander Haase](alexander.haase@rwth-aachen.de).

See the [LICENSE](LICENSE) file in the base directory for details.

All rights reserved.
