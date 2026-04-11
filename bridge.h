#pragma once

void         RunMainLoop(void);
unsigned int GetMouseDisplayID(void);
int          GetActiveAppPidOnDisplay(unsigned int display_id);
void         FocusAppByPid(int pid);
