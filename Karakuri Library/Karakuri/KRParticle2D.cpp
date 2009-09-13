/*!
 @file   KRParticle2D.cpp
 @author numata
 @date   09/08/07
 */

#include "KRParticle2D.h"


#if KR_PARTICLE2D_USE_POINT_SPRITE
static GLenum sPointSpriteName = 0;
static GLenum sPointSpriteCoordReplaceName = 0;
#endif


/*!
    @method KRParticle2D
    Constructor
 */
KRParticle2D::KRParticle2D(unsigned life, const KRVector2D& pos, const KRVector2D& v, const KRVector2D& gravity, const KRColor& color, float size,
                           float deltaRed, float deltaGreen, float deltaBlue, float deltaAlpha, float deltaSize)
    : mBaseLife(life), mLife(life), mPos(pos), mV(v), mGravity(gravity), mColor(color), mSize(size),
      mDeltaRed(deltaRed), mDeltaGreen(deltaGreen), mDeltaBlue(deltaBlue), mDeltaAlpha(deltaAlpha), mDeltaSize(deltaSize)
{
}

bool KRParticle2D::step()
{
    if (mLife == 0) {  
        return false;
    }
    mV += mGravity;
    mPos += mV;
    mLife--;  
    return true;
}

std::string KRParticle2D::to_s() const
{
    return "<particle2>()";
}


void KRParticle2DSystem::init()
{
#if KR_PARTICLE2D_USE_POINT_SPRITE
    if (sPointSpriteName == 0) {
#if KR_MACOSX || KR_IPHONE_MACOSX_EMU
        if (_KROpenGLVersionValue > 1.4 && 0) {
            sPointSpriteName = GL_POINT_SPRITE;
            sPointSpriteCoordReplaceName = GL_COORD_REPLACE;
        } else if (KRCheckOpenGLExtensionSupported("GL_ARB_point_sprite")) {
            sPointSpriteName = GL_POINT_SPRITE_ARB;
            sPointSpriteCoordReplaceName = GL_COORD_REPLACE_ARB;
        } else {
            std::string errorFormat = "This computer does not support point sprite.";
            if (KRLanguage == KRLanguageJapanese) {
                errorFormat = "このコンピュータはポイントスプライトをサポートしていません。";
            }
            throw KRRuntimeError(errorFormat);
        }
#endif  // #if KR_MACOSX || KR_IPHONE_MACOSX_EMU
        
#if KR_IPHONE && !KR_IPHONE_MACOSX_EMU
        sPointSpriteName = GL_POINT_SPRITE_OES;
        sPointSpriteCoordReplaceName = GL_COORD_REPLACE_OES;
#endif  // #if KR_IPHONE && !KR_IPHONE_MACOSX_EMU
    }
#endif  // #if KR_PARTICLE2D_USE_POINT_SPRITE
    
    mStartPos = KRScreenSize / 2;
    
    mColor = KRColor::White;
    
#if KR_PARTICLE2D_USE_POINT_SPRITE
    mSize = 64.0f;
#else
    mMinSize = 1.0f;
    mMaxSize = 64.0f;
#endif
    
    mMinV = KRVector2D(-8.0f, -8.0f);
    mMaxV = KRVector2D(8.0f, 8.0f);
    
    mGravity = KRVector2DZero;
    
    mDeltaSize = 0.0f;
    mDeltaRed = 0.0f;
    mDeltaGreen = 0.0f;
    mDeltaBlue = 0.0f;
    mDeltaAlpha = -2.0f;
    
    mBlendMode = KRBlendModeAddition;
    
    mParticleCount = 256;
    mGenerateCount = 0;
    
    mLife = 60;
    
    mActiveGenCount = 0;
    for (int i = 0; i < KRParticle2DGenMaxCount; i++) {
        mGenInfos[i].count = 0;
    }
}


#pragma mark -
#pragma mark Constructor / Destructor

/*!
    @method KRParticle2DSystem
    Constructor
 */
