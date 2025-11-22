/*********************************************************/
//	Nkfl_Interface.H
//		Header File for Nikon File Library Interface.
//
//		This file defines the basic interface of Nikon File Library.
//
//		Copyright(c) 1999, Nikon Corporation - All rights reserved.
/*********************************************************/
#ifndef _Nkfl_Interface_H
#define _Nkfl_Interface_H


/*********************************************************/
//	Function
/*********************************************************/
///////////////////////////////////////////////////////////
//	Declaration and definition for Entry Function of Nikon Browse Library
//
#if defined(_WIN32)

#ifdef _cplusplus
extern "C"
{
#endif

	unsigned long __declspec(dllexport) WINAPI Nkfl_Entry(unsigned long ulCommand, void* pParam );
	typedef unsigned long __declspec(dllexport) WINAPI Nkfl_EntryProc( unsigned long ulCommand, void* pParam );
	typedef Nkfl_EntryProc *Nkfl_EntryProcPtr;

#ifdef _cplusplus
}
#endif

#elif defined(__APPLE__)

	#if defined(__OBJC__)
		#define	EXTERN_C	
	#else
		#define EXTERN_C	extern "C"
	#endif

	EXTERN_C unsigned long Nkfl_Entry(unsigned long ulCommand, void* pParam );
	typedef unsigned long Nkfl_EntryProc( unsigned long ulCommand, void* pParam );
	typedef Nkfl_EntryProc *Nkfl_EntryProcPtr;

#endif//_WIN32

///////////////////////////////////////////////////////////
#if defined(__APPLE__)
	typedef Rect RECT;
	#ifndef MAX_PATH
		#define MAX_PATH PATH_MAX
	#endif
#endif//__APPLE__

typedef	void*	NkflPtr;

///////////////////////////////////////////////////////////
//	Definition Callback function.
//
#if defined(_WIN32)
	typedef unsigned long WINAPI NkflProgressProc( unsigned long ulDone, unsigned long ulTotal, void* pProgressParam );
	typedef NkflProgressProc* NkflProgressProcPtr;
#elif defined(__APPLE__)
	typedef unsigned long NkflProgressProc( unsigned long ulDone, unsigned long ulTotal, void* pProgressParam );
	typedef NkflProgressProc* NkflProgressProcPtr;
#endif//_WIN32


///////////////////////////////////////////////////////////

typedef	void*	NkflPtr;




/*********************************************************/
//	Structures.
/*********************************************************/
///////////////////////////////////////////////////////////
//	NkflLibraryParam
//		It's for kNkfl_Cmd_OpenLibrary
//
typedef struct tagNkflLibraryParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long 	ulVersion;				//	Version
	unsigned long	ulVMMemorySize;			//	Size of vertual memory
	NkflPtr*		pNkflPtr;				//  Pointer of StratoObject
	unsigned char	VMFileInfo[ MAX_PATH ];	//	Swap file info
#if defined(_WIN32)
	unsigned char	DefProfPath[ MAX_PATH ];
#endif//_WIN32
} NkflLibraryParam, *NkflLibraryPtr;

///////////////////////////////////////////////////////////
//	NkflSessionParam
//		It's for kNkfl_Cmd_OpenSession and kNkfl_Cmd_CloseSession
//
typedef struct tagNkflSessionParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulType;					//	File type (eNkflSource)
	void*			pFileInfo;				//	File Name or file Memory 
	unsigned long	ulFileSize;				//	Memory size
    bool            bImageLoadSkip;         //  ImageLoad Skip Flag
} NkflSessionParam, *NkflSessionPtr;

///////////////////////////////////////////////////////////
//	NkflFileInfoParam
//		It's for kNkfl_Cmd_GetImageInfo
//
typedef struct tagNkflFileInfoParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulFormat;				//	File format (eNkflFormat)
} NkflFileInfoParam, *NkflFileInfoPtr;


///////////////////////////////////////////////////////////
//	NkflImageInfoParam
//		It's for kNkfl_Cmd_GetImageInfo, kNkfl_Cmd_GetOriginalInfo and kNkfl_Cmd_GetThumbnailInfo
//
typedef struct tagNkflImageInfoParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulImageID;				//	Thumbnail ID
	unsigned long	ulWidth;				//	Image width
	unsigned long	ulHeight;				//	Image height
	unsigned long	ulByteDepth;			//	Image length
	unsigned long	ulColor;				//	Color (eNkflColor)
	unsigned long	ulOrientation;			//	Flip/Rotation (eNkflOrientation)
	double			dbResolution;			//	Resolution(for kNkfl_Cmd_GetImageInfo)
} NkflImageInfoParam, *NkflImageInfoPtr;

///////////////////////////////////////////////////////////
//	NkflImageParam
//		It's for kNkfl_Cmd_GetImageData and kNkfl_Cmd_GetThumbnailData
//
typedef struct tagNkflImageParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulImageID;				//	Thumbnail ID
	RECT			rectArea;				//	Read Image rect
	unsigned long	ulDataSize;				//	Buffer size
	void*			pData;					//	Image buffer
	NkflProgressProc* pFunc;				//	Pointer of callback func
	void*			pProgressParam;			//	private data for callback func
} NkflImageParam, *NkflImagePtr;

///////////////////////////////////////////////////////////
//	NkflTagInfoParam
//		It's for kNkfl_Cmd_GetTagInfo
//
typedef struct tagNkflTagInfoParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulCount;				//	Tag Count
	unsigned long*	pulTagList;				//	Tag List
} NkflTagInfoParam, *NkflTagInfoPtr;

///////////////////////////////////////////////////////////
//	NkflTagDataParam
//		It's for kNkfl_Cmd_GetTagData
//
typedef struct tagNkflTagDataParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulTagID;				//	Tag ID (eNkflTag)
	unsigned long	ulTagType;				//	Tag Type (eNkflTagType)
	unsigned long	ulTagValue;				//	Tag Value
	unsigned long	ulTagLength;			//	Tag Length
	void*			pData;					//  Tag Data
} NkflTagDataParam, *NkflTagDataPtr;

/////////////////////////////////////////////////////////////
//	NkflTagParam_BitsPerSample
//		It's for kNkfl_Tag_BitsPerSample
//
typedef struct tagNkflTagParam_BitsPerSample
{
	unsigned long	ulSize;					//Size of Structure
	unsigned long	ulBitsPerSample[4];		//Bits per each component
}NkflTagParam_BitsPerSample,*NkflTagParam_BitsPerSamplePtr;

///////////////////////////////////////////////////////////
//	NkflTagParam_DateTime
//		It's for kNkfl_Tag_DateTime
//
typedef struct tagNkflTagParam_DateTime
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulYear;					//	Shot year
	unsigned long	ulMonth;				//	Shot month
	unsigned long	ulDay;					//	Shot day
	unsigned long	ulHour;					//	Shot hour
	unsigned long	ulMinute;				//	Shot minute
	double			dbSecond;				//	Shot second including subsecond
} NkflTagParam_DateTime, *NkflTagParam_DateTimePtr;

///////////////////////////////////////////////////////////
//	NkflTagParam_LensInfo
//		It's for kNkfl_Tag_LensInfo
//
typedef struct tagNkflTagParam_LensInfo
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulWideLength;			//	Focal length at minimum zoom
	unsigned long	ulTeleLength;			//	Focal length at maximum zoom
											//  When non-zoom lens, this is 0
	double			dbWideMaxAperture;		//	Maximum aperture at minimum zoom
	double			dbTeleMaxAperture;		//	Maximum aperture at maximum zoom
											//  When Max aperture is not varied, this is 0.0
} NkflLensInfo, *NkflLensInfoPtr;

////////////////////////////////////////////////////////////
//		NkflLensType
//		This structure is for kNkfl_Tag_LensType
//
typedef struct tagNkflTagParamLensType
{
	bool			bIsCPU;					// true = CPU(Nikon Lens), false = non-CPU or the other lenses.
	bool			bIsActiveDType;			// true = bIsDType is active
	bool			bIsDType;				// true = D type, false = conventional

	//for supporting
	bool			bIsGLense;			//	true:G-Lense		false:Normal
	bool			bIsAntiVibration;	//  true:Anti-Vibration	false:Normal

	bool			bIsVLense;			//	true:V-Lense		false:Normal
	bool			bIsFMountAdapter;	//	true:FMountAdapter	false:Normal
	bool			Reserved;			//
	bool			bIsELense;			//	true:E-Lense		false:Normal
	bool			bIsSTMLense;		//	true:STM-Lense		false:Normal
} NkflLensType,*NkflLensTypePtr;

////////////////////////////////////////////////////////////
//		NkflTagParam_SkinSoftening
//		This structure is for kNkfl_Tag_SkinSoftening
//
typedef struct tagNkflTagParamSkinSoftening
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSkinSoftening;		//	SkinSoftening setting (eNkflSkinSoftening)
} NkflTagParam_SkinSoftening, *NkflTagParam_SkinSofteningPtr;

