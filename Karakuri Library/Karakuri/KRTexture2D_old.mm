/*
 *  KRTexture2D_old.mm
 *  Karakuri Library
 *
 *  Created by numata on 10/09/20.
 *  Copyright 2010 Satoshi Numata. All rights reserved.
 *
 */

#include "KRTexture2D_old.h"
#include "KRTexture2D.h"
#include "KRTexture2DLoader.h"
#include "KRFont.h"
#include "KRColor.h"
#include "KRPNGLoader.h"
#include "KRTexture2DAtlas.h"
#include "KarakuriGlobals.h"


#pragma mark Constructor / Destructor

KRTexture2D::KRTexture2D(const std::string& filename, KRTexture2DScaleMode scaleMode)
{
    if (_gKRTexture2DBatchCount > 0) {
        _KRTexture2D::processBatchedTexture2DDraws();
    }
    
    mAtlasSize = KRVector2DZero;
    mAtlas = NULL;
    mAtlasDiv = KRVector2DInt(1, 1);
    mIsAtlasFlipped = false;
    mTextureTarget = GL_TEXTURE_2D;

    mFileName = filename;
    NSString* filenameStr = [[NSString alloc] initWithCString:filename.c_str() encoding:NSUTF8StringEncoding];
    mTextureName = KRCreateGLTextureFromImageWithName(filenameStr, &mImageSize, &mTextureSize, (scaleMode==KRTexture2DScaleModeLinear)? YES: NO);
    [filenameStr release];

    if (mTextureName == GL_INVALID_VALUE || mTextureName == GL_INVALID_OPERATION) {
        const char* errorFormat = "Failed to load \"%s\". Please confirm that the image file exists.";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "\"%s\" の読み込みに失敗しました。画像ファイルが存在することを確認してください。";
        }
        throw KRRuntimeError(errorFormat, filename.c_str());
    }

    _KRTexture2DName = GL_INVALID_VALUE;
}

KRTexture2D::KRTexture2D(const std::string& filename, const KRVector2D& atlasSize)
{
    if (_gKRTexture2DBatchCount > 0) {
        _KRTexture2D::processBatchedTexture2DDraws();
    }

    mAtlas = NULL;
    mAtlasDiv = KRVector2DInt(1, 1);
    mIsAtlasFlipped = false;
    mTextureTarget = GL_TEXTURE_2D;

    mFileName = filename;
    NSString* filenameStr = [[NSString alloc] initWithCString:filename.c_str() encoding:NSUTF8StringEncoding];
    mTextureName = KRCreateGLTextureFromImageWithName(filenameStr, &mImageSize, &mTextureSize);
    [filenameStr release];
    if (mTextureName == GL_INVALID_VALUE || mTextureName == GL_INVALID_OPERATION) {
        const char* errorFormat = "Failed to load \"%s\". Please confirm that the image file exists.";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "\"%s\" の読み込みに失敗しました。画像ファイルが存在することを確認してください。";
        }
        throw KRRuntimeError(errorFormat, filename.c_str());
    }
    _KRTexture2DName = GL_INVALID_VALUE;

    if (atlasSize.x > 0.0 && atlasSize.y > 0.0) {
        mAtlas = new KRTexture2DAtlas(this, KRVector2DZero, atlasSize);
    }
}

KRTexture2D::KRTexture2D(const std::string& str, KRFont* font)
{
    if (_gKRTexture2DBatchCount > 0) {
        _KRTexture2D::processBatchedTexture2DDraws();
    }
    
    mAtlas = NULL;

    NSString* strStr = [[NSString alloc] initWithCString:str.c_str() encoding:NSUTF8StringEncoding];
    mTextureName = KRCreateGLTextureFromString(strStr, font->getFontObject(), KRColor::White, &mTextureTarget, &mImageSize, &mTextureSize);
    [strStr release];
    if (mTextureName == GL_INVALID_VALUE || mTextureName == GL_INVALID_OPERATION) {
        const char* errorFormat = "Failed to create a texture for a string: \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "文字列テクスチャの生成に失敗しました。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, str.c_str());
    }
    _KRTexture2DName = GL_INVALID_VALUE;
}

KRTexture2D::~KRTexture2D()
{
    if (_KRTexture2DName == mTextureName) {
        _KRTexture2DName = GL_INVALID_VALUE;
    }
    glDeleteTextures(1, &mTextureName);

    if (mAtlas != NULL) {
        delete ((KRTexture2DAtlas*)mAtlas);
    }
}


