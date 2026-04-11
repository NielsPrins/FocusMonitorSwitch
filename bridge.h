#pragma once

void         RunMainLoop(void);
unsigned int GetMouseDisplayID(void);
int          GetActiveAppPidOnDisplay(unsigned int display_id);
int          IsMouseButtonDown(void);
void         FocusAppByPid(int pid);
