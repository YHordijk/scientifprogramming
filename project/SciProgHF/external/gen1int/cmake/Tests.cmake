ADD_TEST(tools  ${CMAKE_SOURCE_DIR}/tools/runtest.sh -tools)
ADD_TEST(basic  ${CMAKE_SOURCE_DIR}/tools/runtest.sh -basic)
ADD_TEST(geo    ${CMAKE_SOURCE_DIR}/tools/runtest.sh -geo)
ADD_TEST(mag    ${CMAKE_SOURCE_DIR}/tools/runtest.sh -mag)
ADD_TEST(carmom ${CMAKE_SOURCE_DIR}/tools/runtest.sh -carmom)
ADD_TEST(delta  ${CMAKE_SOURCE_DIR}/tools/runtest.sh -delta)
ADD_TEST(nucpot ${CMAKE_SOURCE_DIR}/tools/runtest.sh -nucpot)
ADD_TEST(gaupot ${CMAKE_SOURCE_DIR}/tools/runtest.sh -gaupot)
ADD_TEST(odist  ${CMAKE_SOURCE_DIR}/tools/runtest.sh -odist)
ADD_TEST(f90mod ${CMAKE_SOURCE_DIR}/tools/runtest.sh -f90mod)