#pragma mark -
#pragma mark Status Getting Functions

int KRTexture2D::getDivX()
{
    return mAtlasDiv.x;
}

int KRTexture2D::getDivY()
{
    return mAtlasDiv.y;
}

bool KRTexture2D::isAtlasFlipped()
{
    return mIsAtlasFlipped;
}

KRVector2D KRTexture2D::getAtlasSize() const
{
    return mAtlasSize;
}

double KRTexture2D::getWidth() const
{
    return mImageSize.x;
}

double KRTexture2D::getHeight() const
{
    return mImageSize.y;
}

KRVector2D KRTexture2D::getSize() const
{
    return mImageSize;
}

KRVector2D KRTexture2D::getCenterPos() const
{
    return KRVector2D(mImageSize.x / 2, mImageSize.y / 2);
}


#pragma mark -

void KRTexture2D::setTextureAtlasSize(const KRVector2D& size)
{
    mAtlasSize = size;
}

void KRTexture2D::setTextureOrigin(const KRVector2D& origin)
{
    mOrigin = origin;
}


#pragma mark -
#pragma mark Drawing Functions (Old)

void KRTexture2D::draw(const KRVector2D& centerPos, const KRRect2D& srcRect, double rotation, const KRVector2D &origin, const KRVector2D &scale, double alpha)
{
    drawC(centerPos, srcRect, rotation, origin, scale, KRColor(1.0, 1.0, 1.0, alpha));
}

