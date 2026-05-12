#pragma once
// Registers a host callback so Console.WriteLn / DevCon / Log::Write
// messages from the PCSX2 core are forwarded to BionicLogger.
void PCSX2Log_Init();