////////////////////////////////////////////////////////////
//		NkflTagParam_PortraitImpressionBalance
//		This structure is for kNkfl_Tag_PortraitImpressionBalance
//
typedef struct tagNkflTagParamPortraitImpressionBalance
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulHue;
	unsigned long	ulBrightness;
} NkflTagParam_PortraitImpressionBalance, *NkflTagParam_PortraitImpressionBalancePtr;

////////////////////////////////////////////////////////////
//		NkflTagParam_PixelShiftNoiseReduction
//		This structure is for kNkfl_Tag_PixelShiftNoiseReduction
//
typedef struct tagNkflTagParamPixelShiftNoiseReduction
{
	unsigned long	ulSize;					//	Size of structure
	bool			bResolutionPriority;
} NkflRawDevelopment_PixelShiftNoiseReduction, *NkflRawDevelopment_PixelShiftNoiseReductionPtr;

////////////////////////////////////////////////////////////
//		NkflTagParam_FilmGrain
//		This structure is for kNkfl_Tag_FilmGrain
//
typedef struct tagNkflTagParamFilmGrain
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulFilmGrainIntensity;
	unsigned long	ulFilmGrainSize;
} NkflTagParam_FilmGrain, * NkflTagParam_FilmGrainPtr;

///////////////////////////////////////////////////////////
//	NkflTagParam_GPSPosition
//		It's for kNkfl_Tag_GPSLatitude and kNkfl_Tag_GPSLongitude
//
typedef struct tagNkflTagParam_GPSPosition
{
	unsigned long	ulSize;					//Size of Structure
	double			dbDegrees;			
	double			dbMinutes;
	double			dbSeconds;
}NkflTagParam_GPSPosition, *NkflTagParam_GPSPositionPtr;

///////////////////////////////////////////////////////////
//	NkflTagParam_GPSTimeStamp
//		It's for kNkfl_Tag_GPSTimeStamp
//
typedef struct tagNkflTagParam_GPSTimeStamp
{
	unsigned long	ulSize;					//Size of Structure
	unsigned long	ulHours;			
	unsigned long	ulMinutes;
	unsigned long	ulSeconds;
}NkflTagParam_GPSTimeStamp, *NkflTagParam_GPSTimeStampPtr;

//#####################################################################################
////////////////////////////////////////////////////////////
// NkflSplinePoint
//	It's for tagNkflTagParam_UserDefinedCurve structure
//
typedef struct tagNkflSplinePoint
{
	unsigned char	x;						//	Spline Point X ( 0 - 255 )
	unsigned char	y;						//	Spline Point Y ( 0 - 255 )
} NkflSplinePoint;
//#####################################################################################

//#####################################################################################
////////////////////////////////////////////////////////////
//  NkflTagParam_UserDefinedCurve
//		It's for kNkfl_Tag_NkUserDefinedCurve
//
typedef struct tagNkflTagParam_UserDefinedCurve
{
	unsigned long	ulSize;					//The size of this structure
	unsigned char	iID[2];					//	0x49, 0x5F
	unsigned char	iInputMin;				//	(Black Point)
	unsigned char	iInputMax;				//	(White Point)
	unsigned char	iOutputMin;
	unsigned char	iOutputMax;
	unsigned char	iGammaInteger;			//	integer portion ( 0 - 20 )
	unsigned char	iGammaFractional;		//	fractional portion ( 0 - 100 )
	unsigned char	iSplinePointNum;		//	Number of Spline Points ( 2 - 20 )
	NkflSplinePoint	SplinePoint[20];
	unsigned char	Reserved[15];
	unsigned char	LutData[2048];
} NkflTagParam_UserDefinedCurve,*NkflTagParam_UserDefinedCurvePtr;
//#####################################################################################

//#####################################################################################
////////////////////////////////////////////////////////////
//  NkflTagParam_WBMode
//		It's for kNkfl_Tag_NkWhiteBalance
//
typedef struct tagNkflTagParam_WBMode
{
	unsigned long	ulSize;					// size of this structure
	unsigned long	ulWBMode;				// WhilteBalance (eNkflWhiteBalance)
	unsigned long	ulColorTemperature;		// ulWBMode is kNkfl_WhiteBalance_ColorTemperature, set color temperature to this parameter
} NkflTagParam_WBMode, *NkflTagParam_WBModePtr;
//#####################################################################################

//#####################################################################################
////////////////////////////////////////////////////////////
//  NkflTagParam_ColorMatrix
//		It's for kNkfl_Tag_NkColorMatrixModulus
//
typedef struct tagNkflTagParam_ColorMatrix
{
	unsigned long	ulSize;					//	size of this structure
	double			dbMkr2;
	double			dbMkb2;
	double			dbMkr3;
	double			dbMkb3;
} NkflTagParam_ColorMatrix, *NkflTagParam_ColorMatrixPtr;
//#####################################################################################

///////////////////////////////////////////////////////////
//	NkflTagStringInfoParam
//		It's for kNkfl_Cmd_GetTagStringInfo
//
typedef struct tagNkflTagStringInfoParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulLines;				//	Line count
	unsigned long	ulColumns;				//	Column count
} NkflTagStringInfoParam, *NkflTagStringInfoPtr;

///////////////////////////////////////////////////////////
//	NkflTagStringParam
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflTagStringParam
{
	unsigned long	ulSize;					//	Size of structure
	unsigned long	ulSessionID;			//	ID value of session
	unsigned long	ulLines;				//	Line number
	unsigned long	ulColumns;				//	Column number
	unsigned long	ulStringLength;			// 	String length
	unsigned long	ulLayoutLength;			//	Max string length in column
	void*			pData;					//	Data buffer
} NkflTagStringParam, *NkflTagStringPtr;


///////////////////////////////////////////////////////////
//	NkflColorTempRange
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflColorTempRangeParam
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulMWB;
	unsigned long ulDefalut;
	unsigned long ulMinColorTemp;
	unsigned long ulMaxColorTemp;
} NkflColorTempRangeParam, *NkflColorTempRangeParamPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopmentInfo
//
typedef struct tagNkflRawDevelopmentInfo
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulRawDevelopmentInfo;
} NkflRawDevelopmentInfo, *NkflRawDevelopmentInfoPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopmentParam
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopmentParam
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulRawDevelopment;
	void* pData;
} NkflRawDevelopmentParam, *NkflRawDevelopmentParamPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_RawParameterSet
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_RawParameterSet
{
	unsigned long ulSize;
	unsigned long ulParamterSet;
} NkflRawDevelopment_RawParameterSet, *NkflRawDevelopment_RawParameterSetPtr;

typedef struct tagNkflRawDevelopment_RawQuality
{
	unsigned long ulSize;
	unsigned long ulQuality;
} NkflRawDevelopment_RawQuality, *NkflRawDevelopment_RawQualityPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_ExpComp
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_ExpComp
{
	unsigned long ulSize;
	double dbExpComp;
} NkflRawDevelopment_ExpComp, *NkflRawDevelopment_ExpCompPtr;

///////////////////////////////////////////////////////////
//	NkflRGB
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRGB
{
	unsigned long ulR;
	unsigned long ulG;
	unsigned long ulB;
} NkflRGB, *NkflRGBPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_WBAdj
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_WBAdj
{
	unsigned long ulSize;
	unsigned long ulMWB;
	long lColorTemp;
	NkflRGB rgb;
} NkflRawDevelopment_WBAdj, *NkflRawDevelopment_WBAdjPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_Tint
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_Tint
{
	unsigned long ulSize;
	double lfTint; // -12 - 12
} NkflRawDevelopment_Tint, *NkflRawDevelopment_TintPtr;


///////////////////////////////////////////////////////////
//	NkflRawDevelopment_NR
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_NR
{
	unsigned long ulSize;
	unsigned long ulNRType;
} NkflRawDevelopment_NR, *NkflRawDevelopment_NRPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_ColorMode
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_ColorMode
{
	unsigned long ulSize;
	unsigned long ulColorMode;
} NkflRawDevelopment_ColorMode, *NkflRawDevelopment_ColorModePtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_Sharpness
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_Sharpness
{
	unsigned long ulSize;
	unsigned long ulSharpness;
} NkflRawDevelopment_Sharpness, *NkflRawDevelopment_SharpnessPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_ToneComp
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_ToneComp
{
	unsigned long ulSize;
	unsigned long ulToneComp;
} NkflRawDevelopment_ToneComp, *NkflRawDevelopment_ToneCompPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_Saturation
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_Saturation
{
	unsigned long ulSize;
	unsigned long ulSaturation;
} NkflRawDevelopment_Saturation, *NkflRawDevelopment_SaturationPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_HueAdj
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_HueAdj
{
	unsigned long ulSize;
	long ulHueAdj;
} NkflRawDevelopment_HueAdj, *NkflRawDevelopment_HueAdjPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_FilterEffect
//		It's for kNkfl_Cmd_GetTagString
//
typedef struct tagNkflRawDevelopment_FilterEffect
{
	unsigned long ulSize;
	unsigned long ulFilterEffect;
} NkflRawDevelopment_FilterEffect, *NkflRawDevelopment_FilterEffectPtr;

