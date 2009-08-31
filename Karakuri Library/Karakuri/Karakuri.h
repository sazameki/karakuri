/*
 *  Karakuri.h
 *  Karakuri Prototype
 *
 *  Created by numata on 09/07/18.
 *  Copyright 2009 Satoshi Numata. All rights reserved.
 *
 */

#pragma once


#include <Karakuri/Karakuri_Defines.h>
#include <Karakuri/Karakuri_Types.h>
#include <Karakuri/KarakuriException.h>
#include <Karakuri/KarakuriString.h>
#include <Karakuri/KarakuriFunctions.h>

#if KR_MACOSX || KR_IPHONE_MACOSX_EMU
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>
#endif

#if KR_IPHONE && !KR_IPHONE_MACOSX_EMU
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#endif

#include <Karakuri/Karakuri_Globals.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <iostream>
#include <list>
#include <map>
#include <set>
#include <string>
#include <vector>

// Game Base Class
#include <Karakuri/KarakuriGame.h>

// Fundamental Classes
#include <Karakuri/KarakuriWorld.h>
#include <Karakuri/KRColor.h>
#include <Karakuri/KRGraphics.h>
#include <Karakuri/KRInput.h>
#include <Karakuri/KRRandom.h>

// Text Support Classes
#include <Karakuri/KRSaveBox.h>
#include <Karakuri/KRTextReader.h>

// Control Support Classes

#include <Karakuri/KRButton.h>
#include <Karakuri/KRLabel.h>
#include <Karakuri/KRSlider.h>
#include <Karakuri/KRSwitch.h>

// 2D Graphics Classes
#include <Karakuri/KRTexture2D.h>
#include <Karakuri/KRTexture2DAtlas.h>
#include <Karakuri/KRFont.h>
#include <Karakuri/KRParticle2D.h>
#include <Karakuri/KRPrimitive2D.h>

// Audio Playback Classes
#include <Karakuri/KRMusic.h>
#include <Karakuri/KRSound.h>

// Physical Simulation
#include <Karakuri/KRSimulator2D.h>
#include <Karakuri/KRSimulator3D.h>

// Network Classes
#include <Karakuri/KarakuriNetwork.h>


