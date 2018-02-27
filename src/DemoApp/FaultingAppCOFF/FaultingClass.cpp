#include "FaultingClass.h"

CFaultingClass::CFaultingClass()
{	
}

void CFaultingClass::Crash()
{
	LPDWORD lpError = NULL;
	*lpError        = 0;
}