KRParticle2DSystem::KRParticle2DSystem(const std::string& filename, bool doLoop)
    : mDoLoop(doLoop)
{
    mHasInnerTexture = true;
    mTexture = new KRTexture2D(filename);
    
    init();
}
/*!
    @method KRParticle2DSystem
    Constructor
 */
KRParticle2DSystem::KRParticle2DSystem(KRTexture2D *texture, bool doLoop)
    : mDoLoop(doLoop)
{
    mHasInnerTexture = false;
    mTexture = texture;
    
    init();
}

/*!
    @method ~KRParticleSystem
    Destructor
 */
KRParticle2DSystem::~KRParticle2DSystem()
{
    for (std::list<KRParticle2D *>::iterator it = mParticles.begin(); it != mParticles.end(); it++) {
        delete *it;
    }
    mParticles.clear();
    
    if (mHasInnerTexture) {
        delete mTexture;
    }
}


#pragma mark -
#pragma mark Getter Functions

unsigned KRParticle2DSystem::getLife() const
{
    return mLife;
}

KRVector2D KRParticle2DSystem::getStartPos() const
{
    return mStartPos;
}

unsigned KRParticle2DSystem::getParticleCount() const
{
    return mParticleCount;
}

int KRParticle2DSystem::getGenerateCount() const
{
    return mGenerateCount;
}

unsigned KRParticle2DSystem::getGeneratedParticleCount() const
{
    return mParticles.size();
}

KRBlendMode KRParticle2DSystem::getBlendMode() const
{
    return mBlendMode;
}

KRColor KRParticle2DSystem::getColor() const
{
    return mColor;
}

float KRParticle2DSystem::getDeltaRed() const
{
    return mDeltaRed;
}

float KRParticle2DSystem::getDeltaGreen() const
{
    return mDeltaGreen;
}

float KRParticle2DSystem::getDeltaBlue() const
{
    return mDeltaBlue;
}

float KRParticle2DSystem::getDeltaAlpha() const
{
    return mDeltaAlpha;
}

KRVector2D KRParticle2DSystem::getMinV() const
{
    return mMinV;
}

KRVector2D KRParticle2DSystem::getMaxV() const
{
    return mMaxV;
}

KRVector2D KRParticle2DSystem::getGravity() const
{
    return mGravity;
}


#pragma mark -
#pragma mark Setter Functions

void KRParticle2DSystem::setStartPos(const KRVector2D& pos)
{
    mStartPos = pos;
}

void KRParticle2DSystem::setColor(const KRColor& color)
{
    mColor = color;
}

void KRParticle2DSystem::setColorDelta(float red, float green, float blue, float alpha)
{
    mDeltaRed = red;
    mDeltaGreen = green;
    mDeltaBlue = blue;
    mDeltaAlpha = alpha;
}

void KRParticle2DSystem::setBlendMode(KRBlendMode blendMode)
{
    mBlendMode = blendMode;
}

void KRParticle2DSystem::setParticleCount(unsigned count)
{
    mParticleCount = count;
}

void KRParticle2DSystem::setGenerateCount(int count)
{
    mGenerateCount = count;
}

#if KR_PARTICLE2D_USE_POINT_SPRITE

float KRParticle2DSystem::getSize() const
{
    return mSize;
}

void KRParticle2DSystem::setSize(float size)
{
    // We limit the size to 64 pixels, because the size of point sprite is limited to 64 pixels on iPhone
    if (size < 0.0f) {
        size = 0.0f;
    } else if (size > 64.0f) {
        size = 64.0f;
    }
    mSize = size;
}

#else

float KRParticle2DSystem::getMinSize() const
{
    return mMinSize;
}

float KRParticle2DSystem::getMaxSize() const
{
    return mMaxSize;
}

void KRParticle2DSystem::setMinSize(float size)
{
    mMinSize = size;
}

void KRParticle2DSystem::setMaxSize(float size)
{
    mMaxSize = size;
}

