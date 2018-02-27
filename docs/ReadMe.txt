------------------
0. Date of writing
------------------

Rome, July 5th 2013

----------------------------
1. Brief project description
----------------------------

Bug Finder is a windows run-time debugger specialized to intercept and 
decode exceptions, in particular Delphi exceptions in faulting processes for 
which is difficult or impossible to trap errors in code.

As said above, sometimes is not possible to trap exceptions in code due to the 
fact that some of them cause the dead of the process. In this situation is 
absolutely necessary to debug the process to get the faulting condition, but in 
a production, or pre-production, environment is not possible.

The Bug Finder will solve the problem.

For Delphi applications compiled with a detailed debug map files it will get 
also informations about the location of the exceptions in the source code.

----------
2. License
----------

The Bug Finder is absolutely free under the terms of the GPL license.

------------------
3. Project support
------------------

Please send any comment or suggestion by email at:

  antonio.petricca@gmail.com
  
--------------  
4. Compilation
--------------

Use Delphi 5.0 or above.

---------------
5. Dependencies
---------------

 - Microsoft Windows 9x, NT, 2000, XP
 - Delphi Jedi VCL library (partially distributed with this project) 
 - LMD Controls
 - MIcrosoft .NET Framework 2.0 or above
 - PSAPI.DLL
 - DBGHELP.DLL
  
----------------  
6. How to use it
----------------

Please follow these simple steps to setup and use the bug finder:

 1) Compile your executable with the "Detailed map file" option enabled. Repeat 
    this step, if you need it, for each DLL module you want to monitor.

 2) Write an INI file containing the file name to debug and few other options. 
    If you don't pass its name to the command line of the executable the 
    BugFinder will search for the file "BugFinder.ini".
    
 3) If you need them, place any you want tracing breakpoint to get informed
    about interesting method calls.
    
 4) Run the Bug Finder passing it the INI file name.
 
 5) Click on the bug try icon to see the log. If you specified the "SpoolerToFile" 
    option in the INIfile you'll get a detailed exception log file 
    named BugFinder.log.
    
--------    
7. Notes    
--------

This release in an alpha version, please send me report about any bug, problem or 
suggestion (antonio.petricca@gmail.com).

Thank you,

Antonio Petricca