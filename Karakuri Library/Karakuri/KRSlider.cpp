/*!
    @file   KRSlider.cpp
    @author numata
    @date   09/08/28
 */

#include "KRSlider.h"
#include "KRPrimitive2D.h"


/*!
    @method KRSlider
    Constructor
 */
KRSlider::KRSlider(const KRRect2D& frame)
    : KRControl(frame), mValue(0.0f), mMinValue(0.0f), mMaxValue(1.0f)
{
    mThumbTexture = NULL;
    mThumbTextureName = "";
    
    mBackTexture = NULL;
    mBackTextureName = "";
}

/*!
    @method ~KRSlider
    Destructor
 */
KRSlider::~KRSlider()
{
    if (mThumbTexture != NULL) {
        delete mThumbTexture;
    }
    if (mBackTexture != NULL) {
        delete mBackTexture;
    }
}

#pragma mark -
#pragma mark Control Implementation

bool KRSlider::update(KRInput *input)
{
    if (!mSelected) {
        mSelected = true;
        return true;
    } else {
#if KR_MACOSX
        bool inputOn = (input->getMouseState() & KRInput::MouseButtonAny)? true: false;
#endif
#if KR_IPHONE
        bool inputOn = input->getTouch();
#endif
        
        if (!inputOn) {
            mSelected = false;
            return false;
        } else {
#if KR_MACOSX
            KRVector2D pos = input->getMouseLocation();
#endif
#if KR_IPHONE
            KRVector2D pos = input->getTouchLocation();
#endif
            float thumbWidth = 20.0f;

            float value = (pos.x - mFrame.x - thumbWidth/2) / (mFrame.width - thumbWidth);
            if (value < mMinValue) {
                value = mMinValue;
            } else if (value > mMaxValue) {
                value = mMaxValue;
            }
            if (mValue != value) {
                mValue = value;
                mWorld->sliderValueChanged(this);
            }
            return true;
        }
    }        
}

void KRSlider::draw(KRGraphics *g)
{
    if (mThumbTexture == NULL && mThumbTextureName.length() > 0) {
        mThumbTexture = new KRTexture2D(mThumbTextureName);
    }
    
    if (mBackTexture == NULL && mBackTextureName.length() > 0) {
        mBackTexture = new KRTexture2D(mBackTextureName);
    }
    
    
    float thumbWidth = 20.0f;

    if (mThumbTexture != NULL) {
        thumbWidth = mThumbTexture->getWidth();
    }
    
    float centerX = mFrame.x + (mFrame.width - thumbWidth) * (mValue / (mMaxValue - mMinValue)) + thumbWidth/2;
    
    if (mBackTexture != NULL) {
        // Left Edge
        mBackTexture->draw(KRVector2D(mFrame.x, mFrame.y), KRRect2D(0, 0, mBackTextureEdgeSize, mFrame.height));
        
        // Left Background
        mBackTexture->draw(KRRect2D(mFrame.x+mBackTextureEdgeSize, mFrame.y, (centerX-(mFrame.x+mBackTextureEdgeSize)), mFrame.height),
                           KRRect2D(mBackTexture->getWidth()/2-1, 0, 1, mFrame.height));
        
        // Right Background
        mBackTexture->draw(KRRect2D(centerX, mFrame.y, mFrame.x+mFrame.width-centerX-mBackTextureEdgeSize, mFrame.height),
                           KRRect2D(mBackTexture->getWidth()/2, 0, 1, mFrame.height));
        
        // Right Edge
        mBackTexture->draw(KRVector2D(mFrame.x+mFrame.width-mBackTextureEdgeSize, mFrame.y), KRRect2D(mBackTexture->getWidth()-mBackTextureEdgeSize, 0, mBackTextureEdgeSize, mFrame.height));
    } else {
        if (mSelected) {
            KRPrimitive2D::fillQuad(mFrame, KRColor::Red);
        } else {
            KRPrimitive2D::fillQuad(mFrame, KRColor::Blue);
        }
    }
    
    if (mThumbTexture != NULL) {
        mThumbTexture->draw(centerX-thumbWidth/2, mFrame.y);
    } else {
        KRPrimitive2D::fillQuad(KRRect2D(centerX-thumbWidth/2, mFrame.y, thumbWidth, mFrame.height), KRColor::Yellow);
    }
}


#pragma mark -
#pragma mark Slider Implementation

float KRSlider::getMaxValue() const
{
    return mMaxValue;
}

float KRSlider::getMinValue() const
{
    return mMinValue;
}

float KRSlider::getValue() const
{
    return mValue;
}

void KRSlider::setMaxValue(float value)
{
    mMaxValue = value;
}

void KRSlider::setMinValue(float value)
{
    mMinValue = value;
}

void KRSlider::setValue(float value)
{
    mValue = value;
}

void KRSlider::setTextureNames(const std::string& backName, float edgeSize, const std::string& thumbName)
{
    mBackTextureName = backName;
    mBackTextureEdgeSize = edgeSize;

    mThumbTextureName = thumbName;
}