#endif

void KRParticle2DSystem::setSizeDelta(float value)
{
    mDeltaSize = value;
}

void KRParticle2DSystem::setLife(unsigned life)
{
    mLife = life;
}

void KRParticle2DSystem::setMinV(const KRVector2D& v)
{
    mMinV = v;
}

void KRParticle2DSystem::setMaxV(const KRVector2D& v)
{
    mMaxV = v;
}

void KRParticle2DSystem::setGravity(const KRVector2D& a)
{
    mGravity = a;
}

void KRParticle2DSystem::addGenerationPoint(const KRVector2D& pos)
{
    if (mActiveGenCount >= KRParticle2DGenMaxCount) {
        return;
    }
    for (int i = 0; i < KRParticle2DGenMaxCount; i++) {
        if (mGenInfos[i].count == 0) {
            mGenInfos[i].count = mGenerateCount;
            mGenInfos[i].centerPos = pos;
            mActiveGenCount++;
            break;
        }
    }
}

void KRParticle2DSystem::step()
{
    // Continuous Generation
    if (mDoLoop) {
        if (mGenerateCount >= 0) {
            unsigned count = 0;
            while (mParticles.size() < mParticleCount) {
                KRVector2D theV(KRRand->nextInt(mMaxV.x - mMinV.x) + mMinV.x, KRRand->nextInt(mMaxV.y - mMinV.y) + mMinV.y);
                
    #if KR_PARTICLE2D_USE_POINT_SPRITE
                float theSize = mSize;
    #else
                float theSize = KRRand->nextFloat() * (mMaxSize - mMinSize) + mMinSize;
    #endif
                
                KRParticle2D *particle = new KRParticle2D(mLife, mStartPos, theV, mGravity, mColor, theSize,
                                                          mDeltaRed, mDeltaGreen, mDeltaBlue, mDeltaAlpha, mDeltaSize);
                mParticles.push_back(particle);
                count++;
                if (count == mGenerateCount) {
                    break;
                }
            }
        }
    }
    // Point to Point Generation
    else {
        int genCount = 0;
        int finishedCount = 0;
        for (int i = 0; i < mActiveGenCount; i++) {
            if (mGenInfos[i].count > 0) {
                unsigned createCount = KRMin(mGenerateCount, mGenInfos[i].count);
                for (int j = 0; j < createCount; j++) {
                    KRVector2D theV(KRRand->nextInt(mMaxV.x - mMinV.x) + mMinV.x, KRRand->nextInt(mMaxV.y - mMinV.y) + mMinV.y);
#if KR_PARTICLE2D_USE_POINT_SPRITE
                    float theSize = mSize;
#else
                    float theSize = KRRand->nextFloat() * (mMaxSize - mMinSize) + mMinSize;
#endif
                    KRParticle2D *particle = new KRParticle2D(mLife, mGenInfos[i].centerPos, theV, mGravity, mColor, theSize,
                                                              mDeltaRed, mDeltaGreen, mDeltaBlue, mDeltaAlpha, mDeltaSize);
                    mParticles.push_back(particle);
                }
                mGenInfos[i].count -= createCount;
                if (mGenInfos[i].count == 0) {
                    finishedCount++;
                }
                genCount++;
                if (genCount >= mActiveGenCount) {
                    break;
                }
            }
        }
        mActiveGenCount -= finishedCount;
    }
    
    // Move all points 
    for (std::list<KRParticle2D *>::iterator it = mParticles.begin(); it != mParticles.end();) {
        if ((*it)->step()) {
            it++;
        } else {
            it = mParticles.erase(it);
        }
    }    
}

