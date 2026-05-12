#pragma once

#ifdef __cplusplus
extern "C" {
#endif

bool iOSVM_Initialize(const char* isoPath);
void iOSVM_RunFrame(void);
void iOSVM_Shutdown(void);

#ifdef __cplusplus
}
#endif