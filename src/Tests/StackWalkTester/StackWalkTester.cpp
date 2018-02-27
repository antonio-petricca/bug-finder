// StackWalkTester.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

void StackWalkMethod(LPSTACKFRAME lpFrame)
{
	// Walk the stack

	while (StackWalk(
		IMAGE_FILE_MACHINE_I386,
		GetCurrentProcess(),
		GetCurrentThread(),
		lpFrame,
		NULL,
		NULL,
		&SymFunctionTableAccess,
		&SymGetModuleBase,
		NULL
	))
	{
		printf("Address: 0x%.08x\n", lpFrame->AddrPC.Offset);
	}

}

void StackWalkBridgeMethod(LPSTACKFRAME lpFrame)
{
	StackWalkMethod(lpFrame);
}

int _tmain(int argc, _TCHAR* argv[])
{
	// Get current thread context 

	CONTEXT Ctx;
	
	Ctx.ContextFlags = CONTEXT_FULL;
	GetThreadContext(GetCurrentThread(), &Ctx);

	// Init stack frame

	STACKFRAME Frame;
	
	memset(&Frame, 0, sizeof(STACKFRAME));
	Frame.AddrPC.Offset    = Ctx.Eip;
	Frame.AddrPC.Mode      = AddrModeFlat;
	Frame.AddrStack.Offset = Ctx.Esp;
    Frame.AddrStack.Mode   = AddrModeFlat;
    Frame.AddrFrame.Offset = Ctx.Ebp;
    Frame.AddrFrame.Mode   = AddrModeFlat;

	// Invoke stack walker

	StackWalkBridgeMethod(&Frame);

	return 0;
}