///////////////////////////////////////////////////////////
//	NkflFlexibleColorParams
//
typedef struct tagNkflFlexibleColorParams
{
    double dbContrast;
    double dbHighlight;
    double dbShadow;
    double dbWhiteLevel;
    double dbBlackLevel;
    double dbSaturation;
    double dbColorBlender[8][3];
    double dbColorGrading[3][3];
    double dbBlending;
    double dbBalance;
} NkflFlexibleColorParams, * NkflFlexibleColorParamsPtr;

	///////////////////////////////////////////////////////////
//	NkflRawDevelopment_PictureControl
//
typedef struct tagNkflRawDevelopment_PictureControl
{
	unsigned long ulSize;
	unsigned long ulPictureControl;
	bool bApplyQuickAdjust;
	double dbQuickAdjust;
	bool bSharpessAuto;
	double dbSharpness;
	bool bClarityAuto;
	double dbClarity;
	bool bUserDefinedCurve;
	bool bContrastAuto;
	double dbContrast;
	double dbBrightness;
	double dbHighlight;
	double dbShadow;
	bool bSaturationAuto;
	double dbSaturation;
	double dbHue;
	long lFilter;
	unsigned long lToning;
	double dbToningIntensity;
	double dbApplyLevel;
	bool bApplyQuickSharp;
	bool bQuickSharpAuto;
	double dbQuickSharp;
	double dbMiddleRangeSharp;
	NkflFlexibleColorParams flc_dbParams;
} NkflRawDevelopment_PictureControl, *NkflRawDevelopment_PictureControlPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_ActiveDLighting
//
typedef struct tagNkflRawDevelopment_ActiveDLighting
{
	unsigned long ulSize;
	unsigned long ulActiveDLighting;
} NkflRawDevelopment_ActiveDLighting, *NkflRawDevelopment_ActiveDLightingPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_SkinSoftening
//
typedef struct tagNkflRawDevelopment_SkinSoftening
{
	unsigned long ulSize;
	unsigned long ulSkinSoftening;
} NkflRawDevelopment_SkinSoftening, *NkflRawDevelopment_SkinSofteningPtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_PortraitImpressionBalance
//
typedef struct tagNkflRawDevelopment_PortraitImpressionBalance
{
	unsigned long ulSize;
	double dbHue;
	double dbBrightness;
} NkflRawDevelopment_PortraitImpressionBalance, *NkflRawDevelopment_PortraitImpressionBalancePtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_Dehaze
//
typedef struct tagNkflRawDevelopment_Dehaze
{
	unsigned long ulSize;
	unsigned long ulDehaze;
} NkflRawDevelopment_Dehaze, * NkflRawDevelopment_DehazePtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopment_FilmGrain
//
typedef struct tagNkflRawDevelopment_FilmGrain
{
	unsigned long ulSize;
	unsigned long ulFilmGrainIntensity;
	unsigned long ulFilmGrainSize;
} NkflRawDevelopment_FilmGrain, * NkflRawDevelopment_FilmGrainPtr;

///////////////////////////////////////////////////////////
//	NkflOutputDeviceProfile
//
typedef struct tagNkflOutputDeviceProfile
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned char OutputDeviceProfile[MAX_PATH];//UTF8
} NkflOutputDeviceProfile, *NkflOutputDeviceProfilePtr;

///////////////////////////////////////////////////////////
//	NkflOutputProfileParam
//
typedef struct tagNkflOutputProfileParam
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulRenderingIntent;
	unsigned char OutputProfile[MAX_PATH];
} NkflOutputProfileParam, *NkflOutputProfileParamPtr;

///////////////////////////////////////////////////////////
//	NkflDynamicRange
//
typedef struct tagNkflDynamicRange
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulDynamicRange;
} NkflDynamicRange, *NkflDynamicRangePtr;

///////////////////////////////////////////////////////////
//	NkflEditState
//
typedef struct tagNkflEditState
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulEditState;
} NkflEditState, *NkflEditStatePtr;

///////////////////////////////////////////////////////////
//	NkflFlexibleColorRange
//
typedef struct tagNkflFlexibleColorRange
{
	double dbMinFlexibleColorContrast;
	double dbMaxFlexibleColorContrast;
	double dbStepFlexibleColorContrast;
	double dbMinFlexibleColorHighlight;
	double dbMaxFlexibleColorHighlight;
	double dbStepFlexibleColorHighlight;
	double dbMinFlexibleColorShadow;
	double dbMaxFlexibleColorShadow;
	double dbStepFlexibleColorShadow;
	double dbMinFlexibleColorWhiteLevel;
	double dbMaxFlexibleColorWhiteLevel;
	double dbStepFlexibleColorWhiteLevel;
	double dbMinFlexibleColorBlackLevel;
	double dbMaxFlexibleColorBlackLevel;
	double dbStepFlexibleColorBlackLevel;
	double dbMinFlexibleColorSaturation;
	double dbMaxFlexibleColorSaturation;
	double dbStepFlexibleColorSaturation;
	double dbMinFlexibleColorBlender[8][3];
	double dbMaxFlexibleColorBlender[8][3];
	double dbStepFlexibleColorBlender[8][3];
	double dbMinFlexibleColorGrading[3][3];
	double dbMaxFlexibleColorGrading[3][3];
	double dbStepFlexibleColorGrading[3][3];
	double dbMinFlexibleColorBlending;
	double dbMaxFlexibleColorBlending;
	double dbStepFlexibleColorBlending;
	double dbMinFlexibleColorBalance;
	double dbMaxFlexibleColorBalance;
	double dbStepFlexibleColorBalance;
} NkflFlexibleColorRange, * NkflFlexibleColorRangePtr;

///////////////////////////////////////////////////////////
//	NkflRawDevelopmentRange
//
typedef struct tagNkflRawDevelopmentRange
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	double dbMinQuickAdjust;
	double dbMaxQuickAdjust;
	double dbStepQuickAdjust;
	double dbMinSharpening;
	double dbMaxSharpening;
	double dbStepSharpening;
	double dbMinClarity;
	double dbMaxClarity;
	double dbStepClarity;
	double dbMinContrast;
	double dbMaxContrast;
	double dbStepContrast;
	double dbMinBrightness;
	double dbMaxBrightness;
	double dbStepBrightness;
	double dbMinHighlight;
	double dbMaxHighlight;
	double dbStepHighlight;
	double dbMinShadow;
	double dbMaxShadow;
	double dbStepShadow;
	double dbMinSaturation;
	double dbMaxSaturation;
	double dbStepSaturation;
	double dbMinHue;
	double dbMaxHue;
	double dbStepHue;
	double dbMinToningIntensity;
	double dbMaxToningIntensity;
	double dbStepToningIntensity;
	double dbMinApplyLevel;
	double dbMaxApplyLevel;
	double dbStepApplyLevel;
	double dbMinQuickSharp;
	double dbMaxQuickSharp;
	double dbStepQuickSharp;
	double dbMinMiddleRangeSharp;
	double dbMaxMiddleRangeSharp;
	double dbStepMiddleRangeSharp;
	NkflFlexibleColorRange flc_dbRanges;
} NkflRawDevelopmentRange, *NkflRawDevelopmentRangePtr;

///////////////////////////////////////////////////////////
//	NkflColorProcess
//
typedef struct tagNkflColorProcess
{
	unsigned long ulSize;
	unsigned long ulSessionID;
	unsigned long ulColorProcess;
} NkflColorProcess, *NkflColorProcessPtr;

typedef struct tagNkflPicConListItem{
	unsigned long	ulID;
}NkflPicConListItem;

///////////////////////////////////////////////////////////
//	NkflPictureControlList
//
typedef struct tagNkflPictureControlList
{
	unsigned long	ulSize;
	unsigned long	ulSessionID;
	unsigned long		ulListCount;				//	List Count
	NkflPicConListItem*	pulListItems;				//	Pointer of NkflPicConListItem List
} NkflPictureControlList, *NkflPictureControlListPtr;

///////////////////////////////////////////////////////////
//	NkflPictureControlVersion
//
typedef struct tagNkflPictureControlVersion
{
	unsigned long	ulSize;
	unsigned long	ulSessionID;
	unsigned long	ulLatestVersion;				//	Version of the picture control at latest applicable.
	unsigned long	ulModifiedVersion;				//	Version of the picture control at (current) edited.
	unsigned long	ulRecordedVersion;				//	Version of the picture control at the time of shooting.
} NkflPictureControlVersion, *NkflPictureControlVersionPtr;

///////////////////////////////////////////////////////////
//	NkflDevelopColorMode
//  SDK-330
typedef struct tagNkflDevelopColorMode
{
	unsigned long	ulSize;
			 long	lDevelopColorMode;
} NkflDevelopColorMode, *NkflDevelopColorModePtr;

///////////////////////////////////////////////////////////
//	NkflDetailedError
//
#if __BIG_ENDIAN__
typedef struct NkflDetailedError
{
	unsigned int filler;
	unsigned short detailedCode;
	unsigned short errCode;
}
NkflDetailedError;
#else
typedef struct NkflDetailedError
{
	unsigned short errCode;
	unsigned short detailedCode;
	unsigned int filler;
}
NkflDetailedError;
#endif

