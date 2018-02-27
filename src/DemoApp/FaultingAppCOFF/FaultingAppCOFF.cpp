#include <windows.h>
#include "FaultingClass.h"

void InternalRunException()
{
	LPDWORD lpError = NULL;
	*lpError        = 0;	
}

void _stdcall RaiseExceptionFromCoffDll()
{
	InternalRunException();
}

void _stdcall RaiseExceptionFromCoffDllByClass()
{
	
	CFaultingClass *cFaulting = new CFaultingClass();
	cFaulting->Crash();
	delete cFaulting;
}