void KRTexture2D::drawC(const KRVector2D& centerPos, const KRRect2D& srcRect, double rotation, const KRVector2D &origin, const KRVector2D &scale, const KRColor& color)
{
    if (_KRTexture2DName != mTextureName) {
        _KRTexture2D::processBatchedTexture2DDraws();
    }
    
    if (!_KRTexture2DEnabled) {
        _KRTexture2DEnabled = true;
        glEnable(GL_TEXTURE_2D);
    }
    if (_KRTexture2DName != mTextureName) {
        _KRTexture2DName = mTextureName;
        glBindTexture(GL_TEXTURE_2D, mTextureName);
        
#if __DEBUG__
        _KRTextureChangeCount++;
#endif
    }
    
    KRRect2D theSrcRect = srcRect;
    if (srcRect.width == 0.0 && srcRect.height == 0.0) {
        theSrcRect.x = 0.0;
        theSrcRect.y = 0.0;
        theSrcRect.width = mImageSize.x;
        theSrcRect.height = mImageSize.y;
    }
    theSrcRect.y = mImageSize.y - theSrcRect.y;
    
    float texX = (theSrcRect.x / mImageSize.x) * mTextureSize.x;
    float texY = (theSrcRect.y / mImageSize.y) * mTextureSize.y;
    float texWidth = (theSrcRect.width / mImageSize.x) * mTextureSize.x;
    float texHeight = (theSrcRect.height / mImageSize.y) * mTextureSize.y * -1;
    
    float p1_x = 0.0f;
    float p2_x = theSrcRect.width;
    float p3_x = 0.0f;
    float p4_x = theSrcRect.width;
    
    float p1_y = theSrcRect.height;
    float p2_y = theSrcRect.height;
    float p3_y = 0.0f;
    float p4_y = 0.0f;
    
    // Translate the 4 coord points according to the origin
    if (origin.x != 0.0f) {
        p1_x -= origin.x;
        p2_x -= origin.x;
        p3_x -= origin.x;
        p4_x -= origin.x;
    }
    if (origin.y != 0.0f) {
        p1_y -= origin.y;
        p2_y -= origin.y;
        p3_y -= origin.y;
        p4_y -= origin.y;
    }
    
    // Scale the 4 coord points
    if (scale.x != 1.0f) {
        p1_x *= scale.x;
        p2_x *= scale.x;
        p3_x *= scale.x;
        p4_x *= scale.x;
    }
    if (scale.y != 1.0f) {
        p1_y *= scale.y;
        p2_y *= scale.y;
        p3_y *= scale.y;
        p4_y *= scale.y;
    }
    
    // Rotate the 4 coord points
    if (rotation != 0.0) {
        double cos_value = cos(rotation);
        double sin_value = sin(rotation);
        float p1_x2 = p1_x * cos_value - p1_y * sin_value;
        float p2_x2 = p2_x * cos_value - p2_y * sin_value;
        float p3_x2 = p3_x * cos_value - p3_y * sin_value;
        float p4_x2 = p4_x * cos_value - p4_y * sin_value;
        
        float p1_y2 = p1_x * sin_value + p1_y * cos_value;
        float p2_y2 = p2_x * sin_value + p2_y * cos_value;
        float p3_y2 = p3_x * sin_value + p3_y * cos_value;
        float p4_y2 = p4_x * sin_value + p4_y * cos_value;
        
        p1_x = p1_x2;
        p2_x = p2_x2;
        p3_x = p3_x2;
        p4_x = p4_x2;
        
        p1_y = p1_y2;
        p2_y = p2_y2;
        p3_y = p3_y2;
        p4_y = p4_y2;
    }
    
    // Translate the center point to the appropriate location
    p1_x += centerPos.x;
    p2_x += centerPos.x;
    p3_x += centerPos.x;
    p4_x += centerPos.x;
    
    p1_y += centerPos.y;
    p2_y += centerPos.y;
    p3_y += centerPos.y;
    p4_y += centerPos.y;
    
    // Set the vertices into an array
    int batchPos = _gKRTexture2DBatchCount * 6;
    
    _gKRTexture2DDrawData[batchPos].vertex_x = (GLfloat)p1_x;    _gKRTexture2DDrawData[batchPos].vertex_y = (GLfloat)p1_y;
    _gKRTexture2DDrawData[batchPos+1].vertex_x = (GLfloat)p2_x;  _gKRTexture2DDrawData[batchPos+1].vertex_y = (GLfloat)p2_y;
    _gKRTexture2DDrawData[batchPos+2].vertex_x = (GLfloat)p3_x;  _gKRTexture2DDrawData[batchPos+2].vertex_y = (GLfloat)p3_y;
    _gKRTexture2DDrawData[batchPos+3].vertex_x = (GLfloat)p2_x;  _gKRTexture2DDrawData[batchPos+3].vertex_y = (GLfloat)p2_y;
    _gKRTexture2DDrawData[batchPos+4].vertex_x = (GLfloat)p3_x;  _gKRTexture2DDrawData[batchPos+4].vertex_y = (GLfloat)p3_y;
    _gKRTexture2DDrawData[batchPos+5].vertex_x = (GLfloat)p4_x;  _gKRTexture2DDrawData[batchPos+5].vertex_y = (GLfloat)p4_y;
    
    float tx_1 = texX;
    float tx_2 = texX + texWidth;
    float ty_1 = texY;
    float ty_2 = texY + texHeight;
    
    _gKRTexture2DDrawData[batchPos].texCoords_x = tx_1;      _gKRTexture2DDrawData[batchPos].texCoords_y = ty_2;
    _gKRTexture2DDrawData[batchPos+1].texCoords_x = tx_2;    _gKRTexture2DDrawData[batchPos+1].texCoords_y = ty_2;
    _gKRTexture2DDrawData[batchPos+2].texCoords_x = tx_1;    _gKRTexture2DDrawData[batchPos+2].texCoords_y = ty_1;
    _gKRTexture2DDrawData[batchPos+3].texCoords_x = tx_2;    _gKRTexture2DDrawData[batchPos+3].texCoords_y = ty_2;
    _gKRTexture2DDrawData[batchPos+4].texCoords_x = tx_1;    _gKRTexture2DDrawData[batchPos+4].texCoords_y = ty_1;
    _gKRTexture2DDrawData[batchPos+5].texCoords_x = tx_2;    _gKRTexture2DDrawData[batchPos+5].texCoords_y = ty_1;
    
    _gKRTexture2DDrawData[batchPos].colors[0] =
    _gKRTexture2DDrawData[batchPos+1].colors[0] =
    _gKRTexture2DDrawData[batchPos+2].colors[0] =
    _gKRTexture2DDrawData[batchPos+3].colors[0] =
    _gKRTexture2DDrawData[batchPos+4].colors[0] =
    _gKRTexture2DDrawData[batchPos+5].colors[0] =
        (GLubyte)(255 * color.r);
    
    _gKRTexture2DDrawData[batchPos].colors[1] =
    _gKRTexture2DDrawData[batchPos+1].colors[1] =
    _gKRTexture2DDrawData[batchPos+2].colors[1] =
    _gKRTexture2DDrawData[batchPos+3].colors[1] =
    _gKRTexture2DDrawData[batchPos+4].colors[1] =
    _gKRTexture2DDrawData[batchPos+5].colors[1] =
        (GLubyte)(255 * color.g);
    
    _gKRTexture2DDrawData[batchPos].colors[2] =
    _gKRTexture2DDrawData[batchPos+1].colors[2] =
    _gKRTexture2DDrawData[batchPos+2].colors[2] =
    _gKRTexture2DDrawData[batchPos+3].colors[2] =
    _gKRTexture2DDrawData[batchPos+4].colors[2] =
    _gKRTexture2DDrawData[batchPos+5].colors[2] =
        (GLubyte)(255 * color.b);
    
    _gKRTexture2DDrawData[batchPos].colors[3] =
    _gKRTexture2DDrawData[batchPos+1].colors[3] =
    _gKRTexture2DDrawData[batchPos+2].colors[3] =
    _gKRTexture2DDrawData[batchPos+3].colors[3] =
    _gKRTexture2DDrawData[batchPos+4].colors[3] =
    _gKRTexture2DDrawData[batchPos+5].colors[3] =
        (GLubyte)(255 * color.a);
    
    _gKRTexture2DBatchCount++;
    
    if (_gKRTexture2DBatchCount >= _gKRTexture2DBatchSize) {
        _KRTexture2D::processBatchedTexture2DDraws();
    }
}

