# sam21-iphone

This is a clone from https://github.com/huggingface/sam2-studio with following modification :

it can build and run correctly on REAL iphone(tested only on iPhone 16 pro max, iOS 18.1) .
it CANNOT run on iPhone simulator, as the coreml output is all zero and cause the NAN issue.

The porpuse is to make the coreml model running on iOS and to compare with the model that use in our app.

the coreml models are not included in this project, please download and add in accordingly from:

https://huggingface.co/collections/apple/core-ml-segment-anything-2-66e4571a7234dc2560c3db26


Advertisement:

we build an 100% free and fully functional iOS app that run on SAM.

https://apps.apple.com/sg/app/cutcha-photo/id6478521132

The sam the app used:

https://github.com/chongzhou96/EdgeSAM