/*********************************************************/
//	Enumlation values.
/*********************************************************/
///////////////////////////////////////////////////////////
//	eNkflCommand
//
enum eNkflCommand
{
	kNkfl_Cmd_OpenLibrary				= 0x0001,
	kNkfl_Cmd_CloseLibrary				= 0x0002,
	kNkfl_Cmd_OpenSession				= 0x0003,
	kNkfl_Cmd_CloseSession				= 0x0004,
	kNkfl_Cmd_GetFileInfo				= 0x0005,
	kNkfl_Cmd_GetOutputProfile			= 0x0016,
	kNkfl_Cmd_GetOutputProfile_UTF8		= 0x0017,// SDK-319: Added for Win
	kNkfl_Cmd_SetOutputProfile			= 0x0116,
	kNkfl_Cmd_SetOutputProfile_UTF8		= 0x0117,// SDK-319: Added for Win
	kNkfl_Cmd_GetImageInfo				= 0x0011,
	kNkfl_Cmd_SetImageInfo				= 0x0111,
	kNkfl_Cmd_GetRawDevelopmentInfo		= 0x0010,
	kNkfl_Cmd_RawDevelopment			= 0x0110,
	kNkfl_Cmd_GetRawDevelopmentParam	= 0x0210,
	kNkfl_Cmd_GetRawDevelopmentRange	= 0x0310,
	kNkfl_Cmd_GetImageData				= 0x0012,
	kNkfl_Cmd_GetThumbnailCount			= 0x0025,
	kNkfl_Cmd_GetThumbnailInfo			= 0x0021,
	kNkfl_Cmd_SetThumbnailInfo			= 0x0121,
	kNkfl_Cmd_GetThumbnailData			= 0x0022,
	kNkfl_Cmd_GetOriginalInfo			= 0x0031,
	kNkfl_Cmd_GetTagInfo				= 0x0051,
	kNkfl_Cmd_GetTagData				= 0x0052,
	kNkfl_Cmd_GetTagStringInfo			= 0x0041,
	kNkfl_Cmd_GetTagString				= 0x0042,
	kNkfl_Cmd_GetColorTempRange			= 0x0018,
	kNkfl_Cmd_GetEditState				= 0x0060,
	kNkfl_Cmd_GetColorProcess			= 0x0070,
	kNkfl_Cmd_SetColorProcess			= 0x0170,
	kNkfl_Cmd_GetPictureControlList		= 0x0080,
	kNkfl_Cmd_GetPictureControlVersion	= 0x0090,
	kNkfl_Cmd_GetDevelopColorMode		= 0x0100,// SDK-330
	kNkfl_Cmd_SetDevelopColorMode		= 0x0101,// SDK-330
	kNkfl_Cmd_GetOutputDeviceProfile	= 0x0400,// SDK-331
	kNkfl_Cmd_SetOutputDeviceProfile	= 0x0401,// SDK-331
	kNkfl_Cmd_GetDynamicRange,
	kNkfl_Cmd_SetDynamicRange
};

///////////////////////////////////////////////////////////
//	eNkflSource
//
enum eNkflSource
{
	kNkfl_Source_FileName				= 0x0001,
	kNkfl_Source_FSSpec					= 0x0002,
	kNkfl_Source_Memory					= 0x0004,
	kNkfl_Source_FileName_UTF8			= 0x0008,// SDK-319: Added for Win  
};

///////////////////////////////////////////////////////////
//	eNkflFormat
//
enum eNkflFormat
{
	kNkfl_Format_None					= 0x000000,
	kNkfl_Format_JPEG					= 0x000020,
	kNkfl_Format_TIFF					= 0x000001,
	kNkfl_Format_NEF					= 0x100000,
	kNkfl_Format_NRW					= 0x200000,
	kNkfl_Format_HEIF					= 0x000030
};

///////////////////////////////////////////////////////////
//	eNkflColor
//
enum eNkflColor
{
	kNkfl_Color_Gray					= 0x0002,
	kNkfl_Color_RGB_Gray				= 0x0003,	// For 3 plane GrayScale images
	kNkfl_Color_CMYK_Gray				= 0x0004,   // support only reading
	kNkfl_Color_RGB						= 0x0020,   
	kNkfl_Color_CMYK					= 0x0022,   // support only reading
	kNkfl_Color_Lch						= 0x0023,   // not support
	kNkfl_Color_Lab						= 0x0024    // not support
};

///////////////////////////////////////////////////////////
//	eNkflToneMode
//
enum eNkflToneMode
{
	kNkfl_ToneMode_SDR,
	kNkfl_ToneMode_NLog,
	kNkfl_ToneMode_HLG,
	kNkfl_ToneMode_PQ
};

///////////////////////////////////////////////////////////
//	eNkflDynamicRange
//
enum eNkflDynamicRange
{
	kNkfl_DynamicRange_SDR,
	kNkfl_DynamicRange_HDR
};

///////////////////////////////////////////////////////////
// eNkflRawDevelopment
//
enum eNkflRawDevelopment
{
	kNkfl_RawDevelopment_RawParameterSet = 0x00000001,
	kNkfl_RawDevelopment_RawQuality = 0x00000002,
	kNkfl_RawDevelopment_ExpComp = 0x00000004,
	kNkfl_RawDevelopment_WBAdjustment = 0x00000008,
	kNkfl_RawDevelopment_Tint = 0x00000010,
	kNkfl_RawDevelopment_NR = 0x00000020,
	kNkfl_RawDevelopment_PictureControl = 0x00000040,
	kNkfl_RawDevelopment_ColorMode = 0x00000080,
	kNkfl_RawDevelopment_Sharpness = 0x00000100,
	kNkfl_RawDevelopment_ToneComp = 0x00000200,
	kNkfl_RawDevelopment_Saturation = 0x00000400,
	kNkfl_RawDevelopment_HueAdjustment = 0x00000800,
	kNkfl_RawDevelopment_FilterEffect = 0x00001000,
	kNkfl_RawDevelopment_ActiveDLighting = 0x00002000,
	kNkfl_RawDevelopment_SkinSoftening = 0x00004000,
	kNkfl_RawDevelopment_PortraitImpressionBalance = 0x00008000,
	kNkfl_RawDevelopment_PictureControlAsShot = 0x00010000,
	kNkfl_RawDevelopment_PixelShiftNoiseReduction = 0x00020000,
	kNkfl_RawDevelopment_Dehaze = 0x00040000,
	kNkfl_RawDevelopment_FilmGrain = 0x00080000
};

///////////////////////////////////////////////////////////
// eNkflRawParameterSet
//
enum eNkflRawParameterSet
{
	kNkfl_RawParameterSet_AsShot			= 0x0001,
	kNkfl_RawParameterSet_LastSaveSetting	= 0x0002
};

///////////////////////////////////////////////////////////
// eNkflRawQuality
//
enum eNkflRawQuality
{
	kNkfl_RawQuality_High			= 0x0001,
	kNkfl_RawQuality_Low			= 0x0002,
	kNkfl_RawQuality_LowResolution	= 0x0003
};

///////////////////////////////////////////////////////////
// 
enum eNkflWB
{
	kNkfl_WB_AsShot				= 0x0001,
	kNkfl_WB_GrayPoint			= 0x0002,
	kNkfl_WB_Auto				= 0x1000,
	kNkfl_WB_Auto0				= 0x0003,
	kNkfl_WB_Auto1				= 0x0004,
	kNkfl_WB_Auto2				= 0x0005,
	kNkfl_WB_NaturalLightAuto	= 0x0006,
	kNkfl_WB_Incandescent		= 0x0100,
	kNkfl_WB_Flourescent		= 0x1002,       // Flourescent = HCFFlourescent
	kNkfl_WB_HCFlourescent		= 0x0400,
	kNkfl_WB_DirectSunLight		= 0x0200,
	kNkfl_WB_Flash				= 0x0500,
	kNkfl_WB_Cloudy				= 0x0202,
	kNkfl_WB_Shade				= 0x0201,
	kNkfl_WB_Underwater			= 0x0600
};

enum eNkflNR
{
	kNkfl_NR_AsShot	= 1,
	kNkfl_NR_OFF	= 0,
	kNkfl_NR_Normal	= 2,
	kNkfl_NR_High	= 3,
	kNkfl_NR_Low	= 4
};

