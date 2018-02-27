unit hDebugUtils;

interface

const
  { Special code constants }

  INT_3C : Byte = $CC;

  { Win32 OpenThread constants }

  THREAD_GET_CONTEXT       = $0008;
  THREAD_QUERY_INFORMATION = $0040;

  { Debug Win32 constants }

  CTX_FLAGS_SINGLE_STEP    = $0100;

implementation

end.