#if KR_PARTICLE2D_USE_POINT_SPRITE
void KRParticle2DSystem::draw()
{
    KRTexture2D::processBatchedTexture2DDraws();
    
    // ポイントスプライトを有効化
    glTexEnvi(sPointSpriteName, sPointSpriteCoordReplaceName, GL_TRUE);
    glEnable(sPointSpriteName);
    
    KRGraphicsInst->setBlendMode(mBlendMode);
    
    mTexture->set();
    
    glPointSize(mSize);  
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    
    //float constant = 0.0f;
    //float linear = 0.002f;
    //float quadratic = 0.00001f;
    //float coefficients[] = { constant, linear, quadratic };
    //glPointParameterfv(GL_POINT_DISTANCE_ATTENUATION, coefficients);    
	//glPointParameterf(GL_POINT_FADE_THRESHOLD_SIZE, 60.0f);
	glPointParameterf(GL_POINT_SIZE_MIN, 0.0f);
	glPointParameterf(GL_POINT_SIZE_MAX, 64.0f);
    
    unsigned particleCount = mParticles.size();
    
    GLfloat data[particleCount * 6];
    GLfloat *p = data;
    
    for (std::list<KRParticle2D *>::iterator it = mParticles.begin(); it != mParticles.end(); it++) {
        float ratio = (1.0f - (float)((*it)->mLife) / (*it)->mBaseLife);
        //float ratio2 = ratio * ratio;
        *(p++) = (*it)->mPos.x;
        *(p++) = (*it)->mPos.y;
        *(p++) = KRMax((*it)->mColor.r + (*it)->mDeltaRed * ratio, 0.0f);
        *(p++) = KRMax((*it)->mColor.g + (*it)->mDeltaGreen * ratio, 0.0f);
        *(p++) = KRMax((*it)->mColor.b + (*it)->mDeltaBlue * ratio, 0.0f);
        *(p++) = KRMax((*it)->mColor.a + (*it)->mDeltaAlpha * ratio, 0.0f);
    }
    glVertexPointer(2, GL_FLOAT, 6 * sizeof(GLfloat), data);  
    glColorPointer(4, GL_FLOAT, 6 * sizeof(GLfloat), data + 2);  
    glDrawArrays(GL_POINTS, 0, particleCount);
    
#if __DEBUG__
    _KRTextureBatchProcessCount++;
#endif    
}
#else // #if KR_PARTICLE2D_USE_POINT_SPRITE
void KRParticle2DSystem::draw()
{
    KRGraphicsInst->setBlendMode(mBlendMode);
    
    KRVector2D centerPos = mTexture->getCenterPos();
    for (std::list<KRParticle2D *>::iterator it = mParticles.begin(); it != mParticles.end(); it++) {
        float ratio = (1.0f - (float)((*it)->mLife) / (*it)->mBaseLife);
        float size = KRMax((*it)->mSize + (*it)->mDeltaSize * ratio, 0.0f);
        KRColor color;
        color.r = KRMax((*it)->mColor.r + (*it)->mDeltaRed * ratio, 0.0f);
        color.g = KRMax((*it)->mColor.g + (*it)->mDeltaGreen * ratio, 0.0f);
        color.b = KRMax((*it)->mColor.b + (*it)->mDeltaBlue * ratio, 0.0f);
        color.a = KRMax((*it)->mColor.a + (*it)->mDeltaAlpha * ratio, 0.0f);
        
        mTexture->draw(KRRect2D((*it)->mPos.x-size/2, (*it)->mPos.y-size/2, size, size), color);
    }
}
#endif  // #if KR_PARTICLE2D_USE_POINT_SPRITE

std::string KRParticle2DSystem::to_s() const
{
#if KR_PARTICLE2D_USE_POINT_SPRITE
    return KRFS("<particle2_sys>(size=%3.1f, life=%u, count=%u, generated=%u, tex=%s)", mSize, mLife, mParticleCount, mParticles.size(), mTexture->c_str());
#else
    return KRFS("<particle2_sys>(size=(%3.1f, %3.1f), life=%u, count=%u, generated=%u, tex=%s)", mMinSize, mMaxSize, mLife, mParticleCount, mParticles.size(), mTexture->c_str());
#endif
}