enum eNkflPictureControl
{
	kNkfl_PictureControl_AsShot				= 0x0001,
	kNkfl_PictureControl_Standard			= 0x0002,
	kNkfl_PictureControl_Neutral			= 0x0003,
	kNkfl_PictureControl_Vivid				= 0x0004,
	kNkfl_PictureControl_Monochrome			= 0x0005,
	kNkfl_PictureControl_Flat				= 0x0006,
	kNkfl_PictureControl_Auto				= 0x0007,
	kNkfl_PictureControl_Dream				= 0x0008,
	kNkfl_PictureControl_Morning			= 0x0009,
	kNkfl_PictureControl_Pop				= 0x000A,
	kNkfl_PictureControl_Sunday				= 0x000B,
	kNkfl_PictureControl_Somber				= 0x000C,
	kNkfl_PictureControl_Drama				= 0x000D,
	kNkfl_PictureControl_Silence			= 0x000E,
	kNkfl_PictureControl_Bleach				= 0x000F,
	kNkfl_PictureControl_Melancholic		= 0x0010,
	kNkfl_PictureControl_Pure				= 0x0011,
	kNkfl_PictureControl_Denim				= 0x0012,
	kNkfl_PictureControl_Toy				= 0x0013,
	kNkfl_PictureControl_Sepia				= 0x0014,
	kNkfl_PictureControl_Blue				= 0x0015,
	kNkfl_PictureControl_Red				= 0x0016,
	kNkfl_PictureControl_Pink				= 0x0017,
	kNkfl_PictureControl_Charcoal			= 0x0018,
	kNkfl_PictureControl_Graphite			= 0x0019,
	kNkfl_PictureControl_Binary				= 0x001A,
	kNkfl_PictureControl_Carbon				= 0x001B,
	kNkfl_PictureControl_D2XModeI			= 0x001C,
	kNkfl_PictureControl_D2XModeII			= 0x001D,
	kNkfl_PictureControl_D2XModeIII			= 0x001E,
	kNkfl_PictureControl_FlexibleColor		= 0x0020,
	kNkfl_OptionalPictureControl_Portrait	= 0x0486,
	kNkfl_OptionalPictureControl_Landscape	= 0x04c7,
	kNkfl_PictureControl_RichTonePortrait	= 0x0493,
	kNkfl_PictureControl_FlatMonochrome		= 0x0654,
	kNkfl_PictureControl_DeepToneMonochrome	= 0x0655,
	// Tone mode: HLG
	kNkfl_PictureControl_HLG_Standard		= 0x1001,
	kNkfl_PictureControl_HLG_Monochrome		= 0x1002,
	kNkfl_PictureControl_HLG_Flat			= 0x1003
};

enum eNkflColorMode
{
	kNkfl_ColorMode_AsShot		= 0x0001,
	kNkfl_ColorMode_ModeI		= 0x0002,
	kNkfl_ColorMode_ModeII		= 0x0003,
	kNkfl_ColorMode_ModeIII		= 0x0004,
	kNkfl_ColorMode_ModeIa		= 0x0005,
	kNkfl_ColorMode_ModeIIIa	= 0x0006,
	kNkfl_ColorMode_BW			= 0x0007
};

enum eNkflSharpness
{
	kNkfl_Sharpness_AsShot		= 0x0001,
	kNkfl_Sharpness_None		= 0xFFFF,
	kNkfl_Sharpness_Normal		= 0x0002,
	kNkfl_Sharpness_Low			= 0x0003,
	kNkfl_Sharpness_MediumLow	= 0x0004,
	kNkfl_Sharpness_MediumHigh	= 0x0005,
	kNkfl_Sharpness_High		= 0x0006
};

enum eNkflSaturation
{
	kNkfl_Saturation_AsShot		= 1,
	kNkfl_Saturation_Normal		= 2,
	kNkfl_Saturation_Moderate	= 3,
	kNkfl_Saturation_Enhanced	= 4
};

enum eNkflToneComp
{
	kNkfl_ToneComp_AsShot			= 0x0001,
	kNkfl_ToneComp_Normal			= 0x0002,
	kNkfl_ToneComp_LowContrast		= 0x0003,
	kNkfl_ToneComp_MediumLow		= 0x0004,
	kNkfl_ToneComp_MediumHigh		= 0x0005,
	kNkfl_ToneComp_HighContrast		= 0x0006,
	kNkfl_ToneComp_UserDefinedCurve	= 0x0007
};

enum eNkflFilterEffect
{
	kNkfl_FilterEffect_OFF		= 0,
	kNkfl_FilterEffect_Yellow	= 1,
	kNkfl_FilterEffect_Orange	= 2,
	kNkfl_FilterEffect_Red		= 3,
	kNkfl_FilterEffect_Green	= 4,
	kNkfl_FilterEffect_AsShot	= 0xFF
};

enum eNkflToning
{
	kNkfl_Toning_AsShot		= 0x0000,
	kNkfl_Toning_BW			= 0x0080,
	kNkfl_Toning_Sepia		= 0x0081,
	kNkfl_Toning_Cyanotype	= 0x0082,
	kNkfl_Toning_Red		= 0x0083,
	kNkfl_Toning_Yellow		= 0x0084,
	kNkfl_Toning_Green		= 0x0085,
	kNkfl_Toning_Turquoize	= 0x0086,
	kNkfl_Toning_Cyan		= 0x0087,
	kNkfl_Toning_Violet		= 0x0088,
	kNkfl_Toning_Magenta	= 0x0089
};

///////////////////////////////////////////////////////////
// eNkflActiveDLighting
enum eNkflActiveDLighting
{
	kNkfl_ActiveDLighting_AsShot = 1,
	kNkfl_ActiveDLighting_None,
	kNkfl_ActiveDLighting_Low,
	kNkfl_ActiveDLighting_Normal,
	kNkfl_ActiveDLighting_High,
	kNkfl_ActiveDLighting_ExtraHigh,
	kNkfl_ActiveDLighting_ExtraHigh2
};

///////////////////////////////////////////////////////////
// eNkflSkinSoftening
enum eNkflSkinSoftening
{
	kNkfl_SkinSoftening_Unchanged = 1,
	kNkfl_SkinSoftening_Off,
	kNkfl_SkinSoftening_Low,
	kNkfl_SkinSoftening_Normal,
	kNkfl_SkinSoftening_High
};

///////////////////////////////////////////////////////////
// eNkflEditState
enum eNkflEditState
{
	kNkfl_EditState_None				= 0,
	kNkfl_EditState_ApplicableEdit,
	kNkfl_EditState_InapplicableEdit
};

///////////////////////////////////////////////////////////
// eNkflColorProcess
enum eNkflColorProcess
{
	kNkfl_ColorProcess_Latest			= 0,
	kNkfl_ColorProcess_AppliedInCamera
};

// ======================= end ========================= //

///////////////////////////////////////////////////////////
//	eNkflTagType
//
enum eNkflTagType
{
	kNkfl_TagType_Byte					= 0x0001,
	kNkfl_TagType_String				= 0x0002,
	kNkfl_TagType_Long					= 0x0004,
	kNkfl_TagType_SLong					= 0x0009,
	kNkfl_TagType_Double				= 0x0008,
	kNkfl_TagType_Rational				= 0x0005,
	kNkfl_TagType_Undefined				= 0x0007,
	kNkfl_TagType_SRational				= 0x000A,
	kNkfl_TagType_Boolean				= 0x1001,
	kNkfl_TagType_DateTime				= 0x1002,
	kNkfl_TagType_LensInfo				= 0x8002,
//	kNkfl_TagType_UserDefinedCurve		= 0x8003, // not suppport
	kNkfl_TagType_GPSPosition			= 0x8004,
	kNkfl_TagType_GPSTimeStamp			= 0x8005,
	kNkfl_TagType_LensType				= 0x8006,
//	kNkfl_TagType_ColorMatrix			= 0x8009,// not support
	kNkfl_TagType_WBMode				= 0x800A,
	kNkfl_TagType_BitsPerSample			= 0x800B,
	kNkfl_TagType_SkinSoftening			= 0x800C,
	kNkfl_TagType_PortraitImpressionBalance = 0x800D,
	kNkfl_TagType_FilmGrain				= 0x800E
};

///////////////////////////////////////////////////////////
//	eNkflTag
//
enum eNkflTag
{
	kNkfl_Tag_ImageWidth				= 0x0100,
	kNkfl_Tag_ImageLength				= 0x0101,
	kNkfl_Tag_BitsPerSample				= 0x0102,
	kNkfl_Tag_PhotoMetric				= 0x0106,
//	kNkfl_Tag_Orientation				= 0x0112,		// One of eNkflOrientation, not support
	kNkfl_Tag_XResolution				= 0x011A,
	kNkfl_Tag_YResolution				= 0x011B,
	kNkfl_Tag_DateTime					= 0x0132,
	kNkfl_Tag_ImageDescription			= 0x010E,
	kNkfl_Tag_Make						= 0x010F,
	kNkfl_Tag_Model						= 0x0110,
	kNkfl_Tag_Software					= 0x0131,
	kNkfl_Tag_Artist					= 0x013B,

	kNkfl_Tag_CopyRight					= 0x8298,
	kNkfl_Tag_IPTC						= 0x83BB,
	kNkfl_Tag_ICCProfile				= 0x8773,
	kNkfl_Tag_UserComment				= 0x9286,
	kNkfl_Tag_ExifVersion				= 0x9000,
	kNkfl_Tag_ExposureTime				= 0x829A,
	kNkfl_Tag_FNumber					= 0x829D,
	kNkfl_Tag_ExposureProgram			= 0x8822,		// One of eNkflExposureMode
	kNkfl_Tag_ExposureBiasValue			= 0x9204,
	kNkfl_Tag_MeteringMode				= 0x9207,		// One of eNkflMeteringMode
	kNkfl_Tag_Flash						= 0x9209,
	kNkfl_Tag_FocalLength				= 0x920A,