void KRTexture2D::drawAtPoint(double x, double y, double alpha)
{
    drawInRect(KRRect2D(KRVector2D(x, y), mImageSize), alpha);
}

void KRTexture2D::drawAtPointC(double x, double y, const KRColor& color)
{
    drawInRectC(KRRect2D(KRVector2D(x, y), mImageSize), color);
}

void KRTexture2D::drawAtPoint(const KRVector2D& pos, double alpha)
{
    drawInRect(KRRect2D(pos, mImageSize), alpha);
}

void KRTexture2D::drawAtPointCenter(const KRVector2D& centerPos, double alpha)
{
    KRVector2D pos = centerPos - getSize() / 2;
    drawC(pos, KRRect2DZero, 0.0, KRVector2DZero, KRVector2D(1.0, 1.0), KRColor(1.0, 1.0, 1.0, alpha));
}

void KRTexture2D::drawAtPointC(const KRVector2D& pos, const KRColor& color)
{
    drawC(pos, KRRect2DZero, 0.0, KRVector2DZero, KRVector2D(1.0, 1.0), color);
}

void KRTexture2D::drawAtPointCenterC(const KRVector2D& centerPos, const KRColor& color)
{
    KRVector2D pos = centerPos - getSize() / 2;
    drawC(pos, KRRect2DZero, 0.0, KRVector2DZero, KRVector2D(1.0, 1.0), color);
}

void KRTexture2D::drawAtPoint(const KRVector2D& pos, const KRRect2D& srcRect, double alpha)
{
    drawC(pos, srcRect, 0.0, KRVector2DZero, KRVector2D(1.0, 1.0), KRColor(1.0, 1.0, 1.0, alpha));
}

void KRTexture2D::drawAtPointC(const KRVector2D& pos, const KRRect2D& srcRect, const KRColor& color)
{
    drawC(pos, srcRect, 0.0, KRVector2DZero, KRVector2D(1.0, 1.0), color);
}

void KRTexture2D::drawInRect(const KRRect2D& rect, double alpha)
{
    KRVector2D scale(rect.width / mImageSize.x, rect.height / mImageSize.y);
    drawC(rect.getOrigin(), KRRect2DZero, 0.0, KRVector2DZero, scale, KRColor(1.0, 1.0, 1.0, alpha));
}

void KRTexture2D::drawInRectC(const KRRect2D& rect, const KRColor& color)
{
    drawC(rect.getOrigin(), KRRect2DZero, 0.0, KRVector2DZero, KRVector2D(rect.width / mImageSize.x, rect.height / mImageSize.y), color);
}

void KRTexture2D::drawInRect(const KRRect2D& destRect, const KRRect2D& srcRect, double alpha)
{
    KRRect2D theSrcRect = srcRect;
    if (srcRect.width == 0.0 && srcRect.height == 0.0) {
        theSrcRect.x = 0.0;
        theSrcRect.y = 0.0;
        theSrcRect.width = mImageSize.x;
        theSrcRect.height = mImageSize.y;
    }
    
    KRVector2D scale(destRect.width / theSrcRect.width, destRect.height / theSrcRect.height);
    drawC(destRect.getOrigin(), srcRect, 0.0, KRVector2DZero, scale, KRColor(1.0, 1.0, 1.0, alpha));
}

