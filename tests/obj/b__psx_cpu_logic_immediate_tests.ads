pragma Warnings (Off);
pragma Ada_95;
with System;
with System.Parameters;
with System.Secondary_Stack;
package ada_main is

   gnat_argc : Integer;
   gnat_argv : System.Address;
   gnat_envp : System.Address;

   pragma Import (C, gnat_argc);
   pragma Import (C, gnat_argv);
   pragma Import (C, gnat_envp);

   gnat_exit_status : Integer;
   pragma Import (C, gnat_exit_status);

   GNAT_Version : constant String :=
                    "GNAT Version: 16.1.0" & ASCII.NUL;
   pragma Export (C, GNAT_Version, "__gnat_version");

   GNAT_Version_Address : constant System.Address := GNAT_Version'Address;
   pragma Export (C, GNAT_Version_Address, "__gnat_version_address");

   Ada_Main_Program_Name : constant String := "_ada_psx_cpu_logic_immediate_tests" & ASCII.NUL;
   pragma Export (C, Ada_Main_Program_Name, "__gnat_ada_main_program_name");

   procedure adainit;
   pragma Export (C, adainit, "adainit");

   procedure adafinal;
   pragma Export (C, adafinal, "adafinal");

   function main
     (argc : Integer;
      argv : System.Address;
      envp : System.Address)
      return Integer;
   pragma Export (C, main, "main");

   type Version_32 is mod 2 ** 32;
   u00001 : constant Version_32 := 16#1d837535#;
   pragma Export (C, u00001, "psx_cpu_logic_immediate_testsB");
   u00002 : constant Version_32 := 16#b2cfab41#;
   pragma Export (C, u00002, "system__standard_libraryB");
   u00003 : constant Version_32 := 16#986fbd5a#;
   pragma Export (C, u00003, "system__standard_libraryS");
   u00004 : constant Version_32 := 16#76789da1#;
   pragma Export (C, u00004, "adaS");
   u00005 : constant Version_32 := 16#a201b8c5#;
   pragma Export (C, u00005, "ada__strings__text_buffersB");
   u00006 : constant Version_32 := 16#a7cfd09b#;
   pragma Export (C, u00006, "ada__strings__text_buffersS");
   u00007 : constant Version_32 := 16#e6d4fa36#;
   pragma Export (C, u00007, "ada__stringsS");
   u00008 : constant Version_32 := 16#8a611ac3#;
   pragma Export (C, u00008, "systemS");
   u00009 : constant Version_32 := 16#45e1965e#;
   pragma Export (C, u00009, "system__exception_tableB");
   u00010 : constant Version_32 := 16#074a6cda#;
   pragma Export (C, u00010, "system__exception_tableS");
   u00011 : constant Version_32 := 16#7fa0a598#;
   pragma Export (C, u00011, "system__soft_linksB");
   u00012 : constant Version_32 := 16#acdd2381#;
   pragma Export (C, u00012, "system__soft_linksS");
   u00013 : constant Version_32 := 16#33935a56#;
   pragma Export (C, u00013, "system__secondary_stackB");
   u00014 : constant Version_32 := 16#b0931c82#;
   pragma Export (C, u00014, "system__secondary_stackS");
   u00015 : constant Version_32 := 16#6ce3be0f#;
   pragma Export (C, u00015, "ada__exceptionsB");
   u00016 : constant Version_32 := 16#0fa7c4bb#;
   pragma Export (C, u00016, "ada__exceptionsS");
   u00017 : constant Version_32 := 16#85bf25f7#;
   pragma Export (C, u00017, "ada__exceptions__last_chance_handlerB");
   u00018 : constant Version_32 := 16#c1262c0b#;
   pragma Export (C, u00018, "ada__exceptions__last_chance_handlerS");
   u00019 : constant Version_32 := 16#b8c4a5f1#;
   pragma Export (C, u00019, "system__exceptionsS");
   u00020 : constant Version_32 := 16#c367aa24#;
   pragma Export (C, u00020, "system__exceptions__machineB");
   u00021 : constant Version_32 := 16#8d1d496c#;
   pragma Export (C, u00021, "system__exceptions__machineS");
   u00022 : constant Version_32 := 16#2f7ce883#;
   pragma Export (C, u00022, "system__exceptions_debugB");
   u00023 : constant Version_32 := 16#ba6f4290#;
   pragma Export (C, u00023, "system__exceptions_debugS");
   u00024 : constant Version_32 := 16#1d4109f1#;
   pragma Export (C, u00024, "system__img_intS");
   u00025 : constant Version_32 := 16#46bfce2b#;
   pragma Export (C, u00025, "system__storage_elementsS");
   u00026 : constant Version_32 := 16#5c7d9c20#;
   pragma Export (C, u00026, "system__tracebackB");
   u00027 : constant Version_32 := 16#0cfbee7e#;
   pragma Export (C, u00027, "system__tracebackS");
   u00028 : constant Version_32 := 16#5f6b6486#;
   pragma Export (C, u00028, "system__traceback_entriesB");
   u00029 : constant Version_32 := 16#427da54f#;
   pragma Export (C, u00029, "system__traceback_entriesS");
   u00030 : constant Version_32 := 16#727e0fa1#;
   pragma Export (C, u00030, "system__traceback__symbolicB");
   u00031 : constant Version_32 := 16#3e2e1203#;
   pragma Export (C, u00031, "system__traceback__symbolicS");
   u00032 : constant Version_32 := 16#701f9d88#;
   pragma Export (C, u00032, "ada__exceptions__tracebackB");
   u00033 : constant Version_32 := 16#47e3d2a3#;
   pragma Export (C, u00033, "ada__exceptions__tracebackS");
   u00034 : constant Version_32 := 16#f9910acc#;
   pragma Export (C, u00034, "system__address_imageB");
   u00035 : constant Version_32 := 16#2b8d87f9#;
   pragma Export (C, u00035, "system__address_imageS");
   u00036 : constant Version_32 := 16#bfdff066#;
   pragma Export (C, u00036, "system__img_address_32S");
   u00037 : constant Version_32 := 16#9111f9c1#;
   pragma Export (C, u00037, "interfacesS");
   u00038 : constant Version_32 := 16#92ff51e4#;
   pragma Export (C, u00038, "system__img_address_64S");
   u00039 : constant Version_32 := 16#fd158a37#;
   pragma Export (C, u00039, "system__wch_conB");
   u00040 : constant Version_32 := 16#536239a0#;
   pragma Export (C, u00040, "system__wch_conS");
   u00041 : constant Version_32 := 16#5c289972#;
   pragma Export (C, u00041, "system__wch_stwB");
   u00042 : constant Version_32 := 16#7e7315a1#;
   pragma Export (C, u00042, "system__wch_stwS");
   u00043 : constant Version_32 := 16#7cd63de5#;
   pragma Export (C, u00043, "system__wch_cnvB");
   u00044 : constant Version_32 := 16#55a2f3d0#;
   pragma Export (C, u00044, "system__wch_cnvS");
   u00045 : constant Version_32 := 16#e538de43#;
   pragma Export (C, u00045, "system__wch_jisB");
   u00046 : constant Version_32 := 16#e01591fa#;
   pragma Export (C, u00046, "system__wch_jisS");
   u00047 : constant Version_32 := 16#3007a9ef#;
   pragma Export (C, u00047, "system__parametersB");
   u00048 : constant Version_32 := 16#2bcfb19f#;
   pragma Export (C, u00048, "system__parametersS");
   u00049 : constant Version_32 := 16#0286ce9f#;
   pragma Export (C, u00049, "system__soft_links__initializeB");
   u00050 : constant Version_32 := 16#ac2e8b53#;
   pragma Export (C, u00050, "system__soft_links__initializeS");
   u00051 : constant Version_32 := 16#8599b27b#;
   pragma Export (C, u00051, "system__stack_checkingB");
   u00052 : constant Version_32 := 16#4d3e0fd5#;
   pragma Export (C, u00052, "system__stack_checkingS");
   u00053 : constant Version_32 := 16#8b7604c4#;
   pragma Export (C, u00053, "ada__strings__utf_encodingB");
   u00054 : constant Version_32 := 16#c9e86997#;
   pragma Export (C, u00054, "ada__strings__utf_encodingS");
   u00055 : constant Version_32 := 16#bb780f45#;
   pragma Export (C, u00055, "ada__strings__utf_encoding__stringsB");
   u00056 : constant Version_32 := 16#b85ff4b6#;
   pragma Export (C, u00056, "ada__strings__utf_encoding__stringsS");
   u00057 : constant Version_32 := 16#d1d1ed0b#;
   pragma Export (C, u00057, "ada__strings__utf_encoding__wide_stringsB");
   u00058 : constant Version_32 := 16#5678478f#;
   pragma Export (C, u00058, "ada__strings__utf_encoding__wide_stringsS");
   u00059 : constant Version_32 := 16#c2b98963#;
   pragma Export (C, u00059, "ada__strings__utf_encoding__wide_wide_stringsB");
   u00060 : constant Version_32 := 16#d7af3358#;
   pragma Export (C, u00060, "ada__strings__utf_encoding__wide_wide_stringsS");
   u00061 : constant Version_32 := 16#df45aed8#;
   pragma Export (C, u00061, "ada__tagsB");
   u00062 : constant Version_32 := 16#99822aba#;
   pragma Export (C, u00062, "ada__tagsS");
   u00063 : constant Version_32 := 16#3548d972#;
   pragma Export (C, u00063, "system__htableB");
   u00064 : constant Version_32 := 16#0bb84228#;
   pragma Export (C, u00064, "system__htableS");
   u00065 : constant Version_32 := 16#1f1abe38#;
   pragma Export (C, u00065, "system__string_hashB");
   u00066 : constant Version_32 := 16#acfdc257#;
   pragma Export (C, u00066, "system__string_hashS");
   u00067 : constant Version_32 := 16#704b659a#;
   pragma Export (C, u00067, "system__unsigned_typesS");
   u00068 : constant Version_32 := 16#159aaf05#;
   pragma Export (C, u00068, "system__val_lluS");
   u00069 : constant Version_32 := 16#0d1904b9#;
   pragma Export (C, u00069, "system__val_utilB");
   u00070 : constant Version_32 := 16#66caf8e0#;
   pragma Export (C, u00070, "system__val_utilS");
   u00071 : constant Version_32 := 16#8b956324#;
   pragma Export (C, u00071, "system__case_util_nssB");
   u00072 : constant Version_32 := 16#ef0e9ee9#;
   pragma Export (C, u00072, "system__case_util_nssS");
   u00073 : constant Version_32 := 16#c7620b41#;
   pragma Export (C, u00073, "ada__text_ioB");
   u00074 : constant Version_32 := 16#46a4a696#;
   pragma Export (C, u00074, "ada__text_ioS");
   u00075 : constant Version_32 := 16#6e6e3f5b#;
   pragma Export (C, u00075, "ada__streamsB");
   u00076 : constant Version_32 := 16#bd793559#;
   pragma Export (C, u00076, "ada__streamsS");
   u00077 : constant Version_32 := 16#367911c4#;
   pragma Export (C, u00077, "ada__io_exceptionsS");
   u00078 : constant Version_32 := 16#44f765f3#;
   pragma Export (C, u00078, "system__put_imagesB");
   u00079 : constant Version_32 := 16#9a7e9601#;
   pragma Export (C, u00079, "system__put_imagesS");
   u00080 : constant Version_32 := 16#22b9eb9f#;
   pragma Export (C, u00080, "ada__strings__text_buffers__utilsB");
   u00081 : constant Version_32 := 16#89062ac3#;
   pragma Export (C, u00081, "ada__strings__text_buffers__utilsS");
   u00082 : constant Version_32 := 16#1cacf006#;
   pragma Export (C, u00082, "interfaces__c_streamsB");
   u00083 : constant Version_32 := 16#ecfa876a#;
   pragma Export (C, u00083, "interfaces__c_streamsS");
   u00084 : constant Version_32 := 16#22b1fb99#;
   pragma Export (C, u00084, "system__crtlB");
   u00085 : constant Version_32 := 16#a9f4d4a9#;
   pragma Export (C, u00085, "system__crtlS");
   u00086 : constant Version_32 := 16#a94e7662#;
   pragma Export (C, u00086, "system__file_ioB");
   u00087 : constant Version_32 := 16#ec2e4f85#;
   pragma Export (C, u00087, "system__file_ioS");
   u00088 : constant Version_32 := 16#7598b591#;
   pragma Export (C, u00088, "ada__finalizationS");
   u00089 : constant Version_32 := 16#d00f339c#;
   pragma Export (C, u00089, "system__finalization_rootB");
   u00090 : constant Version_32 := 16#801d2417#;
   pragma Export (C, u00090, "system__finalization_rootS");
   u00091 : constant Version_32 := 16#14fb286b#;
   pragma Export (C, u00091, "system__case_utilB");
   u00092 : constant Version_32 := 16#5499fba9#;
   pragma Export (C, u00092, "system__case_utilS");
   u00093 : constant Version_32 := 16#8e328749#;
   pragma Export (C, u00093, "system__finalization_primitivesB");
   u00094 : constant Version_32 := 16#a30892a3#;
   pragma Export (C, u00094, "system__finalization_primitivesS");
   u00095 : constant Version_32 := 16#afd63177#;
   pragma Export (C, u00095, "system__os_locksS");
   u00096 : constant Version_32 := 16#b9ada65a#;
   pragma Export (C, u00096, "interfaces__cB");
   u00097 : constant Version_32 := 16#610373b9#;
   pragma Export (C, u00097, "interfaces__cS");
   u00098 : constant Version_32 := 16#1311b8a5#;
   pragma Export (C, u00098, "system__os_constantsS");
   u00099 : constant Version_32 := 16#861c956a#;
   pragma Export (C, u00099, "system__os_libB");
   u00100 : constant Version_32 := 16#b4b4641d#;
   pragma Export (C, u00100, "system__os_libS");
   u00101 : constant Version_32 := 16#94d23d25#;
   pragma Export (C, u00101, "system__atomic_operations__test_and_setB");
   u00102 : constant Version_32 := 16#57acee8e#;
   pragma Export (C, u00102, "system__atomic_operations__test_and_setS");
   u00103 : constant Version_32 := 16#4d0260e6#;
   pragma Export (C, u00103, "system__atomic_operationsS");
   u00104 : constant Version_32 := 16#553a519e#;
   pragma Export (C, u00104, "system__atomic_primitivesB");
   u00105 : constant Version_32 := 16#b0203cad#;
   pragma Export (C, u00105, "system__atomic_primitivesS");
   u00106 : constant Version_32 := 16#256dbbe5#;
   pragma Export (C, u00106, "system__stringsB");
   u00107 : constant Version_32 := 16#11e31adb#;
   pragma Export (C, u00107, "system__stringsS");
   u00108 : constant Version_32 := 16#e0daad44#;
   pragma Export (C, u00108, "system__file_control_blockS");
   u00109 : constant Version_32 := 16#6f0a212e#;
   pragma Export (C, u00109, "psxS");
   u00110 : constant Version_32 := 16#2350623f#;
   pragma Export (C, u00110, "psx__cpuB");
   u00111 : constant Version_32 := 16#d4861e94#;
   pragma Export (C, u00111, "psx__cpuS");
   u00112 : constant Version_32 := 16#a7740a83#;
   pragma Export (C, u00112, "psx__registerB");
   u00113 : constant Version_32 := 16#da6a830e#;
   pragma Export (C, u00113, "psx__registerS");
   u00114 : constant Version_32 := 16#06249ef3#;
   pragma Export (C, u00114, "psx__typesS");
   u00115 : constant Version_32 := 16#413a85e2#;
   pragma Export (C, u00115, "psx__cpu__stepB");
   u00116 : constant Version_32 := 16#5380f4ad#;
   pragma Export (C, u00116, "psx__cpu__stepS");
   u00117 : constant Version_32 := 16#f8bbf887#;
   pragma Export (C, u00117, "psx__cpu__cyclesB");
   u00118 : constant Version_32 := 16#cb6afad2#;
   pragma Export (C, u00118, "psx__cpu__cyclesS");
   u00119 : constant Version_32 := 16#e0adb4c5#;
   pragma Export (C, u00119, "psx__cpu__instructionB");
   u00120 : constant Version_32 := 16#539b7d3d#;
   pragma Export (C, u00120, "psx__cpu__instructionS");
   u00121 : constant Version_32 := 16#8329383b#;
   pragma Export (C, u00121, "psx__cpu__executeB");
   u00122 : constant Version_32 := 16#77967831#;
   pragma Export (C, u00122, "psx__cpu__executeS");
   u00123 : constant Version_32 := 16#15835e9a#;
   pragma Export (C, u00123, "psx__cpu__muldivB");
   u00124 : constant Version_32 := 16#de939a6a#;
   pragma Export (C, u00124, "psx__cpu__muldivS");
   u00125 : constant Version_32 := 16#e73f30c3#;
   pragma Export (C, u00125, "psx__memoryB");
   u00126 : constant Version_32 := 16#32abde0f#;
   pragma Export (C, u00126, "psx__memoryS");
   u00127 : constant Version_32 := 16#45bfb273#;
   pragma Export (C, u00127, "ada__streams__stream_ioB");
   u00128 : constant Version_32 := 16#44ae819b#;
   pragma Export (C, u00128, "ada__streams__stream_ioS");
   u00129 : constant Version_32 := 16#5de653db#;
   pragma Export (C, u00129, "system__communicationB");
   u00130 : constant Version_32 := 16#c51bd61d#;
   pragma Export (C, u00130, "system__communicationS");
   u00131 : constant Version_32 := 16#5bdae43b#;
   pragma Export (C, u00131, "psx__timersB");
   u00132 : constant Version_32 := 16#ab19291a#;
   pragma Export (C, u00132, "psx__timersS");
   u00133 : constant Version_32 := 16#79ef05bb#;
   pragma Export (C, u00133, "psx__memory__cyclesB");
   u00134 : constant Version_32 := 16#1c223a08#;
   pragma Export (C, u00134, "psx__memory__cyclesS");
   u00135 : constant Version_32 := 16#a5ba3250#;
   pragma Export (C, u00135, "psx__cpu__fetchB");
   u00136 : constant Version_32 := 16#27253c6e#;
   pragma Export (C, u00136, "psx__cpu__fetchS");
   u00137 : constant Version_32 := 16#19be13e8#;
   pragma Export (C, u00137, "psx__dmaB");
   u00138 : constant Version_32 := 16#f631ce1c#;
   pragma Export (C, u00138, "psx__dmaS");
   u00139 : constant Version_32 := 16#957a60cd#;
   pragma Export (C, u00139, "psx__gpuB");
   u00140 : constant Version_32 := 16#cd1b16df#;
   pragma Export (C, u00140, "psx__gpuS");
   u00141 : constant Version_32 := 16#a56a70fa#;
   pragma Export (C, u00141, "system__memoryB");
   u00142 : constant Version_32 := 16#92f586d9#;
   pragma Export (C, u00142, "system__memoryS");

   --  BEGIN ELABORATION ORDER
   --  ada%s
   --  interfaces%s
   --  system%s
   --  system.atomic_operations%s
   --  system.case_util_nss%s
   --  system.case_util_nss%b
   --  system.parameters%s
   --  system.parameters%b
   --  system.crtl%s
   --  system.crtl%b
   --  interfaces.c_streams%s
   --  interfaces.c_streams%b
   --  system.storage_elements%s
   --  system.img_address_32%s
   --  system.img_address_64%s
   --  system.stack_checking%s
   --  system.stack_checking%b
   --  system.string_hash%s
   --  system.string_hash%b
   --  system.htable%s
   --  system.htable%b
   --  system.strings%s
   --  system.strings%b
   --  system.traceback_entries%s
   --  system.traceback_entries%b
   --  system.unsigned_types%s
   --  system.wch_con%s
   --  system.wch_con%b
   --  system.wch_jis%s
   --  system.wch_jis%b
   --  system.wch_cnv%s
   --  system.wch_cnv%b
   --  system.img_int%s
   --  system.traceback%s
   --  system.traceback%b
   --  system.secondary_stack%s
   --  system.standard_library%s
   --  ada.exceptions%s
   --  system.exceptions_debug%s
   --  system.exceptions_debug%b
   --  system.soft_links%s
   --  system.wch_stw%s
   --  system.wch_stw%b
   --  ada.exceptions.last_chance_handler%s
   --  ada.exceptions.last_chance_handler%b
   --  ada.exceptions.traceback%s
   --  ada.exceptions.traceback%b
   --  system.address_image%s
   --  system.address_image%b
   --  system.exception_table%s
   --  system.exception_table%b
   --  system.exceptions%s
   --  system.exceptions.machine%s
   --  system.exceptions.machine%b
   --  system.memory%s
   --  system.memory%b
   --  system.secondary_stack%b
   --  system.soft_links.initialize%s
   --  system.soft_links.initialize%b
   --  system.soft_links%b
   --  system.standard_library%b
   --  system.traceback.symbolic%s
   --  system.traceback.symbolic%b
   --  ada.exceptions%b
   --  ada.io_exceptions%s
   --  ada.strings%s
   --  ada.strings.utf_encoding%s
   --  ada.strings.utf_encoding%b
   --  ada.strings.utf_encoding.strings%s
   --  ada.strings.utf_encoding.strings%b
   --  ada.strings.utf_encoding.wide_strings%s
   --  ada.strings.utf_encoding.wide_strings%b
   --  ada.strings.utf_encoding.wide_wide_strings%s
   --  ada.strings.utf_encoding.wide_wide_strings%b
   --  interfaces.c%s
   --  interfaces.c%b
   --  system.atomic_primitives%s
   --  system.atomic_primitives%b
   --  system.atomic_operations.test_and_set%s
   --  system.atomic_operations.test_and_set%b
   --  system.case_util%s
   --  system.case_util%b
   --  system.os_constants%s
   --  system.os_lib%s
   --  system.os_lib%b
   --  system.os_locks%s
   --  system.finalization_primitives%s
   --  system.finalization_primitives%b
   --  system.val_util%s
   --  system.val_util%b
   --  system.val_llu%s
   --  ada.tags%s
   --  ada.tags%b
   --  ada.strings.text_buffers%s
   --  ada.strings.text_buffers%b
   --  ada.strings.text_buffers.utils%s
   --  ada.strings.text_buffers.utils%b
   --  system.put_images%s
   --  system.put_images%b
   --  ada.streams%s
   --  ada.streams%b
   --  system.communication%s
   --  system.communication%b
   --  system.file_control_block%s
   --  system.finalization_root%s
   --  system.finalization_root%b
   --  ada.finalization%s
   --  system.file_io%s
   --  system.file_io%b
   --  ada.streams.stream_io%s
   --  ada.streams.stream_io%b
   --  ada.text_io%s
   --  ada.text_io%b
   --  psx%s
   --  psx.types%s
   --  psx.gpu%s
   --  psx.gpu%b
   --  psx.register%s
   --  psx.register%b
   --  psx.cpu%s
   --  psx.cpu%b
   --  psx.cpu.instruction%s
   --  psx.cpu.instruction%b
   --  psx.cpu.cycles%s
   --  psx.cpu.cycles%b
   --  psx.cpu.muldiv%s
   --  psx.cpu.muldiv%b
   --  psx.timers%s
   --  psx.timers%b
   --  psx.memory%s
   --  psx.memory%b
   --  psx.cpu.fetch%s
   --  psx.cpu.fetch%b
   --  psx.dma%s
   --  psx.dma%b
   --  psx.memory.cycles%s
   --  psx.memory.cycles%b
   --  psx.cpu.execute%s
   --  psx.cpu.execute%b
   --  psx.cpu.step%s
   --  psx.cpu.step%b
   --  psx_cpu_logic_immediate_tests%b
   --  END ELABORATION ORDER

end ada_main;