	kNkfl_Tag_NkISOSensitivity			= 0x080002,		//	Nikon(D1)
	kNkfl_Tag_NkFileFormat				= 0x080004,		// One of eNkflFileFormat
	kNkfl_Tag_NkWhiteBalance			= 0x080005,		// One of eNkflWhiteBalance
	kNkfl_Tag_NkEdgeEnhancement			= 0x080006,		// One of eNkflEdgeEnhancement
	kNkfl_Tag_NkFocusMode				= 0x080007,		// One of eNkflFocusMode
	kNkfl_Tag_NkFlashSyncMode			= 0x080008,		// One of eNkflFlashSyncMode
	kNkfl_Tag_NkFlashAutoMode			= 0x080009,		// One of eNkflFlashAutoMode
	kNkfl_Tag_NkWBCompensation			= 0x08000B,
	kNkfl_Tag_NkFlexibleProgram			= 0x08000D,
	kNkfl_Tag_NkExposureDeviation		= 0x08000E,
	kNkfl_Tag_NkSensitivityMode			= 0x08000F,
	kNkfl_Tag_NkActiveDLighting			= 0x080022,
	kNkfl_Tag_NkPictureControlMode		= 0x080023,
	kNkfl_Tag_NkSkinSoftening			= 0x080057,
	kNkfl_Tag_NkToneMode				= 0x080059,
	kNkfl_Tag_NkPortraitImpressionBalanceAdjustment		= 0x08005A,
	kNkfl_Tag_NkNoiseReductionMode		= 0x080062,		// One of eNkflNoiseReductionMode
	kNkfl_Tag_NkDehaze					= 0x080063,		// OFF:0, Intensity:1 -9
	kNkfl_Tag_NkFilmGrain				= 0x08006B,
	kNkfl_Tag_NkBRTCNTCompensation		= 0x080080,		// One of eNkflBRTCNTCompensation
	kNkfl_Tag_NkGammaTable				= 0x080081,		// One of eNkflToneCompensation
	kNkfl_Tag_NkConverterLens			= 0x080082,		// One of eNkflBRTCNTConverterLens
	kNkfl_Tag_NkLensType				= 0x080083,
	kNkfl_Tag_NkLensInfo				= 0x080084,
	kNkfl_Tag_NkAFAreaMode				= 0x08008A,		// One of eNkflAFAreaMode
	kNkfl_Tag_NkAFPreferedArea			= 0x08008B,		// One of eNkflAFPreferedArea
	kNkfl_Tag_NkColorRecurrence			= 0x08008D,		
	kNkfl_Tag_NkColorAdjustment			= 0x080092,
	kNkfl_Tag_NkChromaAdjustment		= 0x080094,
	kNkfl_Tag_NkDateTimePrint			= 0x08009D,
	kNkfl_Tag_NkCPXPictureControl		= 0x0800BD,		// for NRW

	kNkfl_Tag_GPSLatitudeRef			= 0x030001,		// One of eNkflGPSPositionRef
	kNkfl_Tag_GPSLatitude				= 0x030002,
	kNkfl_Tag_GPSLongitudeRef			= 0x030003,		// One of eNkflGPSPositionRef
	kNkfl_Tag_GPSLongitude				= 0x030004,
	kNkfl_Tag_GPSAltitude				= 0x030006,
	kNkfl_Tag_GPSTimeStamp				= 0x030007,
	kNkfl_Tag_GPSSatellites				= 0x030008,
	kNkfl_Tag_GPSMapDatum				= 0x030012,

	kNkfl_Tag_None						= 0xffffffff
};

///////////////////////////////////////////////////////////
//	eNkflOrientation
//
enum eNkflOrientation
{
	kNkfl_Orientation_CW0				= 1,			// Image's top left is visual top left
	kNkfl_Orientation_FlippedCW0		= 2,			// Image's top left is visual top right
	kNkfl_Orientation_CW180				= 3,			// Image's top left is viaual bottom right
	kNkfl_Orientation_FlippedCW180		= 4,			// Image's top left is viaual bottom left
	kNkfl_Orientation_FlippedCW270		= 5,			// Image's top left is viaual left top
	kNkfl_Orientation_CW270				= 6,			// Image's top left is viaual right top
	kNkfl_Orientation_FlippedCW90		= 7,			// Image's top left is viaual right bottom
	kNkfl_Orientation_CW90				= 8				// Image's top left is viaual left bottom
};

///////////////////////////////////////////////////////////
// eNkflPhotometric
//
enum eNkflPhotometric
{
	kNkfl_Photometric_WHITE0			= 0,			// WhiteIsZero. For bilevel and grayscale images:
	kNkfl_Photometric_BLACK0			= 1,			// BlackIsZero. For bilevel and grayscale images:
	kNkfl_Photometric_RGB				= 2,			// RGB
	kNkfl_Photometric_CMYK				= 5,			// CMYK
	kNkfl_Photometric_YCbCr				= 6,			// YCbCr
	kNkfl_Photometric_CFA				= 0x8023,		// CFA ( Color Filter Array )
	kNkfl_Photometric_LAB				= 8,			// CIE Lab
	kNkfl_Photometric_Palette			= 9				// Palette color
};

///////////////////////////////////////////////////////////
//	eNkflExposureMode
//
enum eNkflExposureMode
{
	kNkfl_ExposureMode_Undefined		= 0,			
	kNkfl_ExposureMode_Manual			= 1,			// Manual
	kNkfl_ExposureMode_Program			= 2,			// Program Auto
	kNkfl_ExposureMode_AperturePriority	= 3,			// Aperture Priority Auto
	kNkfl_ExposureMode_ShutterPriority	= 4,			// Shutter Priority Auto
	kNkfl_ExposureMode_CreativeProgram	= 5,			// Biased toward depth of field
	kNkfl_ExposureMode_ActionProgram	= 6,			// Biased toward fast shutter speed
	kNkfl_ExposureMode_PortraitMode		= 7,			// Portrait mode
	kNkfl_ExposureMode_LandscapeMode	= 8				// Landscape mode
};

///////////////////////////////////////////////////////////
//	eNkflMeteringMode
//
enum eNkflMeteringMode
{
	kNkfl_MeteringMode_Undefined		= 0,
	kNkfl_MeteringMode_Average			= 1,			// So far not used
	kNkfl_MeteringMode_CenterWeightedAverage	= 2,	// Center-weighted metering
	kNkfl_MeteringMode_Spot				= 3,			// Spot metering
	kNkfl_MeteringMode_MutiSpot			= 4,			// So far not used
	kNkfl_MeteringMode_Pattern			= 5,			// Color matrix metering
	kNkfl_MeteringMode_Patial			= 6				// So far not used	
};

///////////////////////////////////////////////////////////
//	eNkflFileFormat
//
enum eNkflFileFormat
{
	kNkfl_FileFormat_JPEG_Basic			= 0,			// JPEG-Basic
	kNkfl_FileFormat_JPEG_Normal		= 1,			// JPEG-Normal
	kNkfl_FileFormat_JPEG_Fine			= 2,			// JPEG-Fine
	kNkfl_FileFormat_TIFF_YCbCr			= 16,			// TIFF-YCbCr
	kNkfl_FileFormat_TIFF_RGB			= 17,			// TIFF-RGB
	kNkfl_FileFormat_NEF_RAW			= 32,			// NEF-RAW
	kNkfl_FileFormat_NEF_RGB			= 38,			// NEF-RBG
	kNkfl_FileFormat_NEF_COMP			= 39,			// Compression NEF
	kNkfl_FileFormat_NRW				= 64,
	kNkfl_FileFormat_HEIF_Basic,
	kNkfl_FileFormat_HEIF_Normal,
	kNkfl_FileFormat_HEIF_Fine,
};

///////////////////////////////////////////////////////////
//	eNkflWhiteBalance
//
enum eNkflWhiteBalance
{
	kNkfl_WhiteBalance_Auto				= 0x00,			// Auto
	kNkfl_WhiteBalance_Incandescent		= 0x01,			// Incandescent
	kNkfl_WhiteBalance_Fluorescent		= 0x02,			// Fluorescent
	kNkfl_WhiteBalance_Sunlight			= 0x03,			// Direct sunlight
	kNkfl_WhiteBalance_Flash			= 0x04,			// Flash
	kNkfl_WhiteBalance_Shade			= 0x05,			// Shade
	kNkfl_WhiteBalance_Overcast			= 0x06,			// Overcast, cloudy
	kNkfl_WhiteBalance_Preset			= 0x07,			// Preset white balance
	kNkfl_WhiteBalance_Preset1			= 0x17,			// Preset1 white balance
	kNkfl_WhiteBalance_Preset2			= 0x27,			// Preset2 white balance
	kNkfl_WhiteBalance_Preset3			= 0x37,			// Preset3 white balance
	kNkfl_WhiteBalance_Preset4			= 0x47,			// Preset3 white balance
	kNkfl_WhiteBalance_ColorTemperature	= 0x08,			// Color temperature
	kNkfl_WhiteBalance_AppCustom		= 0x09,			// Application custom
	kNkfl_WhiteBalance_Auto2			= 0x0A,			// Auto2
	kNkfl_WhiteBalance_Underwater		= 0x0B,			// Underwater
	kNkfl_WhiteBalance_Auto1			= 0x0C,			// Auto1
	kNkfl_WhiteBalance_Auto0			= 0x0D,			// Auto0
    kNkfl_WhiteBalance_NaturalLightAuto	= 0x0E,			// Natural light auto
};