void KRTexture2D::drawInRectC(const KRRect2D& destRect, const KRRect2D& srcRect, const KRColor& color)
{
    KRRect2D theSrcRect = srcRect;
    if (srcRect.width == 0.0 && srcRect.height == 0.0) {
        theSrcRect.x = 0.0;
        theSrcRect.y = 0.0;
        theSrcRect.width = mImageSize.x;
        theSrcRect.height = mImageSize.y;
    }
    
    KRVector2D scale(destRect.width / theSrcRect.width, destRect.height / theSrcRect.height);
    drawC(destRect.getOrigin(), srcRect, 0.0, KRVector2DZero, scale, color);
}


#pragma mark -

void KRTexture2D::drawAtlas(int row, int column, const KRVector2D& centerPos, double rotation, const KRVector2D &origin, const KRVector2D &scale, double alpha)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlas(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlas() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->draw(row, column, centerPos, rotation, origin, scale, alpha);
}

void KRTexture2D::drawAtlasC(int row, int column, const KRVector2D& centerPos, double rotation, const KRVector2D &origin, const KRVector2D &scale, const KRColor& color)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasC(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasC() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->drawC(row, column, centerPos, rotation, origin, scale, color);
}

void KRTexture2D::drawAtlasAtPoint(int row, int column, const KRVector2D& pos, double alpha)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasAtPoint(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasAtPoint() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->drawAtPoint(row, column, pos, alpha);
}

void KRTexture2D::drawAtlasAtPointCenter(int row, int column, const KRVector2D& centerPos, double alpha)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasAtPointCenter(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasAtPointCenter() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    KRVector2D pos = centerPos - ((KRTexture2DAtlas*)mAtlas)->getOneSize()/2;    
    ((KRTexture2DAtlas*)mAtlas)->drawAtPoint(row, column, pos, alpha);
}

void KRTexture2D::drawAtlasAtPointCenterC(int row, int column, const KRVector2D& centerPos, const KRColor& color)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasAtPointCenterC(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasAtPointCenterC() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    KRVector2D pos = centerPos - ((KRTexture2DAtlas*)mAtlas)->getOneSize()/2;    
    ((KRTexture2DAtlas*)mAtlas)->drawAtPointC(row, column, pos, color);
}

void KRTexture2D::drawAtlasAtPointC(int row, int column, const KRVector2D& pos, const KRColor& color)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasAtPointC(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasAtPointC() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->drawAtPointC(row, column, pos, color);
}

void KRTexture2D::drawAtlasInRect(int row, int column, const KRRect2D& rect, double alpha)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasInRect(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasInRect() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->drawInRect(row, column, rect, alpha);
}

void KRTexture2D::drawAtlasInRectC(int row, int column, const KRRect2D& rect, const KRColor& color)
{
    if (mAtlas == NULL) {
        const char* errorFormat = "You have to set atlas size at constructor KRTexture2D() when you use drawAtlasInRectC(): \"%s\"";
        if (gKRLanguage == KRLanguageJapanese) {
            errorFormat = "drawAtlasInRectC() を使用するためには、コンストラクタ KRTexture2D() でアトラスサイズを指定する必要があります。\"%s\"";
        }
        throw KRRuntimeError(errorFormat, mFileName.c_str());
    }
    
    ((KRTexture2DAtlas*)mAtlas)->drawInRectC(row, column, rect, color);
}


#pragma mark -

void KRTexture2D::set()
{
    if (!_KRTexture2DEnabled) {
        _KRTexture2DEnabled = true;
        glEnable(GL_TEXTURE_2D);
    }
    if (_KRTexture2DName != mTextureName) {
        _KRTexture2DName = mTextureName;
        glBindTexture(GL_TEXTURE_2D, mTextureName);
        
#if __DEBUG__
        _KRTextureChangeCount++;
#endif
    }
}

#pragma mark -
#pragma mark Exporting Texture Name

GLuint KRTexture2D::getTextureName() const
{
    return mTextureName;
}


#pragma mark -
#pragma mark Debugging Support

std::string KRTexture2D::to_s() const
{
    std::string ret = "<tex2_old>(file=\"" + mFileName + "\", ";
    ret += KRFS("name=%d, image_size=(%3.0f, %3.0f), tex_size=(%3.2f, %3.2f))", mTextureName, mImageSize.x, mImageSize.y, mTextureSize.x, mTextureSize.y);
    return ret;
}

