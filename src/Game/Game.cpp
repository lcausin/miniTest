#include "Game.h"

ShUser * g_pUser		= shNULL;

float g_fGlobalTime = 0.0f;
float g_fCameraSpeed = 20.0f;	// 10.0f -> normal | 100.0f -> High speed
float fTime = 0.0f;


/**
 * Called to initialize DisplayProperties
 */
void ShEntryPoint::SetupDisplayProperties(bool & bLandscape, bool & bEnable3D, bool & bEnableZ, bool & bUseSpecular, bool & bUsePointLights, bool & bUseShadow, int & width, int & height)
{
	bLandscape		= false;
	bEnable3D		= true;
	bEnableZ		= true;
	bUseSpecular	= false;
	bUsePointLights	= true;
	bUseShadow		= true;
	width			= 1280;
	height			= 720;
}
/**
 * Called before engine initialization
 */
void ShEntryPoint::OnPreInitialize(void)
{

}

/**
 * Called after engine initialization
 */
void ShEntryPoint::OnPostInitialize(void)
{
	Plugin * pPlugin = new Plugin();
	ShApplication::RegisterPlugin(pPlugin);
	
	ShGUI::LoadGUIAndSSS(CShIdentifier("gui"), ShGUI::GetRootControl());
}

/**
 * Called on each frame, before the engine update
 */
void ShEntryPoint::OnPreUpdate(float dt)
{
	SH_UNUSED(dt);
}

/**
 * Called on each frame, after the engine update
 */
void ShEntryPoint::OnPostUpdate(float dt)
{
	SH_UNUSED(dt);
}

/**
 * Called before the engine release
 */
void ShEntryPoint::OnPreRelease(void)
{
	// nothing here
}

/**
 * Called after the engine release
 */
void ShEntryPoint::OnPostRelease(void)
{
	// nothing here
}