///////////////////////////////////////////////////////////
//	eNkflEdgeEnhancement
//
enum eNkflEdgeEnhancement
{
	kNkfl_EdgeEnhancement_None			= 0,			// Sharpening-None
	kNkfl_EdgeEnhancement_Low			= 1,			// Sharpening-Low
	kNkfl_EdgeEnhancement_Normal		= 2,			// Sharpening-Normal, middle
	kNkfl_EdgeEnhancement_High			= 3,			// Sharpening-High
	kNkfl_EdgeEnhancement_MediumLow		= 4,			// Sharpening-Medium Low
	kNkfl_EdgeEnhancement_MediumHigh	= 5,			// Sharpening-Medium High
	kNkfl_EdgeEnhancement_Auto			= 9				// Sharpening-Auto
};

///////////////////////////////////////////////////////////
//	eNkflFocusMode
//
enum eNkflFocusMode
{
	kNkfl_FocusMode_Manual				= 0,			// Manual focus mode
	kNkfl_FocusMode_SingleAF			= 16,			// Single servo AF (focus priority)
	kNkfl_FocusMode_ContinuousAF		= 17,			// Continuous servo AF (release priority)
	kNkfl_FocusMode_AutoAF				= 18,			// Auto servo AF
	kNkfl_FocusMode_Preset				= 32
};

///////////////////////////////////////////////////////////
//	eNkflFlashSyncMode
//
enum eNkflFlashSyncMode
{
	kNkfl_FlashSync_Normal				= 0x00,			// Front-curtain sync
	kNkfl_FlashSync_Slow				= 0x01,			// Slow sync
	kNkfl_FlashSync_Rear				= 0x02,			// Rear-curtain sync
	kNkfl_FlashSync_RearSlow			= 0x03,			// Rear with slow sync
	kNkfl_FlashSync_Redeye				= 0x10,			// Red-eye reduction
	kNkfl_FlashSync_RedeyeSlow			= 0x11,			// Red-eye reduction with slow sync
	kNkfl_FlashSync_Off					= 0x20			// OFF
};

///////////////////////////////////////////////////////////
//	eNkflFlashAutoMode
//
enum eNkflFlashAutoMode
{
	kNkfl_FlashAuto_External			= 0,			// Non-TTL auto
	kNkfl_FlashAuto_Manual				= 1,			// Manual
	kNkfl_FlashAuto_FP					= 2,			// FP High-Speed Sync
	kNkfl_FlashAuto_NewTTL				= 3,			// New TTL
	kNkfl_FlashAuto_AA					= 4,			// AA
	kNkfl_FlashAuto_BuiltinTTL			= 5,			// inside SB TTL
	kNkfl_FlashAuto_BuiltinM			= 6,			// inside SB Manual
	kNkfl_FlashAuto_OptionalTTL			= 7,			// outside SB TTL
	kNkfl_FlashAuto_OptionalAA			= 8,			// outside SB AA
	kNkfl_FlashAuto_OptionalA			= 9,			// outside SB A
	kNkfl_FlashAuto_OptionalM			= 10,			// outside SB Manual
	kNkfl_FlashAuto_ComdrTTL			= 11,			// commander TTL
	kNkfl_FlashAuto_ComdrAA				= 12,			// commander AA
	kNkfl_FlashAuto_ComdrM				= 13,			// commander Manual
	kNkfl_FlashAuto_Optional			= 14,			// no comunication SB 
	kNkfl_FlashAuto_BuiltinRPT			= 15,			// inside SB Repeating
	kNkfl_FlashAuto_Comdr				= 16,			// commander
	kNkfl_FlashAuto_BuiltinTTLComdr		= 17,			// inside SB & commander
	kNkfl_FlashAuto_BuiltinMComdr		= 18,			// inside SB Manual & Commander
	kNkfl_FlashAuto_OptionalRPT			= 19,			// outside SB Repeating
	kNkfl_FlashAuto_OptionalTTLComdr	= 20,			// outside SB TTL & commander
	kNkfl_FlashAuto_OptionalAAComdr		= 21,			// outside SB AA & commander
	kNkfl_FlashAuto_OptionalMComdr		= 22,			// outside SB Manula & commander
	kNkfl_FlashAuto_OptionalRPTComdr	= 23,			// outside SB repeating & commander
	kNkfl_FlashAuto_OptionalAComdr		= 24,			// outside SB A & commander
	kNkfl_FlashAuto_None								// None
};
	
///////////////////////////////////////////////////////////
//	Sensitiveity Mode
//
enum eNkflSensitivityMode
{
	kNkfl_SensitivityMode_Normal		= 0,			//	It's for D1	
	kNkfl_SensitivityMode_High			= 1,
	kNkfl_SensitivityMode_Low			= 2,
	kNkfl_SensitivityMode_High2EV		= 3,

	kNkfl_SensitivityMode_Manual		= 0x8001,		//	It's for CoolPix
	kNkfl_SensitivityMode_Default		= 0x8008,
	kNkfl_SensitivityMode_Auto			= 0x8009,
	kNkfl_SensitivityMode_1EVUp			= 0x8010,
	kNkfl_SensitivityMode_2EVUp			= 0x8011
};

///////////////////////////////////////////////////////////
//	eNkflBRTCNTComp		Brightness Contrast compensation for Coolpix
//
enum eNkflBRTCNTComp
{
	kNkfl_BRTCNTComp_Normal				= 0x0001,		// Normal
	kNkfl_BRTCNTComp_Auto				= 0x0002,		// Auto
	kNkfl_BRTCNTComp_BrightnessUp		= 0x0101,		// Brightness (+)
	kNkfl_BRTCNTComp_BrightnessDown		= 0x0102,		// Brightness (-)
	kNkfl_BRTCNTComp_ContrastUp			= 0x0104,		// Contrast (+)
	kNkfl_BRTCNTComp_ContrastDown		= 0x0108,		// Contrast (-)
	kNkfl_BRTCNTComp_BW					= 0x010A,		// B & W
	kNkfl_BRTCNTComp_Sepia				= 0x010C		// sepia
};

///////////////////////////////////////////////////////////
//	eNkflToneCompensation	
//  07/05/21 edit by Yamaguchi.T
enum eNkflToneCompensation
{
	kNkfl_ToneCompensation_Normal		= 0,			// Normal
	kNkfl_ToneCompensation_Low			= 1,			// Low-contrast
	kNkfl_ToneCompensation_High			= 2,			// High-contrast
	kNkfl_ToneCompensation_BW			= 3,			// Black and White
	kNkfl_ToneCompensation_Auto			= 4,			// Auto
	kNkfl_ToneCompensation_MidLow		= 5,			// Medium Low
	kNkfl_ToneCompensation_MidHigh		= 6,			// Medium Hight
	kNkfl_ToneCompensation_DownLoad		= 16,			// DownLoad
	kNkfl_ToneCompensation_CS1			= 17,			// User-defined custom curve1
	kNkfl_ToneCompensation_CS2			= 18,			// User-defined custom curve2
	kNkfl_ToneCompensation_CS3			= 19			// User-defined custom curve3
};

///////////////////////////////////////////////////////////
//	eNkflConverterLens	
//
enum eNkflConverterLens
{
	kNkfl_ConverterLens_None			= 0x0000,		// Not attached
	kNkfl_ConverterLens_Attached		= 0x0001,		// attached
	kNkfl_ConverterLens_Fisheye1		= 0x1001,		// Fisheye converter type 1
	kNkfl_ConverterLens_Fisheye2		= 0x1002,		// Fisheye converter type 2
	kNkfl_ConverterLens_Wide			= 0x2001,		// Wide converter
	kNkfl_ConverterLens_Telephoto1		= 0x3001,		// Tele converter type 1
	kNkfl_ConverterLens_Telephoto2		= 0x3002,		// Tele converter type 2
	kNkfl_ConverterLens_Slide			= 0x4001		// Slide Adaptor
};

///////////////////////////////////////////////////////////
//	eNkflAFAreaMode	
//
enum eNkflAFAreaMode
{
	kNkfl_AFAreaMode_Single					= 0,		// Single Area AF
	kNkfl_AFAreaMode_Dynamic				= 1,		// Dynamic AF
	kNkfl_AFAreaMode_CloseRangePriorDynamic = 2,		// Close range Prior Dynamic mode
	kNkfl_AFAreaMode_Group					= 3			// Group Area mode
};

///////////////////////////////////////////////////////////
//	eNkflAFPreferedArea	
//
enum eNkflAFPreferedArea
{
	kNkfl_AFPreferedArea_Center			= 0,			// Center cell
	kNkfl_AFPreferedArea_Top			= 1,			// Top cell
	kNkfl_AFPreferedArea_Bottom			= 2,			// Bottom cell
	kNkfl_AFPreferedArea_Left			= 3,			// Left cell
	kNkfl_AFPreferedArea_Right			= 4				// Right cell
};

