# SOURCE FILES
set (SRC
  main.cpp 
  param_util.cpp param_util.h
)
# externals
libhandler_opencv ()
libhandler_eigen3 ()
libhandler_boost (COMPONENTS program_options system filesystem)
libhandler_glib ()

add_executable (exp_ctrl_1step ${SRC})
target_link_libraries (exp_ctrl_1step
  irp-imgeval++
  irp_gpgo++
  irp-common 
  ${IRPLIB_BOOST}
  ${IRAP_LCMTYPES}
  ${IRPLIB_LCM}
)

