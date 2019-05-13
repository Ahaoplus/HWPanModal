//
//  HWPanModalPresentationAnimator.m
//  HWPanModal
//
//  Created by heath wang on 2019/4/29.
//

#import "HWPanModalPresentationAnimator.h"
#import "HWPanModalAnimator.h"
#import "UIViewController+LayoutHelper.h"
#import "HWPanContainerView.h"

@interface HWPanModalPresentationAnimator ()

@property (nonatomic, assign) TransitionStyle transitionStyle;

@property (nullable, nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator API_AVAILABLE(ios(10.0));

@end

@implementation HWPanModalPresentationAnimator

- (instancetype)initWithTransitionStyle:(TransitionStyle)transitionStyle {
	self = [super init];
	if (self) {
		_transitionStyle = transitionStyle;
		if (transitionStyle == TransitionStylePresentation) {
            if (@available(iOS 10.0, *)) {
                _feedbackGenerator = [UISelectionFeedbackGenerator new];
                [_feedbackGenerator prepare];
            } else {
                // Fallback on earlier versions
            }
		}
	}

	return self;
}

/**
 * 弹出controller动画
 */
- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)context {

	UIViewController *toVC = [context viewControllerForKey:UITransitionContextToViewControllerKey];
	UIViewController *fromVC = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
	if (!toVC && !fromVC)
		return;

	// If you are implementing a custom container controller, use this method to tell the child that its views are about to appear or disappear.
    
	[fromVC beginAppearanceTransition:NO animated:YES];
	[toVC beginAppearanceTransition:YES animated:YES];

	UIViewController<HWPanModalPresentable> *presentable = [self panModalViewController:context];

	CGFloat yPos = presentable.shortFormYPos;

	UIView *panView = context.containerView.panContainerView ?: toVC.view;
	panView.frame = [context finalFrameForViewController:toVC];
	CGRect rect = panView.frame;
	rect.origin.y = context.containerView.frame.size.height;
	panView.frame = rect;

	if ([presentable isHapticFeedbackEnabled]) {
        if (@available(iOS 10.0, *)) {
            [self.feedbackGenerator selectionChanged];
        } else {
            // Fallback on earlier versions
        }
	}

	[HWPanModalAnimator animate:^{
        CGRect frame = panView.frame;
        frame.origin.y = yPos;
		panView.frame = frame;
	} config:presentable completion:^(BOOL completion) {
		[fromVC endAppearanceTransition];
		[toVC endAppearanceTransition];
		[context completeTransition:completion];
        if (@available(iOS 10.0, *)) {
            self.feedbackGenerator = nil;
        } else {
            // Fallback on earlier versions
        }
	}];

}

/**
 * 使弹出controller消失动画
 */
- (void)animateDismissal:(id<UIViewControllerContextTransitioning>)context {
	UIViewController *fromVC = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
	UIViewController *toVC = [context viewControllerForKey:UITransitionContextToViewControllerKey];
	if (!fromVC && !toVC)
		return;

	[fromVC beginAppearanceTransition:NO animated:YES];
	[toVC beginAppearanceTransition:YES animated:YES];

	UIViewController<HWPanModalPresentable> *presentable = [self panModalViewController:context];

	UIView *panView = context.containerView.panContainerView ?: fromVC.view;

	[HWPanModalAnimator animate:^{
		CGRect frame = panView.frame;
		frame.origin.y = context.containerView.frame.size.height;
		panView.frame = frame;
	} config:presentable completion:^(BOOL completion) {
		[fromVC.view removeFromSuperview];
		[toVC endAppearanceTransition];
		[fromVC endAppearanceTransition];
		[context completeTransition:completion];
	}];
}

- (UIViewController<HWPanModalPresentable> *)panModalViewController:(id<UIViewControllerContextTransitioning>)context {
	switch (self.transitionStyle) {
		case TransitionStylePresentation:
		{
			UIViewController *controller = [context viewControllerForKey:UITransitionContextToViewControllerKey];
			if ([controller conformsToProtocol:@protocol(HWPanModalPresentable)]) {
				return (UIViewController <HWPanModalPresentable> *) controller;
			} else {
				return nil;
			}
		}
		case TransitionStyleDismissal:
		{
			UIViewController *controller = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
			if ([controller conformsToProtocol:@protocol(HWPanModalPresentable)]) {
				return (UIViewController <HWPanModalPresentable> *) controller;
			} else {
				return nil;
			}
		}
	}
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(nonnull id<UIViewControllerContextTransitioning>)transitionContext { 
	switch (self.transitionStyle) {
		case TransitionStylePresentation: {
			[self animatePresentation:transitionContext];
		}
			break;
		case TransitionStyleDismissal: {
			[self animateDismissal:transitionContext];
		}
		default:
			break;
	}
}

- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
	if (transitionContext && [self panModalViewController:transitionContext]) {
		UIViewController<HWPanModalPresentable> *controller = [self panModalViewController:transitionContext];
		return [controller transitionDuration];
	}
	return kTransitionDuration;
}

@end