////////////////////////////////////////////////////////////
//	eNkflColorRecurrence
//
enum eNkflColorRecurrence
{
	kNkfl_ColorRecurrence_None			= 0,		// none 
	kNkfl_ColorRecurrence_sRGB			= 1,		// Natural Mode
	kNkfl_ColorRecurrence_AdobeRGB		= 2,		// Product Mode
	kNkfl_ColorRecurrence_Mode3			= 3,		// Mode 3
	kNkfl_ColorRecurrence_Mode4			= 4,		// Mode 4
	kNkfl_ColorRecurrence_Mode5			= 5,		// Mode 5
	kNkfl_ColorRecurrence_BW			= 6,		// Black & White
	kNkfl_ColorRecurrence_D1Color		= 10		// D1Color
};

///////////////////////////////////////////////////////////
//	eNkflDateTimePrint
//
enum eNkflDateTimePrint
{
	kNkfl_DateTimePrint_None			= 0x0000,		// Non DateTime Print
	kNkfl_DateTimePrint_DateTimePrinted	= 0x0001,		// Date-Time Printed
	kNkfl_DateTimePrint_DateOnly		= 0x0002		// Date Printed
};

/////////////////////////////////////////////////////////////
//	eNkflGPSPositionRef
//
enum eNkflGPSPositionRef
{
	kNkfl_GPSPosition_North_Latitude	=0,
	kNkfl_GPSPosition_South_Latitude	=1,
	kNkfl_GPSPosition_East_Longitude	=2,
	kNkfl_GPSPosition_West_Longitude	=3
};

///////////////////////////////////////////////////////////
//	eNkflCMS
//  for loacal
enum eNkflCMS
{
	kNkfl_CMS_None						= 0,		
	kNkfl_CMS_RGB8						= 1,			// RGB 8bit
	kNkfl_CMS_RGB16						= 2,			// RGB 16bit
	kNkfl_CMS_CMYK						= 3,			// CMYK
	kNkfl_CMS_GRAY8						= 4,			// GRAY 8bit
	kNkfl_CMS_GRAY16					= 5				// GRAY 16bit
};

////////////////////////////////////////////////////////////
//	eNkflRenderingIntent
//
enum eNkflRenderingIntent
{
	kNkfl_RenderingIntent_Perceptual	= 0,			//	Perceptual
	kNkfl_RenderingIntent_Relative		= 1,			//	Relative
	kNkfl_RenderingIntent_Absolute		= 2,			//	Absolute
	kNkfl_RenderingIntent_Saturation	= 3				//	Saturation
};

///////////////////////////////////////////////////////////
//	eNkflCode
//
enum eNkflCode
{
	kNkfl_Code_None										= 0x0000,	//	There is no error.
	kNkfl_Code_Err_OutofMemory							= 0x0001,	//	Error: Could not allocate memory.
	kNkfl_Code_Err_OutofResource						= 0x0002,	//	Error: Could not resource.
	kNkfl_Code_Err_NotSupported							= 0x0003,	//	Error: Not supported function was called.
	kNkfl_Code_Err_InvalidParam							= 0x0004,	//	Error: Parameter error.
	kNkfl_Code_Err_WrongSequence						= 0x0005,	//	Error: Sequence error
	kNkfl_Code_Err_FileNotFound							= 0x0006,	//	Error: Could not find DLL file.
	kNkfl_Code_Err_OutofVersion							= 0x0007,	//	Error: Version error
	kNkfl_Code_Err_Unexpected							= 0x0008,	//	Error: The reason may be bug.	
	kNkfl_Code_Err_FileIO								= 0x0009,	//	Error: File IO error.
	kNkfl_Code_Err_NotAllowed							= 0x000A,	//	Error: Not allowed.
	kNkfl_Code_Err_TagNotFound							= 0x000B,	//	Error: Specified tag is not found.
	kNkfl_Code_Err_Abort								= 0x000C,	//	Error: Abort because error has occuurred at callback proc.
	kNkfl_Code_Err_Cancel								= 0x000D,	//	Error: Cancel indicated by application.
	kNkfl_Code_Err_TagRead								= 0x000E,	//	Error: Read tag data is invalid.
	kNkfl_Code_Err_WrongAliasHandle						= 0x000F,	//	Error: Wrong Alias handle is set to parameter (Macintosh Only)
	kNkfl_Code_Err_PictureControlAppliedImage			= 0x0010,	//	Error: cannot apply for picture control image(add 2007/05/18 by Yamaguchi.T)
	kNkfl_Code_Err_ColorModeNotSupported				= 0x0011,	//	Error: cannot apply for color mode image(add 2007/05/18 by Yamaguchi.T)
	kNkfl_Code_Err_RawDevelopmentNotAllowed				= 0x0012,	//	Error: no allowed to raw develop
	kNkfl_Code_Err_ShootingDataNotFound					= 0x0013,	//	Error: do not find ShooingData in image.
	kNkfl_Code_Err_OptionalPictureControlNotInstalled	= 0x0014,	//	Error: OPC isn't installed.
	kNkfl_Code_Err_NoiseReductionNotApplicable			= 0x0015,	//	Error: do not apply NoiseReduction.

    kNkfl_Code_Err_TagFailed			                = 0x0016,	//	Error: Tag error.
    kNkfl_Code_Err_WrongImageInfo			            = 0x0017,	//	Error: Illegal image information structure.

	kNkfl_Code_Warn_OptionalPictureControlNotApplicable	= 0x0101,	//	Warning: do not apply OptionalPictureControl.
	kNkfl_Code_Warn_EditStateNotExist					= 0x0102,	//	Warning: The image does not have edit information.
	kNkfl_Code_Warn_EditStateNotApplicable				= 0x0103,	//	Warning: The image have non-applicable edit information.
	kNkfl_Code_Warn_LowResolutionNotApplicable			= 0x0104,	//	Warning: do not apply LowResolution.
	kNkfl_Code_Warn_D2XModeNotApplicable				= 0x0105,	//	Warning: do not apply D2XMode
	kNkfl_Code_Warn_Auto2NotApplicable					= 0x0106,	//	Warning: do not apply Auto2(WhiteBalance)
	kNkfl_Code_Warn_ExtraHigh2NotApplicable				= 0x0107,	//	Warning: do not apply ExtraHigh2(ActiveD-Lighting)
	kNkfl_Code_Warn_UnderwaterNotApplicable				= 0x0108,	//	Warning: do not apply Underwater(WhiteBalance)
	kNkfl_Code_Warn_Auto1NotApplicable					= 0x0109,	//	Warning: do not apply Auto1(WhiteBalance)
	kNkfl_Code_Warn_FlatNotApplicable					= 0x0110,	//	Warning: do not apply Flat
	kNkfl_Code_Warn_Auto0NotApplicable					= 0x0111,	//	Warning: do not apply Auto0(WhiteBalance)
	kNkfl_Code_Warn_PicCtrlAutoNotApplicable			= 0x0112,	//	Warning: do not apply PicCtrl Auto.
	kNkfl_Code_Warn_NaturalLightAutoNotApplicable		= 0x0113,	//	Warning: do not apply Natural Light Auto.
	kNkfl_Code_Warn_CreativePicCtrlNotApplicable		= 0x0114,	//	Warning: do not apply CreativePicCtrl.
	kNkfl_Code_Warn_HLGPicCtrlNotApplicable				= 0x0115,	//	Warning: do not apply HLGPicCtrl.
};

///////////////////////////////////////////////////////////
//	eNkflCode
//
enum eNkflPictureControlVersion
{
	kNkfl_PictureControlVersion_None	= 0x00, // Image is not picture control.
	kNkfl_PictureControlVersion_0100	= 0x01, // Image is picture control ver1.
	kNkfl_PictureControlVersion_0200	= 0x02, // Image is picture control ver2.
	kNkfl_PictureControlVersion_0210	= 0x03, // Image is picture control ver2.1.
	kNkfl_PictureControlVersion_0300	= 0x04, // Image is picture control ver3.
	kNkfl_PictureControlVersion_0301	= 0x05, // Image is picture control ver3.0.1
	kNkfl_PictureControlVersion_0302	= 0x06, // Image is picture control ver3.0.2
	kNkfl_PictureControlVersion_0310	= 0x07, // Image is picture control ver3.1
	kNkfl_PictureControlVersion_Latest	= kNkfl_PictureControlVersion_0310, // Latest( = ver.3.1).
};

///////////////////////////////////////////////////////////
//	eNkflDevelopColorMode
//  SDK-330
enum eNkflDevelopColorMode
{
	kNkfl_DevelopColorMode_AppliedInCamera  = 0,
	kNkfl_DevelopColorMode_sRGB				= 1,
	kNkfl_DevelopColorMode_AdobeRGB			= 2,
};

///////////////////////////////////////////////////////////
//	eNkflNoiseReductionMode
//
enum eNkflNoiseReductionMode
{
	kNkfl_NoiseReductionMode_Undefined = 0,
	kNkfl_NoiseReductionMode_Type_A = 1,
	kNkfl_NoiseReductionMode_Type_B = 2,
};

///////////////////////////////////////////////////////////
// eNkflFilmGrainSize
enum eNkflFilmGrainSize
{
	kNkfl_FilmGrainSize_Small = 0,
	kNkfl_FilmGrainSize_Medium,
	kNkfl_FilmGrainSize_Large
};

///////////////////////////////////////////////////////////
#endif
