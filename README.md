---------
Licensing
---------

Bug Finder
Copyright (C) 2008-2018  Antonio Petricca <antonio.petricca@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

------------
Introduction
------------

Bug Finder is a windows run-time debugger specialized to intercept and
decode exceptions, in particular Delphi exceptions in faulting processes for
which is difficult or impossible to trap errors in code.

As said above, sometimes is not possible to trap exceptions in code due to the
fact that some of them cause the dead of the process. In this situation is
absolutely necessary to debug the process to get the faulting condition, but in
a production, or pre-production, environment is not possible.

The Bug Finder will solve the problem.

For Delphi applications compiled with a detailed debug map files it will get
also information about the location of the exceptions in the source code.

----------------
More information
----------------

Please read the file "docs/ReadMe.txt" and other text documents.

The past complete history can be found at https://sourceforge.net/projects/exccatch/
now discontinued and archived on GitHub.

