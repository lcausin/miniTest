#pragma once

#include <ShSDK/ShSDK.h>
#include <ShEntryPoint/ShEntryPoint.h>

#include <Plugin/Plugin.h>

//
// Callbacks declaration
extern void	OnTouchDown				(int iTouch, float positionX, float positionY);
extern void	OnTouchUp				(int iTouch, float positionX, float positionY);
extern void	OnTouchMove				(int iTouch, float positionX, float positionY);

extern void OnLogin					(ShUser * pUser);
extern void OnLogout				(ShUser * pUser);
extern void OnUserChanged			(ShUser * pUser);
