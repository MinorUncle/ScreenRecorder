//
//  Formats.h
//  GJCaptureTool
//
//  Created by 未成年大叔 on 16/10/16.
//  Copyright © 2016年 MinorUncle. All rights reserved.
//

#ifndef Formats_h
#define Formats_h

typedef enum GJType{
    VideoType,
    AudooType,
}GJType;
typedef enum ProfileLevel{
    profileLevelBase,
    profileLevelMain,
    profileLevelHigh,
}ProfileLevel;
typedef enum EntropyMode{
    EntropyMode_CABAC,
    EntropyMode_CAVLC,
}EntropyMode;

#define VIDEO_TIMESCALE 1000

#if __COREFOUNDATION_CFBASE__
static CFStringRef  getCFStrByLevel(ProfileLevel level){
    CFStringRef ref;
    switch (level) {
        case profileLevelBase:
            ref = kVTProfileLevel_H264_Baseline_AutoLevel;
            break;
        case profileLevelMain:
            ref = kVTProfileLevel_H264_Main_AutoLevel;
            break;
        case profileLevelHigh:
            ref = kVTProfileLevel_H264_High_AutoLevel;
            break;
        default:
            break;
    }
    return ref;
}
static CFStringRef getCFStrByEntropyMode(EntropyMode model){
    CFStringRef ref;
    switch (model) {
        case EntropyMode_CABAC:
            ref = kVTH264EntropyMode_CABAC;
            break;
        case EntropyMode_CAVLC:
            ref = kVTH264EntropyMode_CAVLC;
            break;
        default:
            break;
    }
    return ref;
}



#endif

typedef struct GJVideoFormat{
    
    uint32_t width,height;
    uint8_t fps;
    uint32_t bitRate;
}GJVideoFormat;

typedef struct H264Format{
    GJVideoFormat baseFormat;
    uint32_t gopSize;
    EntropyMode model;
    ProfileLevel level;
    BOOL allowBframe;
    BOOL allowPframe;
    
}H264Format;

typedef struct _GJAudioFormat{
    uint32_t width;
    uint32_t height;
}GJAudioFormat;


typedef struct GJPacket{
    uint32_t timestamp;
    uint32_t pts;
    uint32_t dts;
    uint8_t* data;
    uint32_t dataSize;
}GJPacket;

typedef struct GJFrame{
    GJType mediaType;
    uint32_t timestamp;
    uint32_t pts;
    uint8_t* data;
    uint32_t dataSize;
}GJFrame;




#endif /* Formats_h */
