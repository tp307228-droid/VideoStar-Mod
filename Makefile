INSTALL_TARGET_PROCESSES = VideoStar
ARCHS = arm64
TARGET = iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FallVdsTool

FallVdsTool_FILES = \
	Tweak.x \
	FallVdsTool/FallVdsToolUI.m \
	FallVdsTool/FloatingButton.m \
	FallVdsTool/HideStream.m \
	FallVdsTool/LicenseManager.m \
	FallVdsTool/LicenseVC.m \
	FallVdsTool/MediaReplacerVC.m \
	FallVdsTool/QRImporterVC.m

FallVdsTool_CFLAGS  = -fobjc-arc -I./FallVdsTool
FallVdsTool_CCFLAGS = -fobjc-arc
FallVdsTool_FRAMEWORKS = \
	UIKit CoreGraphics Foundation \
	AVFoundation Photos PhotosUI \
	QuartzCore ReplayKit

include $(THEOS_MAKE_PATH)/tweak.mk
