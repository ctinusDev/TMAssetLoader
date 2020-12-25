//
//  NSObject+TM_DataBind.h
//  TMAssetLoadEngine
//
//  Created by tomychen on 2020/12/25.
//

#import <Foundation/Foundation.h>

#pragma mark - WeakStrong
/*
 * block外用@weakify(self)声明弱引用，block内部使用@strongify(self)声明强引用，防止内部多线程情况下将self释放。
 * block内部直接使用原生的self，并且@weakify和@strongify要成对出现
 */
/*weak self*/
#define weakify(VAR) __weak __typeof__(VAR) VAR##_weak_ = VAR

/*strong self*/
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"
#if  __has_feature(objc_arc)
#define strongify(VAR) __strong __typeof__(VAR) VAR = (VAR##_weak_)
#else
#define strongify(VAR) __strong __typeof__(VAR) VAR = [[(VAR##_weak_) retain] autorelease];
#endif
#pragma clang diagnostic pop


@interface NSObject (TM_DataBind)
/**
 给对象绑定上另一个对象以供后续取出使用，如果 object 传入 nil 则会清除该 key 之前绑定的对象
 
 @attention 被绑定的对象会被 strong 强引用
 @note 内部是使用 objc_setAssociatedObject / objc_getAssociatedObject 来实现
 
 @code
 - (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath {
 // 1）在这里给 button 绑定上 indexPath 对象
 [cell tm_bindObject:indexPath forKey:@"indexPath"];
 }
 
 - (void)didTapButton:(UIButton *)button {
 // 2）在这里取出被点击的 button 的 indexPath 对象
 NSIndexPath *indexPathTapped = [button tm_getBoundObjectForKey:@"indexPath"];
 }
 @endcode
 */
- (void)tm_bindObject:(id)object forKey:(NSString *)key;

/**
 取出之前使用 bind 方法绑定的对象
 */
- (id)tm_getBoundObjectForKey:(NSString *)key;

/**
 给对象绑定上一个 double 值以供后续取出使用
 */
- (void)tm_bindDouble:(double)doubleValue forKey:(NSString *)key;

/**
 取出之前用 bindDouble:forKey: 绑定的值
 */
- (double)tm_getBoundDoubleForKey:(NSString *)key;

/**
 给对象绑定上一个 BOOL 值以供后续取出使用
 */
- (void)tm_bindBOOL:(BOOL)boolValue forKey:(NSString *)key;

/**
 取出之前用 bindBOOL:forKey: 绑定的值
 */
- (BOOL)tm_getBoundBOOLForKey:(NSString *)key;

/**
 给对象绑定上一个 long 值以供后续取出使用
 */
- (void)tm_bindLong:(long)longValue forKey:(NSString *)key;

/**
 取出之前用 bindLong:forKey: 绑定的值
 */
- (long)tm_getBoundLongForKey:(NSString *)key;

/**
 移除之前使用 bind 方法绑定的对象
 */
- (void)tm_clearBindingForKey:(NSString *)key;

/**
 移除之前使用 bind 方法绑定的所有对象
 */
- (void)tm_clearAllBinding;

/**
 返回当前有绑定对象存在的所有的 key 的数组，如果不存在任何 key，则返回一个空数组
 @note 数组中元素的顺序是随机的
 */
- (NSArray<NSString *> *)tm_allBindingKeys;

/**
 返回是否设置了某个 key
 */
- (BOOL)tm_hasBindingKey:(NSString *)key;

@end
