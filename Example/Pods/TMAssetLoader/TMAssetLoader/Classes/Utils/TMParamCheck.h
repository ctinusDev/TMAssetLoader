//
//  TMParamCheck.h
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import <Foundation/Foundation.h>

@interface TMParamCheck : NSObject

extern BOOL paramCheckTypes(id param, Class types,...);

@end

#define kParamCheckTypesReturn(param, returnType, typeClasses,...) if(!paramCheckTypes(param, typeClasses, ##__VA_ARGS__)) {\
return returnType;\
}

//如果returnType是void可以直接不填
#define kParamCheck(param, returnType, type) kParamCheckTypesReturn(param, returnType, type.class)
#define kParamCheck2(param, returnType, type1, type2) kParamCheckTypesReturn(param, returnType, type1.class, type2.class)
#define kParamCheck3(param, returnType, type1, type2, type3) kParamCheckTypesReturn(param, returnType, type1.class, type2.class, type3.class)
#define kParamCheck4(param, returnType, type1, type2, type3, type4) kParamCheckTypesReturn(param, returnType, type1.class, type2.class, type3.class)
#define kParamCheck5(param, returnType, type1, type2, type3, type4, type5) kParamCheckTypesReturn(param, returnType, type1.class, type2.class, type3.class, type4.class, type5.class)
#define kParamCheck6(param, returnType, type1, type2, type3, type4, type5, type6) kParamCheckTypesReturn(param, returnType, type1.class, type2.class, type3.class, type4.class, type5.class, type6.class)
#define kParamCheck7(param, returnType, type1, type2, type3, type4, type5, type6, type7) kParamCheckTypesReturn(param, returnType, type1.class, type2.class, type3.class, type4.class, type5.class, type6.class, type7.class)
